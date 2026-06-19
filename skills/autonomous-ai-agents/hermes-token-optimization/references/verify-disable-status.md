# Verifying platform_disabled Is Actually Working

After adding skills to `skills.platform_disabled.<platform>` in config.yaml and doing `/reset`, **don't assume it worked** — verify exactly as you would any other config change.

## The Cross-Reference Technique

```
1. CHECK CONFIG  → What SHOULD be disabled?
2. CHECK RUNTIME → What IS actually disabled?
3. CROSS-REFERENCE → Any gaps?
```

### Step 1: Read Config Intent

```python
import yaml
with open('/home/qn/.hermes/config.yaml') as f:
    config = yaml.safe_load(f)
pd = config.get('skills', {}).get('platform_disabled', {})
for platform, disabled_list in pd.items():
    print(f"{platform}: {len(disabled_list)} skills configured as disabled")
```

### Step 2: Check Runtime Status

```bash
hermes skills list
```

Look at the **Status** column — each skill shows `disabled` or `enabled`. The footer line shows totals:
```
0 hub-installed, 60 builtin, 60 local — 56 enabled, 64 disabled
```

### Step 3: Cross-Reference

```python
import subprocess, yaml, re

# 1. Parse hermes skills list output
result = subprocess.run(["hermes", "skills", "list"],
    capture_output=True, text=True, timeout=10)
enabled = set()
disabled = set()
for line in result.stdout.split("\n"):
    if line.startswith("│ ") and "│ disabled │" in line:
        name = line.split("│")[1].strip().replace("…", "")
        disabled.add(name)
    elif line.startswith("│ ") and "│ enabled  │" in line:
        name = line.split("│")[1].strip().replace("…", "")
        enabled.add(name)

# 2. Parse config intent
with open('/home/qn/.hermes/config.yaml') as f:
    config = yaml.safe_load(f)
config_disabled = set(
    config.get('skills', {}).get('platform_disabled', {}).get('qqbot', [])
)

# 3. Cross-reference
still_enabled = config_disabled & enabled
if still_enabled:
    print(f"⚠️  {len(still_enabled)} skills configured as disabled but still enabled:")
    for s in sorted(still_enabled):
        print(f"  - {s}")
else:
    print("✅ All configured-disabled skills are actually disabled")
```

## Common Issues Found by This Technique

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Config says 69 disabled, runtime shows 0 disabled | Config change written but `/reset` never happened | User does `/reset` in chat |
| Config says 69 disabled, runtime shows N < 69 disabled | Some skill names in the config list no longer exist (removed by curator) | Normal — non-existent names are silently ignored |
| Runtime shows extra disabled skills not in config | Curator or other mechanism also disabled them | Usually fine; check if any important skills were caught |
| Config shows N disabled, runtime shows N + M disabled | Platform mix-up — you're looking at the wrong platform's list | Verify current platform with `hermes status` or source context |

## When to Run This

- **After every skill disable operation and `/reset`** — don't move on until verified
- **After curator runs** (which can uninstall or archive skills, making disabled-list entries orphaned)
- **When starting a new platform** — verify the platform_disabled list for that platform is correct

## Pitfalls

- `hermes skills list` shows **all installed skills**, not just the ones for the current platform. The `platform_disabled` filter applies at *load time*, not in the listing. So a skill may appear as "enabled" in the list but still be filtered out of the current session — this is expected.
- **The best check is actual behaviour:** after `/reset`, does `skills_list()` return only the expected set? The footer line shows enabled/disabled totals — that's the ground truth for the current session.
- Skill names in config.yaml must match the `name` field in SKILL.md frontmatter exactly. Mismatched names are silently ignored.
