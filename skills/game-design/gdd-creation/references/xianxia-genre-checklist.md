# 修仙/MMO 题材 GDD 完整性清单

Reviewing a GDD for a 修仙 (xianxia cultivation) or MMO-style game? Cross-reference
the GDD against this list AND against the existing codebase — modules that already
implement a system not covered by the GDD are missed systems.

## 支柱系统（题材标配——缺失就是真缺口）

| 系统 | 为什么重要 |
|------|-----------|
| 角色创建 + 灵根/资质 | 角色根基设定；与转世天赋直接联动（前世火系功法→今世火系天赋加成，本质就是灵根机制） |
| 生产/生活技能（炼丹/炼器/制符/阵法 + 采集） | 题材招牌玩法；经济系统的产出端——材料从哪来、灵石往哪花都靠它 |
| 任务/剧情内容（quest/story/NPC） | 探索驱动需要内容线，不能只靠"瞎逛" |
| 挂机/修炼/离线收益 | 移动端修仙标配；与"实时在线"模式直接冲突，需要明确取舍 |
| 装备（品质/词条/强化） | 成长驱动的核心支柱之一 |
| 世界观/地域/宗门格局 | 探索驱动的内容基础 |
| 怪物/NPC 生态 | 战斗打什么、跟谁对话 |
| 存档安全/防作弊 | 永久死亡游戏必须防回档作弊 |
| 测试/QA 计划 | 开发路线图需要验收阶段 |

## 交叉对照方法

1. 读项目树（AGENTS.md、typeclasses/、world/、commands/ 等）——每个已存在的模块都可能是没进 GDD 的系统
2. 把每个模块映射到 GDD 章节；映射不上的 = 缺口
3. 按层级报告缺口（A 级：支柱系统整个缺失；B 级：提了但没定方向）
4. 让用户决定补哪些——绝不静默改写文档

## XunDaoMUD 实例（2026-08）

骨架 GDD 覆盖 11 个系统（传承/功法/战斗/境界/经济/宗门/探索/PvP/社交…），但缺失：
- A 级：灵根/角色创建、生产技能、任务/剧情、挂机修炼
- B 级：装备、世界观、怪物NPC生态、存档安全、测试计划

用户处置：骨架文档保持不动（已足够），缺失系统拆成独立细节文档，放在专门设计文档目录
（~/mud/docs/design/，README 索引，骨架+分系统结构），后续迁移到新 GitHub 仓库。
