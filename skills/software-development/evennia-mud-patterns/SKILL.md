---
name: evennia-mud-patterns
description: "Evennia MUD 开发陷阱与模式：ndb 行为、持久化脚本生命周期、战斗处理器流程、数据流追踪技巧。适用于 XunDaoMUD 及其他 Evennia 项目的 bug 调试与系统设计。"
version: 1.0.0
author: Emma
license: MIT
metadata:
  hermes:
    tags: [evennia, mud, game-dev, python, xundao]
    related_skills: [code-task]
---

# Evennia MUD 开发模式

> 本文档记录在 XunDaoMUD 开发过程中发现的 Evennia 框架级陷阱、修复模式与设计约定。

---

## 🪤 Evennia ndb 陷阱

### 问题

`getattr(obj.ndb, "key", default)` 在属性存在但值为 `None` 时**不会回退到默认值**。

这是因为 Evennia 的 `ndb`（NickleDB）不抛 `AttributeError`——访问不存在的属性返回 `None`，访问被显式设为 `None` 的属性也返回 `None`，Python 的 `getattr` 无法区分这两种情况。

```python
# ❌ 错误写法 — 当 c.ndb.on_tick 被显式设为 None 时爆炸
for eff in getattr(c.ndb, "on_tick", []):

# ✅ 正确写法 — None 被 or 截获，回退到空列表
for eff in (c.ndb.on_tick or []):
```

### 适用范围

所有 ndb 存储的列表/字典属性都适用此规则，包括：
- `on_tick` — tick 效果列表
- `on_damage` — 受伤效果列表
- 任何自定义 ndb 列表属性

### 真实案例

- `handler.py` 战斗结束时 `end_combat` 设 `c.ndb.on_tick = None`，第二次调用时 `getattr(c.ndb, "on_tick", [])` 返回 `None` → `TypeError: 'NoneType' object is not iterable`
- Chrome 提交 `bbd3dba`（双杀修复）

---

## 🔄 持久化脚本生命周期

### 问题

Evennia 的全局持久化脚本（`persistent=True`）在 `evennia reload` 后，DB 记录（`interval`、`persistent` 标志等）幸存，但**内存中的计时器（`ndb._task`，即 Twisted `LoopingCall`）不会自动重建**。

```python
# 效果：脚本的 DB 存在，at_repeat() 永远不触发
SearchScript("monster_respawn")  # → 找到记录
script.interval                  # → 10 （从 DB 恢复）
script.ndb._task                 # → None （没有被重建！）
```

### 修复模式

在 `at_server_start()` / 服务器启动回调中，**无论脚本是否已存在，都调用 `script.start()` 确保计时器跑起来**：

```python
scripts = search_script("monster_respawn")
if scripts:
    scripts[0].start(interval=10)   # ← 重启计时器
else:
    create_script("typeclasses.monster_respawn.MonsterRespawnScript")
```

### 适用范围

所有带 `interval` 的全局持久化脚本都需要此防护：
- `MonsterRespawnScript`
- `AggressionMonitorScript`
- `RelicPoolMonitor`
- `GameTimeScript`
- 任何自定义 `interval` 脚本

### 真实案例

- `at_server_startstop.py` 原写法只检查"脚本是否在 DB"，不在才创建
- reload 后脚本存在但 `ndb._task` 没启动 → 所有怪物刷新停止
- Chrome 提交 `8454471`（四脚本统一修复）

---

## ⚔️ 战斗处理器双杀模式

### 问题

`CombatHandler` 在多处独立检测到同一方死亡后都会调用 `end_combat()`，第二次调用时已经在已清理的状态上操作。

### 调用链

```
_monster_action()
  ├─ _resolve_skill_effects() → 检测到死亡
  │    └─ end_combat() ← 🥇 第一次调用，设置 ndb 为 None
  │    └─ return
  └─ 返回后再次检测 HP≤0
       └─ end_combat() ← 🥇🥇 第二次调用，ndb 已清空
            └─ for eff in (c.ndb.on_tick or []) → 不炸
```

### 修复方案（双保险）

1. **根本修** — `_monster_action()` 调用 `_resolve_skill_effects` 后，检查 `self.player.ndb.combat_handler` 是否为 None。如果已为空，直接 `return`，防止第二次 `end_combat`

2. **防御修** — `end_combat` 和 `_apply_effects` 中所有 ndb 列表读取改用 `(c.ndb.on_tick or [])` 替代 `getattr(...)`

