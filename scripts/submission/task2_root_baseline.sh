#!/usr/bin/env bash
set -euo pipefail

MODEL="${MODEL:-models/qwen3_8b_q40/dllama_model_qwen3_8b_q40.m}"
TOKENIZER="${TOKENIZER:-models/qwen3_8b_q40/dllama_tokenizer_qwen3_8b_q40.t}"
PROMPT="${PROMPT:-Hello World}"
STEPS="${STEPS:-128}"
NTHREADS="${NTHREADS:-8}"
NBATCHES="${NBATCHES:-32}"
MAX_SEQ_LEN="${MAX_SEQ_LEN:-4096}"
WORKERS=("${WORKER1:-127.0.0.1:9991}" "${WORKER2:-127.0.0.1:9992}" "${WORKER3:-127.0.0.1:9993}")

./dllama inference \
  --model "$MODEL" \
  --tokenizer "$TOKENIZER" \
  --buffer-float-type q80 \
  --workers "${WORKERS[0]}" "${WORKERS[1]}" "${WORKERS[2]}" \
  --nthreads "$NTHREADS" \
  --max-seq-len "$MAX_SEQ_LEN" \
  --n-batches "$NBATCHES" \
  --steps "$STEPS" \
  --prompt "$PROMPT"
