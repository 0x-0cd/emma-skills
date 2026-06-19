---
name: paper-deep-dive
description: >-
  Deep analysis of academic papers with structured output: extract content,
  analyze figures, synthesize findings, and save to project knowledge base.
version: 1.0.0
author: Emma
metadata:
  hermes:
    tags: [research, paper-analysis, academic, literature-review, knowledge-integration]
    category: research
    related_skills: [arxiv, research-backed-validation]
---

# Paper Deep Dive

## When to Use

The user asks you to read a specific paper (arXiv, PDF, or other academic source)
and produce a comprehensive, structured analysis saved to the project's knowledge
base.

**Signals:**
- "看看这篇论文讲了啥"
- "分析下这篇论文"
- "把这篇论文拉下来看看"
- User provides an arXiv ID or paper URL and asks for analysis

**Not for:** quick abstract reading, claim validation (use `research-backed-validation`),
or paper search (use `arxiv`).

---

## Workflow

### Phase 1: Access the Paper

Try sources in **this order**:

| Priority | Source | Command | Best for |
|:--------:|--------|---------|----------|
| 1 | arXiv HTML | `web_extract(urls=["https://arxiv.org/html/IDv1"])` | **Richest** — preserves figure image URLs → can extract captions + download figures |
| 2 | arXiv PDF | `web_extract(urls=["https://arxiv.org/pdf/ID.pdf"])` | Good for text, loses figure positioning |
| 3 | Abstract page | `web_extract(urls=["https://arxiv.org/abs/ID"])` | Fast overview before deep dive |

HTML is strongly preferred because it embeds figure references (`<img src="IDv1/x1.png">`)
that you need for the figure analysis phase. PDF → text extraction loses these.

**⚠️ Long paper handling:** `web_extract` may truncate papers over ~5000 chars.
Check for truncation markers and supplement with partial extracts (section by section)
via curl + grep if needed.

### Phase 2: Extract Figure Metadata

After scraping the HTML version, extract all figure captions and image URLs:

```bash
curl -sL --proxy http://127.0.0.1:7890 "https://arxiv.org/html/PAPER_IDv1" | python3 -c "
import sys, re
html = sys.stdin.read()
figures = re.findall(r'<figure[^>]*>(.*?)</figure>', html, re.DOTALL)
for i, fig in enumerate(figures):
    img_src = re.search(r'<img[^>]*src=\"([^\"]+)\"', fig)
    caption = re.search(r'<figcaption[^>]*>(.*?)</figcaption>', fig, re.DOTALL)
    print(f'--- Figure {i+1} ---')
    if img_src: print(f'  Image: {img_src.group(1)}')
    if caption:
        text = re.sub(r'<[^>]+>', '', caption.group(1)).strip()
        text = re.sub(r'\s+', ' ', text)
        print(f'  Caption: {text[:500]}')
"
```

**Output tells you:**
- Which figures are main visuals (architecture diagrams, result plots, examples)
- What each figure shows (via its caption)
- Download URLs for `browser_vision` analysis

### Phase 3: Download Figures for Vision Analysis

When vision model access is available (Hermes config: `xiaomi/mimo-v2.5`):

```bash
mkdir -p /tmp/paper_figs
for f in x1 x2 x3 x4; do
    curl -sL --proxy http://127.0.0.1:7890 \
      "https://arxiv.org/html/PAPER_IDv1/${f}.png" \
      -o "/tmp/paper_figs/${f}.png"
done
```

Then use `browser_vision` for visual analysis. Ask specifically about:
- Architecture diagrams: "Describe the architecture flow and key components"
- Result plots: "What do the bars/lines represent? Which method wins? By how much?"
- Example figures: "What does this example demonstrate?"

**If browser/vision tools are unavailable**, rely on the extracted captions plus
the paper's textual descriptions of each figure (often in the body text).

### Phase 4: Synthesize Structured Analysis

Organise around this template:

