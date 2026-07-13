#!/usr/bin/env python3
"""Wait for two active batches to close, then launch the next priority pair."""

from __future__ import annotations

import argparse
import csv
import subprocess
import time
from pathlib import Path


JOURNALS = (
    "Revista Brasileira de Política Internacional",
    "Revista Brasileira de Ciências Sociais",
)


def batch_status(root: Path, label: str) -> tuple[int, int, int]:
    manifest = root / "data/processed/credibility_prompt_v3_full_corpus/batch_manifests" / f"{label}.csv"
    output = root / "data/processed/credibility_prompt_v3_integral_reading/full_corpus"
    with manifest.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    pids = [row["pid"] for row in rows]
    complete = sum((output / "provenance" / f"{pid}.json").exists() for pid in pids)
    failed = sum((output / "failed" / f"{pid}.txt").exists() for pid in pids)
    return complete, failed, len(pids)


def select_batch(root: Path, label: str, journal: str) -> None:
    command = [
        "Rscript",
        "--vanilla",
        str(root / "scripts/34_select_credibility_integral_next_batch.R"),
        "--manifest",
        str(root / "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"),
        "--out-dir",
        str(root / "data/processed/credibility_prompt_v3_integral_reading/full_corpus"),
        "--limit",
        "100",
        "--label",
        label,
        "--journal-title",
        journal,
    ]
    subprocess.run(command, cwd=root, check=True)


def launch_batches(root: Path, labels: list[str], args: argparse.Namespace) -> None:
    command = [
        "python3",
        str(root / "scripts/41_run_credibility_integral_parallel_batches.py"),
        "--labels",
        *labels,
        "--model",
        args.model,
        "--model-reasoning-effort",
        args.reasoning_effort,
        "--service-tier",
        args.service_tier,
        "--timeout",
        str(args.timeout),
        "--poll-seconds",
        str(args.poll_seconds),
        "--ephemeral",
        "--run",
    ]
    subprocess.run(command, cwd=root, check=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--poll-seconds", type=int, default=60)
    parser.add_argument("--timeout", type=int, default=2400)
    parser.add_argument("--model", default="gpt-5.6-luna")
    parser.add_argument("--reasoning-effort", default="xhigh")
    parser.add_argument("--service-tier", default="default")
    args = parser.parse_args()

    root = args.root.resolve()
    labels = ["active_batch_019", "active_batch_020"]
    while True:
        statuses = [batch_status(root, label) for label in ("active_batch_017", "active_batch_018")]
        print(f"Current batches: {statuses}", flush=True)
        if all(complete == total and failed == 0 for complete, failed, total in statuses):
            break
        time.sleep(args.poll_seconds)

    for label, journal in zip(labels, JOURNALS):
        manifest = root / "data/processed/credibility_prompt_v3_full_corpus/batch_manifests" / f"{label}.csv"
        if not manifest.exists():
            select_batch(root, label, journal)

    launch_batches(root, labels, args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
