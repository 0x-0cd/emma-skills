# Holographic Memory Provider — Architecture & Retrieval Capabilities

> Source: `~/.hermes/hermes-agent/plugins/memory/holographic/`
> Analyzed 2026-06-12. Three-layer architecture: HRR algebra engine → SQLite+FTS5 store → multi-strategy retrieval.

## Architecture

```
┌─────────────────────────────────────────┐
│  retrieval.py — Retrieval Layer         │
│  search / probe / related / reason /    │
│  contradict (6 retrieval strategies)     │
├─────────────────────────────────────────┤
│  store.py — Storage Layer               │
│  SQLite + FTS5 + entity extraction +    │
│  trust scoring                          │
├─────────────────────────────────────────┤
│  holographic.py — HRR Algebra Engine    │
│  bind / unbind / bundle / similarity    │
│  Based on Plate (1995) phase-vector     │
│  Holographic Reduced Representations    │
└─────────────────────────────────────────┘
```

## Storage Layer (`store.py`)

- **SQLite** primary database at `~/.hermes/memory_store.db`
- **FTS5** full-text index with automatic trigger-based sync
- **Schema**: `facts` + `entities` + `fact_entities` (many-to-many) + `memory_banks`
- **Entity extraction**: Regex rules for capitalized multi-word phrases, double/single-quoted terms, AKA patterns ("Guido aka BDFL")
- **Trust scoring**: 0.0–1.0, initial 0.5, adjusted asymmetrically (helpful +0.05, unhelpful -0.10)
- **HRR vectors**: 1024-dimensional phase vectors (8KB each), stored as BLOB

## HRR Algebra Engine (`holographic.py`)

Pure numpy vector symbolic architecture using phase vectors (angles in [0, 2π)):

| Operation | Math | Purpose |
|-----------|------|---------|
| **bind(a, b)** | Phase addition (circular convolution) | Associate two concepts |
| **unbind(m, k)** | Phase subtraction (circular correlation) | Retrieve bound value |
| **bundle(v₁, v₂, ...)** | Circular mean of complex exponentials | Merge multiple concepts |
| **similarity(a, b)** | Phase cosine similarity [-1, 1] | Compare vectors |

**Key property**: `unbind(bind(content, role_c) + bind(entity, role_e), entity) ≈ content_vector`

This enables compositional retrieval via algebra alone — no embedding API calls, no vector DB.

**Deterministic atoms**: Concept vectors generated from SHA-256, identical across machines and language versions.

## Retrieval Strategies (`retrieval.py`)

All strategies combine HRR algebraic operations with trust-weighted scoring.

| Method | How It Works | Use Case |
|--------|-------------|----------|
| **search(query)** | FTS5 → Jaccard rerank → HRR similarity (0.3) → trust weight | Standard keyword search |
| **probe(entity)** | `unbind(fact, bind(entity, role))` extracts entity-associated content | "What do we know about X?" |
| **related(entity)** | Checks structural role of entity in fact vectors (any role) | "What's connected to X?" |
| **reason([e1, e2, ...])** | Multi-entity AND semantics via min() over entity scores | "Facts about A AND B simultaneously" |
| **contradict()** | High entity overlap + low content similarity = contradiction | Automated memory hygiene |

### Hybrid Scoring (search)
```
relevance = 0.4 × FTS5_rank + 0.3 × Jaccard + 0.3 × HRR_sim
final_score = relevance × trust_score × temporal_decay
```

### SNR Capacity
The HRR system warns when `n_items > dim/4` (SNR < 2.0). At 1024 dims, ~256 items before degradation.

## When to Use Holographic vs MEMORY.md

| Criterion | MEMORY.md | Holographic (fact_store) |
|-----------|-----------|--------------------------|
| **Capacity** | 2200–4000 chars | Unlimited (SQLite) |
| **Injection** | Full text in every session prompt | On-demand retrieval |
| **Query** | LLM reads all entries | FTS5 + HRR algebra |
| **Entity tracking** | None | Automatic extraction + linking |
| **Trust scoring** | None | Per-fact, feedback-adjusted |
| **Contradiction detection** | None | Automated pairwise comparison |
| **Multi-entity reasoning** | None | Vector-space AND/OR semantics |

### Decision Heuristic
- **High-frequency, small** (preferences, env facts, core conventions) → MEMORY.md
- **Low-frequency, large** (research findings, device configs, historical decisions) → Holographic
- **Needs retrieval** (search across topics, entity-based lookup) → Holographic
- **Always needed** (user name, timezone, communication style) → MEMORY.md
