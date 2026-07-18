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
import hashlib
import html
import json
import os
import re
import subprocess
import sys
import tomllib
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
        "provenance": out_dir / "provenance",
        "failed": out_dir / "failed",
        "combined": out_dir / "combined",
    }
    for directory in dirs.values():
        directory.mkdir(parents=True, exist_ok=True)
    return dirs


def load_manifest(path: Path, pids: set[str] | None = None) -> list[dict[str, str]]:
    rows = read_csv_dict(path)
    for row in rows:
        for field in ("pid", "input_text_hash"):
            if not row.get(field):
                raise ValueError(f"Manifest row lacks {field}: {row.get('pid', '')}")
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
    quote_pairs = {
        '"': '"',
        "'": "'",
        "“": "”",
        "‘": "’",
        "«": "»",
    }
    while len(text) >= 2 and quote_pairs.get(text[0]) == text[-1]:
        text = text[1:-1].strip()
    return text


def metadata_field_matches(field: str, expected: str, got: Any) -> bool:
    if field in {"title", "journal_title"}:
        return normalize_metadata_text(expected) == normalize_metadata_text(got)
    return got == expected


def canonicalize_descriptive_metadata(record: dict[str, Any], row: dict[str, str]) -> None:
    """Use the manifest as the source of truth after the model preserves the PID."""
    classification = record.get("classification")
    if not isinstance(classification, dict):
        return

    if not row.get("pid"):
        return
    if record.get("pid") != row["pid"] or classification.get("pid") != row["pid"]:
        return

    for field in ("pid", "title", "journal_title", "input_text_hash"):
        record[field] = row.get(field, "")
        classification[field] = row.get(field, "")

    # The schema uses null for method fields when the credibility screen does
    # not apply; normalize redundant model output before validation.
    if classification.get("credibility_revolution_screen_applicable") is False:
        classification["credibility_revolution_method_present"] = None
        classification["credibility_revolution_method_type"] = None


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


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def codex_config() -> dict[str, Any]:
    codex_home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    config_path = codex_home / "config.toml"
    if not config_path.exists():
        return {}
    try:
        with config_path.open("rb") as handle:
            return tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError):
        return {}


def effective_runtime(args: argparse.Namespace) -> dict[str, str | None]:
    config = codex_config()
    return {
        "model": args.model or config.get("model"),
        "model_reasoning_effort": args.model_reasoning_effort or config.get("model_reasoning_effort"),
        "service_tier": args.service_tier or config.get("service_tier"),
    }


