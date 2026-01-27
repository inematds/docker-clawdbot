> **⚠️ This project has moved to [docker-moltbot](https://github.com/inematds/docker-moltbot).** All future security updates will be in the new repo.

---

# 🔒 Security Guide

Comprehensive security reference for Clawdbot (now Moltbot). Based on the [official security documentation](https://docs.clawd.bot/gateway/security).

> **Running an AI agent with shell access on your machine is… spicy.**
> There is no "perfectly secure" setup. The goal is to be deliberate about who can talk to your bot, where the bot is allowed to act, and what the bot can touch.

---

## Table of Contents

- [Quick Security Audit](#quick-security-audit)
- [Known Vulnerabilities](#known-vulnerabilities)
  1. [Prompt Injection](#1-prompt-injection)
  2. [Remote Shell Access](#2-remote-shell-access)
  3. [Session Logs in Plaintext](#3-session-logs-in-plaintext)
  4. [Plugins Run In-Process](#4-plugins-run-in-process)
  5. [WhatsApp with Personal Number](#5-whatsapp-with-personal-number)
  6. [Node Execution (system.run)](#6-node-execution-systemrun)
  7. [Browser Control Exposure](#7-browser-control-exposure)
  8. [Network Exposure](#8-network-exposure)
  9. [Reverse Proxy Misconfiguration](#9-reverse-proxy-misconfiguration)
  10. [Credential Storage Locations](#10-credential-storage-locations)
  11. [Dynamic Skills as Trusted Code](#11-dynamic-skills-as-trusted-code)
- [Threat Model Summary](#threat-model-summary)
- [Deployment Scenarios](#deployment-scenarios)
- [Docker-Specific Hardening](#docker-specific-hardening)
- [Incident Response](#incident-response)

---

## Quick Security Audit

Run this regularly, especially after config changes:

```bash
# Inside the container:
docker compose exec clawdbot clawdbot security audit
docker compose exec clawdbot clawdbot security audit --deep
docker compose exec clawdbot clawdbot security audit --fix
```

The audit checks:
- **Inbound access**: DM policies, group policies, allowlists — can strangers trigger the bot?
- **Tool blast radius**: elevated tools + open rooms — could prompt injection escalate to shell/file/network?
- **Network exposure**: Gateway bind/auth, Tailscale Serve/Funnel
- **Browser control exposure**: remote nodes, relay ports, remote CDP endpoints
- **Local disk hygiene**: permissions, symlinks, config includes
- **Plugins**: extensions without explicit allowlists
- **Model hygiene**: warns about legacy/weak models

`--fix` applies safe guardrails automatically:
- Tightens `groupPolicy="open"` → `groupPolicy="allowlist"`
- Resets `logging.redactSensitive="off"` → `"tools"`
- Fixes permissions: `~/.clawdbot → 700`, config → `600`, credentials `*.json` → `600`

---

## Known Vulnerabilities

### 1. Prompt Injection

| | |
|---|---|
| **Risk** | 🔴 **HIGH** |
| **What** | Attacker crafts messages that manipulate the AI model into unsafe actions: "ignore your instructions", "dump your filesystem", "run this command", etc. |
| **Why it matters** | Even with strong system prompts, prompt injection is **not solved**. When tools are enabled, the risk escalates from information disclosure to arbitrary code execution. |
| **Key insight** | **Prompt injection does NOT require public DMs.** Even if only you can message the bot, injection can happen via any untrusted content the bot reads: web search results, browser pages, emails, docs, attachments, pasted code/logs. The sender is not the only threat surface — the **content itself** can carry adversarial instructions. |

**Mitigation:**
- Keep inbound DMs locked down (`dmPolicy: pairing` or `allowlist`)
- Prefer mention gating in groups; avoid "always-on" bots in public rooms
- Treat links, attachments, and pasted instructions as hostile by default
- Run sensitive tool execution in a sandbox; keep secrets out of the agent's reachable filesystem
- Limit high-risk tools (`exec`, `browser`, `web_fetch`, `web_search`) to trusted agents
- Use a **read-only or tool-disabled reader agent** to summarize untrusted content, then pass the summary to your main agent
- Keep secrets out of prompts; pass them via env/config on the gateway host
- **Use strong models**: Prefer the latest generation, best-tier model (e.g., Anthropic Opus 4.5) for tool-enabled agents. Avoid weaker/cheaper models for agents with tools or untrusted inboxes — they are significantly more susceptible to tool misuse and instruction hijacking

---

### 2. Remote Shell Access

| | |
|---|---|
| **Risk** | 🔴 **HIGH** |
| **What** | The bot can execute arbitrary shell commands on the host machine. This means anyone who can influence the bot's behavior has effective root/user-level shell access. |
| **Why it matters** | Combined with prompt injection, this turns text messages into remote code execution. A single manipulated message could `rm -rf`, exfiltrate data, install malware, or pivot to other systems. |

**Mitigation:**
- Configure `AGENTS.md` to explicitly block dangerous commands (`rm -rf /`, `curl | sh`, `git push --force`, etc.)
- Enable sandbox mode — when off, `exec` runs on the gateway host directly
- Set `tools.exec.host` to `sandbox` and configure exec approvals for host execution
- Restrict which tools are available per agent
- Use `no-new-privileges` Docker security option (included in this setup)
- Run the container as a non-root user (included in this setup)
- Consider Docker network isolation (`internal: true`) to prevent network pivoting

---

### 3. Session Logs in Plaintext

| | |
|---|---|
| **Risk** | 🟡 **MEDIUM** |
| **What** | Session transcripts are stored on disk as plaintext JSONL files at `~/.clawdbot/agents/<agentId>/sessions/*.jsonl`. |
| **Why it matters** | Any process or user with filesystem access can read complete conversation histories, including sensitive data discussed with the bot. This is required for session continuity and memory indexing, but creates a data exposure risk. |

**Mitigation:**
- Treat disk access as the trust boundary
- Lock down permissions on `~/.clawdbot/` (run `security audit --fix`)
- For stronger agent isolation, run agents under separate OS users or separate hosts
- Use full disk encryption (LUKS) to protect against physical theft
- Set up encrypted backups:
  ```bash
  tar czf - ~/.clawdbot | gpg --symmetric --cipher-algo AES256 -o backup.tar.gz.gpg
  ```
- Consider `logging.redactSensitive: "tools"` to redact sensitive tool output from logs
- Monitor filesystem access with `auditd`:
  ```bash
  sudo auditctl -w /home/clawdbot/.clawdbot/ -p rwa -k clawdbot-config
  ```

---

### 4. Plugins Run In-Process

| | |
|---|---|
| **Risk** | 🟡 **MEDIUM** |
| **What** | Plugins/extensions run in the same process as the Gateway. A malicious or buggy plugin has full access to the Gateway's memory, credentials, and capabilities. |
| **Why it matters** | Installing a plugin from npm (`clawdbot plugins install <pkg>`) is equivalent to running untrusted code. npm lifecycle scripts can execute code during install. A compromised plugin can read all secrets, intercept messages, or modify bot behavior silently. |

**Mitigation:**
- Only install plugins from sources you trust
- Use explicit `plugins.allow` allowlists
- Review plugin code before enabling — inspect unpacked code on disk at `~/.clawdbot/extensions/<name>/`
- Prefer pinned, exact versions (`@scope/plugin@1.2.3`)
- Restart the Gateway after plugin changes
- Review plugin config before enabling
- Audit installed plugins regularly

---

### 5. WhatsApp with Personal Number

| | |
|---|---|
| **Risk** | 🟡 **MEDIUM** |
| **What** | When using your personal WhatsApp number in self-chat mode, the bot monitors your WhatsApp account. By default, anyone who messages you may receive a pairing code response from the bot. |
| **Why it matters** | Friends, family, coworkers, or strangers messaging your number will unexpectedly interact with an AI bot. This can confuse contacts, leak the bot's existence, or allow unauthorized access if DM policy is too permissive. |

**Mitigation:**
- Set `dmPolicy: allowlist` with only your number:
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
- Switch to a **dedicated number** as soon as possible
- Set `groupPolicy: allowlist` to control which groups the bot responds in
- Avoid `dmPolicy: open` — it allows anyone to interact

---

### 6. Node Execution (system.run)

| | |
|---|---|
| **Risk** | 🔴 **HIGH** |
| **What** | If a macOS/mobile node is paired, the Gateway can invoke `system.run` on that node. This is **remote code execution** on the paired device. |
| **Why it matters** | A compromised bot or successful prompt injection could execute arbitrary commands on your Mac, phone, or other paired devices — potentially accessing files, cameras, location, and other system resources outside the container. |

**Mitigation:**
- On macOS: Settings → Exec approvals → set security to `deny` if you don't need remote execution
- Use `ask` mode to require manual approval for each execution
- Use `allowlist` mode to restrict which commands can run
- Remove node pairing for devices that don't need remote execution
- Treat node pairing tokens as critical secrets — rotate if compromised
- Audit paired nodes regularly: `clawdbot pairing list`

---

### 7. Browser Control Exposure

| | |
|---|---|
| **Risk** | 🟡 **MEDIUM** |
| **What** | The bot can control web browsers via remote CDP (Chrome DevTools Protocol) endpoints, relay ports, and remote nodes. This includes navigating pages, clicking elements, reading content, and executing JavaScript. |
| **Why it matters** | Browser control with authenticated sessions could allow the bot to perform actions on websites as you — reading emails, making purchases, accessing banking, etc. If exposed publicly, anyone could control the browser. |

**Mitigation:**
- Treat browser control like operator access — restrict to tailnet-only
- Pair nodes deliberately; avoid public exposure of CDP endpoints
- Don't expose relay ports to the public internet
- Use dedicated browser profiles without saved passwords/sessions for bot access
- The security audit checks for browser control exposure — run it regularly
- Avoid `controlUi.dangerouslyDisableDeviceAuth` (severe security downgrade)
- Prefer HTTPS (Tailscale Serve) or localhost-only for the Control UI

---

### 8. Network Exposure

| | |
|---|---|
| **Risk** | 🔴 **HIGH** |
| **What** | The Gateway HTTP server can be exposed to the network if misconfigured. Binding to `0.0.0.0` instead of `127.0.0.1` exposes the gateway (including auth endpoints, webchat, and API) to anyone who can reach the port. |
| **Why it matters** | On a cloud VPS with a public IP, this means the entire internet can probe your gateway. Even with auth, this massively increases attack surface. Combined with weak or missing gateway auth, this is a critical vulnerability. |

**Mitigation:**
- **This Docker setup binds to `127.0.0.1` by default** ✅
- Never bind to `0.0.0.0` on a public server
- Use `ufw deny 18789/tcp` to block the gateway port externally
- Use SSH tunnels for remote access:
  ```bash
  ssh -L 18789:localhost:18789 user@your-server
  ```
- Use Tailscale for zero-trust remote access (no open ports)
- Set a strong `GATEWAY_AUTH_TOKEN` (at least 24 random characters)
- On cloud VPS: enable firewall, Fail2Ban, SSH key-only auth

---

### 9. Reverse Proxy Misconfiguration

| | |
|---|---|
| **Risk** | 🟡 **MEDIUM** |
| **What** | When running behind a reverse proxy (nginx, Caddy, Traefik), misconfigured `trustedProxies` can lead to authentication bypass. Proxied connections may appear to come from localhost, receiving automatic trust. |
| **Why it matters** | An attacker could spoof `X-Forwarded-For` headers to appear as a local/trusted client, bypassing gateway authentication entirely. |

**Mitigation:**
- Configure `gateway.trustedProxies` explicitly:
  ```yaml
  gateway:
    trustedProxies:
      - "127.0.0.1"
    auth:
      mode: password
      password: ${CLAWDBOT_GATEWAY_PASSWORD}
  ```
- Ensure your proxy **overwrites** (not appends to) incoming `X-Forwarded-For` headers
- When trustedProxies is set, the Gateway uses `X-Forwarded-For` for real client IP detection
- Without trustedProxies, proxy headers from unknown addresses are rejected when auth is disabled
- Always set gateway auth when using a reverse proxy

---

### 10. Credential Storage Locations

| | |
|---|---|
| **Risk** | 🟡 **MEDIUM** |
| **What** | Credentials and tokens are stored in various locations on disk. Knowing these paths is essential for auditing, backup, and incident response. |
| **Why it matters** | If any of these files are world-readable or accessible to unauthorized users/processes, all connected services are compromised. |

**Credential map:**

| Credential | Location |
|---|---|
| WhatsApp auth | `~/.clawdbot/credentials/whatsapp/<id>/creds.json` |
| Telegram bot token | Config/env or `channels.telegram.tokenFile` |
| Discord bot token | Config/env |
| Slack tokens | Config/env (`channels.slack.*`) |
| Pairing allowlists | `~/.clawdbot/credentials/<channel>-allowFrom.json` |
| Model auth profiles | `~/.clawdbot/agents/<id>/agent/auth-profiles.json` |
| Legacy OAuth | `~/.clawdbot/credentials/oauth.json` |
| Session data | `~/.clawdbot/agents/<id>/sessions/sessions.json` |
| Gateway config | `~/.clawdbot/clawdbot.json` |

**Mitigation:**
- Run `clawdbot security audit --fix` to auto-fix permissions
- Ensure `~/.clawdbot/` is `700`, config files are `600`
- Pass secrets via environment variables, never hardcode in config files
- Use `.env` file with `chmod 600` (this Docker setup does this automatically)
- Back up credentials encrypted (GPG/age)
- Rotate tokens immediately if compromise is suspected

---

### 11. Dynamic Skills as Trusted Code

| | |
|---|---|
| **Risk** | 🟡 **MEDIUM** |
| **What** | Clawdbot can refresh skills mid-session via the skills watcher (changes to `SKILL.md` files) and remote node connections (macOS-only skills via bin probing). Skills define what tools and commands the bot can use. |
| **Why it matters** | If an attacker can modify skill files (via filesystem access, a compromised tool, or a manipulated bot action), they can inject new capabilities or commands into the bot's toolset. This is essentially code injection via configuration. |

**Mitigation:**
- Treat skill folders as **trusted code** — restrict who can modify them
- Lock down workspace filesystem permissions
- Monitor skill file changes with `auditd` or filesystem watches
- Review any new or modified `SKILL.md` files before they take effect
- Don't allow the bot to modify its own skill files in untrusted contexts
- Use `read_only: true` in Docker where possible

---

## Threat Model Summary

Your AI assistant can:
- ⚡ Execute arbitrary shell commands
- 📁 Read/write files on the host
- 🌐 Access network services
- 📱 Send messages to anyone (if given WhatsApp/Telegram/etc. access)
- 🖥️ Control web browsers
- 📲 Execute commands on paired devices (nodes)

People who message you can:
- 🎭 Try to trick the AI into unsafe actions (prompt injection)
- 🕵️ Social engineer access to your data
- 🔍 Probe for infrastructure details

**Core principle: Access control before intelligence**

Most failures are not fancy exploits — they're "someone messaged the bot and the bot did what they asked." Design so that even successful manipulation has limited blast radius.

---

## Deployment Scenarios

### 🏠 Local Server (Home / Office)

You have physical access. Machine is behind your router.

**Threat model:** Other LAN devices, physical access, network malware.

**Minimum security:**
```
✅ Gateway bind: loopback (default)
✅ DM policy: pairing (default)
✅ Logging enabled
✅ Config permissions: chmod 600
✅ Docker container isolation
```

**Recommended extras:**
- Block port 18789 on router (no port forwarding)
- Enable automatic security updates
- Use Tailscale for remote access

### ☁️ Cloud VPS

Public IP. Under constant automated attack.

**Threat model:** SSH brute-force, port scanners, API token theft, prompt injection from web.

**🚨 Required (do ALL):**
1. **Firewall (UFW):** `sudo ufw deny 18789/tcp`
2. **SSH key-only auth** (disable password login)
3. **Fail2Ban:** `sudo apt install fail2ban`
4. **Automatic security updates**
5. **Tailscale** for remote access (recommended over open SSH)

---

## Docker-Specific Hardening

### What This Setup Does Automatically

| Measure | Status |
|---|---|
| Gateway binds to `127.0.0.1` | ✅ Default |
| DM policy: pairing | ✅ Default |
| Credentials via env vars | ✅ `.env` |
| Config file permissions `600` | ✅ Entrypoint |
| Non-root container user | ✅ Dockerfile |
| `no-new-privileges` | ✅ Compose |
| Logging + diagnostics | ✅ Default |

### Manual Steps Needed

| Step | Priority |
|---|---|
| Configure `AGENTS.md` to block dangerous commands | 🔴 High |
| Review and restrict MCP tool access | 🔴 High |
| Set Docker network to `internal: true` (if full isolation needed) | 🟡 Medium |
| Set up prompt injection protection for web content | 🟡 Medium |
| Run `clawdbot security audit` regularly | 🟡 Medium |

### Maximum Docker Hardening

```yaml
# docker-compose.yml additions:
services:
  clawdbot:
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    read_only: true
    tmpfs:
      - /tmp:size=512M,noexec,nosuid
```

---

## Incident Response

If you suspect compromise (someone got into a room, a token leaked, a plugin did something unexpected):

### 1. Stop the blast radius
- Disable elevated tools or **stop the Gateway**
- Lock down inbound surfaces (DM policy, group allowlists, mention gating)

### 2. Rotate secrets
- Rotate `gateway.auth` token/password
- Rotate `hooks.token` if used
- Revoke suspicious node pairings
- Rotate model provider credentials (Anthropic/OpenAI/etc. API keys)
- Rotate channel tokens (Telegram, Discord, Slack)

### 3. Audit
- Review session logs: `~/.clawdbot/agents/*/sessions/*.jsonl`
- Check `clawdbot security audit --deep`
- Review installed plugins
- Check for unauthorized file modifications

### 4. Recover
- Rebuild container from clean image
- Restore config from encrypted backup
- Re-pair only trusted devices/users

---

## Quick Manual Audit

```bash
# Inside container:
# Check config permissions
stat -c '%a' ~/.clawdbot/clawdbot.json
# Should be: 600

# Check DM policy
grep -o '"dmPolicy":"[^"]*"' ~/.clawdbot/clawdbot.json
# Should be: "dmPolicy":"pairing"

# Check logging
grep -o '"level":"[^"]*"' ~/.clawdbot/clawdbot.json
# Should be: "level":"info"

# On the host (VPS):
sudo ufw status
grep "PasswordAuthentication" /etc/ssh/sshd_config
sudo fail2ban-client status sshd
ss -tlnp | grep -E '18789|22'
```

---

## Further Reading

- [Official Security Docs](https://docs.clawd.bot/gateway/security)
- [Configuration Reference](https://docs.clawd.bot/gateway/configuration)
- [Pairing Guide](https://docs.clawd.bot/start/pairing)
- [Plugin System](https://docs.clawd.bot/plugin)
- [Session Management](https://docs.clawd.bot/concepts/session)