### 真实案例

- `handler.py:158` → `for eff in (c.ndb.on_tick or []):`
- Chrome 提交 `bbd3dba`

---

## 📐 数据流追踪技巧

调试 Evennia 项目时按以下顺序追踪数据流：

1. **命令层** — `commands/` 下的 `Cmd*.func()` → 输入入口
2. **类型类** — `typeclasses/` → 核心逻辑（物品、角色、战斗）
3. **ndb vs db** — `self.db.*` 是持久化的（存入 DB），`self.ndb.*` 是内存级的（reload 后丢失）
4. **框架源码** — 怀疑框架行为时追 Evennia 源码（`site-packages/evennia/`）：
   - `scripts/scripts.py` → `ScriptBase.start()` / `at_repeat()` 的 LoopingCall 生命周期
   - `objects/objects.py` → `DefaultObject.db` / `ndb` 的 `AttributeProperty` vs `TagProperty`
   - `commands/cmdhandler.py` → 命令解析和调度

---

## 🧪 验证清单

Evennia 项目的改动至少验证以下三项：

- [ ] 语法检查：`python -c "import py_compile,glob;[py_compile.compile(f,doraise=1) for f in glob.glob('**/*.py',recursive=1) if '__pycache__' not in f]"`
- [ ] 加载检查：`evennia reload` 后服务器启动无报错
- [ ] 逻辑验证：在 shell 中手动触发脚本并检查状态（`search_script` / `obj.db.*` 查询）

---

## 🧩 效果系统扩展模式

在 Evennia MUD 中扩展效果系统（添加新的 Effect 类型）有一套固定模式：

### 扩展步骤

1. **创建 Effect 子类** — 在 `typeclasses/effects/` 下新建文件，继承 `Effect`，覆写 `at_apply` / `at_remove` / `at_tick` / `filter_damage` / `on_hit` 等 hook
2. **注册到 EFFECT_CLASSES** — 在 `typeclasses/effects/registry.py` 中 import + 追加映射
3. **添加到战斗管线** — 选择合适的 ndb 列表：
   - `on_damage` — 受伤时拦截伤害（防御、抗性、护盾）
   - `on_tick` — 每回合触发效果（DOT/HOT、buff 衰减）
   - `on_hit` — 受伤后执行副作用（叠层、触发条件）
   - `on_heal` — 治疗时拦截（预留）
4. **注册到战斗初始化** — `_register(target, effect)` 按 `eff_type` 自动投递到合适的列表
5. **清理** — `end_combat` 遍历所有 ndb 列表调用 `at_remove`

### 关键：钩子选择

```python
# Effect 基类提供的 hook，按阶段分类：

# 生命周期 hooks（由引擎调度）
at_apply(caster, target)    # 效果施加时
at_remove(target)           # 效果移除时（战斗结束/到期）
at_tick(target) → bool      # 每回合触发，return False 表示到期

# 管线 hooks（由战斗引擎遍历调用）
filter_damage(damage, ctx)  # 伤害拦截（在 HP 写入前）
on_hit(target, damage, ctx) # 受伤后副作用（在 HP 写入后）
filter_heal(heal)           # 治疗拦截（预留）
```

### 真实案例

- `dodge_stack` 效果（灵闪·壹）：`on_hit` 叠闪避层，`at_tick` 每回合衰减
- Chrome 提交 `b34aff1` 和 `1cff841`

---

## ⚠️ 被动效果不会自动进入战斗管线

### 问题

通过 `SkillHandler.activate()` 创建的效果存储在 `obj.ndb.passive_effects` 中，但**不会自动出现在战斗管线的 `on_tick` / `on_damage` / `on_hit` 列表中**。

### 数据流断点

```
SkillHandler.activate()
  └─ create_effect() → eff.at_apply(owner, owner)
  └─ owner.ndb.passive_effects.append(eff)    ← 只存在这里
                                                     ↓
CombatHandler.__init__()
  └─ _init_defensive_effects()                 ← 只创建防御/抗性
  └─ 没有扫描 passive_effects                  ← ❌ 断点！
```

### 修复模式

在战斗初始化时增加一步扫描 `passive_effects`，将战斗相关的效果注册到管线：

```python
def _init_skill_effects(self):
    """为玩家注册被动技能的战斗效果"""
    for eff in getattr(self.player.ndb, "passive_effects", []) or []:
        if eff.eff_type == "dodge_stack":
            eff.at_apply(self.player, self.player)  # 重设战斗初始状态
            self._register(self.player, eff)          # 注册到 on_tick + on_hit
```

