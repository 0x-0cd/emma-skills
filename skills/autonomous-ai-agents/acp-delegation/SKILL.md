---
name: acp-delegation
description: "Delegate coding tasks to autonomous coding agent CLIs — Claude Code, Codex, OpenCode. Covers common orchestration patterns (background mode, git worktrees, PR review, PTY handling) and CLI-specific quick-start guides."
version: 1.0.0
author: Hermes Agent
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Coding-Agent, Delegation, Claude-Code, Codex, OpenCode, ACP, Orchestration]
    related_skills: [hermes-agent, test-driven-development, github-pr-workflow]
---

# ACP Delegation — Coding Agent CLI Orchestration

Delegate coding tasks to external autonomous coding agent CLIs. This skill covers the shared orchestration patterns that apply to all ACP CLIs, with CLI-specific details in the `references/` directory.

## When to Use

Use when the user asks to:
- "Have Claude/Codex/OpenCode build a feature"
- "Use an AI coding agent to refactor this"
- "Run an autonomous coding session for PR review"
- "Batch-fix issues across the codebase"

## Shared Orchestration Patterns

### Mode 1: Print/One-Shot Mode (Preferred for most tasks)

Run a single task and get the result back — no interactive session needed:

```bash
# Claude Code
claude -p 'Add error handling to all API calls' --allowedTools 'Read,Edit' --max-turns 10

# Codex
codex exec 'Add dark mode toggle to settings'

# OpenCode
opencode run 'Add retry logic to API calls' --model deepseek/deepseek-v4-flash
```

**When to use:** one-shot tasks, CI/CD, structured output extraction, piped input.

### Mode 2: Background + PTY (Long Tasks)

For tasks that take more than a minute:

```bash
# Start in background
terminal(command="claude -p 'Refactor auth module'" --max-turns 20, workdir="~/project", background=true, pty=true)
# Returns session_id

# Monitor progress
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")

# Kill if needed
process(action="kill", session_id="<id>")
```

**When to use:** refactoring, multi-file changes, any task over ~60 seconds.

### Git Worktrees for Parallel Tasks

Run multiple independent coding agents simultaneously using isolated worktrees:

```bash
# Create worktrees
git worktree add -b fix/issue-78 /tmp/issue-78 main
git worktree add -b fix/issue-99 /tmp/issue-99 main

# Launch agents in each worktree
terminal(command="claude -p 'Fix issue 78'" --allowedTools 'Read,Edit', workdir="/tmp/issue-78", background=true, pty=true)
terminal(command="codex exec 'Fix issue 99'", workdir="/tmp/issue-99", background=true, pty=true)

# Monitor progress
process(action="list")

# After completion, push and create PRs
terminal(command="cd /tmp/issue-78 && git push -u origin fix/issue-78")
terminal(command="gh pr create --title 'fix: ...' --body '...'")

# Cleanup
git worktree remove /tmp/issue-78
```

### PR Review Pattern

```bash
# Quick review of local changes
git diff main...HEAD | claude -p 'Review this diff for bugs and security issues' --max-turns 1

# Deep review via PR number
claude -p 'Review this PR thoroughly' --from-pr 42 --max-turns 10

# Codex review
codex exec 'Review the changes in this branch'
```

## Choosing a CLI

| Task | Recommended CLI | Reason |
|------|----------------|--------|
| Production-grade code | Claude Code | Best tool-use, subagents, review workflow |
| Quick one-shot coding | Codex | Fast startup, exec mode |
| Open-source models | OpenCode | BYOK model routing, no vendor lock |
| Batch issue fixing | Any via worktrees | All support git worktree isolation |
| Review + iterate | Claude Code | --continue, session management |

## CLI-Specific References

Each CLI's detailed command reference, install guide, auth setup, and known pitfalls are in the `references/` directory:

| File | Covers |
|------|--------|
| `references/claude-code.md` | Full Claude Code CLI reference (all flags, subcommands, interactive TUI setup via tmux, MCP, hooks, agent teams, settings) |
| `references/codex.md` | Codex CLI (install, auth, exec mode, flags, parallel worktrees, Hermes gateway caveats) |
| `references/opencode.md` | OpenCode CLI (install via npm/script, auth with BYOK, global CLAUDE.md, model routing, CodeGraph MCP) |

## Common Pitfalls

1. **Always use `pty=true`** for interactive TUI CLIs (Claude Code, OpenCode interactive mode) — they hang without a PTY. `opencode run` and `claude -p` do NOT need PTY.
2. **Git repo required** — all three CLIs refuse to run outside a git directory. Use `mktemp -d && git init` for scratch work.
3. **Set `workdir` explicitly** — keep the CLI focused on the right project.
4. **Set `--max-turns` / `--max-cost`** — prevents infinite loops and runaway costs.
5. **Monitor background processes** — use `process(action="poll")` for status, don't just wait.
6. **Don't interfere** — agents may be doing multi-step work; check progress instead of killing.
7. **Parallel is fine** — run multiple instances at once for batch work via worktrees.
8. **Clean up worktrees** — remove them when done to avoid repo bloat.
9. **Background sessions persist** — always clean up tmux sessions and background processes.
