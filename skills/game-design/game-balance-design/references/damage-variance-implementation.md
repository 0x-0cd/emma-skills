# Damage Variance ±15% Implementation

Added 2026-06-24 during MUD combat balance iteration.

## Why

The combat system had a deterministic damage pipeline — same monster, same skill, same target = identical damage every hit. This made combat feel mechanical and predictable. No drama, no tension.

The user (project lead) observed this and requested variance.

## Design Iteration

1. **Asked about randomness** — The user proactively asked whether direct damage had any variance. The answer was "none."
2. **Proposed ±10%** — Initial suggestion using `random.uniform(0.9, 1.1)`.
3. **User chose ±15%** — The user responded "加15%吧，每次伤害的最终结果在85%-115%浮动，这样比较有意思" — they wanted a wider, more dramatic range.

## Code Change

One line in `typeclasses/combat/damage.py:_calc_raw_damage()`:

```python
# Before:
return max(int(base * element_factor * realm_rate * attack_rate), 1)

# After:
return max(int(base * element_factor * realm_rate * attack_rate * random.uniform(0.85, 1.15)), 1)
```

Also added `import random` at top of file.

## Why ±15% Works

| Variance | Effect on Combat Feel |
|----------|----------------------|
| ±5% | Barely noticeable — might as well not exist |
| ±10% | Perceptible but safe — good for serious RPGs |
| **±15%** | **Noticeable every fight, still tactical — sweet spot ✅** |
| ±25%+ | Slot machine — impossible to plan strategy |

The 85%-115% range means:
- Best vs worst roll is ~35% difference in damage
- Over a 10-round fight, the variance averages out but each individual hit feels alive
- Combined with ±HP variance on monsters (9-11 HP), two identical monster encounters can play out completely differently

## Distribution Choice

Used `random.uniform()` (flat distribution) rather than `random.triangular()` (bell curve). User accepted this without comment. Uniform distribution produces more extreme values, making variance more noticeable per hit.
