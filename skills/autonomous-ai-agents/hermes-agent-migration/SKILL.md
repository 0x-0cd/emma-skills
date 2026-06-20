---
name: hermes-agent-migration
description: "Migrate and sync Hermes Agent identity across machines: skills repo (emma-skills public), soul data repo (hermes-soul private), export/import workflow, and automated daily cron sync at 02:00 UTC+8."
version: 2.0.0
author: Emma
tags:
  - hermes
  - migration
  - sync
  - backup
  - cron
  - identity
  - portability
metadata:
  hermes:
    tags: [hermes, migration, sync, backup, cron, identity, portability]
    related_skills: [hermes-memory-workflow, hermes-maintenance]
---

# Hermes Agent — Identity Migration & Sync

> **Prerequisite:** `hermes-memory-workflow` covers the in-session memory system. This skill covers the cross-machine portability layer — moving Emma's full identity (skills + memory + config) between machines.

## Architecture Overview

Two repositories + one automated cron script form the portable identity layer:

```
┌───────────────────────────────────────────────────────────┐
│ GitHub (0x-0cd)                                            │
│                                                           │
│  PUBLIC: emma-skills          PRIVATE: hermes-soul        │
│  ├─ skills/* (37 custom)      ├─ export-soul.sh          │
│  ├─ install.sh                ├─ import-soul.sh          │
│  └─ README                    ├─ install.sh (new)         │
│                               └─ README                   │
│                                                           │
│  Cron (daily 02:00 UTC+8, no_agent=true)                  │
│  └─ ~/.hermes/scripts/sync-all.sh                         │
│       ├─ scan ~/.hermes/skills/ → emma-skills git push    │
│       └─ export-soul.sh → hermes-soul GitHub Release      │
└───────────────────────────────────────────────────────────┘
```

### Key Design Decision: no_agent Script > LLM Cron

The old cron was LLM-powered (session_search → detect → report). It was a **空转** pattern — burned tokens every night, only reported "no change", never actually pushed anything.

The new approach: **no_agent=true bash script**. Deterministic, zero-token runtime, actually modifies repos, delivers stdout directly. Use this pattern for any repetitive synchronization task.

### Repository Info

| Component | URL | Visibility | Contents | Typical Size |
|-----------|-----|-----------|----------|-------------|
| **emma-skills** | `github.com/0x-0cd/emma-skills` | 🔓 Public | 37 custom skills across 13 categories + install.sh | ~1.5MB |
| **hermes-soul** | `github.com/0x-0cd/hermes-soul` | 🔒 Private | export/import/install scripts + GitHub Releases (memory data) | ~1MB (scripts), ~11MB (tarball) |
| **Cron Script** | `~/.hermes/scripts/sync-all.sh` | — | no_agent bash; runs daily at 02:00; outputs to QQ | — |

## emma-skills: What Belongs

**Only Emma-specific custom skills** — anything in `~/.hermes/skills/` that is NOT in `~/.hermes/hermes-agent/skills/`.

### Detection Logic

```bash
# Built-in skill index
declare -A BUNDLED_MAP
while IFS= read -r -d '' dir; do
  rel="${dir#~/.hermes/hermes-agent/skills/}"
  BUNDLED_MAP["$rel"]=1
done < <(find ~/.hermes/hermes-agent/skills -mindepth 2 -maxdepth 2 -type d -print0)

# Categorized custom skills (inside bundled categories but not bundled themselves)
find ~/.hermes/skills -mindepth 2 -maxdepth 2 -type d | while read dir; do
  rel="${dir#~/.hermes/skills/}"
  [[ -z "${BUNDLED_MAP[$rel]:-}" ]] && echo "CUSTOM: $rel"
done

# Uncategorized custom skills (directly under ~/.hermes/skills/, not in bundled)
find ~/.hermes/skills -maxdepth 1 -type d | while read dir; do
  base="$(basename "$dir")"
  [[ -d "~/.hermes/hermes-agent/skills/$base" ]] && continue  # bundled category
  [[ "$base" == .* ]] || [[ "$base" == _* ]] && continue
  [[ "$base" == apple ]] && continue
  [ -f "$dir/SKILL.md" ] && echo "CUSTOM: $base"
done
```

### ❌ Excluded
- Generic Hermes skills that ship with the agent (in `~/.hermes/hermes-agent/skills/`)
- Disabled skills (`~/.hermes/skills/_disabled/`)
- Hidden/system files

### Current emma-skills contents

