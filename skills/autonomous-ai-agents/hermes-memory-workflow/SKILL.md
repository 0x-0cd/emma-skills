---
name: hermes-memory-workflow
description: "Active maintenance and retrieval for the three-tier progressive-disclosure memory system: MEMORY.md as 元记忆 (meta-memory index, injected every turn) + fact_store (structured facts, on-demand) + skill_view/session_search (full-depth execution). Covers meta-memory architecture, content strategy, Chinese entity annotation, progressive disclosure pattern, deduplication, contradiction detection, and trust feedback."
version: 2.2.0
author: Emma
license: MIT
metadata:
  hermes:
    tags: [hermes, memory, holographic, fact-store, curation, retrieval, workflow]
    related_skills: [hermes-token-optimization, hermes-maintenance, hermes-agent]
---

# Hermes Agent — Memory Workflow

> **Related:** `hermes-token-optimization` covers token-cost-driven consolidation (Method 5) and has `references/holographic-memory-provider.md` for architectural background. This skill covers the **active retrieval and curation workflow** — making the memory system useful day-to-day.

Systematic practices for maintaining and retrieving from the agent's memory. Designed for the three-tier progressive-disclosure architecture: MEMORY.md as 元记忆 (meta-memory index, T1) → fact_store for structured facts (T2) → skill_view/session_search for full-depth execution (T3).

---

## Architecture Overview

The memory system follows **Progressive Disclosure** — a pattern from context engineering where the agent discovers context incrementally rather than loading everything upfront. This maps to a three-tier model:

```
┌──────────────────────────────────────────────────┐
│ T1: DISCOVERY — MEMORY.md (injected every turn)  │
│ Role: 元记忆 (meta-memory) — what exists & where │
│ Content: entity index + retrieval pointer only    │
│ Format: 🏷️ Entity → source (memory/user/fact/     │
│         skill/session) + 1-line description       │
│ Target: <25% utilization (~550 chars at 2200 cap) │
├──────────────────────────────────────────────────┤
│ T2: ACTIVATION — fact_store (Holographic)         │
│ Role: structured facts on demand                  │
│ Content: tool details, project records,           │
│          reference data, history                  │
│ Operations: add / search / probe / reason /       │
│             related / contradict / feedback       │
│ Trigger: task context matches an entity           │
├──────────────────────────────────────────────────┤
│ T3: EXECUTION — skill_view / session_search       │
│ Role: full-depth context when needed              │
│ Content: skill bodies, reference files, session   │
│          transcripts, past decisions              │
│ Trigger: probe/search turns up enough signal      │
│          to warrant deeper retrieval              │
└──────────────────────────────────────────────────┘
```

**The key shift:** MEMORY.md is NOT a dump of all important facts. It's a **discovery index** — just enough for the agent to know _what_ knowledge exists and _where_ to retrieve it from the lower tiers. Concrete facts live in T2/T3 and are pulled JIT.

**Principle:** "Every token in context has an opportunity cost. If a fact isn't needed this turn, it shouldn't be in MEMORY.md."

See `references/progressive-disclosure-research.md` for the context-engineering literature this draws from (Anthropic, SwirlAI, Third i case study).

---

## Content Strategy (Meta-Memory — What Goes Where)

The guiding principle: **MEMORY.md is a discovery layer, not a fact dump.** Each entry is a 元记忆 (meta-memory) entry — an index pointer that says "this exists, here's how to find details."

### MEMORY.md Format (元记忆 — targets under 500 chars total)

Group entries by domain with emoji prefixes for scannability:

```markdown
👤 用户 → memory:user（哥哥杭州/苏州，早8晚12，可互怼不爆粗）
🔐 安全 → memory:user（隐私红线·GitHub禁PII·kill确认两次）
📂 项目 → fact_store probe('project')
🔧 工具链 → fact_store search('tool|config|provider')
📖 工作流 → fact_store search('workflow|conventions')
🔄 同步 → skill_view('hermes-agent-migration') §cron
🌐 代理 → memory:memory（代理网络操作 SOP·mihomo启停/节点选择）
📚 书单 → fact_store search('reading')
```

Each entry has three parts:
1. **Emoji category** — visual scannability
2. **Entity name** — the thing that exists
3. **Pointer** — `source(query)` — explicit path to retrieve details

### What Belongs in MEMORY.md (identity layer only)

- **User identity and communication constraints** — 1-2 entries, pointer to `memory:user`
- **Security and privacy rules** — must be visible every turn to prevent violations
- **The Content Strategy itself** (this section) — so the agent knows the format
- **Domain pointers** — 1 line per major domain, pointing to the correct retrieval tool

**Conscious exclusion:** Tool paths, exact commands, project details, historical facts, config specifics — all live in T2 (fact_store) or T3 (skills/sessions).

### Put in fact_store (activation layer)

- **Tool details**: exact paths, commands, config locations, installation records
- **Project records**: repo URLs, migration tools, skill lists, backup info
- **Historical facts**: past events, decision records, session-derived notes
- **Reference data**: pricing tables, model specs, API details, environment quirks

### Put in skills / session_search (execution layer)

- **Procedures and workflows**: complex multi-step tasks → `skill_view`
- **Past decisions and context**: session history → `session_search`
- **Detailed reference material**: error transcripts, provider quirks → skill `references/`

