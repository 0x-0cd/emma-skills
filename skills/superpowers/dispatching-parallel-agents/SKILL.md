---
name: dispatching-parallel-agents
description: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
---

# Dispatching Parallel Agents

## Overview

You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

When you have multiple unrelated failures (different test files, different subsystems, different bugs), investigating them sequentially wastes time. Each investigation is independent and can happen in parallel.

**Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.

## When to Use

**Use when:**
- 3+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem can be understood without context from others
- No shared state between investigations
- **Codebase analysis at scale:** full-project tech debt audit, architecture review, or cross-cutting concern scan (100+ files, 10000+ lines)

**Don't use when:**
- Failures are related (fix one might fix others)
- Need to understand full system state
- Agents would interfere with each other

### Dimension-Based Splitting (for Codebase Analysis)

When analyzing a large codebase, split by **orthogonal dimensions** rather than by file or by subsystem. Each dimension produces findings that can be independently verified and merged:

| Good Dimensions | Bad Dimensions |
|:---------------|:---------------|
| Severity (🔴🟡🟢) — each agent scans the same files for different concerns | By file (agent A scans X, agent B scans Y) — you'll miss cross-cutting issues |
| Concern type (security/performance/architecture/consistency) | By language (Python/JS/CSS) — structural problems cross languages |
| Analysis formula (syntax errors / runtime paths / cycle detection / naming) | By commit author or date — artificial split with zero analytical value |

## The Pattern

### 1. Identify Independent Domains

Group failures by what's broken:
- File A tests: Tool approval flow
- File B tests: Batch completion behavior
- File C tests: Abort functionality

Each domain is independent - fixing tool approval doesn't affect abort tests.

### 2. Create Focused Agent Tasks

Each agent gets:
- **Specific scope:** One test file or subsystem
- **Clear goal:** Make these tests pass
- **Constraints:** Don't change other code
- **Expected output:** Summary of what you found and fixed

### 3. Dispatch in Parallel

```typescript
// In Claude Code / AI environment
Task("Fix agent-tool-abort.test.ts failures")
Task("Fix batch-completion-behavior.test.ts failures")
Task("Fix tool-approval-race-conditions.test.ts failures")
// All three run concurrently
```

### 4. Review and Integrate

When agents return:
- Read each summary
- Verify fixes don't conflict
- Run full test suite
- Integrate all changes

## Agent Prompt Structure

Good agent prompts are:
1. **Focused** - One clear problem domain
2. **Self-contained** - All context needed to understand the problem
3. **Specific about output** - What should the agent return?

### Debugging Prompt

```markdown
Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts:

1. "should abort tool with partial output capture" - expects 'interrupted at' in message
2. "should handle mixed completed and aborted tools" - fast tool aborted instead of completed
3. "should properly track pendingToolCount" - expects 3 results but gets 0

These are timing/race condition issues. Your task:

1. Read the test file and understand what each test verifies
2. Identify root cause - timing issues or actual bugs?
3. Fix by:
   - Replacing arbitrary timeouts with event-based waiting
   - Fixing bugs in abort implementation if found
   - Adjusting test expectations if testing changed behavior

Do NOT just increase timeouts - find the real issue.

Return: Summary of what you found and what you fixed.
```

### Codebase Analysis Prompt

For analysis tasks, each agent gets the **same base context** (project structure, framework version, key files) but a **different analytical lens**. This prevents duplication of shared context while keeping each agent focused:

```markdown
## 分析任务
扫描 XunDaoMUD 项目的 [维度] 问题。

## 项目路径
/home/qn/projects/XunDaoMUD

## 背景事实（共享给所有子 agent）
[project: Evennia 6.0.0, Python 3.12, SQLite, ~4万行]
[codegraph: 1370 nodes / 2561 edges]
[key architecture: layered cmdset, etc.]

## 分析范围（每个 agent 不同的 lens）
Scan all Python sources (exclude __pycache__/.venv/node_modules) for:
- Agent A — 🔴 阻塞级: syntax errors, import cycles, runtime crash paths, PII
- Agent B — 🟡 重度: god files >300 lines, duplicate code, hardcoded magic numbers, naming inconsistencies
- Agent C — 🟢 轻度: stale comments, unused imports, small style drift

## 交付要求
每条发现附精确文件路径和行号范围。
```

