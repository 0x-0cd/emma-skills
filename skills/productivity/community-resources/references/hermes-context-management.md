# Hermes Context Management

## Overview

Hermes Agent offers three layers of context management — this file covers when each applies and how to configure, troubleshoot, or upgrade them.

---

## 1. Built-in ContextCompressor (default)

Hermes ships with a `ContextCompressor` in `agent/context_compressor.py`. It auto-triggers when the active context reaches ~80% of the model's window.

### Behavior
- Summarizes older conversation turns into a flat compressed block
- Injected back into the prompt to keep it under the token limit
- Runs automatically — no user action needed

### Configuration (.env)
```bash
# Percentage of context window to trigger compression (default: 80)
CONTEXT_COMPRESSION_THRESHOLD=80

# Minimum messages before compression activates (default: 20)
CONTEXT_COMPRESSION_MIN_MESSAGES=20
```

### Known Bug — Silent Data Loss
If compression fails (API timeout, model error, rate limit), the compressor **silently discards the messages it was trying to summarize** instead of preserving them.

**Symptoms:**
- Agent suddenly "forgets" something it knew 20 messages ago
- Long sessions degrade faster than expected
- No error messages — just quiet data loss

**Fix** — edit `context_compressor.py`:
```python
# BROKEN — silently drops context on failure
try:
    summary = await summarize_messages(messages_to_compress)
    compressed_context = summary
except Exception:
    compressed_context = ""  # DATA LOST

# FIXED — preserves original context if compression fails
try:
    summary = await summarize_messages(messages_to_compress)
    compressed_context = summary
except Exception as e:
    logger.warning(f"Context compression failed: {e}, preserving original context")
    compressed_context = messages_to_compress  # safe fallback
```

**Location of the file:**
```bash
find ~/.hermes -name "context_compressor.py" -type f
# Typically: ~/.hermes/hermes-agent/agent/context_compressor.py
```

### Recovery
Even after compression, original messages may persist in `state.db` (Hermes host-level history). Use `session_search` via the agent to recall pre-compression content.

---

## 2. Pluggable Context Engine System (v0.16.0+)

Hermes v0.16.0+ supports **pluggable context engines** via `plugins/context_engine/`. This allows replacing the default `ContextCompressor` with a different engine.

### Architecture
- Discovery: `plugins/context_engine/__init__.py` → `discover_context_engines()`
- Loading: `plugins/context_engine/__init__.py` → `load_context_engine(name)`
- Plugin format: directory under `plugins/context_engine/<name>/` with `__init__.py`
- The module must have either:
  - A `register(ctx)` function (preferred) OR
  - A class extending `ContextEngine` ABC
- Only ONE engine can be active at a time

### Switching Engines (config.yaml)
```yaml
context:
  engine: lcm     # or "compressor" (default)

plugins:
  enabled:
    - hermes-lcm  # only needed for community plugins
```

### Built-in vs Plugin Engines
- **Repo-shipped engines** — live in `~/.hermes/hermes-agent/plugins/context_engine/<name>/`. Always available without user installation.
- **Community plugin engines** — installed via `~/.hermes/plugins/<name>/` and require `plugins.enabled` in config.yaml. Discovered by `hermes_cli.plugins.get_plugin_context_engine()`.

### Tool Registration
Context engines can register tools that the agent can call (e.g. LCM's `lcm_grep`, `lcm_expand`). These are loaded via `get_tool_schemas()` on the engine instance and added to the agent's `_context_engine_tool_names` set.

### Slash Commands
Engines can also register slash commands (e.g. `/lcm status`) via `register_command()` on the plugin context. These are integrated with the global plugin command registry.

---

## 3. hermes-lcm Plugin — Lossless Context Management

**GitHub:** https://github.com/stephenschoettler/hermes-lcm
**Based on:** LCM paper by Ehrlich & Blackman (Voltropy PBC, Feb 2026)

### What It Does
hermes-lcm replaces the lossy `ContextCompressor` with a **lossless** engine using a hierarchical Summary DAG:

1. **SQLite message store** — preserves raw messages before compaction
2. **Summary DAG** — compacts older context into depth-aware summary nodes (not flat summary)
3. **Bounded recovery** — agent can drill back into exact compacted material
4. **Agent tools:** `lcm_grep`, `lcm_describe`, `lcm_expand`, `lcm_expand_query`
5. **Source-aware retrieval** — filters by descendant source lineage
6. **Session controls** — ignore/noisy/read-only glob patterns
7. **Large payload externalization** — oversized tool results, media base64 data
8. **Sensitive-pattern redaction** — API keys, bearer tokens, passwords

### Requirements
- **Hermes v0.16.0+** (with pluggable context engine support) ✅
- **Python 3.11+** ✅
- **tiktoken** (optional, for accurate token estimation) — fallback to char-based if missing
- **regex** (optional, for message ignore patterns) — fallback to stdlib `re` if missing

### Installation
```bash
# Clone to Hermes plugins directory
git clone https://github.com/stephenschoettler/hermes-lcm \
  ~/.hermes/plugins/hermes-lcm

# Enable in config.yaml:
#   plugins:
#     enabled:
#       - hermes-lcm
#   context:
#     engine: lcm

# Profile-specific install:
HERMES_PROFILE=myprofile ./scripts/install.sh  # from repo checkout
```

### Verification
```bash
# Restart Hermes, then:
hermes plugins           # should list hermes-lcm
# Agent startup should log: "Context engine: lcm"
```

### Security Features
- Named redaction of secrets (API keys, bearer tokens, passwords, private keys) before LCM stores or summarizes them
- Storage-boundary guard: media-like `data:*;base64` payloads and long base64 strings are externalized before writing to SQLite
- Sensitive-pattern configurable via glob patterns

---

## When to Use Each

| Situation | Recommendation |
|-----------|---------------|
| Short sessions (<50 messages) | Default compressor is fine |
| Long sessions (100+ messages) | Consider hermes-lcm for lossless recovery |
| Agent keeps forgetting mid-conversation | Check for silent compression bug (fix above) |
| Need to drill back into compacted history | hermes-lcm (Summary DAG + LCM tools) |
| Sensitive data in conversations | hermes-lcm (built-in redaction) |
| Minimal dependencies, vanilla setup | Stick with default compressor |
| Working with Claude Code / Codex / OpenCode | Use obra/superpowers hooks for their native compression |

---

## References
- LCM paper: https://papers.voltropy.com/LCM
- hermes-lcm repo: https://github.com/stephenschoettler/hermes-lcm
- Hermes optimization guide (part 6 - context compression): https://github.com/OnlyTerp/hermes-optimization-guide
- Hermes deep documentation (context section): https://hermes-agent.nousresearch.com/docs/
