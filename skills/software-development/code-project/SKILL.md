---
name: code-project
description: "代码项目管理：Git 工作流规范、提交规范、PII 隐私红线、本地开发产物管理。Emma 在处理 git 操作时使用的 skill。"
version: 1.2.0
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
| **技术债审计** | "技术债还有哪些"、"项目健康度"、"代码质量怎么样" |

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

### ⚠️ 已知陷阱：不小心用 `git add -A` 跟进了不该进的文件

**第一步：确认 .gitignore 是否存在**

**不要用文件搜索（search_files/ls/find）判断 .gitignore 是否存在！** 它可能只在 git 历史中有，不在工作目录里（例如被意外 `.gitignore` 忽略掉了，或还没被追踪时用 search_files 可能找不到）。

```bash
# ✅ 正确：用 git log 确认是否曾被 git 跟踪过
git log --all --oneline -- .gitignore

# 输出示例（表示有历史）：
# d04f550 fix: remove _evennia_ref from tracking, add .gitignore
# ccba745 chore(gitignore): add .codegraph/ and .hermes/ for solo dev
# ...

# 输出为空 → 说明从未被跟踪，可以创建全新的 .gitignore
# 有输出 → 恢复已有版本再追加，不要从头重写
```

**第二步：恢复原版 .gitignore（如果已存在）**

```bash
# ✅ 正确：从最近的 commit 恢复
# 用 git log 找到最后一个 touch 过 .gitignore 的 commit hash
git show <latest_commit_hash>:.gitignore > .gitignore

# ❌ 不要用 HEAD~1，可能不是正确的 commit（或 commit 历史中该文件不存在）
# ❌ 不要从头重写，会丢失项目已有的忽略规则
```

**第三步：从跟踪中移除误加文件 + 追加忽略规则**

```bash
# 从跟踪中移除（不删本地文件）
git rm --cached <误加文件>

# 追加忽略规则
echo "# local dev artifact" >> .gitignore
echo "<误加文件>" >> .gitignore

# 提交修复
git add .gitignore
git commit -m "fix: remove <误加文件> from tracking, update .gitignore"
git push origin <branch>
```

**常见误加文件：**
- 本地开发 symlink（如 `_evennia_ref` → Evennia 库的 symlink）
- IDE 配置目录（`.vscode/`、`.idea/`）
- 缓存/日志目录（`server/logs/`、`__pycache__/`）
- 框架/库引用（非项目源码的本地引用）

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
_evennia_ref     # 本地 Evennia 库 symlink
tmp/
```

**判断标准：** 如果一个目录的内容是工具运行产生的缓存/索引（可重建）、不是项目源代码/配置、不会影响其他人运行项目、只在你机器上有意义 → 就加 `.gitignore`。

### 确认文件是否真的需要加 .gitignore

当你说"X文件需要加 .gitignore"时，**先验证再行动**——模式可能已经覆盖了它：

```bash
# ✅ 用 git ls-files 确认文件是否被跟踪
git ls-files <可疑文件>

# 输出为空 → 未被跟踪（已在 .gitignore 覆盖范围内或不在仓库中）
# 有输出   → 已被跟踪，需要 git rm --cached 再追加忽略
```

不要默认假设一个文件需要追加 gitignore 规则——`*.db`、`*.log` 等通配模式可能已经覆盖了。

> **教训（2026-07-12 Mneme）：** memories.db（2MB）被列为技术债条目，以为需要加 .gitignore。实际 `git ls-files` 确认它未被跟踪，`*.db` 模式已覆盖。先验证再行动。

---

## 🪪 项目改名工作流

当用户发现项目目录名和实际项目名不一致需要改名时，按以下步骤安全执行：

### 标准流程

```bash
# 0. 先确认 GitHub 远程仓库名是否正确
git remote -v
# 如果远程仓库名需要改，去 GitHub 上 rename repo 再 git remote set-url

# 1. 全量搜索所有硬编码的旧路径
#    搜所有常见文件类型，不限于项目内部
grep -rn "旧路径" --include="*.py" --include="*.md" --include="*.toml" \
     --include="*.yaml" --include="*.yml" --include="*.json" \
     --include="*.jsonc" --include="*.sh" ~/

# 2. 分类路径引用
#    按"项目内部"和"外部依赖（skills/benchmarks/scripts）"分类

# 3. 改名目录
mv ~/projects/旧目录 ~/projects/新目录

# 4. 重装可编辑安装（旧 pip install -e 指向旧路径）
pip install -e . --no-deps

# 5. 更新第1步找到的所有引用
#    - 项目内部文件：直接 edit
#    - 外部依赖：逐一 patch

