---
name: github-profile-design
description: "Design and build GitHub Profile README with dynamic widgets, dark/light mode, and integrated agent avatar"
version: 1.0.0
author: Emma
platforms: [linux]
metadata:
  hermes:
    tags: [GitHub, Profile, README, Design, Widgets]
    related_skills: [code-task, opencode, github-repo-management]
---

# GitHub Profile README Design

## 什么时候用

用户让你"装修"、"美化"、"更新" GitHub 个人主页（Profile README），或者问"GitHub Profile 怎么搞炫酷"。

## 前置

- 目标 GitHub 用户名已知（如 `0x-0cd`）
- Profile 仓库存在（`<username>/<username>`）
- 本地已 clone（如 `~/profile_repo/`）
> - 需要 OpenCode 小弟的帮助来生成最终 README（参考 `code-task` skill）

## 设计流程

### Step 1: 调研可用 Widget

从以下主流 widget 库中选择（先对目标用户名做实测验证）：

| Widget | 来源 | 实测要点 |
|--------|------|---------|
| **GitHub Stats** | `github-readme-stats` (79.6k⭐) | 支持 `username` 参数、自定义主题色 |
| **Top Languages** | `github-readme-stats` 同源 | 支持 `layout=compact` 或 `donut` |
| **Contribution Streak** | `github-readme-streak-stats` | 自定义 `ring`/`fire`/`currStreakLabel` 色 |
| **Trophy** 🏆 | `github-profile-trophy` | 有时 Vercel 实例会挂，备选方案 |
| **Activity Graph** | `github-readme-activity-graph` | 支持 `custom_title`、主题色全定制 |
| **Visitor Badge** | `komarev.com/ghpvc` | 或 `visitor-badge.laobi.icu`（前者更稳定） |
| **Tech Stack Badges** | `shields.io` | 使用 `style=for-the-badge` 视觉效果最好 |
| **Metrics** (终极方案) | `lowlighter/metrics` | 可生成大 infographic，但会大幅增加 README 复杂度 |

### Step 2: 测试每个 Widget

对目标账号做冒烟测试 —— 有些 widget 对特定账号可能 404 或限流：

```bash
# 测试 stats
curl -s "https://github-readme-stats.vercel.app/api?username=0x-0cd&show_icons=true" | head -5

# 测试 streak
curl -s "https://github-readme-streak-stats.herokuapp.com?user=0x-0cd" | head -5

# 测试 activity graph
curl -s "https://github-readme-activity-graph.vercel.app/graph?username=0x-0cd" | head -5

# 测试 visitor badge
curl -s "https://komarev.com/ghpvc/?username=0x-0cd"
```

> 如果某个 widget 返回的不是 SVG/图片（如 403/500/HTML），**不要硬加**到 README 里，选择备选或跳过。

### Step 3: 设计布局结构

推荐的极客风布局（自上而下）：

```
┌─ 头像 + handle + 社交链接 ─────────────────────┐
│  [头像 120px] `0x0cd` · AI Agent Engineer       │
│  Email · X · Telegram · Website  (badge 行)      │
│  _slogan_                                        │
│  └ Emma 头像 + "Co-crafted with Emma" ─────────┘ │
├─ YAML 档案卡片 ──────────────────────────────────┤
├─ Stats + Languages（双栏并排）───────────────────┤
├─ Streak（居中宽栏）──────────────────────────────┤
├─ Tech Stack Badges（居中一行行展示）──────────────┤
├─ Featured Repositories（stat-pin 卡片，2×2 或 4列）┤
├─ Activity Graph（全宽）──────────────────────────┤
├─ Footer: Visitor Counter + 版权/签名 ────────────┤
```

### Step 4: 深色/亮色自适应

使用 `<picture>` + `<source media="(prefers-color-scheme: dark/light)">` 实现双主题：

```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="...dark_params">
  <source media="(prefers-color-scheme: light)" srcset="...light_params">
  <img src="...dark_default" alt="...">
</picture>
```

各 widget 在 dark/light 下的色值参考：

| Widget | Dark | Light |
|--------|------|-------|
| Stats card bg | `bg_color=0d1117` | `bg_color=ffffff` |
| Stats text | `text_color=ffffff` | 不设（默认黑色） |
| Streak text | `currStreakLabel=ffffff` | `currStreakLabel=000000` |
| Streak dates | `dates=666666` | `dates=999999` |

### Step 5: 用 OpenCode 小弟生成 README

参考 `code-task` skill 的 prompt 模板：

