# Web Search Backend Troubleshooting

When `web_search` or `web_extract` tools consistently time out or return errors, the search backend may be unreachable from your network environment.

## Symptom: DuckDuckGo (ddgs) Keeps Timing Out

This is the default search backend. It frequently fails in restricted network environments (China, corporate firewalls, etc.) because DuckDuckGo's servers are slow to respond from those regions.

## Diagnostic Flow

### 1. Check Current Backend

```bash
grep search_backend ~/.hermes/config.yaml
grep extract_backend ~/.hermes/config.yaml
```

### 2. List Available Backends

Available search backends are installed as `plugins/web/*/` under the Hermes source directory. Each has its own auth requirements:

| Backend | Auth | Free? | Notes |
|---------|------|-------|-------|
| `ddgs` | None | ✅ Free | Default, unreliable from China |
| `exa` | `EXA_API_KEY` | Paid tier | Fast, reliable, AI-native search |
| `tavily` | `TAVILY_API_KEY` | Paid tier | Good for content extraction |
| `brave-free` | `BRAVE_SEARCH_API_KEY` | ✅ Free tier | Requires Brave Search API signup |
| `searxng` | Self-hosted | ✅ Free | Requires own instance + config |
| `firecrawl` | `FIRECRAWL_API_KEY` | Paid tier | Search + crawl |
| `parallel` | `PARALLEL_API_KEY` | Paid tier | AI-native search and extract |

### 3. Check Which API Keys Are Set

```bash
grep -E "EXA|TAVILY|BRAVE|PARALLEL|FIRECRAWL|SEARXNG" ~/.hermes/.env
```

Keys ending with `=` (empty) are commented out or unconfigured. Keys with actual values are ready to use.

### 4. Switch to a Working Backend

```bash
# Switch search backend to exa (requires EXA_API_KEY in .env)
hermes config set web.search_backend exa

# Switch extract backend independently (default: tavily)
hermes config set web.extract_backend tavily

# Or use a shared backend for both
hermes config set web.backend exa
```

### 5. Verify

Use `web_search` with a simple test query — if it returns results without timeout, the switch is working.

Extract backends are verified via `web_extract` on a known-good URL.

## Common Scenarios

| Scenario | Root Cause | Fix |
|----------|------------|-----|
| ddgs times out >50% of calls | DuckDuckGo blocked/slow from China | Switch to exa or tavily |
| Backend errors "no API key" | Required env var not set | Add key to `~/.hermes/.env` |
| Search works but extract fails | `extract_backend` uses different provider | Configure independently via `web.extract_backend` |
| New backend chosen but still fails | API key may be expired or out of quota | Check provider dashboard or switch to another |

## Pitfalls

- **Config change takes effect immediately** — unlike model/provider changes that need `/reset`, the web search backend is read at call time. No session restart needed.
- **Search and extract are independent** — configure `web.search_backend` and `web.extract_backend` separately. They can use different providers.
- **Proxy adds latency** — if mihomo/Clash proxy is running (TUN mode), API calls to the search backend go through it. Test with and without proxy to isolate.
- **Available != configured** — a backend may be registered (visible in `plugins/web/*/`) but unreachable if its required env var is not set. The active provider resolution chain (`agent/web_search_registry.py`) walks a legacy preference order (`firecrawl → parallel → tavily → exa → searxng → brave-free → ddgs`) filtered by `is_available()`. Setting the config explicitly bypasses availability checks.
- **Extract may fall through silently** — if `web.extract_backend` names a provider that doesn't support extraction (e.g., `brave-free` is search-only), the system falls through to available backends. The user may get search from one provider and extract from another without realizing it.
