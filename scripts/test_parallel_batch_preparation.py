from __future__ import annotations

import csv
import importlib.util
import json
import sys
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[1]
PREP_PATH = PROJECT_DIR / "scripts/40_prepare_credibility_integral_parallel_batches.py"
RUNNER_PATH = PROJECT_DIR / "scripts/41_run_credibility_integral_parallel_batches.py"


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def write_rows(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def read_pids(path: Path) -> list[str]:
    with path.open(encoding="utf-8", newline="") as f:
        return [row["pid"] for row in csv.DictReader(f)]


def manifest_rows(n: int) -> list[dict[str, str]]:
    return [
        {
            "eligible_order": str(i),
            "pid": f"S{i:03d}",
            "title": f"Title {i}",
            "journal_title": "Dados" if i <= 4 else "Lua Nova",
            "input_text_hash": f"hash-{i}",
        }
        for i in range(1, n + 1)
    ]


def mark_complete(out_dir: Path, pid: str) -> None:
    (out_dir / "reading_logs").mkdir(parents=True, exist_ok=True)
    (out_dir / "classifications").mkdir(parents=True, exist_ok=True)
    (out_dir / "reading_logs" / f"{pid}.json").write_text("{}", encoding="utf-8")
    (out_dir / "classifications" / f"{pid}.json").write_text("{}", encoding="utf-8")


def test_prepare_reuses_incomplete_batch_and_creates_disjoint_next_batch(tmp_path, monkeypatch):
    prep = load_module(PREP_PATH, "parallel_prep")
    manifest = tmp_path / "full_corpus_manifest.csv"
    batch_dir = tmp_path / "batch_manifests"
    out_dir = tmp_path / "full_corpus"
    quality_dir = tmp_path / "quality_reports"
    rows = manifest_rows(6)
    write_rows(manifest, rows)
    write_rows(batch_dir / "active_batch_001.csv", rows[:2])
    mark_complete(out_dir, "S001")
    (out_dir / "failed").mkdir(parents=True, exist_ok=True)
    (out_dir / "failed" / "S002.txt").write_text("previous failure\n", encoding="utf-8")

    monkeypatch.setattr(
        sys,
        "argv",
        [
            "prep",
            "--manifest",
            str(manifest),
            "--out-dir",
            str(out_dir),
            "--batch-dir",
            str(batch_dir),
            "--quality-dir",
            str(quality_dir),
            "--workers",
            "2",
            "--limit",
            "2",
            "--model-reasoning-effort",
            "high",
        ],
    )

    assert prep.main() == 0

    assert read_pids(batch_dir / "active_batch_001.csv") == ["S001", "S002"]
    assert read_pids(batch_dir / "active_batch_002.csv") == ["S003", "S004"]
    plan = json.loads((quality_dir / "credibility_prompt_v3_parallel_batches_plan.json").read_text(encoding="utf-8"))
    assert plan["labels"] == ["active_batch_001", "active_batch_002"]
    assert plan["model_reasoning_effort"] == "high"
    assert all("--model-reasoning-effort" in batch["command"] for batch in plan["batches"])
    assert "xhigh" not in (quality_dir / "credibility_prompt_v3_parallel_batches_plan.md").read_text(
        encoding="utf-8"
    )


def test_runner_prints_commands_without_run(tmp_path, monkeypatch, capsys):
    runner = load_module(RUNNER_PATH, "parallel_runner")
    batch_dir = tmp_path / "batch_manifests"
    out_dir = tmp_path / "full_corpus"
    manifest = tmp_path / "full_corpus_manifest.csv"
    rows = manifest_rows(2)
    write_rows(manifest, rows)
    write_rows(batch_dir / "active_batch_001.csv", rows[:1])

    monkeypatch.setattr(
        sys,
        "argv",
        [
            "runner",
            "--labels",
            "active_batch_001",
            "--manifest",
            str(manifest),
            "--out-dir",
            str(out_dir),
            "--batch-dir",
            str(batch_dir),
            "--model-reasoning-effort",
            "high",
        ],
    )

    assert runner.main() == 0
    output = capsys.readouterr().out
    assert "add --run to execute" in output
    assert "--model-reasoning-effort high" in output
    assert "--combined-stem active_batch_001" in output
