# DLLAMA Competition Submission Repo

This repository is prepared only for competition usage.
All content below is focused on Task 1, Task 2, Task 3, reproducible run commands, and submission requirements.

## 1. Competition Scope

Source project:
- https://github.com/b4rtaz/distributed-llama

Tasks:
- Task 1: Llama 3.1 8B Instruct Q40 baseline
- Task 2: Qwen 3 8B Q40 baseline
- Task 3: Llama 3.1 8B Instruct Q40 optimized

Evaluation:
- Throughput metric: tokens/s
- Prompt sets: short, long, leaderboard
- Leaderboard prompt compared across all teams

## 2. What Is Included In This Submission

This submission repo contains:
- Modified DLLAMA code used for optimization workflow
- Example run scripts for benchmark execution
- Competition-oriented notes and decisions

This submission repo does not include:
- ROCm backend code and scripts

ROCm note:
- We planned ROCm experiments but removed ROCm implementation from this submission branch due to limited pre-benchmark time.
- We prioritized stable and reproducible CPU/Vulkan-oriented benchmark workflows.

## 3. Build

Build root binary:

```sh
make clean
make dllama
```

## 4. Worker Startup (Multi-node)

On each worker node, run:

```sh
scripts/submission/worker.sh 9991
```

Use different ports for each worker, for example:
- Worker 1: 9991
- Worker 2: 9992
- Worker 3: 9993

## 5. Task Run Scripts

### Task 1 (Baseline, fixed rules)

Rule-aligned script:
- 4 nodes total (1 root + 3 workers)
- 2 threads per node
- max sequence length 4096

```sh
scripts/submission/task1_root_baseline.sh
```

### Task 2 (Baseline, runtime tuning allowed)

Rule-aligned script:
- 4 nodes total (1 root + 3 workers)
- source/model/tokenizer unchanged
- runtime parameters tunable (threads, batches, max sequence length)

```sh
scripts/submission/task2_root_baseline.sh
```

### Task 3 (Optimized)

Optimized run example script:

```sh
scripts/submission/task3_root_optimized.sh
```

## 6. Single-node Tuning Utilities (Pre-benchmark)

Primary iterative tuning utility:

```sh
scripts/iterative_bench.sh \
  --backend cpu \
  --max-seq-len 4096 \
  --auto-model-id qwen3_0.6b_q40 \
  --iterations 1 \
  --runs-per-case 1 \
  --nthreads-list 4,8,12,16 \
  --nbatches-list 8,16,32 \
  --out-dir report/benchmarks_auto \
  --tag prebench \
  --build
```

Other useful scripts:
- scripts/run_single_node_bench.sh
- scripts/optimize_then_bench.sh
- scripts/check_regression.py
- scripts/summarize_benchmark.py

## 7. Task 3 Optimization Summary

Approaches tried:
- Automated parameter sweeps for throughput and stability
- Finite optimize-then-benchmark loops
- Regression checks against baseline tags

What worked:
- Reproducible benchmark automation
- Faster iteration for runtime parameter selection
- Clear artifact structure for logs and CSV metrics

What did not proceed in this branch:
- ROCm backend path
- Reason: limited time before benchmark start; branch simplified for clean submission and reproducibility

## 8. Submission Checklist

Before benchmarking starts in local timezone, ensure this repo has:
- Optimized/modified DLLAMA repository (if applicable)
- Any additional implementation code used by the team
- Example run scripts for Task 3
- This README with approaches, decisions, what worked, and what did not

## 9. Quick Command Reference

Task 1 root:

```sh
scripts/submission/task1_root_baseline.sh
```

Task 2 root:

```sh
scripts/submission/task2_root_baseline.sh
```

Task 3 root:

```sh
scripts/submission/task3_root_optimized.sh
```

Worker:

```sh
scripts/submission/worker.sh 9991
```
