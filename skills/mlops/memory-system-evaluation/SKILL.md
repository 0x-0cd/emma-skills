---
name: memory-system-evaluation
description: Run standard memory benchmarks (LoCoMo, LongMemEval, BEAM) against custom memory backends — adapter creation, ingestion pipeline, parameter tuning, and failure analysis.
version: 1.0.0
author: Emma
tags:
  - Memory Systems
  - Benchmarking
  - LoCoMo
  - Temporal Reasoning
  - Evaluation
  - Vector Search
  - MLOps
---

# Memory System Evaluation

Systematic evaluation of custom memory backends against academic benchmarks. Use when benchmarking, comparing, or debugging a memory system's performance.

## When to Use

- User wants to evaluate a memory system (Mneme, Mem0, custom backend) against standard benchmarks
- Need to run LoCoMo, LongMemEval, or BEAM against your own adapter
- Debugging low benchmark scores — distinguishing search failures from answerer errors from judge errors
- Tuning parameters (TOP_K, chunk size, overlap) for maximum benchmark performance

## Workflow

### Phase 1: Setup

#### 1.1. Clone the benchmark repo
```bash
git clone <benchmarks-repo> && cd <benchmarks-repo>
```

#### 1.2. Create a client adapter
Implement three methods matching the standard async interface:

| Method | Purpose |
|--------|---------|
| `add(messages, user_id, timestamp=None)` | Store conversation turns into memory system |
| `search(query, user_id, top_k=200)` | Semantic search over stored memories |
| `delete_user(user_id)` | Clear memories (between runs) |

The adapter wraps the memory system's HTTP API or SDK into an async client class. See `references/locomo-integration.md` for a complete example.

#### 1.3. Install dependencies
```bash
uv sync --group benchmarks
```
The `benchmarks` optional-deps group should include:
- `httpx` or `aiohttp` (for API calls)
- `openai` (for answerer/judge LLM calls)

#### 1.4. Verify API connectivity
Before running any benchmark, verify the LLM answerer/judge API:
```python
import httpx
r = httpx.post(
    "https://api.deepseek.com/chat/completions",
    headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
    json={"model": "deepseek-v4-flash", "messages": [{"role": "user", "content": "hi"}], "max_tokens": 5},
    timeout=30
)
assert r.status_code == 200
```

### Phase 2: Create Runner

Create a runner script that:
1. Downloads/loads the dataset
2. Ingests conversations into the memory system via the adapter
3. For each question: search → answer → judge
4. Collects results per cut-off (top-10, top-20, top-50)

**Key parameters** (set via environment variables):
- `TOP_K`: Number of search results to retrieve (default 50)
- `MAX_CONVERSATIONS`: Conversations to process (default 1 for smoke test)
- `MAX_QUESTIONS`: Questions per conversation (default 3 for smoke test)

**⚠️ Critical: `MAX_QUESTIONS` is PER-CONVERSATION, not a global total.**
Total question count = `MAX_CONVERSATIONS × min(MAX_QUESTIONS, questions_in_conv)`.
With 5 conversations × 100 questions each = 500 questions × 2 API calls each = 1000 calls.
At RPM=30 (~15s per question pair), that's **~4 hours** of wall time.
**Always compute `total_questions × time_per_question` before starting a full run.**
For a quick comparison benchmark, use `MAX_CONVERSATIONS=3 MAX_QUESTIONS=10` (~60 API calls, ~15 minutes).
- `DEEPSEEK_MODEL`: Answerer/judge model name (default `deepseek-v4-flash`)
- `DEEPSEEK_BASE`: API base URL (default `https://api.deepseek.com/v1`)

**Essential: reference date**
Pass the last session's date string as `reference_date` to the answer generation prompt. This grounds temporal reasoning:
```python
ref_date_human = sorted_sessions[-1][1]  # e.g., "9:55 am on 22 October, 2023"
```

### Phase 3: Smoke Test

Run a minimal test first — 1 conversation, 3 questions:
```bash
TOP_K=50 MAX_CONVERSATIONS=1 MAX_QUESTIONS=3 python3 run_benchmark.py
```

Check for three success signals:
1. **Ingestion**: All chunks stored without errors
2. **Search**: Returns results with scores AND content text
3. **Judge**: DeepSeek API returns 200, judge produces CORRECT/WRONG

### Phase 4: Analyze Failures

Categorize each failed question into one of three failure modes:

| Failure Mode | Signal | Root Cause |
|---|---|---|
| **Search miss** | 0 results, or results lack the relevant chunk | Low TOP_K, poor embedding quality, wrong user_id scope |
| **Answerer error** | Search returned relevant chunks but model gave wrong answer | Missing temporal context in chunk text, model hallucination, poor prompt |
| **Judge error** | Generated answer is actually correct but judge scored 0 | Judge model too strict, structured output parsing failure |

**The most common failure mode** (especially for temporal questions): the memory system stores timestamps in metadata fields, but the benchmark prompt reads `created_at` for chronological display. The fix is always to **embed temporal context in the chunk content text itself**.