```
skills/
├── autonomous-ai-agents/
│   ├── acp-delegation/
│   ├── chinese-messaging-platforms/
│   ├── hermes-agent-migration/       ← this skill itself!
│   ├── hermes-maintenance/
│   ├── hermes-memory-workflow/
│   ├── hermes-provider-config/
│   ├── hermes-security/
│   └── hermes-token-optimization/
├── book-reading-guide/               # External download
├── creative/
│   └── technical-blog-writing/
├── dogfood/
│   └── hermes-self-evolution/        # Hermes auto-created
├── github/
│   └── github-profile-design/
├── idea-workflow/                    # Custom category
│   ├── idea-superpowers-suite/
│   ├── idea-to-design-doc/
│   ├── idea-to-implementation-doc/
│   └── idea-to-ui-design-brief/
├── karpathy-skill/                   # Deleted 2026-06-19 in commit 23548d0
├── mlops/
│   ├── memory-system-evaluation/
│   └── onnx-embeddings/
├── productivity/
│   ├── community-resources/
│   └── github-blog/
├── red-teaming/
│   └── godmode/
├── research/
│   ├── chinese-content-research/
│   ├── evidence-based-health-analysis/
│   ├── media-crawler-pipeline/
│   ├── paper-deep-dive/
│   └── research-backed-validation/
├── software-development/
│   ├── code-project/                # Emma written
│   ├── code-task/                   # Emma written
│   └── opencode-skills-portfolio/
└── superpowers/                     # Custom category
    ├── brainstorming/
    ├── dispatching-parallel-agents/
    ├── using-hermes-skills/
    └── writing-skills/
```

Total: **37 custom skills** across **15 category/subcategory groups** (as of skill creation; karpathy-skill was deleted 2026-06-19, count may differ — run `ls ~/emma-skills/skills/` to verify).

### Install on a new machine

```bash
git clone git@github.com:0x-0cd/emma-skills.git ~/emma-skills
cd ~/emma-skills && bash install.sh
# install.sh auto-detects existing skills and skips them
# New skills are placed preserving category structure
hermes skills list
```

## hermes-soul: Soul Data

Private repo containing scripts to backup/restore Emma's identity data. The actual data (memory_store.db, config, secrets, lcm.db, kanban.db) is stored as **GitHub Releases** via tar.gz, not directly in git.

### Files Backed Up

| File | Purpose | Sensitivity | Typical Size |
|------|---------|-------------|:----:|
| `memory_store.db` | Emma's personality + holographic facts | 🔴 Personal data | 216K |
| `config.yaml` | All Hermes configuration | 🟡 Config | 20K |
| `.env` | API keys | 🔴 **Secrets!** | 24K |
| `auth.json` | OAuth tokens | 🔴 **Secrets!** | 4K |
| `lcm.db` | Session compression context | 🟢 Transcripts | 31M |
| `kanban.db` | Kanban board data | 🟢 Task data | 112K |

### Export (automated by cron, or manual)

```bash
cd ~/hermes-soul
bash export-soul.sh               # Create tar.gz locally
bash export-soul.sh /tmp --upload # Create + upload to GitHub Release
```

### Import / Restore

```bash
cd ~/hermes-soul
# From local file
bash import-soul.sh hermes-soul-YYYYMMDD_HHMMSS.tar.gz

# From GitHub Release (via gh CLI)
bash import-soul.sh --from-gh 0x-0cd/hermes-soul

# One-click (clone → download latest Release → restore)
bash install.sh
```

## The Automated Sync (Cron)

Single cron job (`6305f00fbeac`) runs **daily at 02:00 Beijing time**.

### ⚠️ Current State (as of 2026-06-20) — Migration Pending

**The cron is STILL running in LLM-prompt mode, NOT the no_agent bash script described below.** The intended migration to `no_agent=true` + `sync-all.sh` hasn't been completed.

Current cron config:
- Mode: LLM-driven (has an LLM prompt, enabled_toolsets=[terminal, file, session_search])
- No `script` set, no `no_agent` flag
- Last status: ok (runs nightly, reports "no change" because its detection logic is incomplete)

**Known design flaw in current LLM cron:** It only checks modification timestamps of 4 specific public skills (`book-reading-guide/hermes-self-evolution/karpathy-skill/nuwa-skill`) under `~/emma-skills/skills/`. It does NOT check:
- `~/.hermes/config.yaml` changes (especially `platform_disabled` additions/removals)
- `git status` in `~/emma-skills/` for unpushed commits
- Disk state vs config.yaml references (e.g., skill directory exists but was disabled in config, or vice versa)
- Files outside those 4 skills (e.g., new skills or removed ones)

This means after a skill audit that modifies 14+ SKILL.md files, adds/removes `platform_disabled` entries, and reorganizes `_disabled/` directories, the cron reports "no change — skipping sync."

**To migrate to no_agent:**
```bash
# 1. Confirm sync-all.sh exists and is executable
ls -la ~/.hermes/scripts/sync-all.sh

# 2. Update the cron job to no_agent mode
# cronjob(action='update', job_id='6305f00fbeac', script='sync-all.sh', no_agent=true)
```

### Intended Design (no_agent bash, not yet active)

Mode: `no_agent=true` — runs `~/.hermes/scripts/sync-all.sh` directly without an LLM.

### What sync-all.sh Does

**Phase 1 — emma-skills sync:**
1. Build bundled skill index from `~/.hermes/hermes-agent/skills/`
2. Scan `~/.hermes/skills/` — find all custom skills (not in bundled index, not `.`/`_`/`apple`)
3. Copy each custom skill to `~/emma-skills/skills/` (preserving category structure)
4. Remove stale skills from repo that no longer exist in source
5. If anything changed: `git add -A && git commit && git push origin main`

