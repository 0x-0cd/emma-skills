---
name: chinese-content-research
description: "Research Chinese internet content — trending topics, tech news, social media posts, platform-specific data. Use web_extract on Chinese aggregator sites as primary method; web_search (DuckDuckGo/Brave) is unreliable for Chinese queries."
version: 1.2.0
author: Emma
tags: [chinese, research, web_extract, social-media, scraping, aggregators]
---

# Chinese Content Research

When researching Chinese internet content, there are three methods ranked by effectiveness. MiMo API search is the best for high-volume Chinese queries.

## Core Pattern — Three Methods

### Method 1 (BEST): MiMo API Web Search
When user says "用小米搜" or when high-volume/parallel Chinese search is needed:
```bash
# KEY LOCATION (2026-08-03 update): MiMo key now lives in ~/.hermes/auth.json under credential_pool.xiaomi[].access_token.
# The old ~/.hermes/.env XIAOMI_API_KEY is GONE — sourcing .env and grepping XIAOMI_API_KEY returns nothing/401.
# Reliable pattern: read key with python3 from auth.json (never print it), then call the API:
python3 << 'EOF'
import json, urllib.request
auth = json.load(open('/home/qn/.hermes/auth.json'))
key = next(c['access_token'] for c in auth['credential_pool'].get('xiaomi', []) if c.get('access_token'))
body = json.dumps({
    "model": "mimo-v2.5",
    "messages": [{"role": "user", "content": "搜索查询"}],
    "tools": [{"type": "web_search", "max_keyword": 5, "force_search": True, "limit": 8}]
}).encode()
req = urllib.request.Request("https://api.xiaomimimo.com/v1/chat/completions",
    data=body, headers={"Content-Type": "application/json", "api-key": key})
d = json.loads(urllib.request.urlopen(req, timeout=60).read())
msg = d["choices"][0]["message"]
print(msg.get("content", ""))
for a in msg.get("annotations", [])[:8]:
    print("*", a.get("title",""), "|", a.get("site_name",""), "|", a.get("publish_time",""))
    print("  ", (a.get("summary") or "")[:200]); print("  URL:", a.get("url",""))
EOF
```
- Returns structured `annotations` array: `{title, site_name, publish_time, summary, url}`
- Also returns curated `content` with numbered/organized news items
- **Zero timeout issues** on Chinese queries (unlike exa/tavily)
- Parallel bash background jobs: 15 simultaneous searches → 600+ raw → ~500 unique after dedup
- Cost: ¥16/千次 (mimo-v2.5 series only)
- **Pitfall: .env key access** — `grep`/`sed` on `~/.hermes/.env` returns truncated values due to hermes security masking. ALWAYS use `bash -c 'source ~/.hermes/.env; ...'` or write a script that sources it
- **Pitfall: subagents cannot use MiMo** — `delegate_task` subagents inherit wrong provider keys and get 401 errors. Do MiMo searches in `execute_code` or `terminal`, NOT via delegate_task

### Method 2: web_extract on Aggregator Sites
For targeted extraction from known reliable sites (see Aggregator Sites below).

### Method 3 (Fallback): web_search (DuckDuckGo/Brave)
```
web_search (Chinese query) → ❌ timeout / garbage results
```

## Aggregator Sites Quick Reference

### Trending & Social
| Site | URL | Covers |
|------|-----|--------|
| **Tophub** | `https://tophub.today/n/KqndgxeLl9` | 微博热搜榜 (real-time, 50 items, hotness scores) |
| Tophub Zhihu | `https://tophub.today/n/mproPpoq6O` | 知乎热榜 |
| Tophub Baidu | `https://tophub.today/n/Jb0vmloB1G` | 百度热榜 |

### Tech News
| Site | URL | Covers |
|------|-----|--------|
| **IT之家** | `https://www.ithome.com/` | 综合科技资讯 (业界/手机/AI/汽车/游戏)，带热榜+分类 |
| 36氪快讯 | `https://www.36kr.com/newsflashes` | 资本市场/科技产业/融资动态 |
| 驱动之家 | `https://news.mydrivers.com/` | 硬件/手机/系统 |
| 观察者网 | `https://user.guancha.cn/` | 科技+时政深度 |

