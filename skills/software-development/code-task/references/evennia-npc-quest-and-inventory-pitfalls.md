# Evennia NPC/Quest/Inventory 常见陷阱

## 1. 对话 show_if 只限制选项可见性，不限制关键词直访

### 问题
NPC 对话分支的 `show_if` 字段**只在玩家输入 `ask <npc>`（无关键词）列出选项时生效**。如果玩家直接输入 `ask <npc> 关键词`，该分支会**直接执行**，不检查 `show_if`。

### 示例
```python
"交任务": {
    "response": "...",
    "show_if": {
        "quest_flag": "quest_accepted",
        "not_flag": "turned_in",
    },
    "conditions": {"item_rarity": "TIER_1"},
    "actions": [
        {"type": "remove_items", "item_rarity": "TIER_1", "quantity": 1},
        {"type": "set_flag", "flag": "turned_in"},
        {"type": "complete_quest", "quest_key": "some_quest"},
    ],
}
```

如果玩家在完成任务后仍然有 TIER_1 物品，直接输入 `ask npc 交任务` 会跳过 `not_flag: turned_in` 检查，导致重复交付。

### 修复
在 `talk.py` 的 `CmdAsk.func()` 中，**关键词分支也检查 `show_if`**：

```python
# 先检查 show_if
if not npc._check_show_if(entry.get("show_if", {}), flags, quest_states):
    response = npc.db.default_response
elif _check_conditions(caller, entry.get("conditions", {})):
    _execute_actions(caller, entry.get("actions", []))
    response = entry.get("response", npc.db.default_response)
else:
    response = entry.get("else_response", npc.db.default_response)
```

### 保护规则
- **永远不要在 `show_if` 放唯一的安全检查** — `conditions` 和 `complete_quest` 内部也要做状态验证
- 两个 NPC 的交付分支（铁匠+镇长）都曾因此问题可重复刷奖励

---

## 2. complete_quest action 不检查任务是否已完成

### 问题
`_execute_actions` 的 `complete_quest` 分支没有检查 `caller.db.quest_states[quest_key] == "completed"`。每次执行 `complete_quest` action 都会重新检查 completion_triggers 并发放奖励。

### 修复
在 `complete_quest` 分支开头加入：

```python
if caller.db.quest_states.get(quest_key) == "completed":
    caller.msg(f"|Y任务「{quest_key}」已经完成了。|n")
    continue
```

### 完整体检清单
每次新增 NPC 交付任务时检查：
- [ ] `complete_quest` action 是否防重复（系统级，一次修复全局生效）
- [ ] 对话分支的 `show_if` 是否有 `not_flag` 守卫
- [ ] `conditions` 是否验证了交付条件
- [ ] actions 中是否设置了交付完成 flag
- [ ] actions 顺序：complete_quest 最好在 remove_items 之前（配合防重复检查）

---

## 3. 自定义 Inventory 系统的双重数量追踪

### 数据结构
`XunDaoMUD` 使用自定义背包系统，每个 slot 是：
```python
# caller.db.inventory: list[dict | None]
slot = {"dbref": item.id, "quantity": N}  # N 是堆叠数量
```

同时每个 item 对象也有 `item.db.quantity` 属性——但**背包显示只读 slot["quantity"]**。

### 常见 Bug：改对象属性，不碰 slot
```python
# ❌ 错误做法：只改对象属性
self.db.quantity -= 1
if self.db.quantity <= 0:
    self.delete()
```
这不会更新 `caller.db.inventory` 中的 slot，导致：
- Slot 仍是 `{"dbref": deleted_id, "quantity": N}`（数量不变）
- 若 item 已 `delete()`，slot 变成悬空指针
- `show_bag()` 读 slot["quantity"] 显示旧值 → 数量"没少"
- `_find_empty_slot()` 跳过该 slot → 格子不释放

### 区分两种消耗模式

#### 模式 A：单颗消耗（丹药、符箓等）— 一次用 1 个
```python
# ✅ 正确：从背包扣 1，数量归零时清理 slot + 删 item
for idx, slot in enumerate(caller.db.inventory or []):
    if slot and slot["dbref"] == self.id:
        caller.remove_from_inventory(idx, 1)  # 只减 1，不是 slot["quantity"]
        # 如果整堆用完，remove_from_inventory 已清理 slot
        if caller.db.inventory[idx] is None:
            self.delete()
        break
```
注意：
- 传入 `1`（消耗量），**不是** `slot["quantity"]`（整堆数量）——后者会清空整堆
- `remove_from_inventory` 会在 `slot["quantity"] <= quantity` 时自动将 slot 设为 None