**Phase 2 — hermes-soul sync:**
1. Run `export-soul.sh /tmp` to create tar.gz of all identity files
2. Upload as GitHub Release via `gh release create`
3. Clean up Releases older than 30 days (keep max ~10)
4. Remove temp tar.gz files

### Design Principles for Cron Scripts

- **Prefer no_agent bash scripts** over LLM cron prompts for deterministic tasks. LLM cron jobs burn tokens on "空转" (detecting no-change and reporting it). Save LLM cron jobs for tasks that need reasoning (summarize feeds, draft briefings, pick interesting items).
- **Script path resolves under `~/.hermes/scripts/`** — relative paths work (e.g., `script: sync-all.sh`).
- **Cron runs with no `prompt` when `no_agent=true`** — `prompt` and `skills` are ignored; only `script` matters.
- **stdout is delivered verbatim** to the target (QQ). Design the script's output as the status report.
- **Context‑from chaining** works when you need data collection + processing in separate ticks.
- **`deliver` auto-detects** the current chat — for daily reports that land in QQ, omit `deliver` (auto), or pass explicit `origin`.

### Config Reference

```yaml
# In cron job definition (via cronjob tool):
# action: create (or update)
# job_id: 6305f00fbeac
# name: 🧠 Emma 全能同步
# schedule: 0 2 * * *
# script: sync-all.sh
# no_agent: true
# enabled_toolsets: []  # no tools needed — script uses its own commands
```

## Migration Workflow: New Machine (Full)

```bash
# 1. Install Hermes Agent
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# 2. Clone both repos
git clone git@github.com:0x-0cd/hermes-soul.git ~/hermes-soul
git clone git@github.com:0x-0cd/emma-skills.git ~/emma-skills

# 3. Restore soul (memory + config + secrets) — requires gh CLI auth'd
cd ~/hermes-soul && bash install.sh
# This downloads the latest GitHub Release and restores to ~/.hermes/

# 4. Install custom skills
cd ~/emma-skills && bash install.sh
# Copies all skills to ~/.hermes/skills/, preserves category structure

# 5. Verify
hermes doctor          # Check config + API keys
hermes                 # Launch — Emma should recognize you 🥹
```

## Manual Operations

Normally both repos are auto-synced by the daily cron. Manual intervention is rarely needed.

### Force a sync immediately

```bash
bash ~/.hermes/scripts/sync-all.sh
```

### Add a new custom skill mid-cycle

No action needed — the cron will pick it up at 02:00. If you want it pushed right now:

```bash
bash ~/.hermes/scripts/sync-all.sh
```

### Revert a bad emma-skills push

```bash
cd ~/emma-skills
git revert HEAD
git push origin main
```

### Revert a bad hermes-soul Release

Old Releases are kept for 30 days. To restore a specific version:

```bash
cd ~/hermes-soul
gh release download soul-<timestamp> --repo 0x-0cd/hermes-soul --dir /tmp/
bash import-soul.sh /tmp/hermes-soul-<timestamp>.tar.gz
```

## Pitfalls

- **Skill describes cron as no_agent, but it isn't** — As of 2026-06-20, the soul sync cron (6305f00fbeac) still runs the old LLM-prompt mode, not the `sync-all.sh` bash script described in this skill's "Automated Sync" section. The migration hasn't been executed. Check the cron's actual config via `cronjob(action='list')` before assuming the mode.
- **LLM cron's change detection is incomplete** — The current LLM cron only checks file modification timestamps of 4 specific public skills. It won't detect config.yaml changes, `platform_disabled` changes, disk-vs-config mismatches, or unpushed commits. If you're seeing "no change" reports when you know something changed, this is why.

- **gh CLI must be authenticated** — `gh auth status` before `sync-all.sh` runs. If gh session expires, the soul sync phase fails silently (logged in script output).
- **SSH key for emma-skills push** — Public repo uses SSH URL. Ensure `~/.ssh/id_*` is configured.
- **No duplicate notifcations** — `no_agent=true` scripts don't trigger completion notifications. The stdout IS the notification (delivered as a message). If the script runs silently (nothing to do), QQ gets a "no changes" report.
- **Script must be self-contained** — no reliance on environment variables set by interactive sessions. `sync-all.sh` sets its own paths.
- **`red-teaming/godmode` is synced** — This is a custom skill added within a non-bundled category. It will be included in emma-skills. If privacy concerns arise, add it to the exclusion list in the script.
- **`book-reading-guide` and `karpathy-skill` are uncategorized** — They live directly under `skills/` in the repo rather than in a category folder. This is fine — the install.sh preserves their location.
- **Old tar.gz files accumulate in /tmp** — `sync-all.sh` cleans up after itself (`rm -f "$ARCHIVE"`), but if the export step crashes, a stray ~11MB tar.gz may remain. Monitor `/tmp` if disk space is tight.
- **hermes-soul is PRIVATE** — Contains API keys (`.env`) and OAuth tokens (`auth.json`). Never make it public. The tar.gz releases inherit the repo's privacy.
- **Don't put generic Hermes skills in emma-skills** — The sync script properly excludes bundled skills. Manually adding them would waste space and drift from upstream.
