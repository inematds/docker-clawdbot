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

## Quick Start

### 1. Clone the repo
```bash
git clone https://github.com/inematds/docker-clawdbot.git
cd docker-clawdbot
```

### 2. Configure environment
```bash
cp .env.example .env
nano .env  # Fill in your API keys
```

**Required:**
- `ANTHROPIC_API_KEY` — get from [Anthropic Console](https://console.anthropic.com/)
- `GATEWAY_AUTH_TOKEN` — generate with `openssl rand -hex 24`

**Optional:**
- `TELEGRAM_BOT_TOKEN` — get from [@BotFather](https://t.me/BotFather)
- `OPENAI_API_KEY` — for Codex CLI / image generation
- `BRAVE_API_KEY` — for web search

### 3. Build and run
```bash
docker compose up -d
```

### 4. Check status
```bash
docker compose logs -f
```

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
| `clawdbot-logs` | Log files |

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

## Contributing

PRs welcome! Please follow the security checklist in [SECURITY.md](SECURITY.md).

## License

MIT