#### Recovery: temporal metadata fix
Before storing a chunk, prepend the session date:
```
# BEFORE (broken): created_at = ingestion timestamp (today)
[user] Caroline: I went to a support group yesterday...

# AFTER (fixed): date embedded in content
[2023-05-08] [user] Caroline: I went to a support group yesterday...
```

### Phase 5: Tune Parameters

After smoke test passes, iterate on parameters:

| Parameter | Range | Effect |
|---|---|---|
| `TOP_K` | 50 → 200 | Wider recall, more context for answerer |
| Chunk size (`CHUNK_SIZE`) | 1 → 5+ | Wider context per memory, fewer chunks |
| Embedding model | Small → Large | Better semantic matching |
| Search strategy | Vector only → Hybrid (vector + keyword) | Better recall for named entities |

**Tuning order**: Always fix temporal metadata first (Phase 4), then tune TOP_K, then consider hybrid search.

### Phase 6: Full Run

Once tuned, run the full benchmark:
```bash
TOP_K=200 MAX_CONVERSATIONS=10 python3 run_benchmark.py
```

**Estimate wall time first:**
- Total questions ≈ `MAX_CONVERSATIONS × MAX_QUESTIONS` (per-conversation cap)
- Each question = 2 DeepSeek API calls (answer + judge)
- At RPM=30, each question pair takes ~10-15s
- Example: 3 convs × 10 questions = 30 questions × ~15 min
- Example: 5 convs × 100 questions = 500 questions × ~4 hours
- Use `MAX_CONVERSATIONS=3 MAX_QUESTIONS=10` for a quick comparison run

## Local Mode (no HTTP server)

When your memory system's HTTP server is unreliable (e.g., uvicorn + aiohttp/httpx timeout on ARM64 while sync clients work), bypass it entirely and run the benchmark in-process.

Create a runner that imports the memory system's library directly instead of going through HTTP:

```python
# Add the memory system's source + site-packages to sys.path
sys.path.insert(0, os.path.join(PROJECT_DIR, "src"))
_site = os.path.join(PROJECT_DIR, ".venv/lib/python3.11/site-packages")
if _site not in sys.path:
    sys.path.insert(0, _site)

# Import components directly
from mneme.storage.db import Database
from mneme.storage.vector import VectorIndex
from mneme.embed.model import EmbeddingModel
from mneme.engine.store import Store
from mneme.engine.search import Searcher

# ... then call store.store() and searcher.search() directly
```

The trade-offs:
- ✅ No server startup/teardown overhead
- ✅ No connection timeout issues
- ✅ Faster iteration (skip HTTP serialization)
- ⚠️ Memory system's dependencies must be accessible (see pitfall below)
- ⚠️ ONNX model loads once at startup (~9s for all-MiniLM-L6-v2)
- ⚠️ Can't test the HTTP API layer itself

## Common Pitfalls

### ⚠️ Search result field name: to_dict() keys ≠ prompt expectations

When passing `Memory.to_dict()` results to the answer generation prompt, the dict keys (`content`, `type`, `user_id`, etc.) may not match what the prompt template reads. The prompt likely reads `memory`, `created_at`, or other keys — if the keys don't align, the LLM sees empty content and answers "No information available", yielding 0% scores.

**Symptom:** Search returns 50/50 results with good scores, but every question answers "No information available" → all WRONG.

**Fix:** Map `to_dict()` keys to what the prompt expects before passing to the answerer:

```python
search_results = searcher.search(query, top_k=50, user_id=user_id)
```python
# Map to prompt-expected format
# ⚠️ Memory.to_dict() uses "content" key, but prompts often expect "memory"
memories_for_prompt = []
for mem, score in search_results[:50]:
    d = mem.to_dict()
    # Verify field alignment before running:
    # print(f"to_dict keys: {list(d.keys())}")
    memories_for_prompt.append({
        "memory": d.get("content", ""),       # what prompts typically read
        "created_at": d.get("created_at", ""),
        "id": d.get("id", ""),
        "score": score,
    })

