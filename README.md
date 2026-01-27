# 🦞 Docker Clawdbot

Docker setup for [Clawdbot](https://docs.clawd.bot) — AI personal assistant with security hardening out of the box.

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

## Requirements

- Docker Engine 24+
- Docker Compose v2+
- At least 2GB RAM (4GB recommended with Whisper)

## Contributing

PRs welcome! Please follow the security checklist in [SECURITY.md](SECURITY.md).

## License

MIT
