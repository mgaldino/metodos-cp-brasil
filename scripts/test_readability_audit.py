"""
test_readability_audit.py

Comprehensive tests for readability_audit.py.

Run:
    python3 -m pytest test_readability_audit.py -v
"""

import json
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from readability_audit import (
    MIN_WORDS_FOR_METRICS,
    aggregate_metrics,
    classify_ai_score,
    count_words,
    hedging_pct,
    main,
    nominalization_pct,
    pangram_score,
    parse_file,
    parse_rmd,
    parse_tex,
    passive_voice_pct,
    readability_metrics,
    run_audit,
    section_metrics,
    style_metrics,
)


# ========================================================================
# Parser tests
# ========================================================================


class TestParseRmd:
    """Tests for .Rmd parser."""

    SAMPLE_RMD = """\
---
title: "My Paper"
author: "Jane Doe"
output: pdf_document
---

Some preamble text before sections.

# Introduction

This is the introduction section with enough words to be meaningful.

## Literature Review

The literature review discusses many important topics and findings
from prior research in the field.

# Methods

We use ordinary least squares regression to estimate the model.

```{r setup, include=FALSE}
library(tidyverse)
data <- read_csv("data.csv")
```

The data was collected from multiple sources.
"""

    def test_finds_sections(self) -> None:
        sections = parse_rmd(self.SAMPLE_RMD)
        assert "Introduction" in sections
        assert "Literature Review" in sections
        assert "Methods" in sections

    def test_strips_yaml_frontmatter(self) -> None:
        sections = parse_rmd(self.SAMPLE_RMD)
        all_text = " ".join(sections.values())
        assert "title:" not in all_text
        assert "output: pdf_document" not in all_text

    def test_strips_r_code_chunks(self) -> None:
        sections = parse_rmd(self.SAMPLE_RMD)
        all_text = " ".join(sections.values())
        assert "library(tidyverse)" not in all_text
        assert "read_csv" not in all_text

    def test_preamble_captured(self) -> None:
        sections = parse_rmd(self.SAMPLE_RMD)
        assert "Preamble" in sections
        assert "preamble text" in sections["Preamble"]

    def test_empty_document(self) -> None:
        sections = parse_rmd("")
        assert sections == {}

    def test_no_yaml(self) -> None:
        text = "# Intro\n\nHello world.\n"
        sections = parse_rmd(text)
        assert "Intro" in sections


class TestParseTex:
    r"""Tests for .tex parser."""

    SAMPLE_TEX = r"""
\documentclass{article}
\begin{document}

\begin{abstract}
This paper studies the effect of institutions on economic growth
using a novel instrumental variable strategy.
\end{abstract}

\section{Introduction}
We study the \textbf{causal} effect of democratic institutions
on long-run economic performance. Prior work by \cite{AJR2001}
established that colonial origins matter.

\section{Data}
Our dataset covers 150 countries from 1960 to 2020.
We use GDP per capita as the dependent variable.

\end{document}
"""

    def test_finds_sections(self) -> None:
        sections = parse_tex(self.SAMPLE_TEX)
        assert "Introduction" in sections
        assert "Data" in sections

    def test_extracts_abstract(self) -> None:
        sections = parse_tex(self.SAMPLE_TEX)
        assert "Abstract" in sections
        assert "instrumental variable" in sections["Abstract"]

    def test_strips_commands(self) -> None:
        sections = parse_tex(self.SAMPLE_TEX)
        # \textbf{causal} should become just "causal"
        assert "\\textbf" not in sections["Introduction"]
        assert "causal" in sections["Introduction"]

    def test_strips_cite(self) -> None:
        sections = parse_tex(self.SAMPLE_TEX)
        assert "\\cite" not in sections["Introduction"]
        assert "AJR2001" in sections["Introduction"]

    def test_no_abstract(self) -> None:
        text = r"\section{Intro}" + "\nHello world.\n"
        sections = parse_tex(text)
        assert "Abstract" not in sections
        assert "Intro" in sections

    def test_empty_document(self) -> None:
        sections = parse_tex("")
        assert sections == {}


