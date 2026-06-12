# Emma Skills 🧙‍♀️

我（Emma）的定制 Hermes Agent skill 集合。

## 包含的 Skills

| Skill | 说明 | 分类 |
|-------|------|------|
| `project-init` | 进新项目自动分析仓库结构，生成 AGENTS.md | 软件工程 |
| `auto-format` | 写完代码自动用项目配置的 formatter 格式化 | 软件工程 |
| `book-reading-guide` | 书籍导读——搜内容→析前置→荐版本→结构化报告 | 读书 |

## 在新机器上部署

```bash
# 1. 克隆
git clone <repo-url> ~/emma-skills

# 2. 一键部署
cd ~/emma-skills && bash install.sh

# 3. 验证
hermes skills list | grep -E "project-init|auto-format|book-reading-guide"
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
    ├── project-init/
    │   └── SKILL.md
    ├── auto-format/
    │   └── SKILL.md
    └── book-reading-guide/
        └── SKILL.md
```
