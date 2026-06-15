#!/usr/bin/env python3
"""
25_run_credibility_prompt_v3_integral_codex_batch.py

Run one Codex exec process per article for credibility_prompt_v3 classification
with mandatory full-body reading logs. This is intentionally not a rule-based
classifier. Scripts only assemble prompts, call Codex, validate outputs, and
combine accepted JSON classifications.

Default target is the 10-paper test manifest. Use --manifest and --out-dir to
scale to the 175-paper pilot after the test is accepted.
"""

from __future__ import annotations

import argparse
import csv
import html
import json
import re
import subprocess
import sys
import unicodedata
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


PROJECT_DIR = Path(__file__).resolve().parents[1]

DEFAULT_MANIFEST = PROJECT_DIR / "data/processed/credibility_prompt_v3_test/manifest_10_papers.csv"
DEFAULT_OUT_DIR = PROJECT_DIR / "data/processed/credibility_prompt_v3_integral_reading/test_10"
PROMPT_TEMPLATE = (
    PROJECT_DIR
    / "data/processed/credibility_prompt_v3_integral_reading/prompts/classifier_prompt_v3_integral_reading.md"
)
OUTPUT_SCHEMA = (
    PROJECT_DIR
    / "data/processed/credibility_prompt_v3_integral_reading/prompts/integral_reading_output_schema.json"
)
CLASSIFIER_PROMPT_V3 = PROJECT_DIR / "data/processed/credibility_prompt_v3_test/prompts/classifier_prompt_v3.md"

CLASSIFICATION_FIELDS = [
    "pid",
    "title",
    "journal_title",
    "input_text_hash",
    "is_empirical_paper",
    "empirical_evidence_type",
    "is_empirical_quant_paper_torreblanca",
    "is_empirical_qual_paper",
    "quantitative_analysis_type",
    "quantitative_analysis_evidence_quote",
    "has_statistical_inference",
    "statistical_inference_quote",
    "qualitative_analysis_goal",
    "qualitative_goal_clarity",
    "qualitative_goal_quote",
    "causal_or_explanatory_claim_present",
    "causal_or_explanatory_claim_quote",
    "credibility_revolution_screen_applicable",
    "credibility_revolution_screen_reason",
    "credibility_revolution_method_present",
    "credibility_revolution_method_type",
    "causal_design_quote",
    "main_variables_or_relationship",
    "sample_or_data_source",
    "tough_call",
    "tough_call_reason",
    "brief_justification",
]

TOP_LEVEL_FIELDS = [
    "pid",
    "title",
    "journal_title",
    "input_text_hash",
    "status",
    "full_body_read",
    "incomplete_reason",
    "section_reading_log",
    "general_summary",
    "decision_audit",
    "classification",
]

ENUMS = {
    "empirical_evidence_type": {
        "none",
        "quantitative_only",
        "qualitative_only",
        "mixed_empirical",
        "unclear",
    },
    "quantitative_analysis_type": {
        "none",
        "descriptive_statistics_only",
        "bivariate_tests_or_correlations_only",
        "statistical_modeling",
        "unclear",
    },
    "qualitative_analysis_goal": {
        None,
        "descriptive_reconstruction",
        "explanatory_why",
        "interpretive_meaning",
        "mixed_descriptive_explanatory",
        "unclear",
    },
    "qualitative_goal_clarity": {
        None,
        "clear",
        "ambiguous_tough_call",
        "internally_inconsistent",
    },
    "credibility_revolution_screen_reason": {
        "not_empirical",
        "qualitative_only",
        "descriptive_quantitative_only",
        "bivariate_or_correlation_screen",
        "statistical_modeling_screen",
        "explicit_causal_design_screen",
        "causal_claim_with_quantitative_analysis_screen",
        "unclear",
    },
}

METHOD_TYPES = {
    "experiment_field",
    "experiment_survey",
    "experiment_lab",
    "experiment_list",
    "difference_in_differences",
    "event_study",
    "instrumental_variables",
    "regression_discontinuity",
    "regression_kink",
    "synthetic_control",
    "synthetic_difference_in_differences",
    "matching_or_weighting",
    "dag_or_formal_causal_graph",
    "doubly_robust",
    "causal_trees_or_forests",
    "causal_discovery",
    "other_modern_causal_method",
    "fixed_effects_causal_panel_claim",
    "observational_regression_with_causal_claim_no_design",
    "none_detected",
}

DIAGNOSTIC_NOT_DESIGN_METHOD_TYPES = {
    "fixed_effects_causal_panel_claim",
    "observational_regression_with_causal_claim_no_design",
    "none_detected",
}

