# OpenCode Session Database

## Location

```
~/.local/share/opencode/opencode.db
```

SQLite database. WAL mode — check for `opencode.db-wal` and `opencode.db-shm` when sizing.

## Schema (session-related tables)

| Table | FK | Cascade |
|-------|----|---------|
| `session` | — | — |
| `session_message` | `session_id → session(id)` | ON DELETE CASCADE |
| `session_context_epoch` | `session_id → session(id)` | ON DELETE CASCADE |
| `session_input` | (not used in current schema) | — |

## Commands

### List sessions

```sql
SELECT id, title, slug, time_created, time_updated, cost
FROM session
ORDER BY time_updated DESC;
```

### Count sessions & messages

```sql
SELECT COUNT(*) FROM session;
SELECT COUNT(*) FROM session_message;
```

### Delete all sessions (cascade cleans messages & context epochs)

```bash
sqlite3 ~/.local/share/opencode/opencode.db \
  "PRAGMA foreign_keys = ON; DELETE FROM session;"
```

The CASCADE FK on `session_message` and `session_context_epoch` handles related rows. SQLite has foreign keys OFF by default in the CLI — `PRAGMA foreign_keys = ON` is required for the cascade to fire.

### Reclaim space after deletion

```bash
sqlite3 ~/.local/share/opencode/opencode.db "VACUUM;"
```

Deleting sessions frees internal pages but does not shrink the file on disk until VACUUM.

### Other tables (not affected by session deletion)

`account`, `account_state`, `project`, `project_directory`, `workspace`, `todo`, `migration` — these hold persistent configuration and are not cascaded from session deletion.

## Notes

- Discovered during Hermes session cleanup (2026-06-29): user asked to clear OpenCode sessions after clearing Hermes sessions. The initial `hermes sessions delete` workflow was already known; OpenCode's DB location was found by searching `~/.local/share/opencode/`.
- The DB was 177MB with 115 sessions and 204 messages before cleanup. After DELETE + VACUUM it dropped to 156MB (remaining size = project/account/workspace data).
