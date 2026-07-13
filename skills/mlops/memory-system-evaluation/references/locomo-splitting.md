# LoCoMo 评测分片并行策略

> 将全量 LoCoMo 评测（10 对话 × ~1500 题）拆为多个独立任务并行跑，再合并结果。
> 已验证：2026-07-12 Mneme 补丁链 session — CONV_START/CONV_END/BATCH_NAME 实现 + merge_locomo_results.py 验证通过。

## 为什么能分片

LoCoMo-10 数据集的 **每个 conversation 是完全独立的**：

- 不同 speaker pair（Caroline & Melanie / Jon & Gina / John & Maria …）
- 各自独立的 ingestion 流程
- 各自独立的 QA 集
- `user_id` 按 conversation index 隔离（`locomo_0`, `locomo_1`, …）

**不存在跨 conversation 的依赖**，没有全局状态需要共享。

## 分片方案

### 按 conversation index 切

最自然的分片方式。每个 task 处理一个连续区间：

```
Task 1: conv 0,1,2  — ~600 题 — 3~4h
Task 2: conv 3,5,6  — ~450 题 — 2~3h
Task 3: conv 6,7    — ~350 题 — 2h
Task 4: conv 8,9    — ~300 题 — 1.5h
```

### 环境变量接口

在 `run_locomo_local.py` 中已实现三个 env var：

```bash
CONV_START=0       # 起始 conversation index（默认 0）
CONV_END=2         # 结束 conversation index（默认 9）
BATCH_NAME=task1   # 结果文件标识（可选）
```

使用示例：

```bash
# 分片 1: conv 0-2
CONV_START=0 CONV_END=2 BATCH_NAME=task1 TOP_K=200 python run_locomo_local.py

# 分片 2: conv 3-5
CONV_START=3 CONV_END=5 BATCH_NAME=task2 TOP_K=200 python run_locomo_local.py
```

结果文件自动带上 BATCH_NAME 前缀，避免覆盖。

### 跑之前先算 token

执行前先估算 token 和费用：

```bash
python3 -c "
questions = 385  # 分片内题数
per_q = 2900     # answer_gen + judge 平均 token
total_tok = questions * per_q
cost = total_tok * 0.15 / 1_000_000
print(f'{questions}题 ≈ {total_tok:,}tok ≈ \${cost:.2f} (DeepSeek Flash)')
"
```

Conv 1 最小（81 题），适合做 smoke test：
- ~$0.04，15~20 分钟

全量 1,540 题：
- ~$0.67（Flash），~2~4 小时

## 结果合并

所有分片跑完后，用项目根目录下的 `merge_locomo_results.py` 合并：

```bash
python merge_locomo_results.py results/locomo_mneme/locomo_*.json \
  -o results/locomo_mneme/merged.json
```

该脚本功能：
- 接受 N 个结果文件（glob 或显式列表）
- 合并所有 evaluations 数组
- 使用 `compute_overall_metrics` 重算 metrics
- metadata 中记录 `merged_from` 文件列表
- 输出到指定路径

### 注意事项

- 每个分片必须使用**相同的 LLM 模型和 judge 配置**，否则结果不可比
- 每个分片独立消耗 API token，总 cost = 各分片之和（不节省总成本，只节省墙钟时间）
- 如果某个分片失败，只需重跑该区间，不影响其他已完成的
- 分片粒度建议至少 2-3 个 conversation 一组，太细（每 conv 一个 task）的开销不划算
