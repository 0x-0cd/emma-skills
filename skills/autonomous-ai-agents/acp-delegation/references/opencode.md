# OpenCode CLI — Quick Reference

## Install

```bash
# Native binary (no Node.js dep) — recommended for ARM64
curl -fsSL https://opencode.ai/install | bash
# Add to PATH: source ~/.bashrc or export PATH="$HOME/.opencode/bin:$PATH"

# npm (fallback)
npm install -g opencode-ai@latest
```

## Auth (BYOK — Bring Your Own Key)

Configure `~/.opencode.json`:

```json
{
  "model": "deepseek/deepseek-v4-flash",
  "provider": {
    "deepseek": {
      "models": {
        "deepseek/deepseek-chat": {"name": "DeepSeek V4 Chat"}
      }
    }
  }
}
```

Auth tokens are stored in `~/.local/share/opencode/auth.json` (auto-generated).

## One-Shot Tasks

```bash
opencode run 'Add retry logic to API calls' --model deepseek/deepseek-v4-flash
# Attach context files
opencode run 'Fix bug' -f config.yaml -f .env.example
```

No PTY needed for `run` mode.

## Interactive Sessions (Background + PTY)

```bash
terminal(command="opencode", workdir="~/project", background=true, pty=true)
process(action="submit", session_id="<id>", data="Implement OAuth refresh")
process(action="poll", session_id="<id>")
process(action="kill", session_id="<id>")  # Ctrl+C doesn't work here
```

## Model Routing

| Task | Model | Example |
|:-----|:------|:--------|
| Simple | Flash | Single-file fix, code review |
| Complex | Pro | Multi-file refactor, new feature |

```bash
opencode run 'fix typo' --model deepseek/deepseek-v4-flash
opencode run 'implement MCP storage' --model deepseek/deepseek-v4-pro
```

## Global CLAUDE.md

OpenCode reads global behavioral instructions from `~/.claude/CLAUDE.md`:

```bash
mkdir -p ~/.claude
curl -fsSL https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md > ~/.claude/CLAUDE.md
```

## Verification

```bash
opencode run 'Respond with exactly: OPENCODE_SMOKE_OK'
# Expected: OPENCODE_SMOKE_OK
```

## Known Pitfalls

- `opencode run` does NOT need PTY; TUI sessions DO need PTY
- `/exit` is NOT valid — use Ctrl+C or `process(action="kill")`
- Model names use `provider/model` format (e.g. `deepseek/deepseek-v4-flash`)
- Long tasks (>5 min) may timeout in foreground — use `background=true`
- npm uses Node.js launcher; `curl | bash` delivers native binary — prefer the latter on ARM64
