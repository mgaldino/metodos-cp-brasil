"""
readability_audit.py

Compute readability and style metrics for academic papers (.Rmd, .tex, .pdf).
Optionally integrates with Pangram for AI-content detection.

Usage:
    python3 readability_audit.py path/to/paper.Rmd [--no-pangram]

Output: JSON to stdout with per-section and aggregate metrics.

Requires: pip install textstat pdfplumber pangram-sdk
"""

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path
from typing import Any

import pdfplumber
import textstat

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

MIN_WORDS_FOR_METRICS = 10

NOMINALIZATION_SUFFIXES = (
    "tion", "sion", "ment", "ness", "ity", "ance", "ence", "ism",
)
MIN_NOMINALIZATION_WORD_LEN = 6  # only count words longer than 5 chars

HEDGE_WORDS = frozenset({
    "might", "could", "may", "would", "suggest", "perhaps", "possibly",
    "likely", "appear", "seem", "tend", "indicate", "imply", "propose",
    "potential", "presumably",
})

# Regex for passive voice: auxiliary + optional adverb + past participle
_AUX = r"\b(?:am|is|are|was|were|be|been|being)\b"
_PAST_PARTICIPLE = r"\b(\w+(?:ed|en|wn|lt|nt|pt|xt))\b"
PASSIVE_RE = re.compile(
    rf"{_AUX}\s+(?:\w+\s+)?{_PAST_PARTICIPLE}", re.IGNORECASE,
)

PASSIVE_FALSE_POSITIVES = frozenset({
    "different", "comment", "government", "extent", "document",
    "instrument", "development", "department", "management",
    "investment", "argument", "environment", "treatment",
    "assessment", "agreement", "achievement", "improvement",
    "requirement", "statement", "movement", "establishment",
    "commitment", "involvement", "element", "event", "present",
    "current", "recent", "frequent", "ancient", "parent",
    "student", "president", "patient", "moment", "content",
    "percent", "agent", "accident", "innocent", "absent",
    "silent", "violent", "evident", "excellent", "consistent",
    "dependent", "independent", "permanent", "prominent",
})

# ---------------------------------------------------------------------------
# Parsers
# ---------------------------------------------------------------------------


def parse_rmd(text: str) -> dict[str, str]:
    """Parse an .Rmd file into sections keyed by heading.

    Strips YAML frontmatter (``---`` ... ``---``) and R code chunks.
    Splits on ``# `` or ``## `` markdown headers.
    """
    # Strip YAML frontmatter
    text = re.sub(r"^---\s*\n.*?\n---\s*\n", "", text, count=1, flags=re.DOTALL)
    # Strip R code chunks
    text = re.sub(r"```\{r[^}]*\}.*?```", "", text, flags=re.DOTALL)

    sections: dict[str, str] = {}
    current_heading = "Preamble"
    current_lines: list[str] = []

    for line in text.splitlines():
        m = re.match(r"^(#{1,2})\s+(.+)", line)
        if m:
            # Save previous section
            body = "\n".join(current_lines).strip()
            if body:
                sections[current_heading] = body
            current_heading = m.group(2).strip()
            current_lines = []
        else:
            current_lines.append(line)

    # Save last section
    body = "\n".join(current_lines).strip()
    if body:
        sections[current_heading] = body

    return sections


def parse_tex(text: str) -> dict[str, str]:
    r"""Parse a .tex file into sections keyed by ``\section{}`` title.

    Extracts ``\begin{abstract}...\end{abstract}`` as "Abstract".
    Strips LaTeX commands for cleaner text.
    """
    sections: dict[str, str] = {}

    # Extract abstract
    abstract_m = re.search(
        r"\\begin\{abstract\}(.*?)\\end\{abstract\}", text, re.DOTALL,
    )
    if abstract_m:
        sections["Abstract"] = _strip_latex(abstract_m.group(1).strip())

    # Split by \section{}
    parts = re.split(r"\\section\{([^}]+)\}", text)
    # parts = [preamble, title1, body1, title2, body2, ...]
    for i in range(1, len(parts), 2):
        title = parts[i].strip()
        body = parts[i + 1] if i + 1 < len(parts) else ""
        body = _strip_latex(body.strip())
        if body:
            sections[title] = body

    return sections


def _strip_latex(text: str) -> str:
    """Remove common LaTeX commands, leaving readable text."""
    # Remove \command{...} keeping content inside braces
    text = re.sub(r"\\(?:textbf|textit|emph|texttt|cite|citep|citet|ref|label)\{([^}]*)\}", r"\1", text)
    # Remove remaining \commands (no braces)
    text = re.sub(r"\\[a-zA-Z]+", "", text)
    # Remove braces
    text = re.sub(r"[{}]", "", text)
    # Collapse whitespace
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def parse_pdf(path: str | Path) -> dict[str, str]:
    """Extract full text from a PDF using pdfplumber.

    Returns a single section keyed as "Full Text".
    """
    pages: list[str] = []
    with pdfplumber.open(path) as pdf:
        for page in pdf.pages:
            page_text = page.extract_text()
            if page_text:
                pages.append(page_text)
    return {"Full Text": "\n".join(pages)}


def parse_file(path: str | Path) -> dict[str, str]:
    """Dispatch to the appropriate parser based on file extension."""
    path = Path(path)
    suffix = path.suffix.lower()
    if suffix == ".rmd":
        return parse_rmd(path.read_text(encoding="utf-8"))
    elif suffix == ".tex":
        return parse_tex(path.read_text(encoding="utf-8"))
    elif suffix == ".pdf":
        return parse_pdf(path)
    else:
        raise ValueError(f"Unsupported file type: {suffix}")


# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------


