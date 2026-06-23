---
name: game-balance-design
description: "Data-driven game balance methodology: extract formulas from code → multi-path scenario analysis → iterative threshold design with verified constraints"
version: 1.1.0
author: Emma
platforms: [linux]
tags: [game-design, balance, economics, cultivation-curve, thresholds, system-design]
metadata:
  hermes:
    tags: [game-design, balance, economics, cultivation-curve, thresholds, system-design]
---

# Game Balance Design — Data-Driven Methodology

Use when the user asks you to design or adjust **game economy, cultivation curves, consumable pricing, deduction/forging thresholds, probability distributions, or any numerical system**. Do NOT guess or use intuition — always extract real formulas from code first.

## When This Skill Fires

- "设计推演的修为门槛"
- "稀有度概率分布应该怎么调？"
- "修炼曲线/突破成本设计"
- "某系统的数值平衡"
- Any question whose answer involves a `curve_*` function, `_calc_*` helper, `THRESHOLD`, `INTERVAL`, or `RARITY` constant

## Core Workflow

### Phase 1: Code Recon — Extract Real Curves

Search for: `curve_*`, `_calc_*`, `*THRESHOLD*`, `*INTERVAL*`, `*RARITY*`, `cultivation`, `breakthrough`

Write a Python script that imports the game's actual formula functions and prints a full numeric table. **Never hardcode values you haven't verified against the source.**

### Phase 2: Multi-Path Scenarios

Run at least three player paths:

| Path | Purpose |
|------|---------|
| 🔴 Worst (pseudo-spirit-root, no bonuses) | Prevents beginner grind |
| 🟢 Best (true-spirit-root, max bonuses) | Checks upper bound; is it too strong? |
| 🟡 Middle (average stats) | What most players experience |

**Always calculate:**
- Balance right after realm breakthrough (breakthrough costs consume most savings)
- Time-to-first-experience (how long until a new player can try this system)
- Accumulation speed at each realm tier (not just absolute numbers)

### Phase 3: Two Hard Constraints

| Constraint | Check |
|------------|-------|
| **Realm Lock** | Player at current realm's peak can't afford next tier's threshold |
| **Usability** | Freshly-broken-through player can afford threshold within ~5-10 minutes |

### Phase 4: Iterative Presentation

Present as multi-knob options with data tables. Each proposal must include:
- Cultivation ticks / real-time minutes to afford
- Balance after breakthrough
- Worst-case player timeline

Let the user choose, then compile the selected combination into a final design doc.

## Pitfalls

- **Cumulative ≠ available:** Most cumulative cultivation gets consumed by breakthroughs. The player's actual balance at any point is `excess × total_earned`, not `total_earned`.
- **Ignore breakthrough costs = wrong by orders of magnitude:** The user called this out repeatedly. Always check post-breakthrough余额.
- **Only checking average/optimal paths = missed beginner pain:** Always check pseudo-spirit-root worst case first.
- **Slots follow skill tier, not player realm:** A 大乘 player drawing 练气-tier affixes gets at most 1 slot (练气's max), not 4 (大乘's max).
- **Deduction thresholds scale with cultivation speed per tier:** Higher-realm players earn faster, so thresholds should scale accordingly but still feel meaningful.

## Reference Files

- `references/game-balance-design.md` — Full session case study (5-round iteration on deduction thresholds), Python script template, and common numerical failure modes.
- `references/game-content-documentation.md` — Standards for documenting game content tables (affix index, realm names, table format conventions).
- `references/map-grid-from-image.md` — Technique: extract a room grid and connectivity from a user-drawn map image using PIL pixel analysis.

## Combat Damage / Skill Value Design

Use this sub-pattern when the user asks you to design **attack power, spell damage, skill base values, or any combat numerical system**.

### Workflow (verified 2026-06-22: 灵技 2~6 阶五行伤害设计)

#### Step 1: Extract HP Formula

Search for the HP/max_resource calculation function (`curve_max_resource` or similar). Identify:

```python
# Typical formula:
# level=0: 10 + related_attr // 10
# level≥1: int(RESOURCE_BASE[tier] * growth^index * (attr/100) + 25)
```

List `RESOURCE_BASE` values per tier and calculate HP at key points (entry, mid, peak) for an average-attribute player.

#### Step 2: Extract Damage Formula

Find the raw damage calculation (`_calc_raw_damage` or similar):

```python
raw = base_damage × element_factor × realm_power(level) × curve_attack_strength(attack)
final = raw × (1 - defense / (defense + 500))  # after defense reduction
```

Key variables to extract for each tier:

