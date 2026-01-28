#!/bin/bash
set -e

CONFIG_DIR="$HOME/.clawdbot"
CONFIG_FILE="$CONFIG_DIR/clawdbot.json"

# Create config from template if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
  echo "🦞 First run — creating config from template..."
  cp "$CONFIG_DIR/clawdbot.json.template" "$CONFIG_FILE" 2>/dev/null || true
fi

# Helper: inject JSON value using Node.js
inject_json() {
  local file="$1" script="$2"
  node -e "
    const fs = require('fs');
    const cfg = JSON.parse(fs.readFileSync('$file', 'utf8'));
    $script
    fs.writeFileSync('$file', JSON.stringify(cfg, null, 2));
  "
}

# Inject GATEWAY_AUTH_TOKEN
if [ -n "$GATEWAY_AUTH_TOKEN" ]; then
  echo "🔑 Setting gateway auth token..."
  inject_json "$CONFIG_FILE" "
    cfg.gateway = cfg.gateway || {};
    cfg.gateway.auth = cfg.gateway.auth || {};
    cfg.gateway.auth.token = process.env.GATEWAY_AUTH_TOKEN;
  "
fi

# Inject Telegram bot token
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  echo "📱 Enabling Telegram..."
  inject_json "$CONFIG_FILE" "
    cfg.channels = cfg.channels || {};
    cfg.channels.telegram = cfg.channels.telegram || {};
    cfg.channels.telegram.enabled = true;
    cfg.channels.telegram.botToken = process.env.TELEGRAM_BOT_TOKEN;
    cfg.channels.telegram.dmPolicy = cfg.channels.telegram.dmPolicy || 'pairing';
    cfg.channels.telegram.groupPolicy = cfg.channels.telegram.groupPolicy || 'allowlist';
  "
fi

# Detect and configure LLM provider
# Priority: Anthropic direct > OpenRouter > OpenAI > Google
LLM_CONFIGURED=false

if [ -n "$ANTHROPIC_API_KEY" ] && [ "$ANTHROPIC_API_KEY" != "sk-ant-your-key-here" ]; then
  echo "🧠 Anthropic API key detected — using Anthropic direct"
  inject_json "$CONFIG_FILE" "
    cfg.auth = cfg.auth || {};
    cfg.auth.profiles = cfg.auth.profiles || {};
    cfg.auth.profiles['anthropic:default'] = { provider: 'anthropic', mode: 'token' };
  "
  LLM_CONFIGURED=true
elif [ -n "$OPENROUTER_API_KEY" ] && [ "$OPENROUTER_API_KEY" != "sk-or-your-key-here" ]; then
  echo "🧠 OpenRouter API key detected — using OpenRouter"
  inject_json "$CONFIG_FILE" "
    cfg.auth = cfg.auth || {};
    cfg.auth.profiles = cfg.auth.profiles || {};
    cfg.auth.profiles['openrouter:default'] = { provider: 'openrouter', mode: 'token' };
    cfg.auth.order = cfg.auth.order || {};
    cfg.auth.order['anthropic'] = ['openrouter:default'];
    cfg.auth.order['openai'] = ['openrouter:default'];
    cfg.auth.order['google'] = ['openrouter:default'];
  "
  LLM_CONFIGURED=true
elif [ -n "$OPENAI_API_KEY" ] && [ "$OPENAI_API_KEY" != "sk-your-key-here" ]; then
  echo "🧠 OpenAI API key detected — using OpenAI"
  inject_json "$CONFIG_FILE" "
    cfg.auth = cfg.auth || {};
    cfg.auth.profiles = cfg.auth.profiles || {};
    cfg.auth.profiles['openai:default'] = { provider: 'openai', mode: 'token' };
  "
  LLM_CONFIGURED=true
elif [ -n "$GOOGLE_API_KEY" ] && [ "$GOOGLE_API_KEY" != "your-key-here" ]; then
  echo "🧠 Google API key detected — using Google"
  inject_json "$CONFIG_FILE" "
    cfg.auth = cfg.auth || {};
    cfg.auth.profiles = cfg.auth.profiles || {};
    cfg.auth.profiles['google:default'] = { provider: 'google', mode: 'token' };
  "
  LLM_CONFIGURED=true
fi

if [ "$LLM_CONFIGURED" = "false" ]; then
  echo "⚠️  No valid LLM API key found! Set at least one in .env"
fi

# Docker requires binding to 0.0.0.0 inside the container for port mapping to work.
# The docker-compose.yml restricts external access to 127.0.0.1 on the host.
echo "🌐 Setting gateway bind to lan (required for Docker port mapping)..."
inject_json "$CONFIG_FILE" "
  cfg.gateway = cfg.gateway || {};
  cfg.gateway.bind = 'lan';
"

# Configure logging
echo "📝 Configuring logging..."
inject_json "$CONFIG_FILE" "
  cfg.logging = cfg.logging || {};
  cfg.logging.level = cfg.logging.level || 'info';
"

# Set proper permissions on config (secrets inside)
chmod 600 "$CONFIG_FILE" 2>/dev/null || true

echo "🦞 Starting Clawdbot..."
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  🌐 Webchat: http://localhost:18789/chat                ║"
echo "║  🔑 Token: use your GATEWAY_AUTH_TOKEN from .env        ║"
echo "║  📋 Status: docker exec clawdbot clawdbot status        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
exec "$@"
