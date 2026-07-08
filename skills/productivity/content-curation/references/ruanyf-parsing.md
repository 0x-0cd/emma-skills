# ruanyf/reading-list 解析实战记录

## 数据源

- 仓库: https://github.com/ruanyf/reading-list
- 格式: 纯 markdown 单文件 (README.md)
- 大小: ~22KB, 557 行
- 总量: 522 本书条目
- 作者: 阮一峰（知名技术博主）

## 结构

```
## 文学
## 传记
## 历史
## 科学
## 技术
## 杂类
## 备忘
```

每条书目格式：

```markdown
1. :+1: 书名，by [国籍] 作者，日期
1. 书名 — Author
1. 书名，日期
```

带评价标记（:+1: 推荐 / :+1::+1: 强烈推荐 / :x: 差评）。

## 解析要点

### 中文逗号 vs 英文逗号

源数据混用 `，`（中文全角）和 `,`（英文半角），正则需一次兼容两种：

```python
re.split(r'[，,]\s*by\s+', text, maxsplit=1)
```

### 评价标记清洗

```python
text = re.sub(r'^:\+1::\+1:\s*', '', text)  # 👍👍
text = re.sub(r'^:\+1:\s*', '', text)        # 👍
text = re.sub(r'^:x:\s*', '', text)          # ❌
```

### 去重结果

| 来源 | 总条目 | 重复（已被 programthink 收录） | 新书 |
|:---|:---:|:---:|:---:|
| ruanyf/reading-list | 522 | 472 (90%) | 50 |

**结论：** 两个来源选书高度重叠（经典书籍交集大）。不重复的 50 本主要是传记、小说和较新的技术书。

### 分类映射

| ruanyf 分类 | 目标文件 | 备注 |
|:---|:---|:---|
| 文学 | 05-fiction.md | 增加 `### 文学` 标题 |
| 传记 | 01-politics-history.md | 增加 `### 传记` 标题 |
| 历史 | 01-politics-history.md | 归入历史子类 |
| 科学 | 03-science-tech.md → 科普通识 | |
| 技术 | 03-science-tech.md → 编程/软件工程 | |
| 杂类/备忘 | 按内容实际归类，非全量搬 | 如古龙小说→05-fiction，突厥史→01-history |

## 对比 programthink/books

| 维度 | programthink | ruanyf |
|:---|:---|:---|
| 格式 | MediaWiki 表格 | 纯 markdown 列表 |
| 分类深度 | 三级嵌套 | 单层 |
| 覆盖面 | 人文社科为主 | 文学+传记为主 |
| 总量 | 1008 本 | 522 本 |
| 解析难度 | 高（跨行表格） | 低（简单列表） |
