# Token Optimization Article Reference — Session Notes

**Date:** 2026-06-10  
**Source:** https://cloud.tencent.com/developer/techpedia/2607/20497 — "Hermes Agent 的 Token 消耗如何优化？"  

## Core Premise

Unlike traditional Q&A AI, Hermes Agent sends much more context per turn: system prompt, enabled Skill list, conversation history, memory files, tool call results, etc. A complex task can consume 10-100x more tokens than a simple Q&A.

## Token Consumption Sources (with Optimization Potential)

| Source | Description | Potential |
|--------|-------------|-----------|
| System Prompt | Agent personality + behavior rules | 🟡 Medium |
| Skill List | Each enabled SKILL.md enters context | 🔴 **High** |
| Conversation History | Multi-turn chat records | 🟡 Medium |
| Memory Files | Long-term memory + recent logs | 🔴 **High** |
| Tool Call Results | Browser screenshots, command output, file content | 🔴 **High** |
| Model Reasoning Steps | Think-call-tool cycles | 🟡 Medium |

## Six Optimization Methods

### 1. Reduce Enabled Skills
Regularly audit installed skills, disable/remove unused ones. This is the highest-ROI optimization.

### 2. Enable Context Compression (Default: ON)
Hermes auto-compresses older turns into summaries when approaching the context window limit. No extra config needed.

### 3. Tiered Model Selection
- Simple tasks → lightweight models (cheaper, faster)
- Complex tasks → flagship models
- Hermes supports per-task-type model assignment

### 4. Limit Tool Output Length
Configure max output lines to prevent large results from flooding context.

### 5. Periodic Memory Cleanup
- Purge non-critical temp memories >90 days old
- Migrate valuable long-term content to MEMORY.md
- Delete raw log files after migration

### 6. Budget Limits & Alerts
Set token budget caps and usage alerts to prevent cost surprises.

## User-Specific Notes

- **88 skills installed**, all enabled by default — massive optimization opportunity
- User prefers to be consulted before disabling anything: "禁用工具前记得问我"
- Using DeepSeek v4 Flash as primary model — already relatively efficient
- ARM64 Raspberry Pi — no local model serving, no GPU workloads
