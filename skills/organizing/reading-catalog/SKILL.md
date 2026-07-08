---
name: reading-catalog
description: 维护个人阅读书单 GitHub 仓库：结构设计、分类体系、藏书迁移、格式规范
created_by: Emma
tags:
  - reading
  - book-list
  - catalog
  - markdown
  - github
  - organization
---

# reading-catalog — 个人阅读书单管理 Skill

> 覆盖如何创建、组织、扩充一个纯 Markdown 的个人书单 GitHub 仓库。
> 不包含「书籍导读」——那是 book-reading-guide 的职责。

---

## 什么时候用

| 场景 | 触发词 |
|:----|:-------|
| 创建新书单仓库 | "建个书单"、"做个阅读计划"、"新建 reading list" |
| 扩充/迁移藏书 | "搬书"、"导入书单"、"迁移藏书" |
| 调整分类结构 | "重新分类"、"改类目"、"调整结构" |
| 整理已有书单 | "整理一下"、"归归类"、"格式化" |

---

## 仓库结构设计

### 推荐布局（已验证）

```
reading-list/
├── README.md                       ← 总索引 + 条目格式说明
├── 01-politics-history.md          ← 政治 / 历史 / 社科 / 军事
├── 02-philosophy.md                ← 哲学 / 心理学
├── 03-science-tech.md              ← 科学 / 技术 / IT
├── 04-economics.md                 ← 经济 / 管理 / 投资
├── 05-fiction.md                   ← 文学 / 小说 / 文艺
└── 06-reference.md                 ← 工具书 / 方法论 / 其他
```

**为什么这么分：** 6 个文件避免单文件过长，同时不至于拆碎成几十个小文件。每个大类内部用 `####` 做二级子分类。

### README 设计

```markdown
# 📚 阅读书单

个人阅读收藏，按类目分类整理。纯 Markdown 结构，无外部链接。

---

## 类目索引

| # | 类目 | 说明 |
|:---:|:---|:---|
| 01 | [政治 / 历史 / 社科](./01-politics-history.md) | 政治理论、各国历史、社会学 |
| 02 | [哲学 / 心理学](./02-philosophy.md) | 哲学史、哲学家、认知/社会心理学 |
| ... | ... | ... |

---

> 条目格式：`- **《书名》** — 作者 · 子分类`
```

### ⚠️ 已确认的用户偏好

- **纯 Markdown，不加外部链接**（不附下载链接、购买链接、Goodreads 链接）
- **不暴露阅读进度**（不标记已读/在读/想读/搁置等状态）
- **格式简洁**：`- **《书名》** — 作者 · 子分类`
- **作者国籍用括号标注**，如 `(英) 约翰·密尔`、`(美) 弗朗西斯·福山`

---

## 条目格式标准

```markdown
- **《书名》** — 作者 · 大类
- **《书名》** — 作者 · 大类 · 子分类
```

示例：
```markdown
- **《论民主》** — (美) 罗伯特·道尔 · 政治理论 · 民主与宪政
- **《资本论》** — (德) 卡尔·马克思 · 政治理论 · 共产主义 / 社会主义
```

分类格式约定：
- 大类名写在第一个 `·` 后面
- 子分类名写在第二个 `·` 后面（可选）
- 大类名和子分类名与文件内 `###` / `####` 标题保持一致

---

## 藏书迁移工作流（从外部来源批量导入）

### 通用步骤

1. **获取源数据** — 下载或抓取外部书单的原始数据文件
2. **解析条目** — 用 Python 脚本解析结构化数据（wiki table、CSV、JSON 等）
3. **分类映射** — 将源数据的分类体系映射到我们的 6 个文件结构
4. **清洗格式化** — 清洗作者字段、书名中的 wiki/HTML 残留，统一括号
5. **写入文件** — 按分类将条目追加到对应文件
6. **验证提交** — 检查条目数、空书名、残留标记，然后 commit + push

### 分类映射要点

将外部书单的分类对应到我们的结构时，遵循以下原则：

- **政治理论、政治小说、国别政治** → `01-politics-history.md` → 对应二级分类下
- **世界史、国别史、军事史** → `01-politics-history.md` (历史部分)
- **社会学** → `01-politics-history.md` (社会学部分)
- **哲学流派、哲学家著作** → `02-philosophy.md` → 哲学部分
- **心理学** → `02-philosophy.md` → 心理学部分
- **科普、数学、物理、化学、生命科学** → `03-science-tech.md` → 对应科学分类
- **编程、软件工程、安全、AI、操作系统** → `03-science-tech.md` → 对应 IT 分类
- **经济学、金融、投资、管理** → `04-economics.md`
- **文学、小说、文化研究** → `05-fiction.md`
- **学习方法、工具书** → `06-reference.md`

### 可能跳过的内容

从外部来源（如 programthink/books）迁移时，根据用户要求跳过：
- **中国政治与政治人物**相关内容（带有极端主观偏颇的书籍）

### 数据清洗

批量导入后必须检查以下项目：

```bash
# 检查空书名
grep -cP '《》' *.md

# 检查残留 wiki/HTML 标记
grep -c '<br' *.md
grep -c '&nbsp;' *.md

# 检查作者括号一致性（所有 ) 前应有 (）
python3 -c "
import re
for fn in ['*.md']:
    c = open(fn).read()
    entries = re.findall(r'^- \*\*《[^》]+》\*\* — (.+?)(?: ·|\$)', c, re.MULTILINE)
    bad = [e for e in entries if ')' in e and not e.startswith('(')]
    if bad:
        print(f'{fn}: {len(bad)} entries with missing open paren')
"
```

### 批量修改技巧

当需要清洗大量条目的作者字段时，Python regex 比 sed 更可靠（编码问题少）：

```python
import re
for fp in files:
    with open(fp, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    new_lines = []
    for line in lines:
        # 修复作者字段缺少左括号：— X) → — (X)
        m = re.match(r'^(- \*\*《[^》]+》\*\* — )([^(][^)]*\))(.*)$', line)
        if m:
            new_lines.append(m.group(1) + '(' + m.group(2) + m.group(3) + '\n')
        else:
            new_lines.append(line.rstrip('\n'))
    with open(fp, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))
```

---

## 参考

- `references/programthink-migration.md` — 从 programthink/books 迁移的完整分类映射表（用于参考类目对应关系）

---

## 已知陷阱

### 作者括号不一致
外部来源的国籍标注格式多样：`英) 作者`、`(英) 作者`、`英/美) 作者`。迁移后统一为 `(XX) 作者`。

### 格式泄漏
某些 wiki 来源的表格中，文件类型列（PDF/EPUB/MOBI）可能泄漏到书名或作者字段中。需检查并移除这类条目。

### 中文长书名截断
某些书名包含副标题或"其它中文名"注释，需要清洗为简洁的主书名。
