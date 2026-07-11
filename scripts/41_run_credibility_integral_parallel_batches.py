#!/usr/bin/env python3
"""
Run frozen integral-reading batches in parallel.

The script launches one low-level batch runner per label, with distinct
manifests and distinct combined stems. It requires --run for real execution;
without --run it only prints the commands that would be launched.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import time
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[1]

DEFAULT_MANIFEST = PROJECT_DIR / "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"
DEFAULT_OUT_DIR = PROJECT_DIR / "data/processed/credibility_prompt_v3_integral_reading/full_corpus"
DEFAULT_BATCH_DIR = PROJECT_DIR / "data/processed/credibility_prompt_v3_full_corpus/batch_manifests"
DEFAULT_PLAN_JSON = PROJECT_DIR / "quality_reports/credibility_prompt_v3_parallel_batches_plan.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--labels", nargs="+", default=None, help="Batch labels, e.g. active_batch_011 active_batch_012.")
    parser.add_argument("--plan-json", type=Path, default=DEFAULT_PLAN_JSON)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--batch-dir", type=Path, default=DEFAULT_BATCH_DIR)
    parser.add_argument("--timeout", type=int, default=2400)
    parser.add_argument("--codex-bin", default="codex")
    parser.add_argument("--model", default=None)
    parser.add_argument("--model-reasoning-effort", choices=["low", "medium", "high", "xhigh"], default="high")
    parser.add_argument("--service-tier", choices=["default", "fast"], default="default")
    parser.add_argument("--ephemeral", action="store_true")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--run", action="store_true", help="Actually launch child batch runners.")
    parser.add_argument("--combine-on-failure", action="store_true", help="Refresh combined outputs even if a child fails.")
    parser.add_argument("--skip-combine", action="store_true", help="Skip canonical combine and summaries after children finish.")
    parser.add_argument("--poll-seconds", type=int, default=30)
    return parser.parse_args()


def as_project_path(path: Path) -> Path:
    return path if path.is_absolute() else PROJECT_DIR / path


def project_relative(path: Path) -> str:
    try:
        return str(path.relative_to(PROJECT_DIR))
    except ValueError:
        return str(path)


def load_labels(args: argparse.Namespace) -> list[str]:
    if args.labels:
        return args.labels
    if args.plan_json.exists():
        plan = json.loads(args.plan_json.read_text(encoding="utf-8"))
        labels = plan.get("labels")
        if labels:
            return list(labels)
    raise SystemExit("Informe --labels ou prepare um plano JSON antes de executar.")


def r_env() -> dict[str, str]:
    env = os.environ.copy()
    env["LANG"] = "pt_BR.UTF-8"
    env["LC_ALL"] = "pt_BR.UTF-8"
    env["LC_CTYPE"] = "pt_BR.UTF-8"
    return env


def batch_command(args: argparse.Namespace, label: str) -> list[str]:
    manifest = args.batch_dir / f"{label}.csv"
    if not manifest.exists():
        raise SystemExit(f"Manifesto do batch ausente: {manifest}")
    cmd = [
        "python3",
        "scripts/25_run_credibility_prompt_v3_integral_codex_batch.py",
        "--manifest",
        project_relative(manifest),
        "--out-dir",
        project_relative(args.out_dir),
        "--timeout",
        str(args.timeout),
        "--codex-bin",
        args.codex_bin,
        "--model-reasoning-effort",
        args.model_reasoning_effort,
        "--combined-stem",
        label,
        "--service-tier",
        args.service_tier,
    ]
    if args.model:
        cmd.extend(["--model", args.model])
    if args.ephemeral:
        cmd.append("--ephemeral")
    if args.force:
        cmd.append("--force")
    return cmd


def command_line(cmd: list[str]) -> str:
    return " ".join(cmd)


def run_checked(cmd: list[str], *, env: dict[str, str] | None = None) -> None:
    print("+ " + command_line(cmd), flush=True)
    subprocess.run(cmd, cwd=PROJECT_DIR, env=env, check=True)


def summarize(csv_path: Path, out_path: Path, label: str) -> None:
    if not csv_path.exists():
        print(f"Skipping summary; CSV not found: {project_relative(csv_path)}")
        return
    run_checked(
        [
            "Rscript",
            "--vanilla",
            "scripts/32_summarize_credibility_integral_batch.R",
            "--csv",
            project_relative(csv_path),
            "--out",
            project_relative(out_path),
            "--label",
            label,
        ],
        env=r_env(),
    )


def combine_and_summarize(args: argparse.Namespace, labels: list[str]) -> None:
    run_checked(
        [
            "python3",
            "scripts/25_run_credibility_prompt_v3_integral_codex_batch.py",
            "--manifest",
            project_relative(args.manifest),
            "--out-dir",
            project_relative(args.out_dir),
            "--combine-only",
        ]
    )
    combined_dir = args.out_dir / "combined"
    for label in labels:
        summarize(
            combined_dir / f"{label}.csv",
            combined_dir / f"batch_summary_{label}.md",
            label,
        )
    summarize(
        combined_dir / "classifications_integral_reading.csv",
        combined_dir / "batch_summary_current.md",
        "full_corpus_current_manifest_valid",
    )


def run_parallel(args: argparse.Namespace, labels: list[str]) -> dict[str, int]:
    log_dir = args.out_dir / "parallel_run_logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    processes: dict[str, tuple[subprocess.Popen[bytes], object, object]] = {}
    for label in labels:
        cmd = batch_command(args, label)
        stdout_path = log_dir / f"{label}.stdout.log"
        stderr_path = log_dir / f"{label}.stderr.log"
        stdout_file = stdout_path.open("wb")
        stderr_file = stderr_path.open("wb")
        proc = subprocess.Popen(cmd, cwd=PROJECT_DIR, stdout=stdout_file, stderr=stderr_file)
        processes[label] = (proc, stdout_file, stderr_file)
        print(f"Started {label}: pid={proc.pid}")
        print(f"  stdout: {project_relative(stdout_path)}")
        print(f"  stderr: {project_relative(stderr_path)}")

    return_codes: dict[str, int] = {}
    while processes:
        finished: list[str] = []
        for label, (proc, stdout_file, stderr_file) in processes.items():
            return_code = proc.poll()
            if return_code is None:
                continue
            stdout_file.close()
            stderr_file.close()
            return_codes[label] = return_code
            status = "OK" if return_code == 0 else f"FAIL rc={return_code}"
            print(f"Finished {label}: {status}", flush=True)
            finished.append(label)
        for label in finished:
            processes.pop(label)
        if processes:
            time.sleep(args.poll_seconds)
    return return_codes


def main() -> int:
    args = parse_args()
    args.plan_json = as_project_path(args.plan_json)
    args.manifest = as_project_path(args.manifest)
    args.out_dir = as_project_path(args.out_dir)
    args.batch_dir = as_project_path(args.batch_dir)

    if args.poll_seconds <= 0:
        raise SystemExit("--poll-seconds deve ser positivo.")
    labels = load_labels(args)
    commands = [batch_command(args, label) for label in labels]

    if not args.run:
        print("Prepared commands; add --run to execute:")
        for cmd in commands:
            print(command_line(cmd))
        return 0

    return_codes = run_parallel(args, labels)
    failed = {label: code for label, code in return_codes.items() if code != 0}

    if args.skip_combine:
        return 1 if failed else 0
    if failed and not args.combine_on_failure:
        print("Skipping canonical combine because at least one child failed.")
        return 1

    combine_and_summarize(args, labels)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
