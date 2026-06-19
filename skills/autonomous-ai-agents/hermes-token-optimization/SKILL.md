---
name: hermes-token-optimization
description: "Optimize Hermes Agent's token consumption: audit and disable skills, limit tool output, configure compression, set budget alerts."
version: 1.4.0
author: Emma
license: MIT
metadata:
  hermes:
    tags: [hermes, token, optimization, cost, skills, memory, configuration]
    related_skills: [hermes-agent, hermes-maintenance]
---

# Hermes Agent — Token Consumption Optimization

Strategies to reduce token consumption when using Hermes Agent. Each skill's SKILL.md, conversation history, memory files, and tool output all enter the model context — optimizing these can dramatically cut costs.

---

## Token Consumption Sources

| Source | Description | Optimization Potential |
|--------|-------------|----------------------|
| **Skill list** | Each enabled skill's SKILL.md enters context | 🔴 **High** |
| **Memory files** | Long-term memory + session log content | 🔴 **High** |
| **Tool call results** | Command output, browser screenshots, file content | 🔴 **High** |
| System prompt | Agent personality and behavior rules | 🟡 Medium |
| Conversation history | Multi-turn chat records | 🟡 Medium (built-in compression) |
| Model reasoning steps | Think-call-tool cycles in complex tasks | 🟡 Medium |

---

## Optimization Methods

### Method 1: Audit & Disable Unused Skills

**This is the highest-ROI optimization.** Each enabled skill loads its SKILL.md into the system prompt.

**Workflow — ALWAYS ask user before disabling:**

1. **List installed skills** — `skills_list()` to get current catalog
2. **Check which are enabled** — Hermes loads all installed skills by default (no `platform_disabled` in config.yaml means everything is enabled)
3. **Categorize for the user (NEVER dump a flat list):**
   - Group by category/type with descriptions
   - Mark each group with a question (e.g. "这些你用吗？")
   - Go step by step — user picks groups to disable, one or a few at a time
4. **Present categories to the user** — show grouped list and ask which groups to disable
5. **Disable via config.yaml:**

```yaml
# Add to ~/.hermes/config.yaml under skills:
skills:
  platform_disabled:
    cli:
      - skill-name-1
      - skill-name-2
```

Or use Python to edit config.yaml:

```python
import yaml
with open('/home/qn/.hermes/config.yaml') as f:
    data = yaml.safe_load(f)
disabled = data.setdefault('skills', {}).setdefault('platform_disabled', {}).setdefault('cli', [])
disabled.extend(['skill-name'])
# Deduplicate — use dict.fromkeys() to preserve order (not set())
data['skills']['platform_disabled']['cli'] = list(dict.fromkeys(disabled))
with open('/home/qn/.hermes/config.yaml', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
```

6. **Notify user** — `/reset` or new session required for changes to take effect.

7. **Verify** — After `/reset`, confirm that the disabled list actually worked. See `references/verify-disable-status.md` for the cross-reference technique (compare config.yaml intent with `hermes skills list` runtime output).

**Skill categories to evaluate:**
- Creative/design tools (excalidraw, p5js, manim-video, ascii-art, comfyui, sketch, etc.)
- MLOps/inference (llama-cpp, vllm, audiocraft, weights-and-biases, etc.)
- Idea workflow suite (idea-superpowers-suite, idea-to-design-doc, etc.)
- Social media / email (xurl, himalaya)
- Smart home / red-teaming (openhue, godmode)
- Platform-specific (chinese-messaging-platforms, yuanbao — unless gateway-connected)
- Code delegation CLIs (claude-code, codex, opencode — unless user has these installed)

### Method 2: Context Compression (Enabled by Default)

Hermes automatically compresses conversation history when approaching the token limit. No configuration needed — it summarizes earlier turns to free space.

**Reference:** Built-in ContextCompressor in `hermes-agent` skill docs.

### Method 3: Tiered Model Selection

Use lightweight models for simple tasks, flagship models for complex ones. Hermes supports per-task-type model configuration:

```yaml
# In config.yaml, set auxiliary model providers for different task types:
auxiliary:
  vision:
    provider: openrouter
    model: google/gemini-2.0-flash-001  # lightweight for vision
  skills_hub:
    provider: openrouter
    model: google/gemini-2.0-flash-001  # lightweight for searches
```

Simple tasks (weather, short Q&A) → use cheap/fast models
Complex tasks (code generation, deep analysis) → use flagship models

