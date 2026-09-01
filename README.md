# AsaasDeck

Painel local, no navegador, para gerenciar um backend Grails de desenvolvimento — ver status,
iniciar, parar e limpar, acompanhar o log, diagnosticar o Docker quando ele cai, destravar o Rider
quando ele para de responder e manter os apps mobile apontando para o IP certo da máquina.

![AsaasDeck](docs/screenshot.png)

Um único arquivo Python, biblioteca padrão apenas: sem `pip install`, sem `node_modules`, sem build
step. O HTML, o CSS e o JavaScript são servidos embutidos no próprio script.

## Por que existe

Rodar um backend Grails grande localmente envolve uma sequência chata e repetitiva: carregar o
SDKMAN, fixar as versões de Java e Grails, entrar na pasta certa, subir a aplicação, descobrir o IP
da máquina, copiar esse IP para a configuração dos apps mobile, e caçar no log o código OTP para
concluir um login de teste. O AsaasDeck junta tudo isso em uma página.

## Requisitos

- macOS
- `python3` (o do sistema serve; se faltar: `brew install python3`)
- SDKMAN instalado em `~/.sdkman`, com as versões de Java e Grails do projeto
- O backend e suas dependências (banco, cache) já configurados para rodar localmente

## Instalação

```bash
git clone https://github.com/PeterNovassatt/asaas-deck.git
cd asaas-deck
./install.sh
```

O instalador copia o script para `~/.local/bin/asaas-deck` e, se necessário, adiciona esse
diretório ao `PATH` no seu `~/.zshrc`.

Em um terminal novo:

```bash
asaas-deck
```

E abra <http://localhost:7070>.

Para atualizar: `git pull && ./install.sh`.

> Sem instalar nada: `python3 asaas-deck` funciona direto da pasta clonada.

## Uso

### Status e dependências

O bloco da direita mostra o estado do backend — **rodando**, **iniciando** ou **parado** — com PID,
tempo de execução e o código HTTP que a aplicação está devolvendo de fato. Abaixo, as dependências
que precisam estar de pé (Docker, MySQL, Redis, Webpack) e o daemon do Gradle. Cada item tem ícone,
cor e texto, para não depender só de cor.

### Docker e o Rancher Desktop

O Docker tem linha própria porque, quando ele cai, o que resolve é saber **por que** caiu:

| Estado | O que significa |
|---|---|
| **ativo** | o engine responde; mostra a versão |
| **VM congelada** | o QEMU está vivo mas o engine não responde — típico depois que o Mac suspende |
| **VM parada** | o Rancher Desktop está aberto, mas a VM não subiu |
| **Rancher fechado** | o aplicativo não está em execução |

O diagnóstico é feito só com sinais do host: processos do QEMU e do hostagent, resposta do
`docker info` e a idade do `serial.log` da VM. Nada consulta o guest de propósito — `limactl shell`
fica pendurado por minutos justamente quando a VM está congelada, que é quando você precisa da
resposta.

Nos três estados de falha aparece o botão **Reiniciar Docker** (pede confirmação). Ele encerra a VM,
reabre o Rancher Desktop, espera o engine responder e sobe os containers do `docker-compose.yaml`.
Containers em execução são interrompidos; **imagens e volumes são preservados**, porque vivem no
disco da VM.

Se o `rdctl shutdown` ficar pendurado — o que acontece com a VM congelada, já que ele depende do
guest — o painel espera 45 segundos e então derruba os processos do QEMU e do hostagent. O
`rdctl` é procurado dentro do bundle do Rancher Desktop, porque o instalador não o coloca no PATH;
se o seu estiver em outro lugar, aponte com `ASAAS_RDCTL`.

### Rider travado

O Rider trava de um jeito silencioso: a janela some, mas o `Rider.Backend` continua vivo — agora sem
pai — segurando a mesma solution. O sintoma é o botão de cancelar build (o martelo com a barra) aceso
o tempo todo, com build, deploy e debug sem sair do lugar.

O card do Rider mostra o estado e, quando há sobras, lista cada uma com PID, tipo e idade:

| Estado | O que significa |
|---|---|
| **ativo** | há uma janela do Rider e nada preso |
| **processos presos** | backends sem janela, ou workers e nós de MSBuild pendurados neles |
| **fechado** | o Rider não está em execução |

**Diagnosticar** não encerra nada: escreve no log a janela em uso e o backend dela, cada processo
preso com o dono, os build servers do dotnet e um veredito.