### When In Doubt

| Frequency | Needs | Store |
|-----------|-------|-------|
| Every turn | Identity, security, retrieval pointers | MEMORY.md (元记忆) |
| Every session | User preferences, communication rules | `memory:user` |
| When topic comes up | Project details, tool config | `fact_store` (probe) |
| On task match | Workflow procedures | `skill_view` |
| Rare / historical | Past decisions, session context | `session_search` |

---

## Memory Calibration Protocol (User-Initiated Correction Loop)

This is a distinct workflow from the user-initiated cleanup (Phase 2 above). Calibration is triggered when the user says "咱们来进行一个记忆校准" or equivalent. The user actively corrects your understanding; your job is to present, absorb, and update.

### The Four Dimensions

When the user asks for calibration, present your current understanding structured across exactly these four categories:

| # | Dimension | What It Covers | Where It Lives |
|---|-----------|----------------|----------------|
| 1 | **对用户的认知** | Identity, background, work, personality, preferences | `memory:user` + `fact_store search('background|patent|preference')` |
| 2 | **对Emma的认知** | My role, capabilities, platform constraints, identity | `memory:user` (inline) + `fact_store search('email|权限')` |
| 3 | **对约束的遵循** | Privacy redlines, safety rules, testing iron laws, approval gates | `memory:memory` (core inline) + `memory:user` |
| 4 | **对工作流的理解** | Project workflow, coding pipeline, quality gates, memory management | `memory:memory` (meta-index) + `fact_store search('conventions')` |

### Procedure

**CRITICAL: One-by-one is mandatory, not optional.** The user has explicitly rejected batch summaries ("这个记忆内容已经压缩得有点变形了…我们来整个重新过一遍。你一条一条问我"). Presenting a big summary first and asking for batch corrections leads to missed errors. Always go entry by entry from the start.

```markdown
1. IDENTIFY — Scan current MEMORY.md, USER.md, fact_store, and relevant skills
2. ORGANIZE — Structure findings into the 4-dimension format above
3. PRESENT — Go through entries ONE AT A TIME, not all at once. For each entry:
   - Show the content verbatim as an assertion the user can confirm/deny
   - Ask "这条还准确吗？要改什么？"
   - Wait for response before moving to the next entry
   - Start with dimension 1 (对用户的认知) and work through all four
   - All rule entries should be in Chinese (用户偏好中文)
4. ABSORB — For each correction:
   a. Acknowledge it explicitly ("修正: 旧X → 新Y")
   b. Update memory: user identity facts → `memory:user replace`
   c. Update memory: environment facts → `memory:memory replace/remove`
   d. Update fact_store: detailed facts → `fact_store remove + add` (old_id → new structured entry)
   e. Update skills: workflow/correction → `skill_manage patch`
   f. Clean up stale references (cron prompts, skill examples, duplicate entries)
5. VERIFY — Search ~/.hermes/ for remaining stale terms to confirm full removal
6. REPORT — Present a diff summary showing what changed per dimension
```

### Pitfalls

- **Don't use `fact_store(action='update')` for content changes** — It doesn't re-extract HRR entities. Use remove + add instead.
- **Don't forget external references** — Cron prompts, skill files, and reference docs may contain stale terms. Check them.
- **Don't treat the four dimensions as fixed** — New dimensions may emerge. Note them and update this skill section.
- **Don't skip verification** — Always grep/stale-search after corrections to catch hidden copies (log files are exempt).
- **User corrections to factual details are memory updates, not skill updates** — Only workflow/approach corrections belong in skills. Factual corrections (how many years, which company, what date) go to memory/fact_store.
- **memory tool `replace` requires non-empty `content`** — `memory(action='replace', old_text='...', content='')` FAILS with "content is required". To delete an entry, use `memory(action='remove', old_text='...')`. To modify, both `old_text` (to identify) and `content` (the replacement) are mandatory.
- **Batch memory operations are all-or-nothing** — If ANY operation in the batch fails validation, NONE are applied. Validate every operation's parameters before submitting. Common mistakes: using `replace` where `remove` is needed, missing `old_text` on remove/replace.
- **Layering check should cover all three tiers** — During calibration or reorganization, audit MEMORY.md, USER PROFILE, AND fact_store for overlap, bloat, and stale entries. Don't stop at MEMORY.md — USER PROFILE often has duplicate entries (same preference stated in both places), and fact_store accumulates untagged/stale entries that need cleanup.

---

## Retrieval Protocol (Memory-First)

This is the **fixed workflow** that activates at the start of every task:

```
1. Identify relevant entities from the task description
2. probe("entity") — get all facts about a core entity
3. reason(["entityA", "entityB"]) — find intersection facts (multi-entity AND)
4. search("keywords") — FTS5 fallback if probe/reason miss
5. Only then check MEMORY.md or ask the user
```

**Why this order:**
- `probe()` uses HRR algebra to find structurally relevant facts, not just keyword matches
- `reason()` does multi-entity AND semantics — no vector database can do this
- `search()` is the familiar FTS5 keyword fallback
- MEMORY.md data is always in context already (injected), so step 5 is mostly reassurance

**Implementation:** Encoded in MEMORY.md as Workflow规约 step ⑤.

