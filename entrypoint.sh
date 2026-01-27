#!/bin/bash
set -e

CONFIG_DIR="$HOME/.clawdbot"
CONFIG_FILE="$CONFIG_DIR/clawdbot.json"

# Create config from template if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
  echo "🦞 First run — creating config from template..."
  cp "$CONFIG_DIR/clawdbot.json.template" "$CONFIG_FILE" 2>/dev/null || true
fi

# Inject environment variables into config
if [ -n "$GATEWAY_AUTH_TOKEN" ]; then
  echo "🔑 Setting gateway auth token..."
  node -e "
    const fs = require('fs');
    const cfg = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
    cfg.gateway = cfg.gateway || {};
    cfg.gateway.auth = cfg.gateway.auth || {};
    cfg.gateway.auth.token = process.env.GATEWAY_AUTH_TOKEN;
    fs.writeFileSync('$CONFIG_FILE', JSON.stringify(cfg, null, 2));
  "
fi

if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  echo "📱 Enabling Telegram..."
  node -e "
    const fs = require('fs');
    const cfg = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
    cfg.channels = cfg.channels || {};
    cfg.channels.telegram = cfg.channels.telegram || {};
    cfg.channels.telegram.enabled = true;
    cfg.channels.telegram.botToken = process.env.TELEGRAM_BOT_TOKEN;
    cfg.channels.telegram.dmPolicy = 'pairing';
    cfg.channels.telegram.groupPolicy = 'allowlist';
    fs.writeFileSync('$CONFIG_FILE', JSON.stringify(cfg, null, 2));
  "
fi

# Set proper permissions
chmod 600 "$CONFIG_FILE" 2>/dev/null || true

echo "🦞 Starting Clawdbot..."
exec "$@"