### Social Media Platforms (direct extraction)
| Platform | Extractability | Notes |
|----------|---------------|-------|
| **小红书** | ✅ Public notes via `web_extract` on note URLs | Can see explore feed, individual notes. Posting NOT supported. |
| **微博** | ✅ Search results, posts | Weibo AJAX API often blocked; use tophub for trends |
| **知乎** | ⚠️ Partial | Some pages require login; tophub for trending |
| **抖音** | ❌ Hard | Requires browser automation (JS-heavy, anti-crawl) |

## GitHub API for Repo Discovery

When searching for Chinese open-source tools and git clone fails (VPN protocol issues with port 9418/22):

```bash
# Search via API (works over HTTPS, stable through VPN)
curl -s "https://api.github.com/search/repositories?q=<keywords>&sort=stars&order=desc&per_page=5" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); [print(f'⭐{r[\"stargazers_count\"]} | {r[\"full_name\"]}\n  {r[\"description\"]}\n  {r[\"html_url\"]}\n') for r in d.get('items',[])]"

# Read file contents without cloning
curl -sL "https://raw.githubusercontent.com/<owner>/<repo>/main/<path>"

# Get repo structure
curl -s "https://api.github.com/repos/<owner>/<repo>/contents/"
```

## Multi-Platform Scraping: MediaCrawler

