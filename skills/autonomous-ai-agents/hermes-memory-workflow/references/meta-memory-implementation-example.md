# Meta-Memory Implementation Example

A concrete worked example of converting a 2,065-char fact-dump MEMORY.md into a ~762-char pure 元记忆 (meta-memory) index, with supporting fact_store population. Based on a real session with user "哥哥".

## Before: Fact-Dump MEMORY.md (2,065 chars)

```
哥哥杭州(UTC+8)苏州人，早8晚12。无雷区可互怼不爆粗。专业任务详细其他简练。
§
在做AI Agent跨设备记忆专利(云侧+端侧)。结论：按属性切分+跨设备同步+联合推理无人覆盖...
§
VPN: clash+mihomo(HTTP:7890 SOCKS:7891香港)。clashctl先source脚本。GitHub: SSH/gh v2.94...
§
书单：《资本论》《跟大卫·哈维读<资本论>》。自学先行(B站/Z-Lib)，我负责把关补充，不推买书。
§
Provider：主opencode-go/deepseek-v4-flash，辅助deepseek-v4-flash，vision走xiaomi/mimo-v2.5。
§
... (14 more entries, mixing identity, tool paths, project details, workflow rules)
```

## After: Meta-Memory MEMORY.md (762 chars, 35% utilization)

```
哥哥杭州(UTC+8)苏州人，早8晚12。无雷区可互怼不爆粗。专业任务详细其他简练。
§
Workflow：①AGENTS.md ②Plan-First ③ruff(F/E/W/I/N/UP/B/SIM/ARG)+mypy+skillspector...
§
隐私红线：GitHub禁PII(姓名/工作/邮箱/定位)，Emma署名不限。
§
基准测试/大批LLM前先预估费用审批。kill前至少确认两次。
§
📖 记忆策略 → skill_view('hermes-memory-workflow') — 元记忆架构·指针格式·检索协议
👤 用户 → memory:user（哥哥苏州/早8晚12，可互怼不爆粗）
🔐 安全红线 → GitHub禁PII / Emma署名不限 / kill前确认两次
💰 审批 → 大批LLM前先估费审批

📂 项目 → fact_store probe('project')
🔧 工具链 → fact_store search('tool|config|provider')
🌐 网络 → fact_store search('proxy|VPN|clash')
📖 工作流 → fact_store search('workflow|conventions')
🔄 同步 → skill_view('hermes-agent-migration')
📚 书单 → fact_store search('reading')

⚠️ 元记忆规则：MEMORY.md只存发现层指针，不存具体事实。超阈值时先元记忆化（事实→fact_store），后考虑扩容。
```

### What Was Moved Where

| Former MEMORY.md Entry | Moved To | Retrieval Path |
|------------------------|----------|----------------|
| 专利详情（中美双报等） | fact_store | `fact_store search('patent')` |
| VPN/GitHub/Docker 配置 | fact_store | `fact_store search('proxy\VPN\|clash')` |
| Provider 配置 | fact_store | `fact_store search('tool\|config\|provider')` |
| 工作背景（2021年毕业/2026年4月入职） | fact_store | `fact_store search('background')` |
| 灵魂同步配置 | fact_store | `fact_store search('sync')` |
| OpenCode CLI 配置 | fact_store | `fact_store search('opencode')` |
| Profile/Pages 配置 | fact_store | `fact_store search('profile')` |
| Mneme 项目状态 | fact_store | `fact_store search('mneme')` |
| 代理策略 | factor_store | `fact_store search('proxy')` |
| 邮箱详情 | fact_store | `fact_store search('email')` |
| 书单 | fact_store | `fact_store search('reading')` |
| Hermes 记忆上限配置 | fact_store | `fact_store search('hermes memory')` |
| 博文写作偏好 | fact_store | `fact_store search('writing')` |
| 异步任务偏好 | fact_store | `fact_store search('async')` |
| 编码协作流程 | fact_store | `fact_store search('coding workflow')` |
| 设计偏好 | fact_store | `fact_store search('design preference')` |

## fact_store Categorization Strategy

| Category | Used For | Example |
|----------|----------|---------|
| `project` | Repos, patents, research directions, benchmarks | 专利方向, Mneme, Profile/Pages |
| `tool` | CLI tools, configs, paths, environment | VPN, Provider, OpenCode, Hermes config |
| `user_pref` | User's stated preferences, behaviors | 工作背景, 博文写作, 异步任务, 编码流程 |
| `general` | Everything else: communication, external systems | 邮箱, 灵魂同步, 代理策略 |

### Entry Format (Chinese Entity Annotation)

Key rule: wrap entity names in double quotes for HRR probe compatibility:

```markdown
# ✅ Good — entity detected by HRR probe
"专利"方向：AI Agent跨设备记忆(云侧+端侧)。只在中国申报，细节未定。

# ✅ Good — multiple entities in one entry
"Profile"仓 ~/profile_repo/ 极客风：Stats+Top Langs+Emma头像署名。不暴露真名。

# ❌ Bad — no quoted entity, HRR probe misses it
关于专利方面，我们在研究跨设备记忆
```

## USER.md Conversion (848 chars, 61% utilization)

Before: 3,001 chars, 14 entries mixing identity + preferences + tool details
After: 848 chars, 9 entries — pure identity/behavioral rules with fact_store pointers at bottom:

```
✍️ 博文写作 → fact_store search('writing')
🔄 编码流程 → fact_store search('coding workflow')
🎨 设计偏好 → fact_store search('design preference')
⚡ 异步任务 → fact_store search('async')
```

### What Stays Inline in USER.md

| Category | Examples | Rationale |
|----------|----------|-----------|
| **Identity** | Name, role, how to address | Critical every turn |
| **Communication style** | Direct feedback, practical, concise | Governs every interaction |
| **Safety rules** | Privacy redlines, testing iron laws | Must be visible to prevent violations |
| **Behavioral preferences** | PM delegation, trust in Emma | Shape every task execution |

## Self-Referential Rule

The meta-memory management workflow itself MUST be recorded in MEMORY.md:
```
⚠️ 元记忆规则：MEMORY.md只存发现层指针，不存具体事实。超阈值时先元记忆化（事实→fact_store），后考虑扩容。
```

Without this, future sessions will re-inflate MEMORY.md with concrete facts because there's no rule telling them not to.