## Common Mistakes

**❌ Too broad:** "Fix all the tests" - agent gets lost
**✅ Specific:** "Fix agent-tool-abort.test.ts" - focused scope

**❌ No context:** "Fix the race condition" - agent doesn't know where
**✅ Context:** Paste the error messages and test names

**❌ No constraints:** Agent might refactor everything
**✅ Constraints:** "Do NOT change production code" or "Fix tests only"

**❌ Vague output:** "Fix it" - you don't know what changed
**✅ Specific:** "Return summary of root cause and changes"

**❌ Single monolithic task for large scope:** "Analyze the whole project" in one agent
**✅ Dimension-split:** Split by orthogonal axis (severity, concern type, analysis formula)

### Silent-Hang Trap

When a subagent task is too large (100+ files, 10000+ lines), the terminal-based dispatch (`opencode run --format json` via `terminal()`) can **silently hang** — no error logged, no progress, no crash. You won't know until the user asks or hours pass.

**Prevention:** Any analysis covering the full project must use `delegate_task` with dimension-split, not a single `opencode run` call. `delegate_task` subagents have better isolation and output handling for large scopes.

**Detection:** If a background process doesn't notify within 15 minutes, check the OpenCode log:
```bash
tail -50 ~/.local/share/opencode/log/opencode.log
```
Static log = silent hang. Kill it (`process action=kill`) and switch to dimension-split strategy.

**Recovery:** After killing, check `git diff --stat` to ensure no half-written files were left behind, then re-dispatch as parallel subagents with smaller scopes.

## Variation: Structured Content Generation (Tutorials, Docs, Guides)

When the user asks for a large multi-chapter document (tutorial, guide, blog series, documentation), **parallel content generation with dimension-split by chapter** is the most efficient pattern. Each sub-agent writes independent chapters to disk simultaneously.

### Pattern Diagram

```
User request → "Write a 6-chapter tutorial"
                │
                ├─ Parent: writes Chapter 1 (intro/outline) + handles compilation + delivery
                │
                ├─ Sub-agent 1: Chapters 2-3 (each to its own file)
                ├─ Sub-agent 2: Chapters 4-5
                └─ Sub-agent 3: Chapters 6-8 (remaining + appendix)
```

### Key Differences from Debugging/Analysis Splits

| Aspect | Debugging Split | Content Generation Split |
|--------|----------------|--------------------------|
| Goal | Find root cause and fix | Write prose to a consistent standard |
| Shared context | Codebase structure, error messages | Audience, tool chain, writing style, constraints |
| Each agent's scope | One test file or subsystem | One or two chapters |
| Output | Summary of findings | Markdown file(s) on disk |
| Conflict risk | Agents editing same file | None — each writes to separate files |
| Verification | Run full test suite | Read files, check style and coverage |

### Context Structure for Each Agent

Each sub-agent needs the **same base context** (audience, tools, constraints, overall workflow) but a **different chapter-specific context**. Package it as:

```
## Base context (shared across ALL agents)
- Audience: complete beginners / professionals / etc.
- Recommended tools: [list with download links and prices]
- Constraints: don't recommend X, use Y instead
- Overall workflow/structure: [the master sequence]
- Writing style: tone, formatting, terminology conventions

## Your chapter(s)
- File path: /path/to/output/02_chapter_title.md
- Content requirements: [specific topics to cover, word count ranges]
- Key principles/constraints specific to this section
```

### Flow

1. **Parent prepares**: creates output directory, writes Chapter 1 (outline + intro), crafts sub-agent tasks with carefully separated context
2. **Sub-agents write**: each writes its assigned chapter(s) to files in the shared output directory
3. **Parent compiles**: verifies all files exist, reads snapshots for quality, assembles final package
4. **Parent delivers**: email with attachments, file transfer, or direct presentation

### Pitfalls

