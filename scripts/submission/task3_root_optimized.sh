#!/usr/bin/env bash
set -euo pipefail

MODEL="${MODEL:-models/llama3_1_8b_instruct_q40/dllama_model_llama3_1_8b_instruct_q40.m}"
TOKENIZER="${TOKENIZER:-models/llama3_1_8b_instruct_q40/dllama_tokenizer_llama3_1_8b_instruct_q40.t}"
PROMPT="${PROMPT:-Summarize distributed inference in one sentence.}"
STEPS="${STEPS:-256}"
NTHREADS="${NTHREADS:-12}"
NBATCHES="${NBATCHES:-16}"
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
  --temperature 0.7 \
  --topp 0.9 \
  --prompt "$PROMPT"
