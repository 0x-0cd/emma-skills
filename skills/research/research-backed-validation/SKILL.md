---
name: research-backed-validation
description: "Validate user claims/hypotheses or investigate prior art / patent landscapes for AI, ML, or tech concepts. Also supports patent filing feasibility analysis."
version: 1.3.0
author: Agent
created_by: agent
metadata:
  hermes:
    tags: [research, validation, literature-review, hypothesis-testing, evidence-analysis]
    category: research
    related_skills: [arxiv, web_search, web_extract]
---

# Research-Backed Validation

When the user expresses an intuition, claim, or hypothesis about AI/ML/tech — and you need to determine whether it's supported by real research — use this workflow.

## When to Use

- User says "I think X is true about AI/tech" and you need to verify with evidence
- User references a claim from an article/news/blog post and wants fact-checking
- User proposes a theory and you need to find supporting/contradictory academic literature
- User asks "is there any research on [topic]?" — go beyond just searching; evaluate and synthesize

## Workflow

### Phase 1: Understand & Scope

Make sure you understand the user's claim precisely before searching:

- What is the *core claim* being made? (one sentence)
- What kind of evidence would support or refute it? (academic papers, industry reports, news articles)
- What domain does it belong to? (LLM reasoning, robotics, theory, engineering...)

### Phase 2: Multi-Source Research

**Do NOT rely on a single search.** Run 3-5 targeted searches from different angles:

```
Round 1: Direct connection  — "user's exact topic + key terms"
Round 2: Adjacent research  — "broader field + related concept"
Round 3: Counter-evidence   — "opposing view / limitations / no free lunch"
Round 4: News/industry      — "latest developments + companies working on it"
Round 5: Deep dive          — "specific paper name / author + key finding"
```

**Research sources (prefer in this order):**
1. Academic papers (arXiv, Semantic Scholar, Nature, NeurIPS, ICML, ICLR, CVPR, etc.)
2. Official company blogs or announcements (Google DeepMind blog, Anthropic, OpenAI, Meta AI)
3. Reputable tech news with original reporting (not reblogged summaries)
4. Verified Wikipedia entries (for established concepts)
5. Conference proceedings/papers lists

**Avoid:**
- Medium posts without citations
- Unsubstantiated LinkedIn or Twitter posts
- AI-generated content summarizing AI content (recursive dilution)

### Phase 3: Map Evidence to Claim

For each piece of evidence, ask:
- Does it **support** the claim, **contradict** it, or is it **neutral**?
- Is it **theoretical** (model, proof, framework) or **empirical** (experiment results, benchmarks)?
- Is it **recent** (within 1-2 years) or **classic** (foundational but possibly outdated)?
- Is the **conclusion qualified** (with caveats/limitations) or **absolute**?

### Phase 4: Structure the Answer

Use this template for long-form analyses:

```
## 🔍 Context
[What the user said, what prompted the question]

## Evidence Chain
[Organize findings — strongest evidence first, supporting then contradictory]

## ⚡ Current State
[Table or structured comparison: what's proven vs what's aspirational vs what's disproven]

## 🎯 Verdict
[Clear final judgment: Supported / Partially Supported / Not Supported / Too Early To Tell]
[With specific caveats and nuance]
```

For shorter answers, adapt the template but always include the verdict.

### Phase 5: Include Caveats

Every research-backed answer needs a "but" section:
- Limitations of the studies cited
- Time sensitivity (research moves fast)
- Differences between the user's specific context and general findings
- Information-theoretic bounds (e.g., No Free Lunch papers for self-improvement)

## Pitfalls

- **Confirmation bias**: Don't just find evidence that supports the user's intuition. Actively search for counterarguments, limitations, and "no free lunch" papers.
- **Single source fallacy**: One paper ≠ established truth. Multiple independent sources converging = signal.
- **Dated evidence**: Papers from 2023 about LLMs are ancient history in 2026. Prefer 2025-2026 for rapidly moving fields.
- **Overclaiming**: Don't say "research proves X" when the paper actually says "X shows promise under constrained conditions." Be faithful to the paper's own caveats.
- **Narrative collapse**: Don't just list papers — synthesize. What does the *body of evidence* collectively say?
- **Precision mismatch**: If the user says "AI can improve itself" but the papers say "models can self-play within a narrow domain," call out the mismatch explicitly.

## Variant: Tech Rumor / News Article Fact-Checking