def codex_version(codex_bin: str) -> str | None:
    try:
        result = subprocess.run(
            [codex_bin, "--version"],
            cwd=PROJECT_DIR,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=30,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    return result.stdout.strip() or result.stderr.strip() or None


def write_run_metadata(
    args: argparse.Namespace,
    manifest_path: Path,
    rows: list[dict[str, str]],
    dirs: dict[str, Path],
) -> Path:
    runtime = effective_runtime(args)
    if not runtime["model"]:
        raise ValueError("Could not resolve the effective Codex model; pass --model explicitly.")
    if not runtime["model_reasoning_effort"]:
        raise ValueError(
            "Could not resolve model reasoning effort; pass --model-reasoning-effort explicitly."
        )
    if not runtime["service_tier"]:
        raise ValueError("Could not resolve service tier; pass --service-tier explicitly.")

    args.model = runtime["model"]
    args.model_reasoning_effort = runtime["model_reasoning_effort"]
    args.service_tier = runtime["service_tier"]
    version = codex_version(args.codex_bin)

    metadata_path = dirs["combined"] / f"{args.combined_stem}_run_metadata.json"
    contract = {
        "manifest_path": str(manifest_path.resolve()),
        "manifest_sha256": sha256_file(manifest_path),
        "selected_pids": [row["pid"] for row in rows],
        "model": runtime["model"],
        "model_reasoning_effort": runtime["model_reasoning_effort"],
        "service_tier": runtime["service_tier"],
        "prompt_template_sha256": sha256_file(PROMPT_TEMPLATE),
        "classifier_prompt_sha256": sha256_file(CLASSIFIER_PROMPT_V3),
        "output_schema_sha256": sha256_file(OUTPUT_SCHEMA),
        "codex_binary": args.codex_bin,
        "codex_version": version,
        "runner_script_sha256": sha256_file(Path(__file__).resolve()),
    }
    if metadata_path.exists():
        existing = json.loads(metadata_path.read_text(encoding="utf-8"))
        if existing.get("contract") != contract:
            raise ValueError(
                f"Run metadata conflict at {metadata_path}; refusing to mix models, efforts, "
                "manifests, or prompt versions in one combined stem."
            )
        return metadata_path

    payload = {
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "contract": contract,
        "requested": {
            "model": args.model,
            "model_reasoning_effort": args.model_reasoning_effort,
            "service_tier": args.service_tier,
        },
        "codex_binary": args.codex_bin,
        "codex_version": version,
        "runner_script": str(Path(__file__).resolve()),
        "runner_script_sha256": sha256_file(Path(__file__).resolve()),
    }
    atomic_write_text(metadata_path, json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    return metadata_path


def pid_provenance_path(pid: str, dirs: dict[str, Path]) -> Path:
    return dirs["provenance"] / f"{pid}.json"


def save_pid_provenance(pid: str, contract: dict[str, Any], dirs: dict[str, Path]) -> None:
    reading_path = dirs["reading"] / f"{pid}.json"
    classification_path = dirs["classifications"] / f"{pid}.json"
    payload = {
        "pid": pid,
        "recorded_at_utc": datetime.now(timezone.utc).isoformat(),
        "contract": contract,
        "reading_log_sha256": sha256_file(reading_path),
        "classification_sha256": sha256_file(classification_path),
    }
    atomic_write_text(
        pid_provenance_path(pid, dirs),
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    )


def provenance_matches(pid: str, contract: dict[str, Any], dirs: dict[str, Path]) -> bool:
    path = pid_provenance_path(pid, dirs)
    if not path.exists():
        return False
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False
    reading_path = dirs["reading"] / f"{pid}.json"
    classification_path = dirs["classifications"] / f"{pid}.json"
    if not reading_path.exists() or not classification_path.exists():
        return False
    return (
        payload.get("pid") == pid
        and payload.get("contract") == contract
        and payload.get("reading_log_sha256") == sha256_file(reading_path)
        and payload.get("classification_sha256") == sha256_file(classification_path)
    )


def csv_value(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, (list, dict)):
        return json.dumps(value, ensure_ascii=False)
    return str(value)


def combine_outputs(
    rows: list[dict[str, str]],
    dirs: dict[str, Path],
    combined_stem: str = "classifications_integral_reading",
    contract: dict[str, Any] | None = None,
) -> dict[str, Any]:
    manifest_pids = [row["pid"] for row in rows]
    records: list[dict[str, Any]] = []
    complete_pids: set[str] = set()

    for row in rows:
        record, _ = load_saved_record(row, dirs)
        if record is None or (
            contract is not None and not provenance_matches(row["pid"], contract, dirs)
        ):
            continue
        records.append(ordered_classification(record["classification"]))
        complete_pids.add(row["pid"])

    if not re.fullmatch(r"[A-Za-z0-9_.-]+", combined_stem):
        raise ValueError("--combined-stem may contain only letters, numbers, underscore, dot, and hyphen")

    jsonl_path = dirs["combined"] / f"{combined_stem}.jsonl"
    csv_path = dirs["combined"] / f"{combined_stem}.csv"
    if combined_stem == "classifications_integral_reading":
        report_path = dirs["combined"] / "integral_reading_batch_report.md"
    else:
        report_path = dirs["combined"] / f"{combined_stem}_batch_report.md"

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


def load_saved_record(
    row: dict[str, str], dirs: dict[str, Path]
) -> tuple[dict[str, Any] | None, list[str]]:
    pid = row["pid"]
    classification_path = dirs["classifications"] / f"{pid}.json"
    reading_path = dirs["reading"] / f"{pid}.json"
    if not classification_path.exists() or not reading_path.exists():
        return None, ["saved classification or reading log is missing"]
    try:
        reading_record = json.loads(reading_path.read_text(encoding="utf-8"))
        classification = json.loads(classification_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        return None, [f"could not parse saved output: {exc}"]
    if not isinstance(reading_record, dict) or not isinstance(classification, dict):
        return None, ["saved outputs must be JSON objects"]
    record = {**reading_record, "classification": classification}
    errors = validate_record(record, row)
    if errors or record.get("status") != "complete":
        return None, errors or ["saved record status is not complete"]
    return record, []


def already_complete(
    row: dict[str, str], dirs: dict[str, Path], contract: dict[str, Any] | None = None
) -> bool:
    record, _ = load_saved_record(row, dirs)
    if record is None:
        return False
    return contract is None or provenance_matches(row["pid"], contract, dirs)


def build_codex_command(args: argparse.Namespace, raw_path: Path) -> list[str]:
    cmd = [args.codex_bin, "exec"]
    if args.model:
        cmd.extend(["--model", args.model])
    if args.model_reasoning_effort:
        cmd.extend(["-c", f'model_reasoning_effort="{args.model_reasoning_effort}"'])
    if getattr(args, "service_tier", None):
        cmd.extend(["-c", f'service_tier="{args.service_tier}"'])
    cmd.extend(
        [
            "--cd",
            str(PROJECT_DIR),
            "--sandbox",
            "read-only",
            "--output-schema",
            str(OUTPUT_SCHEMA),
            "-o",
            str(raw_path),
        ]
    )
    if args.ephemeral:
        cmd.append("--ephemeral")
    cmd.append("-")
    return cmd


def output_naming_errors(out_dir: Path, combined_stem: str) -> list[str]:
    if "full_corpus_ab" in out_dir.parts and combined_stem == "classifications_integral_reading":
        return [
            "A/B output directories under full_corpus_ab require a non-default --combined-stem "
            "to keep test outputs distinct from canonical combined filenames."
        ]
    return []


def run_codex_for_row(
    row: dict[str, str],
    prompt: str,
    dirs: dict[str, Path],
    args: argparse.Namespace,
    contract: dict[str, Any],
) -> tuple[bool, str]:
    pid = row["pid"]
    raw_path = dirs["raw"] / f"{pid}.json"
    stdout_path = dirs["logs"] / f"{pid}.stdout.log"
    stderr_path = dirs["logs"] / f"{pid}.stderr.log"

    cmd = build_codex_command(args, raw_path)

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
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
        if isinstance(stdout, bytes):
            stdout = stdout.decode("utf-8", errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", errors="replace")
        stdout_path.write_text(stdout, encoding="utf-8")
        stderr_path.write_text(stderr, encoding="utf-8")
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

    canonicalize_descriptive_metadata(record, row)
    errors = validate_record(record, row)
    if errors:
        return False, "validation errors:\n" + "\n".join(f"- {error}" for error in errors)

    if record["status"] != "complete":
        return False, f"incomplete record: {record.get('incomplete_reason')}"

    save_valid_record(record, row, dirs)
    save_pid_provenance(pid, contract, dirs)
    return True, "ok"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
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
    parser.add_argument(
        "--model-reasoning-effort",
        choices=["low", "medium", "high", "xhigh"],
        default=None,
        help=(
            "Optional Codex model reasoning effort. When provided, passed to codex exec as "
            "-c model_reasoning_effort=\"<effort>\" without editing user config."
        ),
    )
    parser.add_argument(
        "--service-tier",
        choices=["default", "fast"],
        default=None,
        help="Optional Codex service tier override passed with -c service_tier=...",
    )
    parser.add_argument("--timeout", type=int, default=1800, help="Timeout per article in seconds.")
    parser.add_argument("--ephemeral", action="store_true", help="Pass --ephemeral to codex exec.")
    parser.add_argument(
        "--combined-stem",
        default="classifications_integral_reading",
        help=(
            "Filename stem for combined CSV/JSONL outputs. The default preserves historical "
            "paths; use a block-specific stem to avoid overwriting canonical combined files."
        ),
    )
    return parser.parse_args(argv)


def main() -> int:
    args = parse_args()
    manifest_path = args.manifest if args.manifest.is_absolute() else PROJECT_DIR / args.manifest
    out_dir = args.out_dir if args.out_dir.is_absolute() else PROJECT_DIR / args.out_dir
    naming_errors = output_naming_errors(out_dir, args.combined_stem)
    if naming_errors:
        for error in naming_errors:
            print(error, file=sys.stderr)
        return 1
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
        metadata_path = dirs["combined"] / f"{args.combined_stem}_run_metadata.json"
        contract = None
        if metadata_path.exists():
            try:
                contract = json.loads(metadata_path.read_text(encoding="utf-8"))["contract"]
            except (OSError, json.JSONDecodeError, KeyError) as exc:
                print(f"Invalid run metadata at {metadata_path}: {exc}", file=sys.stderr)
                return 1
        summary = combine_outputs(
            rows, dirs, combined_stem=args.combined_stem, contract=contract
        )
        print(json.dumps(summary, ensure_ascii=False, indent=2))
        return 0

    print(f"Manifest: {manifest_path}")
    print(f"Output dir: {out_dir}")
    print(f"Selected articles: {len(rows)}")

    contract = None
    if not args.dry_run:
        try:
            metadata_path = write_run_metadata(args, manifest_path, rows, dirs)
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
            contract = metadata["contract"]
        except (ValueError, OSError, json.JSONDecodeError, KeyError) as exc:
            print(str(exc), file=sys.stderr)
            return 1
        print(f"Run metadata: {metadata_path}")

    ok = 0
    failed = 0
    skipped = 0

    for index, row in enumerate(rows, start=1):
        pid = row["pid"]
        if already_complete(row, dirs, contract) and not args.force:
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
        assert contract is not None
        success, message = run_codex_for_row(row, prompt, dirs, args, contract)
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

    summary = combine_outputs(
        rows, dirs, combined_stem=args.combined_stem, contract=contract
    )
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
