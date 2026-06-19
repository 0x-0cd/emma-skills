---
name: chinese-content-research
description: "Research Chinese internet content — trending topics, tech news, social media posts, platform-specific data. Use web_extract on Chinese aggregator sites as primary method; web_search (DuckDuckGo/Brave) is unreliable for Chinese queries."
version: 1.1.0
author: Emma
tags: [chinese, research, web_extract, social-media, scraping, aggregators]
---

# Chinese Content Research

When researching Chinese internet content, **do not rely on `web_search`** — it uses DuckDuckGo/Brave backends that frequently time out on Chinese queries (especially through VPN). Use `web_extract` directly on reliable Chinese aggregator sites instead.

## Core Pattern

```
web_search (Chinese query) → ❌ timeout / garbage results
web_extract (known aggregator URL) → ✅ works reliably
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

## Pitfalls

- **web_search timeout loop**: `web_search` frequently times out on Chinese queries (DuckDuckGo/Brave backends struggle through VPN). After the **first** timeout on a Chinese query, immediately switch to `web_extract` on a known aggregator or official site. Do NOT retry 3+ times — you'll waste turns. If you must search, use short English queries (e.g. `"deepseek" "v4.1"`) rather than Chinese ones.\n- **web_search on English queries still works**: For Chinese-tech topics, search in English can sometimes succeed where Chinese queries fail. Use English query terms + "Chinese" / site filters as a fallback.
- **Fact-checking Chinese tech rumors**: Chinese tech aggregators (快科技, IT之家, 36氪) frequently repost forum/community posts as "news" with minimal verification. Trace every claim to its original source (Linux.do, Zhihu, etc.) before trusting it. The publication chain is usually: `forum post → tech blog → mainstream media repost`, each step adding credibility without adding verification.
- **GitHub clone through VPN**: HTTPS clone and archive downloads may fail while API (api.github.com) works. Use the API + raw.githubusercontent.com pattern.
- **Xiaohongshu posting is a dead end**: No public API. Don't attempt browser-automation posting — fragile and against ToS. Reading is fine.
- **tophub.today URLs**: The numeric ID in URLs (e.g., `/n/KqndgxeLl9`) is a stable identifier per topic list. Save the ones you need.
