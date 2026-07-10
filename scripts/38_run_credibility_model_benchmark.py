#!/usr/bin/env python3
"""Run a checkpointed, timed credibility-classification model benchmark."""

from __future__ import annotations

import argparse
import csv
import hashlib
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
PROMPT_TEMPLATE = (
    PROJECT_DIR
    / "data"
    / "processed"
    / "credibility_prompt_v3_integral_reading"
    / "prompts"
    / "classifier_prompt_v3_integral_reading.md"
)
OUTPUT_SCHEMA = PROMPT_TEMPLATE.with_name("integral_reading_output_schema.json")


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


def read_manifest(manifest: Path) -> list[dict[str, str]]:
    with manifest.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    if len(rows) != 10 or len({row["pid"] for row in rows}) != 10:
        raise ValueError("Benchmark manifest must contain exactly 10 unique PIDs.")
    if any(not row.get("input_text_hash") for row in rows):
        raise ValueError("Every benchmark row must have input_text_hash.")
    return rows


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
    force: bool = False,
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
        "--service-tier",
        "default",
        "--ephemeral",
        "--combined-stem",
        combined_stem(config),
    ]
    if pid is not None:
        command.extend(["--pid", pid])
    if combine_only:
        command.append("--combine-only")
    if force:
        command.append("--force")
    return command


def validate_saved_output(
    out_root: Path, config: BenchmarkConfig, row: dict[str, str]
) -> tuple[bool, str]:
    base = arm_dir(out_root, config)
    pid = row["pid"]
    classification_path = base / "classifications" / f"{pid}.json"
    reading_path = base / "reading_logs" / f"{pid}.json"
    if not classification_path.exists() or not reading_path.exists():
        return False, "classification or reading log missing"
    try:
        classification = json.loads(classification_path.read_text(encoding="utf-8"))
        reading = json.loads(reading_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        return False, f"unparseable saved output: {exc}"
    if not isinstance(classification, dict) or not isinstance(reading, dict):
        return False, "saved outputs must be JSON objects"
    expected_hash = row["input_text_hash"]
    if classification.get("pid") != pid or reading.get("pid") != pid:
        return False, "saved PID mismatch"
    if (
        classification.get("input_text_hash") != expected_hash
        or reading.get("input_text_hash") != expected_hash
    ):
        return False, "saved input_text_hash mismatch"
    if reading.get("status") != "complete" or reading.get("full_body_read") is not True:
        return False, "reading log is not complete"
    sections = reading.get("section_reading_log")
    if not isinstance(sections, list) or not sections:
        return False, "reading log has no sections"
    if any(
        not isinstance(section, dict) or not str(section.get("section_summary", "")).strip()
        for section in sections
    ):
        return False, "reading log has an empty section summary"
    return True, "ok"


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


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def codex_version(codex_bin: str) -> str:
    result = subprocess.run(
        [codex_bin, "--version"], text=True, encoding="utf-8", capture_output=True, check=True
    )
    return result.stdout.strip()


def ensure_metadata(out_root: Path, manifest: Path, codex_bin: str) -> None:
    contract_files = [manifest, Path(__file__), RUNNER, PROMPT_TEMPLATE, OUTPUT_SCHEMA]
    contract = {
        "manifest": str(manifest),
        "configurations": [asdict(config) for config in CONFIGS],
        "service_tier": "default",
        "execution": "sequential with rotating arm order by PID",
        "file_sha256": {str(path): sha256_file(path) for path in contract_files},
        "codex_version": codex_version(codex_bin),
    }
    metadata = {
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "contract": contract,
        "effective_speed": "not_observed_by_codex_exec",
        "baseline": "gpt-5.5 xhigh canonical classifications; historical gpt-5.5 high A/B",
    }
    out_root.mkdir(parents=True, exist_ok=True)
    metadata_path = out_root / "benchmark_metadata.json"
    if metadata_path.exists():
        existing = json.loads(metadata_path.read_text(encoding="utf-8"))
        if existing.get("contract") != contract:
            raise RuntimeError("Existing benchmark metadata does not match the current run contract.")
        return
    metadata_path.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def has_complete_timing(
    rows: list[dict[str, object]], label: str, pid: str
) -> bool:
    return any(
        row["label"] == label and row["pid"] == pid and row["status"] == "complete"
        for row in rows
    )


def run_one(
    *,
    manifest: Path,
    out_root: Path,
    config: BenchmarkConfig,
    row: dict[str, str],
    timeout: int,
    codex_bin: str,
    timing_rows: list[dict[str, object]],
    timing_path: Path,
) -> bool:
    pid = row["pid"]
    output_complete, _ = validate_saved_output(out_root, config, row)
    timing_complete = has_complete_timing(timing_rows, config.label, pid)
    if output_complete and timing_complete:
        print(f"SKIP {config.label} {pid} already complete", flush=True)
        return True
    force = output_complete and not timing_complete

    command = build_runner_command(
        manifest=manifest,
        out_root=out_root,
        config=config,
        timeout=timeout,
        codex_bin=codex_bin,
        pid=pid,
        force=force,
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
    output_complete, _ = validate_saved_output(out_root, config, row)
    complete = result.returncode == 0 and output_complete
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
    csv_path = arm_dir(out_root, config) / "combined" / f"{combined_stem(config)}.csv"
    if result.returncode != 0 or not csv_path.exists():
        return False
    with csv_path.open(encoding="utf-8", newline="") as handle:
        return len(list(csv.DictReader(handle))) == 10


def main() -> int:
    args = parse_args()
    manifest = as_project_path(args.manifest).resolve()
    out_root = as_project_path(args.out_root).resolve()
    validate_out_root(out_root)
    rows = read_manifest(manifest)
    pids = [row["pid"] for row in rows]

    print(f"Manifest: {manifest}")
    print(f"Output root: {out_root}")
    for index, pid in enumerate(pids):
        print(f"{index + 1:02d} {pid}: " + ", ".join(c.label for c in rotated_configs(index)))

    if not args.run:
        print("Dry plan only. Pass --run to execute 30 classifications.")
        return 0

    ensure_metadata(out_root, manifest, args.codex_bin)
    timing_path = out_root / "benchmark_timings.csv"
    timing_rows: list[dict[str, object]] = list(read_timings(timing_path))
    failures: list[tuple[str, str]] = []

    for index, row in enumerate(rows):
        pid = row["pid"]
        for config in rotated_configs(index):
            complete = run_one(
                manifest=manifest,
                out_root=out_root,
                config=config,
                row=row,
                timeout=args.timeout,
                codex_bin=args.codex_bin,
                timing_rows=timing_rows,
                timing_path=timing_path,
            )
            if not complete:
                failures.append((config.label, pid))

    combine_results = [
        combine_arm(
            manifest=manifest,
            out_root=out_root,
            config=config,
            timeout=args.timeout,
            codex_bin=args.codex_bin,
        )
        for config in CONFIGS
    ]
    combine_ok = all(combine_results)
    missing_timings = [
        (config.label, pid)
        for config in CONFIGS
        for pid in pids
        if not has_complete_timing(timing_rows, config.label, pid)
    ]
    if missing_timings:
        print(f"Missing successful timings: {missing_timings}", file=sys.stderr)
    if failures:
        print("Failed classifications:", file=sys.stderr)
        for label, pid in failures:
            print(f"- {label}: {pid}", file=sys.stderr)
    return 0 if not failures and combine_ok and not missing_timings else 1


if __name__ == "__main__":
    raise SystemExit(main())