class TestParseFile:
    """Tests for the parse_file dispatcher."""

    def test_unsupported_extension(self) -> None:
        with pytest.raises(ValueError, match="Unsupported file type"):
            parse_file("paper.docx")

    def test_rmd_dispatch(self, tmp_path: Path) -> None:
        rmd = tmp_path / "paper.Rmd"
        rmd.write_text("# Intro\n\nHello world with enough words for a section.\n")
        sections = parse_file(rmd)
        assert "Intro" in sections

    def test_tex_dispatch(self, tmp_path: Path) -> None:
        tex = tmp_path / "paper.tex"
        tex.write_text(r"\section{Intro}" + "\nHello world.\n")
        sections = parse_file(tex)
        assert "Intro" in sections


# ========================================================================
# Metrics tests
# ========================================================================


class TestReadabilityMetrics:
    """Tests for readability score computation."""

    SIMPLE_TEXT = (
        "The cat sat on the mat. The dog ran in the park. "
        "It was a sunny day. Birds sang in the trees. "
        "Kids played on the swings."
    )
    COMPLEX_TEXT = (
        "The institutionalization of democratic governance mechanisms "
        "necessitates the operationalization of multidimensional "
        "accountability frameworks, incorporating both horizontal "
        "and vertical dimensions of representational legitimacy "
        "within the broader context of deliberative democratization "
        "processes that characterize contemporary political systems."
    )

    def test_returns_all_keys(self) -> None:
        m = readability_metrics(self.SIMPLE_TEXT)
        assert "flesch_re" in m
        assert "fk_grade" in m
        assert "fog" in m
        assert "smog" in m

    def test_simple_text_high_flesch(self) -> None:
        m = readability_metrics(self.SIMPLE_TEXT)
        # Simple sentences should have high readability
        assert m["flesch_re"] > 60

    def test_complex_text_lower_flesch(self) -> None:
        m = readability_metrics(self.COMPLEX_TEXT)
        simple_m = readability_metrics(self.SIMPLE_TEXT)
        assert m["flesch_re"] < simple_m["flesch_re"]

    def test_values_are_floats(self) -> None:
        m = readability_metrics(self.SIMPLE_TEXT)
        for v in m.values():
            assert isinstance(v, float)


class TestStyleMetrics:
    """Tests for style metric computation."""

    def test_returns_all_keys(self) -> None:
        text = "The cat sat on the mat and it was a good day for everyone."
        m = style_metrics(text)
        assert "passive_voice_pct" in m
        assert "nominalization_pct" in m
        assert "hedging_pct" in m


class TestPassiveVoice:
    """Tests for passive voice detection."""

    def test_detects_passive(self) -> None:
        text = "The ball was thrown by the player."
        pct = passive_voice_pct(text)
        assert pct > 0

    def test_active_voice_low(self) -> None:
        text = "The player threw the ball. She ran fast. He kicked hard."
        pct = passive_voice_pct(text)
        assert pct == 0.0

    def test_multiple_sentences(self) -> None:
        text = (
            "The cake was eaten by the children. "
            "The dog chased the cat. "
            "The report was written by the committee."
        )
        pct = passive_voice_pct(text)
        # 2 out of 3 sentences are passive
        assert 50 < pct < 80

    def test_empty_text(self) -> None:
        assert passive_voice_pct("") == 0.0


class TestNominalization:
    """Tests for nominalization detection."""

    def test_high_nominalization(self) -> None:
        text = (
            "The implementation of the authorization required "
            "the consideration of the organization and the "
            "establishment of proper documentation and measurement."
        )
        pct = nominalization_pct(text)
        assert pct > 20

    def test_low_nominalization(self) -> None:
        text = "The cat sat on the mat. Dogs run in the park."
        pct = nominalization_pct(text)
        assert pct == 0.0

    def test_short_words_ignored(self) -> None:
        # "tion" is only 4 chars, should not be counted
        text = "tion sion ment ness ity ance ence ism"
        pct = nominalization_pct(text)
        assert pct == 0.0

    def test_empty_text(self) -> None:
        assert nominalization_pct("") == 0.0