### 边界情况

- **多场战斗**：每次战斗开始时重新注册，结束时清理
- **效果重复注册**：`_register` 只追加，`_ensure_ndb` 惰性初始化，要求 `end_combat` 必须清理 ndb 列表
- **状态重置**：`at_apply` 在每次战斗开始时重新初始化（如 `ndb._dodge_bonus = 0`）

### 判断条件

一个被动效果是否需要战斗注册：
- ✅ 它需要在 `at_tick` / `filter_damage` / `on_hit` 中做事情 → 需要注册
- ❌ 它只修改 `db.*` 基础属性（如 锻骨 +max_hp）→ 不需要注册

---

## 🚧 Exit 拦截 + Item-Flag 通行模式

### 场景

当需要实现 **"从某房间的任何出口离开都要触发事件"** 且 **"使用特定物品后获得永久通行权"** 时，Evennia 中有成熟的实现模式。

### 架构

```
┌──────────────────────────────────────────────┐
│  at_traverse (exits.py)                       │
│    ┌─ source_location.key == "清源河"           │
│    │   ├─ db.qingyuan_river_ward 有?           │
│    │   │   ├─ YES → 放行 + 提示                │
│    │   │   └─ NO  → _do_river_intercept()      │
│    │   │         ├─ 叙事文本                   │
│    │   │         ├─ 检查怪物池 → 取1只/强制生成  │
│    │   │         └─ 完整 CombatHandler 启动    │
│    │   └─ (正常通行)                           │
└──────────────────────────────────────────────┘
```

### 模式拆解

#### 1. Room-Gated Exit Interception（房间门控出口拦截）

在 `Exit.at_traverse` 中检查玩家的**当前所在房间**，而非 exit 上的属性：

```python
def at_traverse(self, traversing_object, target_location):
    source_location = traversing_object.location
    # ... tutorial_block 拦截 ...

    # 清源河门控：检查房间名，不是 exit 属性
    if source_location and source_location.key == "清源河":
        if traversing_object.db.qingyuan_river_ward:
            # 有标记 → 放行提示
            traversing_object.msg(...)
        else:
            # 无标记 → 拦截 + 自动战斗
            self._do_river_intercept(traversing_object, source_location)
            return

    # 原始通行逻辑...
    if traversing_object.move_to(...):
        self.at_post_traverse(...)
```

**判断标准：** 用 `source_location.key` 而非 `self.db.river_guard` 属性。当拦截逻辑与房间绑定（所有从该房间出去的 exit 都触发）而非与特定出口绑定时，房间名判读更简洁且不需要改 world_builder。

#### 2. 自动战斗触发（复用 CmdBattle 模式）

完整流程（参考 `commands/character/attack.py:100-130`）：

```python
def _do_river_intercept(self, traversing_object, source_location):
    # 已有战斗 → 提醒
    if traversing_object.ndb.combat_handler:
        traversing_object.msg(...)
        return

    # 叙事提示
    traversing_object.msg("河中怪鱼突然跃出水面...")

    # 取怪物：优先从房间怪物池拿，池空则强制实例化
    pools = source_location.db.monster_pools or {}
    fish_data = pools.get("河中怪鱼")
    if fish_data and fish_data.get("quantity", 0) > 0:
        despawn_monsters(source_location, "河中怪鱼", 1)
        monster = spawn_combat_monster("river_monster_fish", combat_id=1)
    else:
        monster = spawn_combat_monster("river_monster_fish", combat_id=1)

    if not monster:
        return

    # 影子房间 + CombatHandler（完全复用 CmdBattle 流程）
    shadow = create_shadow_room(source_location)
    enter_shadow_room(traversing_object, shadow)
    monster.move_to(shadow, quiet=True)
    handler = CombatHandler(
        player=traversing_object,
        monsters=[monster],
        shadow_room=shadow,
        source_room=source_location,
        template_keys={monster.key: "river_monster_fish"},
        on_start=lambda: traversing_object.cmdset.add(...),
        on_end=lambda: traversing_object.cmdset.delete(...),
    )
    handler.start()
```

**关键细节：**
- `despawn_monsters` 参数用 **display_name**（"河中怪鱼"），不是 template_key
- `spawn_combat_monster` 参数用 **template_key**（"river_monster_fish"）
- 怪物池为空时（全被杀光还未刷新）直接 `spawn_combat_monster` 兜底，不阻塞玩家
- 战斗结束后 `destroy_shadow_room` 自动将玩家送回源房间

