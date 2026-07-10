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
