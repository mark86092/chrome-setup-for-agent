# chrome-setup-for-agent

## 環境

Docker 容器裡跑 headful Chrome，同時提供 CDP 與 noVNC，可由程式與人同時控制。

- 容器內程序（supervisord 管理）：Xvfb(:99)、fluxbox、x11vnc(:5900)、noVNC/websockify(:6080)、Chrome、socat
- Chrome 的 CDP 只聽容器內 `127.0.0.1:9222`，由 socat 轉出到容器 `0.0.0.0:9223`
- Chrome 版本跟隨 `google-chrome-stable`（Dockerfile 未鎖版本，重建後可能變動），profile 持久化在 `./profile`（`--user-data-dir`，Chrome 136+ 必須指定）
- Compose 專案名稱 `chrome-setup-for-agent`，服務 `chrome`，容器 `chrome-setup-for-agent-chrome-1`，network `chrome-setup-for-agent_default`
- 啟動需要 `VNC_PASSWORD`（`.env` 或環境變數），範例見 `.env.example`

檔案：`Dockerfile`、`supervisord.conf`、`entrypoint.sh`、`docker-compose.yml`、`README.md`

## 如何連到

容器 IP 會在重建後改變，每次先用 `docker inspect` 查：

```bash
IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' chrome-setup-for-agent-chrome-1)
```

- CDP：`http://$IP:9223`（檢查：`curl http://$IP:9223/json/version`）
- noVNC：`http://$IP:6080/vnc.html`（密碼是啟動時的 `VNC_PASSWORD`）
- Playwright：`chromium.connectOverCDP(`http://${IP}:9223`)`

### 注意

- **要用 IP 連，不能用服務名稱**：CDP 只接受 `localhost` 或 IP 當 Host header，用 `http://chrome:9223` 會回 HTTP 500。
- `webSocketDebuggerUrl` 會跟著請求的 Host 回傳，用 IP 連就是 `ws://<IP>:9223/...`。
- CDP 沒有認證，能連到的人可完全控制瀏覽器與已登入的 session；noVNC 是 http 明文。不要把這兩個 port 暴露到區網或公網，從別台機器請用 SSH tunnel。
- 人與 CDP 同時操作同一個分頁會互相干擾。
- 其他容器若要連，需加入 `chrome-setup-for-agent_default` network，同樣用 IP。

## 常用指令

```bash
docker compose up -d --build        # 需要 VNC_PASSWORD
docker compose down                 # down 時也需要 VNC_PASSWORD（compose 會檢查）
docker exec chrome-setup-for-agent-chrome-1 supervisorctl status
docker logs chrome-setup-for-agent-chrome-1
```