---

## Structured Entry Formatting (Chinese Entities)

HRR's entity extractor uses regex patterns: capitalized multi-word phrases, double-quoted terms, single-quoted terms, and AKA patterns. For Chinese content, **double-quoted terms are the primary detection mechanism**.

### Good (entities detected by HRR):
```
"VPN"配置：clash+mihomo(HTTP:7890 SOCKS:7891香港)
"clashctl"命令：clashping -N 测延迟, clashuse "节点名"切换
"RTK"(Rust Token Killer) v0.42.3 安装到 ~/.local/bin/rtk
```

### Bad (entities missed by HRR):
```
VPN配置：clash+mihomo
clashctl命令：clashping
RTK已安装
```

### Entity Annotation Rules
1. **Wrap key entities in double quotes** — `"实体名"` is the primary mechanism for Chinese content
2. **Tag system** — use comma-separated tags in the `tags` field for additional cross-referencing (e.g., `vpn,clash,network`)
3. **Category system** — use meaningful categories:
   - `tool` — tool paths, commands, config
   - `project` — repo URLs, migration tools
   - `user_pref` — user's stated preferences, personality
   - `general` — historical facts, general knowledge
4. **One self-contained fact per entry** — avoid multi-paragraph entries; split into atomic facts linked by shared entities
5. **Be concise but complete** — include enough context that a future agent (who may not remember the conversation) can understand the fact

---

## Deduplication Pass

Run periodically (trigger: when fact_store exceeds ~100 entries, or user says "整理记忆").

### Detection Patterns
| Pattern | What to Look For | Resolution |
|---------|-----------------|------------|
| **Exact duplicate** | Same content text | Remove one (UNIQUE constraint catches this on add) |
| **Near duplicate** | Slightly different wording of same fact | Keep the more detailed/updated version |
| **Triple repetition** | 3+ entries about same repo/tool | Merge into one fully-annotated entry |
| **English + Chinese** | Same rule in EN + ZH | Keep ZH (user's primary), remove EN |
| **Outdated vs updated** | Older and newer version of same info | Keep latest, remove older |
| **Circular navigation hint** | Fact content is just `"🏷️ Entity→fact_store search('...')"` — a pointer telling the agent to search the same store it's stored in. These are navigation hints that belong in MEMORY.md (where they're injected every turn), not in fact_store. Storing them here creates a dead-end reference that wastes retrieval slots and never provides actual information. | **Remove** — the target data either exists as separate substantive facts or doesn't exist at all. If the data doesn't exist and the hint was the only entry, the pointer was dead all along. |

### Step-by-Step Procedure

1. **List all facts** — `fact_store(action='list', limit=N)` to see current catalog
2. **Identify overlapping groups** — scan for same entities, topics, or tool names appearing multiple times
3. **For each group:**
   - a. Pick the best entry to keep (most complete, latest, with entity annotations)
   - b. Remove duplicates: `fact_store(action='remove', fact_id=N)`
   - c. Optionally update the survivor with merged content: `fact_store(action='update', fact_id=N, content='...')` — but update only edits, doesn't re-annotate entities; if the survivor needs entity annotations, remove it and `add` a new one instead
4. **Verify** — `fact_store(action='list')` and scan one more time for remaining overlap

---

## Contradiction Detection

```bash
# Via the fact_store tool:
fact_store(action='contradict')
```

This scans all facts for high entity overlap + low content similarity = potential contradictions. Uses O(n²) comparison across up to 500 facts.

**When to run:**
- Monthly maintenance
- After batch-adding 10+ facts
- When the user says "我怎么记得之前说过不一样的话"

**How to resolve contradictions:**
1. `fact_store(action='search', query='...')` to find the conflicting entries
2. Read both, determine which is correct
3. Remove or update the incorrect one
4. Optionally provide feedback so the trust system learns: `fact_store(action='feedback', fact_id=N, helpful=True/False)`

---

## Trust Score Feedback Loop

Every fact starts at 0.5 trust. After retrieval, provide feedback to tune the system:

```
# Fact was useful — trust += 0.05
fact_store(action='feedback', fact_id=N, helpful=True)

# Fact was wrong or misleading — trust -= 0.10
fact_store(action='feedback', fact_id=N, helpful=False)
```

**Why asymmetrical:** False information is more harmful than missed information. Wrong facts lose trust faster than correct ones gain it.

**Thresholds:**
- `min_trust=0.3` (default for most queries) — facts below this are excluded from results
- Cleanup candidates: facts with trust ≤ 0.2 should be reviewed for deletion

---

## Proactive Maintenance Triggers

Don't wait for the user to say "整理记忆". Initiate a maintenance pass when:

| Signal | Priority |
|--------|----------|
| MEMORY.md usage crosses a threshold (≥40% → consider, ≥60% → prioritize) | Medium |
| fact_store exceeds ~100 entries | Low |
| User mentions something that feels like "这个我记得我说过"/"我记得有个事实关于..." | High — that's a retrieval failure, likely due to missing annotations |
| After batch-adding 10+ facts in one session | Medium |
| Empty fact_store on a mature system (likely never populated) | High — do an initial populate |
| User says "整理一下记忆"/"更新记忆"/"看看记忆" | High — immediate action |
| LCM lifecycle shows 50+ stale session references that could contain uncaptured facts | Medium — run a Memory Audit sweep (Phase 0.5) |
| User asks to "清理其他session" without explicitly asking for memory extraction | High — audit first, then clean |

