# Game Content Documentation Standards

> Verified: 2026-06-22 (AFFIX_INDEX.md restyle session)
> Applies to: XunDaoMUD affix/game-data markdown files

## Affix Table Format

All affix reference tables use these unified column headers:

```
| 品阶 | 词条名 | 效果 | 境界要求 | 权重 |
```

### Rules

- **品阶**: `1 阶` ~ `6 阶` (not `TIER_1`, not `T1`)
- **效果**: Direct value + attribute text, e.g. `攻击强度+50`, `体魄上限+250`, `修炼速度+25%`. Do NOT prefix with "+" in a separate column.
- **境界要求**: Use realm sub-layer names — `练气一层`, `筑基一层`, `金丹一层`, `元婴一层`, `化神一层`, `大乘一层`. NOT `练气期`, NOT `Lv.1`.
- **权重**: raw `rarity` value from the code. Common = `100`, rare = lower number.
- Group same skill-type (心法/身法/灵技) in ONE table, not split by attribute series.

### Realm Naming Convention

| Level Range | Realm Sub-layer | Code Constant |
|-------------|----------------|---------------|
| Lv.0 | 凡人 | — |
| Lv.1 | 练气一层 | min_level=1 |
| Lv.2 | 练气二层 | |
| ... | ... | |
| Lv.10 | 练气巅峰 | |
| Lv.11 | 筑基一层 | min_level=11 |
| Lv.12 | 筑基二层 | |
| ... | ... | |
| Lv.20 | 筑基巅峰 | |
| Lv.21 | 金丹一层 | min_level=21 |
| Lv.31 | 元婴一层 | min_level=31 |
| Lv.41 | 化神一层 | min_level=41 |
| Lv.51 | 大乘一层 | min_level=51 |

When documenting an affix with `min_level=X`, map to `境界` using the entry sub-layer:
- `min_level=1` → 练气一层
- `min_level=11` → 筑基一层
- `min_level=21` → 金丹一层
- etc.

### Skill Type Headers

```markdown
## 心法（FORCE）— N 个词条
## 身法（DODGE）— N 个词条
## 灵技（BATTLE）— N 个词条
## 加工（CRAFT）— N 个词条
```

Include count after the em dash.

### Item vs Skill 境界要求

| Type | 境界要求 means |
|------|---------------|
| Skills (心法/身法/灵技) | Player's realm requirement (练气一层 ~ 大乘一层) |
| Items (丹药/符箓/装备) | Item's own tier (一品 ~ 六品) |

### Passive Affix Defaults

When documenting affixes that are passive (心法/身法 attr_bonus):

```yaml
mp_cost: 0
sp_cost: 0
cooldown: 0
rarity: 100  # unless explicitly different
```

These defaults should NOT be shown in the markdown table — they clutter. Only note MP cost or cooldown when non-zero.

### Affix Naming Convention (dot-separator)

All tiered affixes use `·` (U+00B7 middle dot) as separator:

```
# ✅ Correct
伤害·金·壹     →  [type]·[element]·[tier]
聚气·壹        →  [series]·[tier]
迅捷·贰        →  [series]·[tier]

# ❌ Wrong
伤害·金壹       →  tier fused to element
聚气壹          →  no separator
```

The three-part form (`伤害·金·壹`) is preferred for affixes with an attribute/element dimension. Two-part form (`聚气·壹`, `迅捷·贰`) is used for affixes without that dimension.

### Affix Stacking Rule

When documenting affix builds:

- Each slot holds ONE affix of ONE tier
- A 大乘 player with 迅捷·陆 equipped gets **+16 dodge**, NOT the sum of 迅捷壹~陆 (+41)
- When calculating totals, add: base + 心法主槽(满阶) + 心法副槽(满阶×50%) + 身法(满阶)
- Do NOT sum cumulative tier values within a single series
