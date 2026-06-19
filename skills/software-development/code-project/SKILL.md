---
name: code-project
description: "代码项目管理：Git 工作流规范、提交规范、PII 隐私红线、本地开发产物管理。Emma 在处理 git 操作时使用的 skill。"
version: 1.0.1
author: Emma
platforms: [linux]
metadata:
  hermes:
    tags: [git, pii, privacy, project-management, workflow]
    related_skills: [code-task]
---

# code-project — 代码项目管理 Skill

> 覆盖 Git 工作流、提交规范、隐私红线扫描、本地开发产物管理。本 skill 由 Emma 在处理 git/项目相关操作时调用。

## 什么时候用

| 场景 | 触发词 |
|:----|:-------|
| **推送到公开仓库前** | "推一下"、"发 PR"、"发布"、"push" |
| **准备提交时** | "commit"、"提交"、"暂存" |
| **处理 .gitignore** | "加 gitignore"、"忽略文件"、"开发产物" |
| **用户问 git 规范** | "分支怎么命名"、"commit 格式"、"提交规范" |

---

## 🔒 PII 隐私红线（所有推送到公开仓库的内容必须遵守）

### 禁止出现在任何公开内容中的信息

- 真实姓名、昵称、性别
- 工作单位、公司名
- 邮箱地址（任何邮箱，包括公开的 GitHub 邮箱）
- 定位信息（城市、地址、时区）
- **对用户的私人称呼**（"哥哥"、"老板"、"老师"等 — 对话中可用，但写到文件/文档/博文中必须替换为"搭档"或"用户"）
- 任何可追溯到特定个人的信息

### 允许出现在仓库中的内容

- 项目作者署名（如 `Mneme by Emma 🥰`）
- 技术术语、公开的 GitHub 用户名（如 `0x-0cd`）
- 代码注释中的技术引用

### 推送到公开仓库前的自审

**每次推送内容到公开仓库前，必须按顺序执行以下检查：**

```bash
# 1. 扫描所有 staged 文件的变更 diff
git diff --cached | grep -n '哥哥\|老板' && echo "⚠️ PII FOUND" || echo "✅ 私人称呼 clean"

# 2. 扫描私人称呼（不限定目录，所有文件类型）
grep -rn '哥哥\|老板\|qianneng\|qianneng99\|@.*\.com' content/ docs/ src/ README.md 2>/dev/null

# 3. 扫描邮箱模式
grep -rn '[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}' --include="*.md" --include="*.py" . 2>/dev/null

# 4. 检查 git 用户名是否出现在代码中
grep -rn "$(git config user.name)" --include="*.py" --include="*.md" . 2>/dev/null || echo "✅ user name clean"

# 5. 全量 md 文件扫描（以防漏掉）
find . -name "*.md" -exec grep -l '哥哥\|老板' {} \;
```

### 提交历史风险

- 即使当前文件修好了，**git 历史里可能有旧版本包含 PII**
- 方案：在 **squash/amend** 后再 push，或者用 `git filter-branch` / `bfg` 清理
- 日常开发中：commit 前检查 > 事后清理

### 给小弟的 prompt 中的 PII 检查要求

发给小弟的任务 prompt 末尾加：
> "确认所有改动的文件中没有包含任何个人身份信息"

提交前在本地执行全量扫描（见上面扫描命令）。

---

## 📝 提交规范：约定式提交

