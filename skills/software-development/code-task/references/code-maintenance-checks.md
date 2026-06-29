# Code Maintenance Checks

> Patterns for finding and fixing code-quality issues across an entire project. Use when the user asks for a code health pass: unused imports, missing trailing newlines, inconsistent styling, dead comments.

## 1. Unused Imports — AST-based Scanning

**Do NOT manually grep for unused imports.** Use Python's `ast` module for accuracy — it catches only truly unused names by checking `ast.Name` and `ast.Attribute` nodes.

```python
import ast

with open(filepath) as f:
    tree = ast.parse(f.read(), filepath)

# Collect top-level imports
toplevel = {}
for node in ast.iter_child_nodes(tree):
    if isinstance(node, ast.Import):
        for alias in node.names:
            name = alias.asname or alias.name
            toplevel[node.lineno] = (name.split('.')[0], alias.name)
    elif isinstance(node, ast.ImportFrom):
        for alias in node.names:
            if alias.name == '*': continue
            name = alias.asname or alias.name
            toplevel[node.lineno] = (name, f'{node.module}.{alias.name}')

# Gather referenced names
used = set()
for node in ast.walk(tree):
    if isinstance(node, ast.Name):
        used.add(node.id)
    elif isinstance(node, ast.Attribute) and isinstance(node.value, ast.Name):
        used.add(node.value.id)

unused = [(lineno, fullname) for lineno, (name, fullname) in toplevel.items() if name not in used]
```

**Verification steps:**
1. Run the AST scan above
2. For each flagged import, `grep -n <name>` the file to double-check (AST can miss string-referenced symbols)
3. After removal, run `python -m py_compile <file>` to confirm syntax is valid
4. For `from X import A, B, C` where only C is unused, edit the line to remove C and fix trailing comma

**When to use:** Before a code-health PR, or when the user asks "clean up unused imports". Don't do this mid-feature.

## 2. Missing Trailing Newlines

POSIX requires text files to end with `\n`. Find violators:

```bash
find . -name '*.py' -not -path '*/__pycache__/*' -not -path '*/.venv/*' \
  | while read f; do
      [ -s "$f" ] && [ "$(tail -c 1 "$f" | xxd -p)" != "0a" ] && echo "$f"
    done
```

Fix by appending a newline. In practice: open the file and add a blank line at the bottom.

## 3. Color Consistency Audit

When checking an Evennia MUD project for color-markup consistency, **categorize by layer**:

| Layer | Files | Approach |
|:------|:------|:---------|
| **Code logic** | `commands/*.py`, `typeclasses/*.py`, `utils/*.py` | Must use `colorize(text, CONSTANT)`. Fix `|G...|n` raw markup here. |
| **Static data** | `world/*.py`, `server/conf/connection_screens.py` | Strings stored in DB at runtime. Raw markup is acceptable — `colorize()` would add unnecessary runtime parsing. Do NOT fix these. |

**Mapping table for Evennia raw markup → named constants:**

| Raw | Constant | Semantic |
|:----|:---------|:---------|
| `\|G` | `COLOR_NORMAL` (N) | Dark green, baseline text |
| `\|y` | `COLOR_HIGHLIGHT` (H) | Bright yellow, highlighted text |
| `\|R` | `COLOR_ERROR` | Red, error/stop messages |
| `\|g` | `COLOR_PROFIT` | Bright green, success/advantage messages |
| `\|W` | `COLOR_VALUE` | White highlight, attribute values |
| `\|n` | Auto-appended by `colorize()` | Reset to `COLOR_NORMAL` |

**Pattern for mixed-color strings (e.g. `|Gtext {H}cmd{N} end|n`):**
```python
# Before:
f"|G已学会身法「{key}」，使用 {H}cmd{key}{N} 来替换。|n"

# After (concatenate colorize calls):
colorize(f"已学会身法「{key}」，使用 ", N) + colorize(f"cmd {key}", H) + colorize(" 来替换。", N)
```

## 4. Batch-Commit Pattern for Mechanical Cleanups

When fixing many small issues across many files (unused imports, trailing newlines, dead comments):

- **Group into one commit** with message `chore: <summary>` (e.g. `chore: remove 13 unused imports, add trailing newlines to 4 files`)
- **Verify each file** individually after edit (`py_compile`)
- **Do NOT** push until user confirms — some cleanups may need review
- **Exception**: if the user explicitly said "一次性改完" or "一起推", batch and push in one go

```
16 files changed, 14 insertions(+), 18 deletions(-)
→ single commit, single push
```
