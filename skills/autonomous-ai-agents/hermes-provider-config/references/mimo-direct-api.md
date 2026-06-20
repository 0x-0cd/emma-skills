# Calling Xiaomi MiMo API Directly (When vision toolset isn't loaded)

The `vision_analyze` tool requires the `vision` toolset which only takes effect on **next session** after enabling (`hermes tools enable vision`). When you need image analysis in the current session, call the Xiaomi MiMo API directly via curl.

## Prerequisites

- `XIAOMI_API_KEY` set in `~/.hermes/.env` (already configured)
- `auxiliary.vision.provider: xiaomi` and `auxiliary.vision.model: mimo-v2.5` in config

## Pattern (terminal)

```bash
# 1. Write base64-encoded image payload to a temp file
#    Use execute_code with Python to build the JSON payload

# 2. Call the API
source ~/.hermes/.env && curl -s -o /tmp/mimo_out.json -w "%{http_code}" \
  "https://api.xiaomimimo.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer *** \
  -d @/tmp/mimo_payload.json

# 3. Read the output
python3 -c "
import json
with open('/tmp/mimo_out.json') as f:
    data = json.load(f)
c = data['choices'][0]
print(c['message'].get('content', ''))
"
```

## Pattern (execute_code with Python)

```python
import json, os, re, base64, subprocess

# Build payload
img_path = "/path/to/image.png"
with open(img_path, "rb") as f:
    img_b64 = base64.b64encode(f.read()).decode()

payload = {
    "model": "mimo-v2.5",
    "messages": [{
        "role": "user",
        "content": [
            {"type": "text", "text": "分析这张图片"},
            {"type": "image_url", "image_url": {
                "url": f"data:image/png;base64,{img_b64}"
            }}
        ]
    }],
    "max_tokens": 4000
}

with open("/tmp/mimo_payload.json", "w") as f:
    json.dump(payload, f, ensure_ascii=False)

# Call via bash with env sourced
result = subprocess.run(
    ["bash", "-c",
        "source ~/.hermes/.env && "
        "curl -s -o /tmp/mimo_out.json -w '%{http_code}' "
        "'https://api.xiaomimimo.com/v1/chat/completions' "
        "-H 'Content-Type: application/json' "
        "-H 'Authorization: Bearer *** "
        "-d @/tmp/mimo_payload.json"],
    capture_output=True, text=True, timeout=120
)

# Read result
with open("/tmp/mimo_out.json") as f:
    data = json.load(f)
content = data['choices'][0]['message'].get('content', '')
```

## Pitfalls

- **`***` in the curl command**: The shell outputs `***` when Hermes redacts the API key, but the actual `$XIAOMI_API_KEY` env var is correct after `source ~/.hermes/.env`. Do NOT replace `***` with a literal value — keep `***` in the command and Hermes handles it.
- **Image size**: Base64-encoded image can be large (200K+ chars). The MiMo model accepts up to ~4410 image tokens (roughly one 1080p PNG screenshot).
- **Reasoning overhead**: MiMo V2.5 uses chain-of-thought reasoning. Set `max_tokens` to at least 4000 to leave room for the visible response after reasoning.
- **Payload on disk**: Write the JSON payload to a temp file and use `@file.json` in curl to avoid bash escaping issues with the inline JSON.
