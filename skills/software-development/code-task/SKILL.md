---
name: code-task
description: "Use when a coding task comes up — 写代码、改代码、修 Bug、重构、代码分析/设计。Emma 自己执行：消歧 → 侦察 → 计划 → TDD → 实现 → 验证 → 提交。无外派。"
version: 4.0.0
author: Emma
platforms: [linux]
metadata:
  hermes:
    tags: [coding, implementation, analysis, tdd, refactor, debugging, evennia, mud, self-execution]
    related_skills: [code-project, game-balance-design]
---

# code-task — 代码任务工作流（Emma 自己写）

> **路由变更（2026-09-11）：** OpenCode 已从本机彻底删除（二进制 + 配置 + 凭证 + session DB）。代码任务**不再外派**。Emma 自己完成全流程：**读代码 → 消歧 → 计划 → TDD → 实现 → 验证 → 提交**。用户说"你自己来改/你来写代码"即走本流程。

> **核心原则：先读懂，再动手；先有验证，再有交付。** 不许"看起来对就提交"。每个改动都要有可执行的验证证据（测试输出、py_compile、import 断言、diff），交付时贴一手证据。

---

## 什么时候用 / 不适用

**用：**
- 🧑‍💻 代码修改类：写功能、修 Bug、重构、调优、写测试
- 🔍 分析类：问题定位（"为什么 X 不工作"）、模块设计、架构审查、技术债扫描

**不用（走别的路）：**

| 场景 | 处理方式 |
|:----|:--------|
| 代码行为查询（"这段代码怎么工作的"） | 本 skill 的 Phase 1 之后直接读代码回答（见坑 #6） |
| Git 提交规范 / PII 红线 / 分支流程 | `code-project` skill |
| 纯数据/纯内容文件（YAML/JSON 静态常量、文案表） | 直接 `write_file` / `patch` |
| 设计文档、产品方案 | `plan` / idea-to-design-doc 类 skill |
| 数值平衡设计 | `game-balance-design` skill |

---

## Phase 0：开工前准备检查

用户说「继续开发 XX」、「检查开发环境」、「看看准备得怎样了」这类无具体任务的开场白时，先做一轮就绪检查，按 ✅ / ⚠️ / ❌ 汇报。**每项都要有实际工具输出支撑，不许凭记忆答。**

```text
1. 项目 Git 状态     → git log --oneline -5 / git status --short / git describe --tags
2. 项目能否导入       → python -c "from <包> import __version__; print(__version__)"
3. 关键依赖是否可用   → 读 pyproject.toml 的 [project.dependencies]，逐个 import 验证
                        （不是 pip list —— import 才能证明真的能用）
4. 核心测试是否通过   → 先跑最快的小测试做 smoke test，不要一上来全量
5. 工作区是否干净     → 有未提交改动先决定 commit 还是 stash，别在脏工作区上开工
```

**跳过条件：** 用户已给出明确任务（"修这个 bug"）→ 直接进 Phase 1；同 session 刚做过 readiness 且没换项目 → 不重复；只读不写的小操作 → 不涉及。

**大依赖安装：** 超过 2 分钟的安装走 `background=True + notify_on_complete=True`，不要阻塞在等待上。

---

## Phase 1：消歧

**在动手前先把歧义消灭。** 需求不清楚就问，不猜。

| 维度 | 要问什么 | 通过标准 |
|:----|:--------|:--------|
| **做什么** | 改代码还是做分析？ | 明确 |
| **改/分析什么** | 具体文件/模块？ | 精确路径或明确搜索条件 |
| **改成什么样** | 预期行为变化？分析到什么粒度？ | 具体描述，不是"修好它" |
| **不改什么** | 哪些文件/模块不能动？ | 明确边界 |
| **为什么** | 背景/目的（意图不明时才问） | 理解上下文 |
| **交付要求** | 出方案还是直接改？要跑测试吗？ | 明确完成标准 |

