---
name: onnx-embeddings
description: "Generate sentence embeddings with ONNX Runtime — no PyTorch needed. Edge-device friendly."
version: 1.0.0
author: Emma
tags: [onnx, embeddings, sentence-transformers, edge, arm64, raspberry-pi, lightweight]
---

# ONNX Embeddings

## When to Use

When you need text embeddings (for RAG, memory systems, semantic search) but:
- **Cannot install PyTorch** (ARM64/aarch64, Raspberry Pi, resource-constrained)
- **Install size matters** — ONNX Runtime is ~200MB vs PyTorch ~800MB
- **Install speed matters** — `onnxruntime` installs in seconds vs PyTorch minutes
- **Need offline inference** — download model once, reuse forever

## How It Works

Uses `transformers.AutoTokenizer` for tokenization + `onnxruntime` for inference.
Pre-converted ONNX models are downloaded from HuggingFace Hub.
Embedding pipeline: `tokenize → ONNX forward → mean pooling → L2 normalize`.

## Dependencies

```bash
pip install onnxruntime transformers huggingface-hub numpy
```

## Implementation Template

```python
"""Minimal ONNX embedding model."""
import numpy as np
import onnxruntime as ort
from huggingface_hub import hf_hub_download
from transformers import AutoTokenizer


class ONNXEmbedding:
    def __init__(self, model_name: str = "sentence-transformers/all-MiniLM-L6-v2"):
        self.model_name = model_name
        self._tokenizer: AutoTokenizer | None = None
        self._session: ort.InferenceSession | None = None

    def _load(self):
        self._tokenizer = AutoTokenizer.from_pretrained(self.model_name)
        onnx_path = hf_hub_download(
            repo_id=self.model_name, filename="onnx/model.onnx"
        )
        self._session = ort.InferenceSession(
            onnx_path, providers=["CPUExecutionProvider"]
        )

    def encode(self, text: str | list[str]) -> list[float] | list[list[float]]:
        if self._session is None:
            self._load()

        single = isinstance(text, str)
        texts = [text] if single else text

        inputs = self._tokenizer(
            texts, padding=True, truncation=True, return_tensors="np", max_length=256
        )

        onnx_inputs = {"input_ids": inputs["input_ids"], "attention_mask": inputs["attention_mask"]}
        if "token_type_ids" in [i.name for i in self._session.get_inputs()]:
            onnx_inputs["token_type_ids"] = inputs.get("token_type_ids",
                np.zeros_like(inputs["input_ids"]))

        outputs = self._session.run(None, onnx_inputs)
        last_hidden = outputs[0]

        # Mean pooling
        mask = np.expand_dims(inputs["attention_mask"], axis=-1).astype(last_hidden.dtype)
        embedding = np.sum(last_hidden * mask, axis=1) / np.clip(np.sum(mask, axis=1), 1e-9, None)

        # L2 normalize
        embedding = embedding / np.clip(np.linalg.norm(embedding, axis=1, keepdims=True), 1e-12, None)

        if single:
            return embedding[0].tolist()
        return [v.tolist() for v in embedding]

    @property
    def dims(self) -> int:
        return 384  # all-MiniLM-L6-v2; adjust per model
```

## Supported Models

| Model | Dimensions | Source |
|-------|-----------|--------|
| `all-MiniLM-L6-v2` | 384 | `sentence-transformers/all-MiniLM-L6-v2` |
| `all-mpnet-base-v2` | 768 | `sentence-transformers/all-mpnet-base-v2` |

ONNX files are at `onnx/model.onnx` in each HuggingFace repo.

## Pitfalls

1. **token_type_ids** — Some ONNX models expect it, some don't. Check via `[i.name for i in session.get_inputs()]`
2. **GPU warnings** — `Failed to detect devices under /sys/class/drm/card*` is harmless on non-NVIDIA systems
3. **First-run download** — ~90MB for all-MiniLM-L6-v2; subsequent runs use `~/.cache/huggingface/`
4. **HF_TOKEN** — Set `HF_TOKEN` env var for faster downloads (unauthenticated has rate limits)
5. **max_length** — 256 tokens is usually sufficient for sentence embeddings; longer texts get truncated
6. **Numeric stability** — Always clip denominator in mean pooling (`1e-9`) and L2 normalization (`1e-12`) to avoid division by zero on zero-length inputs (after truncation)

## Integration Example

Used in Mneme memory system — see `src/mneme/embed/model.py`:
- Lazy-loading (`_load()` on first `encode()` call)
- Auto-downloads from HuggingFace
- Falls back to `optimum.onnxruntime.ORTModelForFeatureExtraction` if pre-converted ONNX not found

## Reference

- `references/lightweight-embeddings.md` (was in emma-code-monkey): full working example from Mneme project
- HuggingFace ONNX export guide: https://huggingface.co/docs/optimum/exporters/onnx/overview