| Variable | Source | Example |
|----------|--------|---------|
| `realm_power` | `REALM_BASE[realm] × SUB_REALM_RATE[index]` | 练气一层=0.35, 筑基一层=1.5 |
| `attack_rate` | `curve_attack_strength(attack)` | attack=100→1.0, attack=150→1.19 |
| `def_reduction` | `def/(def+500)` | def=100→16.7%, def=150→23.1% |

#### Step 3: Build HP × realm_power Table

| Realm | Entry Level | realm_power | Entry HP | HP/realm_power |
|-------|------------|-------------|----------|----------------|
| 练气 | 1 | 0.35 | 35 | 100 |
| 筑基 | 11 | 1.50 | 125 | 83 |
| 金丹 | 21 | 7.00 | 1,025 | 146 |
| ... | ... | ... | ... | ... |

The `HP/realm_power` ratio tells you how `base_damage` must scale to maintain a consistent hit-to-kill ratio across tiers.

#### Step 4: Choose Target Hit-to-Kill Ratio & Reverse-Calculate

Decide how many same-tier hits a skill should take to kill an opponent at **entry level** of that tier:

| Ratio | Feel | Use Case |
|-------|------|----------|
| 2-3 hits | Very strong | Ultimate moves, signature skills |
| 4-6 hits | Moderate | Strong skill, noticeable impact |
| **7-12 hits** | **Standard** | **Bread-and-butter basic skills** ✅ |
| 12+ hits | Weak | Filler, spammable basics |

**Principle (verified 2026-07-24):** Base damage skills should be intentionally weak at higher tiers to **encourage combo/buff play**. Higher realm = harder to kill with pure base damage. This prevents "everyone one-shots everything" at endgame.

| Realm | Target kills | Reasoning |
|-------|-------------|-----------|
| 练气 (T1) | ~12 (keep existing) | Few buffs available, baseline |
| 筑基~金丹 (T2~3) | ~8 | Early combos start appearing |
| 元婴~大乘 (T4~6) | ~10~12 | Rich buff options; pure damage should feel weak |

Calculate: `base_damage = (HP_entry_level × target_kills) / (realm_power × attack_rate × def_multiplier)`

Round to clean numbers. Then verify against mid-tier (5th sub-realm) HP:

```text
base_damage=12 @筑基一层(L11): raw=12×1.50×1.19=21.4, final≈16, vs HP=125 → ~7.8 hits ✅
base_damage=20 @金丹一层(L21): raw=20×7.0×1.19=167, final≈128, vs HP=1025 → ~8.0 hits ✅
base_damage=35 @元婴一层(L31): raw=35×30.0×1.19=1250, final≈900, vs HP=10025 → ~11.1 hits ✅
```

#### Step 5: Assign MP Cost

MP cost should follow a clean progression matching damage growth. Higher tiers should have **worse MP efficiency** (diminishing returns) to make them meaningful choices, not free upgrades:

| Tier | base_damage | MP cost | Efficiency | Pattern |
|------|------------|---------|------------|---------|
| T1 | 10 | 1 | 10 dmg/MP | baseline |
| T2 | 30 | 3 | 10 dmg/MP | +2 |
| T3 | 60 | 6 | 10 dmg/MP | +3 |
| T4 | 120 | 10 | 12 dmg/MP | +4 |
| T5 | 250 | 15 | 17 dmg/MP | +5 |
| T6 | 500 | 20 | 25 dmg/MP | +5 |

#### Step 6: Verify Edge Cases

- **Entry-level vs mid-tier:** Skill might 3-shot at tier entry but 2-shot mid-tier. Check both.
- **With best available equipment:** Higher attack makes skills stronger. Account for existing equipment bonuses.
- **Cross-tier fights:** A 炼气 player with a 金丹 skill should see dramatically higher damage. Verify realm_power scaling makes this work naturally.

### Pitfalls

- **Don't guess base_damage.** Always extract HP and realm_power formulas first. The user corrected this approach on 2026-06-22: "先查找一下最大体魄的计算函数，预估一下每个大境界的角色大约会有多少hp，再做设计".
- **realm_power grows ~4-6x per realm, but HP grows ~10x.** This means base_damage must increase per tier just to keep pace — higher-tier skills aren't automatically stronger unless base_damage rises.
- **Attack equipment skews results.** If tier 4 weapons don't exist yet, higher-tier skills will hit slightly weaker than projected. Design conservatively and note the assumption.
- **Each slot = one affix tier, NOT cumulative.** A 大乘 player equipping 迅捷·陆 gets +16 dodge, not 迅捷壹~陆 summed (+41). When presenting affix build examples, always assume single-tier-per-slot.**
- **Ling-gen preconditions on elemental skills:** The user clarified that common skills should have `min_ling_gen=15` (just a token check for having the element), no higher. Only rare/specialized skills warrant higher thresholds.

## Related Skills

- `code-task` — Routing skill that references this methodology in its Prompt Writing section.
