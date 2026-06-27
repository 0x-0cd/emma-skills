# Evennia Combat Effect Pipeline Pitfalls

## Problem 1: HOT/DOT at_tick 直接写 `target.hp` 而非 `target.db.hp`

### 症状
使用带 HOT/DOT 词条的技能后，战斗引擎卡死——怪物不行动、玩家无法操作（"现在不是你的回合"），或 HP 更新不同步。

### 根因
`HOTEffect.at_tick` 和 `DOTEffect.at_tick` 中写的是：

```python
# ❌ 错误：在 Evennia 6.0 中这只是普通 Python 实例属性赋值
target.hp = min(target.hp + self.value, target.max_hp)
target.hp = max(0, target.hp - self.value)
```

Evennia 6.0 不再有 `DefaultObject.__setattr__` 代理到 db 的机制。`target.hp = x` 只是设置了 `target.__dict__['hp'] = x`，而战斗引擎的 `_get_hp()` 读的是 `target.db.hp`——**两个不同的数据源**。

而 `HealEffect.at_apply` 和 `DamageEffect.at_apply` 正确使用了 `target.db.hp = ...`。

### 修复
```python
# ✅ 正确：让战斗管线统一处理 HP 变更
def at_tick(self, target) -> bool:
    return super().at_tick(target)  # 只做倒计时
```

## Problem 2: _apply_effects 管线双重结算

### 症状
HOT/DOT 每 tick 加血/扣血两倍（如果你用错了 `target.hp` 直接写，可能表现为完全不生效）。

### 根因
`CombatHandler._apply_effects()` 已经通过 `_settle_heal(c, eff.value)` 和 `_settle_dot(c, eff.value)` 管线处理了 HOT/DOT 的 HP 变更（使用正确的 `_set_hp` 方法通过 `combatant.db.hp` 写入）。然后又调用了 `eff.at_tick(c)`，而 at_tick 又做了一遍相同的操作。

```python
def _apply_effects(self):
    for eff in getattr(c.ndb, "on_tick", []):
        if eff.eff_type in ("dot", "hot"):
            self._settle_heal(c, eff.value)  # ← 管线已经处理了
            ...

        alive = eff.at_tick(c)  # ← at_tick 又做一遍（双重结算！）
```

### 原则
**Effect 子类的 `at_tick` 只负责倒计时/到期逻辑，不负责 HP 变更。** HP 变更是战斗引擎管线的职责。

## Problem 3: _init_defensive_effects 中防御值来源

`_init_defensive_effects` 读取防御值的回退链：

```python
def_val = getattr(c.db, "defense", None)
if def_val is None:
    def_val = getattr(c.ndb, "defense", 100)  # 默认 100
```

对于怪物（未初始化 db.defense 时），会回退到 ndb.defense 或默认 100。确认怪物模板中是否设置了正确的防御值。

## Problem 4: TickerHandler 静默吞异常 — 卡死不崩溃

### 症状
战斗引擎卡死，但 `_broadcast_battle_status` 仍在被调用（玩家能看到状态刷新）。Log 中可能有一个 `log_trace()` 的输出（容易被忽略）。

### 根因
Evennia 的 `TickerHandler` 在回调执行时，**用 `try/except` 包裹了所有回调调用**，异常被 `log_trace()` 捕获后 **继续调度下一个 tick**，不会停止 ticker。

这意味着 `tick()` 中**任何位置的异常**（包括 `_apply_effects` 中途、AP 累加之前）都会：
1. 被 `log_trace()` 捕获并写入日志
2. ticker 继续跑下一个 tick
3. 但 `tick()` 内的代码从中断点之后的逻辑**全部跳过**（AP 不累加、`_resolve_actions` 不执行）
4. 状态面板仍可能更新（如果广播在异常之前已经完成，或从 `_waiting_for_input` 分支发出）

### 为什么 `_waiting_for_input` 再也不会变
如果异常发生在 `_apply_effects()` 之后、`_waiting_for_input` 检查之前，或者发生在 AP 累加循环中：

