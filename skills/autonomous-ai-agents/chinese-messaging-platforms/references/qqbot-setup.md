# QQ Bot Setup Walkthrough

Connecting Hermes Gateway to QQ Bot via the Official QQ Bot API (v2).

## Prerequisites

1. **QQ Bot Application** — Register at https://q.qq.com
   - Create a new application
   - Note your **App ID** and **App Secret**
2. **Enable Intents** in the bot's developer console:
   - C2C (私聊) messages
   - Group @-messages
   - Guild messages (optional)
3. **Dependencies** (usually already in Hermes venv):
   ```bash
   pip install aiohttp httpx
   ```

## Configuration

### Step 1: Set environment variables in `~/.hermes/.env`

```bash
QQ_APP_ID=your-app-id
QQ_CLIENT_SECRET=your-client-secret
```

Optional env vars:
- `QQBOT_HOME_CHANNEL` — OpenID for cron/notification delivery
- `QQ_ALLOWED_USERS` — Comma-separated user OpenIDs for DM access (default: all)
- `QQ_GROUP_ALLOWED_USERS` — Comma-separated group OpenIDs for group access
- `QQ_ALLOW_ALL_USERS` — Set to `true` to allow all DMs
- `QQ_PORTAL_HOST` — Override portal host (use `sandbox.q.qq.com` for sandbox)

### Step 2: Enable platform in `~/.hermes/config.yaml`

```yaml
platforms:
  qqbot:
    enabled: true
    # Optional advanced config:
    extra:
      markdown_support: true      # enable QQ markdown (msg_type 2)
      dm_policy: open             # open | allowlist | disabled
      group_policy: open          # open | allowlist | disabled
      stt:
        provider: zai             # zai (GLM-ASR), openai (Whisper), etc.
        baseUrl: https://open.bigmodel.cn/api/coding/paas/v4
        apiKey: your-stt-key
        model: glm-asr
```

Alternatively use the interactive wizard:
```bash
hermes gateway setup
# Select "QQ Bot" from the platform list
```

### Step 3: Verify `platform_toolsets` mapping

Check that `~/.hermes/config.yaml` has:
```yaml
platform_toolsets:
  qqbot:
    - hermes-qqbot
```

This is included in the default config — usually no action needed.

### Step 4: Start the gateway

```bash
# Test in foreground
hermes gateway run

# Or install as background service
hermes gateway install
hermes gateway start
hermes gateway status
```

## Testing

1. Open QQ and find your bot
2. Send a direct message — Hermes should respond
3. For group chats: add the bot to a group and @mention it
4. Check gateway logs:
   ```bash
   tail -f ~/.hermes/logs/gateway.log
   ```

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Bot disconnects immediately | Invalid App ID/Secret or missing intents | Double-check credentials at q.qq.com, verify intents enabled |
| Bot only works in sandbox | Bot not published | Publish from sandbox mode, or set `QQ_PORTAL_HOST=sandbox.q.qq.com` |
| Messages not delivered | DM/group policy too restrictive | Check `QQ_ALLOWED_USERS` / `QQ_GROUP_ALLOWED_USERS` |
| Voice messages not transcribed | STT provider not configured | Set `QQ_STT_API_KEY` or configure in `platforms.qqbot.extra.stt` |
| Connection errors | Network issue or missing deps | Verify `aiohttp` and `httpx` installed; check gateway logs |

## Voice (STT)

Two-stage voice transcription:
1. **QQ built-in ASR** — always tried first (free, uses Tencent's speech recognition)
2. **Configured STT provider** (fallback) — if QQ's ASR doesn't return text:
   - Zhipu/GLM (`zai`): default, uses `glm-asr` model
   - OpenAI Whisper: set `QQ_STT_BASE_URL` and `QQ_STT_MODEL`
   - Any OpenAI-compatible STT endpoint

## Config File Verification

Use Python YAML to inspect config programmatically:
```python
import yaml
with open('/home/qn/.hermes/config.yaml') as f:
    cfg = yaml.safe_load(f)
qq = cfg.get('platforms', {}).get('qqbot', {})
print('QQ Bot config:', qq)
```

To check env vars (may be redacted in terminal output):
```bash
grep "^QQ_" /home/qn/.hermes/.env | xxd
```
