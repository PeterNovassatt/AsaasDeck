# Changelog

## 0.2.0

Diagnóstico do Docker, motivado pelo caso que mais custa tempo: a VM do Rancher Desktop congelar
depois que o Mac suspende — o processo do QEMU segue vivo e o `limactl list` reporta `Running`, mas
o guest está morto e o `dockerd` nunca sobe.

- Linha própria para o **Docker** nas dependências, dizendo *por que* está fora e não só *que* está:
  `ativo`, `VM congelada`, `VM parada` ou `Rancher fechado`
- O diagnóstico usa apenas sinais do host — processos do QEMU e do hostagent, resposta do
  `docker info` e idade do `serial.log` da VM. Nada consulta o guest, porque `limactl shell` fica
  pendurado por minutos exatamente quando a VM está nesse estado
- Botão **Reiniciar Docker**, com confirmação, que encerra a VM, reabre o Rancher Desktop, espera o
  engine responder (até 240 s) e sobe os containers do `docker-compose.yaml`. Imagens, containers e
  volumes são preservados — eles vivem no disco da VM
- Quando o `rdctl shutdown` fica pendurado (o que acontece justamente com a VM congelada, porque ele
  depende do guest), o painel espera 45 s e então derruba os processos do QEMU e do hostagent
- `rdctl` é localizado dentro do bundle do Rancher Desktop, já que o instalador não o coloca no PATH
- Novas chaves de configuração: `rdctl` e `compose_dir`

## 0.1.0

Primeira versão.

- Status do backend (rodando / iniciando / parado) com PID, uptime e código HTTP real
- Dependências monitoradas: MySQL, Redis, Webpack e daemon do Gradle
- Ações: iniciar, parar, limpar e encerrar o daemon do Gradle
- Iniciar abre uma janela do terminal (iTerm2 ou Terminal do macOS) e executa um script gerado,
  porque o `grails run-app` não conclui o startup sem um terminal de verdade
- IP local com botão para gravar o `IP_ADDRESS` nos `DebugSettings.cs` dos apps mobile
- Campo de e-mail por app, gravando o `LoginUsername` de cada repositório
- Código OTP extraído do log, em destaque e com botão de copiar
- Log do backend com timestamps discretos e cores por nível, filtrando a barra de progresso do
  Gradle (que é escrita sem quebra de linha e cola nas mensagens da aplicação)
- Caminhos autodetectados, com override por `~/.asaas-deck/config.json` ou variáveis `ASAAS_*`
- Interface responsiva, com favicon e apple-touch-icon para uso no celular