When the user asks you to **verify a tech news article, rumor, or leak** — distinct from validating a scientific claim — use this workflow.

### What's Different from Claim Validation

| Claim Validation | Tech Rumor Fact-Checking |
|---|---|
| User has a hypothesis → find evidence | User found a claim online → verify authenticity |
| Output: verdict (supported/refuted) | Output: truth assessment + source chain analysis |
| Academic papers are primary evidence | Official channels + API data + repos are primary |
| Evidence quality matters most | Source credibility + chain of custody matter |

### Phase 1: Read & Deconstruct the Article

Extract the **core factual claims** from the article, not the speculation:

- What **specific, verifiable facts** does it assert? (e.g., "V4.1 is in grayscale testing", "knowledge cutoff updated to 2026.1")
- Who is the **original source**? (not the republisher — trace back: forum post → tech blog → mainstream media)
- Does the article cite **named individuals** or anonymous "some netizens"?

**Source chain signal:** If the chain is `forum user post → tech aggregator → mainstream media repost` with no original reporting, treat as high-risk.

### Phase 2: Concrete Verifications (API/Repo/Endpoint Checks)

For tech product rumors, check the **authoritative sources** directly:

1. **Public API model list** — Hit the `/v1/models` endpoint of the provider; absence = strong signal
2. **Official docs / changelogs** — Check for any announcement
3. **HuggingFace / GitHub** — Check for new model weights or branches
4. **Third-party model providers** — Check OpenRouter, OpenCode Go, etc. for new model entries
5. **Known API compatibility** — Try calling the purported new model name via API (it will either work, return a clear error, or auth-fail — all informative)

Each check is a **concrete data point** — don't rely solely on web search.

### Phase 3: Source Credibility Analysis

Assess each link in the publication chain:

| Source Level | Signal | Examples |
|---|---|---|
| **Original** (forum/social) | Low — single user, unverified | Linux.do, Reddit, Twitter/X |
| **Aggregator** (tech blog) | Medium — repackages with editorial filter | 快科技, IT之家, 36氪 |
| **Mainstream repost** | Varied — distribution, not reporting | 新浪财经, 搜狐, 腾讯新闻 |

