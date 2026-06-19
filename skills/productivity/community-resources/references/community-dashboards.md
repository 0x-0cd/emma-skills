# Community Hermes Dashboards / Web UIs

Two community web dashboards exist as alternatives to the Hermes CLI/TUI. Both are MIT-licensed, self-hosted, and read from `~/.hermes/`.

## hermes-hudui (joeynyc)

**定位:** 意识监控器 / 仪表盘 (read-only visualization)

| 属性 | 值 |
|------|-----|
| GitHub | https://github.com/joeynyc/hermes-hudui |
| 技术栈 | Python (FastAPI) + Node.js (Vite + Tailwind) |
| 端口 | 3001 |
| 安装 | `git clone` → `./install.sh` → `source venv/bin/activate && hermes-hudui` |
| 页面数 | 18 tabs |
| 特色 | Hermes Replay (可审计的会话回放+导出), 5套主题, 中英双语, 键盘快捷键 |
| 社区 | ~131 commits, 11 releases |

**18 tabs:** Executive Dashboard, Identity, Memory, Skills, Sessions, Cron, Projects, Health, Costs, Model Analytics, Patterns, Corrections, Sudo Governance, Live Chat, OAuth, Gateway, Plugins, Model Capabilities

## Hermes Control Interface / HCI (xaspx)

**定位:** 管理控制台 (read-write control panel)

| 属性 | 值 |
|------|-----|
| GitHub | https://github.com/xaspx/hermes-control-interface |
| 技术栈 | Vanilla JS + Vite + Express + WebSocket |
| 端口 | 10274 |
| 安装 | `git clone` → `cp .env.example .env` → `npm install && npm run build` → `node server.js` |
| 页面数 | 11 pages |
| 特色 | 实时聊天, 文件浏览器, MCP管理器 (启停+日志), RBAC权限 (3角色20权限), Swarm监控, Token分析+预算告警, PWA |
| 社区 | ~267 commits, 25 releases, 12 contributors |
| 安全 | bcrypt密码, CSP (no unsafe-eval), CSRF, 限流 |

**11 pages:** Home, Chat, Agents, Office (ZOO Swarm), Monitor, Usage, Logs, Skills, Files, MCP, Maintenance

## 对比总结

| 维度 | hermes-hudui | HCI |
|------|-------------|-----|
| 读/写 | 基本只读 | 读写都有 |
| 能聊天 | 仅看对话流 | 真·流式聊天, 多profile |
| 能操作文件 | ❌ | ✅ 文件浏览器+编辑器 |
| 能管理MCP | ❌ | ✅ 完整控制面板 |
| RBAC | ❌ | ✅ 3角色20权限 |
| 主题换肤 | ✅ 5套 | ❌ |
| 中英双语 | ✅ | ❌ |
| 社区活跃度 | 较低 | 更高 |

两个可以同时运行 (端口不同), 互不冲突。