class TestHedging:
    """Tests for hedging word detection."""

    def test_detects_hedges(self) -> None:
        text = "This might suggest that the results could possibly indicate a trend."
        pct = hedging_pct(text)
        # "might", "suggest", "could", "possibly", "indicate" = 5 hedges out of 11 words
        assert pct > 30

    def test_no_hedges(self) -> None:
        text = "The sun rises in the east. Water boils at one hundred degrees."
        pct = hedging_pct(text)
        assert pct == 0.0

    def test_empty_text(self) -> None:
        assert hedging_pct("") == 0.0


class TestWordCount:
    """Tests for word counting."""

    def test_simple(self) -> None:
        assert count_words("hello world") == 2

    def test_empty(self) -> None:
        assert count_words("") == 0

    def test_multiline(self) -> None:
        assert count_words("one two\nthree four") == 4


class TestSectionMetrics:
    """Tests for per-section metric aggregation."""

    def test_short_section_returns_zeros(self) -> None:
        text = "Too short."
        m = section_metrics(text)
        assert m["word_count"] < MIN_WORDS_FOR_METRICS
        assert m["flesch_re"] == 0.0
        assert m["fog"] == 0.0
        assert m["passive_voice_pct"] == 0.0

    def test_long_section_returns_metrics(self) -> None:
        text = (
            "The implementation of democratic governance structures "
            "was carefully designed to ensure broad participation "
            "across all levels of government administration."
        )
        m = section_metrics(text)
        assert m["word_count"] >= MIN_WORDS_FOR_METRICS
        assert "flesch_re" in m
        assert "passive_voice_pct" in m

    def test_all_keys_present(self) -> None:
        text = "A " * 20  # 20 words
        m = section_metrics(text)
        expected_keys = {
            "word_count", "flesch_re", "fk_grade", "fog", "smog",
            "passive_voice_pct", "nominalization_pct", "hedging_pct",
        }
        assert set(m.keys()) == expected_keys


class TestAggregateMetrics:
    """Tests for aggregate metric computation."""

    def test_combines_sections(self) -> None:
        sections = {
            "A": "The cat sat on the mat and played with balls all day long.",
            "B": "The dog ran in the park and chased the birds around the field.",
        }
        m = aggregate_metrics(sections)
        assert m["word_count"] > 0
        assert "flesch_re" in m


# ========================================================================
# Pangram tests
# ========================================================================


class TestClassifyAiScore:
    """Tests for AI score classification thresholds."""

    def test_human(self) -> None:
        assert classify_ai_score(0.0) == "Human"
        assert classify_ai_score(0.14) == "Human"

    def test_collaborative(self) -> None:
        assert classify_ai_score(0.15) == "Collaborative"
        assert classify_ai_score(0.29) == "Collaborative"

    def test_substantial_ai(self) -> None:
        assert classify_ai_score(0.30) == "Substantial AI"
        assert classify_ai_score(0.69) == "Substantial AI"

    def test_primarily_ai(self) -> None:
        assert classify_ai_score(0.70) == "Primarily AI"
        assert classify_ai_score(1.0) == "Primarily AI"


class TestPangramScore:
    """Tests for pangram_score with mocked API."""

    @patch("pangram.Pangram")
    def test_returns_dict(self, mock_pangram_cls: MagicMock) -> None:
        mock_client = MagicMock()
        mock_client.predict.return_value = {"fraction_ai": 0.12}
        mock_pangram_cls.return_value = mock_client

        result = pangram_score("Some sample text for analysis.")
        assert isinstance(result, dict)
        assert result["score"] == 0.12
        assert result["category"] == "Human"
        assert "raw" in result

    @patch("pangram.Pangram")
    def test_high_ai_score(self, mock_pangram_cls: MagicMock) -> None:
        mock_client = MagicMock()
        mock_client.predict.return_value = {"fraction_ai": 0.85}
        mock_pangram_cls.return_value = mock_client

        result = pangram_score("AI generated text.")
        assert result["score"] == 0.85
        assert result["category"] == "Primarily AI"

    @patch("pangram.Pangram")
    def test_missing_fraction_ai(self, mock_pangram_cls: MagicMock) -> None:
        mock_client = MagicMock()
        mock_client.predict.return_value = {}
        mock_pangram_cls.return_value = mock_client

        result = pangram_score("Some text.")
        assert result["score"] == 0.0
        assert result["category"] == "Human"


