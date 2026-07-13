# Provider Quality Analysis (LoCoMo Benchmark)

Analysis from Mneme Conv 0-5 benchmark runs comparing direct DeepSeek API vs opencode-go proxy.

## Head-to-Head: Conv 0-5 (581 questions)

| Metric | Direct DeepSeek | Opencode-go Proxy | Delta |
|--------|:---------------:|:-----------------:|:-----:|
| Overall accuracy | **78.3%** | **46.3%** | -32.0pp |
| Empty responses | 9.5% | **51.2%** | +41.7pp |
| Avg answer length | 64 chars | 33 chars | -31 chars |
| Non-empty accuracy | ~87% | **~96%** | +9pp |
| Wall time (per 100 Qs) | ~30 min | ~70 min | 2.3× slower |

## Root Cause: Empty Responses

The 32pp accuracy gap is almost entirely explained by empty responses:

- Opencode-go returns **51.2% empty answers** (blank string `""`)
- Direct DeepSeek returns only **9.5% empty answers**
- When opencode-go DOES return content, it's actually **more accurate** than direct DeepSeek (96% vs 87% on non-empty responses)

This suggests the opencode-go proxy has a server-side issue with long-context prompts (the benchmark sends top-50 search results in the answer generation prompt). The API may silently drop or truncate responses under context pressure.

## Mitigation: ANSWER_RETRIES

Add retry logic with exponential backoff:

```python
for attempt in range(ANSWER_RETRIES):  # default 5
    if attempt > 0:
        await asyncio.sleep(min(2 ** attempt, 30))
    raw = await answerer.generate(...)
    answer = raw.strip()
    if answer:
        break
```

This handles the transient empty response issue. After 5 retries with backoff (total ~31s), if the API still returns empty, it's logged as a true failure.

## Per-Category Breakdown (Direct DeepSeek)

| Category | Accuracy |
|----------|:--------:|
| single-hop | 79.5% |
| multi-hop | 81.4% |
| temporal | 77.2% |
| open-domain | 67.9% |

Open-domain questions are hardest (less explicit grounding in memory content).
Temporal questions benefit most from the date-prefixing fix in chunk content.

## Recommendation

For benchmark-quality results: **always use direct DeepSeek API** (~$0.67 for full 1,540-question run). Opencode-go is only suitable if you need consolidated API call records and can accept the quality hit — use `ANSWER_RETRIES=5` to mitigate empty responses.
