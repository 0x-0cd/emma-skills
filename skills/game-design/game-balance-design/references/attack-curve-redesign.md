# 攻击强度倍率曲线重设计 — 实况记录

> 日期：2026-06-24
> 背景：代码审查发现 `curve_attack_strength()` 中存在硬分支（attack ≤ 100 恒为 1.0），导致 debuff 无实际效果（ attack=1 和 attack=100 伤害完全一样）。

---

## 诊断

### 旧代码

```python
def curve_attack_strength(attack: int) -> float:
    if attack <= 100:
        return 1.0          # 硬分支：小于100全等于1
    return (attack / 100.0) ** 0.45
```

### 问题

| attack | 旧倍率 | 问题 |
|:------:|:------:|------|
| 1 | 1.0 | debuff 白给 |
| 50 | 1.0 | 降攻50%毫无感知 |
| 100 | 1.0 | 基准线 |
| 200 | 1.37 | 正常 |
| 500 | 2.06 | 正常 |

防御曲线 `def/(def+500)` 从 0 开始就有意义，攻击却有个硬门槛——不对称，设计上是个 smell。

---

## 提案：三种方案

> 全部基于 `resolve_template_attrs` 支持的 `_base/_range` 格式，不改代码结构。

### 方案 A — 线性惩罚 + 幂增益

```python
def curve_attack_strength(attack: int) -> float:
    if attack <= 0:
        return 0.1
    if attack < 100:
        return attack / 100.0          # 线性惩罚
    return (attack / 100.0) ** 0.45    # 幂增益
```

| attack | 倍率 | 倾向 |
|:------:|:----:|------|
| 1 | 0.01 | 几乎打不动 |
| 50 | 0.50 | 伤害减半 |
| 100 | 1.00 | 基准 |
| 200 | 1.37 | +37% |

**优势：** 对称于防御曲线，attack=100 是清晰的心理基准。

### 方案 B — 纯幂曲线（用户选择 ✅）

```python
def curve_attack_strength(attack: int) -> float:
    if attack <= 0:
        return 0.1
    return (attack / 100.0) ** 0.5    # 连续纯幂
```

| attack | 倍率 | 等效加成 |
|:------:|:----:|:--------:|
| 1 | 0.10 | -90% |
| 10 | 0.32 | -68% |
| 50 | 0.71 | -29% |
| 100 | 1.00 | 0% |
| 200 | 1.41 | +41% |
| 500 | 2.24 | +124% |
| 1000 | 3.16 | +216% |

**优势：** 一条公式到底、每个 attack 值都有意义。指数 `0.5`（sqrt）比旧版 `0.45` 略陡，装备堆攻击的正反馈更强。

### 方案 C — 对数曲线

```python
import math

def curve_attack_strength(attack: int) -> float:
    if attack <= 0:
        return 0.05
    return math.log(attack + 1, 2) / math.log(101, 2)
```

| attack | 倍率 |
|:------:|:----:|
| 1 | 0.15 |
| 50 | 0.89 |
| 100 | 1.00 |
| 500 | 1.20 |

**优势：** 极其平滑，永不溢出。**劣势：** 太平，堆攻击正反馈不够，修仙感弱。被否决。

---

## 决策

- 用户选择 **方案 B**，指数 0.5
- 理由：公式简洁、攻防对称、debuff 有意义、对装备提升的正反馈足够

## 改动文件

| 文件 | 改动 |
|------|------|
| `utils/realm_util.py` | 函数体重写，去掉硬分支，加 `x≤0→0.1` clamp |
| `docs/PLAYER_ATTR_REFERENCE.md` | 公式表、数值表同步更新 |
| `docs/AFFIX_INDEX.md` | 公式描述同步 |

## 关于后续怪物模板设计

本次会话还建立了怪物属性浮动惯例：hp/mp/sp/attack/defense 加 ~10% 基础数值的随机浮动。详见 SKILL.md 中 **Monster Template Attribute Design** 章节。
