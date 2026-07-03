---
name: using-hermes-skills
description: Routes tasks to the right Hermes skill. Use when starting a session, switching tasks, or unsure which skill fits.
version: 2.0.0
author: Emma
license: MIT
metadata:
  hermes:
    tags: [meta, routing, workflow, productivity]
    related_skills: [brainstorming, plan, writing-skills]
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill — your skill routing is handled by the parent agent.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

# Using Hermes Skills — Skill Router

## Overview

Hermes has 60+ skills covering software development, creative work, research,
GitHub workflows, platform integrations, ML/AI ops, and Hermes maintenance.
This meta-skill routes your task to the right one — so you don't start coding
without a plan, or start designing without understanding the scope.

**Use this when:**
- You're starting a new session and don't know which skill to load
- You switch from one task type to another (e.g., coding → research → review)
- The user gives a vague request that needs routing before execution
- You're about to start work and want to check "is there a skill for this?"

## Instruction Priority

When multiple instruction sources conflict:

1. **User's explicit instructions** (AGENTS.md, direct requests) — highest priority
2. **Skills** — override default system behavior where they conflict
3. **Default system prompt** — lowest priority

If AGENTS.md says "don't use TDD" and a skill says "always use TDD," follow the user's instructions. The user is in control.

## Platform Adaptation

Skills are loaded via platform-specific tools:

- **Hermes / Claude Code:** Use `skill_view(name)` — invokes the skill and loads its content
- **Copilot CLI:** Use the `skill` tool — skills are auto-discovered from installed plugins
- **Gemini CLI:** Skills activate via the `activate_skill` tool
- **Other environments:** Check your platform's documentation for skill loading

## Core Operating Rules

These 5 rules apply at all times, in every skill:

### 1. Surface Assumptions
Before implementing anything non-trivial, explicitly state your assumptions:

```
ASSUMPTIONS I'M MAKING:
1. [assumption about requirements]
2. [assumption about scope]
3. [assumption about tech stack]
→ Correct me now or I'll proceed with these.
```

**Why:** The most common failure mode is silently filling in ambiguous requirements.

### 2. Maintain Scope Discipline
**Touch only what you're asked to touch.** Do not:
- "Clean up" code orthogonal to the task
- Refactor adjacent systems
- Delete code you don't fully understand
- Add features not in the spec

### 3. Verify, Don't Assume
Every skill includes a verification step. A task is not complete until verification passes. **"Seems right" is never sufficient** — there must be evidence (passing tests, clean build output, runtime data).

### 4. Push Back When Warranted
Point out problems directly. Explain concrete downsides. Propose an alternative. Accept the user's override if they have full information.

**Sycophancy is a failure mode.** Honest technical disagreement is worth more than false agreement.

### 5. Enforce Simplicity
Before finishing, ask yourself:
- Can this be done in fewer lines / steps?
- Are these abstractions earning their complexity?
- Would a more experienced engineer ask "why didn't you just...?"

## Skill Discovery Decision Tree

