from pathlib import Path

import pytest

import scripts._38_run_credibility_model_benchmark as benchmark


def test_rotated_configs_balances_first_position() -> None:
    first_labels = [benchmark.rotated_configs(index)[0].label for index in range(6)]
    assert first_labels == [
        "sol_medium",
        "terra_medium",
        "terra_xhigh",
        "sol_medium",
        "terra_medium",
        "terra_xhigh",
    ]


def test_build_runner_command_contains_isolated_configuration(tmp_path: Path) -> None:
    config = benchmark.CONFIGS[0]
    command = benchmark.build_runner_command(
        manifest=tmp_path / "manifest.csv",
        out_root=tmp_path / "full_corpus_ab" / "gpt56_model_benchmark_10",
        config=config,
        timeout=120,
        codex_bin="codex",
        pid="PID1",
    )
    assert command[0] == benchmark.sys.executable
    assert command[command.index("--model") + 1] == "gpt-5.6-sol"
    assert command[command.index("--model-reasoning-effort") + 1] == "medium"
    assert command[command.index("--service-tier") + 1] == "default"
    assert command[command.index("--pid") + 1] == "PID1"
    assert "--ephemeral" in command
    assert command[command.index("--combined-stem") + 1].endswith("sol_medium_10")


def test_validate_out_root_rejects_non_benchmark_path(tmp_path: Path) -> None:
    with pytest.raises(ValueError):
        benchmark.validate_out_root(tmp_path / "full_corpus")


def test_validate_out_root_accepts_isolated_path(tmp_path: Path) -> None:
    benchmark.validate_out_root(
        tmp_path / "full_corpus_ab" / "gpt56_model_benchmark_10"
    )


def test_validate_saved_output_rejects_hash_mismatch(tmp_path: Path) -> None:
    config = benchmark.CONFIGS[0]
    base = tmp_path / config.label
    (base / "classifications").mkdir(parents=True)
    (base / "reading_logs").mkdir(parents=True)
    row = {"pid": "PID1", "input_text_hash": "expected"}
    (base / "classifications" / "PID1.json").write_text(
        '{"pid":"PID1","input_text_hash":"wrong"}', encoding="utf-8"
    )
    (base / "reading_logs" / "PID1.json").write_text(
        '{"pid":"PID1","input_text_hash":"expected","status":"complete",'
        '"full_body_read":true,"section_reading_log":[{"section_summary":"ok"}]}',
        encoding="utf-8",
    )

    complete, reason = benchmark.validate_saved_output(tmp_path, config, row)

    assert complete is False
    assert "hash" in reason


def test_has_complete_timing_requires_success() -> None:
    rows = [{"label": "sol_medium", "pid": "PID1", "status": "failed"}]
    assert not benchmark.has_complete_timing(rows, "sol_medium", "PID1")
    rows.append({"label": "sol_medium", "pid": "PID1", "status": "complete"})
    assert benchmark.has_complete_timing(rows, "sol_medium", "PID1")
