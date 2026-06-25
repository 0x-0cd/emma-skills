# Evennia 全局脚本陷阱：self.owner 不存在

## 症状

服务器启动后，全局脚本的 `at_repeat()` 报错：

```
AttributeError: 'RelicPoolMonitor' object has no attribute 'owner'
```

## 根因

Evennia 中 `create_script("path.to.ScriptClass")` **不带 `obj` 参数**创建的脚本是**全局脚本**（global script）。

全局脚本**没有 `self.owner` 属性**。`self.owner` 仅存在于**对象型脚本**（创建时传了 `obj=some_object`）。

## 修复模式

### 全局脚本内存储数据 → 用 `self.db`

```python
# ❌ 错误：self.owner 不存在
pool = self.owner.server.db.relic_pool or {"total_value": 0}

# ✅ 正确：存到自己身上
pool = self.db.relic_pool or {"total_value": 0}
```

### 从其他代码查找/读写脚本数据

用 ScriptDB 的 Django ORM 查询：

```python
from evennia.scripts.models import ScriptDB
script = ScriptDB.objects.filter(db_key="MyScriptKey").first()
if script:
    data = script.db.my_attr or {}
    script.db.my_attr = updated_data
```

也可以用 Evennia 内置搜索：

```python
from evennia.utils.search import search_script
scripts = search_script("MyScriptKey")
```

### 全局脚本 vs 对象型脚本速查

| 特征 | 全局脚本 | 对象型脚本 |
|------|---------|-----------|
| 创建方式 | `create_script("path.Script")` | `create_script("path.Script", obj=room)` |
| `self.owner` | ❌ 不存在 | ✅ 返回绑定的对象 |
| `self.obj` | 脚本自身 | 绑定的对象 |
| `self.db` | ✅ 可用 | ✅ 可用 |
| 生命周期 | 持久/不随对象删除 | 随对象删除而清理 |
| 使用场景 | 服务器级监控/定时任务 | 房间/角色绑定的行为 |

## 陷阱 2：持久化脚本 reload 后 ndb._task 未自动创建

### 症状

服务器 `evennia reload` 后，全局脚本的 DB 记录存在（`persistent=True, interval=N`），但 `at_repeat()` **从未被调用**。脚本看起来存在但不工作：

```python
# evennia shell 中检查
s = search_script("my_script")[0]
print(s.interval)                          # → 10（DB 值正确）
print(s.ndb._task)                         # → None（计时器任务不存在！）
print(s.ndb._task.running if s.ndb._task else False)  # → False
```

### 根因

Evennia 的 `DefaultScript` 使用 `ndb._task`（`LoopingCall`）来调度 `at_repeat()`。这个 `ndb` 对象是**非持久化**的，在服务器重启/reload 后**需要通过 Evennia 的脚本重启机制重新创建**。

如果 Evennia 的脚本重启流程没有成功调用 `_start_task()`，脚本的 DB 记录和 Python 类定义都存在，但**计时器没启动**，`at_repeat()` **永不触发**。

### 修复方案

#### 方案 A：删旧重建（推荐）

在 `at_server_startstop.py` 中，不只检查脚本是否存在，还要确保它正在运行：

```python
from evennia import search_script, create_script

scripts = search_script("monster_respawn")
if scripts:
    s = scripts[0]
    # 重启脚本计时器（防止 reload 后 ndb._task 未自动创建）
    try:
        s.stop()
    except Exception:
        pass
    s.start(interval=10)
else:
    create_script("typeclasses.monster_respawn.MonsterRespawnScript")
```

也可以在 shell 中手动修复：

```python
from evennia import search_script
s = search_script("my_script")[0]
s.stop()
s.start(interval=s.interval)
```

#### 方案 B：删除 old + create new（更彻底）

```python
old = search_script("my_script")
if old:
    old[0].delete()
create_script("path.to.MyScriptClass")
```

#### 方案 C：at_server_start 里每次都重启

在 `at_server_start()` hooks 中，对所有持久化全局脚本统一做一次 `stop + start`，确保计时器存在。

### 诊断步骤

```bash
cd /path/to/game
evennia shell -c '
from evennia import search_script
s = search_script("monster_respawn")[0]
print(f"interval={s.interval}")
print(f"db_interval={s.db_interval}")
print(f"task exists={s.ndb._task is not None}")
if s.ndb._task:
    print(f"task running={s.ndb._task.running}")
'
```

关键信号：`db_interval=10` + `task exists=False` = 脚本存在但没有计时器。

### 相关框架源码

```python
# evennia/scripts/scripts.py ~line 237
if not self.ndb._task:
    # 没有 LoopingCall → 创建一个
    self.ndb._task = ExtendedLoopingCall(self._step_task)
```
