# Init-Time Blocking Network Calls

Hermes Agent makes several synchronous HTTP requests during startup — before any user
message is processed. In restrictive networks (China firewall, corporate proxy, air-gapped
environments), these calls block agent initialization with their timeouts.

## Blocking Call #1: OpenRouter Model Metadata

**URL:** `https://openrouter.ai/api/v1/models`  
**File:** `agent/model_metadata.py` → `fetch_model_metadata()` (line 631)  
**Timeout:** 10 seconds  
**Gating condition:** ALWAYS fires on agent init when context length needs to be resolved
for any model — even when the primary provider is **not** OpenRouter.

```python
response = requests.get(OPENROUTER_MODELS_URL, timeout=10, verify=_resolve_requests_verify())
```

The call is synchronous (blocks the main thread during agent init). On timeout, the
exception is caught and the function returns an empty/fallback cache silently — no
visible error to the user, no WARNING log, just a 10-second pause.

### Why it fires for non-OpenRouter users

The call chain is:

```
agent_init (agent_init.py) → ... →
  ContextCompressor.__init__ (context_compressor.py:665) →
    get_model_context_length (model_metadata.py:1529) →
      fetch_model_metadata (model_metadata.py:1486) →
        requests.get(OPENROUTER_MODELS_URL, timeout=10)
```

Even though `agent_init.py:405` has an explicit prewarm guard that only fires for
OpenRouter providers:
```python
if (agent.provider == "openrouter" or agent._is_openrouter_url()) ...
```

The `get_model_context_length()` function is called from `ContextCompressor.__init__()`,
which runs unconditionally during agent setup. That function calls
`fetch_model_metadata()` at line 1486 as part of its multi-step context-length
resolution (step 5f in the function's chain), gated on `effective_provider == "openrouter"`.
But wait — the first call to `fetch_model_metadata()` at line 1486 has NO gate: it fires
for anyone whose base_url is empty or whose endpoint didn't return a portal context.

**In practice:** If the primary provider is `opencode-go`, `deepseek`, `xiaomi`, or any
non-OpenRouter, non-portal provider, the OpenRouter fetch executes unconditionally.

### Log signature (verbose mode)

```
00:06:35 - agent.model_metadata - DEBUG - Fetched metadata for 994 models from OpenRouter
```

Without verbose mode, there's no visible indication of this call.

---

## Blocking Call #2: Models.dev Registry

**URL:** `https://models.dev/api.json`  
**File:** `agent/models_dev.py` → `fetch_models_dev()` (line 293)  
**Timeout:** 15 seconds  
**Gating condition:** Only fires when the on-disk cache (`~/.hermes/models_dev_cache.json`)
is missing or older than 1 hour (`_MODELS_DEV_CACHE_TTL = 3600`).

```python
response = requests.get(MODELS_DEV_URL, timeout=15)
```

### Cache hierarchy

1. In-memory cache (<1h old) → instant, no I/O
2. **Disk cache** (file mtime <1h) → ~500ms, no network ← **most cold-starts hit this**
3. Network fetch → 15s timeout on failure
4. Stale disk fallback (5-min grace period before retry)

### When it hurts

- First cold start on a new machine (no cache file yet)
- After `hermes config refresh` (force-refreshes the registry)
- After the cache file ages past 1h (happens ~12x per day)

### Log signature

Fresh disk cache hit (fast path):
```
agent.models_dev - DEBUG - Loaded models.dev from fresh disk cache (145 providers, age=702s)
```

Network fetch (slow path, with proxy):
```
agent.models_dev - DEBUG - Fetched models.dev registry: 145 providers, 5019 total models
```

Network timeout (slow path, without proxy):
```
agent.models_dev - DEBUG - Failed to fetch models.dev: ConnectTimeout(...)
```

---

## Combined Impact

| Scenario | OpenRouter (10s) | Models.dev (15s) | Total init delay |
|----------|:----------------:|:-----------------:|:----------------:|
| Proxy on, fresh cache | ~0.1s | ~0s (disk cache) | ~0.1s |
| Proxy on, cache expired | ~0.1s | ~1-3s | ~1-3s |
| No proxy, fresh cache | **~10s (timeout)** | ~0s (disk cache) | **~10s** |
| No proxy, cache expired | **~10s (timeout)** | **~15s (timeout)** | **~25s** |
| No proxy, first run | **~10s (timeout)** | **~15s (timeout)** | **~25s** |

---

## Diagnosis

Run a minimal chat with verbose logging and grep for the blocking calls:

```bash
hermes chat -q "Hi" -v --ignore-rules 2>&1 | grep -E "model_metadata|models.dev|OpenRouter"
```

Expected output with proxy:
```
agent.model_metadata - DEBUG - Fetched metadata for 994 models from OpenRouter
agent.models_dev - DEBUG - Loaded models.dev from fresh disk cache (...)
```

Expected output without proxy (cache expired):
```
agent.model_metadata - DEBUG - Failed to fetch model metadata from OpenRouter: ...
agent.models_dev - DEBUG - Failed to fetch models.dev: ...
```

To measure exact timing:
```bash
time hermes chat -q "Hi" --ignore-rules 2>/dev/null
```

Compare run times with proxy ON vs OFF.

---

## Workarounds

### Recommended: Run a proxy

The simplest fix. Both OpenRouter and models.dev are accessible via any standard
proxy (mihomo/Clash/V2Ray). Proxy routes these foreign-domain requests externally
while domestic API calls (DeepSeek, Xiaomi, Alibaba) go direct.

```bash
# Start proxy
export CLASHCTL_HOME="$HOME/clashctl"
source "$CLASHCTL_HOME"/scripts/cmd/clashctl.sh
clashctl on

# Verify not blocking anymore
hermes chat -q "Hi" -v --ignore-rules 2>&1 | grep "model_metadata"
```

### Alternative: Pre-warm the cache while proxy is on

If you normally run without proxy, periodically refresh both caches with proxy on:

```bash
# Turn proxy on first, then:
hermes config refresh       # Forces models.dev + OpenRouter refresh

# Or just invoke the internal functions by running a quick chat
hermes chat -q "Hi" --ignore-rules
```

The models.dev disk cache stays valid for 1 hour. The OpenRouter in-memory cache
stays valid for 1 hour (per process lifetime). This reduces the pain to one slow
init per hour instead of every init.

### Future fix (upstream): Lazy / provider-gated resolution

The real fix is to gate `fetch_model_metadata()` on the primary provider actually
being OpenRouter, or make it lazily resolve on first need. Until Hermes ships that
change, this reference documents the workaround.

---

## The "Proxies-Hurt-APIs" Trap

This creates a confusing situation:

| Connection type | Without proxy | With proxy |
|----------------|:-------------:|:----------:|
| OpenRouter/model.dev fetch | ❌ 10-25s timeout | ✅ Fast |
| DeepSeek API (domestic)     | ✅ Fast | ❌ Slower (routed via HK/SG proxy) |
| web_search (DuckDuckGo)     | ❌ 25s timeout | ✅ Fast |

**The proxy helps some calls and hurts others.** The ideal config is:
- **Proxy ON** → for init (OpenRouter/models.dev) and web_search
- **Proxy OFF** → for domestic API calls (DeepSeek, Xiaomi)

If you have a proxy with PAC/rule-based routing, add direct-connect rules for:
```
opencode.ai
api.deepseek.com
api.xiaomi.com
```
So domestic API traffic bypasses the proxy while foreign calls go through it.
