FROM node:22-slim

LABEL maintainer="inematds"
LABEL description="Clawdbot - AI Personal Assistant with security hardening"

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    python3 \
    python3-pip \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Clawdbot
RUN npm install -g clawdbot

# Install Faster Whisper for audio transcription (optional)
RUN pip3 install --break-system-packages --no-cache-dir \
    faster-whisper \
    torch --index-url https://download.pytorch.org/whl/cpu \
    || true

# Create non-root user
RUN useradd -m -s /bin/bash clawdbot

# Create directories with proper permissions
RUN mkdir -p /home/clawdbot/.clawdbot /home/clawdbot/workspace

# Copy files (as root for sed/chmod)
COPY config/clawdbot.json.template /home/clawdbot/.clawdbot/clawdbot.json.template
COPY entrypoint.sh /home/clawdbot/entrypoint.sh

# Fix Windows line endings + set permissions
RUN sed -i 's/\r$//' /home/clawdbot/entrypoint.sh \
    && chmod +x /home/clawdbot/entrypoint.sh \
    && chown -R clawdbot:clawdbot /home/clawdbot

# Switch to non-root user
USER clawdbot
WORKDIR /home/clawdbot/workspace

EXPOSE 18789

ENTRYPOINT ["/home/clawdbot/entrypoint.sh"]
CMD ["clawdbot", "gateway", "run"]