**For each trigger, estimate the scope and pick the right procedure below.**

---

## Calibration Sessions (记忆校准)

When the user sends only "记忆校准" as a message, initiate a full memory calibration session.

### Step-by-Step Procedure

1. **Load all sources** — Pull MEMORY.md, user profile, and fact_store (list all) in parallel
2. **Go through ONE ENTRY AT A TIME** — Do NOT present a big summary and ask for batch corrections. The user explicitly prefers one-by-one review to catch errors that batch review misses.
3. **For each entry:**
   a. Show the entry content verbatim
   b. Ask: "这条还准确吗？要改什么？"
   c. Wait for user response before proceeding to the next entry
4. **Apply corrections as they come in** — Don't accumulate and apply at the end
5. **After all entries reviewed**, present a diff summary showing what changed

### Four Dimensions (organizational structure for the review)

| # | Dimension | What It Covers | Where It Lives |
|---|-----------|----------------|----------------|
| 1 | **对哥哥的认知** | Identity, background, preferences, communication style | `memory:user` + `fact_store search('background|patent|preference')` |
| 2 | **对Emma的认知** | My role, capabilities, constraints | `memory:user` (inline) + `fact_store search('email|权限')` |
| 3 | **约束遵循** | Privacy redlines, safety rules, testing iron laws, approval gates | `memory:memory` (core inline) + `memory:user` |
| 4 | **工作流理解** | Project workflow, coding pipeline, quality gates, memory management | `memory:memory` (meta-index) + `fact_store search('conventions')` |

### Pitfalls Specific to Calibration

