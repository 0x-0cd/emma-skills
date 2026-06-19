# Passwordless Sudo for Hermes Automation Scripts

## Problem

Hermes cron jobs or automation scripts sometimes need elevated privileges for system-level operations (e.g., restarting mihomo/clash TUN mode, managing network interfaces). Without passwordless sudo, these scripts fail silently or hang waiting for a password that never comes.

## General Approach

1. **Identify the exact commands** the script needs sudo for — examine the script or trace execution
2. **Handle shell-wrapped commands** — `sudo sh -c "nohup ... &"` patterns are hard to match in sudoers. Refactor to use `sudo -b` (background) or `sudo ... &` instead
3. **Create precise sudoers rules** scoped to the specific binary/user/args
4. **Test** by running the script non-interactively

## Case Study: clashctl Tun Mode

### The Commands Needed

From `service.sh` in clashctl:

```bash
# Stop (in service_sudo_stop)
sudo pkill -TERM -x "mihomo"   # graceful stop
sudo pkill -KILL -x "mihomo"   # force kill after 200ms

# Start (in service_sudo_start)
sudo sh -c "nohup '/home/qn/clashctl/bin/mihomo' \
  -d '/home/qn/clashctl/resources' \
  -f '/home/qn/clashctl/resources/runtime.yaml' \
  </dev/null > '/home/qn/clashctl/resources/mihomo.log' 2>&1 &"
```

### The Problem

The start command wraps in `sudo sh -c "nohup ... &"` — this is hard to match in sudoers because:
- The quoted paths vary per system
- `sudo sh -c "..."` requires matching the full shell command string
- Wildcard sudoers rules like `sudo /bin/sh -c nohup *` are too broad

### The Fix

**Patch `service_sudo_start` in `~/clashctl/scripts/lib/service.sh`**:

```bash
# Before (hard to sudoers-match):
sudo sh -c "nohup '$BIN_KERNEL' -d '$CLASH_RESOURCES_DIR' -f '$CLASH_CONFIG_RUNTIME' </dev/null > '$service_log_path' 2>&1 &"

# After (sudo -b runs in background, no nohup needed):
sudo -b "$BIN_KERNEL" -d "$CLASH_RESOURCES_DIR" -f "$CLASH_CONFIG_RUNTIME" > "$service_log_path" 2>&1
```

The `sudo -b` flag runs the command in the background and returns immediately. The shell's `&` and `nohup` wrapping are no longer needed.

### Sudoers Rules

Create `/etc/sudoers.d/qn-mihomo` (use `visudo -f`):

```
# Allow qn to stop mihomo via pkill (used by tunoff)
qn ALL=(ALL) NOPASSWD: /usr/bin/pkill

# Allow qn to start mihomo directly (used by tunon via sudo -b)
qn ALL=(ALL) NOPASSWD: /home/qn/clashctl/bin/mihomo
```

### Verification

```bash
# Test stop
sudo pkill -TERM -x "mihomo"    # should not ask for password

# Test start (after stopping)
sudo -b /home/qn/clashctl/bin/mihomo \
  -d /home/qn/clashctl/resources \
  -f /home/qn/clashctl/resources/runtime.yaml \
  > /home/qn/clashctl/resources/mihomo.log 2>&1

# Test from clashctl
export CLASHCTL_HOME="$HOME/clashctl"
source "$CLASHCTL_HOME/scripts/cmd/clashctl.sh"
clashtun off    # should work without password prompt
clashtun on     # should work without password prompt
```

## Principles for Automation Script Sudo

| Principle | Rationale |
|-----------|-----------|
| **Scope to the exact binary** | `NOPASSWD: /usr/bin/pkill` is safer than `NOPASSWD: ALL` |
| **Avoid shell-wrapped sudo** | `sudo sh -c "..."` patterns are hard to sudoers-match; refactor to `sudo -b` or direct binary calls |
| **Avoid `NOEXEC` restrictions** | Automation scripts typically need `EXEC` for subprocess launching |
| **Put rules in `/etc/sudoers.d/`** | Separate file per app (`qn-mihomo`), not in main sudoers |
| **Test non-interactively** | `sudo -n <command>` will fail if passwordless isn't configured |
| **Document the audit trail** | Add comments in the sudoers file explaining what each rule allows |
