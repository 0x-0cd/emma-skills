# LoCoMo + Mneme Integration Notes

Session-specific details from the initial LoCoMo integration with Mneme (June 2026).

## Environment

- **Hardware**: Raspberry Pi 4B (4GB RAM, SD card, 5-15W)
- **Memory system**: Mneme (custom in-house, sqlite-vec backend)
- **LLM**: DeepSeek V4 Flash via `https://api.deepseek.com/v1`
- **OS**: Linux 6.8.0-1057-raspi (ARM64)
- **Proxy**: Clash + mihomo (HTTP 7890, SOCKS 7891)

## API Key Configuration

DeepSeek API keys live in `~/.local/share/opencode/auth.json`:

```json
{
  "deepseek": {
    "type": "api",
    "key": "sk-235a..."
  },
  "opencode-go": {
    "type": "api",
    "key": "sk-3yOD..."
  }
}
```

Use env var → `auth.json["deepseek"]["key"]` → `auth.json["opencode-go"]["key"]` in order.

## Model Names

| Target | Model String |
|--------|-------------|
| Direct DeepSeek API | `deepseek-v4-flash` |
| Direct DeepSeek API | `deepseek-v4-pro` |
| OpenCode proxy | `opencode-go/deepseek-v4-flash` |

## The Temporal Metadata Bug

### Root Cause
The LoCoMo benchmark prompt sorts memories by `created_at` and shows dates like `(May 7, 2023)` before each chunk. But when chunks are stored via Mneme's API, the server sets `created_at` to the **ingestion timestamp** (current time), not the conversation's session date.

### Fix
Prepend the session date to the **content text itself** before storing:

```python
date_str = "8 May, 2023"
chunk_text = f"[{date_str}] " + memory_text
```

### Detection
- Search returns good scores but temporal questions all fail
- Model outputs today-ish dates instead of 2022-2023 dates
- The `reference_date` parameter is set correctly but overridden

## Local Benchmark Mode (no HTTP server)

### Why needed
On this Raspberry Pi, uvicorn serves sync clients (urllib) fine but async clients (aiohttp, httpx) consistently timeout. The server accepts TCP connections but never sends the HTTP response. Switching to in-process mode bypasses this entirely.

### Cross-venv dependency import
When running the benchmark from the benchmark venv but importing Mneme library, add Mneme's site-packages to sys.path:

```python
MNEME_PROJECT_DIR = os.path.expanduser("~/projects/ai-memory-system")
sys.path.insert(0, os.path.join(MNEME_PROJECT_DIR, "src"))
_site = os.path.join(MNEME_PROJECT_DIR, ".venv/lib/python3.11/site-packages")
if _site not in sys.path:
    sys.path.insert(0, _site)
```

### Trade-offs
- ✅ No server/port management
- ✅ No connection timeouts
- ⚠️ ONNX model loads at startup (~9s)
- ⚠️ Can't test HTTP API layer

### ⚠️ user_id: direct field, not metadata
When constructing `Memory` objects directly (local mode), `user_id` must be a **direct constructor argument**, not buried in `metadata`. The `Memory` dataclass has a top-level `user_id` field that the search filter queries:

```python
# ❌ WRONG — search by user_id will find ZERO results
memory = Memory(
    content=text,
    type=MemoryType("conversation"),
    metadata={"user_id": user_id},  # search doesn't look here
)

# ✅ CORRECT
memory = Memory(
    content=text,
    type=MemoryType("conversation"),
    user_id=user_id,  # search filter matches this
    tags=[f"user:{user_id}"],
    metadata={"timestamp": session_epoch},  # only non-search metadata here
)
```

Symptom: ingestion succeeds (DB grows) but all searches return 0 results regardless of query content. The `searcher.search(user_id=...)` filters by `Memory.user_id`, not `metadata["user_id"]`.

### Background Process Output Capture
The Hermes background process may not show intermediate output even with `-u` and `stdbuf -oL`. The `output_preview` field in `process(action='poll')` may remain empty until the process exits. Write progress to a file as a fallback.

## KeyError: Missing QA Fields

### Symptom
Benchmark runs ingestion fine, then crashes on question N with `KeyError: 'question'`. Not all entries in the QA list have the expected keys.

### Fix
Filter out malformed entries in the per-conversation question selection:

```python
conv_questions = [
    (qi, qa) for qi, qa in enumerate(questions)
    if qa.get("category") in CATEGORIES_TO_EVALUATE
    and qa.get("question") and qa.get("answer")
][:MAX_QUESTIONS]
```

## Background Process Output Buffering

The Hermes background process capture may not show intermediate output even with `python3 -u`. Use `stdbuf -oL` for line-buffered output:

```bash
stdbuf -oL .venv/bin/python3 -u run_benchmark.py 2>&1
```

To check progress, poll the process status (`process(action='poll')`) — but the output_preview field may still be empty until the process exits. Write progress to a log file as a fallback.

## Benchmark Results (June 2026)

### Field Mapping Bug: `content` → `memory` key mismatch

**Root cause:** `Memory.to_dict()` returns `{"content": "...", "type": "...", ...}` but the answer generation prompt reads `memory` as the text key. This caused the LLM to see empty input → answer "No information available" → 100% WRONG.

**Symptom:** Search returns 50/50 results with good scores, but every single answer is "No information available" → ~10% accuracy.

**Fix:** Map fields before passing to prompt:
```python
memories_for_prompt = [
    {"memory": m.to_dict().get("content", ""),
     "created_at": m.to_dict().get("created_at", ""),
     "id": m.to_dict().get("id", ""),
     "score": s}
    for m, s in search_results
]
```

**After fix:** Accuracy went from 10.0% → 90.0% (Conv 0, 20 questions).

### Baseline (no weight calibration)
- Recall: 2.60 / 7.00
- Precision: 2.57 / 7.00
- F1: 0.35
- 50 questions evaluated

### With Phase 1-3 (weight calibration + feedback + sleep decay)
- Recall: 3.29 / 7.00 (+26.5%)
- Precision: 3.43 / 7.00 (+33.5%)
- F1: 0.43 (+22.9%)
- 100 questions evaluated (43 evaluation rounds)
- Ingest success rate: 84/100 chunks
