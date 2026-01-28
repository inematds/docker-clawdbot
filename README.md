<p align="center">
  <img src="assets/migration-banner.jpg" alt="ClawdBot → MoltBot Migration" width="100%">
</p>

> # ⚠️🚨 THIS PROJECT HAS MOVED 🚨⚠️
> 
> ## Clawdbot has been renamed to **Moltbot**
> 
> **This repository is archived and no longer maintained.**
> 
> ### 👉 New repository: [docker-moltbot](https://github.com/inematds/docker-moltbot)
> 
> All future updates, bug fixes, and security patches will be in the new repo.
> 
> #### Migration:
> ```bash
> # Clone the new repo
> git clone https://github.com/inematds/docker-moltbot.git
> cd docker-moltbot
> cp /path/to/old/.env .env
> docker compose up -d
> ```
> 
> **The `clawdbot` npm package still works as a compatibility shim, but will eventually be removed.**
> 
> ---

<p align="center">
  <img src="assets/clawdbot-banner.jpg" alt="Clawdbot - AI Assistant" width="100%">
</p>

# 🦞 Docker Clawdbot

Docker setup for [Clawdbot](https://docs.clawd.bot) — AI personal assistant with security hardening out of the box.

<p align="center">
  <img src="assets/clawdbot-robot.jpg" alt="Clawdbot Robot" width="300">
</p>

## Features

- 🔒 **Security hardened** — follows the [Top 10 Security Checklist](SECURITY.md)
- 🐳 **One command setup** — `docker compose up -d`
- 🔐 **Secrets via env vars** — no plaintext credentials
- 👤 **Non-root container** — runs as unprivileged user
- 📝 **Logging enabled** — audit trail by default
- 📱 **Telegram ready** — just add your bot token
- 🎙️ **Audio transcription** — Faster Whisper included (optional)
- 🪟 **Windows compatible** — `.gitattributes` enforces LF endings, Dockerfile fixes CRLF

## Quick Start

### Prerequisites

| Platform | Requirement | Install |
|----------|------------|---------|
| **Windows** | Docker Desktop | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |
| **Windows** | Git | [git-scm.com](https://git-scm.com/download/win) |
| **Mac** | Docker Desktop | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |
| **Linux** | Docker Engine + Compose | `curl -fsSL https://get.docker.com \| sh` |

> ⚠️ **Windows users:** Make sure **Docker Desktop is running** before proceeding. Check the system tray for the Docker icon. If WSL shows `docker-desktop Stopped`, open Docker Desktop and wait for it to start.

### 1. Clone the repo

**Linux / Mac:**
```bash
git clone https://github.com/inematds/docker-clawdbot.git
cd docker-clawdbot
```

**Windows (CMD or PowerShell):**
```cmd
git clone https://github.com/inematds/docker-clawdbot.git
cd docker-clawdbot
```

### 2. Configure environment

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

> ⚠️ **Important:** You MUST create AND edit the `.env` file before running `docker compose up`.

Open the `.env` file and replace the placeholder values with your real keys:

```env
# ❌ WRONG (placeholder — won't work):
ANTHROPIC_API_KEY=sk-ant-your-key-here

# ✅ RIGHT (your real key):
ANTHROPIC_API_KEY=sk-ant-abc123-your-actual-key
```

**Minimum to get started:** You need at least one LLM provider key (see table above) and a gateway token.

To generate a secure gateway token:
```bash
# Linux / Mac:
openssl rand -hex 24

# Windows (PowerShell):
-join ((1..48) | ForEach-Object { '{0:x}' -f (Get-Random -Max 16) })

# Or just use any long random string (at least 24 characters)
```

**Required:**
- `GATEWAY_AUTH_TOKEN` — generate with `openssl rand -hex 24`
- **One LLM provider** (choose one or more):

| Provider | Env Variable | Get Key |
|----------|-------------|---------|
| Anthropic (Claude) | `ANTHROPIC_API_KEY` | [console.anthropic.com](https://console.anthropic.com/) |
| OpenAI (GPT) | `OPENAI_API_KEY` | [platform.openai.com](https://platform.openai.com/api-keys) |
| OpenRouter (multi-model) | `OPENROUTER_API_KEY` | [openrouter.ai](https://openrouter.ai/) |
| Google (Gemini) | `GOOGLE_API_KEY` | [ai.google.dev](https://ai.google.dev/) |

> 💡 **Tip:** OpenRouter gives access to multiple models (Claude, GPT, Llama, Gemini) with a single API key — including free models.

**Optional:**
- `TELEGRAM_BOT_TOKEN` — get from [@BotFather](https://t.me/BotFather)
- `BRAVE_API_KEY` — for web search

### 3. Build and run
```bash
docker compose up -d
```

> 💡 **First run** takes a few minutes to build the image (downloads Node.js, FFmpeg, etc). Subsequent runs are instant.

> ⚠️ **Windows error "pipe/dockerDesktopLinuxEngine"?** Docker Desktop is not running. Open it from the Start menu and wait until it shows "Docker is running", then retry.

### 4. Access the Webchat

Open in your browser:
```
http://localhost:18789/chat
```

When prompted, enter your `GATEWAY_AUTH_TOKEN` from the `.env` file to authenticate.

> 💡 **Tip:** You can also access directly with: `http://localhost:18789/?token=YOUR_TOKEN`

### 5. Check status
```bash
docker compose logs -f
```

### 6. Post-install setup

After the container is running, configure your Clawdbot:

```bash
# Run the interactive setup wizard (API keys, channels, preferences)
docker compose exec -it clawdbot clawdbot configure

# Or just auto-fix detected issues (e.g. enable Telegram if token is set)
docker compose exec -it clawdbot clawdbot doctor --fix

# Check overall health
docker compose exec clawdbot clawdbot status
```

| Command | What it does |
|---------|-------------|
| `clawdbot configure` | Interactive wizard — set up API keys, channels (Telegram, WhatsApp, etc.), model preferences |
| `clawdbot doctor --fix` | Auto-detect and fix config issues (e.g. Telegram configured but not enabled) |
| `clawdbot doctor` | Same check, but only **shows** issues without fixing |
| `clawdbot status` | Show gateway status, connected channels, model info |

## Telegram Setup

1. Create a bot with [@BotFather](https://t.me/BotFather)
2. Add the token to `.env`:
   ```
   TELEGRAM_BOT_TOKEN=123456:ABC-your-token
   ```
3. Restart: `docker compose restart`
4. Message your bot — it will give you a pairing code
5. Approve inside the container:
   ```bash
   docker compose exec clawdbot clawdbot pairing approve telegram <code>
   ```

## Security

This setup implements 7 out of 10 security hardening measures automatically. See [SECURITY.md](SECURITY.md) for the full checklist and manual steps.

### Key defaults:
- Gateway binds to `127.0.0.1` only
- DM policy requires pairing approval
- Config files are `chmod 600`
- Container runs as non-root
- Logging and diagnostics enabled

## Volumes

| Volume | Purpose |
|--------|---------|
| `clawdbot-data` | Config and session data |
| `clawdbot-workspace` | Agent workspace (AGENTS.md, memory, etc) |
| `clawdbot-logs` | Log files (`/home/clawdbot/logs`) |

## Useful Commands

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

## Network Isolation

By default, the container has internet access (needed for API calls). For full isolation:

```yaml
# In docker-compose.yml, change:
networks:
  clawdbot-net:
    internal: true  # No internet access
```

⚠️ This blocks API calls to Anthropic/OpenAI. Only use if you have a local model setup.

## Access Channels

Multiple ways to interact with your Clawdbot from anywhere:

| Channel | Type | Access | Setup |
|---------|------|--------|-------|
| 📱 **Telegram** | Messaging | Anywhere (mobile/desktop) | Create bot via [@BotFather](https://t.me/BotFather) |
| 📲 **WhatsApp** | Messaging | Anywhere (mobile/desktop) | Link via QR code (`clawdbot channels login`) |
| 💬 **Webchat** | Web UI | Local network / VPN | Built-in, runs on gateway port |
| 🌐 **Webchat (public)** | Web UI | Anywhere | Nginx reverse proxy + SSL certificate |
| 🔒 **Tailscale** | VPN | Anywhere (zero-trust) | Install Tailscale on server + devices |
| 💜 **Discord** | Messaging | Anywhere | Create bot via Discord Developer Portal |
| 💼 **Slack** | Messaging | Anywhere | Create Slack app + bot token |
| 🔵 **Signal** | Messaging | Anywhere | Signal CLI or linked device |
| 🟢 **Matrix** | Messaging | Anywhere | Matrix homeserver + bot account |

### Which should I use?

**Simplest setup:** Telegram — one bot token and you're done.

**Most private:** Signal or Tailscale + Webchat.

**Access from anywhere without extra apps:** Telegram + WhatsApp (you already have them on your phone).

**Best for teams/work:** Slack or Discord.

**Most secure remote access to Webchat:** Tailscale — zero-trust VPN, no open ports, works from any network.

### Multi-channel
You can enable **multiple channels simultaneously**. All channels share the same agent, memory, and workspace. Messages from any channel arrive in the same assistant.

⚠️ **Cross-channel messaging is restricted** by design — the bot won't leak data between channels.

## Webchat Access (Remote)

The gateway binds to `127.0.0.1` (loopback). To access the Webchat from another machine, use an **SSH tunnel**:

```bash
# On your local machine (PC/Mac):
ssh -L 18789:localhost:18789 root@your-server-ip
```

Then open in your browser:
```
http://127.0.0.1:18789/chat
```

This is the safest way to access the web interface remotely — no ports exposed, encrypted via SSH.

## WhatsApp: Personal Number Tips

If you use your **personal WhatsApp number** (self-chat mode), be aware:

- ⚠️ By default, anyone who messages you may receive a pairing code response from the bot
- ✅ **Fix:** Set `dmPolicy: allowlist` with only your number to prevent this:
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
- 🔄 **Recommended:** Switch to a **dedicated number** as soon as possible for a cleaner setup

## Recommended Tools & Skills

Enhance your Clawdbot with these additional tools:

### 🛠 CLI Tools

| Tool | Install | Purpose |
|------|---------|---------|
| [Codex CLI](https://github.com/openai/codex) | `npm i -g @openai/codex` | AI coding agent (OpenAI) |
| [agent-browser](https://github.com/vercel-labs/agent-browser) | `npm i -g agent-browser` | Headless browser automation for AI agents |
| FFmpeg | `apt install ffmpeg` | Audio/video processing |
| Faster Whisper | `pip install faster-whisper` | Local audio transcription |

### 🎨 API Services

| Service | Purpose | Pricing |
|---------|---------|---------|
| [OpenRouter](https://openrouter.ai) | Gateway to multiple LLMs (free models available) | Free tier + pay-per-use |
| [Kie.ai](https://kie.ai) | Image, video & music generation (Veo 3.1, Flux, Suno) | Credits |
| [ElevenLabs](https://elevenlabs.io) | Text-to-speech (realistic voices) | Free tier + paid |
| [Gamma](https://gamma.app) | AI presentations & documents | Free tier + paid |
| [HeyGen](https://heygen.com) | AI video avatars | Credits |

### 📚 Skills (for Codex / Claude Code)

| Skill | Install | Purpose |
|-------|---------|---------|
| [Remotion Skills](https://github.com/inematds/remotion-skills) | Copy to `.codex/skills/` | Create videos programmatically with React |

```bash
# Install Remotion Skills for Codex
git clone https://github.com/inematds/remotion-skills.git /tmp/remotion-skills
mkdir -p .codex/skills
cp -r /tmp/remotion-skills/skills/remotion .codex/skills/
```

### 🤖 LLM Organization

Recommended model strategy:

| Model | Provider | Use Case | Cost |
|-------|----------|----------|------|
| Claude Opus 4.5 | Anthropic Max | Main assistant (conversations, tasks) | Monthly plan |
| gpt-5.2-codex | OpenAI ChatGPT Team | Code generation (priority) | Monthly plan |
| Free models | OpenRouter | Sub-agents, secondary tasks | Free |

**Free models on OpenRouter:** DeepSeek R1, Llama 3.1 405B, Llama 3.3 70B, Gemini 2.0 Flash, Qwen3 Coder

## Requirements

- Docker Engine 24+
- Docker Compose v2+
- At least 2GB RAM (4GB recommended with Whisper)

## Troubleshooting

### Windows

| Error | Cause | Fix |
|-------|-------|-----|
| `open //./pipe/dockerDesktopLinuxEngine: O sistema não pode encontrar o arquivo` | Docker Desktop not running | Open Docker Desktop and wait for it to start |
| `.env not found` | Missing config file | Run `copy .env.example .env` and edit with `notepad .env` |
| `the attribute version is obsolete` | Old docker-compose format | Ignore (harmless) or update to latest docker-clawdbot |
| `WSL docker-desktop Stopped` | WSL not started | Open Docker Desktop — it starts WSL automatically |
| Build hangs or fails | Not enough RAM | Ensure at least 4GB allocated to Docker (Settings → Resources) |

### Linux / Mac

| Error | Cause | Fix |
|-------|-------|-----|
| `permission denied` | Not in docker group | Run `sudo usermod -aG docker $USER` then log out/in |
| `port already in use` | Another service on 18789 | Change port in `docker-compose.yml` or stop the other service |
| `no space left on device` | Disk full | Run `docker system prune -a` to clean old images |

### Docker / Container

| Error | Cause | Fix |
|-------|-------|-----|
| `exec entrypoint.sh: no such file or directory` | Windows CRLF line endings | This is auto-fixed by `.gitattributes` and the Dockerfile. If it still happens: `git config core.autocrlf input` then re-clone. Or open `entrypoint.sh` in VS Code, change CRLF → LF (bottom-right), save, rebuild. |
| `error: unknown option '--foreground'` | Old Dockerfile using wrong command | Update Dockerfile — CMD should be `["clawdbot", "gateway", "run"]` (not `start --foreground`) |
| `npm error: spawn git ENOENT` | Git not installed in image | Add `git` to `apt-get install` line in Dockerfile |
| Container keeps restarting | Check `docker logs clawdbot` for the specific error | See errors above |

### General

| Error | Fix |
|-------|-----|
| Bot not responding | Check logs: `docker compose logs -f` |
| API errors | Verify API keys in `.env` are correct |
| Can't access Webchat | Use SSH tunnel: `ssh -L 18789:localhost:18789 user@server` |

## Contributing

PRs welcome! Please follow the security checklist in [SECURITY.md](SECURITY.md).

## License

MIT
