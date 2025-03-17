$CPU_THRESHOLD = 80        
$MEMORY_THRESHOLD = 80    
$DISK_THRESHOLD = 85       
$NETWORK_THRESHOLD = 70    

function Show-Alert {
    param (
        [string]$ResourceType,
        [double]$Value,
        [double]$Threshold
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] ALERTA: $ResourceType atingiu $Value%, acima do limite de $Threshold%" -ForegroundColor Red
    
    $title = "Alerta de Sistema"
    $message = "$ResourceType atingiu $Value%, acima do limite de $Threshold%"
    
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $notification = New-Object System.Windows.Forms.NotifyIcon
        $notification.Icon = [System.Drawing.SystemIcons]::Warning
        $notification.BalloonTipTitle = $title
        $notification.BalloonTipText = $message
        $notification.Visible = $true
        $notification.ShowBalloonTip(5000)
    } catch {

    }
}

function Format-Size {
    param([int64]$Size)
    
    if ($Size -gt 1TB) { return "{0:N2} TB" -f ($Size / 1TB) }
    if ($Size -gt 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    if ($Size -gt 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    if ($Size -gt 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    
    return "$Size bytes"
}

function Get-NetworkUtilization {

    $initialNetworkStats = Get-NetAdapterStatistics | Where-Object { $_.Status -eq "Up" }
    Start-Sleep -Seconds 2
    $currentNetworkStats = Get-NetAdapterStatistics | Where-Object { $_.Status -eq "Up" }
    
    $networkInfo = @()
    
    foreach ($adapter in $currentNetworkStats) {
        $initial = $initialNetworkStats | Where-Object { $_.Name -eq $adapter.Name }
        if ($initial) {
            $bytesSentDelta = $adapter.SentBytes - $initial.SentBytes
            $bytesReceivedDelta = $adapter.ReceivedBytes - $initial.ReceivedBytes
            
            $maxBytesIn2Sec = 250000000  
            $totalBytes = $bytesSentDelta + $bytesReceivedDelta
            $utilizationPercent = [Math]::Min(100, [Math]::Round(($totalBytes / $maxBytesIn2Sec) * 100, 2))
            
            $networkInfo += [PSCustomObject]@{
                AdapterName = $adapter.Name
                Sent = Format-Size $bytesSentDelta
                Received = Format-Size $bytesReceivedDelta
                UtilizationPercent = $utilizationPercent
            }
        }
    }
    
    return $networkInfo
}

function Start-SystemMonitoring {
    param (
        [int]$RefreshInterval = 5, 
        [int]$RunDuration = 0  
    )
    
    $startTime = Get-Date
    $endTime = if ($RunDuration -gt 0) { $startTime.AddSeconds($RunDuration) } else { [datetime]::MaxValue }
    
    Clear-Host
    Write-Host "Monitor de Sistema Windows - Pressione Ctrl+C para sair" -ForegroundColor Green
    Write-Host "------------------------------------------------" -ForegroundColor Green
    
    while ((Get-Date) -lt $endTime) {

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        $cpuUsageRounded = [Math]::Round($cpuUsage, 2)
        
        $osInfo = Get-CimInstance Win32_OperatingSystem
        $totalMemory = $osInfo.TotalVisibleMemorySize * 1KB
        $freeMemory = $osInfo.FreePhysicalMemory * 1KB
        $usedMemory = $totalMemory - $freeMemory
        $memoryUsagePercent = [Math]::Round(($usedMemory / $totalMemory) * 100, 2)
        
        $diskInfo = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, 
            @{Name="Size"; Expression={$_.Size}},
            @{Name="FreeSpace"; Expression={$_.FreeSpace}},
            @{Name="UsedSpace"; Expression={$_.Size - $_.FreeSpace}},
            @{Name="UsagePercent"; Expression={[Math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 2)}}
        
        $networkInfo = Get-NetworkUtilization
        
        Clear-Host
        Write-Host "Monitor de Sistema Windows - $timestamp" -ForegroundColor Cyan
        Write-Host "------------------------------------------------" -ForegroundColor Cyan
        
        if ($cpuUsageRounded -ge $CPU_THRESHOLD) {
            Write-Host "CPU: $cpuUsageRounded%" -ForegroundColor Red
            Show-Alert -ResourceType "CPU" -Value $cpuUsageRounded -Threshold $CPU_THRESHOLD
        } else {
            Write-Host "CPU: $cpuUsageRounded%" -ForegroundColor White
        }
        
        Write-Host "`nMemória:" -ForegroundColor Cyan
        Write-Host "  Total: $(Format-Size $totalMemory)"
        Write-Host "  Em uso: $(Format-Size $usedMemory)"
        Write-Host "  Livre: $(Format-Size $freeMemory)"
        
        if ($memoryUsagePercent -ge $MEMORY_THRESHOLD) {
            Write-Host "  Uso: $memoryUsagePercent%" -ForegroundColor Red
            Show-Alert -ResourceType "Memória" -Value $memoryUsagePercent -Threshold $MEMORY_THRESHOLD
        } else {
            Write-Host "  Uso: $memoryUsagePercent%" -ForegroundColor White
        }
        
        Write-Host "`nDiscos:" -ForegroundColor Cyan
        foreach ($disk in $diskInfo) {
            Write-Host "  $($disk.DeviceID)"
            Write-Host "    Total: $(Format-Size $disk.Size)"
            Write-Host "    Em uso: $(Format-Size $disk.UsedSpace)"
            Write-Host "    Livre: $(Format-Size $disk.FreeSpace)"
            
            if ($disk.UsagePercent -ge $DISK_THRESHOLD) {
                Write-Host "    Uso: $($disk.UsagePercent)%" -ForegroundColor Red
                Show-Alert -ResourceType "Disco $($disk.DeviceID)" -Value $disk.UsagePercent -Threshold $DISK_THRESHOLD
            } else {
                Write-Host "    Uso: $($disk.UsagePercent)%" -ForegroundColor White
            }
        }
        
        Write-Host "`nRede:" -ForegroundColor Cyan
        foreach ($adapter in $networkInfo) {
            Write-Host "  $($adapter.AdapterName)"
            Write-Host "    Enviado: $($adapter.Sent)/s"
            Write-Host "    Recebido: $($adapter.Received)/s"
            
            if ($adapter.UtilizationPercent -ge $NETWORK_THRESHOLD) {
                Write-Host "    Utilização: $($adapter.UtilizationPercent)%" -ForegroundColor Red
                Show-Alert -ResourceType "Rede $($adapter.AdapterName)" -Value $adapter.UtilizationPercent -Threshold $NETWORK_THRESHOLD
            } else {
                Write-Host "    Utilização: $($adapter.UtilizationPercent)%" -ForegroundColor White
            }
        }
        
        Write-Host "`n------------------------------------------------" -ForegroundColor Cyan
        Write-Host "Pressione Ctrl+C para sair | Atualização a cada $RefreshInterval segundos" -ForegroundColor DarkGray
        
        Start-Sleep -Seconds $RefreshInterval
    }
}

Start-SystemMonitoring -RefreshInterval 5 -RunDuration 0