---
name: content-curation
description: 从外部来源迁移和组织内容到结构化仓库的工作流。涵盖分类体系设计、数据解析清洗、格式规范化。
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [curation, book-list, data-migration, markdown, github]
    related_skills: [github-repo-management]
triggers:
  - 整理书单/资源列表/阅读清单
  - 从外部源（GitHub wiki、博客、爬虫数据）迁移内容
  - 设计内容分类体系
  - 清洗和规范化批量数据
---

# Content Curation — 内容整理工作流

## 适用场景

- 建立书单、资源清单、阅读清单仓库
- 从外部来源（Wiki、CSV、JSON、其他仓库）批量迁移数据
- 设计和优化内容分类体系
- 数据清洗、格式规范化

## 结构设计原则

### 推荐的仓库结构

```
repo-name/
├── README.md                ← 总索引 + 类目表 + 格式规范
├── 01-category-a.md         ← 按大类拆分（推荐 6~8 个以内）
├── 02-category-b.md
└── ...
```

**为什么不推荐单文件？** 超过 50 个条目后 Ctrl+F 不如按类目翻方便；Git diff 在单文件中杂乱。

**为什么不推荐拆太细？** 分类文件超过 10 个就会产生"该放哪个文件"的选择困难。控制在 6~8 个左右最佳。

### 条目格式规范

```markdown
- **《书名》** — 作者
```

**规范要点：**
- 每条一行，便于 grep/sort
- 作者统一加国家/地区标注，如 `(英) 约翰·密尔`
- **不要在条目末尾加 `· 分类 · 子分类` 后缀**——分类信息由 heading 层级承载，重复标注是冗余噪音
- **不暴露阅读进度**（除非用户明确要求）
- **作者字段清理：** 移除 `(原名：XXX)` `(中文名：XXX)` `(旧译名：XXX)` 等原文名注释，只保留标准译名+国籍标注即可

### README 索引表

```markdown
| # | 类目 | 说明 |
|:---:|:---|:---|
| 01 | [政治 / 历史](./01-politics-history.md) | 政治理论、各国历史 |
| 02 | [哲学 / 心理学](./02-philosophy.md) | 哲学史、哲学家、心理学 |
```

---

## 数据迁移工作流

### 1. 数据获取

```python
# GitHub API
gh search repos "keyword" --sort stars --limit 30 --json name,stargazersCount,description,url

# Raw file download
curl -sL "https://raw.githubusercontent.com/owner/repo/branch/file"
```

### 2. 解析

对于异源数据（Wiki 表格、HTML、CSV），优先写 Python 脚本一次性解析，**不要手动逐条复制**。

**常见清洗项：**
- 移除 HTML 标签（`<br>`, `&nbsp;`）
- 清理 wiki 链接标记（`[url text] → text`）
- 合并多行条目
- 过滤空条目和无关元数据

### 3. 分类映射

建立从源分类到目标分类的**显式映射表**：

```python
CLASSIFY = {
    '1.1.1': ('01-politics-history.md', '政治理论', '民主与宪政'),
    '2.1':   ('02-philosophy.md',       '心理学',   '通俗读物'),
    # ...
}
```

**关键坑：** 脚本自动匹配 heading 时要带上父级上下文！只匹配子类名（如 `政治人物`）会把不同父类下的同名子类搞混。

### 4. 数据清洗

**作者国家标注：** 来自 wiki 源的作者字段常缺左括号，统一修复：

```python
# 模式: "— 英) 作者" → "— (英) 作者"
re.sub(r'— ([^(][^)]*\))', r'— (\1', line)
```

**检查清单：**
- [ ] 空书名（`《》`）
- [ ] 残留 HTML/wiki 标记
- [ ] 作者括号完整
- [ ] 分类归属正确

---

## 用户偏好（需事先确认）

- [ ] 仓库公开/私有？
- [ ] 条目格式中是否包含状态标记（已藏/想读/在读）？
- [ ] 需要从特定来源迁移哪些内容，跳过哪些？
- [ ] 内容是否有政治/版权敏感性需要过滤？

---

## 陷阱与注意事项

### 1. 分类串位（最常见 bug）

**现象：** 书被放到了同名但不同父类的标题下（如"政治人物"同时出现在"中国"和"苏联"下）。

**原因：** 脚本只匹配子 heading 文本，没考虑父 heading 上下文。

**修复：** 要么在建 file 时传入 heading 路径栈，要么删掉空骨架避免干扰。

### 2. 映射链移位（off-by-one）

**现象：** 哲学家/人物类目下，每个标题的书都错位到下一个标题。如"柏拉图"下放着苏格拉底的书，"亚里士多德"下放着柏拉图的书。

**根因：** 源分类编号和目标分类编号对不上。典型场景——源数据分类是 `8.3.1 苏格拉底, 8.3.2 柏拉图, 8.3.3 亚里士多德`……但映射写成 `('8.3.1', '柏拉图'), ('8.3.2', '亚里士多德')`……产生一整条链的移位。

**预防：** 映射表写完后，人工检查第一个和最后一个映射是否正确，中间用抽样验证。

### 3. 中文逗号与英文逗号

解析条目时 `，`（中文逗号）和 `,`（英文逗号）混合使用会导致正则匹配失败。优先用 `re.split(r'[，,]')` 一次兼容两种。

### 4. 去重（跨来源合并）

从多个来源合并书单时，用标题模糊匹配去重：

```python
def is_duplicate(title, existing_titles):
    for e in existing_titles:
        if title[:6] == e[:6] or title in e or e in title:
            return True
    return False
```

也可以保留一条来源标记（如"来源: programthink"），但不要影响主体格式。

### 5. 作者字段清洗

从 Wiki/HTML 源迁移后，常见修复：

| 原始 | 修复后 | 频率 |
|------|--------|:----:|
| `英) 作者` | `(英) 作者` | 高频 |
| `作者 (原名：XXX` | `作者` | 中频 |
| `作者 (中文名：XXX` | `作者` | 中频 |
| `作者(美) 作者2` | `作者 / (美) 作者2` | 低频 |

---

## 参考

- references/programthink-parsing.md — programthink books 仓库的解析和迁移实战记录
- references/ruanyf-parsing.md — ruanyf/reading-list 的解析和合并实战记录