#### 模式 B：整堆消耗（秘籍等）— 一次用完整个堆叠
```python
# ✅ 正确：整堆消耗
for idx, slot in enumerate(caller.db.inventory or []):
    if slot and slot["dbref"] == self.id:
        caller.remove_from_inventory(idx, slot["quantity"])
        self.delete()
        break
```
秘籍学习是一次性的——学会后整本秘籍不再需要，直接整堆清空。

### 为什么两种模式不能混用
把模式 A 传整堆数量（给 `remove_from_inventory` 传 `slot["quantity"]`）会导致：
- 5 颗丹药，用 1 颗 → 整堆 5 颗全消失
- 玩家损失 4 颗
- `self.delete()` 删对象，但 slot 已被清空 → 看不出 bug

**2026-06-25 实证案例：** `ElixirItem.use()` 只改了 `self.db.quantity` 没碰 slot。`bag` 显示读 slot，所以永远显示旧值。修复方案是将 `remove_from_inventory` 调用放在 `use()` 方法中（即模式 A）。

### 涉及的范围
这种 bug 影响**所有消耗物品的 use() 方法**，因为 `use()` 只接收 `self` 和 `caller`，默认只改自身属性：
- **ElixirItem.use()** — 单颗消耗（丹药），需模式 A
- **SkillBookItem.use()** — 整堆消耗（秘籍），需模式 B
- **TalismanItem.use()** — 单颗消耗（符箓），需模式 A（如果实现）

检查清单：每个 `use()` 实现都要确认它是否同步更新了 `caller.db.inventory` 中的 slot。

---

## 4. remove_items action 的 item_rarity 参数

### 用途
当 NPC 对话需要移除玩家背包中的"任意一块一阶物品"而不是特定模板时，使用 `item_rarity`：

```python
{"type": "remove_items", "item_rarity": "TIER_1", "quantity": 1}
```

### 实现逻辑
在 `_execute_actions` 的 `remove_items` 分支中（约 914-927 行）：

```python
elif rarity_name:
    target = Rarity[rarity_name]  # Rarity.TIER_1
    for idx, slot in enumerate(caller.db.inventory or []):
        if slot is None:
            continue
        item = ObjectDB.objects.filter(id=slot["dbref"]).first()
        if item and item.db.rarity == target:
            _remove_items_from_inventory(caller, item.db.template_key, qty)
            break
```

### 注意事项
- `Rarity` 继承自 `Enum`（不是 `IntEnum`），比较时 `Rarity.TIER_1 == 1` 返回 `False`
- `item.db.rarity` 通过 Evennia Attribute 系统存储/读取，如果序列化丢失枚举类型信息会导致比较失败
- 需要确认 `_remove_items_from_inventory` 中使用 `orig_qty = slot["quantity"]` 在 `remove_from_inventory` 之后仍然可访问（浅拷贝保护）

---

## 5. 交互式面板 + 动态 CmdSet 锁定模式

### 适用场景
当需要一个"进入交互模式 → 操作 → 退出"的多步流程（如出售面板、交易、制作），期间需要锁定其他命令。

### 实现模式

```python
class MyLockCmdSet(CmdSet):
    key = "MyLock"
    priority = 101          # 高于普通 CmdSet 的 100
    no_exits = True         # 不转发到父 CmdSet
    def at_cmdset_creation(self):
        self.add(CmdMyCommand())

# 进入交互模式：
caller.cmdset.add("path.to.MyLockCmdSet", permanent=False)

# 退出交互模式：
caller.cmdset.remove("MyLock")
```

### 状态一致性保护
在命令入口处做状态修正：
```python
def func(self):
    has_lock = caller.cmdset.has("MyLock")
    has_state = bool(caller.ndb.my_state)
    if has_state and not has_lock:
        caller.cmdset.add("path.to.MyLockCmdSet", permanent=False)
    elif not has_state and has_lock:
        caller.cmdset.remove("MyLock")
```

### sell 命令的完整示例（已验证）
见 `commands/character/sell.py` 的 `CmdSell` 和 `SellLockCmdSet`。锁定时序：
- `sell <编号>` / `sell all` → 购物车非空时 `cmdset.add(SellLockCmdSet)`
- `sell confirm` / `sell cancel` / `sell clear` → `cmdset.remove("SellLock")`
