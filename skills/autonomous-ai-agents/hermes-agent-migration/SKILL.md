---
name: hermes-agent-migration
description: "Migrate and sync Hermes Agent identity across machines: skills repo (emma-skills public), soul data repo (hermes-soul private), export/import workflow, and automated daily cron sync at 02:00 UTC+8."
version: 1.1.0
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

Two repositories form the portable identity layer:

```
┌───────────────────────────────────────────────────────────┐
│ GitHub (0x-0cd)                                            │
│                                                           │
│  PUBLIC: emma-skills          PRIVATE: hermes-soul        │
│  ├─ skills/* (Emma's skills)  ├─ memory_store.db 🧠      │
│  ├─ install.sh                ├─ config.yaml ⚙️          │
│  └─ README                    ├─ .env + auth.json 🔑     │
│                               ├─ lcm.db + kanban.db 📜   │
│                               ├─ export-soul.sh          │
│                               └─ import-soul.sh          │
│                                                           │
│  Cron (daily 02:00 UTC+8)                                 │
│  ├─ session_search → detect changes                       │
│  ├─ ⚠️ Currently limited — see "The Daily Sync Cron"      │
│  └─ Reports to QQ (no auto-push yet)                      │
└───────────────────────────────────────────────────────────┘
```

### Repository Info

| Component | URL | Visibility | Contents | Typical Size |
|-----------|-----|-----------|----------|-------------|
| **emma-skills** | `github.com/0x-0cd/emma-skills` | 🔓 Public | Custom skills (book-reading-guide, karpathy-skill, hermes-self-evolution) + install.sh | ~1.5MB |
| **hermes-soul** | `github.com/0x-0cd/hermes-soul` | 🔒 Private | memory_store.db, config.yaml, .env, auth.json, lcm.db, kanban.db + export/import scripts | ~3.7MB (tarball) |
| **Daily Cron** | Job ID `6305f00fbeac` | — | Auto-sync at 02:00 daily, delivers report to QQ | — |

## emma-skills: What Belongs

**Only Emma-specific custom skills** that aren't part of Hermes's built-in catalog.

### ✅ Include
- Skills created by the agent (`created_by: agent` in frontmatter)
- Custom perspective skills (e.g., karpathy-skill)
- Custom tools (e.g., book-reading-guide — the book navigation guide)
- Nuwa-skill was previously included but has been removed (was disabled via config.yaml `platform_disabled`; deleted from disk 2026-06-20)
- Customized versions of any skill with meaningful modifications

### ❌ Exclude
- Generic Hermes skills (project-init, auto-format) — install via `hermes skills install` on target
- Skills in Hermes official categories: `autonomous-ai-agents/`, `creative/`, `data-science/`, `devops/`, `email/`, `github/`, `idea-workflow/`, `media/`, `mlops/`, `note-taking/`, `productivity/`, `red-teaming/`, `research/`, `smart-home/`, `social-media/`, `software-development/`, `superpowers/`, `apple/`
- Hub-installed skills (available via `hermes skills install <name>`)

### Current emma-skills contents
```
emma-skills/
├── README.md
├── install.sh         # Copies skills/ to ~/.hermes/skills/ (skips existing)
├── .gitignore
└── skills/
    ├── book-reading-guide/       # Book guide (custom)
    ├── karpathy-skill/           # Karpathy perspective 🧠
    └── hermes-self-evolution/    # Self-evolution pipeline 🔄
```

### Install on a new machine
```bash
git clone git@github.com:0x-0cd/emma-skills.git ~/emma-skills
cd ~/emma-skills && bash install.sh
hermes skills list | grep -E "book-reading-guide|karpathy|hermes-self-evolution"
```

## hermes-soul: Soul Data

Contains the scripts and data that define Emma's identity.

### Files Tracked

| File | Purpose | Sensitivity |
|------|---------|-------------|
| `memory_store.db` | Emma's personality + holographic facts + user preferences | 🔴 Contains personal info |
| `config.yaml` | All Hermes configuration (provider, model, etc.) | 🟡 Configuration |
| `.env` | All API keys | 🔴 Secrets! |
| `auth.json` | OAuth tokens | 🔴 Secrets! |
| `lcm.db` | Session compression context (~9MB) | 🟢 Transcripts |
| `kanban.db` | Kanban board data | 🟢 Task data |

### Export (on old machine)
```bash
cd ~/hermes-soul
# Basic export to local file
bash export-soul.sh

# Export + upload to GitHub Release (requires gh CLI)
bash export-soul.sh /tmp --upload

# Export + GPG encrypt
bash export-soul.sh /tmp --encrypt
```

