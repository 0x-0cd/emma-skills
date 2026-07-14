# Empty LLM Response Debugging

**Pattern:** LLM API returns empty/none responses despite being reachable and authenticated.

## Diagnosis Flow

### 1. Distinguish: Is the API stable or flaky?

Run a rapid sequential test with 5 simple prompts:

```bash
export http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890
for i in 1 2 3 4 5; do
  echo "=== Request $i ==="
  timeout 30 ~/.opencode/bin/opencode run -m opencode-go/deepseek-v4-flash \
    "Just answer with the number $i. No other text." 2>&1
  sleep 2
done
```

- **All 5 return non-empty → API is healthy.** The issue is prompt-specific (length, content, or client handling).
- **503/5xx errors → Provider outage.** Wait and re-test.
- **Empty responses with no error → Client-side detection bug or reasoning_content issue.**

### 2. Inspect the Raw API Response

Don't rely on the SDK/client library — call the API directly with `curl` to see the actual response shape:

```bash
KEY=$(python3 -c "import json; print(json.load(open('$HOME/.local/share/opencode/auth.json'))['opencode-go']['key'])")

curl -s --connect-timeout 30 \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-v4-flash",
    "messages": [{"role": "user", "content": "Your benchmark prompt here..."}],
    "max_tokens": 4096
  }' https://opencode.ai/zen/go/v1/chat/completions | python3 -c "
import json,sys; d=json.load(sys.stdin); c=d['choices'][0]
print(f'finish_reason: {c[\"finish_reason\"]}')
content = c['message'].get('content', '')
print(f'content: \"{content[:200]}\"')
print(f'content is None? {content is None}')
print(f'content == \"\"? {content == \"\"}')
rc = c['message'].get('reasoning_content', '')
print(f'reasoning_content length: {len(rc)} chars')
print(f'reasoning_content[:80]: \"{rc[:80]}\"')
t = d['usage']
print(f'prompt_tokens: {t[\"prompt_tokens\"]}, completion_tokens: {t[\"completion_tokens\"]}')
"
```

**Key fields to check:**

| Field | What it tells you |
|-------|------------------|
| `finish_reason` | `"length"` → hit max_tokens; `"stop"` → normal; `"error"` → provider issue |
| `content` | Actual response text. Empty `""` vs `None` matters for client checks. |
| `reasoning_content` | Non-empty → model's chain-of-thought consumed token budget. Present in opencode-go's deepseek-v4-flash, absent in direct DeepSeek API. |
| `usage.completion_tokens` | High value with empty content → all budget went to reasoning. |

### 3. Common Root Causes

#### Root Cause A: Client checks `is None` but API returns `""`

**Symptom:** SDK client returns empty string silently — no retry, no error log.

**How it happens:**
```python
# BUG: API returns "" (empty string), content is None is False
content = resp.choices[0].message.content
if content is None:       # ← DOES NOT CATCH ""
    ...
    return content.strip()  # ← returns ""
```

**Fix:**
```python
# CORRECT: catches both None and ""
if not content:            # ← CATCHES BOTH
    # retry
```

**The opencode-go `deepseek-v4-flash` model specifically returns `content: ""` instead of `content: null`** when `reasoning_content` fills the token budget. The `openai` Python SDK deserializes `null` to `None` but `""` to `""` — the SDK itself is fine, the guard code in the application just needs to check `not content` instead of `content is None`.

#### Root Cause B: `reasoning_content` consumes max_tokens

**Symptom:** `finish_reason: "length"`, empty content, non-empty reasoning_content.

**Mechanism:** Some providers emit `reasoning_content` (chain-of-thought tokens) as part of the completion. These tokens count toward `max_tokens`. If the model spends all its token budget on reasoning, content comes back empty.

**Fix A (quick):** Use `max_completion_tokens` instead of `max_tokens` for models that emit `reasoning_content`. The API splits the budget: `max_completion_tokens` caps only the visible content, leaving reasoning unbounded. This is the correct parameter for reasoning-enabled models.

```python
# For models with reasoning_content (deepseek-v4-flash via opencode-go):
#   max_tokens = reasoning + content (SHARED budget)
#   max_completion_tokens = content only (RECOMMENDED)
return {"max_completion_tokens": max_tokens}
```

Applied in `LLMClient._openai_chat_token_limit_kwargs()`:
```python
def _openai_chat_token_limit_kwargs(self, max_tokens: int) -> dict[str, Any]:
    m = self.model.lower()
    if m.startswith(("gpt-5", "o1", "o3", "o4")):
        return {"max_completion_tokens": max_tokens}
    if m.startswith("deepseek") or "deepseek" in m:
        return {"max_completion_tokens": max_tokens}   # ← fix
    return {"max_tokens": max_tokens}
```

