# Monitor de Sistema Windows

Este script em PowerShell monitora o uso de CPU, memória, disco e rede em tempo real, emitindo alertas quando os limites configurados são ultrapassados.

## Funcionalidades
- Monitora o uso de CPU, memória RAM, discos e rede.
- Exibe alertas visuais e sonoros quando os limites são ultrapassados.
- Atualização automática a cada período definido pelo usuário.
- Exibição de estatísticas detalhadas no console.

## Pré-requisitos
- Windows com suporte a PowerShell.
- Permissão para executar scripts PowerShell (caso necessário, execute `Set-ExecutionPolicy RemoteSigned` como administrador).

## ⚙️ Como Usar
1. Clone este repositório ou copie o script para seu computador.
2. Abra o PowerShell como administrador.
3. Navegue até a pasta onde está o script.
4. Execute o comando:
   ```powershell
   .\systemmonitor.ps1
   ```

Você pode configurar os valores dos limites diretamente no script:
```powershell
$CPU_THRESHOLD = 80        
$MEMORY_THRESHOLD = 80    
$DISK_THRESHOLD = 85       
$NETWORK_THRESHOLD = 70   
```

Também é possível definir o intervalo de atualização e a duração da execução:
```powershell
Start-SystemMonitoring -RefreshInterval 5 -RunDuration 0
```
- `RefreshInterval`: Tempo em segundos entre cada atualização.
- `RunDuration`: Tempo total de execução (0 para infinito).

## Monitoramento em Tempo Real
O script exibe informações detalhadas no terminal:
```
Monitor de Sistema Windows - 2024-03-17 14:30:00
------------------------------------------------
CPU: 75%

Memória:
  Total: 16 GB
  Em uso: 12 GB
  Livre: 4 GB
  Uso: 75%

Discos:
  C:
    Total: 500 GB
    Em uso: 350 GB
    Livre: 150 GB
    Uso: 70%

Rede:
  Adaptador Wi-Fi
    Enviado: 1.2 MB/s
    Recebido: 3.5 MB/s
    Utilização: 60%
------------------------------------------------
Pressione Ctrl+C para sair | Atualização a cada 5 segundos
```

## Personalização
Você pode modificar o script para atender às suas necessidades, alterando os limites de alerta, a interface de exibição ou adicionando novos recursos.
