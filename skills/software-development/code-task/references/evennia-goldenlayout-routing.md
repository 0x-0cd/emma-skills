# Evennia Webclient — GoldenLayout Message Routing Chain

> 关键知识：消息从 Evennia 服务器到浏览器面板的完整路径。
> 调试自定义面板（如地图）时必须理解这条链。

## 消息流总览

```
Evennia 服务器 (Python)
  ↓ caller.msg((text, {"type": "map"}))
  ↓ WebSocket (permessage-deflate 压缩)
Evennia.js (浏览器)
  ↓ 处理 ANSI 颜色 / Evennia 标记转 HTML
  ↓ 发射 "text" 事件 (args, kwargs)
plugin_handler.onText
  ↓ 按注册顺序遍历插件
goldenlayout.onText (第一个，先注册先执行)
  → routeMessage(args, kwargs) → 找到匹配面板
  → addMessageToPaneDiv(div, txt, kwargs) → 渲染
  → return true (声明事件已被处理，链停止)
```

## 关键机制

### 1. 路由规则 (`routeMessage`)

消息的 `type` 从 `kwargs["type"]` 或 `args[1]["type"]` 提取：
```python
# 服务器发送：
target.msg((text, {"type": "map"}))
# → args = [text, {"type": "map"}]
# → kwargs["type"] 或者 args[1]["type"] = "map"
```

面板匹配规则：
- 面板的 `.content` div 有 `types` 属性（如 `types="map"`）
- 消息 `type` 包含在面板 `types` 列表中的 → 路由到该面板
- 面板 `types` 包含 `"all"` → 接收所有消息
- 面板 `types` 包含 `"untagged"` → 接收无 type 标记的消息

### 2. 渲染方式 (`addMessageToPaneDiv`)

`updateMethod` 属性决定渲染行为：

| updateMethod | 行为 | 适用场景 |
|:------------|:-----|:---------|
| `"newlines"` | `<div class='out'>text</div>` 追加 | 聊天/游戏日志 |
| `"append"` | `textDiv.append(message)` 直接追加 | 需要原始 HTML 的流式输出 |
| `"replace"` | `textDiv.html(message)` 完全替换 | 地图/状态面板 |

### 3. Evennia 标记处理（重要）

`goldenlayout.onText` 在插件链中**最先注册**。当它声明事件 (`return true`) 时，后注册的 `text2html` 插件**不会执行**。

这意味着：
- **面板 `types="map"` 的消息** → goldenlayout 路由 + 声明事件 → text2html 不处理
- 面板消息中的 `|lcnorth|lt清泉镇北|le` 标记不会被自动转为 HTML `<a>` 链接
- 解决方案：自定义面板需在 JS 中自行处理 Evennia 标记，或由服务器发送 JSON + JS 动态创建 `<a>` 元素

### 4. Evennia.js 层面的处理

`Evennia.js` 库（不是插件）在发射 "text" 事件前会处理：
- ANSI 转义序列 → HTML `<span style="color: ...">`
- Evennia 标记 `|lc...|lt...|le` → `<a onclick="Evennia.msg(...)">`
- 换行符 `\n` 保持原样（交给 `white-space` CSS 处理）

任何在 `onText` 中拿到的 `args[0]` 已经是处理后的 HTML 字符串。

### 5. 自定义 GoldenLayout 组件注册

```javascript
myLayout.registerComponent("Map", function (container, componentState) {
    // 隐藏的 .content div 用于消息路由（必须）
    var hiddenDiv = $("<div class='content' types='map' updateMethod='replace' style='display:none'></div>");
    hiddenDiv.appendTo(container.getElement());
    
    // 自定义渲染结构
    var myContent = $('<div class="my-custom-panel">...</div>');
    myContent.appendTo(container.getElement());
});
```

然后在 `addMessageToPaneDiv` 中拦截特定 type：
```javascript
if (textDiv.attr("types") === "map") {
    // 解析 JSON 数据，更新自定义组件
    var data = JSON.parse(message);
    updateMyComponent(data);
    return;  // 跳过默认渲染
}
```

### 6. Flex 陷阱

多行内容（含 `\n` 或 `<br>`）的面板**不能**用 `display: flex` 容器。
`<br>` 在 flex 容器中被当作 flex 项，不会产生换行。

```css
/* ❌ 错误：flex 导致多行 ASCII/HTML 内容横排 */
.content[types="map"] {
    display: flex;           /* ← 所有行被压到一条水平线上 */
}

/* ✅ 正确：block + text-align: center + white-space: pre */
.content[types="map"] {
    display: block;
    text-align: center;
    white-space: pre;
}
```

### 7. HTML 卡片 vs ASCII 文本的架构选择

| 方案 | 数据格式 | 前端渲染 | 适用场景 |
|:----|:---------|:---------|:---------|
| ASCII 文本 | 预格式化的 `str` 含 `|lc...|le` 链接 | `white-space: pre` + `text-align: center` | 简单列表、协议输出 |
| HTML 卡片 | JSON 字符串，前端 `JSON.parse` | `createElement` / jQuery 动态构建 | 交互式 UI、需样式控制的组件 |

JSON 卡片方案的服务器端数据结构：
```python
def get_map_data(room) -> str:
    dirs = {}
    for obj in room.contents:
        if obj.destination and obj.key in ("north", "south", "east", "west"):
            dirs[obj.key] = str(obj.destination.key)
    data = {
        "center": str(room.key),
        "north": {"name": dirs.get("north", ""), "cmd": "north"} if dirs.get("north") else None,
        "south": {"name": dirs.get("south", ""), "cmd": "south"} if dirs.get("south") else None,
        "west": {"name": dirs.get("west", ""), "cmd": "west"} if dirs.get("west") else None,
        "east": {"name": dirs.get("east", ""), "cmd": "east"} if dirs.get("east") else None,
    }
    return json.dumps(data, ensure_ascii=False)
```

前端发送命令的方式：
```javascript
Evennia.msg("text", ["north"], {});
```
