# Gateway Watchdog — Cronjob Script Pattern

## Problem

The Hermes gateway (running platforms like QQ, Telegram, Discord) can crash or be killed unexpectedly. When the gateway goes down, the user can't reach the agent until someone manually restarts it — and the agent can't self-recover because it's unreachable.

## Solution: no_agent Cronjob Watchdog

Hermes supports **no_agent cronjobs** — shell scripts that run on schedule without consuming any LLM tokens. If the script's stdout is non-empty, it's delivered to the user; if empty, nothing happens (silent success). 

This is the ideal pattern for a gateway watchdog:

```
no_agent=true → script runs → 
  gateway alive? → empty stdout → silent ✓
  gateway dead?  → restart + log → notification
```

## Script Template

Place this at `~/.hermes/scripts/gateway-watchdog.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${HERMES_HOME:-$HOME/.hermes}/logs"
SCRIPT_LOG="$LOG_DIR/gateway-watchdog.log"
mkdir -p "$LOG_DIR"

STATUS=$(hermes gateway status 2>&1 || true)

if echo "$STATUS" | grep -qi "not running\|stopped\|dead\|inactive"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Gateway not running. Starting..." >> "$SCRIPT_LOG"
    nohup hermes gateway run > "$LOG_DIR/gateway-restart.log" 2>&1 &
    PID=$!
    sleep 3
    if kill -0 "$PID" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restarted (PID: $PID)" >> "$SCRIPT_LOG"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed to start" >> "$SCRIPT_LOG"
    fi
else
    PID=$(echo "$STATUS" | grep -oP 'PID:\s*\K\d+' || echo "unknown")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running (PID: $PID)" >> "$SCRIPT_LOG"
fi

tail -n 200 "$SCRIPT_LOG" > "${SCRIPT_LOG}.tmp" && mv "${SCRIPT_LOG}.tmp" "$SCRIPT_LOG"
```

## Cronjob Setup

Create the cronjob using the Hermes cronjob tool:

```python
cronjob(
    action="create",
    name="gateway-watchdog",
    schedule="*/5 * * * *",        # every 5 minutes
    script="gateway-watchdog.sh",   # relative to ~/.hermes/scripts/
    no_agent=True,                  # shell-only, no LLM tokens
    deliver="local"                 # don't notify, just log
)
```

## Key Properties

| Property | Value | Reason |
|----------|-------|--------|
| `no_agent` | `true` | No LLM cost — just shell logic |
| `deliver` | `"local"` | No noisy notifications on success |
| `script` | relative path | Must be under `~/.hermes/scripts/` |
| schedule | `*/5 * * * *` | Fast enough to catch crashes, slow enough for gateways that take 10-30s to start |

## Stdout Semantics (no_agent mode)

Design for **silent when healthy**:

- **Non-empty stdout** → sent to user as a message (treat as alert)
- **Empty stdout** → nothing sent (silent watchdog tick)
- **Non-zero exit / timeout** → error alert sent automatically

## When to Use This Pattern

This watchdog pattern (`script` + `no_agent` + cron) works for any long-lived process that:
- Should always be running
- Can be safely started in background
- Is OK with a 1-5 minute recovery delay
- Needs to be monitored without LLM cost

Examples: gateway server, local inference server (llama.cpp, vLLM), dashboard, API proxies.

## Pitfalls

- Script path must be relative to `~/.hermes/scripts/` — absolute paths are rejected by the cronjob API
- Gateway needs a few seconds to start — the `sleep 3` before the health check prevents false negatives
- `deliver="local"` prevents the user from getting a message every 5 minutes when everything is fine
- If the gateway is intentionally stopped (maintenance), the watchdog will restart it within 5 minutes. Use `hermes cron pause <job_id>` to disable during maintenance
