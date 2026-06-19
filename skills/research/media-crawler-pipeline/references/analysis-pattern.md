# Crawled Data Analysis Pattern

After crawling, data lives in `~/MediaCrawler/data/<platform>/jsonl/*.jsonl`.

## Files

| File | Content | Fields |
|------|---------|--------|
| `search_contents_*.jsonl` | Notes/posts | `title`, `desc`, `liked_count`, `collected_count`, `comment_count`, `time`(ms), `nickname`, `tag_list`, `note_id` |
| `search_comments_*.jsonl` | Comments | `content`, `like_count`, `ip_location`, `nickname`, `note_id`, `sub_comment_count` |

## Analysis Workflow

```python
import json
from datetime import datetime
from collections import Counter, defaultdict

# 1. Load data
notes, comments = [], []
with open("search_contents_2026-06-13.jsonl") as f:
    for line in f:
        if line.strip(): notes.append(json.loads(line))

with open("search_comments_2026-06-13.jsonl") as f:
    for line in f:
        if line.strip(): comments.append(json.loads(line))

# 2. Filter by date (ms timestamp)
cutoff = datetime(2026, 5, 13).timestamp() * 1000
recent = [n for n in notes if n.get('time', 0) >= cutoff]

# 3. Sort by hotness
recent.sort(key=lambda x: x.get('liked_count', 0), reverse=True)

# 4. Filter quality comments
NOISE = ['666', '888', '好', '赞', '支持', '顶', '已关注', '求分享', 
         '牛逼', '厉害', '强', '马克', '码住', '收藏', '不错', 
         '学到了', '谢谢', '感谢', '同问', '蹲', 'cy', '插眼']

quality = []
for c in comments:
    content = c.get('content', '').strip()
    if not content or len(content) < 5: continue
    if content.lower().strip() in NOISE: continue
    quality.append(c)

# 5. Sort comments by likes
quality.sort(key=lambda x: x.get('like_count', 0), reverse=True)

# 6. Theme detection
THEMES = {
    "入门教程": ["入门", "教程", "安装", "配置", "搭建", "新手"],
    "记忆系统": ["记忆", "memory", "记住", "遗忘", "上下文"],
    "对比OpenClaw": ["openclaw", "小龙虾", "龙虾", "对比", "vs"],
    "Skill生态": ["skill", "skills", "技能", "技能包"],
    "Token优化": ["token", "省钱", "省token", "rtk"],
}

for theme, keywords in THEMES.items():
    count = sum(1 for n in recent 
                if any(kw in n.get('desc','').lower() or kw in n.get('title','').lower() for kw in keywords))
    print(f"{theme}: {count}篇")

# 7. Word frequency
words = []
for n in recent:
    words.extend(n.get('tag_list', '').split(',')) if isinstance(n.get('tag_list'), str) else None
Counter(w.strip() for w in words if w.strip()).most_common(20)
```
