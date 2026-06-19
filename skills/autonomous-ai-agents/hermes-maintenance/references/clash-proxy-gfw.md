# Clash Proxy / GFW Workaround

The machine runs behind the Great Firewall of China. A clash/mihomo proxy (clash-for-linux-install by nelvko) provides outside-world access.

## Proxy Status

mihomo runs as a nohup daemon. HTTP proxy on `127.0.0.1:7890`, API on `127.0.0.1:9090`.

## Managing with clashctl

The `clashctl` command is a bash function defined by sourcing the entry script:

```bash
export CLASHCTL_HOME=/home/qn/clashctl
source $CLASHCTL_HOME/scripts/cmd/clashctl.sh

clashctl status       # Check if mihomo is running
clashctl on           # Start service + set proxy env vars
clashctl off          # Stop service + clear proxy env vars
clashctl sub update   # Download & apply latest subscription
clashctl sub ls       # List subscriptions
clashctl log          # Tail proxy logs
clashctl tun          # Check Tun mode status
clashctl tun on/off   # Toggle Tun mode

# Node testing & switching (standalone commands, not subcommands)
clashping                          # Test all 🔰 节点选择 node latencies
clashping -n 10                    # Fastest 10 only
clashping -t 2000 "🌍 国外媒体"    # Custom group, 2s timeout
clashuse "🇯🇵 |日本原生-中转 01"   # Switch to a node by full name
clashuse "🌍 国外媒体" "🇯🇵 |日本-IEPL 01"  # Switch in a specific group
```

## Proxy Autoheal Script

Location: `~/.hermes/scripts/proxy-autoheal.sh`

A self-healing script that runs periodically (or on-demand) to ensure the proxy is healthy:

1. **Update subscription** — `clashctl sub update`
2. **Restart mihomo** — `clashctl off && clashctl on` (now works with Tun mode via sudo key)
3. **Ping all nodes** — `clashping` on the default 🔰 group
4. **Select best node** — parse ping output, prefer 港澳台日韩+Singapore nodes under 500ms
5. **Switch if needed** — `clashuse` to the best node (skips if already current)
6. **Ensure proxy on** — `clashctl on` (sets env vars if mihomo is already running)

### Manual Run

```bash
bash ~/.hermes/scripts/proxy-autoheal.sh
```

Logs to `~/.hermes/logs/proxy-autoheal.log`.

## Sudo Key Configuration (Tun Mode)

When Tun mode is enabled, mihomo needs root privileges to manage the TUN device. Without passwordless sudo for the right commands, `clashctl off` (specifically `service_sudo_stop`) and `clashctl on` (via `service_sudo_start`) will prompt for a password and fail in non-interactive contexts.

### Setup

#### 1. Create sudoers.d entry

```
# /etc/sudoers.d/qn-mihomo
qn ALL=(ALL) NOPASSWD: /usr/bin/pkill
qn ALL=(ALL) NOPASSWD: /home/qn/clashctl/bin/mihomo
```

The first rule allows `service_sudo_stop` (uses `sudo pkill -TERM -x mihomo`).
The second rule allows the patched `service_sudo_start` (uses `sudo /home/qn/clashctl/bin/mihomo -d ... -f ...`).

**Installation** (using SUDO_PASSWORD from `.env`):

```bash
source ~/.hermes/.env
PASS="$SUDO_PASSWORD"

# Write content to temp file first (avoids sudo -S + heredoc stdin conflict)
cat > /tmp/sudoers-entry << 'EOF'
qn ALL=(ALL) NOPASSWD: /usr/bin/pkill
qn ALL=(ALL) NOPASSWD: /home/qn/clashctl/bin/mihomo
EOF

# Use cp (not tee) to avoid stdin conflict
printf '%s\n' "$PASS" | sudo -S cp /tmp/sudoers-entry /etc/sudoers.d/qn-mihomo
printf '%s\n' "$PASS" | sudo -S chmod 440 /etc/sudoers.d/qn-mihomo
printf '%s\n' "$PASS" | sudo -S visudo -c -f /etc/sudoers.d/qn-mihomo
rm /tmp/sudoers-entry
```

**Verification:**

```bash
sudo -n /home/qn/clashctl/bin/mihomo -v          # Should show version
sudo -n pkill --help                              # Should show help
sudo -n /home/qn/clashctl/bin/mihomo -d ... -f ... -t  # Config test passes
```

#### 2. Patch `service_sudo_start` in clashctl

The default `service_sudo_start` wraps the command in `sudo sh -c "nohup '...' &"`. This won't match the sudoers rule because of the `sh -c` wrapper. Replace with a direct `sudo` call:

```bash
# Before (in ~/clashctl/scripts/lib/service.sh):
        sudo sh -c "nohup '$BIN_KERNEL' -d '$CLASH_RESOURCES_DIR' -f '$CLASH_CONFIG_RUNTIME' </dev/null > '$service_log_path' 2>&1 &"

# After:
        sudo "$BIN_KERNEL" -d "$CLASH_RESOURCES_DIR" -f "$CLASH_CONFIG_RUNTIME" > "$service_log_path" 2>&1 &
```

