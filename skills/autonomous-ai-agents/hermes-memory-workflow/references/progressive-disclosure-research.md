# Progressive Disclosure in AI Agent Context Engineering

Three authoritative sources that define the progressive disclosure pattern for AI agents. This reference supports the meta-memory architecture in the parent skill.

---

## 1. Anthropic — Effective Context Engineering for AI Agents

**Source:** [anthropic.com/engineering/effective-context-engineering-for-ai-agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)  
**Published:** Sep 29, 2025

### Core Thesis

Context engineering treats the context window as a **finite resource with diminishing marginal returns**. Progressive disclosure is the recommended pattern — agents discover context through exploration rather than loading everything upfront.

### Key Concepts

- **Context rot**: accurate recall degrades as token count increases (transformer n² pairwise attention)
- **Shift from pre-computed → just-in-time**: agents maintain lightweight identifiers (file paths, stored queries, URLs) and dynamically load data using tools at runtime
- **Hybrid strategy**: pre-load essential context, let the agent explore the rest
- **Example**: Claude Code uses CLAUDE.md (hybrid upfront) + primitives like glob/grep/head/tail for runtime exploration

### Relevance to Meta-Memory

> "Rather than pre-processing all relevant data up front, agents maintain lightweight identifiers and use these references to dynamically load data into context at runtime using tools."

This is exactly the MEMORY.md-as-index model: MEMORY.md = lightweight identifiers, fact_store/skill_view/session_search = runtime retrieval tools.

---

## 2. SwirlAI — Agent Skills: Progressive Disclosure as a System Design Pattern

**Source:** [newsletter.swirlai.com/p/agent-skills-progressive-disclosure](https://www.newsletter.swirlai.com/p/agent-skills-progressive-disclosure)  
**Author:** Aurimas Griciūnas

### Core Thesis

Agent Skills are a system design pattern applying Progressive Disclosure to agent context management, solving context window pollution and making behavior configurable by non-engineers.

### Three-Tier Model

| Layer | Stage | Token Cost | Action |
|-------|-------|-----------|--------|
| **1: Discovery** | Startup | ~80 tokens/skill | Platform reads only name & description from YAML |
| **2: Activation** | When Relevant | ~2,000 median | LLM decides relevance; loads full SKILL.md body |
| **3: Execution** | On Demand | Variable | Pulls in scripts, references, and templates |

### Key Quote

> "A system prompt is always on. A skill sits dormant until the platform decides it's relevant."

### Relevance to Meta-Memory

This three-tier model maps directly to the agent's own memory:
- **MEMORY.md** = Discovery (元记忆 pointers, ~80 tokens/entry)
- **fact_store probe/search** = Activation (structured facts on demand)
- **skill_view / session_search** = Execution (full-depth context)

---

## 3. Third i — Context Engineering for Autonomous Marketing Agents

**Source:** [thirdi.ai/blog/context-engineering-for-autonomous-marketing-agents](https://thirdi.ai/blog/context-engineering-for-autonomous-marketing-agents)  
**Author:** Aravind Nair  
**Published:** May 6, 2026

### Core Thesis

Building CoDI (conversational AI analyst for six-figure ad spend), they went through 4 architecture rebuilds. The breakthrough was progressive disclosure — from 60-80k tokens/query down to 15-25k, accuracy from 70% to 85%.

### V3 Pipeline (The Breakthrough)

| Step | Context Delivered | Token Cost |
|------|------------------|-----------|
| **Planner** | Lightweight metadata (platform name, cube name, 1-line description) | ~2,500 |
| **Query Builder** | Detailed schema for *selected* cubes only | ~4,000 |
| **Data Fetch** | Deterministic (no LLM involvement) | 0 |
| **Analyst** | Columnar JSON format data | 60% reduction |

### Key Quote

> "The question wasn't 'how do we fit more context in?' It was 'how do we give each step only what it needs?'"

### Relevance to Meta-Memory

The planner/query-builder/data-fetch/analyst pipeline is structurally identical to MEMORY.md → fact_store → skill_view → session_search: each tier adds detail only when the previous tier determines it's needed. The token savings (60-80k → 15-25k) demonstrate the practical value of the approach.

---

## Synthesis: Why This Pattern

The pattern generalizes across all three sources:

1. **Context is finite** — each token depletes the attention budget
2. **Discovery before activation** — lightweight metadata first, detail on demand
3. **Just-in-time over pre-computed** — runtime retrieval beats upfront injection for non-essential context
4. **Tiered depth** — most queries stop at T1/T2, only complex tasks reach T3

This is the architectural foundation for the meta-memory (元记忆) model: MEMORY.md as discovery index, fact_store as structured activation, skills/sessions as full-depth execution.
