---
name: hermes-maintenance
description: "Maintain Hermes Agent system-level dependencies: upgrade bundled Node.js, fix TUI npm install failures, handle ARM64-specific quirks (Electron downloads), and post-update health verification."
version: 1.5.0
author: Emma
license: MIT
metadata:
  hermes:
    tags: [hermes, maintenance, upgrade, nodejs, arm64, tui, troubleshooting]
    related_skills: [hermes-agent, community-resources]
---

# Hermes Agent — System Maintenance

> ⚡ 参考文件：`references/session-maintenance.md` — Session 数据库清理与优化
> 🌐 参考文件：`references/chinese-web-sources.md` — 中文互联网信息源（热搜、科技资讯、社区评测）
> 🐶 参考文件：`references/gateway-watchdog.md` — Gateway 心跳保活脚本（system crontab）

System-level maintenance tasks for Hermes Agent: upgrading its bundled Node.js, fixing npm/TUI issues, working around ARM64-specific pitfalls, and verifying system health after updates.

---

## Post-Update Health Verification

Run this checklist after `hermes update` (or any major Hermes change) to confirm the system is healthy. Each step identifies a specific subsystem — if it fails, the linked section or issue has the fix.

### 1. Version & Freshness

```bash
hermes version            # Expected: matches the latest release tag
hermes update --check     # Expected: "Already up to date."
pip show hermes-agent     # Confirm version matches
```

If `hermes update --check` shows an available update, run `hermes update`.

### 2. Configuration Integrity

```bash
hermes config show        # Verify model, provider, and key paths
hermes config check       # Expected: no REQUIRED items missing
```

If `hermes config check` reports "Config version: X → Y (update available)", it's a normal schema migration — run `hermes config migrate` if the user okays it.