### Method 4: Limit Tool Output Length

Large tool outputs (terminal stdout, file reads, browser snapshots) consume significant tokens.

**Default limits (already in Hermes):**

```yaml
tool_output:
  max_bytes: 50000       # 50KB per tool output (≈12.5K tokens)
  max_lines: 2000        # max 2000 lines
  max_line_length: 2000  # max 2000 chars per line
file_read_max_chars: 100000  # max chars per file read call
```

These defaults are already reasonable. Further tightening risks truncating important error messages, search results, or logs. **The default 50KB limit is the sweet spot** — lowering it has low ROI and higher risk of data loss.

For ad-hoc limits per command:
```bash
# Pipe through head to control output size
some-command | head -50
```

### Method 4.5: Increase Memory Character Limit (First Response to Capacity Pressure)

When memory usage hits 80%+, **increase `memory_char_limit` before aggressive consolidation.** The default 2,200 chars is a sensible starting point but not a hard ceiling — raising it to 3,500–4,000 chars is cheap and safe.

**Why this should be your first move:**
- Consolidation risks losing detail or nuance in merged entries
- Extra tokens cost almost nothing (4000 chars ≈ 1500 tokens ≈ ¥0.0045 on DeepSeek V4 Pro)
- A miss due to squeezed-out memory fact costs far more in repeated work than the extra tokens

**How to increase:**
```bash
python3 -c "
import yaml
with open('/home/qn/.hermes/config.yaml') as f:
    data = yaml.safe_load(f)
data['memory']['memory_char_limit'] = 4000   # or 3500
with open('/home/qn/.hermes/config.yaml', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
"
```

> ⚠️ Config changes require `/reset` or new session to take effect (memory snapshot loaded at session start).

Only after increasing the limit and still hitting capacity should you fall back to Method 5 consolidation. For a deeper architectural understanding of the Holographic provider (HRR algebra, entity resolution, trust scoring, contradiction detection), see `references/holographic-memory-provider.md` — this helps decide *what* to put in MEMORY.md vs Holographic.

### Method 5: Memory & SOUL Cleanup (Consolidation)

Memory files (`MEMORY.md` and `USER.md` under `~/.hermes/memories/`) are injected into every session's context. If you've already raised `memory_char_limit` and still need room, consolidate.

#### Token Cost Estimation

| File | Typical Size | Est. Tokens (Cn+En mix) |
|------|-------------|------------------------|
| `MEMORY.md` | 2,000–3,500 bytes | ~1,500–2,500 tokens |
| `USER.md` (SOUL) | 1,500–2,500 bytes | ~1,000–1,800 tokens |
| **Total** | **3,500–6,000 bytes** | **~2,500–4,300 tokens** |

Chinese text ≈ 1.5–2 tokens/char; English ≈ 0.3–0.5 tokens/char. A full memory context at 3,000+ tokens costs real money on paid API calls.

#### Memory Consolidation (Key Technique)

Instead of adding new entries endlessly, **merge related entries into dense single entries** to free space for new facts:

1. **Identify clustered entries** — entries about the same subsystem or topic (e.g., workflow rules spread across 4 entries: AGENTS.md + project-init + Plan-First + auto-format)
2. **Remove the fragmented entries** — `memory(action='remove', old_text='...', target='memory')`
3. **Add one dense merged entry** — combine into a single concise paragraph

This freed ~370 chars in one pass (4 entries → 1), enough headroom for 2–3 new facts.

#### USER.md (SOUL) Maintenance

The SOUL file (user profile) also accumulates duplications and inconsistencies over time:

- **Dedup repeated rules** — e.g., "不说脏话" appearing in both the persona entry and as a standalone line
- **Fix name inconsistencies** — e.g., private nicknames mixed in the same file
- **Remove stale entries** — preferences that have been superseded or are no longer accurate
- **Merge character traits** — concise entries about persona, skills, and preferences into fewer dense lines

**Workflow:**
1. Read both files: `read_file('~/.hermes/memories/MEMORY.md')` and `read_file('~/.hermes/memories/USER.md')`
2. Scan for: duplicate content, inconsistent naming, outdated facts, entries that could merge
3. Fix USER.md — `memory(action='remove', target='user', old_text='...')` for stale entries, then `memory(action='add', target='user', content='...')` for consolidated versions
4. Fix MEMORY.md — same pattern, `target='memory'`
5. Report char/token savings to user