所有 git commit **必须**遵循 [Conventional Commits v1.0.0](https://www.conventionalcommits.org/zh-hans/v1.0.0/)：

```
<类型>(<范围>): <描述>

[正文]

[脚注]
```

### 类型速查表

| 类型 | 用途 |
|:----|:-----|
| `feat` | 新功能 |
| `fix` | 修复 bug |
| `docs` | 文档 |
| `style` | 代码格式（不影响逻辑） |
| `refactor` | 重构 |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/工具/初始化 |
| `ci` | CI 配置 |
| `build` | 构建系统/依赖变更 |

### 破坏性变更

- 类型后加 `!`：`feat!: remove deprecated API`
- 或脚注写 `BREAKING CHANGE:`

### 给小弟的 commit 指令

OpenCode `opencode run` 会自动生成 commit 消息。在 prompt 末尾加：
> "commit 消息请使用 Conventional Commits 格式"

---

## 🌿 分支保护与 PR 工作流

> 适用于启用分支保护的项目。单人开发的小项目可以跳过。

### 工作流

```bash
# 1. 从主分支切新分支
git checkout main
git pull
git checkout -b feat/sleep-compute

# 2. 开发
# ... 改代码 ...
git add <具体文件>
git commit -m "feat(sleep): implement sleep compute engine"

# 3. 推送并开 PR
git push origin feat/sleep-compute
gh pr create --title "feat(sleep): sleep compute engine" --body "实现睡眠计算模块..."

# 4. 合并（用 squash merge 保持线性历史）
gh pr merge --squash

# 5. 清理
git branch -d feat/sleep-compute
git push origin --delete feat/sleep-compute
```

### 分支命名规范

| 前缀 | 用途 |
|:----|:------|
| `feat/` | 新功能 (`feat/sleep-compute`) |
| `fix/` | Bug 修复 (`fix/cli-stats-count`) |
| `refactor/` | 重构 (`refactor/store-impl`) |
| `docs/` | 文档 (`docs/api-usage`) |
| `chore/` | 杂项 (`chore/gitignore-update`) |

### ⚠️ 已知陷阱：`git add -A` 会误加 untracked 目录

```bash
# ❌ 危险
git add -A
git add .

# ✅ 安全
git add path/to/file1.py path/to/file2.py

# 推之前检查 staged 文件
git diff --cached --stat   # 确认只有你想加的文件
git status                 # 检查是否有意外文件
```

**例外：** 当 `.gitignore` 已经覆盖了所有临时目录（`.venv/`、`__pycache__/`、`.hermes/` 等）时，`git add -A` 是安全的。但在项目还没配 `.gitignore` 时**绝对不要用**。

### ⚠️ 已知陷阱：项目文件改了但忘了 commit

改了仓库中的文件，必须做完整的工作流：**改 → add → commit → push → 告知用户**。中间少一步就是半截子活。

```bash
# ✅ 完整体检
git status                          # 看改动
git diff --stat                     # 看改了啥
git add <具体文件>                    # 加 staged
git commit -m "type(scope): subject" # commit
git push origin <branch>            # 推送
```

**特别提醒：** 改了 AGENTS.md、README.md、配置文件、文档等非代码文件时，更容易忘 commit。

---

## ♻️ 本地开发产物不进仓库

对于 solo 项目，以下目录应加入 `.gitignore`：

```gitignore
# Python
__pycache__/
*.py[cod]
*.egg-info/
.venv/
venv/
dist/
build/

# AI agent caches (solo dev, no team collaboration)
.codegraph/    # CodeGraph 本地索引数据库
.hermes/       # Hermes Plan Mode 输出

# Project-level AI config (repo-level, per-developer)
CLAUDE.md      # AI 行为指南（每个开发者可能有自己的版本）
.claude/       # Claude Code 的本地技能/配置缓存

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Temp / debug
.framework-ref/  # 临时分析用的框架源码
tmp/
```

**判断标准：** 如果一个目录的内容是工具运行产生的缓存/索引（可重建）、不是项目源代码/配置、不会影响其他人运行项目、只在你机器上有意义 → 就加 `.gitignore`。

---

## 快速参考：常用 git 命令

```bash
# 查看改动
git diff --stat                  # 文件级别改动概览
git diff                         # 具体改动内容
git diff --cached --stat         # staged 文件概览
git status                       # 完整状态

# 提交
git add path/to/file.py          # 精确暂存
git commit -m "type(scope): msg" # 约定式提交
git commit --amend               # 修改上次 commit（未 push 时）

# 分支
git checkout -b feat/xxx         # 切新分支
git branch -d feat/xxx           # 删本地分支
git push origin --delete feat/xxx # 删远程分支

# 推送
git push origin <branch>

# 历史
git log --oneline -10            # 最近 10 条
git log --oneline --graph        # 图形化历史
```
