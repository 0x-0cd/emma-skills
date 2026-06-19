# Session Store Maintenance Reference

## Quick Command Reference

```bash
# List sessions
hermes sessions list --limit 20

# Show all sessions including skeleton ones (via direct sqlite3)
python3 -c "
import sqlite3
conn = sqlite3.connect('/home/qn/.hermes/state.db')
cur = conn.execute('SELECT id, source, title, message_count, started_at FROM sessions ORDER BY started_at')
rows = cur.fetchall()
for r in rows:
    print(f'{r[0][:30]:30s} | {r[1]:8s} | {(str(r[2])[:28] if r[2] else \"(no title)\"):28s} | msgs={str(r[3] or 0):>3s} | ts={int(r[4])}')
conn.close()
"

# Delete session
hermes sessions delete <session_id> --yes

# Optimize DB
hermes sessions optimize

# Stats
hermes sessions stats
```

## Target Session Cleanup Workflow

1. `session_search()` → browse recent sessions
2. `hermes sessions list` → check CLI view
3. Direct sqlite3 query → find hidden skeleton sessions
4. `session_search(session_id=...)` → read each target session
5. Extract facts → `memory` tool
6. `hermes sessions delete <id> --yes` per session
7. `hermes sessions optimize` → reclaim space
8. Check LCM health → `lcm_status` or `hermes doctor`

## Key Constraints

| Operation | Accepts `--yes`? | Accepts multiple IDs? | Notes |
|-----------|-----------------|----------------------|-------|
| `hermes sessions delete` | ✅ Yes | ❌ No, one per call | Must specify exact session ID |
| `hermes sessions prune` | ✅ Yes | N/A | Works by age/source filter |
| `hermes sessions optimize` | ❌ No | N/A | Runs automatically without prompt |

## LCM Lifecycle After Deletion

Deleting sessions from `state.db` does NOT remove references from `~/.hermes/lcm.db`. After deletion:

- `lcm_status` still shows the old session count in `lifecycle_fragmentation`
- `lcm_doctor` reports `stale_lifecycle_current` and `stale_lifecycle_finalized` warnings
- These are **benign** — leftover metadata rows, not leaked conversation content
- Only bother if disk space is critically low (the lcm.db footprint is usually <20MB)