```
tick():
  _apply_effects()    ← 异常在这里 → TickerHandler 吞掉
  if _waiting_for_input: ← **永远不会执行**
  AP accumulation...  ← **永远不会执行**
  _resolve_actions()  ← **永远不会执行**
  broadcast           ← **永远不会执行**
```

但 ticker 仍然调度下一个 tick，下一个 tick 又在相同位置抛异常……形成**无限死循环**——ticker 跑、抛异常、被吞、再跑，但战斗状态永远不动。

### 调试方法
1. 即使 `_broadcast_battle_status` 仍在工作，检查 Evennia 日志（`server/logs/`）中是否有 `log_trace()` 输出
2. 在 `tick()` 开头加显式日志：`self.player.msg(f"tick #{n} waiting={self._waiting_for_input}")`，看 tick 是否真在跑
3. 在 `_apply_effects()` 的 `_settle_heal` / `_settle_dot` 调用周围加粗粒度的 `try/except` 日志定位具体异常源

## Problem 5: `_ensure_ndb` 漏了 `on_heal` 初始化 → `getattr(obj.ndb, "on_heal", [])` 返回 None

### 症状
使用 HOT 词条的技能后，第一 tick 就开始报 `TypeError: 'NoneType' object is not iterable`。TickerHandler 静默吞异常，战斗卡死。

### 根因

Evennia NdbHolder 的 `__getattr__` 实现会**拦截所有属性访问**，对未显式赋值的属性返回 `None` 而不是抛出 `AttributeError`。

```python
# Python 标准行为：属性不存在 → AttributeError → getattr 返回默认值
getattr(obj, "on_heal", [])  # ✅ 如果 obj 没有 on_heal，返回 []

# Evennia ndb 行为：属性不存在 → NdbHolder 返回 None → getattr 收到 None
getattr(obj.ndb, "on_heal", [])  # ❌ 返回 None，因为 ndb 拦截了 AttributeError
```

所以 `_settle_heal` 的代码：
```python
for eff in getattr(target.ndb, "on_heal", []):
    heal = eff.filter_heal(heal)
```
——这里的 `getattr(..., [])` 永远救不了你。只要 `on_heal` 从来没被初始化过（ndb 第一次访问时返回 None），`getattr` 就永远返回 `None`。

### 修复
在 `_ensure_ndb()` 中补上 `on_heal` 的初始化，跟 `on_tick` / `on_damage` 保持一致：

```python
def _ensure_ndb(self, combatant):
    if combatant.ndb.on_tick is None:
        combatant.ndb.on_tick = []
    if combatant.ndb.on_damage is None:
        combatant.ndb.on_damage = []
    if combatant.ndb.on_heal is None:   # ← 新增
        combatant.ndb.on_heal = []      # ← 新增
```

### 原则
**所有 Evennia ndb 列表属性的惰性初始化必须使用 `is None` 判断 + 显式赋值，不能依赖 `getattr(..., [])` 兜底。** 因为 ndb 不抛 AttributeError。

相关代码路径：
- `damage.py:_ensure_ndb` — 初始化 `on_tick`/`on_damage`/`on_heal`
- `damage.py:_settle_heal` — 遍历 `on_heal`
- `damage.py:_register` — 调用 `_ensure_ndb`

## Problem 6: `combatant.db.hp = value` 的 Evennia 内部调用链可能抛异常

### 症状
与 Problem 4 相同（异常被 TickerHandler 吞掉），但根因在 Evennia 属性系统的内部。

### 完整的调用链

```
_apply_effects()
  → _settle_heal(player, value)         # damage.py:77
    → _set_hp(target, current + final)  # combatant.py:69
      → target.db.hp = hp               # 触发 DbHolder.__setattr__
        → DbHolder.__setattr__("hp", hp)          # attributes.py:1460
          → self.attributes.add("hp", hp)          # AttributeHandler.add
            → backend.get("hp")                    # Django ORM 查数据库
            → if exists: backend.update_attribute(...)
            → else: backend.create_attribute(...)  # SQL INSERT
```

