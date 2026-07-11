#!/usr/bin/env python3
"""Run the isolated Luna xhigh extension of the 10-case model benchmark."""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[1]
BASE_SCRIPT = PROJECT_DIR / "scripts/38_run_credibility_model_benchmark.py"
RUNNER = PROJECT_DIR / "scripts/25_run_credibility_prompt_v3_integral_codex_batch.py"
MANIFEST = PROJECT_DIR / "data/processed/credibility_prompt_v3_full_corpus/batch_manifests/ab_gpt56_models_10.csv"
OUT_ROOT = PROJECT_DIR / "data/processed/credibility_prompt_v3_integral_reading/full_corpus_ab/gpt56_model_benchmark_10_luna_xhigh_v2"
LABEL = "luna_xhigh"
MODEL = "gpt-5.6-luna"
EFFORT = "xhigh"

spec = importlib.util.spec_from_file_location("benchmark_base", BASE_SCRIPT)
if spec is None or spec.loader is None:
    raise ImportError(f"Could not load {BASE_SCRIPT}")
base = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = base
spec.loader.exec_module(base)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_rows() -> list[dict[str, str]]:
    with MANIFEST.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    if len(rows) != 10 or len({row["pid"] for row in rows}) != 10:
        raise ValueError("Benchmark manifest must contain exactly 10 unique PIDs.")
    return rows


def out_dir() -> Path:
    path = OUT_ROOT / LABEL
    path.mkdir(parents=True, exist_ok=True)
    return path


def command(pid: str | None = None, *, combine_only: bool = False) -> list[str]:
    args = [
        sys.executable,
        str(RUNNER),
        "--manifest", str(MANIFEST),
        "--out-dir", str(out_dir()),
        "--timeout", "2400",
        "--codex-bin", "codex",
        "--model", MODEL,
        "--model-reasoning-effort", EFFORT,
        "--service-tier", "default",
        "--ephemeral",
        "--combined-stem",
        "classifications_integral_reading_luna_xhigh_10" if pid is None else f"classifications_integral_reading_luna_xhigh_10_{pid}",
    ]
    if pid is not None:
        args.extend(["--pid", pid])
    if combine_only:
        args.append("--combine-only")
    return args


def ensure_metadata(rows: list[dict[str, str]]) -> None:
    path = OUT_ROOT / "benchmark_metadata.json"
    contract = {
        "manifest": str(MANIFEST),
        "configuration": {"label": LABEL, "model": MODEL, "effort": EFFORT},
        "service_tier": "default",
        "manifest_sha256": sha256(MANIFEST),
        "runner_sha256": sha256(RUNNER),
        "base_benchmark_script_sha256": sha256(BASE_SCRIPT),
        "pids": [row["pid"] for row in rows],
        "codex_version": subprocess.run(
            ["codex", "--version"], capture_output=True, text=True, check=True
        ).stdout.strip(),
    }
    if path.exists():
        existing = json.loads(path.read_text(encoding="utf-8"))
        if existing.get("contract") != contract:
            raise RuntimeError("Existing Luna metadata does not match the current contract.")
        return
    OUT_ROOT.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps({"created_at_utc": datetime.now(timezone.utc).isoformat(), "contract": contract}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    rows = read_rows()
    ensure_metadata(rows)
    timing_path = OUT_ROOT / "benchmark_timings.csv"
    timing_rows = []
    if timing_path.exists():
        with timing_path.open(encoding="utf-8", newline="") as handle:
            timing_rows = list(csv.DictReader(handle))

    for row in rows:
        pid = row["pid"]
        prior_success = any(
            item.get("pid") == pid and item.get("status") == "complete" and item.get("return_code") == "0"
            for item in timing_rows
        )
        if prior_success:
            print(f"SKIP {LABEL} {pid}", flush=True)
            continue
        attempt = sum(1 for item in timing_rows if item.get("pid") == pid) + 1
        started = datetime.now(timezone.utc)
        clock = time.perf_counter()
        result = subprocess.run(command(pid), cwd=PROJECT_DIR, capture_output=True, text=True, check=False)
        elapsed = time.perf_counter() - clock
        finished = datetime.now(timezone.utc)
        log_dir = OUT_ROOT / "benchmark_run_logs" / LABEL
        log_dir.mkdir(parents=True, exist_ok=True)
        (log_dir / f"{pid}.attempt_{attempt}.stdout.log").write_text(result.stdout, encoding="utf-8")
        (log_dir / f"{pid}.attempt_{attempt}.stderr.log").write_text(result.stderr, encoding="utf-8")
        complete, _ = base.validate_saved_output(OUT_ROOT, type("Config", (), {"label": LABEL})(), row)
        status = "complete" if result.returncode == 0 and complete else "failed"
        timing_rows.append({
            "label": LABEL, "model": MODEL, "effort": EFFORT, "pid": pid,
            "attempt": attempt, "started_at_utc": started.isoformat(),
            "finished_at_utc": finished.isoformat(), "elapsed_seconds": f"{elapsed:.6f}",
            "return_code": result.returncode, "status": status,
        })
        with timing_path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=base.TIMING_FIELDS)
            writer.writeheader()
            writer.writerows(timing_rows)
        print(f"{status.upper()} {LABEL} {pid} elapsed={elapsed:.1f}s", flush=True)

    result = subprocess.run(command(combine_only=True), cwd=PROJECT_DIR, check=False)
    csv_path = out_dir() / "combined/classifications_integral_reading_luna_xhigh_10.csv"
    complete_count = 0
    if csv_path.exists():
        with csv_path.open(encoding="utf-8", newline="") as handle:
            complete_count = len(list(csv.DictReader(handle)))
    print(json.dumps({"label": LABEL, "complete": complete_count, "expected": 10, "combine_return_code": result.returncode}))
    return 0 if complete_count == 10 and result.returncode == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
