# Evennia 地图面板卡片布局陷阱

## 十字交叉布局的结构

```html
<div class="map-cards">
  <div class="map-row">[North]</div>                     <!-- row 0 -->
  <div class="map-row">[vertical-line]</div>              <!-- row 1 -->
  <div class="map-row">[West][h-line][Center][h-line][East]</div>  <!-- row 2 -->
  <div class="map-row">[vertical-line]</div>              <!-- row 3 -->
  <div class="map-row">[South]</div>                     <!-- row 4 -->
</div>
```

所有行由 flex 居中：`.map-cards { align-items: center }`，每行内部 `justify-content: center`。

## 陷阱：非对称横向出口导致 Center 卡片偏移竖线

### 现象

当房间只有 **north + east**（或 **north + west**）出口时，渲染结果中北面竖线落到了 Center 卡片和 East 卡片的空隙间，看起来像是 T 型三叉路口，而不是 "北→中心→东" 的正确拓扑。

### 根因

`display: none` 隐藏的卡片（west/left-line）完全退出 flex 流。剩余可见元素 `[Center][right-line][East]` 作为整体居中——Center 卡片不再在容器中心，而是偏左（当只有东）或偏右（当只有西）。上方/下方 2px 竖线始终在容器中心，与 Center 卡片错位。

### 修复方案

在 JS render 函数中（`renderMapCards`），横向出口不对称时向缺少侧插入等宽 `div.map-h-spacer`，利用 flex 居中的"整体推移"机制把 Center 卡片推回容器中心。

计算逻辑：

```
LINE_W = 20  /* 固定宽度，来自 CSS .map-line-h */

只有 east（west 隐藏）:
  spacerW = LINE_W + eastCard.outerWidth()
  // spacer 插入在 Center 卡片之前（.insertBefore）
  // 将整体右推，Center 回到容器中心

只有 west（east 隐藏）:
  spacerW = westCard.outerWidth() + LINE_W
  // spacer 插入在 Center 卡片之后（.insertAfter）
  // 将整体左推，Center 回到容器中心
```

关键实现细节：
- 每次 render 前清理上一轮插的 spacer（`.map-h-spacer`）
- `outerWidth()` 在 `display: block` 状态下才返回非零值，因此**必须在卡片设为 visible 之后**再测量
- 左右横向连接线（`.map-line-h`）各 20px，在 `hLines.eq(0).toggle(wVisible)` 等调用中已处理好可见性

### 为什么不用 `visibility: hidden`

`visibility: hidden` 虽然保留空间，但保留的是元素实际渲染尺寸（含 border、padding、内容）。当内容（房间名）长度不固定时，隐藏侧的空白宽度与可见侧不匹配，仍然无法对齐。

## 通用原则

### 1. flex 居中 + 动态显隐 = 中心漂移

罪魁祸首：`justify-content: center` 把子元素组看作一个整体居中。任一子元素被 `display: none` 移出流，整体重心就改变。**这是 flex 居中固有的行为，不是布局 bug。**

### 2. 用 spacer 而非 margin

`margin: 0 auto` 对 flex 子元素的行为取决于可用空间和 `justify-content` 值。等宽 spacer 是最可预测的修正方式。

### 3. JS 渲染函数中测量，CSS 中不可获知

CSS 无法知道"西侧隐藏、东侧可见"这类运行态信息。修正逻辑必须在 JS 中执行（测量 visible card 宽度 → 计算 → 插入 spacer）。

## 相关文件

- `web/static/webclient/js/plugins/goldenlayout.js` → `renderMapCards()` 函数
- `web/static/webclient/css/custom.css` → `.map-cards` / `.map-row` / `.map-card` 样式
- `utils/map_util.py` → `get_map_data()` 服务端数据准备
