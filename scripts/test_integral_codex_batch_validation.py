from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[1]
RUNNER_PATH = PROJECT_DIR / "scripts/25_run_credibility_prompt_v3_integral_codex_batch.py"


def load_runner():
    spec = importlib.util.spec_from_file_location("integral_runner", RUNNER_PATH)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def valid_record(title: str, journal_title: str, input_text_hash: str) -> dict:
    classification = {
        "pid": "S001",
        "title": title,
        "journal_title": journal_title,
        "input_text_hash": input_text_hash,
        "is_empirical_paper": False,
        "empirical_evidence_type": "none",
        "is_empirical_quant_paper_torreblanca": False,
        "is_empirical_qual_paper": False,
        "quantitative_analysis_type": "none",
        "quantitative_analysis_evidence_quote": None,
        "has_statistical_inference": None,
        "statistical_inference_quote": None,
        "qualitative_analysis_goal": None,
        "qualitative_goal_clarity": None,
        "qualitative_goal_quote": None,
        "causal_or_explanatory_claim_present": False,
        "causal_or_explanatory_claim_quote": None,
        "credibility_revolution_screen_applicable": False,
        "credibility_revolution_screen_reason": "not_empirical",
        "credibility_revolution_method_present": None,
        "credibility_revolution_method_type": None,
        "causal_design_quote": None,
        "main_variables_or_relationship": None,
        "sample_or_data_source": None,
        "tough_call": False,
        "tough_call_reason": None,
        "brief_justification": "No empirical evidence.",
    }
    return {
        "pid": "S001",
        "title": title,
        "journal_title": journal_title,
        "input_text_hash": input_text_hash,
        "status": "complete",
        "full_body_read": True,
        "incomplete_reason": None,
        "section_reading_log": [
            {
                "section_title": "Introduction",
                "section_position": 1,
                "section_summary": "The article introduces the topic.",
                "methods_or_data_mentions": "No methods or data.",
                "classification_relevance": "Supports non-empirical classification.",
            }
        ],
        "general_summary": "The paper is non-empirical.",
        "decision_audit": {
            "own_empirical_evidence": "No own empirical evidence.",
            "own_quantitative_analysis": "No quantitative analysis.",
            "qualitative_evidence": "No qualitative evidence.",
            "statistical_inference": "No statistical inference.",
            "causal_or_credibility_design": "No causal design.",
            "contradictory_sections": "No contradictory sections.",
        },
        "classification": classification,
    }


def test_validate_record_accepts_html_entity_equivalent_titles():
    runner = load_runner()
    row = {
        "pid": "S001",
        "title": "A Imprensa Brasileira e suas &#8220;Cruzadas Morais&#8221;",
        "journal_title": "Opini&#227;o P&#250;blica",
        "input_text_hash": "abc123",
    }
    record = valid_record(
        title="A Imprensa Brasileira e suas “Cruzadas Morais”",
        journal_title="Opinião Pública",
        input_text_hash="abc123",
    )

    assert runner.validate_record(record, row) == []


def test_validate_record_accepts_omitted_outer_title_quotes():
    runner = load_runner()
    row = {
        "pid": "S001",
        "title": '"Acordem! Nossos relógios estão lentos em relação ao nosso tempo"',
        "journal_title": "Contexto Internacional",
        "input_text_hash": "abc123",
    }
    record = valid_record(
        title="Acordem! Nossos relógios estão lentos em relação ao nosso tempo",
        journal_title="Contexto Internacional",
        input_text_hash="abc123",
    )

    assert runner.validate_record(record, row) == []


