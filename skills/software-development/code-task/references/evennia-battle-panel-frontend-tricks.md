# Evennia 战斗面板前端技巧

## 用 CSS background 实现角色卡片 AP 进度条

### 原理
不引入额外 DOM 元素，直接利用角色卡片自身的 `background-image` + `background-size` + CSS 变量实现可变宽度填充。

```css
.battle-card {
    background-color: #2a2a2a;                                    /* 基础暗色（无填充） */
    background-image: linear-gradient(to right, #3a3a3a, #3a3a3a); /* 填充浅灰 */
    background-repeat: no-repeat;
    background-size: var(--ap-pct, 0%) 100%;                     /* JS 控制此变量 */
    transition: background-size 0.6s ease;                        /* 平滑过渡 */
}
```

JS 端只设 CSS 变量，不直接操作 background-size：

```javascript
// setCard() / makeCard() 中：
card[0].style.setProperty("--ap-pct", entry.ap + "%");
```

### 优势
- 无需加新 DOM 元素（性能好）
- CSS transition 自动处理动画
- 与资源条（`transition: width 0.3s ease`）速度独立，可以设不同时间

### 注意事项
- 填充色与底色对比度要足够。`#2a2a2a`→`#3a3a3a` 仅 8% 亮度差，视觉上几乎看不出。建议至少差 20%+（如 `#333`→`#555`）
- `background-size` 的 transition 只对百分比值变化响应，首次设 `--ap-pct` 不会触发动画
- `card[0].style.setProperty(...)` 使用原生 DOM 而非 jQuery，因为 `card.css('--ap-pct', ...)` 不工作

## 下一个行动者边框闪烁

```css
@keyframes border-flash {
    0%, 100% { border-color: #555; }
    50%      { border-color: #fc6; }   /* 暖金色 */
}

.battle-card-next {
    animation: border-flash 0.8s ease-in-out infinite;
}
```

JS 切换：

```javascript
function setNextActor(battlePanel, nextActorName) {
    battlePanel.find(".battle-card").removeClass("battle-card-next");
    if (nextActorName) {
        var escaped = nextActorName.replace(/"/g, "&quot;");
        battlePanel.find('.battle-card[data-name="' + escaped + '"]')
            .addClass("battle-card-next");
    }
}
```

## 后端广播时机与前端状态联动

战斗面板的 AP 填充动画依赖于广播时机。详见 `evennia-combat-effect-pitfalls.md` 的"广播时机 → 前端 AP 可视化"一节。

关键记忆点：
- **广播在 `_resolve_actions` 之前** → 前端看到峰值（满格）
- **玩家 AP 在行动后扣除** → 命令发出才回缩，等待期间保持满格
- **超时扣 AP 兜底** → 防止无限超时循环
