#!/usr/bin/env bash
set -euo pipefail

MODEL="${MODEL:-models/llama3_1_8b_instruct_q40/dllama_model_llama3_1_8b_instruct_q40.m}"
TOKENIZER="${TOKENIZER:-models/llama3_1_8b_instruct_q40/dllama_tokenizer_llama3_1_8b_instruct_q40.t}"
PROMPT="${PROMPT:-Hello World}"
STEPS="${STEPS:-128}"
WORKERS=("${WORKER1:-127.0.0.1:9991}" "${WORKER2:-127.0.0.1:9992}" "${WORKER3:-127.0.0.1:9993}")

./dllama inference \
  --model "$MODEL" \
  --tokenizer "$TOKENIZER" \
  --buffer-float-type q80 \
  --workers "${WORKERS[0]}" "${WORKERS[1]}" "${WORKERS[2]}" \
  --nthreads 2 \
  --max-seq-len 4096 \
  --n-batches 32 \
  --steps "$STEPS" \
  --prompt "$PROMPT"
