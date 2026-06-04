#!/usr/bin/env python3
"""Recover full body text for the eligible SciELO corpus.

This script scales the gold/pilot recovery workflow to the corpus-wide
eligible universe. It does not write to any ``fulltext_gold`` paths. The
eligible manifest is built from the raw article metadata and the exclusion
ledgers before any network request is made.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import csv
import hashlib
import importlib.util
import json
import logging
import sys
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import requests


PROJECT_DIR = Path(__file__).resolve().parent.parent
ARTICLE_METADATA = PROJECT_DIR / "data" / "raw" / "articles_2005_2025.csv"
EXCLUDED_JOURNALS = PROJECT_DIR / "data" / "processed" / "excluded_journals.csv"
EXCLUDED_ARTICLES = PROJECT_DIR / "data" / "processed" / "excluded_articles.csv"
ARTICLEMETA_DIR = PROJECT_DIR / "data" / "raw" / "api_responses" / "articles"

RAW_FULLTEXT_DIR = PROJECT_DIR / "data" / "raw" / "fulltext_corpus"
RAW_HTML_DIR = RAW_FULLTEXT_DIR / "html"
RAW_XML_DIR = RAW_FULLTEXT_DIR / "xml"
RAW_PDF_DIR = RAW_FULLTEXT_DIR / "pdf"
RAW_META_DIR = RAW_FULLTEXT_DIR / "metadata"
LOG_DIR = PROJECT_DIR / "data" / "raw" / "logs"

PROCESSED_DIR = PROJECT_DIR / "data" / "processed" / "fulltext_corpus"
OUTPUT_CSV = PROCESSED_DIR / "article_texts_corpus.csv"
MANIFEST_CSV = PROCESSED_DIR / "fulltext_corpus_manifest.csv"
FAILURE_QUEUE_CSV = PROCESSED_DIR / "fulltext_corpus_failure_queue.csv"

QUALITY_DIR = PROJECT_DIR / "quality_reports"
INVENTORY_CSV = QUALITY_DIR / "fulltext_corpus_inventory.csv"
REPORT_MD = QUALITY_DIR / "fulltext_corpus_recovery_report.md"

GOLD_SCRIPT = PROJECT_DIR / "scripts" / "13_recover_fulltext_gold.py"
EXPECTED_ELIGIBLE_N = 6672
MIN_BODY_CHARS = 3000
MIN_BODY_WORDS = 600
USER_AGENT = (
    "metodos_CP_fulltext_corpus/1.0 "
    "(academic reproducibility; SciELO fulltext recovery)"
)
ACCEPTED_SOURCE_METHODS = {
    "articlemeta_fulltexts_html",
    "citation_xml_body",
    "pdf_text_extraction",
}


def load_gold_recovery_module() -> Any:
    """Load the gold recovery script as a reusable extraction module."""

    spec = importlib.util.spec_from_file_location("fulltext_gold_recovery", GOLD_SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Não foi possível carregar {GOLD_SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


gold_recovery = load_gold_recovery_module()
csv.field_size_limit(sys.maxsize)


PROCESSED_FIELDNAMES = [
    "pid",
    "title",
    "title_en",
    "authors",
    "year",
    "issn",
    "journal_title",
    "doi",
    "document_type",
    "language",
    "body_text",
    "body_char_count",
    "body_word_count",
    "source_method",
    "source_url",
    "input_path",
    "input_hash",
    "retrieved_at",
    "abstract_char_count",
    "reference_tail_ratio",
    "validation_flags",
    "recovery_run_timestamp",
]

MANIFEST_FIELDNAMES = [
    "eligible_order",
    "pid",
    "title",
    "title_en",
    "authors",
    "year",
    "issn",
    "journal_title",
    "doi",
    "document_type",
    "expected_language",
    "articlemeta_json_path",
    "articlemeta_json_hash",
    "articlemeta_html_urls",
    "default_scielo_html_url",
    "doi_url",
    "articlemeta_pdf_urls",
    "raw_html_path",
    "raw_xml_path",
    "raw_pdf_path",
    "processed_output_path",
]

FAILURE_FIELDNAMES = [
    "pid",
    "title",
    "year",
    "issn",
    "journal_title",
    "document_type",
    "language",
    "attempt_count",
    "last_source_method",
    "last_source_url",
    "last_status",
    "last_reason",
    "failure_methods",
    "retry_status",
    "run_timestamp",
]

ATTEMPT_FIELDNAMES = [
    "pid",
    "source_method",
    "source_url",
    "status",
    "reason",
    "raw_path",
]

INVENTORY_FIELDNAMES = [
    "eligible_order",
    "pid",
    "title",
    "title_en",
    "authors",
    "year",
    "issn",
    "journal_title",
    "doi",
    "document_type",
    "language",
    "processed_present",
    "recovery_status",
    "source_method",
    "source_url",
    "input_path",
    "input_hash",
    "retrieved_at",
    "body_char_count",
    "body_word_count",
    "abstract_char_count",
    "reference_tail_ratio",
    "validation_flags",
    "failure_reason",
]

thread_local = threading.local()


def patch_gold_recovery_paths() -> None:
    """Redirect reusable gold functions to corpus-wide raw/output paths."""

    gold_recovery.RAW_FULLTEXT_DIR = RAW_FULLTEXT_DIR
    gold_recovery.RAW_HTML_DIR = RAW_HTML_DIR
    gold_recovery.RAW_XML_DIR = RAW_XML_DIR
    gold_recovery.RAW_PDF_DIR = RAW_PDF_DIR
    gold_recovery.RAW_META_DIR = RAW_META_DIR
    gold_recovery.LOG_DIR = LOG_DIR
    gold_recovery.USER_AGENT = USER_AGENT
    gold_recovery.is_reference_heading = corpus_is_reference_heading
    gold_recovery.html_candidate_urls = corpus_html_candidate_urls


def corpus_is_reference_heading(text: str) -> bool:
    """Return True only for bibliographic reference-section headings.

    The gold script intentionally used a broad starts-with rule. At corpus
    scale, that rule creates false positives for body sentences such as
    "Referências ao voto feminino..." or Spanish section headings such as
    "Referencias conceptuales...". Corpus recovery keeps generic
    "referencias/references" matches exact and only allows known bibliographic
    prefixes.
    """

    key = gold_recovery.normalize_key(text).strip()
    if not key:
        return False
    exact_headings = {
        gold_recovery.normalize_key(item)
        for item in {
            "referencias",
            "referências",
            "references",
            "bibliografia",
            "bibliography",
            "referencias bibliograficas",
            "referências bibliográficas",
            "referencias e notas",
            "referências e notas",
            "references and notes",
            "notes and references",
            "bibliographic references",
        }
    }
    if key in exact_headings:
        return True
    allowed_prefixes = (
        "referencias bibliograficas",
        "referencias e notas",
        "references and notes",
        "notes and references",
        "bibliographic references",
    )
    if gold_recovery.word_count(key) > 8 or len(key) > 100:
        return False
    return any(key.startswith(prefix) for prefix in allowed_prefixes)


def doi_candidate_url(metadata: dict[str, str]) -> str:
    """Return a DOI resolver URL when article metadata has a DOI."""

    doi = str(metadata.get("doi", "")).strip()
    if not doi:
        return ""
    if doi.lower().startswith("http://") or doi.lower().startswith("https://"):
        return doi
    if doi.lower().startswith("doi:"):
        doi = doi[4:].strip()
    if doi.startswith("10."):
        return f"https://doi.org/{doi}"
    return ""


def corpus_html_candidate_urls(
    pid: str,
    articlemeta: dict[str, Any],
    metadata: dict[str, str],
) -> list[str]:
    """Build HTML candidates, adding DOI redirect after SciELO PID URLs."""

    urls = gold_recovery.fulltext_urls(articlemeta, "html", metadata)
    urls.append(f"http://www.scielo.br/scielo.php?script=sci_arttext&pid={pid}")
    doi_url = doi_candidate_url(metadata)
    if doi_url:
        urls.append(doi_url)
    return gold_recovery.unique_preserve_order(urls)


def relative_path(path: Path) -> str:
    """Return a project-relative path string."""

    return str(path.relative_to(PROJECT_DIR))


def read_csv_rows(path: Path) -> list[dict[str, str]]:
    """Read a UTF-8 CSV as dictionaries."""

    with open(path, newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    """Write a CSV atomically using the gold helper."""

    gold_recovery.write_csv(path, rows, fieldnames)


def load_json(path: Path) -> dict[str, Any]:
    """Load a JSON object from disk."""

    with open(path, encoding="utf-8") as handle:
        payload = json.load(handle)
    return payload if isinstance(payload, dict) else {}


def is_true(value: str | None) -> bool:
    """Parse boolean-like CSV values used in exclusion ledgers."""

    return str(value or "").strip().lower() in {"true", "1", "yes", "y", "sim"}


def normalized(value: str | None) -> str:
    """Normalize text for ledger matching."""

    return gold_recovery.normalize_key(value or "")


def setup_logging(run_timestamp: str) -> logging.Logger:
    """Configure corpus recovery logging."""

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_path = LOG_DIR / f"fulltext_corpus_recovery_{run_timestamp}.log"
    logger = logging.getLogger("fulltext_corpus_recovery")
    logger.setLevel(logging.DEBUG)
    logger.handlers.clear()

    fmt = logging.Formatter(
        "%(asctime)s | %(levelname)-7s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    file_handler = logging.FileHandler(log_path, encoding="utf-8")
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(fmt)
    logger.addHandler(file_handler)

    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(fmt)
    logger.addHandler(console_handler)

    logger.info("Log salvo em: %s", log_path)
    return logger


def ensure_directories() -> None:
    """Create all corpus recovery directories."""

    for directory in [
        RAW_HTML_DIR,
        RAW_XML_DIR,
        RAW_PDF_DIR,
        RAW_META_DIR,
        LOG_DIR,
        PROCESSED_DIR,
        QUALITY_DIR,
    ]:
        directory.mkdir(parents=True, exist_ok=True)


def load_exclusion_ledgers() -> tuple[set[str], set[str], set[tuple[str, str]], set[str]]:
    """Load excluded journal and article keys."""

    excluded_titles: set[str] = set()
    excluded_issns: set[str] = set()
    excluded_pairs: set[tuple[str, str]] = set()
    for row in read_csv_rows(EXCLUDED_JOURNALS):
        if not is_true(row.get("exclude_from_analysis")):
            continue
        title_key = normalized(row.get("journal_title"))
        issn_key = normalized(row.get("issn"))
        if title_key:
            excluded_titles.add(title_key)
        if issn_key:
            excluded_issns.add(issn_key)
        if title_key and issn_key:
            excluded_pairs.add((title_key, issn_key))

    excluded_pids = {
        row["pid"]
        for row in read_csv_rows(EXCLUDED_ARTICLES)
        if is_true(row.get("exclude_from_analysis")) and row.get("pid")
    }
    return excluded_titles, excluded_issns, excluded_pairs, excluded_pids


def journal_is_excluded(
    row: dict[str, str],
    excluded_titles: set[str],
    excluded_issns: set[str],
    excluded_pairs: set[tuple[str, str]],
) -> bool:
    """Return True when an article belongs to an excluded journal."""

    title_key = normalized(row.get("journal_title"))
    issn_key = normalized(row.get("issn"))
    return (
        (title_key, issn_key) in excluded_pairs
        or bool(title_key and title_key in excluded_titles)
        or bool(issn_key and issn_key in excluded_issns)
    )


def articlemeta_path(pid: str) -> Path:
    """Return the cached ArticleMeta JSON path for a PID."""

    return ARTICLEMETA_DIR / f"{pid}.json"


def build_manifest_row(
    order: int,
    article: dict[str, str],
    articlemeta: dict[str, Any],
) -> dict[str, Any]:
    """Build one eligible manifest row."""

    pid = article["pid"]
    html_urls = gold_recovery.html_candidate_urls(pid, articlemeta, article)
    default_html = f"http://www.scielo.br/scielo.php?script=sci_arttext&pid={pid}"
    pdf_urls = gold_recovery.fulltext_urls(articlemeta, "pdf", article)
    metadata_path = articlemeta_path(pid)
    return {
        "eligible_order": order,
        "pid": pid,
        "title": article.get("title", ""),
        "title_en": article.get("title_en", ""),
        "authors": article.get("authors", ""),
        "year": article.get("year", ""),
        "issn": article.get("issn", ""),
        "journal_title": article.get("journal_title", ""),
        "doi": article.get("doi", ""),
        "document_type": article.get("document_type", ""),
        "expected_language": article.get("language", ""),
        "articlemeta_json_path": relative_path(metadata_path),
        "articlemeta_json_hash": gold_recovery.file_sha256(metadata_path),
        "articlemeta_html_urls": "|".join(html_urls),
        "default_scielo_html_url": default_html,
        "doi_url": doi_candidate_url(article),
        "articlemeta_pdf_urls": "|".join(pdf_urls),
        "raw_html_path": relative_path(gold_recovery.canonical_raw_path(RAW_HTML_DIR, pid, "html")),
        "raw_xml_path": relative_path(gold_recovery.canonical_raw_path(RAW_XML_DIR, pid, "xml")),
        "raw_pdf_path": relative_path(gold_recovery.canonical_raw_path(RAW_PDF_DIR, pid, "pdf")),
        "processed_output_path": relative_path(OUTPUT_CSV),
    }


def load_eligible_articles_and_manifest() -> tuple[
    list[dict[str, str]], list[dict[str, Any]], dict[str, Any]
]:
    """Build the eligible corpus and manifest from raw metadata and ledgers."""

    articles = read_csv_rows(ARTICLE_METADATA)
    excluded_titles, excluded_issns, excluded_pairs, excluded_pids = load_exclusion_ledgers()

    eligible_articles: list[dict[str, str]] = []
    summary = {
        "raw_records": len(articles),
        "excluded_journal_records": 0,
        "excluded_article_records": 0,
        "non_research_article_records": 0,
        "missing_articlemeta_records": 0,
    }

    for row in articles:
        is_excluded_journal = journal_is_excluded(
            row, excluded_titles, excluded_issns, excluded_pairs
        )
        is_excluded_article = row.get("pid") in excluded_pids
        is_research_article = row.get("document_type") == "research-article"

        summary["excluded_journal_records"] += int(is_excluded_journal)
        summary["excluded_article_records"] += int(is_excluded_article)
        summary["non_research_article_records"] += int(not is_research_article)

        if is_excluded_journal or is_excluded_article or not is_research_article:
            continue
        eligible_articles.append(row)

    pids = [row["pid"] for row in eligible_articles]
    duplicates = sorted({pid for pid in pids if pids.count(pid) > 1})
    if duplicates:
        raise ValueError(f"PIDs duplicados no manifest elegível: {duplicates[:20]}")

    manifest_rows: list[dict[str, Any]] = []
    for order, row in enumerate(eligible_articles, start=1):
        path = articlemeta_path(row["pid"])
        if not path.exists():
            summary["missing_articlemeta_records"] += 1
            continue
        articlemeta = gold_recovery.load_articlemeta(row["pid"])
        manifest_rows.append(build_manifest_row(order, row, articlemeta))

    if summary["missing_articlemeta_records"]:
        missing = [row["pid"] for row in eligible_articles if not articlemeta_path(row["pid"]).exists()]
        raise FileNotFoundError(
            "ArticleMeta JSON ausente para PIDs elegíveis: "
            + ", ".join(missing[:20])
        )

    summary["eligible_records"] = len(eligible_articles)
    summary["manifest_records"] = len(manifest_rows)
    return eligible_articles, manifest_rows, summary


def get_thread_session() -> requests.Session:
    """Return one HTTP session per worker thread."""

    session = getattr(thread_local, "session", None)
    if session is None:
        session = gold_recovery.create_session()
        thread_local.session = session
    return session


def to_int(value: Any, default: int = 0) -> int:
    """Parse integer-like CSV fields."""

    try:
        return int(float(str(value)))
    except (TypeError, ValueError):
        return default


def raw_hash_matches(row: dict[str, Any]) -> bool:
    """Check that a processed row still points to the same raw input."""

    input_path = str(row.get("input_path", "")).strip()
    input_hash = str(row.get("input_hash", "")).strip()
    if not input_path.startswith("data/raw/fulltext_corpus/"):
        return False
    if not input_hash or len(input_hash) != 64:
        return False
    raw_path = PROJECT_DIR / input_path
    return raw_path.exists() and gold_recovery.file_sha256(raw_path) == input_hash


def processed_row_valid_for_resume(
    row: dict[str, Any],
    metadata: dict[str, str],
) -> bool:
    """Return True if an existing processed row can be safely skipped."""

    body_text = str(row.get("body_text", ""))
    if not gold_recovery.normalize_space(body_text):
        return False
    if str(row.get("source_method", "")).strip() not in ACCEPTED_SOURCE_METHODS:
        return False
    if not str(row.get("source_url", "")).strip():
        return False
    if str(row.get("validation_flags", "")).strip():
        return False
    if to_int(row.get("body_char_count")) != len(body_text):
        return False
    if to_int(row.get("body_word_count")) != gold_recovery.word_count(body_text):
        return False
    if len(body_text) < MIN_BODY_CHARS or gold_recovery.word_count(body_text) < MIN_BODY_WORDS:
        return False
    abstract_text = gold_recovery.article_abstract(metadata)
    if gold_recovery.validation_flags(body_text, abstract_text):
        return False
    return raw_hash_matches(row)


def load_existing_resume_rows(
    eligible_articles: list[dict[str, str]],
    logger: logging.Logger,
) -> dict[str, dict[str, Any]]:
    """Load valid processed rows for online resume mode."""

    if not OUTPUT_CSV.exists():
        return {}
    metadata_by_pid = {row["pid"]: row for row in eligible_articles}
    valid_rows: dict[str, dict[str, Any]] = {}
    for row in read_csv_rows(OUTPUT_CSV):
        pid = row.get("pid", "")
        metadata = metadata_by_pid.get(pid)
        if metadata is None:
            continue
        if processed_row_valid_for_resume(row, metadata):
            row = {field: row.get(field, "") for field in PROCESSED_FIELDNAMES}
            if not row.get("recovery_run_timestamp"):
                row["recovery_run_timestamp"] = "resume_from_existing_output"
            valid_rows[pid] = row

    logger.info(
        "Resume habilitado: %d linhas processadas válidas serão preservadas",
        len(valid_rows),
    )
    return valid_rows


def processed_row(
    pid: str,
    metadata: dict[str, str],
    result: Any,
    run_timestamp: str,
) -> dict[str, Any]:
    """Build one corpus processed row with raw provenance."""

    row = gold_recovery.processed_row(pid, metadata, result)
    original_provenance = provenance_from_sidecar(result)
    row["source_url"] = original_provenance["source_url"]
    row["retrieved_at"] = original_provenance["retrieved_at"]
    row["input_path"] = relative_path(result.input_path)
    row["recovery_run_timestamp"] = run_timestamp
    return {field: row.get(field, "") for field in PROCESSED_FIELDNAMES}


def summarize_attempts(attempts: list[dict[str, str]]) -> str:
    """Collapse method-specific attempts into a retry-queue summary."""

    if not attempts:
        return "no_attempts_recorded"
    pieces = []
    for attempt in attempts:
        pieces.append(
            "{method}:{status}:{reason}".format(
                method=attempt.get("source_method", ""),
                status=attempt.get("status", ""),
                reason=str(attempt.get("reason", ""))[:220],
            )
        )
    return " | ".join(pieces)[:4000]


def body_text_hash(row: dict[str, Any]) -> str:
    """Return a stable SHA-256 hash for a processed body text."""

    return hashlib.sha256(str(row.get("body_text", "")).encode("utf-8")).hexdigest()


def duplicate_processed_pids(
    processed_by_pid: dict[str, dict[str, Any]],
) -> set[str]:
    """Return PIDs whose raw hash or body hash is reused by another PID."""

    input_hash_to_pids: dict[str, list[str]] = {}
    body_hash_to_pids: dict[str, list[str]] = {}
    for pid, row in processed_by_pid.items():
        input_hash = str(row.get("input_hash", "")).strip()
        if input_hash:
            input_hash_to_pids.setdefault(input_hash, []).append(pid)
        body_hash = body_text_hash(row)
        if row.get("body_text"):
            body_hash_to_pids.setdefault(body_hash, []).append(pid)

    duplicate_pids: set[str] = set()
    for pid_list in input_hash_to_pids.values():
        if len(pid_list) > 1:
            duplicate_pids.update(pid_list)
    for pid_list in body_hash_to_pids.values():
        if len(pid_list) > 1:
            duplicate_pids.update(pid_list)
    return duplicate_pids


def move_duplicate_processed_rows_to_failures(
    processed_by_pid: dict[str, dict[str, Any]],
    failures_by_pid: dict[str, dict[str, Any]],
    metadata_by_pid: dict[str, dict[str, str]],
    run_timestamp: str,
) -> None:
    """Move duplicated raw/body rows from processed output to retry queue."""

    for pid in sorted(duplicate_processed_pids(processed_by_pid)):
        row = processed_by_pid.pop(pid)
        attempts = [
            {
                "pid": pid,
                "source_method": str(row.get("source_method", "")),
                "source_url": str(row.get("source_url", "")),
                "status": "invalid",
                "reason": "duplicate_input_hash_or_body_hash_across_pids",
                "raw_path": str(row.get("input_path", "")),
            }
        ]
        failures_by_pid[pid] = failure_row(
            metadata_by_pid[pid],
            attempts,
            run_timestamp,
        )


def failure_row(
    metadata: dict[str, str],
    attempts: list[dict[str, str]],
    run_timestamp: str,
) -> dict[str, Any]:
    """Build one retry-queue row for a failed PID."""

    last = substantive_last_attempt(attempts)
    return {
        "pid": metadata.get("pid", ""),
        "title": metadata.get("title", ""),
        "year": metadata.get("year", ""),
        "issn": metadata.get("issn", ""),
        "journal_title": metadata.get("journal_title", ""),
        "document_type": metadata.get("document_type", ""),
        "language": metadata.get("language", ""),
        "attempt_count": len(attempts),
        "last_source_method": last.get("source_method", ""),
        "last_source_url": last.get("source_url", ""),
        "last_status": last.get("status", "not_attempted"),
        "last_reason": last.get("reason", "no_attempts_recorded"),
        "failure_methods": summarize_attempts(attempts),
        "retry_status": "pending",
        "run_timestamp": run_timestamp,
    }


def substantive_last_attempt(attempts: list[dict[str, str]]) -> dict[str, str]:
    """Return the last method attempt that has a substantive diagnostic."""

    for attempt in reversed(attempts):
        if attempt.get("status") == "skipped" and attempt.get("reason") == "offline_no_cache":
            continue
        return attempt
    return attempts[-1] if attempts else {}


def sidecar_for_raw_path(raw_path: Path) -> dict[str, Any]:
    """Return sidecar metadata for a raw input, inferring canonical copies by hash."""

    direct = RAW_META_DIR / f"{raw_path.name}.json"
    if direct.exists():
        return load_json(direct)
    if not raw_path.exists():
        return {}

    raw_hash = gold_recovery.file_sha256(raw_path)
    pid = raw_path.stem
    if "_" in pid:
        pid = pid.split("_", 1)[0]
    for sidecar in sorted(RAW_META_DIR.glob(f"{pid}_*.{raw_path.suffix.lstrip('.')}.json")):
        payload = load_json(sidecar)
        if payload.get("sha256") == raw_hash:
            return payload
    return {}


def provenance_from_sidecar(result: Any) -> dict[str, str]:
    """Return original source provenance for a recovered raw input when available."""

    payload = sidecar_for_raw_path(result.input_path)
    return {
        "source_url": str(payload.get("final_url") or payload.get("source_url") or result.source_url),
        "retrieved_at": str(payload.get("retrieved_at") or result.retrieved_at),
    }


def recover_task(
    pid: str,
    metadata: dict[str, str],
    rate_limit: float,
    offline: bool,
    logger: logging.Logger,
) -> tuple[str, Any | None, list[dict[str, str]]]:
    """Recover one PID in a worker thread."""

    try:
        result, attempts = gold_recovery.recover_one_pid(
            pid=pid,
            metadata=metadata,
            session=get_thread_session(),
            rate_limit=rate_limit,
            offline=offline,
            logger=logger,
        )
        return pid, result, attempts
    except Exception as exc:  # pragma: no cover - defensive recovery guard.
        return pid, None, [
            {
                "pid": pid,
                "source_method": "recovery_exception",
                "source_url": "",
                "status": "exception",
                "reason": repr(exc),
                "raw_path": "",
            }
        ]


def ordered_processed_rows(
    manifest_rows: list[dict[str, Any]],
    processed_by_pid: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    """Return processed rows in manifest order."""

    return [
        processed_by_pid[row["pid"]]
        for row in manifest_rows
        if row["pid"] in processed_by_pid
    ]


def ordered_failure_rows(
    manifest_rows: list[dict[str, Any]],
    failures_by_pid: dict[str, dict[str, Any]],
    processed_by_pid: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    """Return unresolved failure rows in manifest order."""

    return [
        failures_by_pid[row["pid"]]
        for row in manifest_rows
        if row["pid"] in failures_by_pid and row["pid"] not in processed_by_pid
    ]


def write_attempt_log(path: Path, attempts: list[dict[str, str]]) -> None:
    """Write the timestamped attempt log."""

    write_csv(path, attempts, ATTEMPT_FIELDNAMES)


def write_inventory_and_report(
    manifest_rows: list[dict[str, Any]],
    processed_by_pid: dict[str, dict[str, Any]],
    failures_by_pid: dict[str, dict[str, Any]],
    summary: dict[str, Any],
    run_timestamp: str,
    args: argparse.Namespace,
) -> None:
    """Write recovery inventory and Markdown report."""

    inventory_rows = []
    for manifest in manifest_rows:
        pid = manifest["pid"]
        processed = processed_by_pid.get(pid, {})
        failure = failures_by_pid.get(pid, {})
        processed_present = bool(processed)
        inventory_rows.append(
            {
                "eligible_order": manifest["eligible_order"],
                "pid": pid,
                "title": manifest.get("title", ""),
                "title_en": manifest.get("title_en", ""),
                "authors": manifest.get("authors", ""),
                "year": manifest.get("year", ""),
                "issn": manifest.get("issn", ""),
                "journal_title": manifest.get("journal_title", ""),
                "doi": manifest.get("doi", ""),
                "document_type": manifest.get("document_type", ""),
                "language": manifest.get("expected_language", ""),
                "processed_present": processed_present,
                "recovery_status": "recovered" if processed_present else "pending_retry",
                "source_method": processed.get("source_method", ""),
                "source_url": processed.get("source_url", ""),
                "input_path": processed.get("input_path", ""),
                "input_hash": processed.get("input_hash", ""),
                "retrieved_at": processed.get("retrieved_at", ""),
                "body_char_count": processed.get("body_char_count", ""),
                "body_word_count": processed.get("body_word_count", ""),
                "abstract_char_count": processed.get("abstract_char_count", ""),
                "reference_tail_ratio": processed.get("reference_tail_ratio", ""),
                "validation_flags": processed.get("validation_flags", ""),
                "failure_reason": failure.get("last_reason", ""),
            }
        )
    write_csv(INVENTORY_CSV, inventory_rows, INVENTORY_FIELDNAMES)

    method_counts: dict[str, int] = {}
    for row in processed_by_pid.values():
        method = row.get("source_method", "")
        method_counts[method] = method_counts.get(method, 0) + 1
    method_lines = [
        f"- {method}: {count}"
        for method, count in sorted(method_counts.items(), key=lambda item: (-item[1], item[0]))
    ] or ["_No recovered bodies yet._"]

    failures = ordered_failure_rows(manifest_rows, failures_by_pid, processed_by_pid)
    failure_lines = [
        f"- `{row['pid']}` ({row['journal_title']}, {row['year']}): {row['last_reason']}"
        for row in failures[:75]
    ]
    if len(failures) > 75:
        failure_lines.append(
            f"- ... {len(failures) - 75} additional pending PIDs in `{relative_path(FAILURE_QUEUE_CSV)}`"
        )
    if not failure_lines:
        failure_lines = ["None."]

    report_lines = [
        "# Fulltext corpus recovery report",
        "",
        f"Generated at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S %Z')}",
        "",
        "## Summary",
        "",
        f"- Raw SciELO records: {summary.get('raw_records', '')}",
        f"- Eligible records after exclusions and research-article filter: {len(manifest_rows)}",
        f"- Expected eligible records from scaling plan: {EXPECTED_ELIGIBLE_N}",
        f"- Rows in processed corpus CSV: {len(processed_by_pid)}",
        f"- Pending failure queue rows: {len(failures)}",
        f"- Offline mode: {args.offline}",
        f"- Workers: {args.workers}",
        f"- Batch size: {args.batch_size}",
        f"- Rate limit per worker: {args.rate_limit} seconds",
        "",
        "## Exclusion Inputs",
        "",
        f"- Excluded journal ledger: `{relative_path(EXCLUDED_JOURNALS)}`",
        f"- Excluded article ledger: `{relative_path(EXCLUDED_ARTICLES)}`",
        f"- Records belonging to excluded journals: {summary.get('excluded_journal_records', '')}",
        f"- Records listed in excluded-article ledger: {summary.get('excluded_article_records', '')}",
        f"- Non-`research-article` records: {summary.get('non_research_article_records', '')}",
        "",
        "## Recovery Methods",
        "",
        *method_lines,
        "",
        "## Pending Failures",
        "",
        *failure_lines,
        "",
        "## Source Order",
        "",
        "1. ArticleMeta `fulltexts.html` URLs.",
        "2. SciELO HTML body sections with `data-anchor=\"Text\"` or `data-anchor=\"Texto\"`.",
        "3. `citation_xml_url`, only when the XML contains a real `<body>`.",
        "4. SciELO PDF fallback, with text extracted from the preserved PDF.",
        "",
        "## Outputs",
        "",
        f"- Manifest: `{relative_path(MANIFEST_CSV)}`",
        f"- Processed body text: `{relative_path(OUTPUT_CSV)}`",
        f"- Failure queue: `{relative_path(FAILURE_QUEUE_CSV)}`",
        f"- Inventory: `{relative_path(INVENTORY_CSV)}`",
        f"- Raw cache: `{relative_path(RAW_FULLTEXT_DIR)}/`",
        f"- Run timestamp: `{run_timestamp}`",
    ]
    REPORT_MD.write_text("\n".join(report_lines) + "\n", encoding="utf-8")


def write_run_outputs(
    manifest_rows: list[dict[str, Any]],
    processed_by_pid: dict[str, dict[str, Any]],
    failures_by_pid: dict[str, dict[str, Any]],
    summary: dict[str, Any],
    run_timestamp: str,
    args: argparse.Namespace,
    attempt_log_path: Path,
    attempts: list[dict[str, str]],
    output_csv: Path,
    failure_queue_csv: Path,
) -> None:
    """Write processed rows, failures, attempt logs, inventory and report."""

    write_csv(output_csv, ordered_processed_rows(manifest_rows, processed_by_pid), PROCESSED_FIELDNAMES)
    write_csv(
        failure_queue_csv,
        ordered_failure_rows(manifest_rows, failures_by_pid, processed_by_pid),
        FAILURE_FIELDNAMES,
    )
    write_attempt_log(attempt_log_path, attempts)
    if output_csv == OUTPUT_CSV:
        write_inventory_and_report(
            manifest_rows=manifest_rows,
            processed_by_pid=processed_by_pid,
            failures_by_pid=failures_by_pid,
            summary=summary,
            run_timestamp=run_timestamp,
            args=args,
        )


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description="Recover full body text for the eligible SciELO corpus."
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=4,
        help="Number of PID-level workers (default: 4).",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=250,
        help="PIDs per checkpointed batch (default: 250).",
    )
    parser.add_argument(
        "--rate-limit",
        type=float,
        default=0.35,
        help="Seconds to sleep after each HTTP request per worker (default: 0.35).",
    )
    parser.add_argument(
        "--offline",
        action="store_true",
        help="Use only preserved raw files and reconstruct the processed CSV.",
    )
    parser.add_argument(
        "--allow-partial",
        action="store_true",
        help="Exit zero even if some eligible PIDs remain in the failure queue.",
    )
    parser.add_argument(
        "--pid",
        action="append",
        help="Recover only the specified eligible PID(s) into timestamped debug outputs.",
    )
    return parser.parse_args()


def main() -> int:
    """Run corpus-wide fulltext recovery."""

    args = parse_args()
    if args.workers < 1:
        raise ValueError("--workers deve ser pelo menos 1")
    if args.batch_size < 1:
        raise ValueError("--batch-size deve ser pelo menos 1")
    if args.rate_limit < 0:
        raise ValueError("--rate-limit não pode ser negativo")

    patch_gold_recovery_paths()
    ensure_directories()
    run_timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    logger = setup_logging(run_timestamp)
    attempt_log_path = LOG_DIR / f"fulltext_corpus_recovery_attempts_{run_timestamp}.csv"

    eligible_articles, manifest_rows, summary = load_eligible_articles_and_manifest()
    write_csv(MANIFEST_CSV, manifest_rows, MANIFEST_FIELDNAMES)
    logger.info("Manifest elegível salvo em: %s", MANIFEST_CSV)
    logger.info("Corpus elegível: %d PIDs", len(manifest_rows))
    if len(manifest_rows) != EXPECTED_ELIGIBLE_N:
        raise ValueError(
            "Manifest elegível tem "
            f"{len(manifest_rows)} PIDs; plano esperava {EXPECTED_ELIGIBLE_N}."
        )

    is_debug_subset = bool(args.pid)
    if args.pid:
        requested = set(args.pid)
        eligible_pid_set = {row["pid"] for row in eligible_articles}
        missing_requested = sorted(requested - eligible_pid_set)
        if missing_requested:
            raise ValueError(f"PIDs solicitados fora do corpus elegível: {missing_requested}")
        eligible_articles = [row for row in eligible_articles if row["pid"] in requested]
        manifest_rows = [row for row in manifest_rows if row["pid"] in requested]

    output_csv = OUTPUT_CSV
    failure_queue_csv = FAILURE_QUEUE_CSV
    if is_debug_subset:
        output_csv = PROCESSED_DIR / f"article_texts_corpus_debug_{run_timestamp}.csv"
        failure_queue_csv = PROCESSED_DIR / f"fulltext_corpus_failure_queue_debug_{run_timestamp}.csv"

    metadata_by_pid = {row["pid"]: row for row in eligible_articles}
    if args.offline:
        processed_by_pid: dict[str, dict[str, Any]] = {}
        logger.info("Modo offline: reconstruindo CSV apenas a partir dos brutos preservados")
    elif is_debug_subset:
        processed_by_pid = {}
        logger.info("Subset debug: CSV canônico preservado")
    else:
        processed_by_pid = load_existing_resume_rows(eligible_articles, logger)

    failures_by_pid: dict[str, dict[str, Any]] = {}
    all_attempts: list[dict[str, str]] = []
    pids_to_process = [
        row["pid"]
        for row in manifest_rows
        if row["pid"] not in processed_by_pid
    ]
    logger.info("PIDs a processar nesta execução: %d", len(pids_to_process))

    total_batches = (len(pids_to_process) + args.batch_size - 1) // args.batch_size
    for batch_index, start in enumerate(range(0, len(pids_to_process), args.batch_size), start=1):
        batch_pids = pids_to_process[start : start + args.batch_size]
        logger.info(
            "Batch %d/%d: processando %d PIDs",
            batch_index,
            total_batches,
            len(batch_pids),
        )
        batch_failures = 0
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
            futures = {
                executor.submit(
                    recover_task,
                    pid,
                    metadata_by_pid[pid],
                    args.rate_limit,
                    args.offline,
                    logger,
                ): pid
                for pid in batch_pids
            }
            for future in concurrent.futures.as_completed(futures):
                pid, result, attempts = future.result()
                all_attempts.extend(attempts)
                metadata = metadata_by_pid[pid]
                if result is None:
                    failures_by_pid[pid] = failure_row(metadata, attempts, run_timestamp)
                    batch_failures += 1
                    continue
                processed_by_pid[pid] = processed_row(pid, metadata, result, run_timestamp)
                failures_by_pid.pop(pid, None)

        write_run_outputs(
            manifest_rows=manifest_rows,
            processed_by_pid=processed_by_pid,
            failures_by_pid=failures_by_pid,
            summary=summary,
            run_timestamp=run_timestamp,
            args=args,
            attempt_log_path=attempt_log_path,
            attempts=all_attempts,
            output_csv=output_csv,
            failure_queue_csv=failure_queue_csv,
        )
        logger.info(
            "Batch %d/%d concluído: %d recuperados acumulados, %d falhas no batch",
            batch_index,
            total_batches,
            len(processed_by_pid),
            batch_failures,
        )

    for row in manifest_rows:
        pid = row["pid"]
        if pid not in processed_by_pid and pid not in failures_by_pid:
            failures_by_pid[pid] = failure_row(metadata_by_pid[pid], [], run_timestamp)

    move_duplicate_processed_rows_to_failures(
        processed_by_pid=processed_by_pid,
        failures_by_pid=failures_by_pid,
        metadata_by_pid=metadata_by_pid,
        run_timestamp=run_timestamp,
    )

    write_run_outputs(
        manifest_rows=manifest_rows,
        processed_by_pid=processed_by_pid,
        failures_by_pid=failures_by_pid,
        summary=summary,
        run_timestamp=run_timestamp,
        args=args,
        attempt_log_path=attempt_log_path,
        attempts=all_attempts,
        output_csv=output_csv,
        failure_queue_csv=failure_queue_csv,
    )

    failure_count = len(ordered_failure_rows(manifest_rows, failures_by_pid, processed_by_pid))
    logger.info("CSV processado salvo em: %s", output_csv)
    logger.info("Fila de falhas salva em: %s", failure_queue_csv)
    logger.info("Log de tentativas salvo em: %s", attempt_log_path)

    if failure_count:
        logger.error(
            "Recuperação incompleta: %d/%d PIDs recuperados; %d na fila de falhas",
            len(processed_by_pid),
            len(manifest_rows),
            failure_count,
        )
        if not args.allow_partial:
            return 1

    logger.info("Recuperação completa: %d/%d", len(processed_by_pid), len(manifest_rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
