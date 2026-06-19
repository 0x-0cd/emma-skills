# RTK (Rust Token Killer) — Hermes Integration Reference

## Overview

[RTK](https://github.com/rtk-ai/rtk) (v0.42.3+, Apache 2.0) is a Rust CLI proxy that intercepts shell commands and applies per-command-type compression to reduce LLM token consumption by 60–90%. Supported: 100+ commands, 14 AI tool integrations including Hermes.

## How RTK Saves Tokens

| Operation | Without RTK | With RTK | Savings |
|---|---|---|---|
| `ls` / `tree` | ~2,000 tokens | ~400 | –80% |
| `cat` / `read` | ~40,000 | ~12,000 | –70% |
| `grep` / `rg` | ~16,000 | ~3,200 | –80% |
| `git status` | ~3,000 | ~600 | –80% |
| `git diff` | ~10,000 | ~2,500 | –75% |
| `pytest` | ~8,000 | ~800 | –90% |
| `cargo test` | ~25,000 | ~2,500 | –90% |

On command failure, RTK preserves full output at `~/.local/share/rtk/tee/<timestamp>_<command>.log` and displays the path so the LLM can inspect it without re-running.

## Installation

### Pre-built binary (recommended for Hermes host)

```bash
# 1. Download the right archive for your arch
# Linux x86_64
curl -fsSLO https://github.com/rtk-ai/rtk/releases/download/v0.42.3/rtk-x86_64-unknown-linux-musl.tar.gz
# Linux ARM64 (Raspberry Pi, etc.)
curl -fsSLO https://github.com/rtk-ai/rtk/releases/download/v0.42.3/rtk-aarch64-unknown-linux-gnu.tar.gz

# 2. Extract and install
tar -xzf rtk-*.tar.gz
cp rtk ~/.local/bin/
rtk --version  # verify
```

### Homebrew (macOS)

```bash
brew install rtk
```

### Cargo

```bash
cargo install --git https://github.com/rtk-ai/rtk
# NOTE: `cargo install rtk` (no --git) installs a different package!
```

## Hermes Plugin Integration

```bash
rtk init --agent hermes
```

This does three things:
1. Creates `~/.hermes/plugins/rtk-rewrite/` with:
   - `plugin.yaml` — declares `pre_tool_call` hook
   - `__init__.py` — Hermes plugin that calls `rtk rewrite <command>` before each terminal() call
2. Adds `rtk-rewrite` to `config.yaml` under `plugins.enabled`
3. Requires Hermes restart (or `/reset`) to activate

### Plugin Behaviour

- Only triggers on `terminal()` tool calls (not read_file, search_files, etc.)
- Runs `rtk rewrite <command>` with a 2-second timeout
- If RTK returns a rewritten command (exit 0 or 3), the original command is replaced
- If RTK returns 1 or 2 (passthrough), the command runs unmodified
- Fails open: any exception/timeout/missing-binary silently passes through
- Plugin code is minimal (~80 lines) — all rewrite logic lives in the Rust binary

## Verified Working

Tested on aarch64 Linux (Raspberry Pi, 6.8 kernel). Measured ~60% token savings on initial `ls -la` command. The plugin cleanly handles non-rewritable commands (e.g., `git status` in a non-git directory passes through with full output).

## Caveats

- Only intercepts commands through the Hermes `terminal()` tool — built-in tools (read_file, grep via search_files) bypass it
- Telemetry is opt-in and disabled by default
- Config file at `~/.config/rtk/config.toml` (macOS: `~/Library/Application Support/rtk/config.toml`)
- Tracking/analytics viewed via `rtk gain`