- **Overlapping content** between adjacent chapters: each agent's instructions must clearly state boundaries ("Chapter 2 covers X; Chapter 3 covers Y that follows X — do NOT include Y in Chapter 2")
- **Style inconsistency**: all agents must share the same style guidance (tone, formatting conventions, terminology). Without this, compiled chapters feel like different authors
- **File naming convention**: enforce `NN_name.md` in all agent prompts so the parent can glob them predictably
- **Cross-references**: don't let agents write "as covered in Chapter 5" — chapter numbers may shift. Use self-contained references
- **Total output size**: 3 agents x 2 chapters each is comfortable for the parent's context. For 10+ chapters, stagger dispatch or batch differently
- **Sub-agent tool restrictions**: leaf agents cannot use delegate_task, clarify, or memory. They CAN use write_file, terminal, read_file, search_files. Design their task so they can complete it with those tools

### Real-World Example (2026-07-10)

**Request:** "Write a complete photo editing tutorial for Chinese beginners, 8 chapters. No Photoshop. Deliver as markdown files via email."

**Dispatch:**
- Parent (Emma): Chapter 1 (intro, tools, concepts) + compilation + SMTP delivery
- Sub-agent 1: Chapters 2 (basic editing: crop, exposure, white balance) + 3 (skin retouching)
- Sub-agent 2: Chapters 4 (body reshaping) + 5 (color grading with HSL/curves)
- Sub-agent 3: Chapters 6 (export and sharpening) + 7 (complete walkthrough) + 8 (FAQ/appendix)

**Results:** All 8 chapters written in ~2 minutes wall-clock, ~74KB total across 8 files. Compiled, verified, and emailed with 8 attachments. Zero style conflicts because all agents received the same writing-style guidelines in their shared context.

### When to Use This vs. Sequential Writing

| Situation | Approach |
|-----------|----------|
| 3+ independent sections with clear boundaries | Parallel — fastest |
| Content builds on previous sections (tutorial series) | Sequential — later sections need earlier ones |
| User wants iterative review per chapter | Sequential — one at a time, get feedback |
| You have specialized knowledge sub-agents lack | Write it yourself |
| Short document (fewer than 3 sections) | Write it yourself — dispatch overhead not worth it |

## When NOT to Use

**Related failures:** Fixing one might fix others - investigate together first
**Need full context:** Understanding requires seeing entire system
**Exploratory debugging:** You don't know what's broken yet
**Shared state:** Agents would interfere (editing same files, using same resources)

## Real Example from Session

**Scenario:** 6 test failures across 3 files after major refactoring

**Failures:**
- agent-tool-abort.test.ts: 3 failures (timing issues)
- batch-completion-behavior.test.ts: 2 failures (tools not executing)
- tool-approval-race-conditions.test.ts: 1 failure (execution count = 0)

**Decision:** Independent domains - abort logic separate from batch completion separate from race conditions

**Dispatch:**
```
Agent 1 → Fix agent-tool-abort.test.ts
Agent 2 → Fix batch-completion-behavior.test.ts
Agent 3 → Fix tool-approval-race-conditions.test.ts
```

**Results:**
- Agent 1: Replaced timeouts with event-based waiting
- Agent 2: Fixed event structure bug (threadId in wrong place)
- Agent 3: Added wait for async tool execution to complete

**Integration:** All fixes independent, no conflicts, full suite green

**Time saved:** 3 problems solved in parallel vs sequentially

## Key Benefits

1. **Parallelization** - Multiple investigations happen simultaneously
2. **Focus** - Each agent has narrow scope, less context to track
3. **Independence** - Agents don't interfere with each other
4. **Speed** - 3 problems solved in time of 1

## Verification

After agents return:
1. **Review each summary** - Understand what changed
2. **Check for conflicts** - Did agents edit same code?
3. **Run full suite** - Verify all fixes work together
4. **Spot check** - Agents can make systematic errors

## Real-World Impact

From debugging session (2025-10-03):
- 6 failures across 3 files
- 3 agents dispatched in parallel
- All investigations completed concurrently
- All fixes integrated successfully
- Zero conflicts between agent changes

From codebase analysis session (2026-06-25):
- Monolithic single-agent attempt hung for 7 hours (subagent process silent-hang)
- Switched to 3 parallel agents: 🔴🟡🟢 severity dimensions
- All 3 agents returned within 3 minutes
- Zero overlap — each agent found different issues, no conflicts
- Total context saved: ~150K tokens vs running serially
