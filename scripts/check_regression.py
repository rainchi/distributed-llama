#!/usr/bin/env python3
import argparse
import csv


def mean(vals):
    return sum(vals) / len(vals) if vals else 0.0


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--csv", required=True)
    p.add_argument("--baseline-tag", required=True)
    p.add_argument("--candidate-tag", required=True)
    p.add_argument("--profiles", default="short,long")
    p.add_argument("--max-drop-pct", type=float, default=3.0)
    a = p.parse_args()

    profiles = [x.strip() for x in a.profiles.split(",") if x.strip()]
    rows = list(csv.DictReader(open(a.csv, "r", encoding="utf-8")))

    ok = True
    for profile in profiles:
        b = [float(r["pred_tokens_per_s"]) for r in rows if r.get("tag") == a.baseline_tag and r.get("profile") == profile]
        c = [float(r["pred_tokens_per_s"]) for r in rows if r.get("tag") == a.candidate_tag and r.get("profile") == profile]
        if not b or not c:
            print(f"{profile}: missing rows")
            ok = False
            continue
        mb = mean(b)
        mc = mean(c)
        drop = 100.0 * (mb - mc) / mb if mb > 0 else 0.0
        print(f"{profile}: baseline={mb:.2f} candidate={mc:.2f} drop={drop:.2f}%")
        if drop > a.max_drop_pct:
            ok = False

    if not ok:
        raise SystemExit(1)

if __name__ == "__main__":
    main()
