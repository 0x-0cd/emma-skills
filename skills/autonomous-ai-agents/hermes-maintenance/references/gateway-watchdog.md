# Gateway Watchdog — System Crontab Recipe

## Overview

A bash script that monitors `hermes-gateway` systemd user service and restarts it if dead. Runs via system crontab every 5 minutes.

**Why crontab, not Hermes cron:** System-level service monitoring should be independent of the agent runtime. If the gateway is down, Hermes cron may not fire. System crontab is always available.

## Script

Location: `~/.hermes/scripts/gateway-watchdog.sh`

```bash
#!/usr/bin/env bash
# Gateway watchdog — check if hermes gateway is alive, restart if dead
# Runs from cron every 5 minutes
# Gateway runs as systemd user service (hermes-gateway.service)

set -euo pipefail

LOG_DIR="${HERMES_HOME:-$HOME/.hermes}/logs"
SCRIPT_LOG="$LOG_DIR/gateway-watchdog.log"
mkdir -p "$LOG_DIR"

STATUS=$(systemctl --user is-active hermes-gateway 2>&1 || true)

if [ "$STATUS" = "active" ]; then
    PID=$(systemctl --user show hermes-gateway --property MainPID --value 2>/dev/null || echo "unknown")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Gateway running (PID: $PID)" >> "$SCRIPT_LOG"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ Gateway is $STATUS. Restarting..." >> "$SCRIPT_LOG"
    systemctl --user start hermes-gateway 2>&1 >> "$SCRIPT_LOG"
    sleep 2
    NEW_STATUS=$(systemctl --user is-active hermes-gateway 2>&1 || true)
    if [ "$NEW_STATUS" = "active" ]; then
        NEW_PID=$(systemctl --user show hermes-gateway --property MainPID --value 2>/dev/null || echo "unknown")
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Gateway restarted (PID: $NEW_PID)" >> "$SCRIPT_LOG"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Gateway restart failed (status: $NEW_STATUS)" >> "$SCRIPT_LOG"
    fi
fi

# Keep only last 200 lines
tail -n 200 "$SCRIPT_LOG" > "${SCRIPT_LOG}.tmp" && mv "${SCRIPT_LOG}.tmp" "$SCRIPT_LOG"
```

## Crontab Setup

```bash
# Add to crontab (runs every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/qn/.hermes/scripts/gateway-watchdog.sh") | crontab -

# Verify
crontab -l

# Manual test
bash /home/qn/.hermes/scripts/gateway-watchdog.sh
tail -5 ~/.hermes/logs/gateway-watchdog.log
```

## Crontab Management

```bash
# View current crontab
crontab -l

# Edit interactively
crontab -e

# Remove the watchdog entry
crontab -l | grep -v gateway-watchdog | crontab -
```

## Log Output

```
[2026-06-18 01:00:21] ✓ Gateway running (PID: 6415)
[2026-06-18 01:05:21] ✓ Gateway running (PID: 6415)
[2026-06-18 01:10:21] ⚠️ Gateway is inactive. Restarting...
[2026-06-18 01:10:23] ✅ Gateway restarted (PID: 16923)
```

## Pitfalls

- **Systemd user service**: The script uses `systemctl --user`. This requires `systemd` user instance to be running — standard on most Linux desktop/server distros, including Raspberry Pi OS.
- **No proxy dependency**: The script only checks systemd state and runs `systemctl start`. It does NOT need network access, so it works even when mihomo is down.
- **File descriptor limits**: hermes-gateway can accumulate memory over time (observed: 2.1GB after 15h). The watchdog only restarts if the service is DEAD — it does NOT do periodic health-restarts. Manual restart (`hermes gateway restart`) is still needed for memory bloat.
