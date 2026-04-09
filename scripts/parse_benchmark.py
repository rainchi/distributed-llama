#!/usr/bin/env python3
import argparse
import csv
import json
import os
import re
from dataclasses import asdict, dataclass
from statistics import mean

TOKENS_PER_S_RE = re.compile(r"tokens/s:\s*([0-9]+(?:\.[0-9]+)?)\s*\(([0-9]+(?:\.[0-9]+)?)\s*ms/tok\)")
NTOKENS_RE = re.compile(r"nTokens:\s*([0-9]+)")
EVAL_LINE_RE = re.compile(r"Eval\s*([0-9]+)\s*ms\s*Sync\s*([0-9]+)\s*ms")
PRED_LINE_RE = re.compile(r"Pred\s*([0-9]+)\s*ms\s*Sync\s*([0-9]+)\s*ms")

@dataclass
class ParseResult:
    log_file: str
    profile: str
    backend: str
    tag: str
    nthreads: int
    nbatches: int
    max_seq_len: int
    steps: int
    eval_tokens: int
    eval_tokens_per_s: float
    eval_ms_per_tok: float
    pred_tokens: int
    pred_tokens_per_s: float
    pred_ms_per_tok: float
    eval_avg_ms: float
    eval_avg_sync_ms: float
    pred_avg_ms: float
    pred_avg_sync_ms: float

def parse_log(path: str):
    section = None
    eval_tokens = pred_tokens = None
    eval_tps = eval_ms_tok = None
    pred_tps = pred_ms_tok = None
    eval_ms, eval_sync_ms, pred_ms, pred_sync_ms = [], [], [], []

    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for raw in f:
            line = raw.strip()
            m = EVAL_LINE_RE.search(line)
            if m:
                eval_ms.append(float(m.group(1)))
                eval_sync_ms.append(float(m.group(2)))
            m = PRED_LINE_RE.search(line)
            if m:
                pred_ms.append(float(m.group(1)))
                pred_sync_ms.append(float(m.group(2)))

            if line == "Evaluation":
                section = "eval"
                continue
            if line == "Prediction":
                section = "pred"
                continue

            m = NTOKENS_RE.search(line)
            if m and section == "eval":
                eval_tokens = int(m.group(1))
                continue
            if m and section == "pred":
                pred_tokens = int(m.group(1))
                continue

            m = TOKENS_PER_S_RE.search(line)
            if m and section == "eval":
                eval_tps = float(m.group(1))
                eval_ms_tok = float(m.group(2))
                continue
            if m and section == "pred":
                pred_tps = float(m.group(1))
                pred_ms_tok = float(m.group(2))
                continue

    required = [eval_tokens, eval_tps, eval_ms_tok, pred_tokens, pred_tps, pred_ms_tok]
    if any(v is None for v in required):
        raise ValueError(f"Failed to parse required fields from {path}")

    return {
        "eval_tokens": eval_tokens,
        "eval_tokens_per_s": eval_tps,
        "eval_ms_per_tok": eval_ms_tok,
        "pred_tokens": pred_tokens,
        "pred_tokens_per_s": pred_tps,
        "pred_ms_per_tok": pred_ms_tok,
        "eval_avg_ms": mean(eval_ms) if eval_ms else 0.0,
        "eval_avg_sync_ms": mean(eval_sync_ms) if eval_sync_ms else 0.0,
        "pred_avg_ms": mean(pred_ms) if pred_ms else 0.0,
        "pred_avg_sync_ms": mean(pred_sync_ms) if pred_sync_ms else 0.0,
    }

def append_csv(path: str, row: ParseResult):
    data = asdict(row)
    file_exists = os.path.exists(path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(data.keys()))
        if not file_exists:
            writer.writeheader()
        writer.writerow(data)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--log", required=True)
    p.add_argument("--profile", required=True)
    p.add_argument("--backend", required=True, choices=["cpu", "vulkan"])
    p.add_argument("--tag", default="")
    p.add_argument("--nthreads", required=True, type=int)
    p.add_argument("--nbatches", required=True, type=int)
    p.add_argument("--max-seq-len", required=True, type=int)
    p.add_argument("--steps", required=True, type=int)
    p.add_argument("--json-out", required=True)
    p.add_argument("--csv-out", required=True)
    a = p.parse_args()

    parsed = parse_log(a.log)
    result = ParseResult(
        log_file=a.log,
        profile=a.profile,
        backend=a.backend,
        tag=a.tag,
        nthreads=a.nthreads,
        nbatches=a.nbatches,
        max_seq_len=a.max_seq_len,
        steps=a.steps,
        **parsed,
    )

    os.makedirs(os.path.dirname(a.json_out), exist_ok=True)
    with open(a.json_out, "w", encoding="utf-8") as f:
        json.dump(asdict(result), f, indent=2)

    append_csv(a.csv_out, result)
    print(f"Parsed benchmark: {a.profile} {a.backend} pred_tokens/s={result.pred_tokens_per_s:.2f}")

if __name__ == "__main__":
    main()
