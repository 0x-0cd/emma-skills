# Daily Cron Prompt: Emma Soul Sync

**Cron Job ID:** `6305f00fbeac`
**Schedule:** `0 2 * * *` (daily at 02:00 Beijing time, UTC+8)
**Deliver to:** QQ (origin)
**Toolsets:** terminal, file, session_search

This prompt is self-contained — cron runs with `skip_memory=True`, so no MEMORY.md is injected.

---

## Full Prompt Text

```
【Emma 灵魂每日同步任务】

每天凌晨2点自动执行——回忆当天变化、分析是否需要更新两个仓库、执行同步。

## 你的使命

检查本机 ~/.hermes/ 中的变化，自动同步到两个 GitHub 仓库，并在完成后发送总结报告。

---

## 1️⃣ 回忆阶段

用 session_search 搜索最近 36 小时的 session，看看有没有新的重要决策、偏好变化、工作流变更。重点关注：
- 有没有新增的自定义 skill
- 有没有配置变更（provider、model 等）
- 有没有新的记忆写入

---

## 2️⃣ 分析 emma-skills 公共仓（~/emma-skills/）

检查 ~/.hermes/skills/ 中是否有不在 ~/emma-skills/skills/ 中的自定义技能。

**判断标准**：不在以下官方分类目录中的技能目录，且是 agent 创建的或 Emma 专属的：
autonomous-ai-agents/, creative/, data-science/, devops/, email/, github/,
idea-workflow/, media/, mlops/, note-taking/, productivity/, red-teaming/,
research/, smart-home/, social-media/, software-development/, superpowers/, apple/

**操作方法**：
```bash
# 查看 emma-skills 已有的技能
ls ~/emma-skills/skills/
# 查看 ~/.hermes/skills/ 下非官方分类的技能
ls -d ~/.hermes/skills/*/ 2>/dev/null | grep -v -E '(autonomous-ai-agents|creative|data-science|devops|email|github|idea-workflow|media|mlops|note-taking|productivity|red-teaming|research|smart-home|social-media|software-development|superpowers|apple)/'
# 对比差异
diff <(ls ~/emma-skills/skills/) <(ls -d ~/.hermes/skills/*/ | grep -v -E '(autonomous-ai-agents|creative|data-science|devops|email|github|idea-workflow|media|mlops|note-taking|productivity|red-teaming|research|smart-home|social-media|software-development|superpowers|apple)/' | sed 's|.*/||')
```

如果有新的自定义技能：
1. 拷贝到 ~/emma-skills/skills/ 下
2. 更新 README.md（在包含的 Skills 表格中加一行）
3. cd ~/emma-skills && git add -A && git commit -m "🔄 自动同步：新增技能 [技能名]" && git push

如果 emma-skills 的 skills 有内容更新（而非新增），也用 git commit & push 同步。

---

## 3️⃣ 分析 hermes-soul 私仓（~/hermes-soul/）

检查核心灵魂文件是否有变化（比上次 soul release 更新）：

```bash
# 检查 memory_store.db 和 config.yaml 的修改时间
ls -la ~/.hermes/memory_store.db ~/.hermes/config.yaml ~/.hermes/.env ~/.hermes/auth.json ~/.hermes/lcm.db ~/.hermes/kanban.db 2>/dev/null

# 获取上次 soul release 的时间戳
gh release list --repo 0x-0cd/hermes-soul --limit 1 --json createdAt --jq '.[0].createdAt' 2>/dev/null
```

检查方式：对比文件的 mtime 是否晚于上次 release 时间。如果 memory_store.db 或 config.yaml 有更新（时间戳比上次 release 新）：
1. cd ~/hermes-soul && git pull
2. bash export-soul.sh /tmp --upload

注意：.env 和 auth.json 通常不变，lcm.db 每天变化也正常不用每次都打包，但 memory_store.db 和 config.yaml 有变化时一定要更新。

---

## 4️⃣ 报告

在最终回复中输出一份简洁的总结报告：

```
🔮 Emma 灵魂每日同步 | 2026-06-13

🟢 emma-skills：✓ 已是最新（或 ✅ 已同步：[技能名]）
🔮 hermes-soul：✓ 已是最新（或 ✅ 已更新 Release：soul-xxx）

📋 今日无变化，一切正常～
（或者列出具体变更内容）
```

这个报告会通过 cron 自动投递到 QQ，所以直接写就行，不用调用 send_message。

---

## 重要提醒

- GitHub SSH key 已配好，git push 直接走 SSH 没问题
- gh CLI 已登录，gh release 可以直接用
- 两个仓库都是哥哥的，有 push 权限
- 如果发现可疑或不确定的情况，如实报告即可
- 不要自作主张删除已有技能或文件
```