### Import (on new machine)
```bash
cd ~/hermes-soul
# From local file
bash import-soul.sh hermes-soul-20260613_012617.tar.gz

# From GitHub Release (latest)
bash import-soul.sh --from-gh 0x-0cd/hermes-soul

# From GitHub Release (specific version)
bash import-soul.sh --from-gh 0x-0cd/hermes-soul soul-20260613_012617
```

### When to Update Soul
- `memory_store.db` modified (new facts, memory cleanup)
- `config.yaml` changed (provider switch, model change, memory cap change)
- Before a major machine migration

No need to update for routine `lcm.db` changes (session compression rotates daily).

## The Daily Sync Cron

A cron job runs every day at **02:00 Beijing time (UTC+8)**. Its prompt is stored in `references/daily-cron-prompt.md`.

**⚠️ Known limitation (as of 2026-06-20):** The actual deployed cron prompt is a simplified version that only checks mtime on existing `~/emma-skills/skills/` files. It does NOT:
- Detect skill additions/removals (e.g., nuwa-skill was on disk but never git-rm'd)
- Run `diff` between `~/.hermes/skills/` and `~/emma-skills/skills/`
- Auto-commit or push any changes
- Check `hermes-soul` at all

See the reference file for the ideal full prompt. If you update the cron job, replace its prompt with the full version from the reference.

```bash
# View cron
hermes cron list

# Update cron prompt
hermes cron update <job-id> --prompt "$(cat references/daily-cron-prompt.md)"
```

**Toolsets enabled:** terminal, file, session_search  
**Deliver to:** QQ (origin).  
**Note:** Cron runs with `skip_memory=True` — no MEMORY.md/USER.md injected. The prompt must be self-contained.

## Migration Workflow: New Machine (Full)

```bash
# 1. Install Hermes
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# 2. Clone both repos
git clone git@github.com:0x-0cd/hermes-soul.git ~/hermes-soul
git clone git@github.com:0x-0cd/emma-skills.git ~/emma-skills

# 3. Restore soul (memory + config + secrets)
cd ~/hermes-soul && ./import-soul.sh --from-gh 0x-0cd/hermes-soul

# 4. Install skills
cd ~/emma-skills && bash install.sh

# 5. Verify
hermes doctor          # Check config + API keys
hermes                 # Launch — Emma should recognize you 🥹
```

## Updating the Repos (Manual)

### emma-skills
```bash
cd ~/emma-skills

# Add a new skill
cp -r ~/.hermes/skills/<new-skill> skills/
# Update README if needed

# Remove a skill that shouldn't be there
rm -rf skills/<generic-skill>

git add -A
git commit -m "♻️ 同步：添加/更新 [技能名]"
git push origin main
```

### hermes-soul
```bash
cd ~/hermes-soul
git pull
bash export-soul.sh /tmp --upload
# This creates a new GitHub Release with the fresh data
```

## Pitfalls

- **Don't put generic Hermes skills in emma-skills** — Duplicates waste space and drift from upstream. Let the target machine `hermes skills install` them.
- **hermes-soul is PRIVATE** — Contains API keys (`.env`) and OAuth tokens (`auth.json`). Never make it public.
- **Tarball includes secrets** — Use `--encrypt` (GPG) for extra security if transferring over untrusted channels.
- **gh CLI required** — The export script needs `gh release create`. Verify with `gh auth status`.
- **Export needs disk space** — The tarball is ~3.7MB but the temp directory needs room for packaging.
- **Cron prompt is self-contained** — Don't rely on MEMORY.md in the cron prompt. All paths, repo URLs, and decision logic must be explicit in the prompt.
- **SSH key required for emma-skills push** — Public repo uses SSH URL. Ensure `~/.ssh/id_*` is configured on the machine.
- **Cron job ID might change** — If the job is deleted and recreated, the ID changes. Check `hermes cron list` for the current ID.
- **Cron prompt drifts from reference** — The `references/daily-cron-prompt.md` contains the ideal prompt, but the actually-deployed cron prompt can be a different (simplified) version. Always verify the deployed prompt matches after creation or update via `hermes cron list` (preview) or by examining the cron session output.
- **Properly removing a disabled skill** — Disabling via `platform_disabled` in config.yaml hides it from `skills_list` but leaves the files on disk (~67MB wasted for nuwa-skill). Full cleanup: `rm -rf ~/.hermes/skills/<skill>/` + `sed -i '/<skill-name>/d' ~/.hermes/config.yaml`. The config.yaml removal must target `platform_disabled.cli` and `platform_disabled.qqbot` separately (they're different lists).
