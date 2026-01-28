<p align="center">
  <img src="assets/migration-banner.jpg" alt="ClawdBot → MoltBot Migration" width="100%">
</p>

> # ⚠️ Clawdbot está sendo renomeado para **Moltbot**
> 
> Estamos trabalhando em uma versão atualizada. Quando estiver estável, o novo repositório será disponibilizado para migração.
> 
> **Enquanto isso, continue usando este repositório (docker-clawdbot) normalmente.**

---

<p align="center">
  <img src="assets/clawdbot-banner.jpg" alt="Clawdbot - AI Assistant" width="100%">
</p>

# 🦞 Docker Clawdbot

Setup Docker para [Clawdbot](https://docs.clawd.bot) — assistente pessoal de IA com hardening de segurança pronto pra usar.

<p align="center">
  <img src="assets/clawdbot-robot.jpg" alt="Clawdbot Robot" width="300">
</p>

## Funcionalidades

- 🔒 **Segurança reforçada** — segue o [Top 10 Security Checklist](SECURITY.md)
- 🐳 **Setup com um comando** — `docker compose up -d`
- 🔐 **Secrets via variáveis de ambiente** — sem credenciais em texto puro
- 👤 **Container não-root** — roda como usuário sem privilégios
- 📝 **Logging habilitado** — trilha de auditoria por padrão
- 📱 **Pronto pra Telegram** — só adicionar o token do bot
- 🎙️ **Transcrição de áudio** — Faster Whisper incluso (opcional)
- 🪟 **Compatível com Windows** — `.gitattributes` força finais LF, Dockerfile corrige CRLF

## Início Rápido

### Pré-requisitos

| Plataforma | Requisito | Instalação |
|------------|-----------|------------|
| **Windows** | Docker Desktop | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |
| **Windows** | Git | [git-scm.com](https://git-scm.com/download/win) |
| **Mac** | Docker Desktop | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |
| **Linux** | Docker Engine + Compose | `curl -fsSL https://get.docker.com \| sh` |

> ⚠️ **Usuários Windows:** Certifique-se de que o **Docker Desktop está rodando** antes de continuar. Verifique o ícone do Docker na bandeja do sistema. Se o WSL mostrar `docker-desktop Stopped`, abra o Docker Desktop e aguarde ele iniciar.

### 1. Clone o repo

**Linux / Mac:**
```bash
git clone https://github.com/inematds/docker-clawdbot.git
cd docker-clawdbot
```

**Windows (CMD ou PowerShell):**
```cmd
git clone https://github.com/inematds/docker-clawdbot.git
cd docker-clawdbot
```

### 2. Configure o ambiente

**Linux / Mac:**
```bash
cp .env.example .env
nano .env  # Fill in your API keys
```

**Windows (CMD):**
```cmd
copy .env.example .env
notepad .env
```

**Windows (PowerShell):**
```powershell
Copy-Item .env.example .env
notepad .env
```

> ⚠️ **Importante:** Você DEVE criar E editar o arquivo `.env` antes de rodar `docker compose up`.

Abra o arquivo `.env` e substitua os valores placeholder pelas suas chaves reais:

```env
# ❌ ERRADO (placeholder — não vai funcionar):
ANTHROPIC_API_KEY=sk-ant-your-key-here

# ✅ CERTO (sua chave real):
ANTHROPIC_API_KEY=sk-ant-abc123-your-actual-key
```

**Mínimo pra começar:** Você precisa de pelo menos uma chave de provedor LLM (veja a tabela acima) e um token de gateway.

Pra gerar um token de gateway seguro:
```bash
# Linux / Mac:
openssl rand -hex 24

# Windows (PowerShell):
-join ((1..48) | ForEach-Object { '{0:x}' -f (Get-Random -Max 16) })

# Or just use any long random string (at least 24 characters)
```

**Obrigatórios:**
- `GATEWAY_AUTH_TOKEN` — gere com `openssl rand -hex 24`
- **Um provedor LLM** (escolha um ou mais):

| Provedor | Variável de Ambiente | Obter Chave |
|----------|---------------------|-------------|
| Anthropic (Claude) | `ANTHROPIC_API_KEY` | [console.anthropic.com](https://console.anthropic.com/) |
| OpenAI (GPT) | `OPENAI_API_KEY` | [platform.openai.com](https://platform.openai.com/api-keys) |
| OpenRouter (multi-modelo) | `OPENROUTER_API_KEY` | [openrouter.ai](https://openrouter.ai/) |
| Google (Gemini) | `GOOGLE_API_KEY` | [ai.google.dev](https://ai.google.dev/) |

> 💡 **Dica:** O OpenRouter dá acesso a múltiplos modelos (Claude, GPT, Llama, Gemini) com uma única API key — incluindo modelos gratuitos.

**Opcionais:**
- `TELEGRAM_BOT_TOKEN` — pegue com o [@BotFather](https://t.me/BotFather)
- `BRAVE_API_KEY` — para busca na web

### 3. Build e execução
```bash
docker compose up -d
```

> 💡 **Primeira execução** leva alguns minutos pra fazer o build da imagem (baixa Node.js, FFmpeg, etc). As execuções seguintes são instantâneas.

> ⚠️ **Erro no Windows "pipe/dockerDesktopLinuxEngine"?** O Docker Desktop não está rodando. Abra ele pelo menu Iniciar e aguarde até mostrar "Docker is running", depois tente novamente.

### 4. Acesse o Webchat

Abra no seu navegador:
```
http://localhost:18789/chat
```

Quando solicitado, insira seu `GATEWAY_AUTH_TOKEN` do arquivo `.env` para autenticar.

> 💡 **Dica:** Você também pode acessar diretamente com: `http://localhost:18789/?token=SEU_TOKEN`

### 5. Verifique o status
```bash
docker compose logs -f
```

### 6. Configuração pós-instalação

Depois que o container estiver rodando, configure seu Clawdbot:

```bash
# Run the interactive setup wizard (API keys, channels, preferences)
docker compose exec -it clawdbot clawdbot configure

# Or just auto-fix detected issues (e.g. enable Telegram if token is set)
docker compose exec -it clawdbot clawdbot doctor --fix

# Check overall health
docker compose exec clawdbot clawdbot status
```

| Comando | O que faz |
|---------|-----------|
| `clawdbot configure` | Wizard interativo — configura API keys, canais (Telegram, WhatsApp, etc.), preferências de modelo |
| `clawdbot doctor --fix` | Auto-detecta e corrige problemas de config (ex: Telegram configurado mas não habilitado) |
| `clawdbot doctor` | Mesma verificação, mas só **mostra** os problemas sem corrigir |
| `clawdbot status` | Mostra status do gateway, canais conectados, info do modelo |

## Configuração do Telegram

1. Crie um bot com o [@BotFather](https://t.me/BotFather)
2. Adicione o token no `.env`:
   ```
   TELEGRAM_BOT_TOKEN=123456:ABC-your-token
   ```
3. Reinicie: `docker compose restart`
4. Mande uma mensagem pro seu bot — ele vai te dar um código de pareamento
5. Aprove dentro do container:
   ```bash
   docker compose exec clawdbot clawdbot pairing approve telegram <code>
   ```

## Segurança

Este setup implementa 7 de 10 medidas de hardening de segurança automaticamente. Veja [SECURITY.md](SECURITY.md) para o checklist completo e passos manuais.

### Padrões principais:
- Gateway faz bind apenas em `127.0.0.1`
- Política de DM requer aprovação de pareamento
- Arquivos de config têm `chmod 600`
- Container roda como não-root
- Logging e diagnósticos habilitados

## Volumes

| Volume | Finalidade |
|--------|------------|
| `clawdbot-data` | Dados de config e sessão |
| `clawdbot-workspace` | Workspace do agente (AGENTS.md, memória, etc) |
| `clawdbot-logs` | Arquivos de log (`/home/clawdbot/logs`) |

## Comandos Úteis

```bash
# View logs
docker compose logs -f

# Enter container shell
docker compose exec clawdbot bash

# Restart
docker compose restart

# Update Clawdbot
docker compose build --no-cache
docker compose up -d

# Check clawdbot status
docker compose exec clawdbot clawdbot status
```

## Isolamento de Rede

Por padrão, o container tem acesso à internet (necessário pras chamadas de API). Para isolamento total:

```yaml
# In docker-compose.yml, change:
networks:
  clawdbot-net:
    internal: true  # No internet access
```

⚠️ Isso bloqueia chamadas de API pra Anthropic/OpenAI. Use apenas se você tiver um setup de modelo local.

## Canais de Acesso

Múltiplas formas de interagir com seu Clawdbot de qualquer lugar:

| Canal | Tipo | Acesso | Configuração |
|-------|------|--------|--------------|
| 📱 **Telegram** | Mensageiro | Qualquer lugar (mobile/desktop) | Crie um bot via [@BotFather](https://t.me/BotFather) |
| 📲 **WhatsApp** | Mensageiro | Qualquer lugar (mobile/desktop) | Vincule via QR code (`clawdbot channels login`) |
| 💬 **Webchat** | Interface Web | Rede local / VPN | Integrado, roda na porta do gateway |
| 🌐 **Webchat (público)** | Interface Web | Qualquer lugar | Proxy reverso Nginx + certificado SSL |
| 🔒 **Tailscale** | VPN | Qualquer lugar (zero-trust) | Instale Tailscale no servidor + dispositivos |
| 💜 **Discord** | Mensageiro | Qualquer lugar | Crie um bot via Discord Developer Portal |
| 💼 **Slack** | Mensageiro | Qualquer lugar | Crie um Slack app + bot token |
| 🔵 **Signal** | Mensageiro | Qualquer lugar | Signal CLI ou dispositivo vinculado |
| 🟢 **Matrix** | Mensageiro | Qualquer lugar | Homeserver Matrix + conta de bot |

### Qual devo usar?

**Setup mais simples:** Telegram — um bot token e pronto.

**Mais privado:** Signal ou Tailscale + Webchat.

**Acesso de qualquer lugar sem apps extras:** Telegram + WhatsApp (você já tem eles no celular).

**Melhor pra times/trabalho:** Slack ou Discord.

**Acesso remoto mais seguro ao Webchat:** Tailscale — VPN zero-trust, sem portas abertas, funciona de qualquer rede.

### Multi-canal
Você pode habilitar **múltiplos canais simultaneamente**. Todos os canais compartilham o mesmo agente, memória e workspace. Mensagens de qualquer canal chegam no mesmo assistente.

⚠️ **Mensagens entre canais são restritas** por design — o bot não vaza dados entre canais.

## Acesso ao Webchat (Remoto)

O gateway faz bind em `127.0.0.1` (loopback). Para acessar o Webchat de outra máquina, use um **túnel SSH**:

```bash
# On your local machine (PC/Mac):
ssh -L 18789:localhost:18789 root@your-server-ip
```

Depois abra no seu navegador:
```
http://127.0.0.1:18789/chat
```

Essa é a forma mais segura de acessar a interface web remotamente — sem portas expostas, criptografado via SSH.

## WhatsApp: Dicas para Número Pessoal

Se você usar seu **número pessoal do WhatsApp** (modo self-chat), fique atento:

- ⚠️ Por padrão, qualquer pessoa que te mandar mensagem pode receber uma resposta de código de pareamento do bot
- ✅ **Solução:** Defina `dmPolicy: allowlist` com apenas seu número pra evitar isso:
```json
{
  "channels": {
    "whatsapp": {
      "selfChatMode": true,
      "dmPolicy": "allowlist",
      "allowFrom": ["+5511999999999"]
    }
  }
}
```
- 🔄 **Recomendado:** Migre pra um **número dedicado** o mais rápido possível pra um setup mais limpo

## Ferramentas e Skills Recomendadas

Turbine seu Clawdbot com essas ferramentas adicionais:

### 🛠 Ferramentas CLI

| Ferramenta | Instalação | Finalidade |
|------------|------------|------------|
| [Codex CLI](https://github.com/openai/codex) | `npm i -g @openai/codex` | Agente de código IA (OpenAI) |
| [agent-browser](https://github.com/vercel-labs/agent-browser) | `npm i -g agent-browser` | Automação de navegador headless pra agentes IA |
| FFmpeg | `apt install ffmpeg` | Processamento de áudio/vídeo |
| Faster Whisper | `pip install faster-whisper` | Transcrição de áudio local |

### 🎨 Serviços de API

| Serviço | Finalidade | Preço |
|---------|------------|-------|
| [OpenRouter](https://openrouter.ai) | Gateway pra múltiplos LLMs (modelos gratuitos disponíveis) | Tier gratuito + pay-per-use |
| [Kie.ai](https://kie.ai) | Geração de imagem, vídeo e música (Veo 3.1, Flux, Suno) | Créditos |
| [ElevenLabs](https://elevenlabs.io) | Text-to-speech (vozes realistas) | Tier gratuito + pago |
| [Gamma](https://gamma.app) | Apresentações e documentos com IA | Tier gratuito + pago |
| [HeyGen](https://heygen.com) | Avatares de vídeo com IA | Créditos |

### 📚 Skills (para Codex / Claude Code)

| Skill | Instalação | Finalidade |
|-------|------------|------------|
| [Remotion Skills](https://github.com/inematds/remotion-skills) | Copie para `.codex/skills/` | Crie vídeos programaticamente com React |

```bash
# Install Remotion Skills for Codex
git clone https://github.com/inematds/remotion-skills.git /tmp/remotion-skills
mkdir -p .codex/skills
cp -r /tmp/remotion-skills/skills/remotion .codex/skills/
```

### 🤖 Organização de LLMs

Estratégia recomendada de modelos:

| Modelo | Provedor | Caso de Uso | Custo |
|--------|----------|-------------|-------|
| Claude Opus 4.5 | Anthropic Max | Assistente principal (conversas, tarefas) | Plano mensal |
| gpt-5.2-codex | OpenAI ChatGPT Team | Geração de código (prioridade) | Plano mensal |
| Modelos gratuitos | OpenRouter | Sub-agentes, tarefas secundárias | Gratuito |

**Modelos gratuitos no OpenRouter:** DeepSeek R1, Llama 3.1 405B, Llama 3.3 70B, Gemini 2.0 Flash, Qwen3 Coder

## Requisitos

- Docker Engine 24+
- Docker Compose v2+
- Pelo menos 2GB de RAM (4GB recomendado com Whisper)

## Solução de Problemas

### Windows

| Erro | Causa | Solução |
|------|-------|---------|
| `open //./pipe/dockerDesktopLinuxEngine: O sistema não pode encontrar o arquivo` | Docker Desktop não está rodando | Abra o Docker Desktop e aguarde ele iniciar |
| `.env not found` | Arquivo de config faltando | Execute `copy .env.example .env` e edite com `notepad .env` |
| `the attribute version is obsolete` | Formato antigo do docker-compose | Ignore (inofensivo) ou atualize pra versão mais recente do docker-clawdbot |
| `WSL docker-desktop Stopped` | WSL não iniciou | Abra o Docker Desktop — ele inicia o WSL automaticamente |
| Build trava ou falha | RAM insuficiente | Garanta pelo menos 4GB alocados pro Docker (Settings → Resources) |

### Linux / Mac

| Erro | Causa | Solução |
|------|-------|---------|
| `permission denied` | Não está no grupo docker | Execute `sudo usermod -aG docker $USER` e depois faça logout/login |
| `port already in use` | Outro serviço na porta 18789 | Mude a porta no `docker-compose.yml` ou pare o outro serviço |
| `no space left on device` | Disco cheio | Execute `docker system prune -a` pra limpar imagens antigas |

### Docker / Container

| Erro | Causa | Solução |
|------|-------|---------|
| `exec entrypoint.sh: no such file or directory` | Finais de linha CRLF do Windows | Isso é corrigido automaticamente pelo `.gitattributes` e o Dockerfile. Se ainda acontecer: `git config core.autocrlf input` e clone novamente. Ou abra `entrypoint.sh` no VS Code, mude CRLF → LF (canto inferior direito), salve, rebuild. |
| `error: unknown option '--foreground'` | Dockerfile antigo usando comando errado | Atualize o Dockerfile — CMD deve ser `["clawdbot", "gateway", "run"]` (não `start --foreground`) |
| `npm error: spawn git ENOENT` | Git não instalado na imagem | Adicione `git` na linha `apt-get install` do Dockerfile |
| Container reiniciando em loop | Verifique `docker logs clawdbot` pro erro específico | Veja os erros acima |

### Geral

| Erro | Solução |
|------|---------|
| Bot não responde | Verifique os logs: `docker compose logs -f` |
| Erros de API | Verifique se as API keys no `.env` estão corretas |
| Não consegue acessar o Webchat | Use túnel SSH: `ssh -L 18789:localhost:18789 user@server` |

## Contribuindo

PRs são bem-vindas! Por favor siga o checklist de segurança em [SECURITY.md](SECURITY.md).

## Licença

MIT
