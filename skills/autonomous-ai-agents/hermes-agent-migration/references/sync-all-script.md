# sync-all.sh — 全能同步参考

## 位置

`~/.hermes/scripts/sync-all.sh`

## 作用

Cron 调用的 no_agent bash 脚本，每天凌晨 2 点执行两个同步任务。

## 设计原则

1. **no_agent 模式**：不用 LLM，纯 bash 脚本，零 token 消耗
2. **自包含**：脚本内部设置所有路径，不依赖交互式环境变量
3. **幂等**：检测到无变化则不 commit/push，不产生空提交
4. **失败容错**：emma-skills 和 hermes-soul 是独立阶段，一个失败不影响另一个

## 关键路径

| 路径 | 用途 |
|------|------|
| `~/.hermes/hermes-agent/skills/` | Hermes 内置技能索引（对比基准） |
| `~/.hermes/skills/` | 本地所有技能（包含自定义） |
| `~/emma-skills/skills/` | 同步目标 |
| `~/hermes-soul/export-soul.sh` | 灵魂导出脚本 |
| `/tmp/hermes-soul-*.tar.gz` | 临时打包文件（脚本自动清理） |

## 旧版 LLM Cron 的教训

旧 cron 是 LLM 模式，prompt 说 "检查变化→同步"，但实际只检查了 4 个 skill 的 mtime，从不真正 git push。教训：

- **LLM cron 不适合纯机械任务**——模型会"报告"而非"执行"，因为工具调用链太长时模型倾向于简化
- **机械同步任务 → no_agent 脚本**——确定性的循环/条件/文件操作，bash 比 LLM 可靠得多
- **保留 LLM cron 给需要推理的任务**——摘要、筛选、判断"这个值不值得推"等需要语义理解的任务