### 可能抛异常的场景
- **Django `ObjectDoesNotExist`** — 如果 Evennia 对象的 DB 引用过期（极罕见）
- **类型序列化失败** — 如果值类型 Evennia 的 `SaverAttribute` 框架不支持
- **数据库锁定/并发** — SQLite 在极端并发下可能 `OperationalError("database is locked")`

任何这些异常都会穿过 `_set_hp` → `_settle_heal` → `_apply_effects` → `tick()` → 被 TickerHandler 吞掉。

### `_set_hp` 的 hasattr 检查是伪守卫

```python
def _set_hp(self, combatant, hp: int):
    if hasattr(combatant, "db") and hasattr(combatant.db, "hp"):
        combatant.db.hp = hp
    else:
        combatant.ndb.hp = hp
```

`DbHolder.__getattribute__` 对所有属性名都委托给 `AttributeHandler.get` 并返回结果（或 None），**不会抛出 `AttributeError`**（`attributes.py:1453-1458`）。所以 `hasattr(combatant.db, "hp")` 永远为 True，else 分支实际是死代码。

如果 `db.hp` 写入失败需要兜底，应改为 `try/except` 模式而非 `hasattr` 检测。

## Problem 7: 死亡检测双重触发 → 二次 end_combat 崩溃

### 症状
怪物杀死玩家后，出现 TypeError 使角色被销毁：

```
File "handler.py", line 313, in _monster_action
    self.end_combat(winner=alive_monsters[0] if alive_monsters else None)
File "handler.py", line 158, in end_combat
    for eff in getattr(c.ndb, "on_tick", []):
TypeError: 'NoneType' object is not iterable
```

随后 Evennia 输出 `Your character xxx has been destroyed.`

### 根因
战斗引擎中有**两个独立的位置**都会检测玩家死亡并调用 `end_combat`：

1. **`_resolve_skill_effects()` 内部**（怪物 caster 分支，约 539-541 行）— 怪物打出伤害后，检测到玩家 HP≤0，第一次调用 `end_combat`
2. **`_monster_action()` 返回后**（约 311-313 行）— `_resolve_skill_effects` 返回后再次检测 HP，第二次调用 `end_combat`

第一次 `end_combat` 执行了 `c.ndb.on_tick = None` 清理效果列表。第二次 `end_combat` 尝试迭代时，`c.ndb.on_tick` 已经是 `None`，`for eff in None` → `TypeError`。

### 修复方案

**方案 A：`_monster_action` 加守卫（根本修）**

在 `_resolve_skill_effects` 调用后、再次死亡检测之前，检查 `self.player.ndb.combat_handler`。如果战斗已经结束（handler 已被清理），直接 return：

```python
self._resolve_skill_effects(skill, handler=None, caster=monster)

# 守卫：_resolve_skill_effects 内可能已经调过 end_combat 了
if not self.player.ndb.combat_handler:
    return

if self._get_hp(self.player) <= 0:
    alive_monsters = [m for m in self.monsters if self._get_hp(m) > 0]
    self.end_combat(winner=alive_monsters[0] if alive_monsters else None)
```

**方案 B：防御性读 ndb（兜底修）**

`end_combat` 和 `_apply_effects` 中所有遍历 ndb 列表的地方，改用 `or []` 防止 None：

```python
# 改前（即使有 getattr 默认值也没用——ndb 不抛 AttributeError）
for eff in getattr(c.ndb, "on_tick", []):
    ...

# 改后（兜底 None → 空列表）
for eff in (c.ndb.on_tick or []):
    ...
for eff in (c.ndb.on_damage or []):
    ...
```

**推荐两处都改（双保险）。**

### 关联陷阱

