---
name: self-directed-learning-framework
description: Use when helping with any self-learning project, designing a self-study plan, or when the user asks for methodology guidance on learning a new skill independently. Also use when the learner wants to structure their practice more efficiently across domains like music, crafts, coding, or sports.
---

# Self-Directed Learning Framework

A synthesis of four research pillars (SRL, Andragogy, Deliberate Practice, Metacognition) into a practical methodology for **any self-directed skill acquisition**.

## When to Use

- Learner is starting a new skill from zero and needs a structured approach
- Learner is stuck on a plateau and needs to diagnose why practice isn't working
- Learner asks for a "learning roadmap" for any hands-on skill
- Designing a practice plan across domains (music, making, coding, sports, crafts)
- Evaluating whether self-study is viable for a specific skill

## Core Workflow: SRL Practice Cycle

Apply this cycle **per session**, not just per skill.

```
┌──────────────────────────────────────────────────┐
│          ① Forethought（前思）                    │
│   - Set specific, measurable goal for the session │
│   - Identify the sub-skill at the edge of ability  │
│   - Ask "What will I do if I get stuck?"          │
└──────────────────┬───────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│          ② Performance（执行）                    │
│   - Execute with full attention                   │
│   - Self-monitor: pause after each attempt         │
│   - Collect data: record time/errors/output        │
└──────────────────┬───────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│          ③ Self-Reflection（反思）                │
│   - Compare output vs. success criteria            │
│   - Diagnose root cause of errors                  │
│   - Decide next session's strategic adjustment     │
└──────────────────┬───────────────────────────────┘
                   │
                   └──→ Back to ① with adjusted goal
```

### Key Principle for Each Phase

| Phase | Self-Learner's Question | Do NOT |
|-------|------------------------|--------|
| Forethought | "What exactly am I improving today?" | Vague goals ("practice more") |
| Performance | "Am I repeating errors or fixing them?" | Autopilot repetition |
| Reflection | "What changed compared to last time?" | Skipping analysis, moving to next thing |

## Skill Decomposition (for Deliberate/Purposeful Practice)

Break the target skill into sub-skills before designing the cycle:

```
Target Skill: _______________
├── Sub-skill A (basic motor/knowledge)
├── Sub-skill B (intermediate combination)
├── Sub-skill C (advanced integration)
└── Sub-skill D (troubleshooting / error recovery)
```

**Rule of thumb:** If a sub-skill can't be practiced in isolation for 10–20 minutes, decompose further.

## Feedback Loop Design (Metacognition)

Self-directed learning requires **artificial feedback** since no teacher provides it:

| Feedback Type | Example Tools | Domain Examples |
|---------------|--------------|-----------------|
| **Direct measurement** | Stopwatch, multimeter, scale | Soldering (conductivity), running (pace) |
| **Recording + self-review** | Video, audio recording | Piano (watch hand position), sports (form check) |
| **Reference comparison** | Side-by-side with expert output | Drawing, calligraphy, cooking |
| **Quantitative tracking** | Success-rate log per session | Any skill with pass/fail trials |
| **External validation** | Community critique, app feedback | Code review, language exchange, Simply Piano |

**Minimum viable feedback:** At least **two independent signals** per practice session (e.g., recording + time log).

## Practice Session Template

```
Date: _________  Duration: _________  Skill: _________

FORETHOUGHT:
  - Goal for today: __________________________________
  - Specific success criterion: _______________________
  - Sub-skill to focus on: ___________________________

PERFORMANCE:
  - Attempts / reps: _______
  - Best result: ___________
  - Errors observed: _________________________________

REFLECTION:
  1. Did I meet my success criterion? Why / why not?
  2. Which error pattern is most frequent? ____________
  3. Root cause of pattern: ___________________________
  4. Next session's strategic change: _________________
```

## Creating a Practice Environment for Coding Skills

When the target is a coding skill (language, library, tool), the practice environment determines whether the learner actually practices. Friction kills consistency — every extra setup step is a reason to skip.

### Recommended Project Structure

```
skill-dojo/
├── run.py                  ← One-command entry point
├── practices/
│   ├── __init__.py         # Makes it a proper package
│   ├── helpers.py          # Shared validation/tooling
│   ├── phase_01_topic.py   # Each phase = one importable module
│   └── phase_02_topic.py
└── README.md
```

### Design Principles

| Principle | Why | Anti-pattern |
|-----------|-----|-------------|
| **Zero-setup run** | `python run.py` from root works immediately | Setting PYTHONPATH or cd'ing into subdirs |
| **Scaffold then fill** | Learner only fills their solution, not boilerplate | Blank file + "write tests" |
| **Immediate feedback** | Every run prints ✅/❌ per test case | Manual output inspection |
| **Valid module names** | Underscores not hyphens → importable | `phase-01.py` can't be `import practices.phase-01` |
| **Progressive phases** | Each depends only on previous concepts | Lookahead before character classes |

### Mapping Feedback Types to Coding

| Framework Feedback Type | Coding Implementation |
|-------------------------|----------------------|
| Direct measurement | Auto-runner printing ✅/❌ per test |
| Recording + self-review | `git diff` against reference solution |
| Reference comparison | Side-by-side with known-good pattern |
| Quantitative tracking | Success rate per phase ("11/12 passed") |

**Concrete example:** See `references/regex-self-learning-plan.md` for a full walkthrough applying this structure to a Python regex curriculum.

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| **Naïve Practice** — whole skill repeated start-to-finish | Decompose into sub-skills; practice only the hard part |
| **Vanishing feedback** — relying on "feel" instead of data | Add at least one objective measurement per session |
| **Goal creep** — "I'll aim to be good" instead of specific criterion | Force-written criterion before starting |
| **Emotional attribution** — "I'm bad at this" vs "my timing was off" | Use data-driven error diagnosis |
| **Plateau ignorance** — same strategy repeated despite no progress | After 3 flat sessions, **change the method**, not the effort |
| **Over-scoping** — trying to learn all sub-skills at once | Learn one sub-skill to 60% confidence, then the next |

## When NOT to Use This Framework

- The learner already has a qualified teacher/trainer providing structured feedback — follow their plan instead
- The skill has extremely high physical risk requiring supervision (scuba, skydiving, surgery)
- The learner explicitly wants casual, unstructured exploration without performance goals
- The skill's primary goal is relaxation or play, not improvement
