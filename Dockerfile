FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates wget gnupg \
      xvfb x11vnc novnc websockify fluxbox \
      socat supervisor fonts-noto-cjk \
 && wget -qO- https://dl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
      > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update && apt-get install -y --no-install-recommends google-chrome-stable \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash chrome

COPY supervisord.conf /etc/supervisor/conf.d/chrome.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6080 9223
ENTRYPOINT ["/entrypoint.sh"]