**消歧原则：**
1. **持续追问** —— 一个维度没消除就继续问，不做猜测
2. **不替用户做决定** —— 除非听到"你来定"/"你看着办"
3. **把歧义摆到台面上** —— "你说的'优化'是性能优化还是结构优化？改动方向完全不同。"
4. **对模糊用词直接质疑** —— "重构"、"优化"、"修好"、"整理"、"调整"必须先问清具体含义

### UI/UX 设计消歧（面板/组件/图形界面）

| 维度 | 要问的问题 | 通过标准 |
|:----|:---------|:--------|
| **🎨 视觉样式** | 颜色规则？渐变还是定值？有阈值吗？ | 每个元素的颜色/大小/宽高/阈值条件 |
| **🖱 交互行为** | 可点击吗？点击发什么命令？hover/scroll？ | 每个可交互元素的触发方式和效果 |
| **📡 数据驱动** | 什么时候刷新？tick 还是事件驱动？数据来源？ | 更新时机、消息格式、发送方 |
| **⚡ 边界情况** | XX 没有这个属性怎么办？数据为空显示什么？ | 缺失/空值/极限状态的渲染策略 |
| **🔮 预留设计** | 标注"预留/未来"的区域现在怎么处理？ | 留空还是占位，不阻塞当前实现 |

> **验证案例（2026-06-21 战斗面板）：** 用这 5 个维度问 6 个问题一次对齐——三资源条颜色 + 阈值（HP>60%绿/20-60%橙/<20%红，MP 蓝，SP 紫）；buff tag 可点击发命令；事件驱动刷新；怪物无 MP/SP 则隐藏该行；永久效果栏留空。

### 消歧完成的标准
- ✅ 知道是改代码还是做分析、涉及哪些路径/模块、改成什么行为
- ✅ 知道边界约束和完成标准（出方案 or 直接改；验不验测试）
- ✅ 所有模糊用词已替换为具体描述
- ✅ (UI) 5 个 UI 维度已确认

---

## Phase 2：分级与执行策略

任务明确后判断规模和策略。**拿不准就从重的那一档走。**

| 档 | 判据 | 策略 |
|:--|:----|:----|
| **🟢 小改** | 单文件、<30 行、一眼能看出根因、纯配置/文案 | 直接改 → 语法/import 验证 → 提交 |
| **🟡 中等** | 单文件逻辑改动、跨 2-3 文件、根因需追踪 | 先侦察读代码 → 列改动点 → 改 → 跑测试 |
| **🔴 复杂** | 跨 3+ 文件、新模块、架构改动、根因不明、>300 行文件的核心逻辑 | 先做代码库侦察 → **写计划**（`.hermes/plans/` 或直接列给用户确认）→ 分步实施 → 每步验证 |
| **📊 全项目扫描/分析** | 覆盖 100+ 文件或 10000+ 行 | **拆并行子 agent**（`delegate_task`），不要单线硬扫 |

### 复杂任务开工前先侦察

1. 搜关键词找出所有涉及的文件
2. 读关键部分：类型定义、数据格式、已有类似实现
3. 确认"不改什么"边界
4. 把侦察结果整理成改动清单（哪些文件、各自改什么行为），复杂任务先给用户看一眼再动手

### 全项目扫描 → 拆并行子 agent

单线扫全项目容易超时/输出截断。拆成独立维度并行：

```python
delegate_task(tasks=[
    {"goal": "扫描 🔴 阻塞级问题（语法错误/运行时异常/循环依赖）...", "toolsets": ["terminal", "file"]},
    {"goal": "扫描 🟡 重度问题（超大文件/重复逻辑/硬编码）...", "toolsets": ["terminal", "file"]},
    {"goal": "扫描 🟢 轻度问题（未用 import/命名不一致/死代码）...", "toolsets": ["terminal", "file"]},
])
```

拆分维度：按严重性（🔴🟡🟢）/ 按子系统（战斗/物品/命令/世界数据）/ 按检查项（语法/运行时/依赖/硬编码）。每个子 agent 的 scope 应能在 3-5 分钟内完成。

---

## Phase 3：实施规范

### TDD：先 RED 再 GREEN

涉及行为变化的改动：