This runs mihomo directly via sudo (matching the sudoers rule) and uses the shell's `&` for backgrounding instead of `nohup`.

### Pitfalls

- **`sudo -S` + heredoc stdin conflict**: When piping password to `sudo -S` AND using a heredoc (e.g. `printf '%s\n' "$PASS" | sudo -S tee file << 'EOF'`), sudo reads the password from the heredoc instead of the pipe, causing auth failure. Solution: write to a temp file first, then `sudo -S cp` without heredoc.

- **`printf` vs `echo` for passwords**: Use `printf '%s\n' "$PASS"` instead of `echo "$PASS"` for passwords with trailing `$` or other shell-special characters. `echo` may interpret escape sequences.

- **Each terminal() call is a fresh shell**: sudo credentials don't persist between Hermes terminal tool calls. Always source `.env` and pipe the password within the same command block, or combine all sudo commands into one terminal call.

- **Service_manager detection**: On this Pi, `INIT_TYPE=nohup` (detected via `readlink /proc/1/exe` + `_is_root` check). In nohup mode, `service_sudo_start`/`service_sudo_stop` use raw `sudo` commands, not systemd. The sudoers rules above are designed for nohup mode — if the service manager changes to systemd, different rules would be needed (`systemctl start/stop mihomo`).

## Parsing Clashping Output

When you need to programmatically select nodes from `clashping` output, the format is:

```
      🇯🇵 |日本原生-中转 01                   192ms ████▓░░░░░░░░░░░
      ✓ 🇯🇵 |日本原生-中转 01                   312ms ███████▓░░░░░░░░
      🎯 全球直连                           106ms ██▓░░░░░░░░░░░░░
    ==================================================
    ✅ 成功:  87  |  ❌ 超时:   0  |  📊 总计:  87
    📌 当前: 🇯🇵 |日本原生-中转 01
```

### Node Name Format

Clash API node names include the full emoji flag + separator, e.g. `🇯🇵 |日本原生-中转 01`. The `clashuse` command requires this full name. Do NOT strip the flag prefix.

### Python Extraction Regex

```python
import re
# Match optional ✓ marker, then full node name, then ≥3 spaces, then "123ms"
m = re.search(r"^\s*(?:✓\s*)?(.+?)\s{3,}(\d+)ms\s", line)
if m:
    full_name = m.group(1).strip()  # e.g. "🇯🇵 |日本原生-中转 01"
    latency = int(m.group(2))       # e.g. 192
```

### Priority Region Detection

```python
PRIORITY_FLAGS = {
    "\U0001f1ed\U0001f1f0",  # 🇭🇰 Hong Kong
    "\U0001f1f2\U0001f1f4",  # 🇲🇴 Macau
    "\U0001f1e8\U0001f1f3",  # 🇨🇳 China (includes Taiwan nodes)
    "\U0001f1ef\U0001f1f5",  # 🇯🇵 Japan
    "\U0001f1f0\U0001f1f7",  # 🇰🇷 South Korea
    "\U0001f1f8\U0001f1ec",  # 🇸🇬 Singapore
}
PRIORITY_KEYWORDS = ["台湾"]  # Taiwan uses 🇨🇳 flag, disambiguate by name

def is_priority_node(full_name):
    flag_match = re.match(r"([\U0001f1e6-\U0001f1ff]{2})", full_name)
    if flag_match and flag_match.group(1) in PRIORITY_FLAGS:
        return True
    return any(kw in full_name for kw in PRIORITY_KEYWORDS)
```

## Subscription Management

```bash
clashctl sub ls          # List subscriptions (IDs + URLs)
clashctl sub update      # Update current subscription
clashctl sub update 1    # Update specific sub by ID
clashctl sub log         # Subscription update history
```

### What Happens on `sub update`

1. Downloads the subscription URL → writes to temp config
2. Validates the config (YAML structure, required fields)
3. If validation fails → tries subconverter (automatic YAML → Clash format)
4. Writes validated config to `$CLASH_CONFIG_RUNTIME`
5. Calls `_merge_config_restart` to reload mihomo with new config
6. With sudo key configured, this now succeeds even with Tun mode

## Git Clone Behind GFW

```bash
GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=60 git clone --depth 1 <url>
```

Or set proxy env vars before cloning (see clashctl on above).

## npm Install Behind GFW

npm respects the standard `http_proxy` / `https_proxy` env vars. Set them before running `npm install`:

```bash
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
npm install
```

## TUI / Background Processes

Background terminal processes do NOT inherit the shell's proxy env vars. For background tasks that need network access:
1. Set proxy env vars explicitly in the command (e.g., `http_proxy=http://127.0.0.1:7890 npm install`)
2. Or wrap in a script that exports the vars first
