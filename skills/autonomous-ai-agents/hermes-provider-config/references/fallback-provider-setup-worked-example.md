# Worked Example: Opencode Go → DeepSeek Fallback

> **⚠️ 2026-09-11 起本机不适用。** `opencode-go` provider 已随 OpenCode 一起删除，本机
> `fallback_providers` 已置空（`[]`），唯一 provider 是 `deepseek`（模型 `deepseek-flash`），
> **没有 fallback 链**。下面所有 `opencode-go` 的端点 / 定价 / key 路径均已失效。
> 保留此文仅作"以后要重新配 fallback 链时该怎么做"的方法论参考 —— 把它套到别的 provider 上即可，
> 但**不要照抄 opencode-go 那几行**。

Configuring a fallback chain where `opencode-go` is the primary (unstable) provider and `deepseek` is the backup.

## Starting State

```yaml
# ~/.hermes/config.yaml
model:
  base_url: https://api.deepseek.com
  default: deepseek-flash
  provider: deepseek
fallback_providers: []
```

Both API keys already set in `.env`:
```
DEEPSEEK_API_KEY=sk-...
OPENCODE_GO_API_KEY=sk-...
```

## Step 1: Change Primary Provider

```bash
hermes config set model.provider opencode-go
hermes config set model.base_url ''     # Clear old provider's base_url
```

Result:
```yaml
model:
  base_url: ''
  default: deepseek-flash
  provider: opencode-go
```

## Step 2: Add Fallback Provider (WRONG WAY)

```bash
# ❌ BUG: This stores the value as a YAML string, not a list
hermes config set fallback_providers '[{"provider": "deepseek", "model": "deepseek-flash"}]'
```

Result in config.yaml:
```yaml
# ⚠️ String literal — not parsed as YAML list
fallback_providers: '[{"provider": "deepseek", "model": "deepseek-flash"}]'
```

`hermes fallback ls` output: `"No fallback providers configured."`

## Step 3: Add Fallback Provider (CORRECT WAY)

Manually edit `~/.hermes/config.yaml` with proper YAML:

```bash
# Replace the string with proper YAML
# Either use sed or hermes config edit
sed -i "s/fallback_providers:.*/fallback_providers:\n  - provider: deepseek\n    model: deepseek-flash/" ~/.hermes/config.yaml
```

Result:
```yaml
fallback_providers:
  - provider: deepseek
    model: deepseek-flash
```

## Verification

```bash
hermes fallback ls
```

Output:
```
Primary:   deepseek-flash  (via opencode-go)

  Fallback chain (1 entry):
    1. deepseek-flash  (via deepseek)

  Tried in order when the primary fails (rate-limit, 5xx, connection errors).
```

## Final Config State

```yaml
model:
  base_url: ''
  default: deepseek-flash
  provider: opencode-go
fallback_providers:
  - provider: deepseek
    model: deepseek-flash
credential_pool_strategies: {}
```

## Key Takeaways

1. `hermes config set` works well for simple key:value pairs (`model.provider`, `model.default`)
2. **Do NOT** use `hermes config set` for complex YAML structures (lists, dicts) — it serializes to a string
3. For `fallback_providers`, either:
   - Use `hermes fallback` interactive CLI (recommended for discovery)
   - Edit `config.yaml` directly with proper YAML formatting (recommended for deterministic setup)
4. `hermes fallback ls` reads `fallback_providers` from `config.yaml` — if it says "none configured", check the YAML format
5. Changes take effect on next session (`/reset` in CLI, `/restart` in gateway)