```markdown
## 🎯 Core Problem & Motivation

[What gap does this paper address? Why does it matter? Quote the paper's
own framing if notable.]

## Key Idea / Method

[What's the core technical contribution? How does it work?]
[Include architecture description, pseudocode references, equations if relevant.]

### Architecture / Algorithm Details

[If applicable: how the components connect, training/inference flow,
key design choices with rationale.]

## Experimental Setup & Results

[What benchmarks? What metrics? Key numbers?]

### Main Results Table

| Benchmark | Baseline | Their Method | Δ |
|-----------|:--------:|:------------:|:-:|
| ... | ... | ... | ... |

[Any ablation studies or analysis experiments that reveal why it works.]

## 🌟 Implications for [Project Name]

[What does this mean for OUR project? Compare and contrast directly.]

| Dimension | Their Approach | Our Approach | Notes |
|-----------|---------------|--------------|-------|
| ... | ... | ... | ... |

### Key Takeaways
1. [What to adopt/adapt]
2. [What to avoid — pitfalls they reveal]
3. [Open questions for us]
```

### Phase 5: Save to Project Knowledge Base

The output file goes in the project's `docs/research/` directory:

```bash
# Naming convention: NN-topic-summary.md
# Where NN is the next available two-digit number
```

File format:
```markdown
# [Paper Title] — Analysis

> **Source:** arXiv:XXXX.XXXXX (Date)
> **Category:** cs.XX
> **Link:** https://arxiv.org/abs/XXXX.XXXXX

[Full structured analysis as above]

---

*Analysis date: YYYY-MM-DD*
*Figures saved: [path to downloaded figures]*
```

Then **update the index** (`docs/research/index.md`) with a new row:

```markdown
| NN-topic-summary | [Paper Title] Analysis | [One-line key finding] |
```

### Phase 6: Cross-Reference with Existing Knowledge

Before finalising, check whether this paper relates to existing research entries:
- Does it overlap with or extend an entry already in the index? Note the connection.
- Does it suggest changes to design docs or competitive landscape?
- If relevant, cross-link in the index comment column.

---

## Real-World Example (EvoArena 2606.13681)

This skill was created after analysing:
- `arXiv:2606.13681` (EvoArena + EvoMem, June 2026)
- Extracted: 4 main figures + 4 supplementary, analysed captions from HTML
- Saved: `docs/research/07-evoarena-evomem-analysis.md` (~7.2KB)
- Key finding: EvoMem uses patch-based memory, on LoCoMo only 43.0% with +4.8% gain
  — validates our Edge-first + Ebbinghaus approach has headroom

---

## Pitfalls

- **HTML vs PDF**: HTML version may not exist for very new or old papers.
  PDF extraction works but loses figure references — supplement with manual figure
  caption extraction from the abstract page.
- **Truncated content**: Large papers get summarised by web_extract (~5000 char cap).
  Detect by looking for truncation markers, then extract sections individually.
- **Captions ≠ full data**: Captions summarise. Combine with the paper's text body
  describing each figure. When vision tools are unavailable, state this limitation.
- **Version drift**: arXiv ID without `vN` resolves to the latest version, which
  may differ from the version you read. Pin `v1` or whatever version you analysed.
- **Withdrawn papers**: Check the abstract/summary for withdrawal/retraction notices
  before investing time in analysis.
- **Token limits**: Long papers may exceed model context. Extract section by section
  (intro → method → experiments → conclusion) in separate calls.
- **Proxy requirements**: On Chinese networks, HuggingFace/arXiv API calls need
  proxy (`http_proxy=http://127.0.0.1:7890`). Plain arXiv HTML/PDF via web_extract
  usually works without proxy if the tool backend has direct connectivity.

---

## Related Skills

- `research/arxiv` — Searching and fetching papers (precedes deep dive)
- `research/research-backed-validation` — Validating claims / investigating prior art
  (complementary — use when user has a hypothesis, not a specific paper)
- `research/youtube-content` — Analysing video content (different medium, similar
  synthesis structure)