```
Task / Request arrives
│
├── Software Development
│   ├── Write / edit code, debug, review, format?      → code-task
│   ├── Git operations / branch cleanup / worktrees?   → code-project
│   ├── Write / edit a skill?                          → writing-skills
│   ├── Multi-agent / parallel work?                   → dispatching-parallel-agents
│   └── Need to brainstorm / design first?             → brainstorming
│
├── Creative & Design
│   ├── Brainstorm ideas / refine concept?           → brainstorming
│   ├── Write a technical blog post?                 → technical-blog-writing
│   ├── Humanize AI-generated text?                  → humanizer
│   └── Generate ASCII art / diagrams?               → dogfood
│
├── Research & Learning
│   ├── Book reading guide?                          → book-reading-guide
│   ├── Self-directed learning plan?                 → productivity:self-directed-learning-framework
│   ├── Pulse learning challenge (评级+限时+奖章)?   → education:pulse-learning-method
│   ├── Search arXiv papers?                         → arxiv
│   ├── Deep-dive into a paper?                      → paper-deep-dive
│   ├── Validate a claim / hypothesis?               → research-backed-validation
│   ├── Research Chinese internet content?           → chinese-content-research
│   └── Set up media crawler pipeline?               → media-crawler-pipeline
│
├── GitHub
│   ├── Authenticate to GitHub?                      → github-auth
│   ├── Create / triage issues?                      → github-issues
│   ├── Full PR lifecycle (branch→commit→merge)?     → github-pr-workflow
│   ├── Clone / fork / manage repos?                 → github-repo-management
│   └── Inspect codebase stats?                      → codebase-inspection
│
├── Platforms & Tools
│   ├── Chinese messaging platform setup?            → chinese-messaging-platforms
│   ├── Send email?                                  → himalaya
│   ├── Publish to GitHub Pages blog?                → github-blog
│   └── Design GitHub profile README?                → github-profile-design
│
├── Data Science & ML
│   ├── Run memory benchmarks?                       → memory-system-evaluation
│   ├── Generate ONNX embeddings?                    → onnx-embeddings
│   └── Discover community Hermes resources?         → community-resources
│
├── Hermes Agent Configuration
│   ├── Configure LLM providers / models?            → hermes-provider-config
│   ├── Security hardening?                          → hermes-security
│   ├── Token optimization?                          → hermes-token-optimization
│   ├── Maintenance / upgrades?                      → hermes-maintenance
│   ├── Run self-evolution?                          → hermes-self-evolution
│   ├── Identity sync across machines?               → hermes-agent-migration
│   ├── Memory management?                           → hermes-memory-workflow
│   └── General hermes config / setup?               → hermes-agent
│
├── Agent Workflows
│   ├── Need autonomous sub-agents?                  → dispatching-parallel-agents
│   ├── QA testing a web app?                        → dogfood
│   └── Spawn OpenCode coding subagent?              → code-task
│
└── Completely off-topic / unclear?
    └── → brainstorming (start with clarifying questions)
```

## Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (brainstorming, debugging) — these determine HOW to approach the task
2. **Implementation skills second** (TDD, plan) — these guide execution

"Let's build X" → brainstorming first, then implementation skills.
"Fix this bug" → debugging first, then domain-specific skills.

## Skill Types

**Rigid** (TDD, debugging): Follow exactly. Don't adapt away discipline.

**Flexible** (patterns): Adapt principles to context.

The skill itself tells you which.

## Anti-Rationalization Tables

LLMs excel at rationalizing why *this specific task* doesn't need the process.
These are pre-written rebuttals. Do not accept any of these excuses:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |
| "This task is too simple to need a plan." | Acceptance criteria still apply. Five lines is fine. Zero lines is not. |
| "I'll add tests later." | "Later" is the load-bearing word. There is no later. Write the failing test first. |
| "Tests pass, ship it." | Passing tests are evidence, not proof. Did a human review the diff? |
| "I know the codebase well enough." | Even in familiar codebases, project-init surfaces the AGENTS.md, conventions, and config. 30 seconds well spent. |
| "I'll just do it directly, no skill needed." | Every skill exists because someone created a mess skipping it. Don't be that someone. |
| "The user didn't ask for tests." | The user asked for working software. Tests are how you prove it works. |
| "This is just a quick experiment." | Use `spike` — it's designed for that. But spikes get thrown away, not promoted to production. |
| "I know what the user means, no need to clarify." | Assumptions are the #1 source of rework. Surface them. |
| "The change is small, I don't need to verify." | Small changes break things too. Rework is expensive. |

## Verification Checklist

- [ ] Identified the task category from the decision tree
- [ ] Loaded the matching skill via `skill_view(name)`
- [ ] Followed the skill's workflow in order (not skipped steps)
- [ ] Completed verification step before declaring done
- [ ] Not touched files / systems outside the defined scope
- [ ] Surface assumptions if requirements were ambiguous
- [ ] Applied skill priority: process skills first, implementation second
