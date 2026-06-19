---
name: media-crawler-pipeline
description: "Set up, configure, and run MediaCrawler (NanmiCoder) for multi-platform Chinese content collection on Linux/ARM64, with post-processing and analysis."
version: 1.0.0
author: Emma
tags: [media-crawler, xiaohongshu, data-collection, content-research, arm64, raspberry-pi]
---

# MediaCrawler Content Collection Pipeline

Set up and run [MediaCrawler](https://github.com/NanmiCoder/MediaCrawler) for collecting public content from Chinese platforms (小红书, 抖音, B站, 微博, 知乎, etc.) on headless ARM64 Linux (Raspberry Pi), then analyze and turn data into insights.

## When to use

- User wants to collect public content from Chinese social platforms
- User wants to research trends, topics, or competitor content on Xiaohongshu / Bilibili / Weibo
- User wants to turn collected data into analysis or content

## Setup on ARM64 Linux

See `references/setup-arm64.md` for full step-by-step.

### Quick start

```bash
# 1. Clone repo
git clone https://github.com/NanmiCoder/MediaCrawler.git ~/MediaCrawler

# 2. Install system deps for venv
sudo apt install -y python3.12-venv

# 3. Create venv + install deps (use Tsinghua mirror in China)
cd ~/MediaCrawler
python3 -m venv .venv
source .venv/bin/activate
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt

# 4. Install Chromium for Playwright
playwright install chromium
```

### Configuration

Edit `config/base_config.py`:

```python
PLATFORM = "xhs"           # xhs | dy | ks | bili | wb | tieba | zhihu
LOGIN_TYPE = "cookie"       # qrcode | phone | cookie (headless → cookie)
HEADLESS = True             # Pi has no display
ENABLE_CDP_MODE = False     # No desktop browser to connect to
SAVE_DATA_OPTION = "jsonl"  # Easy to post-process
CRAWLER_MAX_NOTES_COUNT = 20
CRAWLER_MAX_COMMENTS_COUNT_SINGLENOTES = 20
ENABLE_IP_PROXY = False     # Chinese platforms → direct connection
```

### Proxy strategy

- **Install deps / download Chromium**: use proxy (GitHub/Azure CDN blocked in China)
- **Runtime collection**: NO proxy (Chinese platform APIs are domestic)
- **Email sending**: use proxy (Gmail SMTP blocked in China)

```bash
# Download with proxy
export http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890
pip install -r requirements.txt

# Run unproxied
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
.venv/bin/python3 main.py
```

### Cookie login (headless)

On a headless Pi, use `LOGIN_TYPE = "cookie"`:
1. On a desktop machine, log into the platform in browser
2. Open DevTools → Application → Cookies → find the session cookie
3. Only `web_session` is needed (for 小红书)
4. Set in config: `COOKIES = "web_session=<value>"`
5. The crawler saves login state to `browser_data/` for reuse

**Cookie expiry**: Xiaohongshu `web_session` expires periodically. When login fails, replace the COOKIES value with a fresh one from the browser.

### Session/cookie rotation (avoid account ban)

⚠️ **"换 session" in MediaCrawler context = rotate the cookie value in `base_config.py`**, NOT switch the Hermes agent session.

To avoid getting rate-limited or banned during long collection campaigns:
1. Get a fresh `web_session` cookie from a desktop browser login
2. Edit `config/base_config.py` — find `COOKIES = "web_session=..."` and replace with the new value
3. Clear cached browser state: `rm -rf ~/MediaCrawler/browser_data/`
4. Run again with the fresh session

Keep a few cookie values handy and rotate periodically.

## xhshow compatibility fix

MediaCrawler's `playwright_sign.py` monkey-patches the `xhshow` library. Version 0.2.0 added `hex_md5_path` parameter to `build_payload_array`. The patch didn't account for this.

See `references/xhshow-compat.md`. Apply after pip install.

### xhshow patch: quick reference

Two changes in `media_platform/xhs/playwright_sign.py`:

1. **Patch function signature** (~line 50) — add `hex_md5_path` parameter
2. **GET path call** (~line 151) — pass `d_value` as `hex_md5_path`

See `references/xhshow-compat.md` for the full details.

## Running

```bash
cd ~/MediaCrawler
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
.venv/bin/python3 main.py
```

Output lands in `data/<platform>/jsonl/` as JSONL:
- `search_contents_<date>.jsonl` — note/post data
- `search_comments_<date>.jsonl` — comment data

## Post-processing & Analysis

See `references/analysis-pattern.md` for a comprehensive analysis workflow (filtering by date, sorting by hotness, noise removal, theme detection, word frequency).

### Quick stats
```bash
wc -l data/xhs/jsonl/*.jsonl
head -1 data/xhs/jsonl/search_contents_*.jsonl | python3 -m json.tool
```

### Python analysis
JSONL is line-delimited JSON. Load with:
```python
import json
notes = [json.loads(line) for line in open(path) if line.strip()]
```

Key fields in notes: `title`, `desc`, `liked_count`, `collected_count`, `comment_count`, `time` (ms epoch), `nickname`, `tag_list`, `note_url`

Key fields in comments: `note_id`, `content`, `like_count`, `ip_location`, `nickname`, `create_time`

### Filtering noisy comments
Filter out纯情绪/无内容评论 by length (< 5 chars), known noise keywords, emoji-only content.

### Sorting & time filtering
- Sort notes by `liked_count` for hotness
- Filter by `time` (ms epoch) for date range (e.g., last month)

## Content creation pipeline

After collecting data:
1. Extract insights from notes + quality comments
2. Write draft content
3. Apply humanizer skill for de-AI-ification
4. Generate supporting images (Python/matplotlib with Chinese font)
5. Format for target platform (小红书 markdown, etc.)

## Platforms

| Code | Platform | Notes |
|------|----------|-------|
| `xhs` | 小红书 | Requires cookie login |
| `dy` | 抖音 | Requires cookie/mobile login |
| `ks` | 快手 | Requires cookie login |
| `bili` | B站 | Public search works without login |
| `wb` | 微博 | Public search works without login |
| `tieba` | 贴吧 | Mostly public |
| `zhihu` | 知乎 | Mostly public |

## Pitfalls

- **输出太大超时**：MediaCrawler 日志输出巨大，用 `tail -N` 或重定向到文件
- **JSONL 解析**：每行一个完整 JSON 对象，别用 `json.loads` 读整个文件
- **内存**：Chromium 吃 ~300MB，Python 进程 ~100MB，Pi 上同时跑不超过 2 个平台
- **Cookie 过期**：小红书 web_session 有时效，过期后重新抓取

## See also

- `chinese-content-research` — broader Chinese content research skill
- `humanizer` — de-AI text processing
- `himalaya` — email delivery with attachments (MML format)
