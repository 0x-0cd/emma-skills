# Auxiliary Provider Resolution — Source-Level Reference

Internal notes from Hermes source code analysis (`agent/auxiliary_client.py`).

## Complete Auxiliary Task Catalog

As of `config.yaml` defaults, there are **11 auxiliary tasks** (the config template generates all 11 on `hermes setup` or `hermes config migrate`):

| Task | Purpose | Default timeout |
|------|---------|:---------------:|
| `approval` | Smart-approval evaluation (when `approvals.mode: smart`) | 30s |
| `compression` | Context compression (summarize old conversation turns) | 120s |
| `curator` | Skill lifecycle management (curator background agent) | 600s |
| `kanban_decomposer` | Break kanban board tasks into ordered subtasks | 180s |
| `mcp` | MCP server response reformatting | 30s |
| `profile_describer` | Generate human-readable profile descriptions | 60s |
| `skills_hub` | Skills hub search and inspection queries | 30s |
| `title_generation` | Auto-generate session titles from context | 30s |
| `triage_specifier` | Task triage / specification routing | 120s |
| `tts_audio_tags` | Generate TTS SSML tags and voice metadata | 30s |
| `vision` | Image analysis (requires multimodal model) | 120s |

Note: `web_extract` was present in earlier Hermes versions but is no longer a separate auxiliary task in the default config template. Web extraction now runs through the main model directly.

## Per-Task Config Structure

Every task inherits this shape (shown for `compression`):

```yaml
auxiliary:
  compression:
    provider: auto       # Provider name or 'auto'
    model: ''            # '' = let provider pick default
    base_url: ''         # Custom endpoint (for custom/specific provider)
    api_key: ''          # '' = inherit from main provider
    extra_body: {}       # Extra request-body fields (provider-specific params)
    timeout: 120         # Seconds before aborting
```

`provider: auto` means Hermes auto-detects the backend (see chains below).
`model: ''` means "let the provider decide the default model for this task type."
`api_key: ''` and `base_url: ''` mean "inherit from the main provider configuration."

## Vision Auto-Detection Code Path

When `auxiliary.vision.provider: auto`, the resolution function:

1. Reads main provider from `config.yaml` (`model.provider`)
2. Looks up vision model override: `_PROVIDER_VISION_MODELS.get(main_provider, main_model)`
3. Special-cases `nous` → strict vision backend with tier-aware defaults
4. Skips providers in `_PROVIDERS_WITHOUT_VISION` (currently: `kimi-coding`, `kimi-coding-cn`)
5. Checks `_main_model_supports_vision()` — rejects known text-only models
6. Falls through to aggregator chain: OpenRouter → Nous Portal → stop

## Provider Vision Model Mapping

```python
_PROVIDER_VISION_MODELS = {
    "xiaomi": "mimo-v2.5",
    "zai": "glm-5v-turbo",
}
```

## Providers Without Vision Support

```python
_PROVIDERS_WITHOUT_VISION = frozenset({
    "kimi-coding",    # Routes through api.kimi.com/coding (Anthropic Messages wire)
    "kimi-coding-cn", # Same endpoint, no image_in capability
})
```

## General Auxiliary Resolution Chain (non-vision)

For compression, approval, curator, title_generation, kanban_decomposer, and all other non-vision auxiliary tasks:

1. Main provider + main model (if configured and not unhealthy)
2. Aggregator chain: OpenRouter → Nous Portal → Anthropic → Custom endpoint → None

The main provider is used directly when available — this reuses the same API key and avoids picking from credential pools (which might select an exhausted key).

### Resolution Priority Source Code

In `agent/auxiliary_client.py`, the `_get_auxiliary_backend()` function for non-vision tasks:
1. Checks `auxiliary.<task>.provider` in config
2. If `auto` or empty: tries main provider → aggregator chain
3. If still nothing: returns `None` (task silently fails)
4. On HTTP 402/429: marks provider unhealthy in `_unhealthy_provider_cache` with TTL

## Unhealthy Provider Skipping
## Unhealthy Provider Skipping

Both vision and general auxiliary chains maintain a health cache. If a provider
recently returned HTTP 402 (billing), it's marked unhealthy for a TTL period
and skipped in auto-detect. This prevents one doomed RTT per aux call when an
account is depleted.

## Key Config Locations

- `config.yaml` → `auxiliary.*` — all 11 tasks (`hermes config set auxiliary.<task>.<key> <val>`)
- `.env` → API keys for OpenRouter (`OPENROUTER_API_KEY`), Google (`GOOGLE_API_KEY`), etc.
- `auth.json` → OAuth tokens and credential pools (managed by `hermes auth`)

## Quick Diagnostic

When an auxiliary task silently returns no result:

```bash
# Check current auxiliary config
hermes config | grep -A 60 '^auxiliary:' | head -70

# Check gateway logs for auxiliary errors
grep -i "auxiliary\|compression\|vision" ~/.hermes/logs/gateway.log 2>/dev/null | tail -10
```

Common causes:
- No `provider` resolves (all `auto` but no aggregator key set)
- Unhealthy provider cache (HTTP 402 from a previous call — wait for TTL or restart)
- Vision-specific: main model doesn't support vision and no aggregator fallback
