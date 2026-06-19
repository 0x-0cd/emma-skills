# Hermes Provider Env Var Name Catalog

Reference list of environment variable names for every Hermes Agent LLM provider.
Based on Hermes Agent source code (`hermes_cli/config.py`, `agent/provider_manager.py`).

## Provider Key Env Vars

| Provider | Key Env Var | Also Checks | Notes |
|----------|-------------|-------------|-------|
| OpenRouter | `OPENROUTER_API_KEY` | — | |
| Anthropic | `ANTHROPIC_API_KEY` | — | |
| Nous Portal | OAuth only | — | Use `hermes auth add nous` |
| OpenAI | `OPENAI_API_KEY` | — | |
| OpenAI Codex | OAuth only | — | Use `hermes auth` |
| GitHub Copilot | `COPILOT_GITHUB_TOKEN` | — | `gh auth token` does NOT work |
| Google Gemini | `GOOGLE_API_KEY` | `GEMINI_API_KEY` | |
| DeepSeek | `DEEPSEEK_API_KEY` | — | |
| xAI / Grok | `XAI_API_KEY` | — | |
| Hugging Face | `HF_TOKEN` | — | |
| Z.AI / GLM | `GLM_API_KEY` | — | |
| MiniMax | `MINIMAX_API_KEY` | — | |
| MiniMax CN | `MINIMAX_CN_API_KEY` | — | |
| Kimi / Moonshot | `KIMI_API_KEY` | — | |
| Alibaba / DashScope | `DASHSCOPE_API_KEY` | — | |
| Xiaomi MiMo | `XIAOMI_API_KEY` | — | Used for vision (mimo-v2.5) |
| Kilo Code | `KILOCODE_API_KEY` | — | |
| OpenCode Go | `OPENCODE_GO_API_KEY` | — | Main model provider for this setup |
| OpenCode Zen | `OPENCODE_ZEN_API_KEY` | — | Alternative OpenCode provider |
| Qwen OAuth | OAuth only | — | Use `hermes auth add qwen-oauth` |

## Base URL Env Vars

Set when using a proxy, self-hosted endpoint, or region-specific URL.

| Provider | Env Var | Default Value |
|----------|---------|---------------|
| DeepSeek | `DEEPSEEK_BASE_URL` | `https://api.deepseek.com` |
| OpenAI | `OPENAI_BASE_URL` | `https://api.openai.com/v1` |
| Anthropic | `ANTHROPIC_BASE_URL` | `https://api.anthropic.com` |
| OpenRouter | `OPENROUTER_BASE_URL` | `https://openrouter.ai/api/v1` |
| OpenCode Go | `OPENCODE_GO_BASE_URL` | `https://opencode.ai/zen/go/v1` |
| Xiaomi | `XIAOMI_BASE_URL` | Provider default (set only when proxying) |
| Google Gemini | `GOOGLE_API_BASE` | Provider default |

## OpenCode CLI (Separate Binary) Auth

The `opencode` binary has its own credential resolution that does NOT share Hermes's `.env`:

- Reads `~/.local/share/opencode/auth.json` as primary
- Supports Viper config binding: config keys can be overridden with `OPENCODE_*` env vars
- Unclear whether it reads `DEEPSEEK_API_KEY` directly — test before relying on it

## Hermes `.env` File Location

```bash
hermes config env-path   # Prints path to ~/.hermes/.env
cat ~/.hermes/.env       # View current env vars
```

## Quick Check Commands

```bash
# Which env vars are loaded into the Hermes process?
env | grep -E 'API_KEY|TOKEN|SECRET' | grep -v 'REDACTED'

# Which providers are configured?
hermes config | grep -E 'provider|default'

# Which auth pools are registered?
hermes auth list
```
