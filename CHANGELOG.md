# Changelog

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
