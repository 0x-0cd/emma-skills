# Codex CLI — Quick Reference

## Install

```bash
npm install -g @openai/codex
```

## Auth

- OpenAI auth: `OPENAI_API_KEY` env var, or Codex OAuth (browser flow from `codex`)
- For Hermes-managed: configure `model.provider: openai-codex` and run `hermes auth add openai-codex`

## One-Shot Tasks

```bash
# Basic
codex exec 'Add dark mode toggle to settings'
# Scratch (git repo needed)
codex exec 'Build a snake game' --workdir $(mktemp -d && git init)
```

## Long Tasks (Background + PTY)

```bash
terminal(command="codex exec --full-auto 'Refactor auth module'", workdir="~/project", background=true, pty=true)
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")
process(action="submit", session_id="<id>", data="yes")  # answer prompt
```

## Key Flags

| Flag | Effect |
|------|--------|
| `exec "prompt"` | One-shot execution, exits when done |
| `--full-auto` | Auto-approves file changes in sandboxed workspace |
| `--yolo` | No sandbox, no approvals (fastest, most dangerous) |
| `--sandbox danger-full-access` | Bypass bubblewrap sandbox (needed in some gateway/container contexts) |

## PR Review

```bash
git clone repo /tmp/review && cd /tmp/review && gh pr checkout 42 && codex review --base origin/main
```

Use `pty=true` for interactive review sessions.

## Hermes Gateway Caveat

Codex sandboxing (`bubblewrap`/user namespaces) may fail when invoked from a Hermes gateway/service context. Typical error: `setting up uid map: Permission denied`. Fix:

```bash
codex exec --sandbox danger-full-access "<task>"
```

Use process-boundary safety (workdir, clean git status, narrow task prompts) as the safety layer instead.

## Known Pitfalls

- **Always use `pty=true`** — Codex is interactive terminal app
- **Git repo required** — won't run outside. Use `mktemp -d && git init` for scratch
- **Use `exec` for one-shots** — `codex exec "prompt"` runs and exits cleanly
- **Parallel is fine** — run multiple Codex processes at once via worktrees
- Not needed for `codex exec` (non-interactive)
