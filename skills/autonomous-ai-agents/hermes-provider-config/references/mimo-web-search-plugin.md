# MiMo Web Search Plugin — API Reference

Server-side web search: MiMo generates search queries, Xiaomi backend executes search + page parsing, returns structured citations. No client-side search code needed.

## Prerequisites

1. **API Key**: `XIAOMI_API_KEY` in `~/.hermes/.env` (format: `sk-...`, 51 chars)
2. **Plugin enabled**: Go to https://platform.xiaomimimo.com/#/console/plugin → activate Web Search Plugin
3. **Model**: Only `mimo-v2.5-pro` and `mimo-v2.5` support web search

## API Format

Standard OpenAI-compatible endpoint: `https://api.xiaomimimo.com/v1/chat/completions`

```json
{
  "model": "mimo-v2.5",
  "messages": [{"role": "user", "content": "今天杭州天气怎么样？"}],
  "tools": [{
    "type": "web_search",
    "max_keyword": 3,
    "force_search": true,
    "limit": 3
  }],
  "tool_choice": "auto",
  "max_completion_tokens": 2048,
  "stream": false
}
```

### Tool Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `type` | string | Must be `"web_search"` (not `"function"` or `"builtin_function"`) |
| `max_keyword` | int | Max concurrent search keywords per round. Controls cost — each keyword = 1 search invocation |
| `force_search` | bool | `true` = always search. `false` = model decides if search is needed |
| `limit` | int | Number of search results to return |
| `user_location` | object | Optional. `{type: "approximate", country, region, city}` for location-aware results |

## Response Structure

Search results appear in `message.annotations` (not `tool_calls`):

```json
{
  "choices": [{
    "message": {
      "content": "搜索结果总结...",
      "annotations": [{
        "type": "url_citation",
        "url": "https://...",
        "title": "页面标题",
        "summary": "网页摘要",
        "site_name": "站点名",
        "publish_time": "ISO时间"
      }]
    }
  }],
  "usage": {
    "web_search_usage": {
      "tool_usage": 3,   // search keywords invoked
      "page_usage": 9    // pages parsed
    }
  }
}
```

Key: `reasoning_content` is still returned even if thinking is not explicitly enabled (non-zero reasoning_tokens).

## Pricing

| Service | Price |
|---------|-------|
| 国内联网服务 | ¥16 / 1000 次 |
| 海外联网服务 | $5 / 1000 次 |

**Cost formula per request**: `web_search_usage.tool_usage × price_per_search + input_tokens × model_input_price + output_tokens × model_output_price`

`max_keyword` directly controls cost multiplier — setting it to 5 means up to 5× search invocations per request.

## Curl Test Pattern

```bash
source ~/.hermes/.env && curl -s \
  'https://api.xiaomimimo.com/v1/chat/completions' \
  --header "api-key: $XIAOMI_API_KEY" \
  --header 'Content-Type: application/json' \
  --data '{
    "model": "mimo-v2.5",
    "messages": [{"role": "user", "content": "YOUR QUERY HERE"}],
    "tools": [{"type": "web_search", "max_keyword": 3, "force_search": true, "limit": 3}],
    "tool_choice": "auto",
    "max_completion_tokens": 2048,
    "stream": false
  }' | python3 -m json.tool
```

## Pitfalls

1. **5-minute cache**: After enabling/disabling the plugin in console, changes take 5 minutes to propagate. If search isn't working immediately, wait.

2. **Model may skip search**: Without `force_search: true`, the model judges whether search is needed and may skip it for "general knowledge" questions. Always set `force_search: true` for real-time info queries.

3. **Token inflation**: Search results are injected into the prompt as context. A simple query that would normally use ~200 tokens can balloon to 3000-5000 input tokens. Factor this into cost estimates.

4. **GitHub Issue #20 — Token Plan vs Pay-as-you-go format confusion**: The GitHub issue (https://github.com/XiaomiMiMo/MiMo-V2-Flash/issues/20) reports that Token Plan API (`token-plan-ams.xiaomimimo.com`) uses a DIFFERENT format: `type: "builtin_function"` with `function.name: "$web_search"`. The pay-as-you-go API (`api.xiaomimimo.com`) uses the standard `type: "web_search"` format documented here. Do NOT mix formats.

5. **Only works with `sk-` keys**: Web search plugin requires pay-as-you-go API key (`sk-...`). Token Plan keys (`tp-...`) have a different endpoint and format.

6. **Key location**: `XIAOMI_API_KEY` lives in `~/.hermes/.env`, NOT in `~/.bashrc`. Config.yaml has `api_key: ''` for xiaomi provider — Hermes resolves it from the env var via credential pool.

## Comparison with Hermes Built-in Search

| Feature | MiMo Web Search Plugin | Hermes (exa/tavily) |
|---------|----------------------|---------------------|
| Search execution | Server-side (Xiaomi backend) | Client-side (Hermes calls exa/tavily API) |
| Query generation | Model auto-generates keywords | Agent constructs search query |
| Cost model | Per-keyword invocation + token inflation | Per-search API call |
| Result format | `annotations` with citations | Tool output (structured) |
| Control | `force_search`, `max_keyword` | Direct query control |
| Best for | Real-time Q&A where model should decide what to search | Agent-driven research with specific queries |
