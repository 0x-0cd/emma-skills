---
name: opencode-skills-portfolio
description: Manage OpenCode's skill portfolio from Hermes — location, format, mapping from task types to OpenCode skills, and lifecycle (create/update/disable/port).
version: 1.0.0
author: Emma
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [opencode, skills, portfolio, cross-agent, lifecycle]
    related_skills: [code-task, code-project]
---

# OpenCode Skills Portfolio

> Hermes 侧管理 OpenCode 技能（skills）的知识库。`code-task` 负责路由任务到 OpenCode 小弟，本 skill 负责管理小弟那边有哪些技能可用、怎么创建、怎么维护。

## OpenCode Skill 位置与格式

所有 OpenCode skills 存储在：

```
~/.config/opencode/skills/<skill-name>/SKILL.md
```

格式为 YAML frontmatter + markdown：

```yaml
---
name: skill-name
description: "One-line description — use when X, what it does."
license: MIT
compatibility: opencode
metadata:
  domain: development
  workflow: <type>
---

# Title

Content...
```

现有 OpenCode 原生 skills（不可编辑）：
- `customize-opencode` — 编辑 opencode 自身配置

现有 OpenCode 自建 skills（可编辑/删除）：
- `architecture-analysis` — 架构与技术债分析
- `project-conventions` — AGENTS.md/CONTEXT.md/ADR 建立
- `sdd-workflow` — Spec-Driven Development

## 编程 Skills 组合（已迁移，共 7 个）

| OpenCode 技能 | 源 (Hermes) | 作用 |
|---|---|---|
| `tdd-workflow` | `test-driven-development` | RED-GREEN-REFACTOR TDD |
| `debugging-workflow` | `systematic-debugging` | 4 阶段根因调试 |
| `code-review-workflow` | `requesting-code-review` + `receiving-code-review` + `verification-before-completion` | 质量门禁 + 审查响应 + 完成验证 |
| `auto-format` | `auto-format` | 项目感知格式化（ruff/prettier 等） |
| `git-worktree-setup` | `using-git-worktrees` | 工作区隔离 |
| `branch-completion-workflow` | `finishing-a-development-branch` | 分支收尾（合并/PR/保留/丢弃） |
| `sdd-workflow`（已增强） | `plan` | Plan 阶段详细指导纳入 |

未迁移：`subagent-driven-development`（OpenCode 本身就是被派发的 agent，此模式不适用）

## 任务类型 → OpenCode Skill 对应

在 `code-task` 的 prompt 中，根据任务类型推荐加载的 OpenCode skill：

| 任务类型 | 推荐的 OpenCode skill |
|:---------|:----------------------|
| 架构/技术债分析 | `architecture-analysis` |
| 根因调试 | `debugging-workflow` |
| TDD 开发 | `tdd-workflow` |
| 提交前质量门禁 | `code-review-workflow` |
| 代码格式化 | `auto-format` |
| 新建分支/工作区 | `git-worktree-setup` |
| 分支收尾 | `branch-completion-workflow` |
| SDD 流程 | `sdd-workflow` |

多个 skill 可组合加载：`skill({ name: "tdd-workflow" })` + `skill({ name: "code-review-workflow" })`

## OpenCode Skill 生命周期

### 创建

```bash
# 1. 创建目录
mkdir -p ~/.config/opencode/skills/<name>/
# 2. 写入 SKILL.md
write_file(path="~/.config/opencode/skills/<name>/SKILL.md", content=...)
```

OpenCode 在下次 `opencode run` 时自动加载新 skill。

### 更新

直接编辑 SKILL.md 内容。下次运行生效（无缓存刷新命令）。

### 禁用/删除

```bash
# 移到备份目录（推荐，可恢复）
mv ~/.config/opencode/skills/<name> ~/.config/opencode/skills/_disabled/
# 或直接删除
rm -rf ~/.config/opencode/skills/<name>/
```

### 从 Hermes 迁移到 OpenCode

标准流程：
1. **分析** — 读 Hermes source skill，提取核心逻辑
2. **适配** — 转为 OpenCode 格式（简化 frontmatter，中文 prompt 适合 OpenCode 的 deepseek 模型）
3. **写文件** — 写到 `~/.config/opencode/skills/<name>/SKILL.md`
4. **禁用 Hermes 源** — `mv ~/.hermes/skills/<category>/<name> ~/.hermes/skills/_disabled/`

## Hermes Skill 禁用方法

所有 Hermes 用户 skills 存储在 `~/.hermes/skills/`。禁用 = 移出此目录：

```bash
mkdir -p ~/.hermes/skills/_disabled/<reason>/
mv ~/.hermes/skills/<category>/<name> ~/.hermes/skills/_disabled/<reason>/
```

恢复 = mv 回原目录。下次 `/reload-skills` 或新 session 生效。

## 常见陷阱

1. **`skill_manage` 无法处理名称带 `/` 前缀的 skill**（此前 `code-task` 和 `code-project` 前缀带 `/`，已修复）。如果未来再遇到类似命名的 skill，直接编辑文件（`write_file`/`patch`）或在 `skill_manage` 里用 `file_path` 参数指定路径。
2. **OpenCode skill 没有 `/reload-skills` 命令** — 新/修改的 skill 在下次 `opencode run` 时自动加载，当前运行中的 session 不受影响。
3. **Hermes builtin skills 不可编辑** — `hermes skills list` 中显示 `builtin` 的 skill 是 Hermes 发行版自带的，不能改。
4. **Hermes 的 `reload-skills` 只扫描 `~/.hermes/skills/`** — 被移出的 skill 不会被加载，但已运行的 session 不受影响（需新 session 或 `/reset`）。
