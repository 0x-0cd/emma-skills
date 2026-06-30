# web_search 超时兜底方案实战记录

## 背景
本环境（树莓派，香港代理）下 web_search 频繁超时（DuckDuckGo / Yahoo / Startpage 三个后端均失败）。以下方案经实战验证可行。

## 方案 A：curl + 豆瓣 Subject Search

```bash
# 搜书名
curl -sL "https://book.douban.com/subject_search?search_text=悉达多+姜乙" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
```

从输出中提取 subject ID：
```bash
curl ... | grep -oP 'subject/\d+' | head -10
```

得到的 subject ID 列表可能包含无关书籍，需要逐一过滤。

## 方案 B：web_extract 拉豆瓣详情

拿到正确的 subject ID 后，用 `web_extract`：
```
web_extract(urls=["https://book.douban.com/subject/<ID>/"])
```

豆瓣详情页会返回结构化 markdown，包含：
- 评分及评分分布（五星百分比）
- 出版社、出版年、ISBN、定价、页数
- 内容简介
- 作者简介
- 目录
- 原文摘录
- 短评精选（正反两面）
- 热门书评标题
- 丛书信息
- 喜欢读的人也喜欢

## 方案 C：curl + 百度搜索补充信息

```bash
curl -sL "https://www.baidu.com/s?wd=<搜索词>" \
  -H "User-Agent: Mozilla/5.0" 2>&1 | grep -oP '"https?://[^"]*douban[^"]*"'
```

## 踩坑记录

1. **ISBN 直链不可靠**：同一个 ISBN 可能对应豆瓣上完全不同的书。比如 `9787201152424` 返回了《白酒到底如何卖2》而非《悉达多》。优先用 subject_search 按书名+译者搜索。

2. **Google 不可用**：谷歌在香港代理环境下超时，不要依赖。

3. **百度结果可能为空**：baidu 搜书名可能提取不到豆瓣链接，需要结合 subject_search 用。

4. **curl 抓取 HTML 可能缺少 info 区块**：豆瓣页面用 JS 渲染部分内容，curl 抓到的 HTML 可能没有完整的 metadata。此时 web_extract 渲染效果更好。

5. **多个不同译本需要分别搜索**：不同译者（姜乙/杨武能/张佩芬）对应不同的豆瓣 subject ID，需分别抓取对比。