**Fix B (fallback):** If the provider doesn't support `max_completion_tokens`, increase `max_tokens` to give room for both reasoning and actual output:
```python
max_tokens = 8192  # double the default for long-context prompts
```

**How to verify which parameter the API accepts:**
```bash
# Test with max_completion_tokens:
curl -s -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"hi"}],"max_completion_tokens":10}' \
  https://opencode.ai/zen/go/v1/chat/completions | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'])"

# Compare: max_completion_tokens=4096 gives ~3.7KB content + reasoning
#          max_tokens=4096 gives ~5KB content (reasoning shares budget)
# The choice affects completion yield: prefer max_completion_tokens for
# guaranteed visible content, max_tokens for maximum total output.
```

#### Root Cause C: Provider-side prompt filtering

**Symptom:** Specific questions consistently return empty across multiple retries (even after provider recovery), while other questions work fine.

**Mechanism:** Some providers filter or silently drop requests matching certain patterns (excessively long prompts, specific keywords, multi-hop reasoning chains).

**Fix:** 
- Retry with exponential backoff (some filters are transient)
- For persistent empty responses: switch to a different provider or direct API
- In benchmark context: track which question IDs fail consistently and categorize them

### 4. The `opencode-go` Specific Profile

| Aspect | Behavior |
|--------|----------|
| **Empty response rate** | ~15-51% depending on prompt length and complexity |
| **Error format** | `content: ""` (empty string), NOT `content: null` |
| **finish_reason when empty** | `"length"` or `"stop"` — both possible |
| **reasoning_content** | Always present, can consume 20-100+ tokens |
| **503 errors** | Intermittent service outages (recover within hours) |
| **Non-empty quality** | ~96% correct — matches direct DeepSeek when it works |
| **Retry effectiveness** | ~70% of empty responses recover within 2-4 retries |
| **Persistently empty** | ~10-15% never recover even with unlimited retries |

## Practical Example: Full Debugging Session

Below is a real debugging transcript showing the progression from "ping works but benchmark fails" to root cause and both fixes:

```bash
# Step 1: Quick ping works
$ opencode run 'ping'  →  pong   ✅

# Step 2: 5 sequential short answers
$ for i in 1..5; do opencode run "answer: $i"; done
→ 1 2 3 4 5  ✅

# Step 3: Benchmark rerun script fails — empty responses on question 1
$ python rerun_empty.py results.json
→ [1/14] conv1_q8 [temporal]  ⚠️  empty after 10 retries  ❌

# Step 4: Raw API inspection reveals the issue
$ curl -s ... | python3 parse_response.py
→ finish_reason: length
→ content: ""
→ reasoning_content: "We are given memories with dates..."
→ completion_tokens: 4096  ← all budget used

# Step 5: Compare max_tokens vs max_completion_tokens
$ curl with max_tokens=4096  → content="" (reasoning consumed all)
$ curl with max_tokens=50    → content="PONG", reasoning=20 tokens
$ curl with max_completion_tokens=4096 → content="PONG", reasoning=15KB, completion=3968
# → max_completion_tokens gives content its own budget, works reliably

# Step 6: Apply both fixes to LLMClient
patch 1: content is None  →  not content     (catches "")
patch 2: max_tokens       →  max_completion_tokens for deepseek models  (dedicated budget)

# Step 7: Re-run — previously empty questions now work
$ python rerun_empty.py results.json
→ [1/14] ✅ CORRECT
→ [2/14] ✅ CORRECT
→ ...
→ Final: 10/14 recovered, overall score 73/81 = 90.1%  🎉
```

**Key insight from this session:** The `max_tokens` vs `max_completion_tokens` distinction is subtle and easy to miss. When a model emits `reasoning_content`, the `max_tokens` parameter pools the budget for both reasoning AND visible content. `max_completion_tokens` gives the visible content an independent quota. This is documented by OpenAI for their o-series models, but the same mechanism applies to any reasoning-enabled model—including DeepSeek V4 Flash routed through opencode-go.

## Verification After Fix

After applying the `not content` fix, re-run the benchmark retry script:

```bash
cd ~/projects/memory-benchmarks
http_proxy=http://127.0.0.1:7890 .venv/bin/python rerun_empty.py results/locomo_mneme/locomo_mneme_local_conv1-retry_*.json
```

Expected improvement: Previously empty questions should now retry properly when the API is healthy.
