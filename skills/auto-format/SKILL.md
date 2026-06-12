---
name: auto-format
description: "Use after writing or editing files to auto-format them using the project's configured formatter (ruff, prettier, biome, gofmt, etc.)"
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [format, lint, code-quality, workflow]
    related_skills: [project-init]
---

# Auto-Format — Project-Aware Code Formatting

> After editing files, auto-format them using whatever formatter the project already has configured. Zero AI involvement — deterministic, fast, free.

## When to Use

- **After writing or patching files** — run this to normalize formatting.
- **Before committing** — ensure all files match project style.
- **When joining a new project** — run once to verify formatter setup.

**Don't use for:**
- Auto-fixing linter errors beyond formatting (that's what `ruff check --fix` is for — separate concern).
- Projects with no formatter configured (skip, don't force one).

## Detection Logic

Check these files in order at the project root. First match wins.

| Formatter | Config Files / Detection | Command |
|-----------|--------------------------|---------|
| **Ruff** | `ruff.toml`, `.ruff.toml`, or `pyproject.toml` containing `[tool.ruff]` | `ruff format <file>` or `ruff format` (project) |
| **Biome** | `biome.json`, `biome.jsonc` | `npx biome format --write <file>` or `npx biome check --write <file>` |
| **Prettier** | `.prettierrc`, `.prettierrc.*`, `prettier` in `package.json` devDependencies | `npx prettier --write <file>` |
| **gofmt** | `.go` files exist + `go.mod` present | `gofmt -w <file>` |
| **cargo fmt** | `Cargo.toml` | `cargo fmt` |
| **Black** | `pyproject.toml` containing `[tool.black]`, or `black` in deps | `black <file>` |
| **clang-format** | `.clang-format` or `_clang-format` | `clang-format -i <file>` |
| **shfmt** | `.editorconfig` with shell indent settings, or `.sh` files | `shfmt -w <file>` |

## Usage

### Option A: Format Single File

After writing or patching a specific file:

```markdown
1. Detect formatter from project config.
2. Run formatter on the file.
3. If file changed, show a one-line diff summary.
```

### Option B: Format Changed Files (recommended)

After a batch of edits, format only files that were modified:

```markdown
1. Detect formatter from project config.
2. Run `git diff --name-only` to list changed files.
3. Filter to files the formatter supports (by extension).
4. Run formatter on each changed file.
5. If any changed, show a summary.
```

### Option C: Format Entire Project

```markdown
1. Detect formatter.
2. Run project-wide format command.
3. Show diff summary of any changes.
```

## Implementation Notes

### Before running any formatter
1. **Check if the command exists** — `which <tool>` or try `npx <tool> --version`.
2. If the tool is only available via a package manager (e.g., `npx` for Node tools, `cargo` for Rust), run it via that.
3. **If not available → skip.** Don't install anything without asking.
4. If `npx` is used, add `--yes` or `--no-install` as appropriate (prefer `--no-install` to avoid auto-installing packages).

### After formatting
1. Run `git diff` or `git diff --stat` to show what changed.
2. If nothing changed, report "Already formatted."
3. If something changed, report the files and the diff stat — don't dump full diffs unless asked.

### Python-specific note
Ruff is preferred over Black when both are available (Ruff is faster and does more). Check for Ruff config first, fall back to Black.

## Common Pitfalls

1. **Running formatter on generated files** — check `.gitattributes` or use `git ls-files` to only format tracked files.
2. **npx auto-install** — always use `--no-install` first; if the tool is missing, report it rather than silently installing.
3. **Formatters that change semantics** — e.g., `biome check --write` does more than formatting (lints too). Prefer `biome format --write` unless the user wants lint fixes.
4. **Large diffs** — after project-wide format, show `--stat`, not the full diff.
5. **Pre-commit hooks** — if the project has pre-commit hooks that auto-format, skip manual formatting to avoid double-work.

## Verification Checklist

- [ ] Formatter detected from project config (not guessed)
- [ ] Formatter is available (installed or via npx)
- [ ] Formatted files are tracked by git (not generated/ignored)
- [ ] Diff reviewed — only formatting changes, no logic changes
- [ ] If no formatter found, skipped cleanly (no error spam)
