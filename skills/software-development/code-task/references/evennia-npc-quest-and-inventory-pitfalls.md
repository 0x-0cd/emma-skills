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

同时每个 item 对象也有 `item.db.quantity` 属性。

### 常见 Bug：只改对象属性，不碰 slot
```python
# ❌ 错误做法：只改了对象属性
self.db.quantity -= 1
if self.db.quantity <= 0:
    self.delete()
```
这不会更新 `caller.db.inventory` 中的 slot，导致：
- Slot 仍是 `{"dbref": deleted_id, "quantity": 1}`（非 None）
- `show_bag()` 的 `_used_slots()` 计数该 slot → 格子数不释放
- `_find_empty_slot()` 跳过该 slot → 新物品从下一格开始

### 正确做法：通过 remove_from_inventory 修改槽位
```python
# ✅ 正确：通过背包系统修改
for idx, slot in enumerate(character.db.inventory or []):
    if slot and slot["dbref"] == self.id:
        character.remove_from_inventory(idx, slot["quantity"])
        break
self.delete()
```

### 涉及的范围
这种 bug 影响**所有消耗物品的 use() 方法**：
- SkillBookItem.use() — 学习秘籍后消耗
- ElixirItem.use() — 使用丹药后消耗
- （如果有）TalismanItem.use() — 使用符箓后消耗

每个都需要用相同的模式修复。

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
