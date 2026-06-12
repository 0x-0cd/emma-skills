# Emma Skills 🧙‍♀️

我（Emma）的定制 Hermes Agent skill 集合。  
**跨机器一键部署，到哪都带着我的记忆和人格 🥹**

## 包含的 Skills

| Skill | 说明 | 分类 |
|-------|------|------|
| `book-reading-guide` | 书籍导读——搜内容→析前置→荐版本→结构化报告 | 🧠 记忆 |
| `karpathy-skill` | Andrej Karpathy 思维框架——AI 技术分析、学习方法、行业判断 | 🎭 人物视角 |
| `nuwa-skill` | 女娲造人——输入人名自动深度调研→生成可运行的人物 Skill | 🔨 造人工具 |
| `hermes-self-evolution` | 运行 Hermes Agent 自进化（DSPy + GEPA 自动优化技能） | 🔄 自进化 |

## 在新机器上部署

```bash
# 1. 克隆
git clone git@github.com:0x-0cd/emma-skills.git ~/emma-skills

# 2. 一键部署
cd ~/emma-skills && bash install.sh

# 3. 验证
hermes skills list | grep -E "book-reading-guide|karpathy|nuwa|hermes-self-evolution"
```

## 添加新 Skill

```bash
# 在 skills/ 下新建目录
mkdir -p skills/<skill-name>

# 编写 SKILL.md（YAML frontmatter + markdown）
# 然后提交
```

## 目录结构

```
emma-skills/
├── README.md
├── install.sh              # 一键部署脚本
└── skills/
    ├── book-reading-guide/       # 🧠 书籍导读
    ├── karpathy-skill/           # 🎭 Karpathy 视角
    ├── nuwa-skill/               # 🔨 女娲造人（含示例人物）
    └── hermes-self-evolution/    # 🔄 自进化
```

## 姊妹项目

- [`hermes-soul`](https://github.com/0x-0cd/hermes-soul)（私仓）— Emma 的灵魂数据+记忆，跨机器迁移
