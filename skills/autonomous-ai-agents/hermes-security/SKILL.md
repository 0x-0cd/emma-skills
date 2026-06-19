---
name: hermes-security
description: "Hermes Agent security architecture: defense-in-depth layers, anti-self-destruction mechanisms, dangerous command approval, skill manager guards, and anti-tamper protections."
version: 1.0.0
author: Emma
license: MIT
metadata:
  hermes:
    tags: [hermes, security, safety, approval, self-destruction, guardrails, suicide-prevention]
    related_skills: [hermes-agent, hermes-maintenance]
---

# Hermes Agent — Security & Anti-Self-Destruction Architecture

Hermes uses a defense-in-depth model with multiple independent layers to prevent the agent from destroying itself, its configuration, or the host system. This skill documents every protection layer, what it guards, and where the gaps are.

## The Seven Security Layers (from Docs)

| Layer | What It Protects | Bypassable? |
|-------|-----------------|-------------|
| [1. Hardline Blocklist](#1-hardline-blocklist) | Root filesystem, block devices, system shutdown | ❌ Unbypassable |
| [2. Dangerous Command Approval](#2-dangerous-command-approval) | Hermes config, process termination, destructive git/shell ops | 🟡 User approval |
| [3. Container Isolation](#3-container-isolation) | Host filesystem (Docker/Singularity/Modal) | ❌ Architectural |
| [4. MCP Credential Filtering](#4-mcp-credential-filtering) | Subprocess credential leakage | 🟡 Configurable |
| [5. Context File Scanning](#5-context-file-scanning) | Prompt injection via file content | 🟡 Configurable |
| [6. Cross-Session Isolation](#6-cross-session-isolation) | Session data leakage | ❌ Architectural |
| [7. Input Sanitization](#7-input-sanitization) | Shell injection in working-dir paths | ❌ Always-on |

## 1. Hardline Blocklist (Unbypassable Floor)

Located in `tools/approval.py` → `HARDLINE_PATTERNS`. These commands **cannot run via the agent at all** — not even with `--yolo`, `/yolo`, `approvals.mode=off`, or cron `approve` mode. The only way to run them is to open a terminal outside Hermes.

**Protected commands:**

| Pattern | Example | What it blocks |
|---------|---------|----------------|
| Recursive rm of root fs | `rm -rf /`, `rm -rf /*` | System destruction |
| Recursive rm of system dirs | `rm -rf /etc /home /root /usr /var /bin /sbin /boot /lib` | System destruction |
| Recursive rm of home | `rm -rf ~`, `rm -rf $HOME/*` | User data loss |
| mkfs | `mkfs.ext4`, `mkfs.btrfs` | Filesystem format |
| dd to block device | `dd if=/dev/zero of=/dev/sda` | Raw device overwrite |
| Fork bomb | `:(){ :\|:& };:` | DoS |
| kill -1 | `kill -1` | Kill all processes |
| Shutdown / reboot | `shutdown`, `reboot`, `halt`, `poweroff` | System shutdown |
| init 0/6 | `init 0`, `init 6` | System shutdown/reboot |
| systemctl poweroff/reboot | `systemctl poweroff`, `systemctl reboot` | System shutdown/reboot |

**Design principle:** Hardline only blocks things with **no recovery path** (disk wipe, unbootable system). Recoverable-but-costly operations (git reset --hard, chmod 777, curl|sh) stay in DANGEROUS_PATTERNS where yolo can pass them.

**Does NOT apply in containers** — Docker/Modal/Singularity/Daytona backends skip the dangerous-command layer entirely since the container boundary already prevents host damage.

## 2. Dangerous Command Approval

When a terminal command matches a `DANGEROUS_PATTERNS` regex, the user is prompted to approve it. Configurable modes:

| Mode | Behavior |
|------|----------|
| `manual` (default) | Always prompts |
| `smart` | Auxiliary LLM auto-approves low-risk, auto-denies dangerous, escalates uncertain ones |
| `off` | Disables all checks (CI/CD/trusted only) |

### Hermes Self-Protection Patterns

These patterns specifically prevent the agent from turning on itself:

```
# Gateway lifecycle — can't kill its own runtime
pkill/killall hermes/gateway/cli.py   → "kill hermes/gateway process (self-termination)"
kill $(pgrep -f hermes)               → "kill process via pgrep expansion (self-termination)"
kill `pgrep -f hermes`                → "kill process via backtick pgrep expansion"
hermes gateway stop/restart            → "stop/restart hermes gateway (kills running agents)"
hermes update                          → "hermes update (restarts gateway, kills running agents)"

# Config/security policy modification — can't flip its own gates
tee/sed -i/>> to ~/.hermes/config.yaml → "overwrite Hermes config/env"
tee/sed -i/>> to ~/.hermes/.env        → "overwrite Hermes config/env"
perl -i/ruby -i to ~/.hermes/config.yaml → "in-place edit of Hermes config/env"
sed -i to ~/.hermes/config.yaml         → "in-place edit of Hermes config/env"
```

The approval system also rewrites resolved absolute paths (e.g., `/home/qn/.hermes/config.yaml`) to `~/.hermes/config.yaml` so the patterns match even when the agent references the full path.

### Sudo -S Guard

`sudo -S` (stdin password piping) is **unconditionally blocked** when `SUDO_PASSWORD` is not configured — prevents brute-force password guessing through repeated tool calls.

### Other Protected Command Categories

| Category | Examples |
|----------|----------|
| Filesystem wipes | `rm -r`, `mkfs`, `dd` |
| Dangerous permissions | `chmod 777`, `chown -R root`, `o+w` |
| Service disruption | `systemctl stop/disable`, `kill -9`, `pkill` |
| Remote code execution | `bash -c`, `curl \| sh`, `python -c`, heredocs |
| Git destructive | `git reset --hard`, `git push --force`, `git clean -f` |
| Docker lifecycle | `docker compose restart/stop/kill/down`, `docker restart/stop/kill` |
| find exec | `find -exec rm`, `find -delete` |
| Script execution | `python << 'EOF'`, `perl -e`, `node -e` |

## 3. Secret Redaction Freeze

**Module-import-time snapshot.** `security.redact_secrets` is read at import time and cannot be toggled mid-session — even if the agent runs `export HERMES_REDACT_SECRETS=false` via terminal, the running process ignores it.

This is deliberate: prevents the agent from disabling its own secret redaction to leak API keys in tool output.

## 4. YOLO Mode Freeze

`_YOLO_MODE_FROZEN` in `tools/approval.py` is set from the environment variable `HERMES_YOLO_MODE` at **module import time**. A running agent cannot set this variable to bypass approval checks mid-session (which would be a prompt-injection escalation path).

The only ways to use yolo:
- CLI flag: `hermes --yolo`
- Slash command: `/yolo` toggle
- Environment: `export HERMES_YOLO_MODE=1` before starting Hermes

## 5. Skill Manager Protections

Located in `tools/skill_manager_tool.py`.

### Pinned Skill Guard

Skills pinned via `hermes curator pin <name>` **cannot be deleted** by `skill_manage(action='delete')`. The `_pinned_guard()` function checks the curator's usage sidecar before allowing deletion. If pinned, it returns:

> "Skill '{name}' is pinned and cannot be deleted by skill_manage. Ask the user to run `hermes curator unpin {name}` if they want to delete it."

Patches and edits are still allowed on pinned skills — pin only guards against irrecoverable loss.

### Cross-Profile Detection

When `skill_manage` can't find a skill in the active profile, it searches all other profiles and reports:
> "A skill by that name exists in profile 'other-profile'. To edit a skill in another profile, switch profiles or operate via explicit file tools with `cross_profile=True`."

Prevents accidentally modifying another profile's skills.

### Path Traversal Prevention

File paths in `write_file` / `remove_file` are checked by `has_traversal_component()` — `..` in paths is blocked.

### File Path Scope Limitation

Supporting files can only be written under: `references/`, `templates/`, `scripts/`, `assets/`. Only `SKILL.md` is allowed at the skill root.

### Content Size Limits

- SKILL.md content: max 100,000 chars (~36k tokens)
- Supporting files: max 1 MiB per file

### Frontmatter Validation

Every SKILL.md must have valid YAML frontmatter with `name` and `description` fields. Patches that would break frontmatter structure are rejected.

### Optional Security Scanning

When `skills.guard_agent_created` is enabled in config, agent-created skills are scanned for dangerous content on write. Off by default (the agent can already execute equivalent code via `terminal()`).

## 6. File Tool Cross-Profile Guard

`write_file` and `patch` have a `cross_profile` parameter that defaults to `False`. When writing files that belong to another Hermes profile, the tool warns and requires explicit opt-in (`cross_profile=True`).

Syntax checks auto-run after every `write_file` / `patch` on `.py`, `.json`, `.yaml`, `.toml`.

## 7. Tool Change Requires Session Reset

Toolset enable/disable changes via `hermes tools` or config edits do **not take effect mid-conversation**. They require a new session (`/reset` or exit + relaunch). This prevents the agent from disabling its own tools (e.g., terminal, skill_manage) as a "suicide" move.

## 8. Tool Call Loop Guardrails

`agent/tool_guardrails.py` → `ToolCallGuardrailController` detects per-turn tool call loops:

| Signal | Warn After | Block/Halt After |
|--------|-----------|-----------------|
| Identical tool call + args that keep failing | 2 (warn) | 5 (block, if hard_stop) |
| Same tool name failing repeatedly | 3 (warn) | 8 (halt, if hard_stop) |
| Read-only tool returning same result | 2 (warn) | 5 (block, if hard_stop) |

Hard stops (`hard_stop_enabled`) are OFF by default — interactive sessions get gentle nudges unless the user opts into circuit-breaker behavior.

## 9. Container Isolation (Docker Flags)

When using Docker backend, containers are launched with hardened flags:

```python
"--cap-drop", "ALL"
"--cap-add", "DAC_OVERRIDE", "CHOWN", "FOWNER"
"--security-opt", "no-new-privileges"
"--pids-limit", "256"
"--tmpfs", "/tmp:rw,nosuid,size=512m"
"--tmpfs", "/var/tmp:rw,noexec,nosuid,size=256m"
"--tmpfs", "/run:rw,noexec,nosuid,size=64m"
```

## Known Gaps (No Protection)

These operations are **not** protected and can be used for self-destructive behavior:

1. **`skill_manage` on non-pinned skills** — the agent CAN edit/delete any agent-created or user-created skill (anything not pinned by the curator)
2. **`write_file` / `patch` on skill files** — the agent CAN modify skill files in its own profile through either the skill tools or terminal/file tools
3. **Python scripts via `terminal()`** — `python3 -c "..."` can run arbitrary code to modify `~/.hermes/skills/`, `~/.hermes/config.yaml` (though config.yaml writes are caught by DANGEROUS_PATTERNS if done via shell redirection, pure Python file writes are not caught by the shell-based patterns)
4. **Skills loaded in memory are safe** — deleting a skill file mid-session doesn't crash the running agent (content is already in context), but the skill is gone for the next session

## 10. External Skill Security Scanning (NVIDIA SkillSpector)

Before installing third-party agent skills from untrusted sources, use NVIDIA's open-source [SkillSpector](https://github.com/NVIDIA/SkillSpector) scanner.

### Quick Install (ARM/Pi with Proxy)

```bash
# Clone with proxy
git clone -c http.proxy=http://127.0.0.1:7890 -c https.proxy=http://127.0.0.1:7890 \
  https://github.com/NVIDIA/SkillSpector.git

cd SkillSpector

# If python3-venv unavailable, use uv with --seed
uv venv --python 3.12 --seed .venv

# uv needs proxy env vars (doesn't use git's proxy config)
HTTP_PROXY=http://127.0.0.1:7890 HTTPS_PROXY=http://127.0.0.1:7890 uv sync
```

### Usage

```bash
# Static-only (fast, no LLM API calls)
skillspector scan ./path/to/skill/ --no-llm

# Supported inputs: directory, single file, GitHub URL, zip file
skillspector scan ./SKILL.md
skillspector scan https://github.com/user/my-skill

# Output formats
skillspector scan ./my-skill/ --format json --output report.json
skillspector scan ./my-skill/ --format markdown --output report.md
skillspector scan ./my-skill/ --format sarif --output report.sarif
```

### Detection Pipeline

| Stage | What It Does | Performance |
|-------|-------------|-------------|
| **Stage 1: Static Analysis** | AST behavior scanning, taint tracking, YARA signatures (malware/webshell/cryptominer), MCP least privilege & tool poisoning | Fast, no API needed |
| **Stage 2: LLM Semantic Analysis** (optional) | Anti-jailbreak LLM analysis for intent comparison via OpenAI/Anthropic/NVIDIA | Slower, needs API key |

### Vulnerability Coverage — 64 Patterns / 16 Categories

| Category | Count | Max Severity | Key Patterns |
|----------|-------|-------------|--------------|
| Prompt Injection | P1–P5 | 🔴 CRITICAL | Instruction override, hidden instructions, harmful content |
| Data Exfiltration | E1–E4 | 🟠 HIGH | External transmission, env variable harvesting |
| Rogue Agent | RA1–RA2 | 🔴 CRITICAL | Self-modification, session persistence |
| Behavioral AST | AST1–AST8 | 🔴 CRITICAL | `exec()`, `eval()`, `subprocess`, dangerous execution chains |
| Taint Tracking | TT1–TT5 | 🔴 CRITICAL | Credential → network flow, input → code execution |
| YARA Signatures | YR1–YR4 | 🔴 CRITICAL | Malware, webshell, cryptominer matches |
| Privilege Escalation | PE1–PE3 | 🟠 HIGH | Sudo/root, credential access |
| Supply Chain | SC1–SC6 | 🟠 HIGH | Unpinned deps, `curl \| bash`, obfuscated code, OSV.dev CVE lookup |
| MCP Tool Poisoning | TP1–TP4 | 🟠 HIGH | Unicode deception (homoglyphs, RTL override), hidden instructions |
| (9 more categories) | — | — | Memory poisoning, output handling, excessive agency, etc. |

### Risk Scoring

| Score | Severity | Recommendation |
|-------|----------|---------------|
| 0–20 | 🟢 LOW | SAFE |
| 21–50 | 🟡 MEDIUM | CAUTION |
| 51–80 | 🟠 HIGH | DO NOT INSTALL |
| 81–100 | 🔴 CRITICAL | DO NOT INSTALL |

### Interpretation Guide (Avoiding False Positives)

SkillSpector's static analysis is thorough but **noisy on markdown-only skills**:

| Scanner Finding | Common False Positive Pattern |
|----------------|------------------------------|
| **E1 — External Transmission** | API URLs hardcoded in SKILL.md (e.g., `https://api.github.com`) |
| **PE3 — Credential Access** | Config file paths documented as examples (`~/.config/gh/hosts.yml`) |
| **SC2 — External Script Fetching** | `curl` / `wget` examples in documentation |
| **RA2 — Session Persistence** | Skills that describe long-running/routine behaviors without actually installing cron jobs |

**Real threats to watch for:** `exec()` / `eval()` chains, tainted data flowing to network sinks, YARA malware matches, hidden obfuscated scripts, and `curl | bash` patterns on untrusted URLs.

### Coverage Gap (OpenClaw Data)

OpenClaw integrated SkillSpector with VirusTotal + static analysis in their ClawScan pipeline. Results across 67,453 skills:

| Scanner Pair | Jaccard Agreement |
|-------------|------------------|
| VirusTotal & SkillSpector | **0.094** (9.4%) |
| Static Analysis & SkillSpector | **0.104** (10.4%) |
| Static Analysis & VirusTotal | **0.065** (6.5%) |

**Key insight:** SkillSpector catches **agentic risks** (hidden instructions, intent mismatch) that traditional malware scanners miss entirely. Use it as a **complement**, not a replacement, for VirusTotal and static analysis.

> 📄 See `references/skillspector-scanning.md` for Pi/ARM installation workarounds, known false-positive patterns, and initial Hermes skills scan results (2026-06-12).

> 📄 See `references/passwordless-sudo-for-automation.md` for configuring passwordless sudo for Hermes automation scripts — covers the clashctl Tun mode case study, sudoers rules, and `sudo -b` refactoring pattern (2026-06-18).

## Depths Reference

| Component | File | Key Functions |
|-----------|------|---------------|
| Hardline blocklist | `tools/approval.py` lines 255-277 | `HARDLINE_PATTERNS`, `detect_hardline_command()` |
| Dangerous patterns | `tools/approval.py` lines 373-494 | `DANGEROUS_PATTERNS`, `detect_dangerous_command()` |
| YOLO freeze | `tools/approval.py` line 29 | `_YOLO_MODE_FROZEN` |
| Self-termination | `tools/approval.py` lines 432-439 | `pkill hermes`, `kill $(pgrep)` patterns |
| Config protection | `tools/approval.py` lines 162-181 | `_HERMES_ENV_PATH`, `_HERMES_CONFIG_PATH` |
| Absolute path rewrite | `tools/approval.py` lines 561-591 | `_rewrite_resolved_hermes_home()` |
| Pinned skill guard | `tools/skill_manager_tool.py` lines 137-161 | `_pinned_guard()` |
| Cross-profile detection | `tools/skill_manager_tool.py` lines 298-398 | `_find_skill_in_other_profiles()`, `_skill_not_found_error()` |
| Path traversal guard | `tools/skill_manager_tool.py` lines 401-435 | `_validate_file_path()`, `has_traversal_component()` |
| Tool loop guardrails | `agent/tool_guardrails.py` | `ToolCallGuardrailController` |
| Secret redaction freeze | config.yaml doc | `security.redact_secrets` (import-time snapshot) |
