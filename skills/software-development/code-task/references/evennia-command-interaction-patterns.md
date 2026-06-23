# Evennia 命令交互模式

> 适用于 Evennia MUD 游戏命令的交互设计。每次新增命令/子命令时参考。

---

## 模式 1：双重确认（Destructive Operation Confirm）

用于"删除/遗忘/解散"等不可逆操作，避免误触。

> ⚠️ **注意：不要用等待 "yes" 独立输入的方式。** Evennia 的命令解析器不会把裸 "yes" 路由到你的命令——它会找一条叫 `yes` 的命令，找不到就报错。正确的做法是让玩家**重复输入完整命令**来完成确认。

**实现方式：** `caller.ndb._expecting_xxx` 状态标志 + 在 `func()` 开头检查 + 判断当前输入是否匹配 pending 操作。

```
玩家: skills forget 破天剑诀
  → func() → forget 分支 → _forget_skill()
  → 设置 ndb._expecting_forget_confirm = {step: 1, key, name}
  → msg: "真的要遗忘「破天剑诀」吗？再次输入 skills forget 破天剑诀 确认"

玩家: skills forget 破天剑诀  (完整命令再次输入)
  → func() 开头检测到 _expecting_forget_confirm
  → 检测到子命令是 forget，技能名匹配 pending key
  → step=1 → step=2
  → msg: "再次确认？遗忘后无法恢复。再次输入以确认遗忘"

玩家: skills forget 破天剑诀  (第三次输入)
  → step=2 → 执行 handler.forget(key) → 清除状态
  → msg: "已遗忘「破天剑诀」"

玩家输入其他命令:
  → func() 开头检测到不是 forget/yiwang → 清除 pending
  → msg: "已取消遗忘"
```

**模板代码：**
```python
def func(self):
    # [在常规 args 解析之前] 检查确认状态
    confirm = caller.ndb._expecting_forget_confirm
    if confirm is not None:
        args = self.args.strip()
        parts = args.split(maxsplit=1)
        sub = parts[0].lower() if parts else ""

        if sub in ("forget", "yiwang") and len(parts) > 1:
            name = parts[1].strip()
            if name == confirm["skill_key"]:
                if confirm["step"] == 1:
                    caller.ndb._expecting_forget_confirm = {
                        "skill_key": confirm["skill_key"],
                        "skill_name": confirm["skill_name"],
                        "step": 2,
                    }
                    caller.msg("再次确认？遗忘后无法恢复。再次输入以确认遗忘")
                    return
                elif confirm["step"] == 2:
                    handler.forget(confirm["skill_key"])
                    caller.ndb._expecting_forget_confirm = None
                    caller.msg("已遗忘「{}」".format(confirm["skill_name"]))
                    return

        # 任何其他命令 → 取消 pending
        caller.ndb._expecting_forget_confirm = None
        if args:
            caller.msg("已取消遗忘")
        return

    # 正常 args 解析...
```

**要点：**
- 检查确认状态的代码必须在 `func()` 最开头，在正常 `args` 解析之前
- 确认状态在命令完成后（无论成功/取消）必须清理为 None
- step=1 和 step=2 的提示要不同，让玩家感知到这是第二次确认
- 玩家输入**任何其他命令**（包括空输入）都自动取消 pending 状态
- 匹配 pending 状态后立即 return，避免继续执行正常分支
- 如果输入的是 forget 但技能名**不匹配** pending key，视为取消旧操作 + 开始新遗忘流程

---

## 模式 2：交互式选择面板（Clickable Slot Picker）

用于让玩家从多个候选项中点击选择，替代手动输入序号。

**实现方式：** Evennia `|lc...|lt...|le` 点击链接语法。

```
玩家: skills eq 斩天剑法
  → func() 检测到第一个 token 不是数字 → 进入 picker
  → _show_eq_picker() 展示:

  ──────────────────────────
  要将「斩天剑法」装备到哪个灵技槽？
  [1] 破空斩          ← 可点击
  [2] 空               ← 可点击
  [3] 空               ← 可点击
  ...
  [8] 空
  ──────────────────────────

玩家点击 [1] → 发送 skills eq 1 斩天剑法 → 直接装备
```

**模板代码：**
```python
def _show_eq_picker(self, caller, handler, name):
    skill = handler._find_skill(name)
    if not skill:
        caller.msg("找不到技能")
        return

    active = caller.db.active_battles or []
    lines = ["要将「{name}」装备到哪个灵技槽？"]

    for i in range(MAX_SLOTS):
        slot_num = i + 1
        existing = active[i] if i < len(active) else None
        if existing:
            status = colorize(existing, RARITY_COLOR)
        else:
            status = colorize("空", N)
        link = f"|lcskills eq {slot_num} {name}|lt[{slot_num}] {status}|le"
        lines.append(link)

    caller.msg("\n".join(lines))
```

