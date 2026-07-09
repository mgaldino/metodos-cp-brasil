#!/usr/bin/env python3
"""Repair one processed fulltext corpus row from preserved raw XML.

This is a narrow recovery tool for cases where the raw SciELO XML is valid but
the processed ``body_text`` row was generated from the wrong portion of the XML.
It updates only one PID in the processed corpus and the matching inventory row,
then refreshes the derived credibility manifest and any active batch manifests
that already contain that PID.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


PROJECT_DIR = Path(__file__).resolve().parents[1]
GOLD_RECOVERY_PATH = PROJECT_DIR / "scripts/13_recover_fulltext_gold.py"
RAW_ARTICLES = PROJECT_DIR / "data/raw/articles_2005_2025.csv"
PROCESSED_FULLTEXT = PROJECT_DIR / "data/processed/fulltext_corpus/article_texts_corpus.csv"
FULLTEXT_INVENTORY = PROJECT_DIR / "quality_reports/fulltext_corpus_inventory.csv"
FULL_CORPUS_MANIFEST = PROJECT_DIR / "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"
BATCH_MANIFEST_DIR = PROJECT_DIR / "data/processed/credibility_prompt_v3_full_corpus/batch_manifests"
REPORT_DIR = PROJECT_DIR / "quality_reports"

VALID_SOURCE_METHODS = {
    "articlemeta_fulltexts_html",
    "citation_xml_body",
    "pdf_text_extraction",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pid", required=True, help="SciELO PID to repair.")
    parser.add_argument(
        "--xml-path",
        type=Path,
        default=None,
        help="Raw XML path. Defaults to data/raw/fulltext_corpus/xml/{pid}.xml.",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write repaired CSVs and refresh derived manifests. Without this, only print diagnostics.",
    )
    parser.add_argument(
        "--skip-manifest-refresh",
        action="store_true",
        help="Do not run script 31 or refresh active batch manifests.",
    )
    return parser.parse_args()


def rel(path: Path) -> str:
    return str(path.resolve().relative_to(PROJECT_DIR))


def load_gold_recovery() -> Any:
    spec = importlib.util.spec_from_file_location("fulltext_gold_recovery", GOLD_RECOVERY_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load {GOLD_RECOVERY_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def read_csv_rows(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        return list(reader.fieldnames or []), list(reader)


def write_csv_atomic(path: Path, fieldnames: list[str], rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=path.stem, suffix=".tmp", dir=path.parent)
    tmp_path = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(
                handle,
                fieldnames=fieldnames,
                extrasaction="ignore",
                lineterminator="\n",
            )
            writer.writeheader()
            for row in rows:
                writer.writerow({field: row.get(field, "") for field in fieldnames})
        tmp_path.replace(path)
    except BaseException:
        tmp_path.unlink(missing_ok=True)
        raise


def one_row(rows: list[dict[str, str]], pid: str, label: str) -> dict[str, str]:
    matches = [row for row in rows if row.get("pid") == pid]
    if not matches:
        raise ValueError(f"PID {pid} not found in {label}")
    if len(matches) > 1:
        raise ValueError(f"PID {pid} appears {len(matches)} times in {label}")
    return matches[0]


def r_digest_text(text: str) -> str:
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
        tmp.write(text)
        tmp_path = tmp.name
    try:
        code = (
            'args <- commandArgs(TRUE); '
            'x <- paste(readLines(args[[1]], encoding="UTF-8", warn=FALSE), collapse="\\n"); '
            'cat(digest::digest(enc2utf8(x), algo="sha256"))'
        )
        result = subprocess.run(
            ["Rscript", "--vanilla", "-e", code, tmp_path],
            check=True,
            text=True,
            capture_output=True,
        )
    finally:
        os.unlink(tmp_path)
    return result.stdout.strip()


def bool_text(value: bool) -> str:
    return "TRUE" if value else "FALSE"


def block_count(body_text: str) -> int:
    return sum(1 for block in body_text.split("\n\n") if block.strip())


def extract_repaired_result(
    pid: str,
    xml_path: Path,
    processed_row: dict[str, str],
    raw_article_row: dict[str, str],
    gold_recovery: Any,
) -> Any:
    metadata = dict(raw_article_row)
    for field in [
        "title",
        "title_en",
        "authors",
        "year",
        "issn",
        "journal_title",
        "doi",
        "document_type",
        "language",
    ]:
        if processed_row.get(field):
            metadata[field] = processed_row[field]

    source_url = processed_row.get("source_url") or "cached_xml"
    retrieved_at = processed_row.get("retrieved_at") or datetime.now(timezone.utc).isoformat()
    result, reason = gold_recovery.extract_from_xml_bytes(
        xml_path.read_bytes(),
        source_url,
        xml_path,
        retrieved_at,
        metadata,
    )
    if result is None:
        raise ValueError(f"Repaired extraction for {pid} is invalid: {reason}")
    return result


def repaired_processed_row(
    old_row: dict[str, str],
    result: Any,
    xml_path: Path,
    run_timestamp: str,
) -> dict[str, Any]:
    row = dict(old_row)
    row.update(
        {
            "body_text": result.body_text,
            "body_char_count": str(result.body_char_count),
            "body_word_count": str(result.body_word_count),
            "source_method": result.source_method,
            "source_url": old_row.get("source_url") or result.source_url,
            "input_path": rel(xml_path),
            "input_hash": result.input_hash,
            "retrieved_at": old_row.get("retrieved_at") or result.retrieved_at,
            "abstract_char_count": str(result.abstract_char_count),
            "reference_tail_ratio": f"{result.reference_tail_ratio:.6f}",
            "validation_flags": ";".join(result.flags),
            "recovery_run_timestamp": run_timestamp,
        }
    )
    return row


def repaired_inventory_row(
    old_row: dict[str, str],
    processed_row: dict[str, Any],
    result: Any,
    xml_path: Path,
    body_hash: str,
    input_hash_duplicate: bool,
    body_hash_duplicate: bool,
) -> dict[str, Any]:
    body = result.body_text
    body_blocks = block_count(body)
    body_chars = result.body_char_count
    body_words = result.body_word_count
    abstract_chars = int(old_row.get("abstract_char_count_expected") or result.abstract_char_count or 0)
    input_path_corpus_ok = rel(xml_path).startswith("data/raw/fulltext_corpus/")
    input_hash_matches_raw = processed_row["input_hash"] == result.input_hash
    retrieved_at_ok = bool(processed_row.get("retrieved_at", "").startswith(tuple(str(y) for y in range(2000, 2100))))
    source_url_ok = bool(str(processed_row.get("source_url", "")).strip())
    source_method_ok = processed_row.get("source_method") in VALID_SOURCE_METHODS
    source_provenance_ok = (
        source_method_ok
        and source_url_ok
        and input_path_corpus_ok
        and input_hash_matches_raw
        and retrieved_at_ok
    )
    body_minimum_size_ok = body_chars >= 3000 and body_words >= 600
    body_has_min_blocks = body_blocks >= 4
    body_substantially_larger_than_abstract = (
        body_chars >= max(3000, abstract_chars * 3) if abstract_chars >= 400 else body_chars >= 3000
    )
    references_not_majority = result.reference_tail_ratio <= 0.45
    first_block = body.split("\n\n", 1)[0] if body else ""
    body_not_frontmatter = not (
        gold_normalized_front_matter(first_block)
    )
    validation_status = all(
        [
            processed_row.get("body_text", "").strip() != "",
            source_provenance_ok,
            body_minimum_size_ok,
            body_has_min_blocks,
            body_substantially_larger_than_abstract,
            references_not_majority,
            body_not_frontmatter,
            not input_hash_duplicate,
            not body_hash_duplicate,
            old_row.get("logical_year_ok", "TRUE") == "TRUE",
            old_row.get("logical_document_type_ok", "TRUE") == "TRUE",
            old_row.get("logical_exclusion_ok", "TRUE") == "TRUE",
            old_row.get("no_gold_path", "TRUE") == "TRUE",
        ]
    )

    suspect_flags = []
    if not source_provenance_ok:
        suspect_flags.append("missing_or_invalid_provenance")
    if not body_minimum_size_ok:
        suspect_flags.append("too_short_for_body")
    if not body_has_min_blocks:
        suspect_flags.append("too_few_body_blocks")
    if not body_substantially_larger_than_abstract:
        suspect_flags.append("not_substantially_larger_than_abstract")
    if not references_not_majority:
        suspect_flags.append("references_majority")
    if not body_not_frontmatter:
        suspect_flags.append("starts_with_front_matter")
    if input_hash_duplicate:
        suspect_flags.append("duplicate_input_hash_across_pids")
    if body_hash_duplicate:
        suspect_flags.append("duplicate_body_hash_across_pids")

    nonblocking_flags = []
    if body_chars < 5000:
        nonblocking_flags.append("short_but_valid")
    if body_words < 1200:
        nonblocking_flags.append("low_word_count_but_valid")
    if result.reference_tail_ratio > 0.25:
        nonblocking_flags.append("large_reference_tail")
    if abstract_chars >= 400 and body_chars < abstract_chars * 4:
        nonblocking_flags.append("near_abstract_size_threshold")

    row = dict(old_row)
    row.update(
        {
            "source_method": processed_row["source_method"],
            "source_url": processed_row["source_url"],
            "input_path": processed_row["input_path"],
            "input_hash": processed_row["input_hash"],
            "input_hash_recomputed": result.input_hash,
            "body_hash": body_hash,
            "retrieved_at": processed_row["retrieved_at"],
            "body_char_count": str(body_chars),
            "body_word_count": str(body_words),
            "reference_tail_ratio": f"{result.reference_tail_ratio:.6f}".rstrip("0").rstrip(".") or "0",
            "present_in_processed": "TRUE",
            "pid_is_unique_in_processed": old_row.get("pid_is_unique_in_processed", "TRUE"),
            "body_text_nonempty": bool_text(bool(processed_row.get("body_text", "").strip())),
            "source_provenance_ok": bool_text(source_provenance_ok),
            "input_path_corpus_ok": bool_text(input_path_corpus_ok),
            "raw_input_exists": bool_text(xml_path.exists()),
            "input_hash_matches_raw": bool_text(input_hash_matches_raw),
            "input_hash_unique_across_pids": bool_text(not input_hash_duplicate),
            "body_hash_unique_across_pids": bool_text(not body_hash_duplicate),
            "body_block_count": str(body_blocks),
            "body_minimum_size_ok": bool_text(body_minimum_size_ok),
            "body_has_min_blocks": bool_text(body_has_min_blocks),
            "body_substantially_larger_than_abstract": bool_text(body_substantially_larger_than_abstract),
            "references_not_majority": bool_text(references_not_majority),
            "body_not_frontmatter": bool_text(body_not_frontmatter),
            "validation_status": "PASS" if validation_status else "FAIL",
            "suspect_flags": ";".join(suspect_flags),
            "nonblocking_flags": ";".join(nonblocking_flags),
        }
    )
    return row


def gold_normalized_front_matter(text: str) -> bool:
    key = " ".join(text.lower().split())
    starts = (
        "abstract",
        "resumo",
        "resumen",
        "resume",
        "palavras chave",
        "keywords",
        "key words",
        "palabras clave",
        "mots cle",
    )
    return any(key.startswith(item) for item in starts)


def replace_pid_row(rows: list[dict[str, Any]], pid: str, new_row: dict[str, Any]) -> None:
    replaced = 0
    for index, row in enumerate(rows):
        if row.get("pid") == pid:
            rows[index] = {**row, **new_row}
            replaced += 1
    if replaced != 1:
        raise ValueError(f"Expected to replace exactly one row for {pid}; replaced {replaced}")


def refresh_full_manifest() -> None:
    env = os.environ.copy()
    env["LANG"] = "pt_BR.UTF-8"
    env["LC_ALL"] = "pt_BR.UTF-8"
    env["LC_CTYPE"] = "pt_BR.UTF-8"
    subprocess.run(
        ["Rscript", "--vanilla", "scripts/31_prepare_credibility_prompt_v3_full_corpus_manifest.R"],
        cwd=PROJECT_DIR,
        env=env,
        check=True,
    )


def refresh_batch_manifests(pid: str) -> list[str]:
    manifest_fields, manifest_rows = read_csv_rows(FULL_CORPUS_MANIFEST)
    repaired_manifest_row = one_row(manifest_rows, pid, rel(FULL_CORPUS_MANIFEST))
    refreshed = []
    for path in sorted(BATCH_MANIFEST_DIR.glob("active_batch_*.csv")):
        fields, rows = read_csv_rows(path)
        if not any(row.get("pid") == pid for row in rows):
            continue
        if fields != manifest_fields:
            raise ValueError(f"Field mismatch between {path} and full corpus manifest")
        replace_pid_row(rows, pid, repaired_manifest_row)
        write_csv_atomic(path, fields, rows)
        refreshed.append(rel(path))
    return refreshed


def write_repair_report(
    pid: str,
    xml_path: Path,
    old_processed: dict[str, str],
    new_processed: dict[str, Any],
    old_inventory: dict[str, str],
    new_inventory: dict[str, Any],
    refreshed_batches: list[str],
    applied: bool,
) -> Path:
    report_path = REPORT_DIR / f"fulltext_corpus_single_pid_repair_{pid}.md"
    input_text_hash = hashlib.sha256(new_processed["body_text"].encode("utf-8")).hexdigest()
    lines = [
        f"# Fulltext corpus single-PID repair: `{pid}`",
        "",
        f"Generated at: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}",
        f"Applied: {applied}",
        "",
        "## Source",
        "",
        f"- Raw XML: `{rel(xml_path)}`",
        f"- Raw XML SHA-256: `{new_processed['input_hash']}`",
        f"- Source method: `{new_processed['source_method']}`",
        f"- Source URL: `{new_processed['source_url']}`",
        "",
        "## Text change",
        "",
        f"- Previous body chars: {old_processed.get('body_char_count')}",
        f"- Previous body words: {old_processed.get('body_word_count')}",
        f"- New body chars: {new_processed.get('body_char_count')}",
        f"- New body words: {new_processed.get('body_word_count')}",
        f"- Previous inventory status: `{old_inventory.get('validation_status')}`",
        f"- New inventory status: `{new_inventory.get('validation_status')}`",
        f"- New input text SHA-256: `{input_text_hash}`",
        f"- New inventory body hash: `{new_inventory.get('body_hash')}`",
        "",
        "## Start of repaired body",
        "",
        "```text",
        new_processed["body_text"][:1200],
        "```",
        "",
        "## Refreshed active batch manifests",
        "",
        *(f"- `{item}`" for item in refreshed_batches),
    ]
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return report_path


def main() -> int:
    args = parse_args()
    pid = args.pid
    xml_path = args.xml_path or PROJECT_DIR / f"data/raw/fulltext_corpus/xml/{pid}.xml"
    if not xml_path.is_absolute():
        xml_path = PROJECT_DIR / xml_path
    if not xml_path.exists():
        raise FileNotFoundError(xml_path)

    csv.field_size_limit(sys.maxsize)
    run_timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    gold_recovery = load_gold_recovery()

    processed_fields, processed_rows = read_csv_rows(PROCESSED_FULLTEXT)
    inventory_fields, inventory_rows = read_csv_rows(FULLTEXT_INVENTORY)
    _, raw_article_rows = read_csv_rows(RAW_ARTICLES)

    old_processed = one_row(processed_rows, pid, rel(PROCESSED_FULLTEXT))
    old_inventory = one_row(inventory_rows, pid, rel(FULLTEXT_INVENTORY))
    raw_article = one_row(raw_article_rows, pid, rel(RAW_ARTICLES))

    result = extract_repaired_result(pid, xml_path, old_processed, raw_article, gold_recovery)
    new_processed = repaired_processed_row(old_processed, result, xml_path, run_timestamp)
    body_hash = r_digest_text(new_processed["body_text"])

    input_hash_duplicate = any(
        row.get("pid") != pid and row.get("input_hash") == new_processed["input_hash"]
        for row in inventory_rows
    )
    body_hash_duplicate = any(
        row.get("pid") != pid and row.get("body_hash") == body_hash
        for row in inventory_rows
    )
    new_inventory = repaired_inventory_row(
        old_inventory,
        new_processed,
        result,
        xml_path,
        body_hash,
        input_hash_duplicate,
        body_hash_duplicate,
    )

    diagnostics = {
        "pid": pid,
        "xml_path": rel(xml_path),
        "apply": args.apply,
        "old_body_char_count": old_processed.get("body_char_count"),
        "new_body_char_count": new_processed["body_char_count"],
        "old_body_word_count": old_processed.get("body_word_count"),
        "new_body_word_count": new_processed["body_word_count"],
        "new_validation_status": new_inventory["validation_status"],
        "new_input_text_hash": hashlib.sha256(new_processed["body_text"].encode("utf-8")).hexdigest(),
        "new_body_hash": body_hash,
        "body_start": new_processed["body_text"][:500],
    }

    if not args.apply:
        print(json.dumps(diagnostics, ensure_ascii=False, indent=2))
        return 0

    if new_inventory["validation_status"] != "PASS":
        raise ValueError(f"Refusing to apply repair because inventory status is {new_inventory['validation_status']}")

    replace_pid_row(processed_rows, pid, new_processed)
    replace_pid_row(inventory_rows, pid, new_inventory)
    write_csv_atomic(PROCESSED_FULLTEXT, processed_fields, processed_rows)
    write_csv_atomic(FULLTEXT_INVENTORY, inventory_fields, inventory_rows)

    refreshed_batches: list[str] = []
    if not args.skip_manifest_refresh:
        refresh_full_manifest()
        refreshed_batches = refresh_batch_manifests(pid)

    report_path = write_repair_report(
        pid,
        xml_path,
        old_processed,
        new_processed,
        old_inventory,
        new_inventory,
        refreshed_batches,
        applied=True,
    )
    diagnostics["repair_report"] = rel(report_path)
    diagnostics["refreshed_batch_manifests"] = refreshed_batches
    print(json.dumps(diagnostics, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