BOOLEAN_CLASSIFICATION_FIELDS = {
    "is_empirical_paper",
    "is_empirical_quant_paper_torreblanca",
    "is_empirical_qual_paper",
    "causal_or_explanatory_claim_present",
    "credibility_revolution_screen_applicable",
    "tough_call",
}

NULLABLE_BOOLEAN_CLASSIFICATION_FIELDS = {
    "has_statistical_inference",
    "credibility_revolution_method_present",
}


def read_csv_dict(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def ensure_dirs(out_dir: Path) -> dict[str, Path]:
    dirs = {
        "prompts": out_dir / "prompts",
        "raw": out_dir / "raw_responses",
        "logs": out_dir / "run_logs",
        "reading": out_dir / "reading_logs",
        "classifications": out_dir / "classifications",
        "failed": out_dir / "failed",
        "combined": out_dir / "combined",
    }
    for directory in dirs.values():
        directory.mkdir(parents=True, exist_ok=True)
    return dirs


def load_manifest(path: Path, pids: set[str] | None = None) -> list[dict[str, str]]:
    rows = read_csv_dict(path)
    if pids is not None:
        rows = [row for row in rows if row["pid"] in pids]
    for row in rows:
        if not row.get("task_packet_file"):
            raise ValueError(f"Manifest row lacks task_packet_file: {row.get('pid')}")
        packet = PROJECT_DIR / row["task_packet_file"]
        if not packet.exists():
            raise FileNotFoundError(f"Task packet not found for {row['pid']}: {packet}")
    return rows


def select_manifest_window(
    rows: list[dict[str, str]],
    offset: int = 0,
    limit: int | None = None,
) -> list[dict[str, str]]:
    if offset < 0:
        raise ValueError("--offset must be non-negative")
    if limit is not None and limit < 0:
        raise ValueError("--limit must be non-negative")
    selected = rows[offset:]
    if limit is not None:
        selected = selected[:limit]
    return selected


def render_prompt(row: dict[str, str]) -> str:
    template = PROMPT_TEMPLATE.read_text(encoding="utf-8")
    classifier = CLASSIFIER_PROMPT_V3.read_text(encoding="utf-8")
    packet = (PROJECT_DIR / row["task_packet_file"]).read_text(encoding="utf-8")
    prompt = template.replace("{{CLASSIFIER_PROMPT_V3}}", classifier)
    prompt = prompt.replace("{{TASK_PACKET}}", packet)
    return prompt


def extract_json_object(text: str) -> dict[str, Any]:
    stripped = text.strip()
    if stripped.startswith("```"):
        stripped = re.sub(r"^```(?:json)?\s*", "", stripped)
        stripped = re.sub(r"\s*```$", "", stripped)
    try:
        return json.loads(stripped)
    except json.JSONDecodeError:
        start = stripped.find("{")
        end = stripped.rfind("}")
        if start >= 0 and end > start:
            return json.loads(stripped[start : end + 1])
        raise


def normalize_metadata_text(value: Any) -> str:
    text = "" if value is None else str(value)
    text = html.unescape(text)
    text = unicodedata.normalize("NFC", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def metadata_field_matches(field: str, expected: str, got: Any) -> bool:
    if field in {"title", "journal_title"}:
        return normalize_metadata_text(expected) == normalize_metadata_text(got)
    return got == expected


def validate_record(record: dict[str, Any], row: dict[str, str]) -> list[str]:
    errors: list[str] = []

    for field in TOP_LEVEL_FIELDS:
        if field not in record:
            errors.append(f"missing top-level field: {field}")

    if errors:
        return errors

    for field in ["pid", "title", "journal_title", "input_text_hash"]:
        expected = row.get(field, "")
        got = record.get(field)
        if expected and not metadata_field_matches(field, expected, got):
            errors.append(f"top-level {field} mismatch: expected {expected!r}, got {got!r}")

    if record.get("status") not in {"complete", "incomplete"}:
        errors.append("status must be complete or incomplete")

    if record.get("status") == "complete":
        if record.get("full_body_read") is not True:
            errors.append("complete record must have full_body_read == true")
        if record.get("classification") is None:
            errors.append("complete record must have classification object")
    elif not isinstance(record.get("full_body_read"), bool):
        errors.append("full_body_read must be boolean")

    if record.get("status") == "incomplete":
        if not record.get("incomplete_reason"):
            errors.append("incomplete record must explain incomplete_reason")
        if record.get("classification") is not None:
            errors.append("incomplete record must have classification == null")

    section_log = record.get("section_reading_log")
    if not isinstance(section_log, list) or not section_log:
        errors.append("section_reading_log must be a non-empty array")
    else:
        for i, section in enumerate(section_log, start=1):
            if not isinstance(section, dict):
                errors.append(f"section_reading_log[{i}] is not an object")
                continue
            for field in [
                "section_title",
                "section_position",
                "section_summary",
                "methods_or_data_mentions",
                "classification_relevance",
            ]:
                if not section.get(field):
                    errors.append(f"section_reading_log[{i}] missing {field}")
            if not isinstance(section.get("section_position"), int):
                errors.append(f"section_reading_log[{i}] section_position must be integer")

    if not record.get("general_summary"):
        errors.append("general_summary is empty")

    audit = record.get("decision_audit")
    if not isinstance(audit, dict):
        errors.append("decision_audit must be an object")
    else:
        for field in [
            "own_empirical_evidence",
            "own_quantitative_analysis",
            "qualitative_evidence",
            "statistical_inference",
            "causal_or_credibility_design",
            "contradictory_sections",
        ]:
            if not audit.get(field):
                errors.append(f"decision_audit missing {field}")

    classification = record.get("classification")
    if classification is None:
        return errors

    if not isinstance(classification, dict):
        errors.append("classification must be an object or null")
        return errors

    extra = set(classification) - set(CLASSIFICATION_FIELDS)
    missing = set(CLASSIFICATION_FIELDS) - set(classification)
    if extra:
        errors.append(f"classification has extra fields: {sorted(extra)}")
    if missing:
        errors.append(f"classification missing fields: {sorted(missing)}")

    for field in ["pid", "title", "journal_title", "input_text_hash"]:
        expected = row.get(field, "")
        got = classification.get(field)
        if expected and not metadata_field_matches(field, expected, got):
            errors.append(f"classification {field} mismatch: expected {expected!r}, got {got!r}")

    for field, allowed in ENUMS.items():
        if classification.get(field) not in allowed:
            errors.append(f"invalid {field}: {classification.get(field)!r}")

    for field in BOOLEAN_CLASSIFICATION_FIELDS:
        if not isinstance(classification.get(field), bool):
            errors.append(f"{field} must be boolean")

    for field in NULLABLE_BOOLEAN_CLASSIFICATION_FIELDS:
        value = classification.get(field)
        if value is not None and not isinstance(value, bool):
            errors.append(f"{field} must be boolean or null")

    method_type = classification.get("credibility_revolution_method_type")
    if method_type is not None:
        if not isinstance(method_type, list):
            errors.append("credibility_revolution_method_type must be array or null")
        else:
            invalid = [value for value in method_type if value not in METHOD_TYPES]
            if invalid:
                errors.append(f"invalid credibility method types: {invalid}")
            if (
                classification.get("credibility_revolution_method_present") is True
                and method_type
                and set(method_type).issubset(DIAGNOSTIC_NOT_DESIGN_METHOD_TYPES)
            ):
                errors.append(
                    "method_present cannot be true when method_type contains only diagnostic non-design labels"
                )

    if classification.get("tough_call") is False and classification.get("tough_call_reason") is not None:
        errors.append("tough_call_reason must be null when tough_call is false")

    if classification.get("has_statistical_inference") is True and not classification.get(
        "statistical_inference_quote"
    ):
        errors.append("has_statistical_inference true requires statistical_inference_quote")

    if (
        classification.get("credibility_revolution_screen_applicable") is False
        and classification.get("credibility_revolution_method_present") is not None
    ):
        errors.append("method_present must be null when screen_applicable is false")

    if (
        classification.get("credibility_revolution_screen_applicable") is False
        and classification.get("credibility_revolution_method_type") is not None
    ):
        errors.append("method_type must be null when screen_applicable is false")

    return errors


def ordered_classification(classification: dict[str, Any]) -> dict[str, Any]:
    return {field: classification.get(field) for field in CLASSIFICATION_FIELDS}


def save_valid_record(record: dict[str, Any], row: dict[str, str], dirs: dict[str, Path]) -> None:
    pid = row["pid"]
    failed_path = dirs["failed"] / f"{pid}.txt"
    reading_payload = {
        field: record.get(field)
        for field in [
            "pid",
            "title",
            "journal_title",
            "input_text_hash",
            "status",
            "full_body_read",
            "incomplete_reason",
            "section_reading_log",
            "general_summary",
            "decision_audit",
        ]
    }
    atomic_write_text(
        dirs["reading"] / f"{pid}.json",
        json.dumps(reading_payload, ensure_ascii=False, indent=2) + "\n",
    )
    classification = ordered_classification(record["classification"])
    atomic_write_text(
        dirs["classifications"] / f"{pid}.json",
        json.dumps(classification, ensure_ascii=False, indent=2) + "\n",
    )
    if failed_path.exists():
        failed_path.unlink()


def save_failed(pid: str, reason: str, dirs: dict[str, Path]) -> None:
    atomic_write_text(dirs["failed"] / f"{pid}.txt", reason + "\n")


def atomic_write_text(path: Path, text: str) -> None:
    tmp_path = path.with_suffix(path.suffix + ".tmp")
    tmp_path.write_text(text, encoding="utf-8")
    tmp_path.replace(path)


def csv_value(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, (list, dict)):
        return json.dumps(value, ensure_ascii=False)
    return str(value)


def combine_outputs(rows: list[dict[str, str]], dirs: dict[str, Path]) -> dict[str, Any]:
    manifest_pids = [row["pid"] for row in rows]
    records: list[dict[str, Any]] = []
    complete_pids: set[str] = set()

    for pid in manifest_pids:
        classification_path = dirs["classifications"] / f"{pid}.json"
        reading_path = dirs["reading"] / f"{pid}.json"
        if not classification_path.exists() or not reading_path.exists():
            continue
        reading_record = json.loads(reading_path.read_text(encoding="utf-8"))
        if reading_record.get("full_body_read") is not True or reading_record.get("status") != "complete":
            continue
        record = json.loads(classification_path.read_text(encoding="utf-8"))
        records.append(ordered_classification(record))
        complete_pids.add(pid)

    jsonl_path = dirs["combined"] / "classifications_integral_reading.jsonl"
    csv_path = dirs["combined"] / "classifications_integral_reading.csv"
    report_path = dirs["combined"] / "integral_reading_batch_report.md"

    with jsonl_path.open("w", encoding="utf-8") as f:
        for record in records:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")

    with csv_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=CLASSIFICATION_FIELDS)
        writer.writeheader()
        for record in records:
            writer.writerow({field: csv_value(record.get(field)) for field in CLASSIFICATION_FIELDS})

    counts = {
        "n_manifest": len(rows),
        "n_complete": len(records),
        "n_missing": len(rows) - len(records),
        "n_failed_files": len(list(dirs["failed"].glob("*.txt"))),
        "n_reading_logs": len(list(dirs["reading"].glob("*.json"))),
    }
    missing_pids = [pid for pid in manifest_pids if pid not in complete_pids]

    report_lines = [
        "# Integral reading batch report",
        "",
        f"Generated at: {datetime.now(timezone.utc).isoformat()}",
        "",
        "## Counts",
        "",
        f"- Manifest articles: {counts['n_manifest']}",
        f"- Complete classifications: {counts['n_complete']}",
        f"- Reading logs: {counts['n_reading_logs']}",
        f"- Missing classifications: {counts['n_missing']}",
        f"- Failed files: {counts['n_failed_files']}",
        "",
        "## Missing PIDs",
        "",
    ]
    if missing_pids:
        report_lines.extend(f"- {pid}" for pid in missing_pids)
    else:
        report_lines.append("_None._")
    report_lines.extend(
        [
            "",
            "## Integrity rule",
            "",
            "A PID is counted as complete only when both a reading log and a valid classification JSON exist.",
            "The batch runner rejects complete classifications without `full_body_read == true`, without section summaries, or without required schema fields.",
        ]
    )
    atomic_write_text(report_path, "\n".join(report_lines) + "\n")

    return {
        **counts,
        "jsonl_path": str(jsonl_path),
        "csv_path": str(csv_path),
        "report_path": str(report_path),
        "missing_pids": missing_pids,
    }


def already_complete(pid: str, dirs: dict[str, Path]) -> bool:
    return (dirs["reading"] / f"{pid}.json").exists() and (dirs["classifications"] / f"{pid}.json").exists()


def run_codex_for_row(
    row: dict[str, str],
    prompt: str,
    dirs: dict[str, Path],
    args: argparse.Namespace,
) -> tuple[bool, str]:
    pid = row["pid"]
    raw_path = dirs["raw"] / f"{pid}.json"
    stdout_path = dirs["logs"] / f"{pid}.stdout.log"
    stderr_path = dirs["logs"] / f"{pid}.stderr.log"

    cmd = [
        args.codex_bin,
        "exec",
        "--cd",
        str(PROJECT_DIR),
        "--sandbox",
        "read-only",
        "--output-schema",
        str(OUTPUT_SCHEMA),
        "-o",
        str(raw_path),
        "-",
    ]
    if args.model:
        cmd[2:2] = ["--model", args.model]
    if args.ephemeral:
        cmd.insert(-1, "--ephemeral")

    try:
        result = subprocess.run(
            cmd,
            input=prompt,
            text=True,
            encoding="utf-8",
            capture_output=True,
            timeout=args.timeout,
            cwd=PROJECT_DIR,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        stdout_path.write_text(exc.stdout or "", encoding="utf-8")
        stderr_path.write_text(exc.stderr or "", encoding="utf-8")
        return False, f"codex exec timed out after {args.timeout} seconds"
    except FileNotFoundError as exc:
        return False, f"codex binary not found: {exc}"
    stdout_path.write_text(result.stdout, encoding="utf-8")
    stderr_path.write_text(result.stderr, encoding="utf-8")

    if result.returncode != 0:
        return False, f"codex exec failed with return code {result.returncode}; see {stderr_path}"
    if not raw_path.exists():
        return False, f"codex exec did not write final message file: {raw_path}"

    try:
        record = extract_json_object(raw_path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        return False, f"could not parse JSON from final message: {exc}"

    errors = validate_record(record, row)
    if errors:
        return False, "validation errors:\n" + "\n".join(f"- {error}" for error in errors)

    if record["status"] != "complete":
        return False, f"incomplete record: {record.get('incomplete_reason')}"

    save_valid_record(record, row, dirs)
    return True, "ok"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--pid", action="append", help="Restrict to one PID; repeatable.")
    parser.add_argument("--offset", type=int, default=0, help="Skip this many selected manifest rows.")
    parser.add_argument("--limit", type=int, default=None, help="Limit number of selected PIDs.")
    parser.add_argument("--force", action="store_true", help="Re-run PIDs with existing valid outputs.")
    parser.add_argument("--dry-run", action="store_true", help="Render prompts but do not call Codex.")
    parser.add_argument("--combine-only", action="store_true", help="Only combine existing valid classification files.")
    parser.add_argument("--codex-bin", default="codex")
    parser.add_argument("--model", default=None, help="Optional Codex model name.")
    parser.add_argument("--timeout", type=int, default=1800, help="Timeout per article in seconds.")
    parser.add_argument("--ephemeral", action="store_true", help="Pass --ephemeral to codex exec.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    manifest_path = args.manifest if args.manifest.is_absolute() else PROJECT_DIR / args.manifest
    out_dir = args.out_dir if args.out_dir.is_absolute() else PROJECT_DIR / args.out_dir
    dirs = ensure_dirs(out_dir)

    selected_pids = set(args.pid) if args.pid else None
    rows = load_manifest(manifest_path, selected_pids)
    try:
        rows = select_manifest_window(rows, offset=args.offset, limit=args.limit)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    if not rows:
        print("No manifest rows selected.", file=sys.stderr)
        return 1

    if args.combine_only:
        summary = combine_outputs(rows, dirs)
        print(json.dumps(summary, ensure_ascii=False, indent=2))
        return 0

    print(f"Manifest: {manifest_path}")
    print(f"Output dir: {out_dir}")
    print(f"Selected articles: {len(rows)}")

    ok = 0
    failed = 0
    skipped = 0

    for index, row in enumerate(rows, start=1):
        pid = row["pid"]
        if already_complete(pid, dirs) and not args.force:
            print(f"[{index}/{len(rows)}] SKIP {pid} already complete")
            skipped += 1
            continue

        prompt = render_prompt(row)
        prompt_path = dirs["prompts"] / f"{pid}.prompt.md"
        prompt_path.write_text(prompt, encoding="utf-8")

        if args.dry_run:
            print(f"[{index}/{len(rows)}] DRY {pid} prompt={prompt_path}")
            ok += 1
            continue

        print(f"[{index}/{len(rows)}] RUN {pid}", flush=True)
        success, message = run_codex_for_row(row, prompt, dirs, args)
        if success:
            print(f"[{index}/{len(rows)}] OK  {pid}")
            ok += 1
        else:
            print(f"[{index}/{len(rows)}] FAIL {pid}: {message}", file=sys.stderr)
            save_failed(pid, message, dirs)
            failed += 1

    if args.dry_run:
        print(
            json.dumps(
                {
                    "selected": len(rows),
                    "prompts_rendered": ok,
                    "out_dir": str(out_dir),
                    "combined": None,
                },
                ensure_ascii=False,
                indent=2,
            )
        )
        return 0

    summary = combine_outputs(rows, dirs)
    print(
        json.dumps(
            {
                "selected": len(rows),
                "ok_or_dry": ok,
                "skipped": skipped,
                "failed": failed,
                "combined": summary,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
