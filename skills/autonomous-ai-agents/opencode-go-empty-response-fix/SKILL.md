---
name: opencode-go-empty-response-fix
description: "Diagnose and fix empty-content responses from opencode-go (deepseek-v4-flash): max_completion_tokens vs max_tokens bug, LLMClient None-check fix, and verification workflow."
version: 1.0.0
author: Emma
license: MIT
metadata:
  hermes:
    tags: [opencode, benchmark, locomo, opencode-go, deepseek, empty-response, llmclient]
    related_skills: [hermes-token-optimization, hermes-maintenance]
---

# opencode-go Empty Response Fix

## Problem

When running LoCoMo benchmarks via opencode-go's deepseek-v4-flash model, some questions return empty content (`""`) despite the API responding successfully (HTTP 200). This causes `rerun_empty.py` to spin forever retrying.

## Root Causes

### Cause 1: LLMClient None-Check Bug

In `benchmarks/common/llm_client.py`, the text-generation method checks:

```python
# BUG: "" (empty string) is NOT None, so this check misses it
if content is None:
    logger.warning(...)
    # retry...
    continue
return content.strip()  # "" returns empty string
```

The opencode-go API returns `content: ""` (not `null`) when reasoning consumes all tokens, so the `is None` check doesn't trigger a retry.

**Fix:** Change `if content is None:` to `if not content:` — this catches both `None` and `""`.

### Cause 2: max_tokens vs max_completion_tokens

opencode-go's deepseek-v4-flash produces `reasoning_content` (chain-of-thought) that shares the same token budget with `max_tokens`. When the prompt is long (e.g., 50 search results as context), reasoning alone can consume all 4096 `max_tokens`, leaving zero budget for visible content → `content: ""` with `finish_reason: "length"`.

**Fix:** Use `max_completion_tokens` instead of `max_tokens` for deepseek models. This separates reasoning budget from visible content budget.

Modify `_openai_chat_token_limit_kwargs` in `LLMClient`:

```python
def _openai_chat_token_limit_kwargs(self, max_tokens: int) -> dict[str, Any]:
    m = self.model.lower()
    if m.startswith(("gpt-5", "o1", "o3", "o4")):
        return {"max_completion_tokens": max_tokens}
    # Add this block:
    if m.startswith("deepseek") or "deepseek" in m:
        return {"max_completion_tokens": max_tokens}
    return {"max_tokens": max_tokens}
```

## Verification Workflow

1. **Quick API stability test:**
```bash
export http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890
KEY=$(python3 -c "import json; print(json.load(open('$HOME/.local/share/opencode/auth.json'))['opencode-go']['key'])" 2>/dev/null)

curl -s --connect-timeout 60 \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -H "User-Agent: opencode-cli" \
  -d '{"model": "deepseek-v4-flash", "messages": [{"role": "user", "content": "Answer with PONG."}], "max_tokens": 50}' \
  https://opencode.ai/zen/go/v1/chat/completions | python3 -c "
import json,sys; d=json.load(sys.stdin); c=d['choices'][0]
content = c['message'].get('content','') or ''
print(f'finish: {c[\"finish_reason\"]}')
print(f'content: {\"✅\" if content.strip() else \"❌\"} \"{content[:100]}\"')
"
```

2. **Run rerun:**
```bash
cd ~/projects/memory-benchmarks
.venv/bin/python rerun_empty.py <results_file>.json
```

3. **Monitor progress:**
```bash
process(action='poll', session_id='<proc_id>')
# or
process(action='log', session_id='<proc_id>')
```

## Script Location

- **rerun_empty.py:** `~/projects/memory-benchmarks/rerun_empty.py`
- **LLMClient:** `~/projects/memory-benchmarks/benchmarks/common/llm_client.py`
- **Result files:** `~/projects/memory-benchmarks/results/locomo_mneme/*.json`

## Pitfalls

- The `_generate_openai` method had the `is None` bug; `_generate_structured_openai` already used `if not raw` correctly — only the text generation path needed fixing.
- `urllib.request` with proxy may get 403 Forbidden on opencode-go API — always use `curl` with proper `User-Agent: opencode-cli` header for manual testing, or use the .venv's `openai` library.
- Each question in rerun takes ~30-90s API time on opencode-go. The total 14-question rerun may take 10-20+ minutes.
- The saved search results in the JSON file (up to 50 memories per question) contribute to prompt length, which increases reasoning consumption.