gen_prompt = get_answer_generation_prompt(question, memories_for_prompt, ...)
```

**Verify before running:** Print the first result's keys and compare with the prompt's expected key names.

### ⚠️ Stale checkpoint files cause confusion

A checkpoint saved from a buggy run (wrong field mapping, wrong user_id, wrong timestamp) is loaded automatically on the next run if the checkpoint path is reused. The final results file merges old checkpoint + new evaluations, producing confusing mixed results.

**Fix:** Always remove old checkpoint before starting a fresh run:

```bash
rm -f results/locomo_mneme/checkpoint*.json results/locomo_mneme/locomo_mneme_local_*.json
# And remove the temp DB
rm -f /tmp/mneme_local_bench.db
```

Or use a unique checkpoint path per run (e.g., timestamp in filename).

### ⚠️ user_id must be direct Memory field, not in metadata
In Local Mode, when constructing `Memory` objects directly, the `user_id` filter queries `Memory.user_id` (a dataclass field), NOT `metadata["user_id"]`. Omitting `user_id=` from the Memory constructor causes all searches to return 0 results — ingestion succeeds silently but retrieval is broken.

```python
# ✅ Pass user_id as a direct arg
Memory(content="...", type=MemoryType("conversation"), user_id=user_id, ...)
```

### ⚠️ Malformed QA entries in dataset
Some LoCoMo QA entries may lack `"question"` or `"answer"` keys, causing KeyError on `qa["question"]`. Filter them out in the question selection:

```python
conv_questions = [
    (qi, qa) for qi, qa in enumerate(questions)
    if qa.get("category") in CATEGORIES_TO_EVALUATE
    and qa.get("question") and qa.get("answer")
][:MAX_QUESTIONS]
```

### ⚠️ Async HTTP clients timeout on ARM64 (Raspberry Pi)
On some ARM64 platforms, uvicorn serves sync clients (urllib) fine but aiohttp/httpx consistently timeout. If this happens, confirm by comparing the two clients against the health endpoint, then switch to Local Mode (no HTTP server) above.

### ⚠️ Temporal metadata in metadata ≠ in content
The benchmark prompt sorts memories by `created_at` and prepends dates to each entry. If the memory system stores session timestamps in `metadata.timestamp` but the server sets `created_at` to the ingestion time, **every memory looks like it was created today**. The fix: embed dates in chunk content text.

### ⚠️ API key routing
Many setups have multiple API keys (direct provider key + proxy key). When the runner sets `DEEPSEEK_API_KEY`, ensure you're using the key that works with the actual `DEEPSEEK_BASE` endpoint. **Test direct API first** before trying proxy workarounds — the proxy may be unreliable.

Hierarchy for key discovery:
1. Environment variable (most specific)
2. `~/.local/share/opencode/auth.json` → `deepseek.key` (direct API key)
3. `~/.local/share/opencode/auth.json` → `opencode-go.key` (proxy key, last resort)

### ⚠️ Model naming
DeepSeek V4 API uses model names `deepseek-v4-flash` or `deepseek-v4-pro` (NOT `deepseek-chat`). OpenCode-proxied names use the `opencode-go/` prefix. Don't mix them up:
- Direct API: `deepseek-v4-flash`
- OpenCode proxy: `opencode-go/deepseek-v4-flash`

### ⚠️ Proxy for model downloads
HuggingFace model downloads (tokenizer, embedding models) may need `http_proxy`:
```bash
http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890 python3 run_benchmark.py
```

### ⚠️ Smoke test first, always
A single failed conversation wastes ~5 minutes. Start with `MAX_CONVERSATIONS=1 MAX_QUESTIONS=3` and verify all three pipeline stages (ingest → search → answer) before burning time on 10 conversations.

### ⚠️ Checkpoint after every conversation (local mode)
When running in local mode (no HTTP server), a kill mid-run loses ALL evaluations — there's no partial save. Always save a checkpoint after each conversation completes:

```python
CHECKPOINT_PATH = Path("results/locomo_mneme/checkpoint.json")

def save_checkpoint():
    CHECKPOINT_PATH.parent.mkdir(parents=True, exist_ok=True)
    CHECKPOINT_PATH.write_text(json.dumps({
        "metadata": {...},
        "evaluations": all_evaluations,
    }, indent=2))

# Call after each conversation's evaluation loop
save_checkpoint()
```

A checkpoint means a crash or manual kill only loses the current conversation, not everything before it.

### ⚠️ Check `created_at` on stored memories
If search returns results but all scores are 0.0 or the chronological sort is wrong, inspect the `created_at` field of stored memories — this is often the canary for temporal metadata bugs.

## Verification Checklist

```
Smoke Test:
- [ ] Memory system service is running and health endpoint responds
- [ ] API key works with chosen model (tested via curl/Python)
- [ ] Adapter.add() returns successfully with memory ID
- [ ] Adapter.search() returns results with content text + scores
- [ ] Runner shows "200 OK" for all DeepSeek API calls
- [ ] At least 1/3 questions correct in smoke test
- [ ] `reference_date` appears correctly in answer generation prompt

Full Run:
- [ ] All 10 conversations ingested without errors
- [ ] Results saved to results/locomo_mneme/ directory
- [ ] Per-question breakdown available for failure analysis
```

## Related Skills

- `evaluating-llms-harness` — LLM evaluation (lm-eval-harness), complementary to memory system evaluation
- `onnx-embeddings` — ONNX-based embedding models, often used in edge-deployed memory systems

## References

- `references/locomo-integration.md` — Session-specific: LoCoMo adapter pattern, temporal metadata debugging, API routing for this environment, local benchmark mode
- `references/arm64-uvicorn-debug.md` — Debugging uvicorn + aiohttp/httpx timeout on Raspberry Pi (ARM64)
- `templates/run_locomo_local.py` — Runnable template for local (no-HTTP) benchmark runner
- [LoCoMo: ACL 2024](https://arxiv.org/abs/2404.06064) — Original paper by Snap Research
- [LoCoMo GitHub](https://github.com/snap-research/LoCoMo) — Benchmark dataset and official implementation
- [LongMemEval](https://arxiv.org/abs/2501.11728) — Extended memory evaluation benchmark
