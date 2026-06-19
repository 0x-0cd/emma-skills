# xhshow v0.2.0 Compatibility Fix

## Problem

MediaCrawler's `media_platform/xhs/playwright_sign.py` monkey-patches `xhshow.core.crypto.CryptoProcessor.build_payload_array` to fix GET request a3_hash computation. 

xhshow v0.2.0 added a new parameter `hex_md5_path` to `build_payload_array`, shifting the parameter positions. The monkey-patch was written for an older version without this parameter.

### Error signature

```
TypeError: _patch_xhshow_a3_hash.<locals>._patched_build() got multiple values for argument 'sign_state'
```

Followed by (if partially patched):
```
AttributeError: 'float' object has no attribute 'encode'
```

## Fix: Two changes in `playwright_sign.py`

### Fix 1: Update monkey-patch signature

In `_patch_xhshow_a3_hash()`, add `hex_md5_path` parameter:

```python
# OLD (broken with v0.2.0):
def _patched_build(self, hex_parameter, a1_value, app_identifier="xhs-pc-web",
                   string_param="", timestamp=None, sign_state=None):
    payload = _original_build(self, hex_parameter, a1_value, app_identifier,
                              string_param, timestamp, sign_state)

# NEW (v0.2.0 compatible):
def _patched_build(self, hex_parameter, hex_md5_path, a1_value, app_identifier="xhs-pc-web",
                   string_param="", timestamp=None, sign_state=None):
    payload = _original_build(self, hex_parameter, hex_md5_path, a1_value, app_identifier,
                              string_param, timestamp, sign_state)
```

### Fix 2: Update GET request call site

In `sign_with_xhshow()`, the GET path calls `build_payload_array` with positional args. Add the missing `hex_md5_path` parameter:

```python
# OLD (5 positional args, missing hex_md5_path):
payload_array = xhshow_client.crypto_processor.build_payload_array(
    d_value, a1_value, "xhs-pc-web", content_string, ts
)

# NEW (6 positional args, v0.2.0 compatible):
payload_array = xhshow_client.crypto_processor.build_payload_array(
    d_value, d_value, a1_value, "xhs-pc-web", content_string, ts
)
```

Pass `d_value` (same as `hex_parameter`) for `hex_md5_path` since the monkey-patch overrides the a3_hash for GET requests anyway.

## Verification

Run a comment crawl (GET path):
```bash
cd ~/MediaCrawler
.venv/bin/python3 main.py
```

Check that comments appear in `data/xhs/jsonl/search_comments_*.jsonl`.