**Known issue: `hermes doctor` timeout (GitHub #35838)**
- `hermes doctor` may hang for 30+ seconds when `models.dev` is unreachable and the local cache is stale
- **Workaround:** `touch ~/.hermes/models_dev_cache.json` to refresh the timestamp
- Root cause: `agent.models_dev.get_provider_info()` blocks synchronously when the remote metadata endpoint times out but the local cache exists and is considered stale. The issue is open with a stale-while-revalidate fix being discussed.

### 3. Skills & Plugins

```bash
hermes skills list        # Check all expected skills are present and enabled
hermes plugins list       # Verify enabled plugins (hermes-lcm, rtk-rewrite, etc.)
```

- Count total skills (expected: ~115-120 with default Hermes hub install)
- Verify custom/agent-created skills aren't missing
- **Cross-profile guard:** editing another profile's skills/plugins requires `cross_profile=true`

### 4. Cron Jobs

```bash
hermes cron list          # Verify all scheduled jobs are active
```

Each job should show `[active]`, a valid schedule, and `Last run: ... ok`. If a job's script references `~/.hermes/scripts/`, note that the runtime resolves paths under `$HERMES_HOME/scripts/` — documentation may lag (GitHub #51765, cosmetic only).

### 5. Memory System

```bash
hermes memory status      # Expected: provider=holographic, status=available ✓
```

Also verify fact_store is accessible (call `fact_store` with `action='list'` or `action='search'`). If error: check `~/.hermes/memory_store.db` existence and permissions.

### 6. Gateway

```bash
systemctl --user status hermes-gateway   # Expected: active (running)
```

**Known issue: "Installed gateway service definition is outdated" (GitHub #41119, #46276)**
- On systemd < 250, unsupported `RestartMaxDelaySec`/`RestartSteps` directives cause a false positive (#41119)
- Multi-profile setups can have PATH mismatch between install and check contexts (#46276)
- Both are cosmetic — the service runs fine. Fix: `hermes gateway restart` refreshes the unit.

Also check gateway logs for persistent errors:
```bash
systemctl --user status hermes-gateway --no-pager | tail -20
```

Look for:
- `WebSocket closed: code=4009 reason=Session timed out` on QQ bot — normal, auto-reconnects
- Repeated `ERROR` or `CRITICAL` messages — investigate

### 7. LCM (Lossless Context Management)

```bash
# Call the lcm_status system tool — checks engine, database, config, lifecycle
lcm_status
```

Expected output shows:
- `engine: lcm`, `plugin_version` matching the installed hermes-lcm version
- `database_integrity: pass`
- `sqlite_storage: pass` (journal_mode=wal)
- `context_pressure: pass` (should be well below 50%)

**LCM lifecycle fragmentation warnings** are normal after session pruning. Categories to ignore:
- `stale_lifecycle_current` — old lifecycle rows referencing deleted sessions
- `lcm_message_sessions_without_lifecycle_reference` — retained historical context
- `lcm_message_sessions_missing_in_state` — imported context from before Hermes state DB tracking

Only take action if fragmentation is >200 stale references. See Session Store Maintenance section for cleanup procedure.

### 8. Cross-Reference Errors with GitHub Issues

For any error encountered, search the Hermes repo:
```bash
gh issue list --repo NousResearch/hermes-agent --state open --search "<error keywords>"
```

Common post-update errors and their issue trackers:

| Symptom | Likely Issue | Status |
|---------|-------------|--------|
| `hermes doctor` timeout / hangs | #35838 — models.dev stale cache blocking | OPEN, workaround available |
| Gateway "service outdated" warning | #41119 — systemd < 250 compat / #46276 — PATH mismatch | OPEN, cosmetic |
| Cron script path errors | #51765 — docstring vs runtime path discrepancy | OPEN, runtime works correctly |
| `hermes tools` requires interactive terminal | Not a bug — tools management requires a TTY by design | Won't fix |

### 9. Summary Report

Compile findings into a structured table for the user:

| Subsystem | Status | Notes |
|-----------|--------|-------|
| Hermes version | ✅ v0.18.0 | Up to date |
| Config | ✅ | Valid |
| Skills | ✅ 116 loaded | All expected |
| Plugins | ✅ hermes-lcm + rtk-rewrite | Enabled |
| Cron | ✅ 2 jobs active | Both running OK |
| Memory | ✅ holographic | 178 facts |
| Gateway | ✅ running | Minor: outdated unit warning (cosmetic) |
| LCM | ✅ pass | Fragmentation: benign |

If all pass → report "Update successful, all systems normal."
If any fail → report findings, link to the relevant issue, and offer the workaround.

---



## Upgrading Bundled Node.js

Hermes bundles its own Node.js at `~/.hermes/node/`. When `hermes update` requires a newer Node version (e.g., v24+), upgrade it manually:

### 1. Check current version

```bash
node --version
# Or check the bundled binary directly:
~/.hermes/node/bin/node --version
```

### 2. Check if Node is Hermes-bundled

```bash
which node              # often ~/.local/bin/node
ls -la ~/.local/bin/node  # symlink → ~/.hermes/node/bin/node
```

### 3. Find the latest version in the required major

```bash
# List available versions:
curl -sL https://nodejs.org/dist/latest-v24.x/ | grep linux-arm64
# Or check the index page for version numbers
```

### 4. Download the ARM64 Linux tarball

First, check the actual latest version available:

```bash
# List available versions for v24.x:
curl -sL https://nodejs.org/dist/latest-v24.x/ | grep -oP 'node-v\K[0-9.]+(?=-linux-arm64\.tar\.xz)' | head -1
```

Then download:

```bash
cd /tmp
VERSION="24.16.0"  # ← replace with actual latest from above
curl -sLO "https://nodejs.org/dist/latest-v24.x/node-v${VERSION}-linux-arm64.tar.xz"
tar xf "node-v${VERSION}-linux-arm64.tar.xz"
```

### 5. Replace Hermes's bundled Node

```bash
cd ~/.hermes
VERSION="24.16.0"  # ← match the version you downloaded
# Backup
mv node node.bak
# Move new version in place
mv "/tmp/node-v${VERSION}-linux-arm64" node
# Restore agent-browser symlink (Hermes-specific)
ln -sf /home/qn/.hermes/hermes-agent/node_modules/agent-browser/bin/agent-browser-linux-arm64 ~/.hermes/node/bin/agent-browser
```

### 6. Verify

```bash
node --version   # should show v24.x
npm --version    # upgraded automatically
node -e "console.log('OK: v' + process.version + ' on ' + process.arch)"
```

### 7. Clean up

```bash
rm -rf ~/.hermes/node.bak /tmp/node-v24.*-linux-arm64*
```

### URL pattern

```
https://nodejs.org/dist/latest-v{MAJOR}.x/node-v{VERSION}-linux-{ARCH}.tar.xz
```

Arch: `arm64` for aarch64, `x64` for x86_64.

---

## Fixing TUI npm install Failures

When `hermes --tui` (or `hermes chat` in TUI mode) reports "npm install failed":

### Root Causes

1. **Corrupted `node_modules`** — partially written or stale package directories cause `ENOTEMPTY` errors during npm renames
2. **Workspace check includes desktop (Electron)** — Hermes's TUI startup calls `_tui_need_npm_install()`, which checks ALL workspace packages, including `apps/desktop` which depends on Electron. On ARM64, downloading the Electron binary times out (several hundred MB).

### Fix Steps

```bash
# Navigate to Hermes source
cd ~/.hermes/hermes-agent

# Remove corrupted node_modules
rm -rf node_modules

# Install workspace packages (skip desktop Electron on ARM64)
npm install --workspace ui-tui --workspace web --ignore-scripts --no-fund --no-audit

# Also install other workspaces that don't need native binaries
npm install --workspace apps/shared --workspace apps/bootstrap-installer --no-fund --no-audit

# Check for missing packages
python3 -c "
import json
from pathlib import Path
ws = Path.home() / '.hermes' / 'hermes-agent'
lock = json.loads((ws / 'package-lock.json').read_text())
installed = json.loads((ws / 'node_modules' / '.package-lock.json').read_text())
missing = [n for n, p in lock.get('packages', {}).items() if n and n not in installed and not (isinstance(p, dict) and (p.get('optional') or p.get('peer')))]
print(f'Missing: {len(missing)}')
if missing: print(f'First 3: {missing[:3]}')
else: print('All packages match!')
"
```

If any packages are still missing (like `agent-browser`), install them individually:

```bash
npm install agent-browser@<version> --no-fund --no-audit
```

### Verify TUI readiness

After fixing, `_tui_need_npm_install()` returns False, so `hermes --tui` starts without the npm install step.

---

## Disk Space Analysis (Raspberry Pi / Resource-Constrained Hosts)

When the user says "磁盘检查 / 磁盘空间不足 / 看看什么占了空间":

### Step 1: Overall View

```bash
df -h                            # Filesystem overview
# Key: /dev/mmcblk0p2 is the SD card root partition
```

### Step 2: Top-Level Directories

```bash
du -sh /* 2>/dev/null | sort -rh | head -15
# Typical big items: /home (£), /usr, /swapfile, /var, /snap
```

### Step 3: Home Directory Breakdown (the biggest user-facing area)

```bash
du -sh ~/* 2>/dev/null | sort -rh | head -20
du -sh ~/.* 2>/dev/null | sort -rh | head -25
# Must check both visible and hidden files
```

### Step 4: Drill Into Hotspots

```bash
du -sh ~/.hermes/* | sort -rh | head -10        # Hermes data
du -sh ~/.cache/* | sort -rh | head -15          # System caches
du -sh ~/.npm/* | sort -rh | head -10            # npm cache
du -sh ~/.nvm/versions/*/*                       # Node versions
du -sh ~/projects/*/ | sort -rh | head -10       # Projects
```

### Step 5: Project .venv Deep-Dive

When a Python project directory is suspiciously large, the culprit is almost always `.venv/` or `node_modules/` — not the source code:

```bash
# Check project dirs (visible + hidden)
du -sh ~/projects/<project>/*/ 2>/dev/null | sort -rh | head -5
du -sh ~/projects/<project>/.*/ 2>/dev/null | sort -rh | head -5

# Drill into venv site-packages to find heavy packages
du -sh ~/projects/<project>/.venv/lib/python3.11/site-packages/*/ 2>/dev/null | sort -rh | head -15
```

Typical heavy packages (observed on Mneme / memory-system projects):
| Package | Size | Notes |
|---------|------|-------|
| `torch/` | 624 MB | PyTorch — largest single dep |
| `transformers/` | 109 MB | HuggingFace |
| `scipy/` | 122 MB | Scientific computing |
| `onnxruntime/` | 48 MB | ONNX Runtime |

**Always check `pyproject.toml` to identify the actual project name** — the directory name may differ from the project name (e.g., `project/ai-memory-system/` is actually named `mneme`). Use `head -10 pyproject.toml` to find `[project]\nname = "..."`.

### Typical Hermes-on-Pi Disk Budget

| Item | Typical Size | Notes |
|------|-------------|-------|
| `~/.hermes/hermes-agent/` | 1.1 GB | Source + venv (416M) + node_modules (381M) |
| `~/.hermes/node/` | 1.5 GB | Bundled Node.js runtime |
| `~/.nvm/versions/` | 1.5 GB | nvm-managed Node (may be unused) |
| `~/.npm/_cacache/` | 600 MB | npm package cache |
| `~/.cache/uv/` | 450 MB | uv toolchain cache |
| `~/.cache/` (other) | 200 MB | pip, node-gyp, mneme |
| `~/.hermes/*.db` | ~30 MB | state.db + lcm.db + memory_store.db |
| `/swapfile` | 2.0 GB | Swap (may be 0B used on Pi with 3.7GB RAM) |

**`/swapfile` is NOT generated by Hermes** — it's an OS swap file. Check `swapon --show` and `free -h` before suggesting removal.

### Typical Reclaimable Space on a Hermes Pi

| Action | Space | Sudo? | Risk |
|--------|-------|-------|------|
| `npm cache clean --force` | ~600 MB | No | ✅ Safe, auto-rebuilds |
| `uv cache clean` | ~420 MB | No | ✅ Safe, auto-rebuilds |
| `pip cache purge` | ~42 MB | No | ✅ Safe, auto-rebuilds |
| `rm -rf ~/.cache/node-gyp ~/.cache/mneme` | ~150 MB | No | ✅ Safe |
| `rm -rf ~/.nvm` | ~1.5 GB | No | ⚠️ Only if Hermes-bundled Node is active |
| `sudo swapoff /swapfile && sudo rm /swapfile && sudo sed -i '/swapfile/d' /etc/fstab` | ~2.0 GB | Yes | ⚠️ Only if swap is unused |
| `sudo journalctl --vacuum-time=3d && sudo apt clean` | ~400 MB | Yes | ✅ Safe |

### Checking Which Node Is Active

Before removing nvm, verify Hermes's bundled Node is the active one:

```bash
which node
readlink -f $(which node)                 # Should point to ~/.hermes/node/bin/node
/home/qn/.nvm/versions/node/*/bin/node --version  # nvm's independent copy
```

If the symlink chain resolves to `~/.hermes/node/bin/node`, the nvm version is unused and safe to remove. OpenCode is a native ARM64 binary (not Node-dependent). CodeGraph is a shell script.

### Pitfall: Sudo Password on Pi

On this Raspberry Pi, `sudo` requires a password and the terminal tool can't interact with password prompts. When a cleanup step needs sudo, report the exact commands and ask the user to run them. Do NOT use `echo "password" | sudo -S` — that's a security anti-pattern.

---

## Cache Cleanup Reference

### npm Cache

```bash
# npm cache (_cacache) can grow to 600M+ on active Node.js projects
npm cache clean --force
# Verifies: du -sh ~/.npm/
# After cleanup: ~80MB (the _cacache dir becomes ~empty but the dir itself stays)
```

npm's `_cacache` is an integrity-verified content-addressable store. `npm cache clean` clears it without affecting installed packages. Subsequent installs rebuild it on demand.

### uv Cache

```bash
# uv toolchain cache can be 420M+ (mostly archive-v0 with downloaded wheels/tarballs)
uv cache clean
# Clears: archive-v0/, simple-v21/, builds-v0/, wheels-v6/, sdists-v9/
```

### pip Cache

```bash
pip cache purge
```

### Other System Caches

```bash
# node-gyp cache (compiled native addon artifacts)
rm -rf ~/.cache/node-gyp

# mneme cache (specific to memory systems)
rm -rf ~/.cache/mneme
```

---

## Session Store Maintenance

Hermes stores all conversation history in `~/.hermes/state.db` (SQLite). Over time this can grow to dozens of MB. Regular maintenance keeps it lean.

### Prune Old Sessions

```bash
# Delete sessions older than 30 days (default: 90)
hermes sessions prune --older-than 30 -y

# Prune only from a specific source (e.g., TUI sessions)
hermes sessions prune --source tui --older-than 7 -y
```

### Delete Specific Sessions

```bash
# List session IDs first
hermes sessions list

# Delete by session ID — accepts --yes flag to skip confirmation
hermes sessions delete <session_id> --yes

# Or pipe confirmation via stdin (alternative)
echo "y" | hermes sessions delete <session_id>
```

**Command accepts exactly ONE session ID per call.** Passing multiple IDs gives "unrecognized arguments" error. Use a loop or call it repeatedly.

**Cannot delete the currently-active session** — returns an error. Always keep at least the active session.

**`hermes sessions list` may not show every session** — sessions with NULL title and low message count (1–29) are hidden. Use `python3 -c "import sqlite3; conn=sqlite3.connect('/home/qn/.hermes/state.db'); cur=conn.execute('SELECT id, source, title, message_count FROM sessions ORDER BY started_at'); [print(*r) for r in cur.fetchall()]; conn.close()"` to see ALL sessions including skeleton/unnamed ones.

Useful pattern — after summarizing and recording memory from a session, delete it to keep the store clean:
1. `session_search(query="...")` to find the target session(s)
2. `session_search(session_id="...")` to read full content
3. Extract key facts → update memory via `memory` tool (not MEMORY.md directly)
4. `hermes sessions delete <session_id> --yes`
5. Loop until only the active session remains

### Optimize Database (Reclaim Disk Space)

After deleting sessions, FTS5 indexes and SQLite pages don't shrink automatically:

```bash
hermes sessions optimize
```

This runs FTS5 index merge + VACUUM. Can reclaim 75%+ of the DB size (observed: 24.1 MB → 5.0 MB after deleting 12 sessions).

**Note: `hermes sessions optimize` does NOT accept `--yes` / `-y`** — unlike `delete` and `prune`, the `optimize` subcommand has no skip-confirmation flag. Just run it without flags and it proceeds automatically.

**Fallback (if `hermes sessions optimize` doesn't exist or errors):**

```bash
sqlite3 ~/.hermes/state.db "VACUUM;"
```

Direct VACUUM reclaims the space from deleted session rows without FTS5 index merging. In practice, this is simpler and equally effective for most cases (observed: 21.6 MB → 10.2 MB after deleting 18 sessions).

**lcm.db doesn't shrink from session deletion alone** — LCM has a separate lifecycle layer with stale references to deleted sessions. `sqlite3 ~/.hermes/lcm.db "VACUUM;"` typically reclaims little-to-no space (<1 MB) because the old message data and lifecycle rows persist. This is expected — the stale LCM data is read-only historical context and doesn't affect performance. Only vacuum lcm.db if disk space is critically low.

### Stats & Health

```bash
hermes sessions stats       # Show session store statistics
hermes sessions list        # List remaining sessions
hermes doctor               # Full diagnostics
```

### LCM Lifecycle Fragmentation Cleanup

After deleting sessions, LCM retains **stale lifecycle references** — rows in `lcm_lifecycle_state` where `current_session_id` or `last_finalized_session_id` point to sessions that no longer have data in LCM. These show up in `lcm_doctor` as `stale_lifecycle_current` / `stale_lifecycle_finalized` warnings.

**They are harmless** — they don't affect performance, retrieval, or context quality. But they cause the LCM doctor to report a `warn` status, and some operators prefer a clean database.

#### Check Current Fragmentation

```bash
# Run diagnostics — look for lifecycle_fragmentation check
hermes doctor

# Or query directly:
sqlite3 ~/.hermes/lcm.db "
SELECT 'stale_current', COUNT(*) FROM lcm_lifecycle_state
WHERE current_session_id != ''
  AND NOT EXISTS (SELECT 1 FROM messages m WHERE m.session_id = current_session_id)
  AND NOT EXISTS (SELECT 1 FROM summary_nodes n WHERE n.session_id = current_session_id)
UNION ALL
SELECT 'stale_finalized', COUNT(*) FROM lcm_lifecycle_state
WHERE last_finalized_session_id != ''
  AND NOT EXISTS (SELECT 1 FROM messages m WHERE m.session_id = last_finalized_session_id)
  AND NOT EXISTS (SELECT 1 FROM summary_nodes n WHERE n.session_id = last_finalized_session_id);
"
```

#### Clean Stale Lifecycle References

**Always backup first:**

```bash
cp ~/.hermes/lcm.db ~/.hermes/lcm.db.backup.$(date +%Y%m%d_%H%M%S)
```

**Then clear stale references** (UPDATE in-place, does NOT delete rows):

```bash
sqlite3 ~/.hermes/lcm.db "
UPDATE lcm_lifecycle_state
SET current_session_id = '',
    current_frontier_store_id = 0,
    current_bound_at = NULL
WHERE current_session_id != ''
  AND NOT EXISTS (SELECT 1 FROM messages m WHERE m.session_id = current_session_id)
  AND NOT EXISTS (SELECT 1 FROM summary_nodes n WHERE n.session_id = current_session_id);
"

sqlite3 ~/.hermes/lcm.db "
UPDATE lcm_lifecycle_state
SET last_finalized_session_id = '',
    last_finalized_frontier_store_id = 0,
    last_finalized_at = NULL
WHERE last_finalized_session_id != ''
  AND NOT EXISTS (SELECT 1 FROM messages m WHERE m.session_id = last_finalized_session_id)
  AND NOT EXISTS (SELECT 1 FROM summary_nodes n WHERE n.session_id = last_finalized_session_id);
"
```

**Verify** by re-running the check queries — both counts should be 0. The `lcm_doctor`'s `lifecycle_fragmentation` severity should drop from `warn` to `notice`.

#### What NOT to Clean

These LCM categories are **benign and intentionally retained** — do not touch:

| Category | Count (typical) | Why retained |
|----------|-----------------|-------------|
| `lcm_message_sessions_without_lifecycle_reference` | ~23 | Historical retained context — keeps older sessions searchable via LCM grep |
| `lcm_message_sessions_missing_in_state` | ~129 | Imported or retained context from before the Hermes state DB tracked this conversation |
| `lcm_node_sessions_missing_in_state` | ~5 | Summary nodes from sessions pruned from state DB but kept for retrieval |
| `state_only_sessions` | ~2 | Sessions never ingested by LCM (e.g., gateway routing sessions) |

All four are `notice`-level and show as "usually safe" / "benign" — no action needed.

### What Gets Deleted

- Conversation transcripts (user + assistant messages)
- Tool call results stored in the session
- Session metadata (title, timestamps, source)

**NOT deleted** — the following are stored separately and survive session deletion:
- Memory files (`~/.hermes/memories/MEMORY.md`, `USER.md`)
- Holographic fact store (`~/.hermes/memory_store.db`)
- Skills and skill data (`~/.hermes/skills/`)
- Configuration (`~/.hermes/config.yaml`, `.env`)
- Cron jobs, channel directory, plugin data

### Workflow: Session Cleanup After Task Completion

When the user says "整理session/更新记忆/清理掉其他session":

1. **Discover sessions** — `session_search()` (browse mode, no args) to see recent sessions with previews. Also run `hermes sessions list` and verify count with `hermes sessions stats` — the CLI list may hide skeleton/unnamed sessions (use direct sqlite3 query on state.db for full visibility)
2. **Read each non-current session** — `session_search(session_id=...)` to load full content. For sessions with 180+ messages, scroll the middle via `around_message_id` to catch key transitions
3. **Cross-check existing memory** — before adding anything, review current memory entries (+ fact_store list) to avoid duplicating facts already stored
4. **Dual-target extraction** — Extract key facts into TWO stores:
   - `memory` tool → durable preferences, project state, identity facts (MEMORY.md)
   - `fact_store` → structured knowledge (benchmark results, bug patterns, testing conventions)
   - Compress to user's preferred size (default target: ~2200 chars per batch, or as specified)
5. **Deduplicate mid-flight** — after adding memory entries, scan for near-duplicates (same entity mentioned in two entries). Remove redundant ones via `memory(action='remove', old_text='...')`
6. **Delete** — Two approaches for deleting processed sessions:

   **Approach A — Bulk SQL (preferred for deleting specific known IDs):**
   ```bash
   sqlite3 ~/.hermes/state.db "DELETE FROM sessions WHERE id IN ('id1', 'id2', 'id3'); VACUUM;"
   ```
   More efficient than N CLI calls. Always verify with `SELECT id, title FROM sessions` after.

   **Approach B — CLI (one ID per call):**
   ```bash
   hermes sessions delete <session_id> --yes
   ```
   For skeleton sessions not visible in the CLI list, use a direct sqlite3 query to discover IDs first.
7. **Optimize** — `hermes sessions optimize` to reclaim disk space; if the command doesn't exist or errors, fall back to direct `sqlite3 ~/.hermes/state.db "VACUUM;"`
8. **Report** — summarize what was cleaned, what was saved to memory, disk reclaimed
9. **Verify LCM state** — `hermes doctor` or check `lcm_status` to confirm LCM lifecycle fragmentation (stale references to deleted sessions) is benign. The stale lifecycle rows do not affect functionality but will show in `lcm_doctor` diagnostics as `stale_lifecycle_current` / `stale_lifecycle_finalized` warnings — these are expected and can be ignored.

### Quick Variant: Purge All Except Current

When the user says "只保留当前的，其他都清掉" or similar aggressive cleanup (no memory extraction needed):

Two approaches, pick the one that fits:

#### Approach A — Direct SQLite (preferred for bulk cleanup)

More robust than CLI parsing — no fragile `awk` on multi-line titles:

```bash
cd ~/.hermes
CURRENT="<current_session_id>"   # from session_search() browse mode

# 1. List all sessions with message counts to assess scope
sqlite3 state.db "SELECT s.id, s.title, COUNT(m.id) as msgs \
  FROM sessions s LEFT JOIN messages m ON m.session_id = s.id \
  GROUP BY s.id ORDER BY s.started_at;"

# 2. Delete messages for all non-current sessions
#    FTS triggers auto-clean fts and fts_trigram tables
sqlite3 state.db "DELETE FROM messages WHERE session_id IN (\
  SELECT id FROM sessions WHERE id != '$CURRENT'\n);"

# 3. Delete the sessions themselves
sqlite3 state.db "DELETE FROM sessions WHERE id != '$CURRENT';"

# 4. Reclaim disk space
sqlite3 state.db "VACUUM;"

# 5. Verify only current session remains
sqlite3 state.db "SELECT id, title FROM sessions ORDER BY started_at;"
```

**Pitfall: `$CURRENT` must be accurate** — double-check before running. If the ID is wrong, you'll delete the active session. Use `session_search()` (browse, no args) to confirm.

**Also check OpenCode sessions** — OpenCode stores session data in a SQLite database at `~/.local/share/opencode/opencode.db` (not `~/.config/opencode/`). Old sessions can accumulate (observed: 115 sessions, ~177 MB). Clean via direct SQL:

```bash
# 0. Check current state
sqlite3 ~/.local/share/opencode/opencode.db "SELECT id, title, time_created, cost FROM session ORDER BY time_updated DESC LIMIT 5;"
sqlite3 ~/.local/share/opencode/opencode.db "SELECT COUNT(*) FROM session;"

# 1. Delete all sessions (cascades to session_message + session_context_epoch via FK CASCADE)
sqlite3 ~/.local/share/opencode/opencode.db "PRAGMA foreign_keys = ON; DELETE FROM session;"

# 2. Verify
sqlite3 ~/.local/share/opencode/opencode.db "SELECT COUNT(*) FROM session; SELECT COUNT(*) FROM session_message;"

# 3. VACUUM to reclaim disk space
sqlite3 ~/.local/share/opencode/opencode.db "VACUUM;"

# 4. Verify size
ls -lh ~/.local/share/opencode/opencode.db
```

**Schema notes:** `session_message` and `session_context_epoch` both have foreign keys with `ON DELETE CASCADE` to `session(id)` — so deleting from `session` automatically cascades. Always `PRAGMA foreign_keys = ON` first or the cascade won't fire. FTS/other tables (account, project, workspace) are untouched. This only clears conversation history/sessions. If the DB remains large (~156 MB after session cleanup), that's from project/account/workspace tables — not session data.

#### Approach B — CLI (use when SQLite access is restricted)

1. **Identify current session ID** — from the first row of `hermes sessions list` output
2. **List all sessions** — `hermes sessions list` + `hermes sessions stats` to confirm counts
3. **Clarify scope** — ask the user: keep recent ones too, or truly everything except this session?
4. **Delete in a loop** (skip the current session):
   ```bash
   CURRENT="<current_session_id>"
   for sid in $(hermes sessions list 2>/dev/null | tail -n +5 | awk '{print $NF}'); do
     if [ "$sid" != "$CURRENT" ]; then
       hermes sessions delete -y "$sid"
     fi
   done
   ```
   ⚠️ **Pitfall: `hermes sessions list` parsing can miss sessions with long titles** — cron sessions and sessions with multi-line previews get truncated or spread across lines, causing `awk '{print $NF}'` to miss or misidentify their IDs. After the loop, ALWAYS run `hermes sessions list` again to verify nothing was missed, and catch stragglers manually.
5. **Reclaim disk space**:
   ```bash
   sqlite3 ~/.hermes/state.db "VACUUM;"     # reclaims 50%+ typically
   sqlite3 ~/.hermes/lcm.db "VACUUM;"       # lcm.db won't shrink much — old lifecycle references persist
   ```
6. **Report** — sessions deleted + MB reclaimed. Note that the LCM database retains old lifecycle rows (~20 MB) — these are expected and harmless. They don't affect performance; only relevant if disk space is critically low.

**Pitfall: duplicate detection during extraction.** When extracting memories from multiple sessions that cover the same project/topic, entries about the same topic can accumulate (e.g. two partially-overlapping project-state entries). Always cross-check existing memory entries before adding, and scan for near-duplicates after each batch-write. Merge overlapping entries into one dense paragraph rather than keeping both fragments.

## Service Monitoring with System Crontab

System-level service monitoring (gateway watchdog, process keepalive) should use **system crontab**, not Hermes cron. Rationale:

- Hermes cron jobs depend on the agent runtime — if the gateway is down, Hermes cron may not fire reliably
- System crontab is independent of Hermes lifecycle
- A no-agent shell script is lighter and more reliable for simple health checks

### Setup Pattern

1. Write a watchdog script at `~/.hermes/scripts/` (bash, no agent involvement)
2. Add to crontab with `crontab -e` or pipeline
3. Verify with `crontab -l` and check the script log

### Concrete Example: Gateway Watchdog

See **`references/gateway-watchdog.md`** for the full recipe — a bash script that checks `hermes-gateway` systemd service every 5 minutes and restarts it if dead. Used instead of a Hermes cron job.

---

## Network Access in Restricted Environments

When the machine is behind a firewall (e.g., Great Firewall of China), a clash/mihomo proxy provides outside-world access. See **`references/clash-proxy-gfw.md`** for:

- Proxy ports, status check, and quick enable commands
- Managing the proxy with `clashctl`
- Git clone and npm install workarounds
- Background process proxy handling

### Proxy Autoheal Script

See **`~/.hermes/scripts/proxy-autoheal.sh`** — a self-healing script that updates subscriptions, pings all proxy nodes, selects the best 港澳台日韩+Singapore node under 500ms, switches to it, and ensures proxy env vars are set. Designed to be run on-demand or as a cron job. Logs to `~/.hermes/logs/proxy-autoheal.log`.

### Tun Mode — Sudo Key Required

When Tun is enabled, mihomo needs root privileges. **`~/.hermes/.env` has `SUDO_PASSWORD`** configured — see `references/clash-proxy-gfw.md` → "Sudo Key Configuration (Tun Mode)" for full setup steps including:

- Writing `/etc/sudoers.d/qn-mihomo` (allow `pkill` + `mihomo` binary)
- Patching `service_sudo_start` in clashctl to use direct sudo instead of `sudo sh -c nohup`
- Pitfall: `sudo -S` + heredoc stdin conflict → use temp file + `cp`
- Pitfall: `printf` vs `echo` for passwords with `$` characters

After setup, `clashctl off` and `clashctl on` work passwordlessly even with Tun mode enabled. The autoheal script can now fully restart mihomo after subscription updates.

### Known Block: Hermes Agent Init — OpenRouter Model Metadata Fetch

Hermes Agent makes an **unconditional HTTP fetch to `openrouter.ai/api/v1/models`** during `fetch_model_metadata()` at init time. In China, OpenRouter is blocked — the synchronous `requests.get()` blocks for ~10 seconds before timing out, delaying every session start.

**Workaround** (preferred over patching source):
- Keep mihomo proxy running so the fetch succeeds quickly
- After one successful fetch, the result is cached for 1 hour
- Upstream PR #46685 adds `HERMES_DISABLE_MODEL_METADATA` env var and better timeout — wait for it to merge, then `hermes update`

**Do NOT** modify Hermes Agent source code directly — upstream fixes are in progress, and local patches create merge conflicts.

---

## Curator Usage

`hermes curator` manages agent-created skills (archive stale ones, consolidate overlaps).

### Quick Status Overview

```bash
hermes curator status
```

Shows: total skills, active/stale/archived counts, most/least active skills, curator scheduling info.

### Fast Stale Check (preferred over `run --dry-run`)

`hermes curator run --dry-run` calls an LLM for full analysis and can hang. For a quick check of which skills are idle:

```bash
hermes curator prune --days 30 --dry-run
```

Replace `30` with the desired idle threshold. Shows skills idle >= N days without touching them.

### Automatic Archival

- Curator runs every 7 days by default
- Skills unused for 30+ days → stale
- Skills unused for 90+ days → archived (recoverable)
- Zero-activity skills cost no tokens (only descriptions in the available_skills list)
- Bundled and hub-installed skills are never touched

---

## Safe Deletion Checklist

Before `rm -rf` on any directory, verify zero side effects:

```bash
# 1. Check cron jobs
ls ~/.hermes/cron/jobs.json 2>/dev/null && grep -i <dirname> ~/.hermes/cron/jobs.json
crontab -l 2>/dev/null | grep -i <dirname>

# 2. Check config files for paths
grep -ri <dirname> ~/.hermes/config.yaml ~/.hermes/*.yaml 2>/dev/null

# 3. Check PATH / PYTHONPATH
echo $PATH | tr ':' '\n' | grep -i <dirname>
echo $PYTHONPATH | tr ':' '\n' | grep -i <dirname>

# 4. Check .pth files and site-packages references
find ~/.local -name "*.pth" -exec grep -l <dirname> {} \;

# 5. Check git submodules / .gitmodules
cat ~/.gitmodules 2>/dev/null

# 6. Cross-reference with `df -h` first to know how much you're about to free
df -h | head -2
du -sh <dirname>
```

---

## Pitfalls

- **`hermes sessions delete` supports `--yes`** — unlike earlier versions, the `delete` subcommand now accepts `--yes` to skip confirmation. No need for `echo "y" | ...` workaround.**`hermes --yolo` does NOT bypass this prompt.**
- **`hermes sessions delete` accepts exactly ONE session ID per call.** Passing multiple IDs gives "unrecognized arguments" error. Use a loop or call it repeatedly.
- **Cannot delete the currently-active session** — `hermes sessions delete` on the current session returns an error. Always keep at least the active session.
- **Deleting from `state.db` does NOT clean LCM lifecycle references.** After deleting sessions via `hermes sessions delete`, the LCM database (`~/.hermes/lcm.db`) retains stale lifecycle rows referencing deleted session IDs. LCM lifecycle fragmentation shows up in `lcm_doctor` as warnings about "stale_lifecycle_current" and "stale_lifecycle_finalized". These are harmless (no performance impact), but they can be cleaned up → see **"LCM Lifecycle Fragmentation Cleanup"** section above for the procedure. Always backup first.
- **`hermes sessions list` output is NOT safe for mechanical parsing** — sessions with long titles or multi-line previews (especially cron sessions with stack-trace-like previews) span multiple lines in the columnar output. `awk '{print $NF}'` will extract the wrong field on continuation lines, missing or misidentifying session IDs. Always verify the delete loop caught everything by re-running `hermes sessions list` and checking for survivors manually.
- **session_search only shows the first N sessions** — after heavy deletion, cross-check with `hermes sessions list` (CLI) which shows all sessions, vs `session_search()` (agent tool) which may paginate.
- **ARM64 Electron downloads timeout** — the Electron binary for ARM64 Linux is ~300MB+ and npm's default timeout (120s) is too short. Always use `--ignore-scripts` when installing workspace packages on ARM64 to skip the Electron postinstall script. If you need Electron (desktop app), install it separately with a longer timeout or pre-download the binary.
- **`npm install --all-workspaces` on ARM64** will try to download Electron for `apps/desktop`. Use explicit workspace flags to skip it.
- **Node symlinks** — `~/.local/bin/node` points to `~/.hermes/node/bin/node`. After replacing the bundled Node, the symlink still works because it points to the same path, just with new content.
- **agent-browser symlink** — the bundled Node's `bin/` directory has an `agent-browser` symlink pointing to the hermes-agent project's node_modules. This gets lost when replacing Node; must be recreated.
- **New Node.js releases** — check the architecture (`uname -m`): `aarch64` = `arm64`, `x86_64` = `x64`.