[**NanmiCoder/MediaCrawler**](https://github.com/NanmiCoder/MediaCrawler) (51K+ ⭐) is the go-to open-source multi-platform Chinese social media scraper:

### Supported Platforms
| 小红书 | 抖音 | 快手 | B站 | 微博 | 贴吧 | 知乎 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|

All support: keyword search, post crawling, comments, creator homepage, IP proxy pool.

### Tech Stack
- Python + Playwright (CDP mode: connects to existing Chrome, reuses login state)
- Node.js required for 抖音/知乎 (JS encryption handling)
- WebUI at `localhost:8080`
- Output: CSV / JSON / Excel / SQLite / MySQL

### Raspberry Pi Compatibility
- **Memory**: Chrome/Chromium is the main hog (~500MB-1GB). Pi with 3.7GB RAM can run it if concurrency limited to 1-2 platforms.
- **Browser**: Install `chromium-browser` from apt (no official Google Chrome for aarch64).
- **CPU**: No ML/GPU workloads, Python is lightweight.
- **Storage**: SQLite local mode is fine for moderate volumes.

### Security Notes
- 51K stars = strong community scrutiny
- Dependencies are standard libraries (httpx, playwright, fastapi, pandas, etc.)
- `pyexecjs` is the highest-risk dep — it executes JS locally for platform signature handling. Audit this if supply-chain security is a concern.
- Disclaimer: for learning/research only; commercial use may violate platform ToS.
## Game Research: Terminology & Fact-Checking

When researching Chinese-localized games (幻兽帕鲁, 原神, etc.), follow these rules strictly:

### Rule 1: Never translate English game terms to Chinese yourself
Official Chinese game names are localized, not literal translations. For example:
- ❌ "Nitewing" → "迅猛鸟" (machine-translated)
- ✅ "Nitewing" → **疾风隼** (official Chinese name)
- ❌ "Eikthyrdeer" → "骑士鹿"
- ✅ "Eikthyrdeer" → **紫霞鹿**

Always verify Chinese names against authoritative game databases:
| Game | Authoritative Chinese DB | URL Pattern |
|------|------------------------|-------------|
| 幻兽帕鲁 | paldb.cc/cn | `https://paldb.cc/cn/<PalName>` |
| 幻兽帕鲁 | B站 Wiki | `https://wiki.biligame.com/palworld/<中文名>` |
| 幻兽帕鲁 | 萌娘百科 | `https://mzh.moegirl.org.cn/<中文名>` |
| 一般游戏 | 配种/图鉴计算器 | `palworldbreedingcalc.com/zh-CN/` |

### Rule 2: AI-generated gaming articles are rampant
Chinese gaming content sites (233乐园, 18183, 17173, etc.) are flooded with AI-generated articles that fabricate game mechanics and item names (e.g. "帕鲁茧" — an item that doesn't exist in 幻兽帕鲁). Cross-reference every specific claim (item names, mechanics, stats) against the authoritative DB above before presenting to the user.

### Rule 3: Build terminology tables proactively
When researching a Chinese-localized game for the first time in a session, build a Chinese↔English term mapping table from authoritative sources BEFORE diving into guides. Present it to the user for validation. This prevents downstream miscommunication.

## Pitfalls

### Web search & scraping
- **MiMo key location**: The xiaomi API key is in `~/.hermes/auth.json` → `credential_pool.xiaomi[].access_token` (as of 2026-08; the old `~/.hermes/.env` `XIAOMI_API_KEY` no longer exists — sourcing it yields nothing and API calls 401). Read the key with python3 from auth.json and never print it. Note hermes security masking also truncates keys shown via grep/sed on `.env` — always read credentials programmatically inside the script that uses them.
- **web_search timeout loop**: `web_search` frequently times out on Chinese queries (DuckDuckGo/Brave backends struggle through VPN). After the **first** timeout on a Chinese query, immediately switch to `web_extract` on a known aggregator or official site. Do NOT retry 3+ times — you'll waste turns. If you must search, use short English queries (e.g. `"deepseek" "v4.1"`) rather than Chinese ones.
- **web_search on English queries still works**: For Chinese-tech topics, search in English can sometimes succeed where Chinese queries fail. Use English query terms + "Chinese" / site filters as a fallback.
- **GitHub clone through VPN**: HTTPS clone and archive downloads may fail while API (api.github.com) works. Use the API + raw.githubusercontent.com pattern.
- **Xiaohongshu posting is a dead end**: No public API. Don't attempt browser-automation posting — fragile and against ToS. Reading is fine.
- **tophub.today URLs**: The numeric ID in URLs (e.g. `/n/KqndgxeLl9`) is a stable identifier per topic list. Save the ones you need.

### Fact-checking & verification
- **Fact-checking Chinese tech rumors**: Chinese tech aggregators (快科技, IT之家, 36氪) frequently repost forum/community posts as "news" with minimal verification. Trace every claim to its original source (Linux.do, Zhihu, etc.) before trusting it. The publication chain is usually: `forum post → tech blog → mainstream media repost`, each step adding credibility without adding verification.
- **AI-generated game articles are epidemic**: Sites like 233乐园, 18183, 17173 are flooded with AI-generated guides that fabricate game mechanics, item names, and stats. A fabricated item called "帕鲁茧" (doesn't exist in 幻兽帕鲁) was presented as fact in multiple articles. ALWAYS cross-reference specific claims (item names, boss mechanics, drop tables) against the authoritative DB (paldb.cc/cn) before telling the user. If you can't verify it, say "I'm not sure" — never present unverified game data as fact.
- **Never translate English game terms to Chinese yourself**: Official Chinese game names are localized, not literal translations. Machine-translating "Nitewing" to "迅猛鸟" or "Eikthyrdeer" to "骑士鹿" will produce wrong names that don't exist in-game. The user WILL notice and correct you. Always look up the official Chinese name from the authoritative DB first. See the Game Research section above for source URLs.
- **Build terminology tables proactively**: When researching a Chinese-localized game for the first time in a session, build a Chinese↔English term mapping table from authoritative sources BEFORE diving into guides. Present it to the user for validation. This prevents downstream miscommunication and shows you did the groundwork.
- **Distinguish similar game locations**: Games often have multiple locations with similar names (e.g. 油田要塞 vs 石油钻井平台 in 幻兽帕鲁 — one has a helicopter boss, the other doesn't). When the user describes confusion about game content, check whether they might be conflating different locations/mechanics before assuming their understanding is wrong.
