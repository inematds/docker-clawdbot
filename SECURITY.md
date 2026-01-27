# 🔒 Security Hardening Checklist

Based on the [Clawdbot Security Hardening Guide](https://docs.clawd.bot) — Top 10 vulnerabilities and fixes.

## Status

| # | Vulnerability | Fix | Status |
|---|--------------|-----|--------|
| 1 | Gateway exposed on 0.0.0.0:18789 | Bind to loopback only | ✅ Default |
| 2 | DM policy allows all users | Set dmPolicy to `pairing` | ✅ Default |
| 3 | Sandbox disabled by default | Docker container isolation | ✅ Docker |
| 4 | Credentials in plaintext | Environment variables + chmod 600 | ✅ Entrypoint |
| 5 | Prompt injection via web content | Wrap untrusted content in tags | ⚠️ Manual |
| 6 | Dangerous commands unblocked | Block rm -rf, curl pipes, git push --force | ⚠️ AGENTS.md |
| 7 | No network isolation | Docker network with `internal: true` option | ✅ Compose |
| 8 | Elevated tool access granted | Restrict MCP tools to minimum needed | ⚠️ Manual |
| 9 | No audit logging enabled | Logging + diagnostics enabled | ✅ Default |
| 10 | Weak/default pairing codes | Pairing mode with rate limiting | ✅ Default |

## What This Docker Setup Does

### Automatically secured:
- **Gateway binds to loopback** — not exposed to the internet
- **Credentials via env vars** — never stored in plaintext config
- **Config file permissions** — chmod 600 on startup
- **Non-root user** — container runs as `clawdbot` user
- **No new privileges** — `security_opt: no-new-privileges`
- **Logging enabled** — info level + diagnostics by default
- **DM pairing mode** — users must be approved before chatting

### Manual steps needed:
- Configure `AGENTS.md` to block dangerous commands
- Set Docker network to `internal: true` if full isolation is needed
- Review and restrict MCP tool access
- Set up prompt injection protection for web content

## Environment Variables

All secrets are passed via environment variables. **Never** put API keys or tokens directly in config files.

See `.env.example` for all available variables.

## Quick Security Audit

Run inside the container:
```bash
# Check config permissions
stat -c '%a' ~/.clawdbot/clawdbot.json
# Should be: 600

# Check gateway binding
grep -o '"bind":"[^"]*"' ~/.clawdbot/clawdbot.json
# Should be: "bind":"loopback"

# Check DM policy
grep -o '"dmPolicy":"[^"]*"' ~/.clawdbot/clawdbot.json
# Should be: "dmPolicy":"pairing"

# Check logging
grep -o '"level":"[^"]*"' ~/.clawdbot/clawdbot.json
# Should be: "level":"info"
```