def test_validate_record_still_requires_literal_hash_match():
    runner = load_runner()
    row = {
        "pid": "S001",
        "title": "A Imprensa Brasileira e suas &#8220;Cruzadas Morais&#8221;",
        "journal_title": "Opini&#227;o P&#250;blica",
        "input_text_hash": "abc123",
    }
    record = valid_record(
        title="A Imprensa Brasileira e suas “Cruzadas Morais”",
        journal_title="Opinião Pública",
        input_text_hash="def456",
    )

    errors = runner.validate_record(record, row)

    assert "top-level input_text_hash mismatch: expected 'abc123', got 'def456'" in errors
    assert "classification input_text_hash mismatch: expected 'abc123', got 'def456'" in errors


def test_validate_record_still_requires_literal_pid_match():
    runner = load_runner()
    row = {
        "pid": "S001",
        "title": "A Imprensa Brasileira e suas &#8220;Cruzadas Morais&#8221;",
        "journal_title": "Opini&#227;o P&#250;blica",
        "input_text_hash": "abc123",
    }
    record = valid_record(
        title="A Imprensa Brasileira e suas “Cruzadas Morais”",
        journal_title="Opinião Pública",
        input_text_hash="abc123",
    )
    record["pid"] = "S002"
    record["classification"]["pid"] = "S002"

    errors = runner.validate_record(record, row)

    assert "top-level pid mismatch: expected 'S001', got 'S002'" in errors
    assert "classification pid mismatch: expected 'S001', got 'S002'" in errors


def test_validate_record_rejects_diagnostic_method_as_positive_design():
    runner = load_runner()
    row = {
        "pid": "S001",
        "title": "A Imprensa Brasileira e suas &#8220;Cruzadas Morais&#8221;",
        "journal_title": "Opini&#227;o P&#250;blica",
        "input_text_hash": "abc123",
    }
    record = valid_record(
        title="A Imprensa Brasileira e suas “Cruzadas Morais”",
        journal_title="Opinião Pública",
        input_text_hash="abc123",
    )
    classification = record["classification"]
    classification["is_empirical_paper"] = True
    classification["empirical_evidence_type"] = "quantitative_only"
    classification["is_empirical_quant_paper_torreblanca"] = True
    classification["quantitative_analysis_type"] = "statistical_modeling"
    classification["causal_or_explanatory_claim_present"] = True
    classification["credibility_revolution_screen_applicable"] = True
    classification["credibility_revolution_screen_reason"] = "statistical_modeling_screen"
    classification["credibility_revolution_method_present"] = True
    classification["credibility_revolution_method_type"] = [
        "observational_regression_with_causal_claim_no_design"
    ]

    errors = runner.validate_record(record, row)

    assert (
        "method_present cannot be true when method_type contains only diagnostic non-design labels"
        in errors
    )


def test_validate_record_rejects_method_type_when_screen_is_false():
    runner = load_runner()
    row = {
        "pid": "S001",
        "title": "A Imprensa Brasileira e suas &#8220;Cruzadas Morais&#8221;",
        "journal_title": "Opini&#227;o P&#250;blica",
        "input_text_hash": "abc123",
    }
    record = valid_record(
        title="A Imprensa Brasileira e suas “Cruzadas Morais”",
        journal_title="Opinião Pública",
        input_text_hash="abc123",
    )
    record["classification"]["credibility_revolution_method_type"] = ["none_detected"]

    errors = runner.validate_record(record, row)

    assert "method_type must be null when screen_applicable is false" in errors


def test_select_manifest_window_applies_offset_and_limit():
    runner = load_runner()
    rows = [{"pid": f"S{i:03d}"} for i in range(5)]

    selected = runner.select_manifest_window(rows, offset=2, limit=2)

    assert [row["pid"] for row in selected] == ["S002", "S003"]


def test_select_manifest_window_rejects_negative_values():
    runner = load_runner()
    rows = [{"pid": "S001"}]

    try:
        runner.select_manifest_window(rows, offset=-1, limit=None)
    except ValueError as exc:
        assert "--offset must be non-negative" in str(exc)
    else:
        raise AssertionError("negative offset should raise ValueError")

    try:
        runner.select_manifest_window(rows, offset=0, limit=-1)
    except ValueError as exc:
        assert "--limit must be non-negative" in str(exc)
    else:
        raise AssertionError("negative limit should raise ValueError")