- **Problem 5** 解释了为什么 Evennia ndb 的 `getattr(ndb, "attr", [])` 不会回退到默认值
- 所有读 `c.ndb.on_tick` / `c.ndb.on_damage` 的地方都应使用防御性读取

## 涉及文件

| 文件 | 职责 |
|:----|:-----|
| `typeclasses/combat/handler.py` | 战斗引擎主逻辑：tick、_apply_effects、_resolve_actions、end_combat |
| `typeclasses/combat/damage.py` | DamageMixin：伤害管线、治疗管线、防御初始化 |
| `typeclasses/combat/combatant.py` | CombatantMixin：属性 getter/setter（_get_hp/_set_hp 等） |
| `typeclasses/effects/hot.py` | HOTEffect at_tick |
| `typeclasses/effects/dot.py` | DOTEffect at_tick |
| `typeclasses/effects/heal.py` | HealEffect（示例：正确使用 target.db.hp） |
| `typeclasses/effects/damage.py` | DamageEffect（示例：正确使用 target.db.hp） |
| `typeclasses/effects/effect.py` | Effect 基类：at_apply/at_remove/at_tick/on_hit 默认实现 |
| `typeclasses/effects/dodge_stack.py` | DodgeStackEffect：受击叠闪避模式，on_hit+at_tick |
| `typeclasses/effects/registry.py` | EFFECT_CLASSES 注册表 |

## 调试技巧

当战斗引擎卡死时：

1. **检查 `_waiting_for_input` 是否卡在 True**（tick 不累加 AP）
2. **检查 `_current_actor` 和 `_waiting_for_input` 是否一致**（都设/都清）
3. **检查 TickerHandler 是否还在运行**：`evennia.TICKER_HANDLER.all_display()` 或查日志
4. **查 Evennia 日志中的 `log_trace()` 输出** — 如果 TickerHandler 吞了异常，日志中会有 traceback。日志路径：`server/logs/`。这是排查"卡死不崩溃"的第一步骤。
5. **在 `tick()` 开头加显式日志**：输出版本号 + `_waiting_for_input` 状态，看 tick 是否真的在每次都被调用
6. **三层 try/except 日志定位法**（已验证有效）：
   - **第 1 层** — `tick()` 整体包 `try/except`，日志标记"战斗tick异常"。确认异常是否从 tick 内部抛出。
   - **第 2 层** — `_apply_effects()` 内每个 effect 独立 `try/except`，输出 `eff.key + eff.eff_type + target`。精确定位是哪个效果在哪个目标身上炸了。
   - **第 3 层** — `_set_hp()` 内 `db.hp = hp` 和 `ndb.hp = hp` 各自包 `try/except`。确认是属性写入失败。
   
   所有日志走 `logger.log_trace()`，这样输出完整的调用栈到 Evennia 日志文件。
7. **在 `_apply_effects()` 的 `_settle_heal` / `_settle_dot` 周围加 `try/except`**：捕获并打印异常，确认是否是 `db.hp = value` 写入失败
8. **确认所有 Effect 子类的 `at_tick` **不直接操作 HP/MP/SP**，只做倒计时
9. **确认 HOT 治疗目标**：`_get_target("hot")` 永远返回 `self.player`（施法者自己）。如果治疗目标写到了错误的 combatant 身上，`_set_hp` 可能报错（如目标只有 ndb 值而没有 db.hp）
10. **检查 Evennia ndb 列表属性的惰性初始化** — 如果在 `_ensure_ndb` 中漏了某个列表（如 `on_heal`），`getattr(obj.ndb, attr, [])` 会因为 ndb 拦截 AttributeError 返回 `None` 而非 `[]`。

## 设计模式：玩家输入期间全局时停

### 动机
玩家打字操作期间（`_waiting_for_input = True`），DOT/HOT/buff 的每 tick 结算仍在推进。如果玩家打字慢/挂机，DOT 可以在一次输入间隙内跳完所有回合，玩家没机会反应。

