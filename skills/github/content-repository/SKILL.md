---
name: content-repository
description: "Create and structure content-only GitHub repos (reading lists, knowledge bases, documentation collections) — pure Markdown, README-as-index, category files, no progress tracking unless asked."
version: 1.0.0
author: Emma
platforms: [linux]
metadata:
  hermes:
    tags: [GitHub, content, reading-list, knowledge-base, markdown]
    related_skills: [github-repo-management, github-profile-design]
---

# Content Repository — Content-Only GitHub Repos

> For repos that hold **structured content** (not code): book lists, reading lists, knowledge bases, documentation collections, note collections.

## When to use

- User says "建立书单"、"整理书单"、"弄个阅读清单"、"建个书库"
- User wants a GitHub repo to hold curated lists, references, or notes
- Any task where the output is **organized Markdown content** rather than runnable code

## Recommended structure

```
repo/
├── README.md            ← Index / table of contents
├── 01-category-a.md     ← One file per major category
├── 02-category-b.md
└── ...
```

### Why this structure

- **README as index**: A brief table-of-contents listing each category file with a one-line description. Reader opens the repo and knows everything available.
- **Category files**: Each file covers one broad category with subcategory headings. Max 2 levels of nesting — deeper than that means the class boundary is wrong.
- **Flat over nested**: One directory level only. No subdirectories. Simpler to navigate, simpler to grep.

## Conventions

### Per-item format

```markdown
- **《Title》** — Author · Subcategory
```

Book title, author, subcategory — three fields, minimal. No extra metadata unless the user requests it.

### Format

- **Pure Markdown** only. No HTML, no external links (unless the user explicitly asks for download/purchase links).
- **UTF-8 encoding**.
- **No YAML frontmatter** in content files (the README can have it, but the category files are pure content).

### Category numbering

Use zero-padded two-digit prefixes: `01-`, `02-`, ..., `12-`. This gives room for up to 99 categories and keeps them in order in file browsers.

## ⚠️ Pitfall: Do NOT add progress/status markers unless asked

For personal content collections (reading lists, book lists, knowledge bases), **do not add**:

- Status columns (`✅已藏`, `📖想读`, `📕在读`, etc.)
- Progress bars or tracking emoji
- Any reading-progress notation

The user may not want to expose their reading status. The repo should be a **static catalogue**, not a task tracker. Only add progress markers if the user explicitly asks for them.

## When to choose a content repo vs other patterns

| Scenario | Approach |
|:---------|:---------|
| Book lists, article collections, knowledge base | Content repo (this skill) |
| Software project with code | Code repo (see `github-repo-management`) |
| GitHub Profile README | Profile repo (see `github-profile-design`) |
| Mixed content + code | Code repo, put content in a `docs/` or `references/` subdir |

## Verification

Before pushing:

- [ ] README lists all category files with descriptions
- [ ] No progress/status markers unless explicitly requested
- [ ] No external links unless explicitly requested
- [ ] All files are valid Markdown (renders cleanly on GitHub)
- [ ] File names use zero-padded two-digit prefixes