```text
1. 写一个能复现问题/描述新行为的测试
2. 跑它 → 确认 FAIL（RED）。如果直接 PASS，说明测试没测到东西，回去改测试
3. 最小实现让它通过（GREEN）
4. 重构：清理实现，保持 GREEN
5. 跑相关测试全集，确认没打破别的
```

**例外：** 纯配置/文案改动、一次性数据修正、UI 样式微调，可以只做冒烟验证。

### 提交前自检清单（必过）

```bash
python -m py_compile <改动的每个 .py 文件>     # 语法
python -c "import <模块>"                      # import 链没断
pytest <相关测试> -q                           # 测试
git diff --stat                                # 只改了该改的
git diff                                       # 通读一遍自己的 diff，找调试残留
grep -rn "TODO\|FIXME\|print(" <改动文件>       # 调试代码残留（按项目惯例判断）
```

**PII 红线：** 提交前 `git diff` 扫一遍，公开内容里不许出现私人称呼、真实姓名、手机号、地址。详见 `code-project`。

### 自我审查

实现完成后自己通读 diff，检查：逻辑正确性、边界情况、命名一致性、调试代码残留、是否有"顺手改到的无关代码"。确认无误再提交。

### 增量 DOM 更新（周期性刷新的 UI 必须遵守）

所有周期性刷新的 UI 组件**必须增量更新**：首次渲染创建 DOM 结构，后续只改已有元素的属性（`width`/`text`/`class`），**禁止清空容器后重建**。否则 CSS `transition` 永远不触发（元素每次都是全新的）。

```js
// ❌ 每次 tick 清空重建 → 过渡动画失效
battlePanel.empty();
// ✅ 只更新属性 → transition: width .3s 生效
card.find('.hp-fill').css('width', newPct + '%');
```

### 顺手还债（有限度）

改动的文件附近有可以顺手清理的小问题（过时注释、未用 import、命名不一致）→ 一并修掉。发现结构性技术债 → 记到 `TECH_DEBT.md`，不在本次 diff 里顺手重构。

### 不夹带未验证的假设

代码改动**只基于读到的源码事实**，不基于"应该是这样"。写之前先 `read_file` / `search_files` 确认路径、函数签名、数据流；对不上就继续查，别用推测填坑。

---

## Phase 4：验证与交付

### 交付必须带一手证据

```text
1. 改了哪些文件、每处改了什么行为
2. 验证证据：测试输出 / py_compile / import 断言 / 实际运行结果
3. git diff --stat 摘要
4. commit hash（走 code-project 的 Conventional Commits）
5. 确认无 PII
```

**不许只写"改完了"** —— 没有工具输出支撑的完成声明不算完成。

> **历史教训（2026-06-14）：** 曾出现"声称 commit `177320f` 已推送但 git log 里没这个 commit"。任何"已完成/已推送"都要自己 `git log -1` 看一眼再说。

### 推送时机

| 情况 | 做法 |
|:----|:----|
| 用户说"一个一个来" | 每个改动 commit + 汇报 + **等 review** 再继续 |
| 用户说"每个单独提交，全部完了一起测" | 逐个 commit（不推）→ 全部完成后批量验证 → 一起推 |
| 用户说"一把梭/全部做完" | 一次做完，批量验证后推 |
| 用户没明说节奏 | **先问**："这些我依次做完汇报，还是一个一个来？" |

---

## 内容/命名/数值设计流程

游戏内容（NPC 对话、物品名、房间文本、剧情、数值）不是普通代码——**先设计给用户审核，再落成代码。**

| 内容类型 | 处理方式 |
|:--------|:--------|
| 已有明确需求（用户说了写什么） | 直接实现 |
| 需要命名的内容池（物品/技能/怪物名） | **先出命名设计稿** → 用户审核 → 再实现 |
| 数值平衡（概率/价格/属性值） | **先出数据草案**（最好用 Python 精算多路径） → 用户审核 → 再实现 |
| 需要创作的文案（房间/物品描述） | 定风格约束 + 示例 → 批量生成 |

```
Emma 出设计稿（命名+备注+风格说明）
    ↓ 呈交用户审核
用户反馈调整 → Emma 更新 → 审核通过
    ↓
实现进代码 → 验证 → 交付
```

