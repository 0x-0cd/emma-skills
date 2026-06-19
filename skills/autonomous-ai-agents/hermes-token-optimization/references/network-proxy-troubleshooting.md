# Network Proxy Troubleshooting for Hermes Tool Calls

## Pattern

When terminal commands (git clone, curl, pip install, apt-get, etc.) time out or fail to connect to external hosts despite an active VPN/proxy, the terminal subprocess may not inherit the proxy settings from the user's shell environment.

## Quick Fix

```bash
export http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890 && <your-command>
```

## When This Applies

- `git clone` from GitHub: frequent "fetch-pack: unexpected disconnect" or timeout
- `curl` to external URLs: connection timeout
- `pip install` / `npm install`: hangs on download
- `wget` / `apt-get`: fails to reach repositories
- Any tool that makes outbound HTTP/HTTPS connections

## Not a Fix For

- `web_search` or `web_extract` timeouts — these run through Hermes' own HTTP client which may use different proxy config
- Local services (127.0.0.1, localhost) — proxy not needed
- DNS resolution failures — proxy doesn't help with name resolution

## Proxy Details (this environment)

- **Proxy**: clash-for-linux + mihomo
- **HTTP**: 127.0.0.1:7890
- **SOCKS**: 127.0.0.1:7891
- **Location**: Hong Kong node

## Verification

After setting proxy:
```bash
curl -sI https://github.com | head -1   # should return HTTP/2 200
```
