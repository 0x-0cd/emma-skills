# AI Agent Memory: Patent / Prior Art Landscape (June 2026)

> Condensed research from session 20260611 — prior art search for "cross-device, cloud+edge agent memory with public/private split."

---

## 🏭 Industry Products

| Product | Funding/Status | Architecture | Relevance |
|---------|---------------|-------------|-----------|
| **Mem0** | $24M raised | Vector DB + KG, single API, cloud | Cloud-only, no edge, no public/private split |
| **Cognee** | $7.5M raised | Graph+Vector+Relational, planning Rust edge engine | Edge planned but not shipped, no privacy-tiered memory |
| **Apple Intelligence** | Shipped (2024) | 3-tier compute: 85% on-device, 12% private cloud, 3% partner | **Compute tiering**, NOT memory tiering. Different concept |
| **Anthropic "Dreaming"** | Shipped (May 2026) | Cross-agent async memory consolidation | Cross-agent ≠ cross-device. No edge/cloud split |
| **O-Mem** (OPPO) | Open source (Nov 2025) | Active user profiling, continuous extraction | User profiling focus, no privacy-tiered storage |
| **Memobase** | Cloud service | Profile-based long-term memory | Cloud-only |
| **Letta** | Open source | Core/external memory, LLM-managed edits | Single-device focus |
| **Kimi Claw** | Cloud service | Cloud long-term memory | Cloud-only, no edge |

**Key gap**: None of these split memory by **privacy/public attribute** across cloud and edge locations.

---

## 📄 Academic Papers (Most Relevant)

| Paper | Venue/Date | Relevance | Key Contribution |
|-------|-----------|-----------|-----------------|
| **CoMIC** (2606.00756) | arXiv, May 2026 | ★★★★★ | Edge agent collaborative memory, each edge maintains working memory, cloud circulates shared insights. Closest to your concept. |
| **Hera** (2605.24598) | arXiv, 2026 | ★★★★ | Step-level device-cloud LLM agent coordinator |
| **Hierarchical Memory Sharing in Multi-Agent** | 2025 | ★★★★★ | Multi-agent hierarchical memory with privacy mechanisms |
| **Rethinking Memory in LLM Agent** (2505.00675) | arXiv, 2025 | ★★★★ | Comprehensive survey of memory representations |
| **O-Mem** (2511.13593) | arXiv, Nov 2025 | ★★★ | Omni memory for personalization, no privacy split |
| **MMAG** | 2025 | ★★★ | Five-layer memory framework (conversational, user, episodic, sensory, working) |
| **Kōan** | 2026 | ★★★ | Deferred consolidation + tripartite memory for CLI agents |
| **Choosing How to Remember** (2602.14038) | arXiv, 2026 | ★★★ | Adaptive memory structures for LLM agents |
| **Memory in the Age of AI Agents** | Dec 2025 | ★★★★ | 47-author survey, distinguishes formation/evolution/retrieval dynamics |
| **Graph-based Agent Memory: Taxonomy, Techniques, and Applications** | 2025 | ★★★ | Graph memory taxonomy |

---

## 📜 Notable Patent Families

(Note: Formal patent search requires professional tools. These are publicly known filings.)

- **Apple**: Multiple patents around Private Cloud Compute, on-device AI processing. Focused on **computation location**, not memory storage location.
- **Google**: Patents around personalized AI, federated learning. Public/on-device personalization patents exist but for model training, not agent memory.
- **Microsoft**: Copilot memory-related patents. Focus on enterprise context, not consumer cross-device.
- **The gap**: No dominant patent family specifically covering "agent memory split by privacy attribute across cloud and edge."

---

## 🎯 Novelty Assessment Summary

| Component | Coverage | Assessment |
|-----------|----------|------------|
| Edge-cloud compute split | Heavy (Apple, Google, many papers) | 🔴 Commodity |
| Agent long-term memory | Moderate (Mem0, Cognee, O-Mem, Letta) | 🟡 Well-explored |
| Privacy-preserving AI | Heavy (federated learning, DP) | 🔴 Commodity |
| **Privacy-attribute memory split** | **Light** | **🟢 Potentially novel** |
| **Cross-device private memory sync** | **Light** | **🟢 Potentially novel** |
| **Joint cloud+edge memory retrieval** | **Light** | **🟢 Potentially novel** |
| **Dynamic privacy reclassification of memories** | **None found** | **🟢 Novel** |

**Overall**: The combination space is green/yellow. The individual components are known, but the specific architecture of splitting agent memory by public/private attribute across cloud and edge — with dynamic classification and cross-device sync — does not appear in prior art.

---

## ⚖️ Patent Filing Strategy (Quick Reference)

| Jurisdiction | Difficulty | Strategy |
|-------------|-----------|----------|
| **US (USPTO)** | Hard (95% invalidity at Fed Circuit) | Frame as distributed memory system improvement, not AI. Avoid "AI" in independent claims. Include hardware. |
| **China (CNIPA)** | Moderate | More permissive for AI/software. File first or dual-file. |
| **Europe (EPO)** | Moderate-hard | Needs technical effect tied to hardware. |

**Key risk**: That the combination is seen as "obvious" — cloud+edge is well-known, memory tiering is well-known. Mitigate by claiming the *specific mechanism* of how privacy classification is done, how retrieval merges results, how sync works across devices.