**命名设计原则：**
- 不同稀有度/等级的名字要有明显区分度（一品朴实、六品传说感）
- 名字暗示稀有度（别给一品起"混沌青莲"，也别给六品起"轻灵草"）
- 考虑生态多样性（不同环境对应不同物品）
- 每个名字附简短备注说明风格和用途
- **风格偏好 接地气**：像真人真物，避免文绉绉/典故堆砌。NPC 名用"张有福、刘大壮、李老根、王大锤"这类；修仙味靠物品和世界观呈现，角色名可以土但要有真实感

> **教训（2026-07-11 采药命名）：** 用户要 52 种药材（一品12 + 二品12 + 三品8 + 四品8 + 五品6 + 六品6）。最初误解为总计 26 种。用户说"1-2品12种"这类表述时，**先确认是各 12 种还是共 12 种**。

**NPC 对话宁少勿多：**
- 引导型 NPC 的对话默认只给 **1 个核心指引分支**
- 一段话能讲完的信息量就别切成三个分支
- 功能指引 NPC 给"关键词 + 命令 + 产物轻提一句"就够，不做"产物详解""背景故事"分支

> **教训（2026-07-11 老农 NPC）：** 设计了三个对话分支（采药指引、农田产物介绍、杂草详解），每个内容都很足。用户反馈"太啰嗦了，改成一个就行"。

**进阶：数据驱动数值迭代** —— 涉及游戏经济、修炼曲线、消耗品定价、概率分布时，先提取代码中的实际公式，写 Python 脚本算多路径场景（最差/最优/平均玩家），再基于数据提案。详见 `game-balance-design`。

> **教训（2026-06-22 推演门槛）：** 连续 4 轮提案被否——每轮都漏算一个玩家路径（累计修炼量≠可支配余额、突破后余额、伪灵根坐牢时间）。从代码提取实际曲线 + 多路径精算后才通过。**每次被否都是数据不完整，不是方向不对。**

---

## Reciprocal Sweep（防漏改）

改动涉及**移除/重命名/重构功能**或**修改公式曲线**时，只改核心逻辑却不扫关联代码/数据，是 review 时被抓的第一大问题。

### 变体 A：移除/重命名/重构的代码扫描

```text
1. 确定核心改动：例如"移除 equip 的心法装备功能"
2. 确定关键词集合："equip.*force"、"equip.*心法"、"active_main_force"
   （既包括被改掉的 API，也包括用户可见文本：NPC 对话、错误提示、帮助文档）
3. grep 全项目收集命中（排除 .pyc/__pycache__/venv）
4. 分类：
   ┌──────────────┬────────────────────────────┐
   │ 已由本次改动覆盖 │ 核心逻辑已改，无需再处理        │
   │ 需要顺带修     │ 废弃引用/错误提示/注释——本次一起改 │
   │ 故意保留      │ 如帮助菜单里的 │Cequip│n（物品装备）│
   └──────────────┴────────────────────────────┘
5. 把"需要顺带修"的条目一并改掉
```

完成标准：grep 后每个命中要么已改，要么被明确判定为"故意保留"并能在交付报告里列出。**零遗漏条目。**

> **教训（2026-06-20）：** 移除 equip force 功能后，`cultivate.py` 的错误提示里还写着"再用 `equip <心法名> force` 装备为主心法"。用户 review 一抓一个准。

### 变体 B：公式/曲线修改的数据值扫描

**数据值比代码引用更容易漏**——公式改了，但按旧公式调出来的数值（怪物属性、技能伤害、掉落价值）全部失效，而且 grep 搜不出来（数据是数值不是标识符）。

**典型案例（2026-06-24）：**
- `curve_attack_strength` 从 `attack≤100→1.0` 改为 `(attack/100)^0.5`
- 怪物模板 `attack: 1` 的倍率从 1.0 骤降到 0.1（10 倍降幅）
- 结果：猛兽扑咬伤害因 defense 削减后 `int()` 归零变成 0
- grep 完全搜不到——数据值是 `1`，不是函数名