```
项目在 ~/profile_repo
任务：生成 GitHub Profile README
用户名：<username>
设计风格：极客风，主题色 teal (#008c8c)，点缀色 orange (#e85827)
包含模块：
1. 头像 + handle + 社交链接（Email/X/Telegram/Website，badges 用 shields.io for-the-badge 风格）
2. YAML 档案卡片
3. GitHub Stats + Top Languages（双栏，dark/light 适配）
4. Streak（dark/light 适配）
5. Tech Stack（badges 行，Python/FastAPI/Docker/Redis/PostgreSQL/Shell/Rust/Move/Git/Linux/GitHub Actions/AI Agent）
6. Featured Repositories（用 stat-pin，dark/light 适配）
7. Activity Graph（dark/light 适配）
8. Footer 访问计数

约束：
- handle 用 `0x0cd`，不要暴露真名/位置
- 模块间用 `---` 分隔
- 所有图片链接必须用完整的 HTTPS URL
- Emma 头像放在顶部 handle 下方，加 "Co-crafted with Emma" 文字，链接到 emma-skills 仓库
- 不要放任何私有仓库到 Featured Repositories
- 所有 widget 的 URL 都要预先测试可用

完成后告诉我：改了什么文件
```

### Step 6: 用户反馈迭代

推送后等用户反馈，常见的调整点：
- **个人信息泄露** → 检查 handle 昵称、位置、邮箱等是否暴露了真实身份
- **私有仓库可见** → 检查 Featured Repos 是否引用了私仓
- **表情包太腻** → 用户可能不喜欢 🥹 之类的情感过载表情
- **头像裁切** → 确保头像裁切居中在人脸，而不是图片正中心
- **链接失效** → 所有链接（Website、社交等）点一下验证

## 头像裁切技巧

当用户提供的人物照片需要裁成正方形头像时，**不要从图片几何中心裁切**。推荐用 RGB 扫描法定位人脸：

```python
from PIL import Image
img = Image.open('input.jpg')
w, h = img.size

# 扫描中心列的颜色分布
pixels = img.load()
for y_pct in range(5, 60, 3):
    y = int(h * y_pct / 100)
    r, g, b = pixels[w//2, y]
    # sky: high B channel
    # face skin: R=220-240, G=150-180, B=150-170 (warm tones)
    # hair: dark (R,G,B < 80)
    # clothing: varies
    print(f"{y_pct}%: ({r},{g},{b})")
```

典型竖屏照片的颜色分层（从上到下）：
1. 天空/背景（高蓝通道）— 顶部 0-25%
2. 头发顶部 — 25-28%
3. 👩 脸部皮肤（暖粉调 R>220, G=150-180）— 28-34%
4. 脖子/阴影 — 34-42%
5. 衣服 — 42% 以下

裁切时：以脸部中心（通常在 30-33% 高度处）为正方形中心点，边长取人脸区域的 2-3 倍。

## 主题色方案

| 角色 | 色值 | 用途 |
|------|------|------|
| 🎨 主色 | `#008c8c` (teal) | 标题、边框、环形图、链接 |
| 🔥 点缀色 | `#e85827` (orange) | Streak fire、Graph 数据点 |
| 🌑 深色模式背景 | `#0d1117` | GitHub 默认 dark bg |
| 🌕 亮色模式背景 | `#ffffff` | GitHub 默认 light bg |

## 已知问题

1. `github-profile-trophy` 依赖 Vercel 免费实例，有时会 503/504。不要把它作为核心模块
2. `github-readme-streak-stats` 的 herokuapp 实例有冷启动延迟，首次加载会慢几秒，不影响功能
3. `komarev.com/ghpvc` 偶尔 403，此时换 `visitor-badge.laobi.icu` 作为备用
4. shields.io `for-the-badge` 风格在 badge 内容过长时会压缩文字，保持文字简短
5. Featured Repos 的 stat-pin 卡片如果用户名或仓库名写错会显示空白卡片，务必先验证

## 验证清单

在推送到 GitHub 前检查：

- [ ] 所有图片 URL 可访问（curl 验证）
- [ ] 无私有仓库出现在 Featured Repos 中
- [ ] 无个人真名/地址/电话等隐私信息
- [ ] 所有社交链接点得通
- [ ] dark/light 模式切换时每个 widget 颜色正常
- [ ] Emma 头像显示正常、裁切居中
- [ ] 用户 avatar（大图）路径正确
- [ ] profile README 长度适中（一般 100-150 行以内）
