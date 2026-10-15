#!/bin/bash
set -euo pipefail

: "${VNC_PASSWORD:?VNC_PASSWORD must be set}"

mkdir -p /home/chrome/profile
x11vnc -storepasswd "$VNC_PASSWORD" /home/chrome/.vncpass >/dev/null
chown -R chrome:chrome /home/chrome

# stale lock from an unclean shutdown blocks Xvfb restart
rm -f /tmp/.X99-lock

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
