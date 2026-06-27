# 战斗管线 — 受击触发效果（on_hit）扩展模式

> 本文件记录 XunDaoMUD 项目中为战斗系统添加"受击触发类"效果（如叠闪避、反伤、受击回血等）的完整扩展模式。

---

## 架构设计

### 效果管道图

```
_calc_raw_damage() → check_dodge() ← 使用 ndb._dodge_bonus
    ↓ (raw != 0)
_settle_damage() → [on_damage: 防御→抗性→护盾] → 写入 HP → [on_hit: 受击触发效果]
    ↓                           ↑                        ↑
  _apply_effects()             ndb.on_damage            ndb.on_hit (新)
  (每 tick, on_tick 衰减)                                + ndb.on_tick (每回合衰减)
```

### 文件改动清单

| 文件 | 改动 |
|:----|:-----|
| `typeclasses/effects/effect.py` | Effect 基类新增 `on_hit(target, damage, ctx)` hook，默认 no-op |
| `typeclasses/effects/dodge_stack.py` | **新建** — `DodgeStackEffect`：`on_hit` 叠层 + `at_tick` 衰减 |
| `typeclasses/effects/registry.py` | import + 注册新 effect_type |
| `typeclasses/combat/damage.py` | `_ensure_ndb` 初始化 `on_hit`；`_settle_damage` 写入 HP 后遍历 `on_hit`；`_register` 新增分发路径 |
| `typeclasses/combat/handler.py` | `end_combat` 清理 `ndb.on_hit` 和 `ndb._dodge_bonus` |
| `utils/combat_util.py` | `check_dodge` 将 `ndb._dodge_bonus` 加到基础闪避值 |
| `world/affix_templates.py` | 添加使用新 effect_type 的 affix 条目 |

## 具体实现参考

### Effect 基类新增 hook

```python
# typeclasses/effects/effect.py — Effect 类新增方法
def on_hit(self, target, damage: int, ctx: dict = None):
    """目标受到非 DoT 伤害结算后触发。用于受击类效果（叠层、反伤等）。"""
    pass
```

### 效果注册（_register 扩展）

```python
# typeclasses/combat/damage.py — _register 新增 on_hit 分发
if effect.eff_type in ("defense", "resistance", "shield"):
    target.ndb.on_damage.append(effect)
elif effect.eff_type == "dodge_stack":
    target.ndb.on_hit.append(effect)
    target.ndb.on_tick.append(effect)  # 同时也注册到 on_tick 做衰减
else:
    target.ndb.on_tick.append(effect)
```

### 伤害管线触发点

```python
# typeclasses/combat/damage.py — _settle_damage 尾端
self._set_hp(target, max(0, current - final))

# 受击触发效果（非 DOT 伤害）
if "dot" not in ctx.get("ignore", []):
    for eff in getattr(target.ndb, "on_hit", []):
        eff.on_hit(target, final, ctx)

return final
```

### 战斗结束清理

```python
# typeclasses/combat/handler.py — end_combat
for c in self.combatants:
    for eff in (c.ndb.on_hit or []):
        eff.at_remove(c)
    c.ndb.on_hit = None
    c.ndb._dodge_bonus = 0  # 清空临时闪避
```

### 闪避检查

```python
# utils/combat_util.py — check_dodge
def check_dodge(defender) -> bool:
    base = _get_attr(defender, "dodge", 0)
    bonus = getattr(defender.ndb, "_dodge_bonus", 0) or 0
    dodge = base + bonus
    if dodge <= 0:
        return False
    return random.randint(1, 100) <= dodge
```

### 词条模板

```python
# world/affix_templates.py — SkillType.DODGE → Rarity.TIER_1 追加
{
    "key": "灵闪·壹",
    "desc": "每次受到非 DoT 伤害叠加1层灵闪（+1闪避），每回合自动衰减1层",
    "rarity": 100,
    "effect_type": "dodge_stack",
    "effect_params": {
        "dodge_per_stack": 1,
        "max_stacks": 99,
    },
    "preconditions": {"min_level": 1},
    "mp_cost": 0,
    "sp_cost": 0,
    "cooldown": 0,
},
```

## 设计约束

- **非 DoT 限制** — DOT 伤害视为持续毒伤/灼烧，不计入"受击"事件
- **闪避已生效的攻击不触发放置** — `_calc_raw_damage` 中 `check_dodge` 成功时 `raw=0`，不会走到 `_settle_damage`，不会叠层
- **战斗结束自动清零** — `end_combat` 负责清理所有临时状态
- **衰减时机** — `_apply_effects` 每 tick 衰减 1 层，即回合结束/开始时（取决于战斗 tick 调度顺序）

## 可扩展方向

这种 `on_hit` 模式可以支持更多受击触发效果：

| 效果类型 | 触发逻辑 | 衰减逻辑 |
|:---------|:---------|:---------|
| 受击叠攻 | 受伤后 +attack | 每 tick 减半 |
| 受击反伤 | 返还一定比例伤害 | 瞬时结算 |
| 受击回血 | 受伤后回少量 HP | 内置 CD（每 N 回合触发一次）|
| 残血狂化 | HP < 30% 时触发额外效果 | 条件即衰减（HP 回上来就消失）|