**流程：**
```text
1. 确定公式改动
2. 列出受影响的数据来源：
   物品/装备/怪物模板 | 技能/词条配置 | NPC对话/任务奖励 | 常量默认值 | 文档/注释
3. 对每个来源问：这个值假设了旧曲线的什么行为？新曲线下还合理吗？
   如果是"基准值"（如 attack=100 代表基准），旧曲线用 ≤100→1.0 掩盖了它，
   新曲线需要显式设为基准值
4. 写 Python 脚本跑新旧对比，算新曲线下的实际数值
5. 需要调整的数据项一并改
```

完成标准：每个受公式影响的数据源，要么已更新，要么被判定为"恰好正确"且有依据。**零遗漏。**

> **教训（2026-06-24）：** 公式改完永远反问——旧公式下哪些"隐藏假设"被新公式打破了？

---

## 文件拆分/重命名的向后兼容策略

把一个大文件拆成多个分类文件（如 `item_templates.py` → 多个 `*_templates.py`），且原文件被多处消费时：

**策略 A：保留原文件为纯 re-export hub**（消费者 ≥3 个时推荐）

```python
# item_templates.py — 注册表合并中心
from world.money_templates import ITEM_TEMPLATES as _MONEY
from world.equipment_templates import ITEM_TEMPLATES as _EQUIP
from world.material_templates import ITEM_TEMPLATES as _MATERIAL

ITEM_TEMPLATES = {}
for _d in (_MONEY, _EQUIP, _MATERIAL):
    ITEM_TEMPLATES.update(_d)
```

优点：消费方代码零改动。

**策略 B：直接更新所有消费者 import**（消费者 ≤2 个，或各自只需特定类型时）

```text
开始 → 原文件被多少文件引用？
  ├── ≥3 → 策略 A（re-export hub）
  └── ≤2 → 消费者是否只需要特定类型？
       ├── 是 → 策略 B（改 import）
       └── 否 → 策略 A
```

> **教训（2026-07-23 item_templates 拆分）：** 原本打算直接改消费方 import，侦察发现 `game_util.py` 有 8 处 `ITEM_TEMPLATES` 引用（通用 loot 查找、任务奖励、货币查询），`at_server_startstop.py` 要遍历所有物品同步描述。最终用策略 A 实现零消费者改动。

---

## 坑

### ⚠️ 1. 后端广播时序问题会伪装成 CSS 动画不生效

用户反馈实时 UI 元素（进度条/填充条）"不动""一直黑的""没动画"时，**先查服务端广播时机，不要默认从 CSS/JS 找原因。**

```python
# ❌ 错误时序：前端永远看不到峰值
tick():
    AP 累加            # 50→150
    _resolve_actions   # 扣 100→50
    广播               # 前端只看到 50% → "一直黑的"

# ✅ 正确时序：前端先看到峰值
tick():
    AP 累加            # 50→150
    广播               # 前端看到 100% → 开始动画
    _resolve_actions   # 扣 100→50（下次广播才回缩）
```

诊断：① 在广播调用前打印数据值 ② 检查广播与状态变更的先后 ③ 浏览器 DevTools Network/Console 看收到的数值是否真的在变。一次 tick 内广播两次 → 前端只看到最终值，动画永不触发。

> **经验（2026-06-22 AP 填充条）：** 以为是 CSS 颜色太暗，实际是 `_broadcast_battle_status` 排在 `_resolve_actions` 之后。把广播挪到 resolve 之前即解决。

### ⚠️ 2. Evennia 命令中不要等裸 "yes" 做确认

不要设 `caller.ndb._expecting_xxx` 状态后等玩家输入裸 `yes` —— Evennia 的命令解析器不会把裸 `yes` 路由到你的命令，会报"「yes」不是可用命令"。

**正确做法：让玩家重复输入完整命令**（如 `skills forget X` 连续输入三次：第一次开始、第二次确认、第三次执行）。在 `func()` 开头检查 pending 状态，输入匹配 pending 的子命令+参数则推进，否则取消。

详见 `references/evennia-command-interaction-patterns.md`（模式 1：双重确认）。