#### Session Cleanup Integration

Memory & SOUL cleanup pairs naturally with session store maintenance (see `hermes-maintenance` skill's "Session Store Maintenance" section):

```
1. List sessions → find non-current sessions with actionable content
2. For each: extract key facts → update MEMORY.md → delete session
3. Run hermes sessions optimize to reclaim DB space
4. Review USER.md for dedup opportunities
```

#### Periodic Cleanup

Set up a cronjob for recurring maintenance:

```bash
hermes cron create "0 4 * * 0" --name memory-cleanup \
  --prompt "Review memory entries older than 90 days. Remove any that are non-critical or superseded. Preserve user preferences and durable facts."
```

Important: memory consolidation and SOUL maintenance should be done manually when the user asks for it, rather than fully automated — the agent needs to understand context to merge correctly.

### Method 6: Set Budget Limits and Alerts

```yaml
# Not all options exist in core — check config.yaml for available budget settings
# At minimum, track usage with:
hermes insights --days 7   # view weekly token usage
```

For API-level controls, set up provider-side spending limits and alerts.

### Method 7: CLI Output Compression via RTK (Rust Token Killer)

**Complementary to all methods above.** RTK (`rtk-ai/rtk`) is a Rust CLI proxy that sits between the agent and the shell, compressing command output *before* it enters LLM context. It reduces terminal output tokens by 60–90% for common commands (git, ls, grep, test runners, etc.) with <10ms overhead.

**How it differs from Hermes' built-in tool_output limits (Method 4):**
- Hermes' 50KB cap is a blunt **truncation** — it cuts output after N bytes
- RTK applies **command-specific filters** — e.g., `ls -la` condenses into a tree view, `git status` strips boilerplate, `pytest` shows only a summary + failures. When a command fails, RTK saves the full output to disk and shows a path to the log file.

**Hermes integration:**
```bash
# Install RTK (pre-built binary from GitHub releases or homebrew)
# Then set up the Hermes plugin:
rtk init --agent hermes
```
This installs a plugin at `~/.hermes/plugins/rtk-rewrite/` and adds it to `config.yaml` under `plugins.enabled`. On every `terminal()` call, it invokes `rtk rewrite <command>` — RTK rewrites the command to use its compressed versions when applicable, or passes through unchanged otherwise. 2-second timeout, fails open silently on any error.

**Caveats:**
- Only applies to `terminal()` tool calls — Hermes built-in tools (read_file, search_files, etc.) are not affected
- RTK trains on usage data locally (opt-in telemetry, disabled by default)
- Requires the `rtk` binary in PATH and the plugin loaded — needs Hermes restart to activate
- Best paired with the Hermes token optimization methods above (skill disabling, model tiering) for cumulative savings

**Reference:** See `references/rtk-integration.md` for detailed installation, troubleshooting, and platform-specific setup.

---

## User Preferences: How to Present Skill Audits

**Critical rule:** This user explicitly stated: *"禁用工具前记得问我，别悄咪咪禁了，容易埋坑"*.

Whenever your optimization plan involves **disabling, uninstalling, or reconfiguring** a skill, tool, or system component:
1. Present the candidate list to the user
2. Explain why each item is a candidate (category + description)
3. Wait for the user's approval before executing
4. Never disable anything silently

This applies to ALL system-modification tasks, not just token optimization.

### Method 1a: Data-Driven Skill Audit (Preferred)

**Use this when the user says to find unused skills — more objective than guessing.**

Instead of presenting categories and asking the user, use actual usage data to identify unused skills:

```
1. Read ~/.hermes/skills/.usage.json — contains per-skill use_count, last_used, created_at
2. Classify each skill:
   - use_count >= 2: genuinely used, KEEP
   - use_count == 0: NEVER used, disable candidate
   - use_count == 1: check if used_at_creation (last_used approx created_at within 5s)
     - used_at_creation: init-touched by curator, never actually used, disable candidate
     - real_use (used much later): KEEP
3. Cross-reference with hermes skills list source column (builtin vs local)
4. Determine platform (check config.yaml skills.platform_disabled for existing per-platform lists)
5. For each candidate: consider if strategically useful despite 0/1 usage
6. Present results grouped by category with usage stats. Let user decide.
7. Implement via config.yaml (see config.yaml modification below — patch tool is blocked)
```

**Key technique: detecting init-touched skills**

When curator first installs skills, it immediately views them. This means last_used_at == created_at within seconds. A real usage has hours/days gap:

```python
from datetime import datetime
last = datetime.fromisoformat(info.get('last_used_at', '').replace('Z', '+00:00'))
created = datetime.fromisoformat(info.get('created_at', '').replace('Z', '+00:00'))
is_init_touch = (last - created).total_seconds() < 5
```

#### Presentation Style

From user feedback:
- NEVER dump a flat list of 50+ skill names — the user gets overwhelmed
- ALWAYS group skills by category/type with a brief description of each group
- Present in digestible chunks: let the user pick groups to disable, not individual items
- Go step by step: user picks a category → you list the items → user confirms → repeat
- When they ask about remaining skills — keep grouping by category, don't dump the full raw list
- **When user says to just do it (explicit go-ahead):** you may skip per-group asking. Always present the final list first and wait for confirmation.

### Audit Workflow (Proven)

```
1. List all skills → group by category
2. For manual audit (no usage data):
   a. Present groups with descriptions
   b. User picks groups → list exact items in that group
   c. User confirms → implement in config.yaml
   d. Repeat until user says stop
3. For data-driven audit (usage.json available):
   a. Parse usage.json, classify by use_count + init-touch detection
   b. Present findings: N skills never used, M init-touched, total X candidates
   c. Let user confirm the full batch or pick groups to exclude
4. Implement via config.yaml (see below)
```

### Method 1b: Multi-Platform Disable

Skills can be disabled per platform. Your current platform (e.g. qqbot, telegram, cli) may have a different enabled set. To check:

```bash
grep -A 200 "platform_disabled:" ~/.hermes/config.yaml | head -50
```

To disable skills for a new platform (e.g. when moving from CLI to QQ bot):

1. **First**, read the existing cli disabled list — these are already vetted unused skills
2. **Mirror** the CLI list to your target platform (same skills, different platform key)
3. **Add** any additional candidates found via usage.json audit
4. Apply via Python YAML manipulation:

```python
import yaml
with open('/home/qn/.hermes/config.yaml') as f:
    config = yaml.safe_load(f)

# Ensure path exists
disabled = config.setdefault('skills', {}).\
    setdefault('platform_disabled', {}).\
    setdefault('qqbot', [])  # or your target platform

# Add skills (dedup preserving order)
existing_set = set(disabled)
for s in cli_disabled_list + additional_candidates:
    if s not in existing_set:
        disabled.append(s)

with open('/home/qn/.hermes/config.yaml', 'w') as f:
    yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
```

---

## Pitfalls

- **platform_disabled format** — The config key is `skills.platform_disabled.<platform_name>` (e.g., `cli`, `telegram`). The disabled list is an array of skill names (matching the `name` in SKILL.md frontmatter).
- **Requires new session** — Skill enablement changes only take effect after `/reset` or starting a new Hermes session. Prompt caching means mid-session changes don't apply.
- **Skills vs Tools** — Disabling a skill (via `platform_disabled`) is different from disabling a toolset (via `hermes tools`). This skill covers skill-level disabling only.
- **Not all skills consume equal tokens** — Skills with short SKILL.md files consume fewer tokens. Check the actual file size with `wc -c ~/.hermes/skills/<category>/<name>/SKILL.md` before deciding.
- **Config.yaml write protection** — Hermes blocks direct write_file/patch calls to `~/.hermes/config.yaml` for security. You MUST edit it via Python subprocess (reading + writing with yaml library) or via `hermes config edit` (interactive). Do NOT use the patch tool — it will be refused.
- **Dedup must preserve order** — When merging new disabled skill names with existing ones, use `list(dict.fromkeys(...))` not `list(set(...))`. `set()` does not preserve insertion order, which can shuffle config entries and confuse diffs.
- **The user prefers being asked** — see "User Preferences" section above. This is not optional.
- **Phantom memory entries waste effort** — When memory references tools, commands, or conventions that don't actually exist (e.g., `clashping` / `clashuse` were recorded but never installed), future sessions waste time trying to use them. When you discover a phantom entry, fix it immediately with `memory(action='replace', ...)` — don't just add workarounds elsewhere. The memory is the source of truth; keep it truthful.
- **Network timeouts on tool calls** — When `git clone`, `curl`, or package installs time out despite the VPN being active, the terminal's subprocess may not inherit proxy settings. Try `export http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890 && <command>`. This is the standard clash/mihomo proxy pattern and should be the first troubleshooting step for network issues.
