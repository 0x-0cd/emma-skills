# OpenCode Go Subscription: Pricing, Limits & Usage Checks

> **Provider type:** `opencode-go` in config.yaml (`model.provider: opencode-go`)
> **Base URL:** `https://opencode.ai/zen/go/v1` (OpenAI-compatible)
> **API key env var:** `OPENCODE_GO_API_KEY` (sourced from `~/.hermes/.env`)
>
> Docs: https://opencode.ai/go

---

## Pricing Model

| Period | Price |
|--------|-------|
| First month | $5 |
| Ongoing | $10/month |

Monthly subscription with usage-based limits — NOT pay-per-token. Top-up credits available as fallback.

---

## Usage Limits (Monetary Caps)

OpenCode Go enforces **dollar-value caps** per time window, not hard request counts. Actual request volume depends on model cost.

| Time Window | Dollar Cap |
|-------------|-----------|
| **5-hour rolling window** | $12 |
| **Weekly** | $30 |
| **Monthly** | $60 |

---

## Per-Model Request Estimates

Estimated requests within each window for common models (based on typical usage patterns):

| Model | req/5h | req/week | req/month |
|-------|--------|----------|-----------|
| DeepSeek V4 Flash | 31,650 | 79,050 | 158,150 |
| DeepSeek V4 Pro | 3,450 | 8,550 | 17,150 |
| MiMo-V2.5 | 30,100 | 75,200 | 150,400 |
| MiMo-V2.5-Pro | 3,250 | 8,150 | 16,300 |
| MiniMax M3 | 3,200 | 8,000 | 16,000 |
| MiniMax M2.7 | 3,400 | 8,500 | 17,000 |
| GLM-5.1 | 880 | 2,150 | 4,300 |
| GLM-5 | 1,150 | 2,880 | 5,750 |
| Kimi K2.6 | 1,150 | 2,880 | 5,750 |
| Kimi K2.7 Code | 1,350 | 4,630 | 9,250 |
| Qwen3.7 Max | 950 | 2,390 | 4,770 |
| Qwen3.7 Plus | 4,300 | 10,800 | 21,600 |
| Qwen3.6 Plus | 3,300 | 8,200 | 16,300 |

> **Note:** The list of models and limits may change as OpenCode updates their offering. Current as of June 2026.

---

## Checking Remaining Usage

**There is NO programmatic API to check remaining quota.** Every REST API path attempted:

| Endpoint | Result |
|----------|--------|
| `{base_url}/dashboard/billing/subscription` | HTML 404 (SPA catch-all) |
| `{base_url}/dashboard/billing/usage` | HTML 404 |
| `{base_url}/me` | 403 (Cloudflare) |
| `opencode.ai/api/*` | HTML 404 or redirect |
| `opencode.ai/zen/api/*` | HTML 404 |

All billing/account endpoints return SPA HTML pages or Cloudflare-protected responses. The API key (`Authorization: Bearer sk-…`) is not accepted on these routes — they're part of the web app, not the LLM gateway.

**Only way to check:** log into the OpenCode web console at https://opencode.ai/auth (interactive browser session required).

---

## Local CLI Stats (Not Subscription Usage)

The `opencode stats` command shows **local OpenCode CLI** usage statistics (session count, message count, token usage tracked by the local client). It does NOT reflect subscription quota.

```
opencode stats
  → Sessions: 49
  → Messages: 465
  → Total Cost: $0.47   ← local cost estimate, not what Go charges
```

---

## Default Models Available

| Model ID | Provider |
|----------|----------|
| `glm-5.1` | Zhipu GLM |
| `glm-5` | Zhipu GLM |
| `kimi-k2.7-code` | Kimi/Moonshot |
| `kimi-k2.6` | Kimi/Moonshot |
| `mimo-v2.5` | Xiaomi MiMo |
| `mimo-v2.5-pro` | Xiaomi MiMo |
| `minimax-m3` | MiniMax |
| `minimax-m2.7` | MiniMax |
| `qwen3.7-max` | Alibaba Qwen |
| `qwen3.7-plus` | Alibaba Qwen |
| `qwen3.6-plus` | Alibaba Qwen |
| `deepseek-v4-pro` | DeepSeek |
| `deepseek-v4-flash` | DeepSeek |

List retrieved from `GET {base_url}/models` with the Go API key.

---

## Credential Resolution

`model.provider: opencode-go` in Hermes resolves credentials in this order:

1. **`OPENCODE_GO_API_KEY`** env var (from `~/.hermes/.env`) — Hermes reads this directly
2. **`auth.json`** (`~/.local/share/opencode/auth.json`) — last-resort fallback for Hermes; primary auth for the `opencode` CLI binary

The `.env` file contains the real key but **terminal output is redacted** (`***`) by Hermes' secret redaction system. Use `source ~/.hermes/.env` in bash to access the actual key in scripts. The `opencode` CLI reads `auth.json` directly and does not depend on `.env`.

```bash
# Check credential pool status
hermes auth list opencode-go

# Check if the model endpoint works
source ~/.hermes/.env
curl -s "$OPENCODE_GO_BASE_URL/models" -H "Authorization: Bearer $OPENCODE_GO_API_KEY" | head
```
