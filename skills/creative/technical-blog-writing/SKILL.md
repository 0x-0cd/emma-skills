---
name: technical-blog-writing
description: "Use when writing or planning a technical blog post. Covers research, structure templates (tutorial/deep-dive/postmortem/benchmark/architecture), code standards, humanization, Hugo/PaperMod publishing with search verification."
version: 1.0.0
author: Emma
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [blog, writing, technical-content, publishing, hugo, papermod]
    related_skills: [humanizer, book-reading-guide]
---

# Technical Blog Writing

Write developer-focused blog posts end-to-end: from research and drafting through humanization and publishing.

## When to Use

- User says "write a blog post", "publish an article", "分享经验"
- User wants to document a project, tool, or workflow
- User asks to "发一篇博文" or "写个技术分享"
- User provides a topic but no structure

**Don't use for:** User writing their own post and only asking for review (use `requesting-code-review` instead).

## Workflow Overview

```
Research → Draft → Humanize → Review → Publish → Verify
```

---

## Phase 1: Pre-writing & Research

Before writing a single line:

1. **Search the web** for similar articles — know what's already out there so you don't repeat
2. **Gather real data** from the user's environment:
   - Hardware specs (CPU, RAM, storage, OS, uptime, temperature)
   - Software versions (Python, Node, Hermes, Hugo, etc.)
   - Screenshots or logs when relevant
3. **Choose a post type** (see Phase 2)
4. **Outline the structure** before drafting — get user buy-in on the outline if the post is long

---

## Phase 2: Post Type Selection

Choose the structure that fits the topic:

### 1. Tutorial / How-To
Step-by-step, reader builds something.
```
Structure:
1. End result first (grab attention)
2. Prerequisites (explicit list, version numbers)
3. Steps with code blocks (every block runnable)
4. Complete code repo link
5. Next steps / extensions
```
Rules: Every code block must be copy-paste-runnable. Explain WHY not just HOW.

### 2. Deep Dive / Explainer
Explain a concept, technology, or decision.
```
Structure:
1. What it is and why care
2. Simplified mental model
3. Detailed mechanics
4. Real-world example
5. Trade-offs and when NOT to use it
6. Further reading
```

### 3. Postmortem / Incident Report
What went wrong and how it was fixed.
```
Structure:
1. Summary (impact, duration)
2. Timeline
3. Root cause analysis
4. Fix implemented
5. Prevention plan
6. Lessons learned
```

### 4. Benchmark / Comparison
Data-driven tool/approach comparison.
```
Structure:
1. What compared and why
2. Reproducible methodology
3. Results (tables/charts)
4. Analysis (what numbers mean)
5. Recommendation with caveats
```

### 5. Architecture / System Design
How a system is built.
```
Structure:
1. Problem to solve
2. Constraints & requirements
3. Options considered
4. Chosen architecture (diagram)
5. Trade-offs accepted
6. Results & lessons
```

### Word Count Guide

| Type | Length |
|------|--------|
| Quick Tip | 500-800 words |
| Tutorial | 1,500-3,000 |
| Deep Dive | 2,000-4,000 |
| Architecture | 2,000-3,500 |
| Benchmark | 1,500-2,500 |

### Audience Signaling

State the assumed reader level in the first paragraph:

> "This post assumes familiarity with Docker and basic Kubernetes concepts."

| Signal | Depth |
|--------|-------|
| "Getting started with X" | Explain everything |
| "Advanced X patterns" | Skip basics, go deep |
| "How we built X" | Technical audience, skip fundamentals |

---

## Phase 3: Drafting

### Article Template

```markdown
# Title (state outcome, include keywords)

> **太长不看版：** 2-3 句话概括全文。使用中文"太长不看版"，不用英文 TL;DR。
> 用 blockquote (`>`) 格式包裹摘要，使其在页面上更醒目。

## The Problem / Why This Matters
## How We Did It / The Solution
### Step 1: First thing (explanation + code + output)
## Results (specific numbers, outcomes)
## Trade-offs & Limitations (honest → builds trust)
## Conclusion (key takeaway + next steps)
```

> **为什么用"太长不看版"而不是 TL;DR？**
> 中文博客读者不一定熟悉 TL;DR 这个缩写。用中文"太长不看版"更友好。
> 放在 blockquote 中既美观又醒目标识这不是正文。

### Writing Rules

