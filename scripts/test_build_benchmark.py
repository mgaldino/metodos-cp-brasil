"""
test_build_benchmark.py

Unit tests for build_benchmark.py.
"""

import csv
import tempfile
from pathlib import Path

import pytest

from build_benchmark import compute_benchmark_stats, save_csv, METRICS


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_row(
    flesch_re: float = 30.0,
    fk_grade: float = 14.0,
    fog: float = 16.0,
    smog: float = 15.0,
    passive_pct: float = 20.0,
    nominal_pct: float = 25.0,
    hedging_pct: float = 1.5,
    word_count: int = 5000,
    filename: str = "paper.pdf",
    journal: str = "APSR",
) -> dict:
    return {
        "filename": filename,
        "journal": journal,
        "flesch_re": flesch_re,
        "fk_grade": fk_grade,
        "fog": fog,
        "smog": smog,
        "passive_pct": passive_pct,
        "nominal_pct": nominal_pct,
        "hedging_pct": hedging_pct,
        "word_count": word_count,
    }


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


class TestComputeBenchmarkStatsBasic:
    """3 rows, check mean is correct."""

    def test_mean_values(self) -> None:
        rows = [
            _make_row(flesch_re=10.0, fk_grade=12.0, fog=14.0),
            _make_row(flesch_re=20.0, fk_grade=14.0, fog=16.0),
            _make_row(flesch_re=30.0, fk_grade=16.0, fog=18.0),
        ]
        stats = compute_benchmark_stats(rows)

        assert stats["flesch_re"]["mean"] == pytest.approx(20.0, abs=0.01)
        assert stats["fk_grade"]["mean"] == pytest.approx(14.0, abs=0.01)
        assert stats["fog"]["mean"] == pytest.approx(16.0, abs=0.01)
        assert stats["flesch_re"]["n"] == 3

    def test_all_metrics_present(self) -> None:
        rows = [_make_row(), _make_row(), _make_row()]
        stats = compute_benchmark_stats(rows)
        for metric in METRICS:
            assert metric in stats
            assert "mean" in stats[metric]
            assert "std" in stats[metric]
            assert "n" in stats[metric]


class TestComputeBenchmarkStatsPercentiles:
    """101 rows (0-100), check p50 ~ 50, p10 < p50 < p90."""

    def test_percentiles_101_rows(self) -> None:
        rows = [_make_row(flesch_re=float(i)) for i in range(101)]
        stats = compute_benchmark_stats(rows)

        assert stats["flesch_re"]["p50"] == pytest.approx(50.0, abs=1.0)
        assert stats["flesch_re"]["p10"] < stats["flesch_re"]["p50"]
        assert stats["flesch_re"]["p50"] < stats["flesch_re"]["p90"]
        assert stats["flesch_re"]["n"] == 101

    def test_p10_approximately_10(self) -> None:
        rows = [_make_row(flesch_re=float(i)) for i in range(101)]
        stats = compute_benchmark_stats(rows)
        assert stats["flesch_re"]["p10"] == pytest.approx(10.0, abs=1.0)

    def test_p90_approximately_90(self) -> None:
        rows = [_make_row(flesch_re=float(i)) for i in range(101)]
        stats = compute_benchmark_stats(rows)
        assert stats["flesch_re"]["p90"] == pytest.approx(90.0, abs=1.0)


class TestComputeBenchmarkStatsEmpty:
    """Empty list returns zeros."""

    def test_empty_returns_zeros(self) -> None:
        stats = compute_benchmark_stats([])

        for metric in METRICS:
            assert stats[metric]["mean"] == 0.0
            assert stats[metric]["std"] == 0.0
            assert stats[metric]["p50"] == 0.0
            assert stats[metric]["n"] == 0


class TestSaveCsvCreatesFile:
    """Write to temp file, verify it has header + rows."""

    def test_creates_file_with_header_and_rows(self) -> None:
        rows = [
            _make_row(filename="a.pdf", journal="APSR"),
            _make_row(filename="b.pdf", journal="AJPS"),
        ]
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "test_output.csv"
            save_csv(rows, path)

            assert path.exists()

            with open(path, newline="", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                fieldnames = reader.fieldnames
                data = list(reader)

            assert "filename" in fieldnames
            assert "journal" in fieldnames
            assert "flesch_re" in fieldnames
            assert "word_count" in fieldnames
            assert len(data) == 2
            assert data[0]["filename"] == "a.pdf"
            assert data[1]["journal"] == "AJPS"

    def test_creates_parent_directories(self) -> None:
        rows = [_make_row()]
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "sub" / "dir" / "output.csv"
            save_csv(rows, path)
            assert path.exists()
