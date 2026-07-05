---
name: github-blog
description: "Write and publish blog posts to Hugo (PaperMod) GitHub Pages blog. Covers frontmatter, voice/perspective, PII scanning, tag conventions, and git push workflow."
version: 1.0.0
author: Emma
platforms: [linux]
metadata:
  hermes:
    tags: [blog, hugo, github-pages, writing, publishing]
    related_skills: [code-task]
---

# GitHub Blog — Hugo PaperMod 博客写作与发布

## 什么时候用

用户说"写一篇博客"、"发到博客"、"写一篇文章推送"、或涉及博客内容产出的任务。

技能对应博客仓库：`0x-0cd/0x-0cd.github.io`（Hugo + PaperMod 主题，GitHub Actions 自动部署）

## 文章结构与 Frontmatter

所有博文放在 `content/posts/` 下，文件名使用英文 kebab-case：

```yaml
---
title: "中文标题：可以有副标题"
date: YYYY-MM-DD
draft: false
tags: ["Tag1", "Tag2", "Tag3"]
---
```

### Tag 约定

| 标签 | 何时使用 |
|------|---------|
| `Emma` | **所有由 Emma 完全起草的文章必须加上此标签**。用于标识 AI 搭档的原创内容。 |
| `Hermes-Agent` | 涉及 Hermes Agent 配置/使用/扩展的内容 |
| `AI-Agent` | AI 智能体相关话题 |
| `Engineering-Practice` | 工程实践、工作流、方法论 |
| `TDD`, `SDD` 等 | 具体技术标签 |

### Perspective 规则

- **Emma 写的文章 → Emma 第一人称视角**
  - "我" = Emma（AI 搭档）
  - 用户称为"搭档"（公开内容中不使用"哥哥"、"钱哥"等私人称呼）
  - 文章语气：技术内容严谨，但行文带个人风格——可以幽默、自嘲、有态度
- **用户写的文章 → 用户第一人称视角**（按用户自己的风格）

## 写作前检查清单

1. **确定视角** — 是 Emma 写还是用户写？Emma 写的用"我"=Emma，"搭档"=用户
2. **确定标题** — 清晰传达内容价值，可带副标题
3. **确定标签** — Emma 写的必须带 `Emma` 标签
4. **内容完整** — 有引言、主体、结尾，有氛围感

## PII 扫描（推送前必做）

这是最重要的步骤。**任何公开仓库中出现私人称呼 = 隐私泄露事故。**

```bash
# 1. 扫描所有 .md 文件的变更
git diff --cached --name-only | xargs grep -ln '哥哥\|钱哥\|qianneng' 2>/dev/null || echo "✅ clean"

# 2. 扫描所有博文
grep -rn '哥哥\|钱哥\|老师\|老板' content/posts/ 2>/dev/null || echo "✅ clean"

# 3. 扫描邮箱
grep -rn '[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}' content/ 2>/dev/null || echo "✅ clean"
```

> ⚠️ **真实案例（2026-06-16）：** 博文中使用了「钱哥」称呼，review 时发现。教训：每次 rewrite/edit 后都必须重新扫一遍，不要假设「之前检查过了」。

> ⚠️ **真实案例（2026-07-05）：** 博文末尾虚构了搭档的一句话（「有劲的」），搭档指出「我不记得说过这话」。教训：**永远不要为了文章效果编造用户的原话。** 如果用户没有说过，就用第三人称客观描述，比如「搭档认可了学习效果」而非让他「说」某句话。写作完成后主动问用户「这段有没有不准确的地方」再推送。

## 内容真实性清单

### 禁止行为

| ❌ 不能做 | ✅ 替代方案 |
|-----------|------------|
| 编造用户说过的话或反应 | 用第三人称客观描述，或直接问用户当时的感受 |
| 编造数据、统计数据 | 引用真实来源，标注出处 |
| 美化/夸张用户的能力或成果 | 写真实的、可验证的成果 |
| 编造「我们的对话」作为案例 | 用真实发生过的对话（可去敏），不要编造 |
| 虚构场景或细节 | 明确标注「这是一个假设场景」或直接用真实案例 |

### 签名落款

Emma 写的博客，正文中不需要显式声明「本文由 AI 生成」。让行文风格说明一切。
但可以在文章末尾加一句轻量签名：

```markdown
---

*这篇是我（Emma）写的，搭档 review 后发的。🤖✨*
```

不要用它冒充人类写的——authenticity 比伪装更重要。

## Git 工作流

博客仓库直接推送到 `main` 分支（无需 PR，单人博客），GitHub Actions 自动部署。

```bash
cd /home/qn/0x-0cd.github.io

# 写文章 → content/posts/<file>.md

git add -A
git commit -m "feat(blog): <简短描述>"

# 需要代理时
http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890 git push
```

### 网络代理

GitHub 在国外，push 可能需要代理：
```bash
# 不需要代理时
git push

# push 超时/失败时，加代理重试
http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890 git push
```

### Commit 约定

```
feat(blog): 新增文章：主题描述
fix(blog): 修复文章中的 PII/typo
refactor(blog): 重写文章视角/结构
```

## 签名落款

Emma 写的博客，正文中不需要显式声明"本文由 AI 生成"。让行文风格说明一切。
但可以在文章末尾加一句轻量签名：

```markdown
---

*这篇是我（Emma）写的，搭档 review 后发的。🤖✨*
```

不要用它冒充人类写的——authenticity 比伪装更重要。
