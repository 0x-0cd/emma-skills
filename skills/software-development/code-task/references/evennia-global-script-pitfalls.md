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