# 6. 验证
python -c "from 包名 import __version__; print('OK')"
python -m pytest 最快测试组 -q
```

### 分类策略

| 引用类型 | 处理方式 | 例子 |
|:---------|:---------|:-----|
| **项目内部文件** | `patch` 直改 | start_server.py 的 cwd、test 中的硬编码路径 |
| **外部 benchmark 项目** | `patch` 直改 | memory-benchmarks/run_locomo_local.py 的 MNEME_PROJECT_DIR |
| **Hermes skills 文档** | `patch` 直改 | skills 目录下的引用文档和模板 |
| **Hermes cron 任务** | `cronjob list` 检查后 update | cron 脚本中的 cwd 参数 |

### 常见陷阱

| 陷阱 | 预防 |
|:----|:-----|
| **只改目录名不改引用** | 改名后立刻搜一遍旧路径确认零命中 |
| **忘记重装 pip install -e** | 旧 editable install 指向已不存在的路径，import 会报 ModuleNotFoundError |
| **漏掉 emma-skills 等外部技能库** | 搜 `~/` 全量，不限项目目录 |
| **漏掉 cron 任务的 cwd 参数** | `hermes cron list` 查看所有任务的工作目录 |

> **教训（2026-07-12 Mneme 改名）：** `ai-memory-system` → `mneme`，发现 9 处硬编码引用分布于项目内部、memory-benchmarks、emma-skills 三个独立位置。改名后还需要 `pip install -e . --no-deps` 重装才能使 import 生效。

---

## 🔍 技术债审计工作流

当用户问"技术债还有哪些"、"项目健康度怎么样"时，按以下流程执行全量扫描：

### 标准扫描清单

```bash
# 1. 读现有技术债文档
cat TECH_DEBT.md 2>/dev/null || echo "无 TECH_DEBT.md"

# 2. Ruff 全面检查
ruff check src/                     # 源码区
ruff check tests/                   # 测试区（很多人只扫 src/，漏掉 tests/）

# 3. 扫描 TODO/FIXME/HACK/XXX 残留
grep -rn "TODO\|FIXME\|HACK\|XXX\|WORKAROUND" --include="*.py" src/ tests/ \
  || echo "✅ 无残留"

# 4. Git 状态快照
git diff --stat                     # 未提交的改动
git ls-files --others --exclude-standard  # untracked 文件

# 5. 遗留测试产物
ls *.db *.db-journal *.db-wal *.db-shm 2>/dev/null \
  && echo "⚠️ DB 产物在项目根" || echo "✅ 无 DB 产物"

# 6. 关键测试冒烟（最快的那组）
python -m pytest tests/test_types.py tests/test_db.py -v --tb=short --timeout=30
```

### 结果汇报

按 🔴 🟡 🟢 三级输出，明确每条的状态、位置和改量：

```markdown
| 优先级 | 项目 | 改量 | 说明 |
|:------:|:----|:----|:-----|
| 🔴 | **阻塞问题** | N 文件 | 需要立即处理 |
| 🟡 | **高优先级** | N 文件 | 应该修的 |
| 🟢 | **低优先级** | N 文件 | 顺手可修 |
```

交叉对照 TECH_DEBT.md 的记录：
- 已有条目是否已解决 → 标记为 ✅
- 未记录的条目 → 新增到报告中
- 计数不一致（如过时的 test count）→ 指出差异

### 常见遗漏

| 容易漏掉的内容 | 检查方式 |
|:--------------|:---------|
| 测试文件的 ruff 问题 | `ruff check tests/` — 很多人只扫 src/ |
| 已解决但 TECH_DEBT 没更新的条目 | 对比 ruff/测试结果和 TECH_DEBT 记录 |
| 被 git 忽略但仍需清理的产物 | `git ls-files --others --exclude-standard` |
| 依赖装了但没用 | `pip list` + 对照 pyproject.toml 的 dependencies |

> **本 session（2026-07-12 Mneme）验证：** 全量扫描发现 ruff src/ 零报错、tests/ 有 15 处（全在 integration_test_v03.py，含 E501 + B007）、TECH_DEBT 记录的 135 测试已过时（实际 166 pass）。扫描完直接修复了 3 项。

---

## ✓ 验证外部代码改动（小弟输出审查流程）

当 OpenCode 小弟完成代码改动后，Emma 需要验证输出再告知用户。按以下顺序执行：

### 审查流水线

```bash
# 1. 改了什么文件
git diff --stat

# 2. 具体改了啥（审查代码质量）
git diff

# 3. 语法检查（只关心改动的文件）
for f in <file1> <file2> ...; do
  python -c "import py_compile; py_compile.compile('$f', doraise=True)" && echo "✅ $f"
done

# 4. 功能验证（跑关键断言，如注册表、config load 等）
python -c "from world.npc_templates import NPC_TEMPLATES; print(list(NPC_TEMPLATES.keys()))"

# 5. PII 扫描
git diff | grep -n '哥哥\|老板\|qianneng\|@.*\.com' || echo "✅ PII clean"
```

### 守则

| 步骤 | 做什么 | 常见坑 |
|:-----|:-------|:-------|
| **看 diff** | 读全量 diff，确认逻辑正确、命名一致、没留调试代码 | 小弟说"做完了"不代表真的做完了 |
| **语法检查** | 只检查改动的文件（预存错误是旧代码，不是本次引入的） | 项目可能已有语法错误，要区分新旧 |
| **功能验证** | 写简短断言验证改动生效（如模板注册、import 成功、config 加载） | 小弟的 claim 不可信，要自己验证 |
| **Git 收尾** | 确认小弟是否已 commit。没 commit → git add → commit → push | **小弟常不提交代码**，必须检查 git status |

### 小弟没提交时的收尾流程

```bash
git status                              # 确认改动
git add <file1> <file2> ...             # 精确暂存
git commit -m "type(scope): message"    # Conventional Commits
git push origin dev                     # 推送到 dev
git log -1                              # 确认 commit hash
```

> **历史教训（2026-06-19）：** 小弟改了 NPC 猎人功能后没有 commit，Emma 收到通知以为完事了，结果用户 pull 不到。从此：不管小弟说没说完，自己查 git status 确认提交状态。

---

## 快速参考：常用 git 命令
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
