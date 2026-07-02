# Python Regex 自学计划 —— 框架实战样例

> 展示如何用 Self-Directed Learning Framework 设计一个完整的编程技能自学项目。
> 对应仓库：https://github.com/0x-0cd/regex-dojo

## 技能分解

```
系统掌握 Python 正则表达式
├── A: 基础匹配 —— 字面量、字符类、特殊字符
│   ├── A1: 字面量匹配
│   ├── A2: 字符类 [abc] [^abc] [a-z]
│   ├── A3: 预定义字符类 \d \w \s
│   └── A4: 通配符 "." 与转义
├── B: 量词与定位
│   ├── B1: 量词 * + ? {n,m}
│   ├── B2: 贪婪 vs 懒惰
│   ├── B3: 锚点 ^ $ \A \Z
│   └── B4: 单词边界 \b \B
├── C: 分组与捕获
│   ├── C1: 捕获组 .groups()
│   ├── C2: 命名组 (?P<name>...)
│   ├── C3: 非捕获组 (?:...)
│   └── C4: 反向引用 \1 \g<name>
├── D: 环视
│   ├── D1: 正向前瞻 (?=...)
│   ├── D2: 负向前瞻 (?!...)
│   ├── D3: 正向后顾 (?<=...)
│   └── D4: 负向后顾 (?<!...)
├── E: Python re 模块 API
│   ├── E1: search vs match vs fullmatch
│   ├── E2: findall vs finditer
│   ├── E3: sub/subn 替换
│   ├── E4: split 分割
│   ├── E5: 标志位 re.I / re.M / re.S / re.X
│   └── E6: compile 预编译
└── F: 进阶实战
    ├── F1: 条件表达式
    ├── F2: 原子组与回溯控制
    ├── F3: 灾难性回溯陷阱
    └── F4: 真实场景（URL/邮箱/IP/日期）
```

## 阶段规划（7 次课，每次 30min）

| 阶段 | 焦点 | 子技能 |
|------|------|--------|
| 1 | 基础匹配入门 | A1–A4 |
| 2 | 量词与贪婪 | B1–B4 |
| 3 | 分组捕获 | C1–C4 |
| 4 | 环视 | D1–D4 |
| 5 | Python API 实战 | E1–E6 |
| 6 | 进阶 + 性能 | F1–F4 |
| 7 | 综合挑战 | 混合场景 |

## 实践项目结构

```
regex-dojo/
├── run.py                     ← python run.py [阶段号]
├── playground.py              ← 自由练习
├── practices/
│   ├── __init__.py
│   ├── helpers.py             ← test() 验证工具
│   ├── phase_01_basics.py     ← 阶段 1
│   └── phase_02_quantifiers.py
├── README.md
└── .gitignore
```

## 反馈机制

| 类型 | 实现 |
|------|------|
| 直接测量 | `test()` 函数打印 ✅/❌ |
| 可视化 | regex101.com 匹配高亮 |
| 对照参考 | 参考答案比对 |
| 定量跟踪 | 通过率/时间记录表 |

## 关键设计决策

- **Scaffold then fill**: 每个挑战文件已写好 test cases，学习者只填 `pattern = r""`
- **根目录可运行**: `python run.py 1` 无需任何额外设置
- **Python 模块规范**: `__init__.py` + 下划线命名，支持 `-m` 调用
- **单一验证函数**: `helpers.test()` 封装了 search/match/fullmatch/findall/sub
