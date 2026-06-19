# Claude Code — CLI Reference

## Install

```bash
npm install -g @anthropic-ai/claude-code
```

## Auth

- Browser OAuth: `claude` (first launch); or `ANTHROPIC_API_KEY`
- Console auth: `claude auth login --console`
- SSO: `claude auth login --sso`
- Status: `claude auth status` (JSON) or `claude doctor`

## Print Mode (Non-Interactive, Preferred)

```bash
claude -p 'Fix the auth bug' --allowedTools 'Read,Edit' --max-turns 10
claude -p 'Analyze auth.py' --output-format json --max-turns 5
cat src/auth.py | claude -p 'Review this code'
git diff HEAD~3 | claude -p 'Summarize changes'
```

## Interactive Mode (via tmux)

```bash
tmux new-session -d -s claude-work -x 140 -y 40
tmux send-keys -t claude-work 'cd /project && claude' Enter
# Handle trust dialog (default "Yes"): tmux send-keys Enter
# Handle permissions dialog (default is "No"): tmux send-keys Down Enter
# Send prompt: tmux send-keys -t claude-work 'Refactor auth' Enter
# Monitor: tmux capture-pane -t claude-work -p -S -30
```

## Key Flags

| Flag | Effect |
|------|--------|
| `-p, --print` | Non-interactive one-shot mode |
| `--max-turns N` | Limit agentic loops (print mode only) |
| `--max-budget-usd N` | Cap API spend (min ~$0.05) |
| `--model <alias>` | `sonnet`, `opus`, `haiku`, or full name |
| `--effort <level>` | `low`, `medium`, `high`, `max`, `auto` |
| `--dangerously-skip-permissions` | Auto-approve ALL tool use |
| `--allowedTools <tools>` | Whitelist: `Read`, `Edit`, `Write`, `Bash`, `WebSearch` |
| `--output-format json` | Structured JSON result |
| `--continue` / `--resume <id>` | Continue/resume previous session |
| `--bare` | Skip plugins/MCP/discovery, fastest startup |
| `--fallback-model haiku` | Auto-fallback when overloaded |
| `--from-pr N` | Review a specific PR |

## Session Continuation

```bash
claude -p 'Continue and add connection pooling' --continue --max-turns 5
claude -p 'Try a different approach' --resume <id> --fork-session --max-turns 10
```

## MCP Integration

```bash
claude mcp add -s user github -- npx @modelcontextprotocol/server-github
claude mcp add -s local postgres -- npx @anthropic-ai/server-postgres --connection-string postgresql://localhost/mydb
```

## Known Pitfalls

- Interactive mode **requires tmux** — `pty=true` alone is insufficient for orchestration
- `--dangerously-skip-permissions` dialog defaults to "No, exit" — must send Down then Enter
- `--max-budget-usd` minimum is ~$0.05
- Session resumption requires same directory
- Trust dialog only appears once per directory, then cached
- Context degradation above 70% — use `/compact` proactively
- Use `--bare` for CI to skip startup overhead (requires `ANTHROPIC_API_KEY`)
