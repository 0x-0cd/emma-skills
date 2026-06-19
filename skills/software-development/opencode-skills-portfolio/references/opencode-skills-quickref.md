# OpenCode Programming Skills Quick Reference

Loaded via `skill({ name: "..." })` in the OpenCode prompt.

## Portfolio (7 skills)

| Name | Trigger | Purpose |
|------|---------|---------|
| `tdd-workflow` | 写新功能/修 bug/重构 | RED → GREEN → REFACTOR 铁律 |
| `debugging-workflow` | 报错/行为异常/测试失败 | 4-phase 根因分析 → 修复 |
| `code-review-workflow` | 提交前/收到审查反馈/声称完成前 | 安全扫描 + 审查验证 + 完成门禁 |
| `auto-format` | 编辑文件后 | 项目配置检测 → 自动格式化 |
| `git-worktree-setup` | 开始新功能前 | 隔离工作区 + 依赖安装 + 基线测试 |
| `branch-completion-workflow` | 功能完成时 | 验证测试 → 选项（合并/PR/保留/丢弃） |
| `sdd-workflow` | 复杂改动/多文件/跨模块 | Spec → Plan → TDD → Validate → Archive |

## Existing (not from this migration)

| Name | Purpose |
|------|---------|
| `architecture-analysis` | 架构/技术债扫描 + 方案设计 + 分步实施 |
| `project-conventions` | AGENTS.md / CONTEXT.md / ADR 建立 |
| `customize-opencode` | (builtin) 编辑 OpenCode 自身配置 |

## Combination Patterns

```markdown
## 参考 resource
- 使用 tdd-workflow 指导开发流程
- 实现完成后用 code-review-workflow 做质量门禁
- 用 auto-format 格式化改动文件
- 完成后用 branch-completion-workflow 收尾
```