#### 3. Item-Flag 标记系统（elixir_effects marks 模式）

在丹药效果系统中增加"标记"字段，使用后设置持久化 db 属性：

**数据定义（`world/elixir_effects.py`）：**
```python
"凝神": {
    "key": "凝神",
    "desc": "凝神静气，稳固修为。",
    "effect_type": "add_cultivation",
    "effect_value": 500,
    "marks": ["qingyuan_river_ward"],  # ← 新增
},
```

**标记处理（`typeclasses/items/elixir_item.py`）：**
```python
# effect 主效果处理完成后...
for mark_key in effect.get("marks", []):
    setattr(caller.db, mark_key, True)
```

**数据流：** `elixir_effects.py` 定义 mark 列表 → `elixir_item.py` 通过 `setattr(caller.db, ...)` 写入 → `exits.py` 在 `at_traverse` 中读取 `db.qingyuan_river_ward`

**注意事项：**
- 标记必须是 `db.*`（持久化），不能用 `ndb.*`（服务器重启后丢失）
- 同一个 effect 可以设置多个标记（`marks: ["flag_a", "flag_b"]`）
- 标记名称使用带模块前缀的 snake_case（如 `qingyuan_river_ward`）

### 适用场景

- **区域门控**：玩家必须完成某事件才能通过
- **Boss 前哨**：击败某怪物 + 使用信物后放行
- **剧情锁**：脚本触发临时封锁，完成任务后标记放行

### 边界情况

| 场景 | 处理 |
|------|------|
| 玩家已在战斗中 | 提示"先结束当前战斗"，不触发拦截 |
| 怪物池为空 | `spawn_combat_monster` 强制实例化 |
| 玩家逃跑 | 回源房间，再次尝试仍触发 |
| 掉落率不足100% | 允许多次触发直到获得道具 |
| 标记已获得 | 放行提示+正常移动 |

### 与 existing tutorial_block 模式的差异

| 维度 | tutorial_block | river_intercept |
|------|:-------------:|:---------------:|
| 拦截条件 | exit 上的 `db.tutorial_block` 属性 | source_room 的 key 值 |
| 触发行为 | 教学对话后原地不动 | 自动进入战斗 |
| 通过条件 | 对话完成后即解除（一次性）| 永久 `db` 标记（永不过期）|
| 覆盖范围 | 单个 exit | 来源房间的所有 exit |

---

## 🔍 OpenCode 多文件交付的数据流验证

### 问题

OpenCode 实现多文件功能改动时，**每个文件的语义正确性通常没问题**，但容易遗漏跨文件的初始化/注册步骤。

### 典型遗漏模式

```
文件 A: 创建了新效果类 ✓
文件 B: 注册到 EFFECT_CLASSES ✓
文件 C: 修改了战斗管线 ✓
        但: 谁负责在战斗开始时把效果注册到管线？← ❌ 遗漏
```

这种 Bug 不会在**语法检查**中暴露——每行 Python 都合法，但运行时效果永远不触发。

### 验证流程

收到 OpenCode 交付后，手动追踪完整运行时数据流：

```
创建 → 注册 → 触发 → 清理

1. 效果对象在哪个文件、由谁创建？
2. 它被添加到哪个 ndb 列表？
3. 这个列表被谁遍历、在什么时机？
4. 清理时谁移除它？
```

### 每类效果的标准生命周期

| 效果类型 | 创建者 | 注册时机 | ndb 列表 | 清理者 |
|---------|--------|---------|---------|-------|
| 被动属性词条（锻骨、凌厉） | SkillHandler.activate | 装备时 | 无（直接改 db） | SkillHandler.deactivate |
| 防御/抗性 | CombatHandler | 战斗开始 | on_damage | end_combat |
| DOT/HOT/shield | CombatHandler._resolve_skill_effects | 技能施放 | on_tick / on_damage | end_combat + at_tick 到期 |
| **被动战斗效果（dodge_stack）** | SkillHandler.activate | **战斗开始**_init_skill_effects | on_hit + on_tick | end_combat |

### 真实案例

- dodge_stack 效果：OpenCode 正确实现了 Effect 类、注册表、管线修改，但忘了加到战斗初始化中
- Chrome 提交 `1cff841` 补上了缺失的 `_init_skill_effects`
