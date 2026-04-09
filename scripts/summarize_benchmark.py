#!/usr/bin/env python3
import argparse
import csv
from collections import defaultdict
from statistics import mean


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--csv", required=True)
    p.add_argument("--top", type=int, default=10)
    a = p.parse_args()

    rows = list(csv.DictReader(open(a.csv, "r", encoding="utf-8")))
    grouped = defaultdict(list)
    for r in rows:
        key = (r["profile"], r["backend"], r["nthreads"], r["nbatches"], r["max_seq_len"])
        grouped[key].append(float(r["pred_tokens_per_s"]))

    print("Top results by profile (sorted by avg prediction tokens/s):\n")
    by_profile = defaultdict(list)
    for key, vals in grouped.items():
        profile, backend, t, b, seq = key
        by_profile[profile].append((mean(vals), backend, t, b, seq, len(vals)))

    for profile, items in by_profile.items():
        print(f"[{profile}]")
        for avg, backend, t, b, seq, n in sorted(items, reverse=True)[:a.top]:
            print(f"backend={backend:7s} t={int(t):2d} b={int(b):2d} seq={int(seq):5d} runs={n:2d} pred_avg={avg:8.2f}")
        print()

if __name__ == "__main__":
    main()
