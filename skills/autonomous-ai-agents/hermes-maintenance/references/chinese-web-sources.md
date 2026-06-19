# Chinese Internet Information Sources

When `web_search` (DuckDuckGo backend) times out — common on this ARM64 Pi behind GFW — fetch information directly from these known aggregators via `web_extract`. These URLs are stable and return structured content.

## Trending / Hot Search

| Source | URL | Coverage |
|--------|-----|----------|
| 微博热搜 (Tophub) | `https://tophub.today/n/KqndgxeLl9` | Weibo trending topics, 52 items, with heat index |
| Tophub 科技榜 | `https://tophub.today/n/5VaobgvDq1` | Tech trending (may 404, try base domain) |

## Tech News (中文科技资讯)

| Source | URL | Coverage |
|--------|-----|----------|
| IT之家 | `https://www.ithome.com/` | Comprehensive tech news: mobile, AI, auto, gaming, industry |
| 36氪快讯 | `https://www.36kr.com/newsflashes` | Startup/VC/tech industry flashes, capital markets |

IT之家 is the richest single source — its homepage summary captures headlines, daily/weekly/monthly rankings, and categorized板块 (AI, auto, phones, etc.).

## Reviews & Community Opinion

| Source | URL pattern | Usage |
|--------|-------------|-------|
| 知乎搜索 | `https://www.zhihu.com/search?type=content&q=<query>` | May fail on fetch; fall back to web_extract on specific article URLs |

## Search Fallback Pattern

When `web_search()` times out:
1. Identify the category (trending → tophub, tech news → IT之家/36氪, reviews → specific articles)
2. `web_extract(urls=[...])` with known aggregator URLs
3. If web_extract also fails, try `browser_navigate` + `browser_snapshot` as last resort

## Notes

- DuckDuckGo search via `web_search` is unreliable on this Pi environment (ConnectTimeout frequent)
- These direct URLs bypass search engines entirely — faster AND more reliable within GFW
- IT之家 and Tophub pages are LLM-summarized by web_extract when large, which is actually ideal for overviews
- For deep dives, extract specific article pages rather than search indexes