### ⚠️ 3. NPC show_if 不防关键词直访 + complete_quest 不防重复

两个叠加漏洞：
1. `show_if` **只在 `ask <npc>`（无关键词）列选项时检查**，玩家直接 `ask npc 关键词` 会绕过守卫
2. `complete_quest` action **不检查 `quest_states[quest_key] == "completed"`**，每次重新发奖励

交付分支必须在**三个层面**防护：`show_if` 守卫、`conditions` 验证、`complete_quest` 防重检查。详见 `references/evennia-npc-quest-and-inventory-pitfalls.md`。

> **教训（2026-07-23）：** 铁匠上线后同时发现两个 bug：矿石不移除 + 任务可重复刷精铁剑。

### ⚠️ 4. `random.choices` 动态权重求和为零

权重从数据字段动态提取时（`affix_weights = [a.get("rarity", 50) for a in pool]`），如果某条数据该字段为 0，且池中所有可用数据权重都为 0，`random.choices()` 抛 `ValueError: Total of weights must be greater than zero`。

```python
# ❌ 危险：存在 rarity=0 的数据就炸
weights = [a.get("rarity", 50) for a in pool]
# ✅ 安全：最小权重为 1
weights = [max(a.get("rarity", 50), 1) for a in pool]
```

> **教训（2026-07-22 推演词条抽取）：** 玩家投入 0 资源后 `_draw_affix_candidates` 报错，一行 `max(..., 1)` 修复。

### ⚠️ 5. 代码行为查询：先读文件，再回答

**顺序铁律：先 `read_file` / `search_files` → 再组织回答。** 说了"让我看看代码"之后必须立刻执行工具调用，不能继续写文字。

任何代码路径、文件名、参数名、行为逻辑的结论，都必须有实际工具输出支撑。模拟场景时先读源文件确认真正逻辑，再推演——**不要先写答案再找代码支持。**

> **教训（2026-06-22 推演幻觉）：** 被问推演系统的文件结构时，没读任何文件就列出了 `commands/character/deduce.py`、`world/deduce_system.py` 等路径，全部不存在，还继续编造了 `yanxiu` 命令和研读逻辑。连续纠正 3 轮才真正开始读代码。

### ⚠️ 6. 小改动也要走完整流程，不要因为"改得快"跳过验证

容易自己给自己找的理由："只是改个常量值 / 加几行 / 换个字符串，不值得走流程"。

**判据：只要改动改变玩家体验或系统行为（CSS 渲染、JS 行为、命令/后端逻辑、Config 逻辑），就必须走完 Phase 3 的自检清单。** 唯一例外：纯静态数据变更（YAML/JSON/TOML 的常量值、静态数据表），不改变程序逻辑 —— 那也需要语法验证。

> **教训（2026-06-23）：** 被要求加心法替换功能时直接 patch 了 `skill_menu.py` 和 `idle_tasks.py`（121 行），被当场抓包"为什么跳过流程"。判断标准应该是："如果这个改动有 bug，用户会觉得是谁的问题？"

### ⚠️ 7. 框架源码在项目目录外时的隔离手法

需要读 Evennia/Django 等框架源码来理解底层行为，但框架安装目录在项目目录之外时：

1. **在项目内建 symlink 指向框架源码**，并**必须加 `.gitignore`**：
   ```bash
   ln -s /home/qn/projects/evennia /home/qn/projects/XunDaoMUD/_evennia_ref
   echo "_evennia_ref" >> .gitignore
   ```
2. 需要长期参考的框架 API 行为，整理进 skill 的 `references/` 而不是每次重新翻源码

---

## 参考文件

