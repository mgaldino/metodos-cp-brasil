"""
build_benchmark.py

Process journal PDFs and compute aggregate readability/style benchmark
statistics for Comparative Politics (CP) and International Relations (IR).

Usage:
    python3 build_benchmark.py --field cp|ir|both

Output:
    ../data/processed/benchmark_cp.csv
    ../data/processed/benchmark_ir.csv
    ../data/processed/benchmark_cp_stats.json
    ../data/processed/benchmark_ir_stats.json

Requires: pip install textstat pdfplumber
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path
from typing import Any

import statistics

# ---------------------------------------------------------------------------
# Imports from readability_audit (same directory)
# ---------------------------------------------------------------------------
from readability_audit import parse_pdf, aggregate_metrics

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SCRIPT_DIR = Path(__file__).resolve().parent
BASE_PDF_DIR = SCRIPT_DIR / ".." / "data" / "raw" / "papers_internacionais"
OUTPUT_DIR = SCRIPT_DIR / ".." / "data" / "processed"

CP_JOURNALS: list[str] = ["APSR", "AJPS", "JOP"]
IR_JOURNALS: list[str] = ["IO", "ISQ", "JCR", "RIO"]

METRICS: list[str] = [
    "flesch_re",
    "fk_grade",
    "fog",
    "smog",
    "passive_pct",
    "nominal_pct",
    "hedging_pct",
]

# Map from readability_audit key names to our output key names
_KEY_MAP: dict[str, str] = {
    "flesch_re": "flesch_re",
    "fk_grade": "fk_grade",
    "fog": "fog",
    "smog": "smog",
    "passive_voice_pct": "passive_pct",
    "nominalization_pct": "nominal_pct",
    "hedging_pct": "hedging_pct",
}

CSV_COLUMNS: list[str] = ["filename", "journal"] + METRICS + ["word_count"]


# ---------------------------------------------------------------------------
# Core functions
# ---------------------------------------------------------------------------


def _remap_metrics(raw: dict[str, Any]) -> dict[str, Any]:
    """Remap keys from readability_audit output to our schema."""
    result: dict[str, Any] = {}
    for src_key, dst_key in _KEY_MAP.items():
        result[dst_key] = raw.get(src_key, 0.0)
    result["word_count"] = raw.get("word_count", 0)
    return result


def process_journal_folder(journal: str) -> list[dict]:
    """Process all PDFs in a journal folder and return per-paper metric rows.

    Each row is a dict with keys: filename, journal, + all metrics + word_count.
    PDFs that fail extraction are skipped with a warning.
    """
    folder = BASE_PDF_DIR / journal
    if not folder.is_dir():
        print(f"WARNING: folder not found: {folder}", file=sys.stderr)
        return []

    pdfs = sorted(folder.glob("*.pdf"))
    if not pdfs:
        print(f"WARNING: no PDFs in {folder}", file=sys.stderr)
        return []

    rows: list[dict] = []
    for pdf_path in pdfs:
        try:
            sections = parse_pdf(pdf_path)
            raw_metrics = aggregate_metrics(sections)
            mapped = _remap_metrics(raw_metrics)
            row = {"filename": pdf_path.name, "journal": journal, **mapped}
            rows.append(row)
            print(f"  [{journal}] {pdf_path.name} ... OK")
        except Exception as exc:
            print(
                f"  [{journal}] {pdf_path.name} ... ERROR: {exc}",
                file=sys.stderr,
            )
            continue

    return rows


def _percentile(sorted_vals: list[float], pct: float) -> float:
    """Compute percentile from a sorted list."""
    n = len(sorted_vals)
    idx = pct / 100 * (n - 1)
    lower = int(idx)
    upper = min(lower + 1, n - 1)
    frac = idx - lower
    return sorted_vals[lower] + frac * (sorted_vals[upper] - sorted_vals[lower])


def compute_benchmark_stats(rows: list[dict]) -> dict:
    """Compute summary statistics per metric from a list of paper rows.

    Returns a dict keyed by metric name, each containing:
        mean, std, p10, p25, p50, p75, p90, n

    If rows is empty, returns zeros for all statistics with n=0.
    """
    stats: dict[str, dict[str, float]] = {}

    for metric in METRICS:
        if not rows:
            stats[metric] = {
                "mean": 0.0,
                "std": 0.0,
                "p10": 0.0,
                "p25": 0.0,
                "p50": 0.0,
                "p75": 0.0,
                "p90": 0.0,
                "n": 0,
            }
            continue

        values = [float(r[metric]) for r in rows]
        sorted_vals = sorted(values)
        stats[metric] = {
            "mean": round(statistics.mean(values), 2),
            "std": round(statistics.stdev(values) if len(values) > 1 else 0.0, 2),
            "p10": round(_percentile(sorted_vals, 10), 2),
            "p25": round(_percentile(sorted_vals, 25), 2),
            "p50": round(_percentile(sorted_vals, 50), 2),
            "p75": round(_percentile(sorted_vals, 75), 2),
            "p90": round(_percentile(sorted_vals, 90), 2),
            "n": len(values),
        }

    return stats


def save_csv(rows: list[dict], path: str | Path) -> None:
    """Save per-paper rows to a CSV file."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)

    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Saved CSV: {path} ({len(rows)} rows)")


def _save_json(data: dict, path: str | Path) -> None:
    """Save stats dict to a JSON file."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)

    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"Saved JSON: {path}")


def build(field: str = "both") -> None:
    """Main function: process journals and save benchmark files.

    Args:
        field: "cp", "ir", or "both"
    """
    field = field.lower()

    if field in ("cp", "both"):
        print("=" * 60)
        print("Processing CP journals...")
        print("=" * 60)
        cp_rows: list[dict] = []
        for journal in CP_JOURNALS:
            print(f"\n--- {journal} ---")
            cp_rows.extend(process_journal_folder(journal))

        csv_path = OUTPUT_DIR / "benchmark_cp.csv"
        json_path = OUTPUT_DIR / "benchmark_cp_stats.json"
        save_csv(cp_rows, csv_path)

        stats = compute_benchmark_stats(cp_rows)
        _save_json(stats, json_path)
        print(f"\nCP benchmark: {len(cp_rows)} papers processed.")

    if field in ("ir", "both"):
        print("=" * 60)
        print("Processing IR journals...")
        print("=" * 60)
        ir_rows: list[dict] = []
        for journal in IR_JOURNALS:
            print(f"\n--- {journal} ---")
            ir_rows.extend(process_journal_folder(journal))

        csv_path = OUTPUT_DIR / "benchmark_ir.csv"
        json_path = OUTPUT_DIR / "benchmark_ir_stats.json"
        save_csv(ir_rows, csv_path)

        stats = compute_benchmark_stats(ir_rows)
        _save_json(stats, json_path)
        print(f"\nIR benchmark: {len(ir_rows)} papers processed.")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Build readability benchmark from journal PDFs.",
    )
    parser.add_argument(
        "--field",
        choices=["cp", "ir", "both"],
        default="both",
        help="Which field to process (default: both)",
    )
    args = parser.parse_args(argv)
    build(args.field)


if __name__ == "__main__":
    main()