# ========================================================================
# Integration tests
# ========================================================================


class TestRunAudit:
    """Integration tests for the full audit pipeline."""

    SAMPLE_RMD = """\
---
title: "Test Paper"
output: pdf_document
---

# Abstract

This paper examines the relationship between institutional quality
and economic development across multiple countries over several decades.
We use instrumental variables to address potential endogeneity concerns.

# Introduction

The study of institutions and their effects on economic outcomes
has been a central topic in political science and economics.
Recent advances in causal inference have enabled researchers to
more rigorously test theoretical predictions about institutional
effects on growth and development across nations.

# Methods

We employ a two-stage least squares approach with colonial origins
as an instrument for contemporary institutional quality measures.
The identification strategy relies on the exclusion restriction
that colonial origins affect growth only through institutions.
"""

    def test_returns_valid_structure(self, tmp_path: Path) -> None:
        rmd = tmp_path / "paper.Rmd"
        rmd.write_text(self.SAMPLE_RMD)

        result = run_audit(rmd, use_pangram=False)

        assert "file" in result
        assert result["file"] == "paper.Rmd"
        assert "date" in result
        assert "sections" in result
        assert "aggregate" in result
        # pangram should not be present when use_pangram=False
        assert "pangram" not in result

    def test_sections_have_metrics(self, tmp_path: Path) -> None:
        rmd = tmp_path / "paper.Rmd"
        rmd.write_text(self.SAMPLE_RMD)

        result = run_audit(rmd, use_pangram=False)

        for name, metrics in result["sections"].items():
            assert "word_count" in metrics, f"Missing word_count in {name}"
            assert "flesch_re" in metrics, f"Missing flesch_re in {name}"
            assert "passive_voice_pct" in metrics, f"Missing passive_voice_pct in {name}"

    def test_aggregate_has_metrics(self, tmp_path: Path) -> None:
        rmd = tmp_path / "paper.Rmd"
        rmd.write_text(self.SAMPLE_RMD)

        result = run_audit(rmd, use_pangram=False)

        assert result["aggregate"]["word_count"] > 0
        assert "flesch_re" in result["aggregate"]

    def test_json_serializable(self, tmp_path: Path) -> None:
        rmd = tmp_path / "paper.Rmd"
        rmd.write_text(self.SAMPLE_RMD)

        result = run_audit(rmd, use_pangram=False)
        # Must not raise
        output = json.dumps(result)
        assert isinstance(output, str)

    @patch("pangram.Pangram")
    def test_with_pangram(self, mock_pangram_cls: MagicMock, tmp_path: Path) -> None:
        mock_client = MagicMock()
        mock_client.predict.return_value = {"fraction_ai": 0.10}
        mock_pangram_cls.return_value = mock_client

        rmd = tmp_path / "paper.Rmd"
        rmd.write_text(self.SAMPLE_RMD)

        result = run_audit(rmd, use_pangram=True)
        assert "pangram" in result
        assert "aggregate" in result["pangram"]
        assert "category" in result["pangram"]
        assert "sections" in result["pangram"]


class TestCLI:
    """Tests for the CLI entry point."""

    SAMPLE_RMD = """\
---
title: "CLI Test"
---

# Intro

This section has enough words to compute metrics properly for the test.
We add several sentences to ensure the word count exceeds the threshold.
"""

    def test_cli_no_pangram(self, tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
        rmd = tmp_path / "paper.Rmd"
        rmd.write_text(self.SAMPLE_RMD)

        main([str(rmd), "--no-pangram"])

        captured = capsys.readouterr()
        result = json.loads(captured.out)
        assert result["file"] == "paper.Rmd"
        assert "sections" in result
        assert "aggregate" in result