**Reiniciar Rider** (pede confirmação) fecha o Rider pelo `osascript`, o que preserva abas,
breakpoints e a última solution; só o que não fechar no prazo é encerrado à força. Depois mata os
processos presos — apurados por PID antes de começar, em vez de varrer por padrão —, limpa os
backends remanescentes, derruba os build servers do dotnet e reabre o Rider. **Salve o que estiver
aberto antes de clicar.**

O `.app` é procurado em `/Applications` e em `~/Applications` (Toolbox); se o seu estiver em outro
lugar, aponte com `ASAAS_RIDER_APP`.

### Iniciar, parar e limpar

| Botão | O que faz |
|---|---|
| **Iniciar** | Abre uma janela do terminal e sobe o backend |
| **Parar** | Encerra o processo do backend e libera a porta |
| **Limpar** | Roda `grails clean` (só com o backend parado) |
| **Encerrar daemon Gradle** | Mata daemons órfãos que ficam segurando locks do build |

O **Iniciar** abre uma janela do seu terminal (iTerm2 se você tiver, senão o Terminal do macOS),
espera 5 segundos e executa o comando de start (veja a seção seguinte). Abrir um terminal não é
capricho: o `grails run-app` não conclui o startup sem um TTY de verdade — sem ele o processo fica
pendurado indefinidamente no `bootRun`.

Duas consequências boas: o build fica visível na janela, então você acompanha e pode interromper com
Ctrl+C; e o backend não morre se você fechar o painel, porque os processos são independentes.

Na primeira vez o macOS pede autorização para o AsaasDeck controlar o terminal — aceite. Se recusar
por engano, libere em **Ajustes do Sistema > Privacidade e Segurança > Automação**.

### Qual comando o Iniciar executa

Na ordem, o primeiro que existir:

1. `start_cmd`, se você definiu no config ou por variável de ambiente
2. `run-asaas-tee` — se você tem esse atalho no shell
3. `run-asaas` — se você tem esse atalho no shell
4. `~/.asaas-deck/start-backend.sh`, gerado pelo próprio painel

A vantagem de um atalho seu é ver no terminal o comando que você já conhece. Só lembre que o
painel lê o log de `~/.asaas-deck/backend.log`: se o seu atalho não escreve lá, o log e o card de
OTP ficam vazios (o status, o IP e as dependências continuam funcionando). Para ter os dois, faça
o atalho espelhar a saída — em fish:

```fish
function run-asaas-tee
    mkdir -p $HOME/.asaas-deck
    run-asaas &| tee $HOME/.asaas-deck/backend.log
end
```

Em zsh ou bash, troque `&|` por `2>&1 |`.

### IP e e-mail dos apps mobile

O bloco da esquerda mostra o IP da máquina e, para cada app mobile, o IP e o e-mail de login que
estão hoje no `DebugSettings.cs`:

- **verde** — o IP do arquivo bate com o da máquina
- **amarelo** — divergente; clique em **→ apps** para gravar o IP atual nos dois
- **vermelho** — arquivo não encontrado (repo não clonado ou em outro caminho)

O campo de e-mail grava o `LoginUsername` de cada repositório separadamente, porque em geral são
contas de teste diferentes em cada app. As alterações aparecem no `git diff` do repo correspondente
— o AsaasDeck nunca commita nada.

### Código OTP

Quando o log traz um código de verificação, ele aparece em destaque no topo, com botão para copiar
(o próprio número também é clicável). O reconhecimento é uma heurística: números de 4 a 8 dígitos
perto de palavras como `otp`, `código`, `token` ou `verificação`. Para ajustar ao formato do seu
log, sem editar o script:

```bash
ASAAS_OTP_REGEX='seu padrão com (\d+) no grupo 1' asaas-deck
```

### Log

O log aparece com timestamps discretos e cores por nível — erros e exceções em vermelho, avisos em
âmbar, informação em verde. A barra de progresso do Gradle é filtrada: ela é escrita sem quebra de
linha e cola nas mensagens da aplicação, então o painel remove esses trechos de dentro da linha em
vez de descartar a linha inteira (que levaria embora o log útil, OTP incluído).

### No celular

A interface é responsiva e o painel escuta na rede local, então dá para abrir do celular usando o
IP da máquina: `http://SEU_IP:7070`. Tem favicon e apple-touch-icon, então o atalho na tela de
início fica com o ícone certo.

## Configuração

O AsaasDeck detecta sozinho onde estão os repositórios, procurando em `~/Documents`,
`/Volumes/workspace`, `~/Projects` e no home. Se os seus caminhos forem outros, crie
`~/.asaas-deck/config.json` a partir do `config.example.json` e apague o que não precisar.