- **Fabricated/hallucinated fact_store entries** — The LLM may have invented facts that were never confirmed by the user (e.g., a "to_emma" GitHub repo that never existed but persisted as fact #12). During calibration, treat every factual claim as suspect until the user confirms it. If the user says "没有这回事", remove it immediately — don't argue or rationalize.
- **Compression corruption in fact_store** — Over many compression cycles, names and details can degrade (e.g., "哥哥" → "钱哥", paths get mangled). During calibration, flag any entry where names look wrong or garbled — ask the user to confirm.
- **Don't present everything at once** — Presenting the full four-dimension summary overwhelms the user and leads to missed corrections. Go one entry at a time, starting with dimension 1.

**Suggested cadence:** Quarterly (every 3 months), or event-driven (job change, frequent corrections, contradict() triggers).

---

## Reorganization Workflow (4-Phase)

When a proactive trigger fires or the user asks for memory cleanup, follow this sequence:

### Phase 0: Quick Compaction (Memory Near Capacity)

**When to use:** MEMORY.md is at ≥50% utilization but there's no time for a full meta-memory conversion. Apply quick wins to buy time.

**Principle:** Remove redundancy and compress before restructuring. This is faster than full conversion and often frees 30-50% capacity.

#### Step 1 — Identify Redundancies

Scan for these patterns:

| Pattern | Signal | Action |
|---------|--------|--------|
| **Duplicate rules** | Same rule written twice (e.g. "隐私红线" as plain text + as emoji pointer) | Pick one, remove the other |
| **Already in fact_store** | Tool paths, command details, version numbers | Remove from memory (already moved) |
| **Historical/completed** | "TDD改造完成(2026-06-16)" — event that's past | Remove or condense to one line |
| **Outdated** | Refers to an older state that's been superseded | Remove |

#### Step 2 — Merge Overlapping Entries

When two entries cover the same topic (e.g. "隐私红线" and "隐私红线更新"), merge them into one:

1. **Draft the merged entry** — combine both contents, removing overlap
2. **Replace** the larger/better-target entry: `memory(action='replace', old_text='...', content='<merged>')`
3. **Remove** the other: `memory(action='remove', old_text='...')`

This is more efficient than removing both and adding a new one — `replace` keeps the entry's identity and slot.

#### Step 3 — Compress Verbose Blocks

Large single entries (e.g. an emoji pointer block taking 500+ chars) can be compressed:

- Remove section headers that are obvious from context
- Merge multiple emoji lines into one pipe-separated line: `📂 项目→fact_store｜🔧 工具链→fact_store search('tool')｜...`
- Shorten prose descriptions to keywords
- **Target:** each entry under 200 chars unless it's a multi-line procedure

#### Step 4 — Measure

```
memory(action='replace', …, content='<compressed>')  # or remove
# Then verify:
# Before: N chars, M entries
# After: N' chars, M' entries
# Goal: <50% utilization
```

#### Running in Parallel

`memory(action='remove')` and `action='replace'` calls are independent — each matches by `old_text` and modifies a single entry. They can be issued in parallel (same batch) when they target different entries. Keep removes in a separate parallel batch from replacements if they share the same old entry.

**Trade-off:** Quick compaction is shallower than full meta-memory conversion. Details that were removed (not moved to fact_store) become recoverable only via session history. Once compacted, schedule a full Phase 2 conversion at the next maintenance window if memory creeps back up.

---

### Phase 0.5: Memory Audit — Pre-Cleanup Sweep

**When to use:** Before running `hermes sessions delete` on old sessions. Verify no important content will be lost — especially cross-session facts that weren't captured individually.

**The insight:** Session state.db cleanup and memory extraction are separate concerns. Don't delete sessions from state.db without first checking whether the LCM database still holds uncaptured facts from those sessions. LCM retains raw messages from sessions long after state.db references are gone.

#### Step 1 — Broad Sweep (All Sessions)

Use `lcm_grep(session_scope='all')` to scan EVERY known session for content that might not be in memory yet. Run multiple queries covering distinct domain facets:

```python
from hermes_tools import lcm_grep

# Domain-spanning keyword sets — tailor to the user's world
for query in [
    "记忆 记得 记住 重要 配置 偏好 习惯",   # user preferences & config
    "项目 开发 分支 仓库 repo git",            # project work
    "设置 配置 安装 API key token 密码",       # tooling & credentials
    "skill 技能 工作流 workflow 流程",          # skill/workflow content
]:
    result = lcm_grep(query=query, session_scope='all', limit=30)
    # Inspect results for sessions with potentially uncaptured content
```

Also run `session_search()` (browse, no args) to see recent sessions with previews, and `hermes sessions list` for CLI visibility.

#### Step 2 — Read Candidate Sessions

For each session that contains potentially new content:
- `session_search(session_id='...')` to load the full transcript
- If the session is large, scroll to key messages via `around_message_id`

#### Step 3 — Cross-Reference Against Current Memory

```python
from hermes_tools import memory

# Read current memory to see what's already captured
current_memory = memory(action='list', target='memory')
# Also check user profile
user_profile = memory(action='list', target='user')
# Optionally check fact_store for structured facts
# fact_store(action='list', limit=50)
```

For each candidate fact from old sessions, check if it already exists in current memory. If yes → skip. If no → proceed to Step 4.

#### Step 4 — Fill Gaps

For genuinely new content from old sessions:
- **User preferences / corrections / identity facts** → `memory(action='add', target='user', content='...')`
- **Environment / project / tooling facts** → `memory(action='add', target='memory', content='...')`
- **Structured knowledge** (benchmark results, API quirks, config commands) → `fact_store(action='add', content='...')`

#### Step 5 — Process Sessions Not in state.db

When `lcm_grep(session_scope='all')` returns sessions that are NOT in `hermes sessions list` (57 out of 60 is typical after prior cleanup), these are LCM-only — they've already been deleted from state.db. Their raw messages remain in LCM as historical context for compression. No further cleanup action needed, but the memory audit steps above still apply.

#### Pitfall: lcm_grep has a 30-result cap per query

Run multiple queries with different keyword combinations (see Step 1). The domain-spanning sets shown above typically cover >90% of important content. For thorough coverage, add domain-specific queries based on the user's world.

---

### Phase 0.6: Integrated Session Cleanup — Extract → Compact → Delete

**When to use:** After Phase 0.5 has identified what to capture, and the user asks to "review old sessions and clean up". This is the reactive counterpart to the proactive audit — the user is explicitly asking you to process and delete sessions.

**The pattern:** Review old sessions → extract important info → consolidate memory → delete processed sessions. Execute in one continuous flow.

#### Step 1 — Browse and Select

```python
# Start here — list recent sessions
session_search()  # browse mode

# For each active session, load its content
session_search(session_id='<id>')  # read full or truncated
```

**Target:** Identify which sessions are old enough to clean. Sessions still in an active discussion chain (user said "下个session继续") are safe to delete — the important decisions have been made.

#### Step 2 — Extract Key Info from Each Session

For each session, distill into durable facts:

- **Commits, merges, deployments** — the concrete output. Last commit hash + summary.
- **User decisions and approvals** — "哥哥说✅", "符合预期", "下个session继续"
- **Design principles that emerged** — naming conventions, architectural choices
- **Tool/workflow fixes** — symlinks created, config changes, new commands discovered

**Format tip:** Compress each session's outcome into 1-2 lines. A session with 296 messages usually reduces to 3-5 bullet points of durable facts.

#### Step 3 — Check Memory Capacity Before Adding

```python
# Understand current memory pressure
# If memory is at ≥90% capacity, compaction is required before adding
# Run memory(action='add') — if it fails with a capacity error, proceed to Step 4
```

**Capacity wall is a feature, not a bug.** The 2,200-char limit forces you to prioritize. When the error fires:
- Don't panic and delete random entries
- Don't try to lower utilization first (that wastes tool calls reading state you already have)
- **The fastest path:** Find one entry that overlaps with your new content → use `memory(action='replace')` to merge them → retry the `add`

#### Step 4 — Consolidate Before Adding

The specific compaction strategy depends on what's in memory:

| Pattern | Ideal Replacement Candidate | Action |
|---------|---------------------------|--------|
| **Overlapping domain** | An existing entry about the *same project/tool* that's older | `replace` — merge old + new into one entry, free exactly 1 slot |
| **Pointer entry** | A short entry that just says "→ fact_store" (and the target exists) | `remove` — the pointer is already redundant with fact_store |
| **Low-value detail** | Historical fact that's no longer relevant (completed migration, old version) | `replace` or `remove` |
| **Compressible block** | Multi-line entry that can be densified | `replace` with compressed version |

**Key insight:** Use `replace` (not `remove` + `add`) when the new and old content belong in the same entry. `replace` keeps the entry's identity slot and is one tool call instead of two. Reserve `add` for genuinely new topics that don't overlap with any existing memory entry.

```python
# Example: old entry about XunDaoMUD project pointer
# New entry: session outcome covering the same project
# → Replace, merging old pointer with new dev progress
memory(action='replace', 
       old_text='寻道MUD→fact_store probe', 
       content='XunDaoMUD 路径~/projects/XunDaoMUD... [合并旧指引+新进度]')
```

#### Step 5 — Add Remaining New Facts

After compaction frees space, `add` any remaining new entries that don't fit naturally into the merged entry. Memory is now in a compact state.

#### Step 6 — Delete Processed Sessions

```bash
hermes sessions delete <session_id_1> --yes
hermes sessions delete <session_id_2> --yes
# ... (one per session, parallel when independent)
```

**Safety:** Run `session_search()` (browse) after deletion to confirm all targeted sessions are gone and only the current session remains.

#### Pitfall: Compaction-first vs Add-first

**Wrong order:** `add` new entries → hit capacity error → then `replace` to consolidate. This wastes the first `add` call and its error output.

**Right order:** Before any `add`, check whether you're near capacity. If the last `add` failed with "exceeds limit", the fastest recovery is: (a) identify an overlapping entry, (b) `replace` it with merged content, (c) retry the `add`. Do not read current memory first — you already know what's there from the current tool results.

#### Pitfall: Don't delete sessions you haven't read

The `hermes sessions delete` command accepts any session_id — there's no guard against deleting a session whose content you didn't review. Always read (or confirm from prior knowledge) before deleting. A session deleted from state.db is only recoverable via LCM's raw message store (which may have been compacted).

#### Pitfall: Session DB browse shows sessions chronologically

`sessions_search()` (browse) returns sessions ordered by recency. Sessions from earlier today may appear alongside sessions from yesterday. Sort by scanning the `when` field in each result — don't assume all sessions visible were created today.

#### Pitfall: Session deletion here vs in hermes-maintenance

`hermes-maintenance` skill → Session Store Maintenance → Workflow covers the mechanical deletion (`hermes sessions delete` / `hermes sessions optimize`) as a separate operation. This phase focuses on the **extraction + compaction** that must happen **before** mechanical deletion. The two skills overlap, but the concern here is data integrity (don't delete before extracting), not the CLI mechanics.

#### Pitfall: Cross-session lcm_grep results show raw messages, not summaries

Expanding summary nodes from past sessions is not supported cross-session in current LCM. Raw message snippets are sufficient for the audit — if you find a snippet mentioning an unfamiliar entity or fact, save it to memory. The full context can be reconstructed from the snippet content.

---

### Phase 1: Structure fact_store Entries

**Goal:** Ensure existing and new facts have proper Chinese entity annotation for HRR probe compatibility.

```
1. For each fact to add:
   a. Identify the core entity (tool name, person, project, concept)
   b. Format as: "实体名"描述... — double-quote the entity
   c. Assign category (tool | project | user_pref | general)
   d. Add comma-separated tags for FTS5 fallback
   e. Check content is self-contained (a future agent should understand without context)
2. Do a probe("entity") after adding to verify HRR detected the entity
3. If probe returned nothing, the entity wasn't annotated — fix and re-add
```

### Phase 2: MEMORY.md Meta-Memory Conversion

**Goal:** Convert MEMORY.md from a fact dump to a pure 元记忆 (meta-memory) index. Identity/preferences stay inline; everything else becomes a pointer.

**Two execution strategies** — pick the right one based on how many entries are being moved:

#### Strategy A: Per-Entry Conversion (≤5 entries to move)

Best for incremental maintenance where only a few entries need relocation. Follows the original verify-before-replace cycle per entry.

```
1. Read current MEMORY.md content via memory(action='list', target='memory')
2. Classify each entry by function (see Strategy B for classification guide)
3. For each entry being MOVED:
   a. ADD the fact to fact_store first
   b. VERIFY it landed via `fact_store(action='probe', entity='EntityName')`
   c. ONLY IF probe returns the expected content → create the pointer in memory
   d. If probe returns nothing → entity annotation may be wrong; fix and re-add
4. Format survivors as emoji + entity + pointer (see Content Strategy above)
5. Remove the old inline content from MEMORY.md
6. Measure: record char count before and after
```

#### Strategy B: Batch Conversion (6+ entries to move, or full conversion from >80% to <50%)

**Faster than per-entry cycling** because it separates the fact_store work (independent) from the memory work (sequential). The order matters:

```
1. Read current MEMORY.md content via memory(action='list', target='memory')
2. Classify every entry into three buckets:
   - KEEP inline — identity, security, privacy, workflow rules (must be visible every turn)
   - MOVE to fact_store — tool paths, project details, reference data, environment info, health
   - REMOVE entirely — completed tasks, outdated history, duplicates
3. BATCH-ADD all MOVE entries to fact_store (parallel — independent calls)
   - Annotate each with "EntityName" in double quotes for HRR detectability
   - Use meaningful categories and comma-separated tags
4. BATCH-VERIFY with probe() calls for key entities
   - `fact_store(action='probe', entity='EntityName')`
   - If any probe misses → fix the annotation and re-add that entry
5. BATCH-REMOVE all old memory entries (parallel — independent)
   - Each call uses old_text to uniquely identify the entry
   - Batch up to 6 removes per tool invocation
   - This frees capacity for the new compact format
6. BATCH-ADD all new compact pointer entries (parallel)
   - Inline rules as full sentences with emoji prefixes
   - Pointers as `emoji Entity→fact_store probe/search('keyword')`
7. Measure: record char count and entry count before and after
```

**Why Strategy B is faster:** fact_store additions and memory removals are both parallelizable (independent tool calls). The per-entry cycling in Strategy A makes 3 calls per entry (add→verify→remove old→add new), while Strategy B does the entire conversion in 4-6 batch rounds regardless of entry count.

#### Classification Guide

```
- Identity/communication constraints → KEEP inline (pointer to memory:user)
- Security/privacy rules → KEEP inline (must be visible every turn)
- Workflow rules needed every turn → KEEP inline (compressed)
- Tool details (paths, commands, config) → MOVE to fact_store, replace with pointer
- Project records (repos, migration tools) → MOVE to fact_store, replace with pointer
- Reference data (pricing, model specs) → MOVE to fact_store, replace with pointer
- Environment info (deployment, paths) → MOVE to fact_store, replace with pointer
- Health info, personal facts → MOVE to fact_store, replace with pointer
- Historical/completed task records → REMOVE entirely
```

#### Verification Best Practice

Use **`probe()`** (not `search()`) for verifying entity-annotated facts. probe() uses HRR algebra to match structured entities; search() uses FTS5 keyword matching and can miss entries due to tokenizer quirks (especially with Chinese content or the `|` OR operator).
- After batch-add, run `fact_store(action='probe', entity='关键实体')` for each core entity
- Only proceed to memory cleanup if probe() confirms the tip is retrievable

**CRITICAL: Verify-before-replace rule.** This is the most common failure mode — proposing a pointer without confirming the target data exists at the destination. Every pointer replacement MUST be preceded by a verification step.

Without verification, a pointer in MEMORY.md silently dead-ends — the agent reads "→ fact_store search('reading')" but the target doesn't exist. The data becomes recoverable only via LCM session backups, which is unreliable and costly. If in doubt, keep the inline content AND add the pointer side-by-side until verification confirms both paths work.

### Phase 3: fact_store Deduplication

**Goal:** Remove overlapping/outdated facts; keep only the best version of each.

```
1. List all facts: fact_store(action='list', limit=1000, min_trust=0)
2. Group by topic (same entity, same tool name, same project)
3. For each group, identify the survivor:
   - Prefer the one with Chinese entity annotations
   - Prefer the newer one for updated info
   - Prefer ZH over EN for same rule
   - Prefer more detailed over brief
4. Remove duplicates: fact_store(action='remove', fact_id=N)
   - Parallelized when possible (all removes are independent)
5. Optionally merge content into the survivor (remove-and-re-add if entity annotations need fixing)
6. Measure: record fact_store count before and after
```

### Post-Cleanup Validation

```python
# Check MEMORY.md health
memory(action='list', target='memory')  # verify <40% if possible
# Check fact_store health
fact_store(action='list', limit=5)  # spot check
# Verify probe still works for key entities
fact_store(action='probe', entity='RTK')
fact_store(action='probe', entity='VPN')
```

If probe misses key entities, re-add those facts with proper `"entity"` annotation.

**Session cleanup**: After memory extraction, delete processed sessions via `hermes sessions delete <id> --yes` (see `hermes-maintenance` skill → Session Store Maintenance → Workflow). Run `hermes sessions optimize` or `sqlite3 ~/.hermes/state.db "VACUUM;"` to reclaim disk space.

---

## MEMORY.md Capacity Planning

Default cap: `memory_char_limit: 2200` (Hermes default). User may have adjusted — check config.

With meta-memory format, the target shifts significantly lower:

| Usage | State | Action |
|-------|-------|--------|
| <25% (~550 chars) | Ideal — pure 元记忆 | Healthy. Add new domain pointers freely. |
| 25–50% (~1,100 chars) | Getting crowded | Review: are there concrete facts mixed in? Move to fact_store. |
| 50–80% | Emergency | Strip all details to pure index format. |
| >80% | Buffer overflow | Raise `memory_char_limit` via `hermes config set` as temporary relief. |

### Meta-Memory Conversion (from fact-dump to index)

When MEMORY.md has too many concrete facts:

1. Identify entries that describe a **specific fact** (tool path, command, project detail) rather than pointing to a retrieval source
2. Move each concrete fact to fact_store via `fact_store(action='add', content='...', ...)`
3. Replace the MEMORY.md entry with a 元记忆 pointer: `🏷️ Entity → fact_store search('keyword')`
4. Test: after conversion, does the agent still know where to find the info? (`fact_store(action='probe', entity='...')`)

### MEMORY/Memory Expansion — NOT the First Response

**Default**: Hermes ships with `memory_char_limit: 2200`. The user may have adjusted it higher (e.g. to 4000); never assume — check `grep memory_char_limit ~/.hermes/config.yaml` first.

**Prefer meta-memory conversion over cap expansion.** Before raising the limit:
1. Run Phase 2 (Meta-Memory Conversion) above
2. If still above 50% after conversion, then consider expansion

```bash
# Only expand after meta-memory conversion proves insufficient:
hermes config set memory_char_limit <N>      # top-level key
hermes config set memory.memory_char_limit <N>  # nested under memory: section
# Run both to ensure both locations are consistent; YAML takes the last value.
```

> **Pitfall**: Direct yaml editing via `patch` or `sed` on `~/.hermes/config.yaml` is blocked by Hermes's security system. Always use `hermes config set`.

### MEMORY/Memory Consolidation (When Expansion Isn't Enough)

1. **Identify clustered entries** — multiple entries about the same subsystem/topic
2. **Merge them** into one dense paragraph
3. **Remove the fragments** via `memory(action='remove', target='memory', old_text='...')` or `memory(action='replace', target='memory', old_text='...', content='...')`
4. **Optionally** move the fragmented detail to fact_store (if it's tool details, not identity/preferences)

---

## Pitfalls

- **probe() and reason() require annotated entities** — If the fact was stored without quoted entities, these operations degrade to FTS5 keyword search. Always annotate on add.
- **reason() returns empty for unrelated entities** — This is correct behaviour (AND semantics). No intersection = no results. Don't interpret as "broken".
- **contradict() is O(n²) with a 500-fact cap** — Beyond 500 facts, it only checks the 500 most recently updated. Run regularly to stay under the cap.
- **Dedicated entities vs tags** — Tags (`tags` field) are for the `search()` FTS5 fallback, not for HRR algebra. HRR uses `"quoted"` entities from the `content` field only.
- **Remove-and-re-add for entity updates** — `fact_store(action='update')` does NOT re-extract entities. If you need to fix entity annotations on an existing fact, remove it and add it fresh.
- **Trust scores reset on re-add** — Removing and re-adding a fact resets its trust to 0.5. If the fact had valuable feedback history, consider `update` instead. (But see the pitfall above — update won't fix entities.)
- **This skill also has a reference file** with a concrete worked example of converting a 2,065-char fact-dump to a pure 元记忆 index: `references/meta-memory-implementation-example.md`.
- **MEMORY.md changes require /reset** — Memory snapshot is loaded at session start. Config changes (like `memory_char_limit`) and MEMORY.md content changes both require a new session to take effect.
- **Do NOT store workflow rules in fact_store** — Workflow rules need to be visible every turn, not retrieved on demand. If a rule lives in fact_store, the agent may forget to look for it.
- **Workflow rules also don't belong in a separate skill** — If a rule is simple enough to fit in MEMORY.md (5-10 sentences), put it there instead of creating a dedicated skill. MEMORY.md is always injected; a skill requires loading first. The threshold: if the rule is shorter than ~200 chars and needed every session → MEMORY.md. If it's a complex multi-step procedure → skill.
- **Meta-memory conversion has a discovery tax** — The first turn after conversion has 1-2 extra tool calls (probe/search) to retrieve details previously inline. This is a deliberate trade-off: cheaper turns forever in exchange for a slightly more expensive first turn. Accept it; do not backfill concrete facts into MEMORY.md just to silence the first-turn latency.
- **Self-referential memory management rule** — The meta-memory management workflow itself MUST be recorded in MEMORY.md (元记忆规则). Without it, future sessions will re-inflate MEMORY.md with concrete facts because there's no rule telling them not to. This prevents the same problem from recurring.
- **Pointer format must be unambiguous** — A 元记忆 entry like `🔧 工具链 → fact_store` is useless without a query. Always include the exact retrieval call: `🔧 工具链 → fact_store search('tool|config|provider')`. The agent needs an actionable command, not a hint.
- **Pointer without destination = dead link** — The most common meta-memory failure: writing `📚 书单 → fact_store search('reading')` in MEMORY.md without ever storing the book list in fact_store. The pointer loads into every session but always returns empty. The data is only recoverable from LCM session backups (if still available). **Prevention:** Never create a pointer without first verifying the target data exists via a retrieval call. See Phase 2, step 3 above.
- **`skill_manage(action='patch')` with `replace_all=True` is dangerous** — Use with extreme care. The pattern `**Goal:** ... \\n\\n\\`\\`\\`\\n\\`\\`\\`` appears 10+ times in YAML frontmatter and code block patterns, not just the intended target. Prefer `patch` without `replace_all` and add enough surrounding context for uniqueness, or use `edit` for full-file rewrites.
- **Fact_store entries can be fabricated/hallucinated** — The LLM may generate plausible-sounding facts (repo names, tool paths, user preferences) that were never real. These persist across sessions because fact_store has no external validation. During calibration, every factual claim is suspect until the user explicitly confirms it. If denied, remove immediately — no rationalization.
- **Compression corruption degrades names and details** — After many add/remove cycles, HRR entity extraction and content compression can corrupt names (e.g., "哥哥" → "钱哥"), mangle file paths, or merge unrelated facts. Watch for garbled names, implausible details, or entries that "feel wrong" — flag them for user confirmation during calibration.
