#!/usr/bin/env python3
"""Run a checkpointed, timed credibility-classification model benchmark."""

from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
import time
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[1]
RUNNER = PROJECT_DIR / "scripts" / "25_run_credibility_prompt_v3_integral_codex_batch.py"
DEFAULT_MANIFEST = (
    PROJECT_DIR
    / "data"
    / "processed"
    / "credibility_prompt_v3_full_corpus"
    / "batch_manifests"
    / "ab_gpt56_models_10.csv"
)
DEFAULT_OUT_ROOT = (
    PROJECT_DIR
    / "data"
    / "processed"
    / "credibility_prompt_v3_integral_reading"
    / "full_corpus_ab"
    / "gpt56_model_benchmark_10"
)


@dataclass(frozen=True)
class BenchmarkConfig:
    label: str
    model: str
    effort: str


CONFIGS = (
    BenchmarkConfig("sol_medium", "gpt-5.6-sol", "medium"),
    BenchmarkConfig("terra_medium", "gpt-5.6-terra", "medium"),
    BenchmarkConfig("terra_xhigh", "gpt-5.6-terra", "xhigh"),
)

TIMING_FIELDS = (
    "label",
    "model",
    "effort",
    "pid",
    "attempt",
    "started_at_utc",
    "finished_at_utc",
    "elapsed_seconds",
    "return_code",
    "status",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--out-root", type=Path, default=DEFAULT_OUT_ROOT)
    parser.add_argument("--timeout", type=int, default=2400)
    parser.add_argument("--codex-bin", default="codex")
    parser.add_argument("--run", action="store_true", help="Execute the benchmark.")
    return parser.parse_args()


def as_project_path(path: Path) -> Path:
    return path if path.is_absolute() else PROJECT_DIR / path


def validate_out_root(out_root: Path) -> None:
    resolved = out_root.resolve()
    if "full_corpus_ab" not in resolved.parts or resolved.name != "gpt56_model_benchmark_10":
        raise ValueError(
            "Benchmark output must be the isolated full_corpus_ab/gpt56_model_benchmark_10 directory."
        )


def read_pids(manifest: Path) -> list[str]:
    with manifest.open(encoding="utf-8", newline="") as handle:
        pids = [row["pid"] for row in csv.DictReader(handle)]
    if len(pids) != 10 or len(set(pids)) != 10:
        raise ValueError("Benchmark manifest must contain exactly 10 unique PIDs.")
    return pids


def rotated_configs(index: int) -> tuple[BenchmarkConfig, ...]:
    offset = index % len(CONFIGS)
    return CONFIGS[offset:] + CONFIGS[:offset]


def combined_stem(config: BenchmarkConfig) -> str:
    return f"classifications_integral_reading_{config.label}_10"


def arm_dir(out_root: Path, config: BenchmarkConfig) -> Path:
    return out_root / config.label


def build_runner_command(
    *,
    manifest: Path,
    out_root: Path,
    config: BenchmarkConfig,
    timeout: int,
    codex_bin: str,
    pid: str | None = None,
    combine_only: bool = False,
) -> list[str]:
    command = [
        sys.executable,
        str(RUNNER),
        "--manifest",
        str(manifest),
        "--out-dir",
        str(arm_dir(out_root, config)),
        "--timeout",
        str(timeout),
        "--codex-bin",
        codex_bin,
        "--model",
        config.model,
        "--model-reasoning-effort",
        config.effort,
        "--ephemeral",
        "--combined-stem",
        combined_stem(config),
    ]
    if pid is not None:
        command.extend(["--pid", pid])
    if combine_only:
        command.append("--combine-only")
    return command


def is_complete(out_root: Path, config: BenchmarkConfig, pid: str) -> bool:
    base = arm_dir(out_root, config)
    return (
        (base / "classifications" / f"{pid}.json").exists()
        and (base / "reading_logs" / f"{pid}.json").exists()
    )


def read_timings(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def write_timings(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=TIMING_FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    temporary.replace(path)


def next_attempt(rows: list[dict[str, object]], label: str, pid: str) -> int:
    prior = [row for row in rows if row["label"] == label and row["pid"] == pid]
    return len(prior) + 1


def write_metadata(out_root: Path, manifest: Path) -> None:
    metadata = {
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "manifest": str(manifest),
        "configurations": [asdict(config) for config in CONFIGS],
        "requested_speed": "standard/default for every arm",
        "effective_speed": "not_observed_by_codex_exec",
        "execution": "sequential with rotating arm order by PID",
        "baseline": "gpt-5.5 xhigh canonical classifications; historical gpt-5.5 high A/B",
    }
    out_root.mkdir(parents=True, exist_ok=True)
    (out_root / "benchmark_metadata.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def run_one(
    *,
    manifest: Path,
    out_root: Path,
    config: BenchmarkConfig,
    pid: str,
    timeout: int,
    codex_bin: str,
    timing_rows: list[dict[str, object]],
    timing_path: Path,
) -> bool:
    if is_complete(out_root, config, pid):
        print(f"SKIP {config.label} {pid} already complete", flush=True)
        return True

    command = build_runner_command(
        manifest=manifest,
        out_root=out_root,
        config=config,
        timeout=timeout,
        codex_bin=codex_bin,
        pid=pid,
    )
    wrapper_log_dir = out_root / "benchmark_run_logs" / config.label
    wrapper_log_dir.mkdir(parents=True, exist_ok=True)
    attempt = next_attempt(timing_rows, config.label, pid)
    started_at = datetime.now(timezone.utc)
    start = time.perf_counter()
    print(f"RUN  {config.label} {pid} attempt={attempt}", flush=True)
    result = subprocess.run(
        command,
        cwd=PROJECT_DIR,
        text=True,
        encoding="utf-8",
        capture_output=True,
        check=False,
    )
    elapsed = time.perf_counter() - start
    finished_at = datetime.now(timezone.utc)
    (wrapper_log_dir / f"{pid}.attempt_{attempt}.stdout.log").write_text(
        result.stdout, encoding="utf-8"
    )
    (wrapper_log_dir / f"{pid}.attempt_{attempt}.stderr.log").write_text(
        result.stderr, encoding="utf-8"
    )
    complete = result.returncode == 0 and is_complete(out_root, config, pid)
    timing_rows.append(
        {
            "label": config.label,
            "model": config.model,
            "effort": config.effort,
            "pid": pid,
            "attempt": attempt,
            "started_at_utc": started_at.isoformat(),
            "finished_at_utc": finished_at.isoformat(),
            "elapsed_seconds": f"{elapsed:.6f}",
            "return_code": result.returncode,
            "status": "complete" if complete else "failed",
        }
    )
    write_timings(timing_path, timing_rows)
    print(
        f"{'OK' if complete else 'FAIL'} {config.label} {pid} elapsed={elapsed:.1f}s",
        flush=True,
    )
    return complete


def combine_arm(
    *,
    manifest: Path,
    out_root: Path,
    config: BenchmarkConfig,
    timeout: int,
    codex_bin: str,
) -> bool:
    command = build_runner_command(
        manifest=manifest,
        out_root=out_root,
        config=config,
        timeout=timeout,
        codex_bin=codex_bin,
        combine_only=True,
    )
    result = subprocess.run(command, cwd=PROJECT_DIR, check=False)
    return result.returncode == 0


def main() -> int:
    args = parse_args()
    manifest = as_project_path(args.manifest).resolve()
    out_root = as_project_path(args.out_root).resolve()
    validate_out_root(out_root)
    pids = read_pids(manifest)

    print(f"Manifest: {manifest}")
    print(f"Output root: {out_root}")
    for index, pid in enumerate(pids):
        print(f"{index + 1:02d} {pid}: " + ", ".join(c.label for c in rotated_configs(index)))

    if not args.run:
        print("Dry plan only. Pass --run to execute 30 classifications.")
        return 0

    write_metadata(out_root, manifest)
    timing_path = out_root / "benchmark_timings.csv"
    timing_rows: list[dict[str, object]] = list(read_timings(timing_path))
    failures: list[tuple[str, str]] = []

    for index, pid in enumerate(pids):
        for config in rotated_configs(index):
            complete = run_one(
                manifest=manifest,
                out_root=out_root,
                config=config,
                pid=pid,
                timeout=args.timeout,
                codex_bin=args.codex_bin,
                timing_rows=timing_rows,
                timing_path=timing_path,
            )
            if not complete:
                failures.append((config.label, pid))

    combine_ok = all(
        combine_arm(
            manifest=manifest,
            out_root=out_root,
            config=config,
            timeout=args.timeout,
            codex_bin=args.codex_bin,
        )
        for config in CONFIGS
    )
    if failures:
        print("Failed classifications:", file=sys.stderr)
        for label, pid in failures:
            print(f"- {label}: {pid}", file=sys.stderr)
    return 0 if not failures and combine_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
