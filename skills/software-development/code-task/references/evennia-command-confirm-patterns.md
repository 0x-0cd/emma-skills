# Evennia 命令多步确认模式

> Evennia 命令处理链中，玩家的原始输入经过 `cmdhandler` 解析后路由到对应 `Command.func()`。如果需要在命令执行过程中插入"确认"步骤，有几个常见陷阱。

---

## 陷阱：用 `ndb` 状态标志 + 等待 "yes" 独立输入

### 问题

```python
# 错误做法
class CmdMyCommand(Command):
    def func(self):
        confirm = self.caller.ndb._pending_confirm
        if confirm:
            if self.args.strip().lower() == "yes":
                # 执行确认后的操作
                ...
            return
        
        # 设置等待确认
        self.caller.ndb._pending_confirm = {"step": 1, ...}
        self.caller.msg("输入 yes 确认")
```

**问题根因：** 当玩家输入 "yes" 时，`cmdhandler` 找不到名叫 "yes" 的命令，报错 `「yes」不是可用命令`。`CmdMyCommand.func()` 永远不会被执行——状态标志检查根本到不了。

这是因为 Evennia 的 `cmdhandler` 在每个 tick 用**命令名匹配**来路由输入，而不是由当前命令"捕获"下一个输入。

### 修复：重复命令确认

```python
class CmdMyCommand(Command):
    def func(self):
        confirm = self.caller.ndb._pending_confirm
        if confirm:
            args = self.args.strip()
            parts = args.split(maxsplit=1) if args else []
            sub = parts[0].lower() if parts else ""
            
            if sub in ("forget", "yiwang"):  # 子命令匹配
                skill_name = parts[1].strip()
                pending_key = confirm["skill_key"]
                if skill_name == pending_key:
                    if confirm["step"] == 1:
                        # step 1 -> 2
                        self.caller.ndb._pending_confirm["step"] = 2
                        self.caller.msg("再次确认？再次输入完整命令确认")
                    elif confirm["step"] == 2:
                        # 执行
                        self.handler.forget(pending_key)
                        self.caller.ndb._pending_confirm = None
                        self.caller.msg("已执行")
                else:
                    # 不同技能名 -> 取消旧 pending 开始新流程
                    self.caller.ndb._pending_confirm = None
                    self._start_new_flow(...)
            else:
                # 其他命令 -> 取消 pending
                self.caller.ndb._pending_confirm = None
                self.caller.msg("已取消")
            return
        
        # 正常执行流程...
```

**原理：** 玩家始终输入完整的命令名（`skills forget xxx`），路由始终进入 `CmdSkills.func()`，在 `func()` 内部检查 pending 状态并判断当前子命令是否匹配。

### 适用场景

- 需要 2-3 步确认的删除/遗忘/销毁操作
- 不需要跨 session 持久化的临时交互状态

注意：这种模式适用于**文本 MUD 命令**的简单确认。如果需要复杂的多步交互菜单（分支、输入验证、动态选项），使用 Evennia 的 `EvMenu`。

---

## 正确模式：`ndb` 状态标志（当确认需要同命令触发时）

```
Round 1: command <target>
  → 设置 ndb._pending = {step: 1, target: X}
  → 提示"再次输入 command <target> 确认"

Round 2: command <target>      ← 同命令，同参数
  → 检测到 pending，step=1 → step=2
  → 提示"再次确认？再次输入以确认"

Round 3: command <target>      ← 同命令，同参数
  → 检测到 pending，step=2 → 执行
  → 清除 pending
```

**关键约束：**
- 必须在 `func()` 开头检查 pending，不能依赖"捕获输入"
- 必须能区分"新调用"和"确认调用"（通过对比参数是否匹配 pending）
- 其他命令输入时自动取消 pending（返回"已取消"）
