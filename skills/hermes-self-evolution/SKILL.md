---
name: hermes-self-evolution
description: "Run Hermes Agent Self-Evolution to automatically optimize skills, prompts, and tools using DSPy + GEPA."
version: 1.0.0
author: Emma
license: MIT
---

# Hermes Agent Self-Evolution 🧬

Evolutionary self-improvement for Hermes Agent. Uses DSPy + GEPA to evolve skills, tool descriptions, system prompts, and code.

## Prerequisites

Installed at `~/hermes-agent-self-evolution/` with venv at `.venv`.
dspy 3.2.1 + gepa 0.0.27 installed.

## Usage

```bash
cd ~/hermes-agent-self-evolution
source .venv/bin/activate

# Point at the hermes-agent repo
export HERMES_AGENT_REPO=~/.hermes/hermes-agent

# Evolve a specific skill (synthetic eval data — no real traces needed)
python -m evolution.skills.evolve_skill \
  --skill <skill-name> \
  --iterations 10 \
  --eval-source synthetic

# Or use real session history from the session DB
python -m evolution.skills.evolve_skill \
  --skill <skill-name> \
  --iterations 10 \
  --eval-source sessiondb
```

## Cost

~$2-10 per optimization run (API calls only, no GPU).

## Notes

- DSPy tries to connect to an LLM API on import — behind GFW may need proxy
- Evolved variants are tested with `pytest tests/ -q` automatically
- All changes go through PR review, never direct commit
- Phase 1 (skills/SKILL.md) is implemented; Phases 2-5 are planned

## Pitfalls

- Running without proxy in China may cause DSPy import to hang
- The tool needs LLM provider API keys configured (uses env vars like OPENAI_API_KEY or can pick up Hermes config)