### 方案
将 `_apply_effects()` 从 `tick()` 顶部挪到 `_waiting_for_input` 检查之后：

```python
def tick(self):
    # 死亡判定（不变）
    ...

    # [时停门] 玩家操作期间：全局静止
    if self._waiting_for_input:
        # 超时检查、刷面板、return（跳过 _apply_effects 和 AP 累加）
        ...

    # 只有不在等待输入时才推进效果
    self._apply_effects()

    # 技能冷却、AP 累加、行动解析...
    ...
```

### 效果
| 场景 | 改前 | 改后 |
|------|------|------|
| 玩家打字 60s | DOT 跳 60 次 | 全局静止，安全 |
| 怪物连动（同 tick） | effect 只推进一次 | 不变（effect 本来就在 tick 级别推进） |
| 超时跳过 | effect 已推进才跳 | 超时后下个 tick 正常推进 |

### 适用条件
- 战斗引擎使用 TickerHandler 驱动的 tick 循环（非实时回合制）
- `_apply_effects` 方法本身是无副作用的（多次调用安全）
- 玩家和怪物共用同一个 tick 循环

### 架构参考：Effect 管线完整流程

### 注册 → 遍历 → 清理全链路

理解整个 pipeline 对设计新效果类型至关重要：

```
_create_defensive_effects()  [战斗开始时]
  └─ DefenseEffect(key="防御") → _register → ndb.on_damage ✓
  └─ ResistanceEffect(金/木/水/火/土) → _register → ndb.on_damage ✓

_init_skill_effects()                                      [战斗开始时]
  └─ for eff in ndb.passive_effects:
       └─ dodge_stack → at_apply + _register → on_tick + on_hit ✓

_register(target, effect):
  if eff_type == "dodge_stack"          → ndb.on_tick + ndb.on_hit
  elif eff_type in ("defense", "resistance", "shield") → ndb.on_damage
  else → ndb.on_tick

_tick():                                              [每回合]
  └─ _apply_effects():
       └─ for eff in ndb.on_tick:
            └─ dot/hot → _settle_dot / _settle_heal (经管线写 HP)
            └─ eff.at_tick(target) → 到期检测 / 衰减逻辑

  └─ _resolve_actions():
       └─ _resolve_skill_effects():
            └─ _settle_damage(target, raw, ctx):
                 └─ for eff in ndb.on_damage:
                 │    └─ defense:  eff.filter_damage(damage)
                 │    └─ resistance: eff.filter_damage(damage, ctx)
                 │    └─ shield:    eff.filter_damage(damage)
                 └─ HP 写入
                 └─ for eff in ndb.on_hit:   ← 受击后触发副作用
                 │    └─ dodge_stack: eff.on_hit(target, final, ctx)
                 └─ 死亡检测 → end_combat

end_combat():                                           [战斗结束]
  └─ for eff in ndb.on_tick:   eff.at_remove(target)
  └─ for eff in ndb.on_damage: eff.at_remove(target)
  └─ for eff in ndb.on_hit:    eff.at_remove(target)   ← 新增清理
  └─ ndb.on_tick = None
  └─ ndb.on_damage = None
  └─ ndb.on_hit = None                                  ← 新增清理
  └─ ndb._dodge_bonus = None                            ← 新增清理
```

### 管线中的钩子点

| 阶段 | 遍历的列表 | 调用的方法 | 返回值用途 |
|------|-----------|-----------|-----------|
| 受伤前 | `ndb.on_damage` | `filter_damage(damage, ctx)` | 修改伤害值（防御/抗性/护盾） |
| 每 tick | `ndb.on_tick` | `at_tick(target)` | bool：是否继续存活 |
| 战斗结束 | 两个列表 | `at_remove(target)` | 无（清理副作用，还原属性） |

### 当前管线「能做什么」&「不能做什么」

