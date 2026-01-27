# 🔒 Security Hardening Checklist

Based on the [Clawdbot Security Hardening Guide](https://docs.clawd.bot) — Top 10 vulnerabilities and fixes.

## Two Deployment Scenarios

This guide covers two distinct setups. Choose your scenario:

| | 🏠 Local Server | ☁️ Cloud VPS |
|---|---|---|
| **Physical access** | Yes — you control the hardware | No — shared datacenter |
| **Network exposure** | LAN only (behind your router) | Public IP, exposed to internet |
| **Attack surface** | Low — internal threats only | High — bots, scanners, brute-force |
| **SSH hardening** | Optional | **Critical** |
| **Firewall** | Recommended | **Required** |
| **Fail2Ban** | Optional | **Required** |
| **VPN/Tailscale** | Nice to have | Highly recommended |
| **Full disk encryption** | Recommended | Provider-dependent |

---

## 🏠 Local Server (Home / Office)

You have physical access to the machine. It sits behind your router/firewall.

### Threat model:
- Other devices on your LAN
- Someone with physical access
- Malware on your network

### Minimum security:
```
✅ Gateway bind: loopback (default)
✅ DM policy: pairing (default)
✅ Logging enabled
✅ Config permissions: chmod 600
✅ Docker container isolation
```

### Recommended extras:
```
🔹 Router: block port 18789 from outside (port forwarding OFF)
🔹 Set a strong user password
🔹 Enable automatic security updates:
    sudo apt-get install -y unattended-upgrades
    sudo dpkg-reconfigure -plow unattended-upgrades
🔹 Use Tailscale for remote access instead of exposing SSH
```

### What you can skip:
- Fail2Ban (no public SSH)
- Change SSH port (not exposed)

---

## 🏠🔒 Local Server — Maximum Security

Same physical access, but you want **enterprise-grade** protection. For sensitive data, compliance, or paranoia (the good kind).

### Threat model:
- Compromised device on your LAN
- Malware/ransomware spreading laterally
- Insider threats (shared office/lab)
- Physical theft of the machine
- Supply chain attacks (compromised dependencies)

### 🛡️ Full hardening:

#### 1. Network Isolation
```bash
# Firewall even on LAN
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24 to any port 22  # SSH only from your LAN
sudo ufw deny 18789/tcp
sudo ufw --force enable

# Dedicated VLAN for the server (configure on your router)
# Isolates Clawdbot from IoT, guests, etc.
```

#### 2. SSH Hardening
```bash
# Key-only auth
ssh-keygen -t ed25519 -C "local-admin"
ssh-copy-id user@server-local-ip

# Disable password + root login
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sudo systemctl restart sshd
```

#### 3. Full Disk Encryption (LUKS)
Protects against physical theft:
```bash
# Best done during OS install
# If already installed, encrypt data partition:
sudo cryptsetup luksFormat /dev/sdX
sudo cryptsetup luksOpen /dev/sdX clawdbot-data
sudo mkfs.ext4 /dev/mapper/clawdbot-data
```

#### 4. Docker with AppArmor/SELinux
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

#### 5. Automatic Security Updates
```bash
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

#### 6. Audit & Monitoring
```bash
# Install auditd for system-level auditing
sudo apt-get install -y auditd
sudo systemctl enable auditd

# Monitor file changes on sensitive paths
sudo auditctl -w /home/clawdbot/.clawdbot/ -p rwa -k clawdbot-config
sudo auditctl -w /root/.ssh/ -p rwa -k ssh-keys

# Log rotation (keep 90 days)
cat > /etc/logrotate.d/clawdbot << 'LOGROTATE'
/tmp/clawdbot/*.log {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
}
LOGROTATE
```

#### 7. Network Monitoring
```bash
# Install and enable intrusion detection
sudo apt-get install -y tripwire aide

# Monitor outbound connections
sudo apt-get install -y nethogs
# Run: sudo nethogs — shows which processes use bandwidth
```

#### 8. Backup Encryption
```bash
# Encrypted backup of Clawdbot data
tar czf - /home/clawdbot/.clawdbot /home/clawdbot/workspace | \
  gpg --symmetric --cipher-algo AES256 -o /backup/clawdbot-$(date +%Y%m%d).tar.gz.gpg
```

#### 9. USB/Physical Port Lockdown
```bash
# Disable USB storage (prevent data exfiltration via USB)
echo "blacklist usb-storage" | sudo tee /etc/modprobe.d/disable-usb-storage.conf
sudo update-initramfs -u

# BIOS/UEFI password (set manually)
# Disable boot from USB/CD in BIOS
```

#### 10. Tailscale for Remote Access
```bash
# Zero-trust network — no open ports needed
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Access only via Tailscale IP
# Block ALL incoming on public interface:
sudo ufw default deny incoming
sudo ufw allow in on tailscale0
```

### Security Level Comparison

| Measure | Basic | Maximum |
|---------|-------|---------|
| Gateway loopback | ✅ | ✅ |
| DM pairing | ✅ | ✅ |
| Logging | ✅ | ✅ |
| chmod 600 | ✅ | ✅ |
| UFW firewall | ❌ | ✅ |
| SSH key-only | ❌ | ✅ |
| Disk encryption | ❌ | ✅ |
| AppArmor/SELinux | ❌ | ✅ |
| Auditd | ❌ | ✅ |
| Network monitoring | ❌ | ✅ |
| USB lockdown | ❌ | ✅ |
| Encrypted backups | ❌ | ✅ |
| VLAN isolation | ❌ | ✅ |
| Tailscale zero-trust | ❌ | ✅ |
| Auto-updates | ❌ | ✅ |

---

## ☁️ Cloud VPS (Hetzner, DigitalOcean, AWS, etc.)

Your server has a **public IP**. It's under constant attack from automated scanners.

### Threat model:
- SSH brute-force bots (thousands per day)
- Port scanners looking for open services
- API token theft if config is exposed
- Prompt injection from web content

### 🚨 Required security (do ALL of these):

#### 1. Firewall (UFW)
```bash
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
# Only allow specific ports you need:
# sudo ufw allow 443/tcp    # HTTPS if serving web
sudo ufw deny 18789/tcp     # Block gateway port externally
sudo ufw --force enable
sudo ufw status
```

#### 2. SSH Key-Only Authentication
⚠️ **Do this in order or you WILL lose access!**

```bash
# Step 1: On your LOCAL machine, generate a key (if you don't have one)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Step 2: Copy your public key to the server
ssh-copy-id user@your-server-ip
# Or manually:
# echo "your-public-key" >> ~/.ssh/authorized_keys
# chmod 600 ~/.ssh/authorized_keys

# Step 3: TEST key login from a NEW terminal (don't close the current one!)
ssh user@your-server-ip

# Step 4: Only after confirming key login works:
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo systemctl restart sshd
```

#### 3. Fail2Ban (anti brute-force)
```bash
sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status:
sudo fail2ban-client status sshd
```

#### 4. Automatic Security Updates
```bash
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

#### 5. Change Default SSH Port (optional, reduces noise)
```bash
# In /etc/ssh/sshd_config, change:
# Port 22
Port 2222    # Or any port between 1024-65535

# Don't forget to update UFW:
sudo ufw allow 2222/tcp
sudo ufw delete allow OpenSSH
sudo systemctl restart sshd
```

#### 6. Remote Access via Tailscale (recommended)
Instead of exposing SSH to the internet:
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# Now access via Tailscale IP only — block SSH from public
```

---

## Clawdbot-Specific Hardening

These apply to **both** scenarios:

### Status

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

### What This Docker Setup Does Automatically:
- **Gateway binds to loopback** — not exposed to the internet
- **Credentials via env vars** — never stored in plaintext config
- **Config file permissions** — chmod 600 on startup
- **Non-root user** — container runs as `clawdbot` user
- **No new privileges** — `security_opt: no-new-privileges`
- **Logging enabled** — info level + diagnostics by default
- **DM pairing mode** — users must be approved before chatting

### Manual Steps Needed:
- Configure `AGENTS.md` to block dangerous commands
- Set Docker network to `internal: true` if full isolation is needed
- Review and restrict MCP tool access
- Set up prompt injection protection for web content

---

## Environment Variables

All secrets are passed via environment variables. **Never** put API keys or tokens directly in config files.

See `.env.example` for all available variables.

---

## Quick Security Audit

Run inside the container:
```bash
# Check config permissions
stat -c '%a' ~/.clawdbot/clawdbot.json
# Should be: 600

# Check gateway binding
grep -o '"bind":"[^"]*"' ~/.clawdbot/clawdbot.json
# Should be: "bind":"lan" (required inside Docker for port mapping)
# The docker-compose.yml restricts external access to 127.0.0.1

# Check DM policy
grep -o '"dmPolicy":"[^"]*"' ~/.clawdbot/clawdbot.json
# Should be: "dmPolicy":"pairing"

# Check logging
grep -o '"level":"[^"]*"' ~/.clawdbot/clawdbot.json
# Should be: "level":"info"
```

Run on the host (VPS only):
```bash
# Check firewall
sudo ufw status

# Check SSH config
grep "PasswordAuthentication" /etc/ssh/sshd_config

# Check fail2ban
sudo fail2ban-client status sshd

# Check open ports
ss -tlnp | grep -E '18789|22'
```
