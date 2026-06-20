# Financial Report Search Template

## Use Case: Morgan Stanley "China Outlook Amid AI And Energy Super Cycle"

### Search Strategies Used (in order)

| # | Strategy | Query | Result |
|---|---|---|---|
| 1 | Exact title quoted + firm | `"China Outlook Amid AI And Energy Super Cycle" Morgan Stanley` | ❌ No match |
| 2 | Partial title + firm | `"China Outlook" "AI" "Energy Super Cycle" Morgan Stanley` | ❌ No match |
| 3 | Author + topic | `Chetan Ahya "China Outlook" AI energy super cycle` | ❌ No match |
| 4 | Site-specific | `site:morganstanley.com China AI energy super cycle outlook` | ✅ Found related reports (AI energy demand, midyear outlook) |
| 5 | Related-article citation hunting | Extract CTOL article citing MS → get source URLs | ✅ Found 3 referenced MS reports |
| 6 | Summit search | `"Morgan Stanley China Summit" AI energy super cycle` | ✅ Found MS China Summit 2026 coverage |
| 7 | PDF search | `Morgan Stanley China outlook AI energy super cycle filetype:pdf` | ❌ No PDF |
| 8 | Aggregator search | Various news sources citing the report | ⚠️ Partial - related content found |

### Verdict: Report not publicly accessible

The exact report title could not be located in public sources. Likely a client-only investor presentation or internal research note.

### Closest Publicly Available Alternatives Found

| Title | URL | Type |
|---|---|---|
| Energy Markets Race to Solve the AI Power Bottleneck | https://www.morganstanley.com/insights/articles/powering-ai-energy-market-outlook-2026 | Public article (Feb 2026) |
| Midyear Economic Outlook: AI Drives Resilient Growth | https://www.morganstanley.com/insights/articles/economic-outlook-midyear-2026 | Public article (2026) |
| 4 Ways the AI Supercycle Is Changing How Companies Operate | https://www.morganstanley.com/insights/articles/ai-supercycle-company-competition | Public article (Mar 2026) |
| India Market Outlook (Chetan Ahya podcast) | https://www.morganstanley.com/insights/podcasts/thoughts-on-the-market/india-market-outlook-2026-chetan-ahya-ridham-desai | Podcast (Jun 2026) |
| China Outlook: Qianlei Fan | https://www.morganstanley.com/insights/podcasts/thoughts-on-the-market-china-outlook | Podcast |

### Key Takeaway

When an investment bank report has an exact title but no public match, the most productive further step is to ask the user:
1. Where they saw the title referenced (news article? email alert? social media?)
2. Whether they need the full report or just the key findings
3. If they have a report code or date range