def count_words(text: str) -> int:
    """Count words in *text*."""
    return len(text.split())


def readability_metrics(text: str) -> dict[str, float]:
    """Compute Flesch RE, FK Grade, FOG, and SMOG for *text*."""
    return {
        "flesch_re": round(textstat.flesch_reading_ease(text), 1),
        "fk_grade": round(textstat.flesch_kincaid_grade(text), 1),
        "fog": round(textstat.gunning_fog(text), 1),
        "smog": round(textstat.smog_index(text), 1),
    }


def passive_voice_pct(text: str) -> float:
    """Return percentage of sentences that contain a passive-voice pattern."""
    sentences = _split_sentences(text)
    if not sentences:
        return 0.0

    def _has_passive(sentence: str) -> bool:
        for m in PASSIVE_RE.finditer(sentence):
            participle = m.group(1).lower()
            if participle not in PASSIVE_FALSE_POSITIVES:
                return True
        return False

    passive_count = sum(1 for s in sentences if _has_passive(s))
    return round(100.0 * passive_count / len(sentences), 1)


def nominalization_pct(text: str) -> float:
    """Return percentage of total words that are nominalizations (>5 chars + suffix)."""
    words = text.split()
    if not words:
        return 0.0
    long_words = [w.lower().rstrip(".,;:!?") for w in words if len(w) >= MIN_NOMINALIZATION_WORD_LEN]
    nom_count = sum(1 for w in long_words if w.endswith(NOMINALIZATION_SUFFIXES))
    return round(100.0 * nom_count / len(words), 1)


def hedging_pct(text: str) -> float:
    """Return percentage of words that are hedge words."""
    words = text.split()
    if not words:
        return 0.0
    hedge_count = sum(
        1 for w in words if w.lower().rstrip(".,;:!?") in HEDGE_WORDS
    )
    return round(100.0 * hedge_count / len(words), 1)


def style_metrics(text: str) -> dict[str, float]:
    """Compute style metrics: passive voice %, nominalization %, hedging %."""
    return {
        "passive_voice_pct": passive_voice_pct(text),
        "nominalization_pct": nominalization_pct(text),
        "hedging_pct": hedging_pct(text),
    }


def section_metrics(text: str) -> dict[str, Any]:
    """Compute all metrics for a section.

    Returns zeros if the section has fewer than MIN_WORDS_FOR_METRICS words.
    """
    wc = count_words(text)
    if wc < MIN_WORDS_FOR_METRICS:
        return {
            "word_count": wc,
            "flesch_re": 0.0,
            "fk_grade": 0.0,
            "fog": 0.0,
            "smog": 0.0,
            "passive_voice_pct": 0.0,
            "nominalization_pct": 0.0,
            "hedging_pct": 0.0,
        }
    return {
        "word_count": wc,
        **readability_metrics(text),
        **style_metrics(text),
    }


def aggregate_metrics(sections: dict[str, str]) -> dict[str, Any]:
    """Compute metrics over the concatenation of all sections."""
    full_text = "\n".join(sections.values())
    return section_metrics(full_text)


def _split_sentences(text: str) -> list[str]:
    """Naive sentence splitter on . ! ? boundaries."""
    return [s.strip() for s in re.split(r"[.!?]+", text) if s.strip()]


# ---------------------------------------------------------------------------
# Pangram integration
# ---------------------------------------------------------------------------


def classify_ai_score(score: float) -> str:
    """Classify a Pangram AI fraction into a human-readable category."""
    if score < 0.15:
        return "Human"
    elif score < 0.30:
        return "Collaborative"
    elif score < 0.70:
        return "Substantial AI"
    else:
        return "Primarily AI"


def pangram_score(text: str) -> dict[str, Any]:
    """Query the Pangram API and return score + category.

    Raises ImportError or runtime errors if the pangram SDK is not available
    or the API call fails.
    """
    from pangram import Pangram  # lazy import so --no-pangram works without SDK

    client = Pangram()
    result = client.predict(text)
    score = result.get("fraction_ai", 0.0)
    return {
        "score": round(score, 3),
        "category": classify_ai_score(score),
        "raw": result,
    }


def pangram_analysis(sections: dict[str, str]) -> dict[str, Any]:
    """Run Pangram on each section and on the aggregate."""
    full_text = "\n".join(sections.values())
    agg = pangram_score(full_text)
    per_section = {}
    for name, body in sections.items():
        if count_words(body) >= MIN_WORDS_FOR_METRICS:
            per_section[name] = pangram_score(body)
    return {
        "aggregate": agg["score"],
        "category": agg["category"],
        "sections": per_section,
    }


# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------


def run_audit(
    path: str | Path,
    use_pangram: bool = True,
) -> dict[str, Any]:
    """Run the full readability audit on *path* and return a result dict."""
    path = Path(path)
    sections = parse_file(path)

    per_section = {name: section_metrics(body) for name, body in sections.items()}
    agg = aggregate_metrics(sections)

    result: dict[str, Any] = {
        "file": path.name,
        "date": str(date.today()),
        "sections": per_section,
        "aggregate": agg,
    }

    if use_pangram:
        try:
            result["pangram"] = pangram_analysis(sections)
        except (ImportError, ConnectionError, RuntimeError, KeyError, ValueError) as exc:
            result["pangram"] = {"error": str(exc)}

    return result


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Readability & style audit for academic papers.",
    )
    parser.add_argument("file", help="Path to paper (.Rmd, .tex, or .pdf)")
    parser.add_argument(
        "--no-pangram",
        action="store_true",
        help="Skip Pangram AI-detection analysis",
    )
    args = parser.parse_args(argv)

    result = run_audit(args.file, use_pangram=not args.no_pangram)
    json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
