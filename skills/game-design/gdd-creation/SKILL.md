---
name: gdd-creation
description: "Game design doc creation via system-by-system brainstorming."
tags: [game-design, gdd, brainstorming, design-document]
---

# Game Design Document (GDD) Creation

Create comprehensive game design documents through structured one-question-at-a-time brainstorming. Each confirmed system is saved immediately to fact_store, preventing decision loss in long sessions.

## When to use

- User wants to design or redesign a game
- User says "let's do game design", "write a GDD", "design a game"
- User wants to brainstorm game mechanics, systems, or concepts

## Prerequisites

- Load `superpowers:brainstorming` for the general brainstorming process — this skill extends it with game-specific domain knowledge
- User should have a rough idea of genre/platform/target audience before starting

## Process

### Phase 1: Vision Establishment (1-2 questions)

1. **Core experience**: "What makes this game fun? What's the player's dopamine moment?"
   - Use clarify with driver categories (social/exploration/growth/competition/etc.)
   - Multiple drivers are common — confirm which to include

2. **Interaction model**: "How does the player interact with the game?"
   - Click/tap vs text input vs hybrid
   - This shapes everything downstream (UI, commands, combat)

3. **Architecture constraints**: online/offline, real-time/turn-based, platform target

### Phase 2: System-by-System Design (N questions)

Design one system per question. For each:

1. **Present the system** briefly (what it does, why it matters)
2. **Offer choices** via clarify (2-4 options with trade-offs)
3. **Confirm design** — user picks or proposes alternative
4. **Save to fact_store IMMEDIATELY** — do NOT batch saves

#### Standard systems checklist

Review each; not every game needs all:

| System | Key questions |
|--------|--------------|
| **Core loop** | What does a typical session look like? |
| **Progression** | How does the player grow? |
| **Combat/Action** | Real-time vs turn-based? Player agency level? |
| **Death/Failure** | What happens on failure? Punishment vs recovery? |
| **Economy** | Currency types, sinks vs faucets |
| **Social** | PvP, guilds, co-op, trading |
| **Exploration** | Map structure, discovery mechanics |
| **Content** | Story, quests, events |
| **Meta-progression** | What persists across runs/resets? |

#### Cross-referencing rule

After confirming a system, ALWAYS ask: "How does this affect [other systems]?" Systems in games are tightly coupled — death affects economy, combat affects progression, social affects exploration.

### Phase 3: GDD Compilation

**Ask the user which document structure they prefer (do not default to one file):**

1. **Single monolithic GDD** — one file, everything inside (small/medium projects)
2. **Skeleton + per-system docs** — user's established preference for larger projects (XunDaoMUD):
   - `README.md` = index table (doc # / content / status) + maintenance conventions
   - `00-gdd-overview.md` = skeleton: positioning, drivers, tech stack, ONE subsection per confirmed system with direction ONLY + cross-references
   - `01-<system>.md` … = one doc per system, holding all numeric/detail design
   - Rule: numeric details NEVER go in the skeleton; they live in the system doc
   - Design docs live in a dedicated dir (e.g. `~/mud/docs/design/`), migrated to the game's GitHub repo later

For a monolithic GDD (or the skeleton in modular mode), use this structure:

```markdown
# [Game Name] Game Design Document

## 1. Project Overview
Name, genre, platform, unique selling point

## 2. Design Goals & Core Experience
What makes it fun. Core player motivation.

## 3. Technical Stack
Constrained by design needs (platform, online/offline, etc.)

## 4. Core Systems Design
One subsection per confirmed system:
- Purpose and mechanics
- Interactions with other systems
- Open questions / TODOs

## 5. Content Plan
World, characters, items, levels (if applicable)

## 6. Development Roadmap
Phase-based plan

## 7. Open Questions
Unresolved design decisions
```

### Phase 4: Self-Review + User Review

1. **Spec self-review**: Check for placeholders, contradictions, ambiguity, scope
2. **Completeness cross-reference**: Before declaring the GDD done, walk the confirmed systems against:
   - The standard systems checklist above (core loop, progression, combat, death, economy, social, exploration, content, meta-progression)
   - **The existing codebase/assets** — read the project tree (AGENTS.md, typeclasses/, world/, commands/); existing modules that implement systems not in the GDD are missed systems. This catches genre staples you forgot to brainstorm
   - Genre-specific checklist if one exists — e.g. `references/xianxia-genre-checklist.md` for 修仙/MMO games
   Report the gaps to the user in priority tiers (A: genre-staple pillar systems missing entirely; B: mentioned but underspecified) and let them decide what gets added — do NOT silently expand the doc
3. **User review gate**: Ask user to review before proceeding to implementation planning

## Incremental fact_store checkpointing

After confirming each major system, save to fact_store:

```
fact_store add:
  category: project
  tags: [project-name, system-name]
  content: "[Project] [System] design: [confirmed decisions]"
```

This is CRITICAL for long sessions. Game design sessions can span hours with many decisions. Do NOT accumulate before saving.

## Pitfalls

- **Don't design systems in isolation** — always cross-reference with other confirmed systems
- **Don't skip death/failure design** — it's the most impactful system for retention
- **Don't assume complexity** — ask about simplification preferences early
- **Save incrementally** — don't wait until the end to save decisions
- **New player experience** — always ask about first-session experience separately
- **One question at a time** — game design decisions need thinking time; 10+ min timeouts are normal
- **Don't rush to code** — "design first, code later" is the correct order
