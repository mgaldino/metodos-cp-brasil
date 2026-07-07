#!/usr/bin/env python3
"""
Prepare or run the next credibility_prompt_v3 integral-reading batch.

The script keeps the operational loop deterministic:

1. Reuse the most recent incomplete active_batch_NNN manifest, if any.
2. Otherwise select the next 100 pending PIDs from the active full-corpus manifest.
3. Optionally render prompts (--dry-run) or run the real Codex batch (--run).
4. After a real run, refresh the canonical combined outputs and write summaries.
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import subprocess
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[1]

DEFAULT_MANIFEST = PROJECT_DIR / "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"
DEFAULT_OUT_DIR = PROJECT_DIR / "data/processed/credibility_prompt_v3_integral_reading/full_corpus"
DEFAULT_BATCH_DIR = PROJECT_DIR / "data/processed/credibility_prompt_v3_full_corpus/batch_manifests"
DEFAULT_QUALITY_DIR = PROJECT_DIR / "quality_reports"

ACTIVE_BATCH_RE = re.compile(r"^active_batch_(\d{3})\.csv$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--batch-dir", type=Path, default=DEFAULT_BATCH_DIR)
    parser.add_argument("--quality-dir", type=Path, default=DEFAULT_QUALITY_DIR)
    parser.add_argument("--label", default=None, help="Batch label, e.g. active_batch_006.")
    parser.add_argument("--limit", type=int, default=100)
    parser.add_argument("--timeout", type=int, default=2400)
    parser.add_argument("--codex-bin", default="codex")
    parser.add_argument("--model", default=None)
    parser.add_argument("--model-reasoning-effort", choices=["low", "medium", "high", "xhigh"], default="xhigh")
    parser.add_argument("--ephemeral", action="store_true")
    parser.add_argument("--force", action="store_true", help="Pass --force to the batch runner.")
    parser.add_argument("--dry-run", action="store_true", help="Render prompts for the selected batch, but do not call Codex.")
    parser.add_argument("--run", action="store_true", help="Run the selected batch with Codex exec.")
    return parser.parse_args()


def as_project_path(path: Path) -> Path:
    return path if path.is_absolute() else PROJECT_DIR / path


def read_pids(path: Path) -> list[str]:
    with path.open(encoding="utf-8", newline="") as f:
        return [row["pid"] for row in csv.DictReader(f)]


def batch_complete(batch_manifest: Path, out_dir: Path) -> bool:
    pids = read_pids(batch_manifest)
    return all(
        (out_dir / "reading_logs" / f"{pid}.json").exists()
        and (out_dir / "classifications" / f"{pid}.json").exists()
        for pid in pids
    )


def active_batch_number(path: Path) -> int | None:
    match = ACTIVE_BATCH_RE.match(path.name)
    return int(match.group(1)) if match else None


def choose_label(batch_dir: Path, out_dir: Path, requested_label: str | None) -> str:
    if requested_label:
        return requested_label

    numbered_batches = sorted(
        ((active_batch_number(path), path) for path in batch_dir.glob("active_batch_*.csv")),
        key=lambda item: item[0] or -1,
    )
    numbered_batches = [(number, path) for number, path in numbered_batches if number is not None]

    for _, path in reversed(numbered_batches):
        if not batch_complete(path, out_dir):
            return path.stem

    next_number = (numbered_batches[-1][0] + 1) if numbered_batches else 1
    return f"active_batch_{next_number:03d}"


def r_env() -> dict[str, str]:
    env = os.environ.copy()
    env["LANG"] = "pt_BR.UTF-8"
    env["LC_ALL"] = "pt_BR.UTF-8"
    env["LC_CTYPE"] = "pt_BR.UTF-8"
    return env


def run(cmd: list[str], *, env: dict[str, str] | None = None) -> None:
    print("+ " + " ".join(cmd), flush=True)
    subprocess.run(cmd, cwd=PROJECT_DIR, check=True, env=env)


def runner_base(args: argparse.Namespace, batch_manifest: Path) -> list[str]:
    cmd = [
        "python3",
        "scripts/25_run_credibility_prompt_v3_integral_codex_batch.py",
        "--manifest",
        str(batch_manifest.relative_to(PROJECT_DIR)),
        "--out-dir",
        str(args.out_dir.relative_to(PROJECT_DIR)),
        "--timeout",
        str(args.timeout),
        "--codex-bin",
        args.codex_bin,
        "--model-reasoning-effort",
        args.model_reasoning_effort,
    ]
    if args.model:
        cmd.extend(["--model", args.model])
    if args.ephemeral:
        cmd.append("--ephemeral")
    if args.force:
        cmd.append("--force")
    return cmd


def ensure_selection(args: argparse.Namespace, label: str, batch_manifest: Path, selection_report: Path) -> None:
    if batch_manifest.exists():
        print(f"Reusing batch manifest: {batch_manifest.relative_to(PROJECT_DIR)}")
        return

    cmd = [
        "Rscript",
        "--vanilla",
        "scripts/34_select_credibility_integral_next_batch.R",
        "--manifest",
        str(args.manifest.relative_to(PROJECT_DIR)),
        "--out-dir",
        str(args.out_dir.relative_to(PROJECT_DIR)),
        "--limit",
        str(args.limit),
        "--label",
        label,
        "--out",
        str(batch_manifest.relative_to(PROJECT_DIR)),
        "--report-out",
        str(selection_report.relative_to(PROJECT_DIR)),
    ]
    run(cmd, env=r_env())


def summarize(csv_path: Path, out_path: Path, label: str) -> None:
    cmd = [
        "Rscript",
        "--vanilla",
        "scripts/32_summarize_credibility_integral_batch.R",
        "--csv",
        str(csv_path.relative_to(PROJECT_DIR)),
        "--out",
        str(out_path.relative_to(PROJECT_DIR)),
        "--label",
        label,
    ]
    run(cmd, env=r_env())


def main() -> int:
    args = parse_args()
    args.manifest = as_project_path(args.manifest)
    args.out_dir = as_project_path(args.out_dir)
    args.batch_dir = as_project_path(args.batch_dir)
    args.quality_dir = as_project_path(args.quality_dir)

    if args.dry_run and args.run:
        raise SystemExit("Use only one of --dry-run or --run.")
    if args.limit <= 0:
        raise SystemExit("--limit must be positive.")

    label = choose_label(args.batch_dir, args.out_dir, args.label)
    batch_manifest = args.batch_dir / f"{label}.csv"
    selection_report = args.quality_dir / f"credibility_prompt_v3_{label}_selection.md"

    ensure_selection(args, label, batch_manifest, selection_report)

    print(f"Selected label: {label}")
    print(f"Batch manifest: {batch_manifest.relative_to(PROJECT_DIR)}")
    print(f"Selection report: {selection_report.relative_to(PROJECT_DIR)}")

    if not args.dry_run and not args.run:
        run_cmd = runner_base(args, batch_manifest) + ["--combined-stem", label]
        dry_cmd = runner_base(args, batch_manifest) + ["--dry-run", "--combined-stem", label]
        print("\nNext commands:")
        print("Dry run: " + " ".join(dry_cmd))
        print("Real run: " + " ".join(run_cmd))
        return 0

    batch_cmd = runner_base(args, batch_manifest) + ["--combined-stem", label]
    if args.dry_run:
        run(batch_cmd + ["--dry-run"])
        return 0

    run(batch_cmd)

    canonical_cmd = [
        "python3",
        "scripts/25_run_credibility_prompt_v3_integral_codex_batch.py",
        "--manifest",
        str(args.manifest.relative_to(PROJECT_DIR)),
        "--out-dir",
        str(args.out_dir.relative_to(PROJECT_DIR)),
        "--combine-only",
    ]
    run(canonical_cmd)

    combined_dir = args.out_dir / "combined"
    summarize(
        combined_dir / f"{label}.csv",
        combined_dir / f"batch_summary_{label}.md",
        f"{label}_limit_{args.limit}",
    )
    summarize(
        combined_dir / "classifications_integral_reading.csv",
        combined_dir / "batch_summary_current.md",
        "full_corpus_current_manifest_valid",
    )

    print("Batch loop step complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