| 能力 | 状态 |
|:----|:----:|
| **受伤前拦截伤害**（防御/抗性/护盾） | ✅ `ndb.on_damage` → `filter_damage` |
| **每 tick 持续效果**（DOT/HOT/buff 衰减） | ✅ `ndb.on_tick` → `at_tick` |
| **受击后触发副作用**（叠层/反击） | ✅ `ndb.on_hit` → `on_hit`（见下文） |
| **攻击者视角钩子** | ❌ 暂无 |
| **filter 执行顺序控制** | ❌ 靠注册顺序，无优先级字段 |

### 扩展管线：添加"受击触发"效果

已实现。以下以「幻影·壹」受击叠闪避为例，说明完整的扩展模式：

#### 修改的组件

| 组件 | 改动 |
|:----|:-----|
| `effect.py` | Effect 基类新增 `on_hit(target, damage, ctx)` hook，默认 pass |
| `dodge_stack.py` | **新建** — `DodgeStackEffect` 覆写 `on_hit`（叠层）+ `at_tick`（衰减） |
| `registry.py` | 注册 `"dodge_stack": DodgeStackEffect` |
| `damage.py` | `_ensure_ndb` 初始化 `ndb.on_hit`；`_register` 特殊分支同时注册到 `on_tick`+`on_hit`；`_settle_damage` 在 HP 写入后遍历 `on_hit` |
| `handler.py` | `_init_skill_effects()` 战斗初始化时扫描被动效果并注册；`end_combat` 清理 `on_hit`+`_dodge_bonus` |
| `combat_util.py` | `check_dodge` 读取 `ndb._dodge_bonus`；`_classify_effects` 特殊显示层数 |
| `affix_templates.py` | 身法 TIER_1 追加词条 |

#### 核心模式

```python
# 1. Effect 子类
class DodgeStackEffect(Effect):
    eff_type = "dodge_stack"
    
    def on_hit(self, target, damage, ctx=None):
        # 非 DOT 伤害才触发
        if "dot" in (ctx or {}).get("ignore", []):
            return
        # 叠层（存到 ndb 临时属性）
        bonus = getattr(target.ndb, "_dodge_bonus", None) or 0
        target.ndb._dodge_bonus = bonus + self.meta.get("dodge_per_stack", 1)
    
    def at_tick(self, target) -> bool:
        # 每回合衰减
        per_stack = self.meta.get("dodge_per_stack", 1)
        bonus = getattr(target.ndb, "_dodge_bonus", None) or 0
        target.ndb._dodge_bonus = max(0, bonus - per_stack)
        return True  # 永远活跃，战斗结束才清理
    
    def at_remove(self, target):
        target.ndb._dodge_bonus = None

# 2. _register 双列表注册
def _register(self, target, effect):
    if effect.eff_type == "dodge_stack":
        target.ndb.on_tick.append(effect)   # 用于衰减
        target.ndb.on_hit.append(effect)    # 用于触发
    elif effect.eff_type in ("defense", "resistance", "shield"):
        target.ndb.on_damage.append(effect)
    else:
        target.ndb.on_tick.append(effect)

# 3. CombatHandler 桥接被动效果
def _init_skill_effects(self):
    for eff in getattr(self.player.ndb, "passive_effects", []) or []:
        if eff.eff_type == "dodge_stack":
            eff.at_apply(self.player, self.player)  # 重置状态
            self._register(self.player, eff)

# 4. check_dodge 读取临时加成
def check_dodge(defender) -> bool:
    base = _get_attr(defender, "dodge", 0)
    bonus = getattr(defender.ndb, "_dodge_bonus", None) or 0
    # 5. 显示处理：不放入 permanent，改为显示层数

    ```python
    def _classify_effects(combatant):
        ...
        if eff.eff_type == "dodge_stack":
            bonus = getattr(combatant.ndb, "_dodge_bonus", None) or 0
            per_stack = eff.meta.get("dodge_per_stack", 1)
            stacks = bonus // per_stack if per_stack else 0
            if stacks > 0:
                buffs.append({"key": eff.key, "turns": stacks})
            continue
    ```

    **关键细节：**
    - 不能用 `permanent` 列表（前端永久标签无 turns 显示）
    - 不能用 `eff.duration` 控制（dodge_stack 的 duration=0 会误入 permanent）
    - 层数放在 `turns` 字段中，前端渲染为 `key✕turns`
    - 层数=0 时不发送条目，避免显示 ×0
    - 前端 buff 渲染逻辑固定为 `b.key + '✕' + b.turns`，所以 key 必须保留原始名（"幻影·壹"），层数通过 turns 传递

#### 关键陷阱

- **被动效果桥接**：`SkillHandler.activate()` 创建的效果存在 `ndb.passive_effects` 中，但**战斗开始时不会自动注册到战斗管线**。需要 `_init_skill_effects()` 显式扫描和注册。
- **不能只注册到 `on_damage`**：`filter_damage` 的返回值必须代表修改后的伤害，在其中做叠层副作用会污染语义。必须拆到独立的 `on_hit` 管线。
- **`end_combat` 清理**：所有自建 ndb 属性（`on_hit`、`_dodge_bonus`）都必须在 `end_combat()` 中清理，否则会跨战斗残留。
- **显示处理**：`duration=0` 的效果默认进入 permanent 列表（UI 永久显示），但 dodge_stack 应该显示层数而非永久标记。需要在 `_classify_effects` 中特殊处理。

## 设计模式：广播时机 → 前端 AP 可视化

### 问题
战斗面板用背景填充显示 AP 进度时，前端永远看不到"满格"状态。因为 AP 涨到阈值后立即被 `_resolve_actions` 扣除，广播总是在扣除之后。

```
tick():
  AP 累加        → 50→150
  _resolve_actions → 扣100→50
  广播           → 前端只看到 50%（永远显示半格）