**Key questions:**
- Does the original source have a track record of accurate leaks?
- Does the aggregator attribute correctly or add their own spin?
- Has the company officially denied or warned about rumors? (DeepSeek's V4 announcement explicitly did this)

### Phase 4: Absence-of-Evidence Reasoning

In rumor verification, **the absence of evidence IS evidence** — within limits:

| If official source | Then |
|---|---|
| Has NOT announced anything | 🚩 Rumor unconfirmed |
| Has explicitly warned about misinformation | 🚩🚩 Strong signal rumor is false |
| Has a known release cycle/history | Compare: does timeline make sense? |
| Shows contradictory signals (diff users see diff results) | 🚩 Likely noise/hallucination, not A/B test |

### Phase 5: Structured Verdict

```
## 📰 Source Chain
[original → aggregator → republisher, with credibility assessment]

## 🔍 What Was Claimed
[bullet points: specific verifiable claims extracted from article]

## ✅ What I Found
[for each claim: evidence for, evidence against, or inconclusive]

## 🏁 Verdict
[True / Likely True / Too Early To Tell / Likely False / False]

## 💡 Why
[one-paragraph reasoning summary]
```

### Pitfalls

- **Single-source trap**: One forum user's anecdote is NOT evidence. Require multiple independent reports.
- **Self-referential rumor**: The article says "there are rumors" and the only source is the article itself. Check the original citation.
- **Screenshot skepticism**: Screenshots in articles are trivially faked or cherry-picked. Look for reproducible steps.
- **Knowledge cutoff ≠ new model**: A model's self-reported knowledge cutoff can shift due to prompt sensitivity or hallucination — not necessarily a new version.
- **Tech blog amplification**: 快科技, 36氪, and similar Chinese tech aggregators often repost forum rumors as "news" with thin verification. Always trace to the original post.

## Variant: Patent / Prior Art Landscape Research

When the user asks to **explore patent filing opportunities** or **map the prior art landscape** for a technology concept — distinct from validating a specific claim — use this separate workflow.

### What's Different from Claim Validation

| Claim Validation | Patent Landscape Research |
|---|---|
| User has a hypothesis → find evidence | User has an invention concept → find what's already out there |
| Output: verdict (supported/refuted) | Output: landscape map (who owns what, gaps, feasibility) |
| Evidence quality matters most | Claim scope and legal strategy matter |
| One "truth" answer | Multi-dimensional assessment (tech + legal + timing) |

### Phase 1: Decompose the Concept
Break the idea into **component concepts** — e.g., for "cloud+edge agent memory": (a) AI agent memory persistence, (b) edge computing privacy, (c) cloud-side knowledge graph, (d) hierarchical storage classification, (e) cross-device sync protocol. Each component is a separate search thread.

### Phase 2: Multi-Angle Search (6+ rounds)
Search from distinct angles — do NOT collapse into one search:

```
Round 1: Industry products   — "existing systems closest to concept"
Round 2: Academic papers     — arXiv, Semantic Scholar, ACL, NeurIPS
Round 3: Existing patents    — Google Patents, USPTO, WIPO PATENTSCOPE
Round 4: Prior art products  — competitors, open-source, startups (funding rounds = signal)
Round 5: Adjacent domains    — neighboring fields that solved similar problems
Round 6: Legal landscape     — USPTO guidance, Alice test trends, CNIPA trends
```

**Search query patterns (adapt per round):**
```
"agent memory" "cloud" "edge" privacy hierarchical
patent AI agent "long-term memory" "cross-device"
arxiv "memory-augmented" "agent" "federated" personalization
"personal AI" memory architecture "on-device" privacy
```

### Phase 3: Three-Dimensional Gap Analysis
For each component, assess:

| Dimension | Question to answer |
|---|---|
| **Product saturation** | How many commercial solutions exist? Any well-funded? |
| **Academic coverage** | How many papers directly address this? Any surveys? |
| **Patent thicket** | How many granted patents? Who holds them? Recent filings? |

Then produce a **novelty heatmap**:
- 🟢 **Green** (no prior art found — potentially novel)
- 🟡 **Yellow** (adjacent prior art exists but doesn't directly overlap)
- 🔴 **Red** (well-covered, obvious combination risk)

### Phase 4: Legal Feasibility Assessment
Research the patent jurisdiction landscape:

- **USPTO**: Check latest §101/AI guidance. Alice test trends. Federal Circuit grant rate (2024: ~4.5% for software at Fed Circuit). Must frame as "technical improvement to computing system" not "AI algorithm."
- **CNIPA** (China): Generally more permissive for AI/software. Consider dual filing strategy.
- **EPO**: Requires "technical effect." Memory management can be technical when tied to hardware.
- **Strategy tips** (per 2025 patent counsel analysis):
  1. Frame as technical improvement to distributed system, not AI
  2. Emphasize concrete mechanism (how data is classified, routed, synced), not the high-level idea
  3. Include hardware references (edge SoC, cloud server, sync protocol)
  4. Provide performance benchmarks if available
  5. Draft multiple claim tiers including at least one very narrow claim
  6. Write "Statement of Technical Improvement" explicitly in the spec

### Phase 5: Synthesize Report
Structure the final answer with:

```
## 🏭 Existing Products
[Table: product, key features, gap vs your concept]

## 📄 Academic Papers
[Table: paper, year, relevance score, key contribution, gap]

## 📜 Patent Landscape
[Notable filings, assignees, claim scope, status]

## 🎯 Novelty Assessment
[Component-by-component heatmap + overall assessment]

## ⚖️ Filing Strategy
[Recommended jurisdiction, claim focus, risk factors]
```

### Pitfalls

- **Prior art illusion**: Just because no product exactly matches your concept doesn't mean it's novel — the *components* may all be obvious in combination. Focus on the specific *mechanism*.
- **Google Patents blind spot**: Google Patents indexes broad but misses many Chinese and Korean filings. Use WIPO PATENTSCOPE for international coverage.
- **Dead patents**: An expired or abandoned patent is still prior art. Check legal status.
- **Startup ≠ prior art**: Startup products without published patents or papers are weak prior art for patent examination (they need to be *enabled* public disclosures).
- **Temporal urgency**: AI agent memory is moving fast. What's novel today may be crowded in 6 months.
- **Alice/§101 trap**: Even if prior art search is clean, the patent office may reject on subject matter eligibility grounds. Plan claims to survive Alice step 2B.

## Variant: Financial / Investor Research Report Discovery

When the user asks to **find a specific investment bank report, investor presentation, or financial research note** — distinct from academic papers or news articles — use this workflow.

### What's Different from Claim Validation

| Claim Validation | Financial Report Discovery |
|---|---|
| User has a hypothesis → find evidence | User knows a report exists → locate it |
| Output: verdict (supported/refuted) | Output: report URL, PDF, or closest available public equivalent |
| Academic papers are primary evidence | Investment bank portals + news citations + SEC filings are primary |
| Search for concepts | Search for specific titles, codes, or authors |

### Phase 1: Understand What You're Looking For

Clarify the target before searching:
- **Exact title** vs approximate title?
- **Is it a published report** (widely distributed) or **investor deck** (internal/client-only)?
- **Which bank/firm?** Morgan Stanley, Goldman Sachs, JP Morgan, etc.
- **Which analyst/team?** (e.g., Chetan Ahya, Jonathan Garner, etc.)
- **Is it a research note, a podcast transcript, a slide deck, or a full report PDF?**
- **Approximate date?** Recent (weeks) vs archived (months/years)

Knowing these helps calibrate expectations — client-only materials are unlikely to appear in public search results.

### Phase 2: Multi-Strategy Search (run 5-8 angles)

Do NOT stop after one search. Run these in sequence until you find a hit or exhaust reasonable options:

```
Strategy 1: Exact title (quoted) + firm name
  "China Outlook Amid AI And Energy Super Cycle" Morgan Stanley

Strategy 2: Author/economist name + topic keywords
  Chetan Ahya China AI energy super cycle

Strategy 3: Author name + report type
  "Chetan Ahya" "investor" presentation OR report OR outlook

Strategy 4: Site-specific on the firm's website
  site:morganstanley.com China AI energy super cycle
  site:goldmansachs.com China outlook AI

Strategy 5: Related-article citation hunting
  Find articles that *cite* or *quote* the report → extract the original source URL
  Search: "Morgan Stanley" "called it" "Asia" "super-cycle"

Strategy 6: Conference/summit name + presentation title
  "Morgan Stanley China Summit" AI energy presentation

Strategy 7: Filetype search for PDF/slides
  "China outlook" "AI" filetype:pdf site:morganstanley.com

Strategy 8: Alternative language searches
  Some Chinese reports have different English marketing titles vs internal titles
```

### Phase 3: When the Report Isn't Public

Most investment bank research is **client-only** (behind advisor login). If you can't find it:

1. **State clearly** that it's not publicly accessible — don't fabricate a URL
2. **Offer the closest publicly available alternatives** from the same firm/analyst on the same topic
3. **Check if there's a public summary** — investment banks often publish blog posts or podcast transcripts that summarize their research
4. **Ask for more context** — exact date, how the user heard about it (news article citation? email?), report code if any

### Phase 4: Structured Answer Template

```
## 🏦 Target Report
[Exact title / estimated title / firm / analyst]

## 🔍 Search Approach
[Which strategies were tried]

## ✅ Public Availability
[Found / Not Found Publicly — explain why if client-only]

## 📄 Closest Available Content
[If not found: table of related publicly available reports from same firm with URLs]

## 💡 Next Steps
[If not found: what additional context would help]
```

### Pitfalls

- **Paywall ≠ non-existent**: Client-only reports exist — they're just gated. Don't incorrectly tell the user "this report doesn't exist."
- **Title drift**: The same report may be called different things on different platforms. The article headline, the database listing, and the internal title may differ. Cast a wider net.
- **Reporter paraphrase**: News articles often paraphrase a report's title in their own words. The citation in a news article may not use the original title.
- **Confidence inflation**: "Report titled X from Y" with a URL that actually goes to a landing page ≠ having found the report. Verify you've actually located the document, not a generic reference to it.
- **Multiple versions**: A "report" may exist as a full PDF, a slide deck, a podcast, and a one-page summary — each with a different title. Treat them as separate targets.

## Related Skills

- `research/arxiv` — for fetching and parsing arXiv papers
- `research/research-paper-writing` — for writing academic papers (complementary, downstream)
- `software-development/spike` — for experimental validation (code-level, not research-level)

## Reference Files

This skill's `references/` directory stores session-specific research findings as condensed knowledge banks — paper summaries, source URLs, key quotes, domain notes, and search templates.

### Available Reference Files

- `references/ai-self-improvement-theory-validation.md` — AI self-improvement theory validation
- `references/ai-agent-memory-patent-landscape-2026.md` — Agent memory patent landscape
- `references/financial-report-search-template.md` — Template: financial report search strategies with concrete examples (added 2026-06)
