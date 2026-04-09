#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-9991}"
HOST="${HOST:-0.0.0.0}"
NTHREADS="${NTHREADS:-2}"

./dllama worker --host "$HOST" --port "$PORT" --nthreads "$NTHREADS"
