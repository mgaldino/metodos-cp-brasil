#!/usr/bin/env python3
"""Consolidate completed batch snapshots into the canonical CSV and JSONL."""

from __future__ import annotations

import argparse
import csv
import json
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[1]
FULL_MANIFEST = PROJECT_DIR / "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"
COMBINED_DIR = PROJECT_DIR / "data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined"
CANONICAL_CSV = COMBINED_DIR / "classifications_integral_reading.csv"
CANONICAL_JSONL = COMBINED_DIR / "classifications_integral_reading.jsonl"
CANONICAL_REPORT = COMBINED_DIR / "integral_reading_batch_report.md"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-dir", type=Path, required=True)
    parser.add_argument("--batch-label", action="append", required=True)
    parser.add_argument("--run", action="store_true", help="Replace canonical outputs after validation.")
    return parser.parse_args(argv)


def read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise ValueError(f"CSV without header: {path}")
        return reader.fieldnames, list(reader)


def read_jsonl(path: Path) -> list[dict[str, object]]:
    records: list[dict[str, object]] = []
    with path.open(encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            if not line.strip():
                continue
            record = json.loads(line)
            if not isinstance(record, dict):
                raise ValueError(f"JSONL record is not an object: {path}:{line_number}")
            records.append(record)
    return records


def index_unique(records: list[dict[str, object]], source: Path) -> dict[str, dict[str, object]]:
    indexed: dict[str, dict[str, object]] = {}
    for record in records:
        pid = str(record.get("pid", ""))
        if not pid:
            raise ValueError(f"Record without PID: {source}")
        if pid in indexed:
            raise ValueError(f"Duplicate PID {pid}: {source}")
        indexed[pid] = record
    return indexed


def atomic_write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, object]]) -> None:
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", newline="", dir=path.parent, delete=False) as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
        temp_path = Path(handle.name)
    os.replace(temp_path, path)


def atomic_write_jsonl(path: Path, rows: list[dict[str, object]]) -> None:
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
        temp_path = Path(handle.name)
    os.replace(temp_path, path)


def atomic_write_text(path: Path, text: str) -> None:
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as handle:
        handle.write(text)
        temp_path = Path(handle.name)
    os.replace(temp_path, path)


def consolidate(args: argparse.Namespace) -> dict[str, object]:
    base_dir = args.base_dir if args.base_dir.is_absolute() else PROJECT_DIR / args.base_dir
    sources = [(base_dir / "classifications_integral_reading.csv", base_dir / "classifications_integral_reading.jsonl")]
    sources.extend((COMBINED_DIR / f"{label}.csv", COMBINED_DIR / f"{label}.jsonl") for label in args.batch_label)

    manifest_fields, manifest_rows = read_csv(FULL_MANIFEST)
    if "pid" not in manifest_fields or "input_text_hash" not in manifest_fields:
        raise ValueError("Full manifest lacks pid or input_text_hash")
    manifest = {row["pid"]: row for row in manifest_rows}
    manifest_order = {row["pid"]: index for index, row in enumerate(manifest_rows)}

    canonical_fields: list[str] | None = None
    csv_records: dict[str, dict[str, object]] = {}
    json_records: dict[str, dict[str, object]] = {}
    source_counts: list[tuple[str, int]] = []

    for csv_path, jsonl_path in sources:
        fields, rows = read_csv(csv_path)
        json_rows = read_jsonl(jsonl_path)
        csv_index = index_unique(rows, csv_path)
        json_index = index_unique(json_rows, jsonl_path)
        if set(csv_index) != set(json_index):
            raise ValueError(f"CSV/JSONL PID mismatch for {csv_path.stem}")
        if canonical_fields is None:
            canonical_fields = fields
        elif fields != canonical_fields:
            raise ValueError(f"CSV schema mismatch: {csv_path}")
        overlap = set(csv_records).intersection(csv_index)
        if overlap:
            raise ValueError(f"PIDs overlap across sources: {sorted(overlap)[:5]}")
        csv_records.update(csv_index)
        json_records.update(json_index)
        source_counts.append((csv_path.stem, len(rows)))

    assert canonical_fields is not None
    unknown = set(csv_records).difference(manifest)
    if unknown:
        raise ValueError(f"PIDs outside full manifest: {sorted(unknown)[:5]}")
    hash_mismatch = [
        pid for pid, row in csv_records.items()
        if row.get("input_text_hash") != manifest[pid]["input_text_hash"]
    ]
    if hash_mismatch:
        raise ValueError(f"input_text_hash mismatch: {hash_mismatch[:5]}")

    ordered_pids = sorted(csv_records, key=manifest_order.__getitem__)
    csv_rows = [csv_records[pid] for pid in ordered_pids]
    json_rows = [json_records[pid] for pid in ordered_pids]
    summary = {
        "manifest_n": len(manifest_rows),
        "complete_n": len(ordered_pids),
        "missing_n": len(manifest_rows) - len(ordered_pids),
        "sources": source_counts,
        "run": bool(args.run),
    }

    if args.run:
        atomic_write_csv(CANONICAL_CSV, canonical_fields, csv_rows)
        atomic_write_jsonl(CANONICAL_JSONL, json_rows)
        source_lines = "\n".join(f"- `{name}`: {count}" for name, count in source_counts)
        report = (
            "# Integral reading canonical consolidation\n\n"
            f"Generated at: {datetime.now(timezone.utc).isoformat()}\n\n"
            "## Counts\n\n"
            f"- Manifest articles: {len(manifest_rows)}\n"
            f"- Complete classifications: {len(ordered_pids)}\n"
            f"- Missing classifications: {len(manifest_rows) - len(ordered_pids)}\n\n"
            "## Frozen sources\n\n"
            f"{source_lines}\n\n"
            "The canonical snapshot includes only completed batch CSV/JSONL pairs listed above. "
            "In-progress batch artifacts are excluded.\n"
        )
        atomic_write_text(CANONICAL_REPORT, report)

    return summary


def main() -> int:
    args = parse_args()
    print(json.dumps(consolidate(args), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