**`|lc...|lt...|le` 链接语法：**
- `|lc<命令>|lt<展示文本>|le` — 点击后发送 `<命令>`，展示 `<展示文本>`
- **重要限制：链接只能发命令，不能直接调用 Python 方法。** 如果想把某个操作做成可点击链接，该操作必须对应一个已注册的命令/子命令。
- 命令部分支持参数，如 `skills eq 1 斩天剑法`
- 展示文本可以包含颜色标记（`|y`、`|G` 等）
- 适用于列表选择、传送门、快捷操作等场景
- 在 Evennia Web 和 Telnet 客户端均有效

**典型场景（身法装备）：**
身法装备需要调用 `handler.activate(key, "dodge")`，但 clickable link 只能发命令。所以必须先新增一个子命令（如 `skills eqdodge <名>`）作为中转，然后在链接中引用它。<!-- 2026-06-23 this session -->

---

## 模式 3：技能详情页的快捷操作链接（已实现）

用于 `skills show` 展示详情后附加快捷操作按钮。

```
skills show 斩天剑法
  ─────────────────
  斩天剑法
  类型：灵技
  稀有度：三品
  ...
  效果：金系伤害+65
  ─────────────────
  [装备] [推演] [遗忘]    ← 点击执行对应操作
```

按技能类型决定可用操作：

| 技能类型 | 装备操作 |
|:---------|:---------|
| 灵技 | 发送 `skills eq <技能名>` → 调出槽位选择面板 |
| 身法 | 直接装备到 `active_dodge` |
| 心法（已是主） | 提示"已是主心法"，不重复装备 |
| 心法（已是副） | 与主心法交换（switchforce） |

推演按钮 → 发送 `tuiyan <技能名>`（占位，等待推演升级功能）
遗忘按钮 → 发送 `skills forget <技能名>` → 进入双重确认流程

---

## 通用准则

1. **保持向后兼容** — 新增行为不删除旧语法。`skills eq <槽位> <名>` 继续可用
2. **状态清理** — 使用 `ndb._expecting_xxx` 的模式必须确保在三种情况下都清理：成功、取消、超时
3. **颜色一致性** — 警告用 `COLOR_ERROR`，成功用 `COLOR_HIGHLIGHT`，普通状态用 `COLOR_NORMAL`
4. **防呆设计** — 批量操作前做前置检查（为空？已满？已存在？），给明确提示而不是静默失败
5. **状态标志存储位置** — 在 EvMenu 节点函数中存状态标志时，**不要用 `caller.ndb._evmenu._xxx`**（EvMenu 对象不支持随意设置属性）。用 `caller.ndb._xxx`（Evennia 的 `ndb` 专为临时标志设计）。<!-- 2026-06-23 node_exit _exited AttributeError -->

---

## 模式 4：研读完成后的自动装备/激活

用于定时研读完成后，根据技能类型自动执行不同操作。

**触发点：** `utils/game_util/idle_tasks.py` 的 `_study_tick()` — 当 `done >= total` 时触发。

**逻辑：** 在 `handler.learn(skill_data)` 之后，按 `skill_type` 分流：

| skill_type | 操作 |
|:-----------|:-----|
| 1（心法/FORCE） | 检查 `_pending_force_replace` 决定替换主/副 → `activate("force")` |
| 2（身法/DODGE） | `active_dodge` 为空则自动 `activate("dodge")`，否则提示用 `eqdodge` 替换 |
| 3（灵技/BATTLE）| 不自动激活（让玩家用 `skills eq` 选择槽位） |

```python
if skill_data.get("skill_type") == 1:
    # ...心法替换逻辑...
    handler.activate(skill_key, "force")
elif skill_data.get("skill_type") == 2:
    if caller.db.active_dodge is None:
        handler.activate(skill_key, "dodge")
        caller.msg(f"|G已自动装备身法「{skill_key}」。|n")
    else:
        caller.msg(f"|G已学会身法「{skill_key}」，但你已有身法在身。使用 skills eqdodge {skill_key} 来替换。|n")
```

**要点：**
- 心法自动激活到 force 槽，因为玩家已有主/副心法替换机制
- 身法仅在无已有身法时自动装备，冲突时让玩家手动处理
- 灵技/技艺从不自动激活，必须玩家手动装备（灵技需要选择槽位1-8）

---

## 模式 5：列表面板全部可点击

当 `skills` 命令展示技能列表时，所有技能名都应该可点击查看详情（`skills show <名>`），不只灵技可点击。实现方式一致：

```python
name_link = f"|lcskills show {skill_key}|lt{colorize(skill_key, RARITY_COLOR.get(skill.rarity, N))}|le"
lines.append(f"主心法：{name_link}")
```

三种类型同样处理：主心法、副心法、身法。发现某个类型的名字不可点击时，立即补齐。< !-- 2026-06-23 this session -->