**Do:**
- Be direct: "Use connection pooling" not "you might want to consider using..."
- Admit trade-offs: "This adds complexity" not "our solution is perfect"
- Use specific numbers: "reduced p99 from 800ms to 90ms"
- Cite sources and benchmarks
- Acknowledge alternatives
- **Chinese-first localization** — use Chinese idioms and abbreviations ("太长不看版" not TL;DR, "比如" not "e.g.", "即" not "i.e."). Only keep English terms for proper nouns or untranslatable technical jargon

**Don't:**
- "In today's fast-paced world of technology..." (filler)
- "Simply do X" (nothing is simple for a reader)
- "Obviously..." / "As we all know..." (dismissive)
- Bury the lede under 3 paragraphs of context
- Marketing language in technical content
- Use "significantly improved" without numbers
- **Off-topic digressions** — every paragraph must serve the article's thesis. If content could be its own separate post, cut it
- **Unverified cost claims** — never write "免费" or "free" without confirming. If a tool is paid, say "paid" not "free"
- **Repetitive content** — merge repeated points between sections. Compress before publishing

### Code Block Standards

```
```python
# One-line explanation of what this does
def function_name(param: type) -> return_type:
    \"\"\"Docstring.\"\"\"
    return result
```
```

Rules:
- Every code block must have a language identifier
- Show output/result after code
- Use realistic variable names (`calculate_total` not `foo`)
- Include error handling in examples
- Pin dependency versions where relevant

---

## Phase 4: Humanization

After drafting, load the `humanizer` skill and do a full pass:

1. Scan for AI tells: em dash overuse, bold overuse, rule-of-three, signposting ("Let's dive in"), filler phrases, "值得注意的是"
2. Remove chatbot artifacts: "I hope this helps!", "Let me know if..."
3. Vary sentence rhythm — mix short and long sentences
4. Add personality: opinions, first-person ("I"), specific reactions
5. Check for generic conclusions — replace with specific ones
6. Remove hedging: "might potentially possibly" → direct statement
7. Check for copula avoidance: "serves as" → "is", "boasts" → "has"

Then do a final self-audit: "What makes this sound like AI wrote it?" Fix the remaining tells.

---

## Phase 5: Review & Publish

1. **Save as draft** — set `draft: true` in the Hugo frontmatter
2. **Present to user** — ask for feedback before publishing
3. **Apply revisions** based on user feedback
4. **Set `draft: false`** when approved
5. **Commit and push** to GitHub
6. **Wait for workflow** to complete (GitHub Actions)

---

## Phase 6: Post-Publish Verification

After deployment:

1. **Verify HTTP 200** on the article URL
2. **Check article title** renders correctly in `<title>`
3. **Verify search index** — `curl https://domain/index.json` should contain the new article
4. If search isn't working, check:
   - `outputs.home` includes `JSON` in hugo.yaml
   - `content/search.md` exists with `layout: "search"`
   - The `index.json` file is generated and non-empty
5. **Check the listing page** (`/posts/` or equivalent) shows the new article

---

## Common Pitfalls

1. **Skipping research** — writing without knowing existing content leads to redundant or inaccurate posts
2. **No humanization pass** — readers can tell when AI wrote it; always run humanizer
3. **Publishing without review** — always let the user review drafts first
4. **Forgetting search index** — adding a post doesn't automatically make it searchable; Hugo needs `outputs.home: [HTML, RSS, JSON]` and a search page
5. **Not verifying after deploy** — CDN cache can mask 404s; verify with explicit curl checks
6. **GitHub Pages 部署源设置** — 如果 Hugo 构建成功但 Pages 显示 404 或 README 内容，检查 Settings → Pages → Source。`build_type: legacy`（从 main 分支部署）会让 workflow 产物无效。必须设为 `build_type: workflow` 才走 GitHub Actions。修复命令：
   ```bash
   gh api -X PUT repos/用户名/仓库名/pages -f build_type=workflow
   ```
7. **Over-structuring** — not every post needs all sections; adapt to the story
7. **Fake specifics** — never invent numbers or data; use what the system actually reports

## Verification Checklist

- [ ] Searched for existing similar content before drafting
- [ ] Gathered real data from the environment (not made-up)
- [ ] Chosen appropriate post type from the 5 templates
- [ ] Drafted with TL;DR + problem → solution → results → trade-offs flow
- [ ] All code blocks are runnable with language identifiers
- [ ] Humanizer pass completed (29-pattern scan)
- [ ] Self-audit: "Does this sound like AI wrote it?"
- [ ] User reviewed and approved the draft
- [ ] `draft: false` set, committed and pushed
- [ ] GitHub Actions workflow completed successfully
- [ ] Article URL returns HTTP 200
- [ ] Search index (`index.json`) contains the article
- [ ] Listing page (`/posts/`) shows the new article
