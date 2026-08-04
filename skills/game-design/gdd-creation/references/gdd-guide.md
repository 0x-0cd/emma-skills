# Game Design GDD Creation Guide

## Reference: 11-System Game Design Checklist

For complex games (especially RPG/MMO/MUD), review these systems:

1. **Core Loop** — The repeat action. What does the player DO most of the time?
2. **Progression** — How does the player grow? Levels, skills, equipment, ranks.
3. **Combat/Action** — Real-time vs turn-based vs hybrid. Player agency level.
4. **Death/Failure** — Punishment vs recovery. Permanent death? Roguelite meta?
5. **Economy** — Currency types, sinks vs faucets, trading.
6. **Social** — PvP, guilds, co-op, chat, trading.
7. **Exploration** — Map structure, random generation, discovery.
8. **Content Delivery** — Story, quests, events, seasonal content.
9. **Meta-progression** — What persists across runs/deaths/resets?
10. **Monetization** — Free-to-play, premium, subscription, cosmetic-only.
11. **Onboarding** — New player experience. First 10 minutes.

## Reference: GDD Document Structure

```markdown
# [Game Name] Game Design Document

## 1. Project Overview
- Name, genre, platform, unique selling point
- One-line summary of what makes this game special

## 2. Design Goals & Core Experience
- What makes it fun? Player's "dopamine moment"
- Target audience and player motivation
- Core design pillars (3-5 max)

## 3. Technical Stack
- Platform constraints driving tech choices
- Online/offline, real-time/turn-based
- Client/server architecture

## 4. Core Systems Design
One subsection per confirmed system:
- Purpose and mechanics
- Key numbers/balances (if known)
- Interactions with other systems
- Open questions / TODOs

## 5. Content Plan
- World/setting outline
- Character/faction design
- Item/equipment categories
- Level/area design

## 6. Monetization (if applicable)
- Revenue model
- What players pay for
- Free vs paid content split

## 7. Development Roadmap
- Phase-based plan (prototype → alpha → beta → launch)
- Milestones and deliverables

## 8. Open Questions
- Unresolved design decisions
- Items needing further research
```

## Reference: Incremental Saving Pattern

For long brainstorming sessions (2+ hours), save after EVERY confirmed system:

```
fact_store add:
  category: project
  tags: [project-name, system-name]
  content: "[Project] [System] design: [2-3 sentence summary of confirmed decisions]"
```

This prevents decision loss if context gets truncated. The session summary should reference these fact_store entries.

## Reference: Cross-System Interaction Map

After confirming all systems, create a quick interaction map:

```
Death ←→ Economy (death drops resources)
Death ←→ Progression (death resets some progress)
Death ←→ Social (death affects guild standing)
Combat ←→ Progression (combat rewards drive growth)
Combat ←→ Economy (combat consumes/resources items)
Economy ←→ Social (trading, guild treasury)
Exploration ←→ Progression (exploration unlocks areas)
Exploration ←→ Content (exploration triggers events)
Social ←→ Progression (guild bonuses, group content)
```

This catches design gaps where two systems don't connect properly.