def test_combine_outputs_custom_stem_does_not_write_canonical_files(tmp_path):
    runner = load_runner()
    dirs = {}
    for name in ["combined", "classifications", "reading", "failed"]:
        dirs[name] = tmp_path / name
        dirs[name].mkdir()

    row = {
        "pid": "S001",
        "title": "Title",
        "journal_title": "Journal",
        "input_text_hash": "abc123",
    }
    record = valid_record(
        title="Title",
        journal_title="Journal",
        input_text_hash="abc123",
    )
    reading_record = {
        field: record[field]
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
    (dirs["reading"] / "S001.json").write_text(
        json.dumps(reading_record, ensure_ascii=False),
        encoding="utf-8",
    )
    (dirs["classifications"] / "S001.json").write_text(
        json.dumps(record["classification"], ensure_ascii=False),
        encoding="utf-8",
    )

    summary = runner.combine_outputs([row], dirs, combined_stem="active_batch_005")

    assert summary["n_complete"] == 1
    assert (dirs["combined"] / "active_batch_005.csv").exists()
    assert (dirs["combined"] / "active_batch_005.jsonl").exists()
    assert (dirs["combined"] / "active_batch_005_batch_report.md").exists()
    assert not (dirs["combined"] / "classifications_integral_reading.csv").exists()
    assert not (dirs["combined"] / "classifications_integral_reading.jsonl").exists()
    assert not (dirs["combined"] / "integral_reading_batch_report.md").exists()


def test_build_codex_command_passes_model_reasoning_effort(tmp_path):
    runner = load_runner()
    raw_path = tmp_path / "response.json"
    args = argparse.Namespace(
        codex_bin="codex",
        model="gpt-5.5",
        model_reasoning_effort="high",
        ephemeral=False,
    )

    cmd = runner.build_codex_command(args, raw_path)

    assert cmd[0:2] == ["codex", "exec"]
    assert ["--model", "gpt-5.5"] == cmd[2:4]
    config_pos = cmd.index("-c")
    assert cmd[config_pos + 1] == 'model_reasoning_effort="high"'
    assert cmd[-1] == "-"


def test_build_codex_command_places_ephemeral_before_stdin_prompt(tmp_path):
    runner = load_runner()
    raw_path = tmp_path / "response.json"
    args = argparse.Namespace(
        codex_bin="codex",
        model=None,
        model_reasoning_effort=None,
        ephemeral=True,
    )

    cmd = runner.build_codex_command(args, raw_path)

    assert cmd[-2:] == ["--ephemeral", "-"]


def test_build_codex_command_omits_model_reasoning_effort_by_default(tmp_path):
    runner = load_runner()
    raw_path = tmp_path / "response.json"
    args = argparse.Namespace(
        codex_bin="codex",
        model=None,
        model_reasoning_effort=None,
        ephemeral=False,
    )

    cmd = runner.build_codex_command(args, raw_path)

    assert "-c" not in cmd
    assert not any("model_reasoning_effort" in value for value in cmd)


def test_parse_args_accepts_model_reasoning_effort_cli():
    runner = load_runner()

    args = runner.parse_args(["--model", "gpt-5.5", "--model-reasoning-effort", "high"])

    assert args.model == "gpt-5.5"
    assert args.model_reasoning_effort == "high"


def test_ab_output_dir_requires_custom_combined_stem():
    runner = load_runner()

    errors = runner.output_naming_errors(
        Path("data/processed/credibility_prompt_v3_integral_reading/full_corpus_ab/gpt55_high"),
        "classifications_integral_reading",
    )

    assert errors
    assert runner.output_naming_errors(
        Path("data/processed/credibility_prompt_v3_integral_reading/full_corpus_ab/gpt55_high"),
        "classifications_integral_reading_ab_gpt55_high_50",
    ) == []
