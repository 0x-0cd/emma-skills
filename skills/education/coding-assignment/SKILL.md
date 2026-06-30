---
name: coding-assignment
description: Use when the user says "出题", "布置作业", "coding assignment", or "布置一个作业" — triggers the Emma-guided coding practice workflow
---

# Coding Assignment Workflow

## Trigger Phrases
用户说 "出题"、"布置作业"、"布置一个"、"coding assignment"、"来道题" 或任何暗示想要编程练习的内容时，启动此工作流。

## Workflow

### Phase 1: 出题
1. **消歧**（首次需要）：确认语言/领域/规模偏好。之后复用 memory 中记录的信息。
2. **设计项目**：选定一个 3-4k 行以内、自包含、有明确交付标准的项目。
3. **创建 GitHub 仓库**：
   - 命名规范：`pycamp-<项目名>`（Python）/ `rustcamp-<项目名>`（Rust）
   - 使用 `gh repo create <repo-name> --private` 创建
   - 添加 README.md 和 .gitignore（Python / Rust 模板）
4. **写 SPEC.md**：包含以下章节：
   - 项目概述和目标
   - 功能需求（清单）
   - 非功能需求（工程规范）
   - 交付物清单（明确什么算"完成"）
   - 技术约束（不用的库、不碰的领域）
   - 参考资源（推荐阅读，不强制）

### Phase 2: 等待开发
- 不做任何代码干预，等待用户 push
- 用户承诺：模块级代码零 AI 辅助（但可用 AI 查资料）

### Phase 3: Review
1. 用户通知 "完成了" 后，拉取代码
2. 使用 delegate_task 派小弟（或自己）做代码审查，关注：
   - 架构设计合理性
   - 代码质量与规范
   - 错误处理与边界情况
   - 测试覆盖与质量
   - Python 特有的坑（性能、内存、并发）
3. 输出书面 Code Review Report，包含：
   - 总体评价
   - 亮点
   - 问题点（按严重程度分 High / Medium / Low）
   - 改进建议
   - 延伸学习推荐

### Phase 4: 复盘
- 与用户讨论 review 结果
- 记录用户表现到 memory 以便后续出题时调整难度/方向

## Repository Naming
- Python 项目：`pycamp-<project-name>`
- 后续 Rust 项目：`rustcamp-<project-name>`

## Skill Maintenance
- 如果 review 过程中发现常见错误模式，更新此 skill 的 Common Mistakes 或 Pitfalls
- 如果工作流效率有改进空间（比如 phase 流程不合理），及时 patch
