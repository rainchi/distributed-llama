#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOH'
Usage:
  scripts/iterative_bench.sh \
    [--model <path>] \
    [--tokenizer <path>] \
    --backend <cpu|vulkan> \
    --max-seq-len <n> \
    [--auto-model-id <id>] \
    [--iterations <n>] \
    [--runs-per-case <n>] \
    [--max-retries <n>] \
    [--nthreads-list <csv>] \
    [--nbatches-list <csv>] \
    [--profiles-file <path>] \
    [--out-dir <dir>] \
    [--tag <name>] \
    [--build]
EOH
}

MODEL=""
TOKENIZER=""
BACKEND="cpu"
MAX_SEQ_LEN=""
AUTO_MODEL_ID="qwen3_0.6b_q40"
ITERATIONS=1
RUNS_PER_CASE=1
MAX_RETRIES=1
NTHREADS_LIST="16"
NBATCHES_LIST="32"
PROFILES_FILE="scripts/bench_profiles.tsv"
OUT_DIR="report/benchmarks"
TAG="iter"
DO_BUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    --tokenizer) TOKENIZER="$2"; shift 2 ;;
    --backend) BACKEND="$2"; shift 2 ;;
    --max-seq-len) MAX_SEQ_LEN="$2"; shift 2 ;;
    --auto-model-id) AUTO_MODEL_ID="$2"; shift 2 ;;
    --iterations) ITERATIONS="$2"; shift 2 ;;
    --runs-per-case) RUNS_PER_CASE="$2"; shift 2 ;;
    --max-retries) MAX_RETRIES="$2"; shift 2 ;;
    --nthreads-list) NTHREADS_LIST="$2"; shift 2 ;;
    --nbatches-list) NBATCHES_LIST="$2"; shift 2 ;;
    --profiles-file) PROFILES_FILE="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    --build) DO_BUILD=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

[[ -z "$MAX_SEQ_LEN" ]] && { echo "--max-seq-len required" >&2; exit 1; }
[[ ! -f "$PROFILES_FILE" ]] && { echo "Profiles file not found: $PROFILES_FILE" >&2; exit 1; }

if [[ -z "$MODEL" || -z "$TOKENIZER" ]]; then
  python3 launch.py "$AUTO_MODEL_ID" -skip-run -y >/dev/null
  MODEL=${MODEL:-$(find "models/$AUTO_MODEL_ID" -maxdepth 1 -type f -name 'dllama_model_*.m' | head -n 1)}
  TOKENIZER=${TOKENIZER:-$(find "models/$AUTO_MODEL_ID" -maxdepth 1 -type f -name 'dllama_tokenizer_*.t' | head -n 1)}
fi

[[ -z "$MODEL" || -z "$TOKENIZER" ]] && { echo "Cannot resolve model/tokenizer" >&2; exit 1; }

IFS=',' read -r -a NTHREADS_ARR <<< "$NTHREADS_LIST"
IFS=',' read -r -a NBATCHES_ARR <<< "$NBATCHES_LIST"

if [[ "$BACKEND" == "vulkan" ]]; then
  NTHREADS_ARR=(1)
fi

if [[ $DO_BUILD -eq 1 ]]; then
  make clean
  if [[ "$BACKEND" == "vulkan" ]]; then
    make DLLAMA_VULKAN=1 dllama
  else
    make dllama
  fi
fi

for ((iter=1; iter<=ITERATIONS; iter++)); do
  while IFS=$'\t' read -r profile steps prompt; do
    [[ -z "$profile" || "$profile" =~ ^# ]] && continue
    [[ "$prompt" == "[REPLACE_WITH_OFFICIAL_LEADERBOARD_PROMPT]" ]] && continue
    for t in "${NTHREADS_ARR[@]}"; do
      for b in "${NBATCHES_ARR[@]}"; do
        scripts/run_single_node_bench.sh \
          --model "$MODEL" \
          --tokenizer "$TOKENIZER" \
          --profile "$profile" \
          --prompt "$prompt" \
          --steps "$steps" \
          --backend "$BACKEND" \
          --nthreads "$t" \
          --max-seq-len "$MAX_SEQ_LEN" \
          --nbatches "$b" \
          --runs "$RUNS_PER_CASE" \
          --max-retries "$MAX_RETRIES" \
          --out-dir "$OUT_DIR" \
          --tag "${TAG}_i${iter}_p${profile}_t${t}_b${b}"
      done
    done
  done < "$PROFILES_FILE"
done

python3 scripts/summarize_benchmark.py --csv "$OUT_DIR/results.csv" --top 15
