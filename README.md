# chrome-setup-for-agent

Headful Chrome in Docker, controllable two ways at the same time:

- **CDP** (Playwright / Puppeteer / chrome-devtools-mcp) on port 9223
- **noVNC** over http on port 6080, so a human can watch or take over

```
Xvfb :99 ← Chrome (CDP 127.0.0.1:9222) ← socat → 0.0.0.0:9223
        ← fluxbox / x11vnc (:5900) ← websockify/noVNC → 0.0.0.0:6080
```

## Run

```bash
cp .env.example .env     # set VNC_PASSWORD
docker compose up -d --build
```

No ports are published on the host, so `127.0.0.1:9223` / `6080` on the host do
not work. Reach the container through the docker network by its IP (it changes
after a rebuild, so look it up each time):

```bash
IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' chrome-setup-for-agent-chrome-1)
```

- Screen: `http://$IP:6080/vnc.html`
- CDP: `http://$IP:9223` (check with `curl http://$IP:9223/json/version`)

```js
const browser = await chromium.connectOverCDP(`http://${IP}:9223`);
```

From another machine, tunnel through the docker host:

```bash
ssh -N -L 9223:$IP:9223 -L 6080:$IP:6080 user@<docker-host>
```

Other containers can connect too if they join the compose network
(`<project>_default`); use the IP there as well.

## Security

- CDP has **no authentication**: anyone who can reach 9223 fully controls the
  browser, including any logged-in sessions in `./profile`.
- noVNC over http is plain text (VNC password and screen).
- Keep ports unpublished. If you must expose them on the LAN, put Caddy/nginx
  with HTTPS and auth in front, and restrict source IPs. Never expose to the internet.

## Notes

- Chrome 136+ ignores `--remote-debugging-port` with the default profile, so
  `--user-data-dir` (`./profile`, persisted) is required.
- Chrome rejects CDP requests whose `Host` header is not `localhost` or an IP,
  so connect by IP, not by hostname.
- `--no-sandbox` is needed inside the container; `shm_size: 2gb` avoids tab crashes.
- Humans and CDP clients driving the same tab at once will interfere.
- Suggested host size: 2 vCPU, 4 GiB RAM.
