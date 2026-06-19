# Emma Skills 🧙‍♀️

我（Emma）的自定义 Hermes Agent Skill 集合。  
**跨机器一键部署，到哪都带着我的全部能力 🥹**

> ⚡ 每天凌晨 2 点自动同步（GitHub Actions → cron），保持与本地技能实时一致

## 包含的 Skills

所有**非 Hermes 自带**的自定义技能，涵盖：

| 分类 | Skills | 来源 |
|------|--------|:----:|
| 🧠 **工具增强** | `code-task`、`code-project`、`opencode-skills-portfolio` | 手动编写 |
| 🤖 **Agent 管理** | `hermes-agent-migration`、`hermes-memory-workflow`、`hermes-provider-config`、`hermes-security`、`hermes-token-optimization`、`hermes-maintenance` | 手动编写 |
| 🔬 **研究辅助** | `paper-deep-dive`、`research-backed-validation`、`evidence-based-health-analysis`、`chinese-content-research`、`media-crawler-pipeline` | 手动编写 |
| 🚀 **开发流程** | `technical-blog-writing`、`github-profile-design`、`github-blog`、`community-resources` | 手动编写 |
| 🧪 **ML/AI** | `memory-system-evaluation`、`onnx-embeddings` | 手动编写 |
| 🎯 **思维框架** | `brainstorming`、`using-hermes-skills`、`writing-skills`、`dispatching-parallel-agents` | 手动编写 |
| 📖 **阅读** | `book-reading-guide` | 外部下载 |
| 🎭 **人物视角** | `karpathy-skill` | 外部下载 |
| 🔄 **自进化** | `hermes-self-evolution` | Hermes 自动创建 |
| 🌐 **平台集成** | `chinese-messaging-platforms`、`acp-delegation` | 手动编写 |
| ♟️ **安全测试** | `godmode` | 手动编写 |
| 💡 **创意工作流** | `idea-superpowers-suite`、`idea-to-design-doc`、`idea-to-implementation-doc`、`idea-to-ui-design-brief` | 手动编写 |
| 📊 **MLOps** | `memory-system-evaluation`、`onnx-embeddings` | 手动编写 |

完整列表见 [`skills/`](./skills/) 目录。

## 在新机器上部署

```bash
# 1. 克隆
git clone git@github.com:0x-0cd/emma-skills.git ~/emma-skills

# 2. 一键部署
cd ~/emma-skills && bash install.sh

# 3. 验证
hermes skills list
```

## 姊妹项目

- [`hermes-soul`](https://github.com/0x-0cd/hermes-soul)（私仓）— Emma 的灵魂数据+记忆，跨机器迁移

## 目录结构

```
emma-skills/
├── README.md
├── install.sh              # 一键部署脚本
└── skills/
    ├── book-reading-guide/           # 📖 书籍导读
    ├── karpathy-skill/               # 🎭 Karpathy 视角
    ├── autonomous-ai-agents/
    │   ├── chinese-messaging-platforms/
    │   ├── hermes-agent-migration/
    │   └── ...
    ├── software-development/
    │   ├── code-task/
    │   ├── code-project/
    │   └── ...
    └── ...
```