- `evennia-attribute-vs-field-access.md` — Evennia 的 Attribute 系统（`db.*`）与模型字段属性（`.key`/`.aliases`/`.destination`）的区别。误用 `room.db.key = "xxx"` 替代 `room.key = "xxx"` 会导致重启后 `db_key` 未变更的 data-loss bug。**所有 Evennia 任务前先扫此文。**
- `evennia-goldenlayout-routing.md` — Evennia 浏览器客户端消息路由链：GoldenLayout 插件链、消息类型路由、`updateMethod` 行为、Evennia 标记处理时机、自定义组件注册、flex 陷阱，以及 ASCII 文本 vs JSON 卡片两种面板方案的架构选择。
- `evennia-tickerhandler-gotchas.md` — TickerHandler 的 ndb store_key 陷阱：non-persistent ticker reload 后 ndb 丢失导致 ticker 孤儿化。
- `evennia-command-interaction-patterns.md` — 命令交互模式：双重确认（forget）、clickable 选择面板（eq picker）、技能详情快捷操作、研读后自动激活、状态标志存储位置。
- `evennia-command-confirm-patterns.md` — 多步确认陷阱：ndb 状态标志 + 裸 "yes" 输入的 cmdhandler 路由失败，及重复命令确认的修复模式。
- `evennia-npc-quest-and-inventory-pitfalls.md` — NPC/任务/背包常见陷阱：show_if 绕过、重复交付、双重数量追踪。
- `evennia-combat-effect-pitfalls.md` — **（23.6K，战斗改动必读）** 战斗效果管线陷阱：HOT/DOT at_tick 误用 `target.hp` 而非 `target.db.hp` 导致引擎卡死、`_apply_effects` 双重结算、TickerHandler 静默吞异常、`db.hp = value` 调用链（DbHolder → AttributeHandler → Django ORM）、防御值初始化回退链、**`_ensure_ndb` 漏初始化导致 `getattr(ndb, ..., [])` 返回 None**（Evennia ndb 不抛 AttributeError）、**玩家输入期间全局时停设计模式**。
- `evennia-global-script-pitfalls.md` — 全局脚本陷阱：`self.owner` 仅存在于对象型脚本，全局脚本用 `self.db` 存数据，及读写脚本数据的查询模式。
- `evennia-battle-panel-frontend-tricks.md` — 战斗面板前端技巧：CSS `background-size` 实现 AP 进度条（无额外 DOM）、下一个行动者边框闪烁动画、后端广播与前端状态联动的时序关系。
- `evennia-map-cards-flex-layout.md` — 地图面板十字卡片布局的 flex 陷阱：非对称横向出口（只有 west 或只有 east）导致 Center 卡片偏离竖线，及用 JS 插入等宽 spacer 的修复方案。
- `combat-reactive-effects.md` — 战斗管线受击触发效果（`on_hit`）扩展模式：DodgeStackEffect 设计、Effect hook 注册、管线改动清单、词条模板格式。
- `code-maintenance-checks.md` — 代码维护检查模式：AST 未用 import 检测、缺失换行扫描、Evennia 颜色一致性审计（分层法）、批量清理提交流程。
- `xundao-content-design.md` — **（33K）** 寻道 MUD 内容设计模式：命名风格、稀有度池、物品模板格式、药材系统案例。
- `game-balance-design.md` — 数值设计工作流：代码公式提取 → 多路径场景 → 迭代提案。含 Python 模板与推演门槛 5 轮迭代案例。
- `game-balance-design`（独立 skill）— 同上工作流的完整版。
- `docs/PLAYER_ATTR_REFERENCE.md`（项目文档）— 玩家属性体系全参考：一级/二级属性、公式曲线（血量/攻击/防御/境界倍率）、伤害管线、五行抗性、升级成长、怪物模板结构。做战斗/怪物/技能数值设计前必读。

---

## 沟通风格（用户偏好）

| ❌ 不要 | ✅ 要 |
|:-------|:-----|
| "好问题"、"说得对"、"这个问题问得好" 等捧哏开头 | 直接接正题 |
| 先评价再回答的客套模式 | 直接给信息或分析 |
| 无意义过渡句（"好嘞！"、"没问题！"） | 保留自然口语节奏，删掉拖沓开场 |

**交付纪律：** 不编造。不确定就说不确定；没验证就说不没验证。宁可说"我搞不定"，也不要给一个像模像样的假答案。

---

## 本 skill 自身的验证

```bash
# 确认参考文件都还在
ls ~/.hermes/skills/software-development/code-task/references/
# 确认 skill 能被 Hermes 加载
hermes skills list | grep code-task
```