Tudo também funciona por variável de ambiente, com o prefixo `ASAAS_`:

```bash
ASAAS_DECK_PORT=7071 asaas-deck        # outra porta para o painel
ASAAS_CORE_DIR=/Volumes/workspace/asaas-core asaas-deck
ASAAS_TERMINAL=Terminal asaas-deck     # força o Terminal do macOS
ASAAS_TERM_DELAY=8 asaas-deck          # mais tempo antes de injetar o comando
```

| Chave | Padrão | Para quê |
|---|---|---|
| `core_dir` | autodetectado | raiz do projeto do backend |
| `asaasmobile_dir` / `asaasmobile_platform_dir` | autodetectado | repos mobile (opcionais) |
| `deck_port` | `7070` | porta do painel |
| `app_port` | `8083` | porta do backend |
| `java` / `grails` | `8.0.442-tem` / `4.1.3` | versões usadas no `sdk use` |
| `term_delay` | `5` | segundos antes de injetar o comando |
| `terminal` | iTerm2 se existir | `iTerm` ou `Terminal` |
| `otp_regex` | heurística | padrão de extração do código OTP |
| `start_cmd` | ver abaixo | comando alternativo de start |
| `rdctl` | autodetectado | caminho do `rdctl` do Rancher Desktop |
| `compose_dir` | `~/Documents/docker/containers` | pasta do `docker-compose.yaml` |
| `rider_app` | autodetectado | caminho do `Rider.app` |

## Arquivos criados

Tudo fica em `~/.asaas-deck/`:

| Arquivo | Conteúdo |
|---|---|
| `backend.log` | saída do backend (sobrescrito a cada Iniciar) |
| `task.log` | saída da última limpeza, reinício do Docker ou diagnóstico do Rider |
| `start-backend.sh` | script gerado pelo botão Iniciar |
| `config.json` | suas configurações (opcional) |

## Como funciona por dentro

`ThreadingHTTPServer` da biblioteca padrão servindo uma página estática e uma API mínima:

| Rota | O que faz |
|---|---|
| `GET /api/status` | estado do backend, IP, dependências, apps mobile e OTP |
| `GET /api/logs` | log tratado |
| `POST /api/start` \| `/stop` \| `/clean` \| `/daemon` | ações |
| `POST /api/inject-ip` | grava o IP nos `DebugSettings.cs` |
| `POST /api/set-email` | grava o `LoginUsername` de um app |
| `POST /api/docker-fix` | reinicia a VM do Rancher e sobe os containers |

O estado das portas vem de uma única chamada de `lsof` com cache de 2 s — quatro chamadas separadas
a cada refresh custavam ~5 s por atualização.

## Desenvolvimento

O HTML/CSS/JS fica na constante `PAGE`, dentro do próprio `asaas-deck`. Para mexer na interface,
edite essa string e reinicie o processo — não há build.

Antes de abrir um PR, rode as mesmas verificações do CI:

```bash
python3 -m py_compile asaas-deck
zsh -n install.sh
python3 .github/scripts/check_page.py
```

O `check_page.py` protege contra dois erros silenciosos: um `"""` no HTML quebrando a string
Python, e a remoção de um elemento que o JavaScript da página procura por id.

## Problemas comuns

**`Address already in use`** — já existe um AsaasDeck rodando; abra <http://localhost:7070>. Se for
outro processo, use `ASAAS_DECK_PORT=7071 asaas-deck`.

**`asaas-deck: command not found`** — `~/.local/bin` não está no `PATH`. Abra um terminal novo ou
rode `source ~/.zshrc`.

**Botão Iniciar não faz nada** — falta autorização de Automação para o terminal (a mensagem no
painel diz isso). Libere em Ajustes do Sistema > Privacidade e Segurança > Automação.

**Dependências em vermelho** — banco e cache não estão de pé. Se a linha do Docker também
estiver fora, resolva o Docker primeiro: o estado mostrado diz o que fazer, e o botão **Reiniciar
Docker** cobre o caso da VM congelada.

**Status fica em "iniciando" por muito tempo** — normal depois de uma limpeza: um build completo
leva vários minutos. Acompanhe na janela do terminal.

**O log não atualiza** — o backend em execução escreve no arquivo aberto quando ele subiu. Se o
`backend.log` foi substituído no meio do caminho, o log volta a aparecer no próximo Iniciar.

## Licença

MIT — veja [LICENSE](LICENSE).
