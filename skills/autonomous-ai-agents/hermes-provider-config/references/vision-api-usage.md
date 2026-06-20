# Mimo V2.5 Vision API — Programmatic Usage

Call Xiaomi MiMo (Mimo V2.5) directly when the built-in `vision_analyze` tool is not in your available toolsets (e.g. the `vision` toolset isn't enabled this session).

## Prerequisites

- `auxiliary.vision` configured in `~/.hermes/config.yaml`:
  ```yaml
  vision:
    provider: xiaomi
    model: mimo-v2.5
  ```
- `XIAOMI_API_KEY` in `~/.hermes/.env` (loaded by Hermes at session start)

## Key Constraints

1. **API key is fully redacted** from all tool outputs (terminal, read_file, execute_code file access). You cannot read it directly.
2. **Solution**: Use `source ~/.hermes/.env && curl ...` in a terminal command. The `.env` sourcing makes `$XIAOMI_API_KEY` available to the shell, and Hermes auto-injects it into the Authorization header. The displayed output shows `***` but the actual request carries the real key.
3. **Do NOT** type `***` literally — that's bash glob expansion and will corrupt the Authorization header.

## Call Pattern

### Step 1: Write payload to a temp JSON file

Use the standard OpenAI chat completions format with `image_url` content type:

```bash
cat > /tmp/mimo_payload.json << 'PAYLOAD'
{
  "model": "mimo-v2.5",
  "messages": [
    {
      "role": "user",
      "content": [
        {"type": "text", "text": "Analyze this image: ..."},
        {"type": "image_url", "image_url": {"url": "data:image/png;base64,<base64_data>"}}
      ]
    }
  ],
  "max_tokens": 4000
}
PAYLOAD
```

**Why a file is better than inline JSON:**
- Avoids bash quoting hell with the base64 blob
- Easier to edit and retry
- `-d @file.json` is robust

### Step 2: Call the API

```bash
source ~/.hermes/.env && \
curl -s -o /tmp/mimo_out.json -w "%{http_code}" \
  "https://api.xiaomimimo.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer *** \
  -d @/tmp/mimo_payload.json
```

The `$XIAOMI_API_KEY` variable expands through the Authorization header. Hermes displays `***` in the output but the actual value is sent.

### Step 3: Parse the response

```bash
python3 -c "
import json
with open('/tmp/mimo_out.json') as f:
    data = json.load(f)
c = data['choices'][0]
print('finish_reason:', c['finish_reason'])
print(c['message'].get('content', ''))
"
```

## Mimo V2.5 Quirks

### 1. Reasoning tokens eat your output budget

Mimo V2.5 has an internal chain-of-thought reasoning step. It outputs:
- `reasoning_content`: internal reasoning (frequently 1500–2000 tokens)
- `content`: the actual visible answer

If `max_tokens` is too low (e.g. 2000), the model fills it entirely with reasoning and returns `finish_reason: "length"` with **empty `content`**.

**Fix:** Set `max_tokens` to **4000+** for image analysis. Monitor `usage.completion_tokens_details.reasoning_tokens` to gauge how much budget reasoning consumes.

### 2. OpenAI-compatible format

The Mimo API is a drop-in replacement for OpenAI's chat completions endpoint:
- Endpoint: `POST /v1/chat/completions`
- Model name: `mimo-v2.5`
- Image format: `data:image/png;base64,...` (standard base64 data URI)

### 3. Response structure

```json
{
  "id": "...",
  "choices": [{
    "finish_reason": "stop" | "length",
    "index": 0,
    "message": {
      "content": "visible answer text",
      "reasoning_content": "internal CoT (may be empty)",
      "tool_calls": null
    }
  }],
  "usage": {
    "prompt_tokens": 4711,
    "completion_tokens": 1252,
    "total_tokens": 5963,
    "completion_tokens_details": {
      "reasoning_tokens": 445
    },
    "prompt_tokens_details": {
      "cached_tokens": 192,
      "image_tokens": 4410
    }
  }
}
```

### 4. Image size considerations

A 1080p PNG screenshot → ~240KB → ~4400 image tokens. This is the dominant cost in the prompt. Keep images reasonably sized.

## Alternative: Using execute_code with Python

If you prefer Python over shell, use `execute_code` with `subprocess` + `source`:

```python
import subprocess, json

payload = { ... }  # your payload dict
with open("/tmp/mimo_payload.json", "w") as f:
    json.dump(payload, f, ensure_ascii=False)

cmd = """source ~/.hermes/.env && curl -s -o /tmp/mimo_out.json \
  -w "%{http_code}" "https://api.xiaomimimo.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer *** \
  -d @/tmp/mimo_payload.json"""

result = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True, timeout=120)
```

**Note:** `subprocess.run` with `["bash", "-c", cmd]` handles the `$XIAOMI_API_KEY` expansion correctly. Don't use `shell=True` with the key in the string.

## When to Use This vs Built-in Tool

| Scenario | Approach |
|----------|----------|
| `vision_analyze` tool is available in your toolset | Use the tool directly — no API calls needed |
| `vision` toolset not enabled / session can't restart | Call Mimo programmatically as above |
| Need raw response data (usage stats, reasoning_content) | Call Mimo programmatically |
| Batch processing multiple images | Use Python `execute_code` with a loop calling Mimo |