```

### 方案一：广播提前到 resolve 之前

将 `_broadcast_battle_status()` 从 `_resolve_actions()` 之后移到之前：

```python
tick():
  AP 累加
  广播             ← 前端看到 AP 峰值（满格）
  _resolve_actions  ← 扣除 AP，可能设等待输入
```

前端在收到满格数据后，CSS `transition` 完成填充动画（0.6s）。下一个广播（1s 后 tick 或玩家行动后）再发送扣减后的值，动画回缩。

### 方案二：延迟玩家 AP 扣除到行动之后

`_resolve_actions()` 中选到玩家时**不扣 AP**，只设等待输入。等玩家真正发出 `attack`/`skill` 指令并在技能结算后，再由 `do_attack`/`do_skill` 扣 AP。

```python
# _resolve_actions()
if self._is_player(actor):
    # 不扣 AP，等玩家实际发出指令后再扣
    self._waiting_for_input = True
    return

# 怪物：立即扣 AP 并行动
self.ap[id(actor)] -= ACTION_THRESHOLD
self._monster_action(actor)

# do_attack / do_skill
self._resolve_skill_effects(skill, handler)
self.ap[id(self.player)] -= ACTION_THRESHOLD  # ← 执行后才扣
self._waiting_for_input = False
```

**边案例——超时兜底：** 超时处理中必须扣 AP（`self.ap[id(self.player)] -= ACTION_THRESHOLD`），否则超时后 `_resolve_actions` 又会选中同样的玩家，造成无限超时循环。

### 时序对比（改后）

| 阶段 | 前端看到 | 原因 |
|------|---------|------|
| AP 从低涨到高 | 背景渐涨 | tick 广播 > CSS transition |
| AP 满了，轮到玩家 | 满格浅灰 + 金色边框闪烁 | 等待输入期间不扣 AP，下个 tick 刷面板保持满格 |
| 玩家发出指令 | 边框停止闪烁，背景从满格回缩 | do_attack/do_skill 扣 AP 后广播 |
| 等待输入超时 | 满格→回缩 | 超时处理扣 AP 后广播 |
