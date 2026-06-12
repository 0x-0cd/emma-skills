---
name: project-init
description: "Use when entering a new or unfamiliar project to analyze the repo and generate/update AGENTS.md with project-specific guidance"
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [project, init, agents-md, onboarding, workflow]
    related_skills: [writing-plans, idea-to-design-doc]
---

# Project Init — Repo Analysis & AGENTS.md Generation

> Inspired by OpenCode's `/init` slash command. Analyzes a repository from scratch and produces a compact, high-signal AGENTS.md that helps any agent (or human) ramp up fast.

## Overview

When you join a new project — whether it's a fresh clone, a worktree, or a repo you haven't visited in a while — run this skill to:

1. **Discover** the project's structure, toolchain, and conventions.
2. **Extract** high-signal facts an agent would otherwise guess wrong.
3. **Generate** or update `AGENTS.md` in the project root.

The result is a living instruction file that captures "would an agent miss this without help?" information — build commands, test rituals, monorepo boundaries, framework quirks, and team conventions.

## When to Use

- **New project clone** — first time entering a repo you haven't analyzed.
- **Stale context** — returning to a project after weeks/months.
- **Before complex work** — starting a large feature, refactor, or investigation in an unfamiliar codebase.
- **After major project changes** — restructure, migration, new toolchain.

**Don't use for:**
- Trivial scripts or single-file projects (just read the file).
- Projects where AGENTS.md is already fresh and accurate (skip if it is).
- Projects where you lack read access to the root.

## Analysis Workflow

### Phase 1: Surface Scan

Read the highest-signal sources first, in priority order:

1. **`README*`** — project identity, setup, architecture overview.
2. **Root manifests** — `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `Gemfile`, `setup.py`, `cabal.project`, `CMakeLists.txt`, etc.
3. **Workspace & monorepo config** — `turbo.json`, `nx.json`, `lerna.json`, `workspace.yaml`, `BUILD` files.
4. **Build / test / lint / format / typecheck config** — `Makefile`, `Justfile`, `Taskfile.yml`, `tsconfig.json`, `.eslintrc*`, `.prettierrc*`, `ruff.toml`, `pytest.ini`, `.golangci.yml`, `clang-format`, `.editorconfig`.
5. **CI workflows** — `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `circleci/config.yml`.
6. **Pre-commit / husky / lefthook config** — `.husky/`, `.pre-commit-config.yaml`, `lefthook.yml`.
7. **Existing instruction files** — `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.cursorrules`, `.github/copilot-instructions.md`, `CONTRIBUTING.md`.
8. **Environment / Docker / devcontainer** — `.env.example`, `Dockerfile`, `docker-compose.yml`, `.devcontainer/devcontainer.json`.
9. **Project-level OpenCode config** — `opencode.json`.
10. **Lockfiles** — `bun.lock`, `pnpm-lock.yaml`, `package-lock.json`, `Cargo.lock`, `go.sum` — to infer the package manager.

### Phase 2: Architecture Deep Dive (if needed)

If the surface scan leaves architecture unclear, read representative code files to find:

- **Real entrypoints** — `main.go`, `src/index.ts`, `bin/`, `cli/main.rs`, `__main__.py`.
- **Package boundaries** — directory structure under `src/`, `lib/`, `packages/`, `internal/`, `app/`.
- **Execution flow** — how requests/commands flow through the system.
- **Data model** — key schemas, database migrations, API contracts.

Prefer files that *wire things together* over random leaf files.

### Phase 3: Synthesize AGENTS.md

Write or update `AGENTS.md` with ONLY repo-specific, high-signal facts:

#### Include:
| Category | Examples |
|----------|----------|
| **Exact commands** | `pnpm test --filter=@scope/pkg`, `cargo test --integration`, `make build-linux` |
| **Command order** | `lint → typecheck → test` (when order matters) |
| **Monorepo layout** | package ownership, dependency graph, shared configs |
| **Framework quirks** | codegen steps, migration ordering, env loading, build artifacts |
| **Test setup** | fixtures, integration prereqs, snapshot workflows, flaky suites |
| **CI gotchas** | environment-specific steps, required secrets, deploy flow |
| **Existing conventions** | from `opencode.json`, `.cursorrules`, `CONTRIBUTING.md` |
| **Dev server / hot-reload** | how to start, how long it takes, what ports |
| **Deployment** | infra tool, deploy commands, review apps |

#### Exclude:
- Generic software advice ("write clean code", "use meaningful names")
- Long tutorials or exhaustive file trees
- Obvious language conventions ("Python uses `def` for functions")
- Speculative claims or anything you couldn't verify
- Content better stored in another referenced file

#### Style:
- Short sections and bullets. Be compact.
- If the project is simple, keep AGENTS.md simple.
- Start with a one-liner: `# <project> — <one-sentence identity>`.
- Group facts under `## Build & Test`, `## Architecture`, `## Conventions`, `## Quirks`.

#### If AGENTS.md already exists:
- **Improve it in place** — don't blindly rewrite.
- Preserve verified useful guidance.
- Delete fluff or stale claims.
- Reconcile with the current codebase state.
- Add new findings discovered by this analysis.

### Phase 4: Report

Announce what was discovered and saved. Example:

```
## Project Init Complete

**`<project>`** — <one-line description>

**AGENTS.md:** <path> (<N> lines, <M> sections)
**Files analyzed:** README, package.json, Makefile, .github/workflows/ci.yml, ...

**Key findings:**
- Build: `make build` (requires Go 1.22+)
- Test: `make test` or `go test ./...`
- Lint: `golangci-lint run`
- Monorepo with 3 packages under `pkg/`
- Uses sqlx for DB — migrations in `migrations/`
```

## Common Pitfalls

1. **Analysis paralysis.** Stick to the priority order. If README + config already tell you 80% of what matters, skip the deep dive.
2. **Overwriting existing AGENTS.md.** Always improve in place unless the file is completely wrong. Preserve what's accurate.
3. **Writing too much.** If it's generic advice, leave it out. The file should be *shorter* than you think.
4. **Omitting negative facts.** If the test suite requires Docker, or the dev server takes 5 minutes to start, say so. These are exactly the facts an agent needs.
5. **Skipping the CI config.** CI workflows often contain the most comprehensive record of build/test/deploy commands and order.
6. **Not checking for instruction files in multiple locations.** Check all of: `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.cursorrules`, `.github/copilot-instructions.md`.
7. **Forgetting to `.gitignore` AGENTS.md if it's team-sensitive.** Some teams prefer not to commit it. Always commit by default, but respect `.gitignore` if present.

## Verification Checklist

- [ ] AGENTS.md exists at project root
- [ ] Covers at least: build commands, test commands, project identity
- [ ] No generic advice present
- [ ] All claims are verifiable from the codebase
- [ ] Existing AGENTS.md content was preserved where accurate (not wiped)
- [ ] CI workflow was checked for build/test/deploy commands
- [ ] Framework/toolchain versions are noted (e.g., "Node 22+", "Python 3.12+")
- [ ] Quirks and gotchas are documented (things that differ from defaults)
- [ ] File doesn't contain speculative or unverified claims

## One-Shot Recipe: Quick Init

```markdown
Run this when you need a fast AGENTS.md for a straightforward project:

1. Read `README*` and the root manifest
2. Check `Makefile` or equivalent for build/test commands
3. Read any existing AGENTS.md / CLAUDE.md / .cursorrules
4. Write AGENTS.md with build, test, and architecture sections
5. Verify by running a build and a test
```
