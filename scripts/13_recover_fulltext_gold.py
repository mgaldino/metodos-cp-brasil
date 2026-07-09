#!/usr/bin/env python3
"""Recover full body text for the 175 SciELO gold/pilot articles.

Sources are tried per PID in this order:
1. ArticleMeta ``fulltexts.html`` URLs cached in
   ``data/raw/api_responses/articles/{pid}.json``.
2. SciELO HTML article sections with ``data-anchor="Text"`` or
   ``data-anchor="Texto"``.
3. ``citation_xml_url`` from the SciELO HTML, only when the XML contains a
   real ``<body>``.
4. SciELO PDF fallback, with text extraction from the downloaded PDF.

Raw files are preserved under ``data/raw/fulltext_gold/`` and are never
overwritten by default. The processed CSV is written to
``data/processed/fulltext_gold/article_texts_gold.csv``.
"""

from __future__ import annotations

import argparse
import copy
import csv
import hashlib
import json
import logging
import re
import tempfile
import time
import unicodedata
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse

import requests
from lxml import etree
from lxml import html as lxml_html
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

try:
    import pdfplumber
except ImportError:  # pragma: no cover - handled at runtime for PDF fallback.
    pdfplumber = None


PROJECT_DIR = Path(__file__).resolve().parent.parent
GOLD_CLASSIFICATIONS = (
    PROJECT_DIR / "data" / "processed" / "classifications_llm_main_analysis.csv"
)
ARTICLE_METADATA = PROJECT_DIR / "data" / "raw" / "articles_2005_2025.csv"
ARTICLEMETA_DIR = PROJECT_DIR / "data" / "raw" / "api_responses" / "articles"

RAW_FULLTEXT_DIR = PROJECT_DIR / "data" / "raw" / "fulltext_gold"
RAW_HTML_DIR = RAW_FULLTEXT_DIR / "html"
RAW_XML_DIR = RAW_FULLTEXT_DIR / "xml"
RAW_PDF_DIR = RAW_FULLTEXT_DIR / "pdf"
RAW_META_DIR = RAW_FULLTEXT_DIR / "metadata"
LOG_DIR = PROJECT_DIR / "data" / "raw" / "logs"
PROCESSED_DIR = PROJECT_DIR / "data" / "processed" / "fulltext_gold"
OUTPUT_CSV = PROCESSED_DIR / "article_texts_gold.csv"

EXPECTED_GOLD_N = 175
MIN_BODY_CHARS = 3000
MIN_BODY_WORDS = 600
HTTP_TIMEOUT = 45
USER_AGENT = (
    "metodos_CP_fulltext_gold/1.0 "
    "(academic reproducibility; SciELO fulltext recovery)"
)

HTML_TEXT_ANCHORS = ("Text", "Texto")
LANGUAGE_FALLBACK_ORDER = ("pt", "en", "es", "fr")
REFERENCE_HEADINGS = {
    "referencias",
    "referencias bibliograficas",
    "referencias bibliográficas",
    "referencias e notas",
    "referências e notas",
    "references",
    "references and notes",
    "notes and references",
    "bibliografia",
    "bibliography",
    "bibliographic references",
    "referencias bibliograficas",
    "referencias bibliograficas",
}
ABSTRACT_LABELS = {
    "abstract",
    "resumo",
    "resumos",
    "resumen",
    "resumenes",
    "resume",
    "resumé",
    "résumé",
    "resumes",
}
KEYWORD_MARKERS = (
    "keywords",
    "key words",
    "palavras-chave",
    "palavras chave",
    "palabra clave",
    "palabras clave",
    "mots-clés",
    "mots-clé",
    "mots cles",
    "mots cle",
    "mots-clefs",
    "descritores",
)


@dataclass
class ExtractionResult:
    """Body extraction result from one raw input."""

    body_text: str
    source_method: str
    source_url: str
    input_path: Path
    input_hash: str
    retrieved_at: str
    flags: list[str]
    body_char_count: int
    body_word_count: int
    abstract_char_count: int
    reference_tail_ratio: float


def setup_logging(run_timestamp: str) -> logging.Logger:
    """Configure file and console logging."""

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_path = LOG_DIR / f"fulltext_gold_recovery_{run_timestamp}.log"
    logger = logging.getLogger("fulltext_gold_recovery")
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


def create_session() -> requests.Session:
    """Create an HTTP session with retry/backoff."""

    session = requests.Session()
    session.headers.update({"User-Agent": USER_AGENT})
    retries = Retry(
        total=4,
        connect=4,
        read=4,
        backoff_factor=1.2,
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=("GET", "HEAD"),
    )
    adapter = HTTPAdapter(max_retries=retries)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session


def atomic_write_bytes(path: Path, data: bytes) -> None:
    """Write bytes atomically."""

    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(dir=path.parent, prefix=path.stem, suffix=".tmp")
    tmp_path = Path(tmp_name)
    try:
        with open(fd, "wb") as handle:
            handle.write(data)
        tmp_path.replace(path)
    except BaseException:
        tmp_path.unlink(missing_ok=True)
        raise


def atomic_write_text(path: Path, data: str) -> None:
    """Write UTF-8 text atomically."""

    atomic_write_bytes(path, data.encode("utf-8"))


def save_raw_if_missing(path: Path, data: bytes) -> bool:
    """Save raw input unless it already exists.

    Returns ``True`` when the file was written and ``False`` when an existing
    cache file was preserved.
    """

    if path.exists():
        return False
    atomic_write_bytes(path, data)
    return True


def url_digest(url: str) -> str:
    """Return a short stable digest for a source URL."""

    return hashlib.sha256(url.encode("utf-8")).hexdigest()[:12]


def candidate_raw_path(directory: Path, pid: str, suffix: str, url: str) -> Path:
    """Return a URL-specific cache path for one raw source candidate."""

    return directory / f"{pid}_{url_digest(url)}.{suffix}"


def canonical_raw_path(directory: Path, pid: str, suffix: str) -> Path:
    """Return the canonical raw path requested for the accepted PID source."""

    return directory / f"{pid}.{suffix}"


def write_raw_sidecar(
    raw_path: Path,
    source_url: str,
    final_url: str,
    content_type: str,
    retrieved_at: str,
) -> None:
    """Write sidecar metadata for a fetched raw file."""

    sidecar = RAW_META_DIR / f"{raw_path.name}.json"
    if sidecar.exists():
        return
    payload = {
        "raw_path": str(raw_path.relative_to(PROJECT_DIR)),
        "source_url": source_url,
        "final_url": final_url,
        "content_type": content_type,
        "retrieved_at": retrieved_at,
        "sha256": file_sha256(raw_path),
    }
    atomic_write_text(sidecar, json.dumps(payload, ensure_ascii=False, indent=2))


def file_sha256(path: Path) -> str:
    """Return SHA-256 hash for a local file."""

    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_csv_rows(path: Path) -> list[dict[str, str]]:
    """Read a CSV as a list of dictionaries."""

    with open(path, newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def load_gold_pids() -> list[str]:
    """Load and validate the 175 gold PIDs."""

    rows = read_csv_rows(GOLD_CLASSIFICATIONS)
    pids = [row["pid"] for row in rows]
    if len(pids) != EXPECTED_GOLD_N:
        raise ValueError(
            f"Esperava {EXPECTED_GOLD_N} PIDs em {GOLD_CLASSIFICATIONS}, "
            f"mas encontrei {len(pids)}."
        )
    duplicates = sorted({pid for pid in pids if pids.count(pid) > 1})
    if duplicates:
        raise ValueError(f"PIDs duplicados no gold: {duplicates}")
    return pids


def load_metadata_by_pid() -> dict[str, dict[str, str]]:
    """Load bibliographic metadata from the raw article CSV."""

    return {row["pid"]: row for row in read_csv_rows(ARTICLE_METADATA)}


def load_articlemeta(pid: str) -> dict[str, Any]:
    """Load a cached ArticleMeta JSON for one PID."""

    path = ARTICLEMETA_DIR / f"{pid}.json"
    if not path.exists():
        raise FileNotFoundError(f"ArticleMeta JSON ausente: {path}")
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def normalize_space(text: str | None) -> str:
    """Normalize whitespace in a string."""

    if not text:
        return ""
    return re.sub(r"\s+", " ", text.replace("\xa0", " ")).strip()


def normalize_key(text: str | None) -> str:
    """Normalize text for accent-insensitive comparisons."""

    text = normalize_space(text).lower()
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return normalize_space(text)


def word_count(text: str) -> int:
    """Count words in Portuguese/English/Spanish/French text."""

    return len(re.findall(r"[A-Za-zÀ-ÖØ-öø-ÿ0-9]+", text))


def metadata_title_candidates(metadata: dict[str, str]) -> list[str]:
    """Return local title metadata useful for front-matter removal."""

    return [
        value
        for value in [metadata.get("title", ""), metadata.get("title_en", "")]
        if normalize_space(value)
    ]


def metadata_author_candidates(metadata: dict[str, str]) -> list[str]:
    """Return local author metadata useful for front-matter removal."""

    authors = normalize_space(metadata.get("authors", ""))
    if not authors:
        return []
    pieces = [authors]
    pieces.extend(re.split(r"\s*(?:\||;)\s*", authors))
    return [piece for piece in pieces if normalize_space(piece)]


def longest_text(values: list[str]) -> str:
    """Return the longest non-empty string from a list."""

    clean = [normalize_space(value) for value in values if normalize_space(value)]
    return max(clean, key=len) if clean else ""


def article_abstract(metadata: dict[str, str], extra_abstracts: list[str] | None = None) -> str:
    """Return the longest available abstract for a PID."""

    values = [
        metadata.get("abstract_pt", ""),
        metadata.get("abstract_en", ""),
    ]
    if extra_abstracts:
        values.extend(extra_abstracts)
    return longest_text(values)


def language_priority(metadata: dict[str, str], available: list[str]) -> list[str]:
    """Order available languages, preferring the article metadata language."""

    raw_language = normalize_space(metadata.get("language", "")).lower()
    preferred = []
    for token in re.split(r"[,;/\s]+", raw_language):
        token = token.strip().lower()
        if token:
            preferred.append(token[:2])
    preferred.extend(LANGUAGE_FALLBACK_ORDER)
    preferred.extend(sorted(available))

    ordered = []
    for lang in preferred:
        if lang in available and lang not in ordered:
            ordered.append(lang)
    return ordered


def fulltext_urls(articlemeta: dict[str, Any], kind: str, metadata: dict[str, str]) -> list[str]:
    """Extract fulltext URLs from ArticleMeta for ``html`` or ``pdf``."""

    fulltexts = articlemeta.get("fulltexts") or {}
    values = fulltexts.get(kind) or {}
    if isinstance(values, str):
        return [values]
    if not isinstance(values, dict):
        return []

    ordered_urls = []
    for lang in language_priority(metadata, list(values.keys())):
        url = values.get(lang)
        if isinstance(url, str) and url not in ordered_urls:
            ordered_urls.append(url)
    return ordered_urls


def add_query_param(url: str, key: str, value: str) -> str:
    """Return ``url`` with one query parameter set to ``value``."""

    parsed = urlparse(url)
    params = dict(parse_qsl(parsed.query, keep_blank_values=True))
    params[key] = value
    return urlunparse(
        (
            parsed.scheme,
            parsed.netloc,
            parsed.path,
            parsed.params,
            urlencode(params),
            parsed.fragment,
        )
    )


def unique_preserve_order(values: list[str]) -> list[str]:
    """Deduplicate strings while preserving order."""

    out = []
    for value in values:
        if value and value not in out:
            out.append(value)
    return out


def fetch_url(
    session: requests.Session,
    url: str,
    rate_limit: float,
    logger: logging.Logger,
) -> tuple[bytes, str, str]:
    """Fetch one URL and return bytes, final URL, and content type."""

    logger.debug("GET %s", url)
    response = session.get(url, timeout=HTTP_TIMEOUT)
    if rate_limit > 0:
        time.sleep(rate_limit)
    response.raise_for_status()
    content_type = response.headers.get("content-type", "")
    return response.content, response.url, content_type


def meta_values(doc: lxml_html.HtmlElement, name: str) -> list[str]:
    """Extract content values from HTML meta tags by name."""

    values = doc.xpath(f"//meta[@name={name!r}]/@content")
    return [normalize_space(value) for value in values if normalize_space(value)]


def html_meta(doc: lxml_html.HtmlElement) -> dict[str, list[str]]:
    """Extract relevant citation metadata from an HTML document."""

    names = [
        "citation_title",
        "citation_author",
        "citation_abstract",
        "citation_xml_url",
        "citation_pdf_url",
        "citation_language",
        "citation_journal_title",
    ]
    return {name: meta_values(doc, name) for name in names}


def html_sections(doc: lxml_html.HtmlElement) -> list[lxml_html.HtmlElement]:
    """Find SciELO body sections in the HTML DOM."""

    sections = []
    for anchor in HTML_TEXT_ANCHORS:
        xpath = (
            "//*[contains(concat(' ', normalize-space(@class), ' '), "
            "' articleSection ') and normalize-space(@data-anchor)=$anchor]"
        )
        sections.extend(doc.xpath(xpath, anchor=anchor))

    if not sections:
        sections.extend(
            doc.xpath(
                "//*[normalize-space(translate(@data-anchor, "
                "'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'))="
                "'text' or normalize-space(translate(@data-anchor, "
                "'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'))='texto']"
            )
        )
    return sections


def blocks_from_html_section(section: lxml_html.HtmlElement) -> list[str]:
    """Extract ordered text blocks from a SciELO HTML body section."""

    section_copy = copy.deepcopy(section)
    etree.strip_elements(
        section_copy,
        "script",
        "style",
        "noscript",
        "svg",
        "math",
        with_tail=False,
    )
    block_tags = {"h1", "h2", "h3", "h4", "h5", "h6", "p", "li"}
    blocks = []
    for element in section_copy.iter():
        if not isinstance(element.tag, str):
            continue
        tag = element.tag.lower()
        if tag not in block_tags:
            continue
        text = normalize_space(element.text_content())
        if text:
            blocks.append(text)
    if not blocks:
        text = normalize_space(section_copy.text_content())
        if text:
            blocks.append(text)
    return blocks


def blocks_from_xml_body(xml_bytes: bytes) -> tuple[list[str], list[str], list[str], list[str]]:
    """Extract body blocks and front metadata from a JATS XML document."""

    parser = etree.XMLParser(recover=True, resolve_entities=False, no_network=True)
    root = etree.fromstring(xml_bytes, parser=parser)

    def local_name(element: etree._Element) -> str:
        return etree.QName(element).localname if isinstance(element.tag, str) else ""

    title_candidates = []
    author_candidates = []
    abstract_candidates = []
    for element in root.iter():
        name = local_name(element)
        text = normalize_space(" ".join(element.itertext()))
        if not text:
            continue
        if name in {"article-title", "trans-title"}:
            title_candidates.append(text)
        elif name == "abstract":
            abstract_candidates.append(text)
        elif name == "name":
            author_candidates.append(text)

    body_blocks = []
    for body in root.iter():
        if local_name(body) != "body":
            continue
        for element in body.iter():
            if local_name(element) not in {"title", "p", "list-item"}:
                continue
            text = normalize_space(" ".join(element.itertext()))
            if text:
                body_blocks.append(text)
        break
    return body_blocks, title_candidates, author_candidates, abstract_candidates


def is_reference_heading(text: str) -> bool:
    """Return True if a block is a reference-section heading."""

    key = normalize_key(text).strip()
    if key in {normalize_key(item) for item in REFERENCE_HEADINGS}:
        return True
    if (
        key.startswith("referencias bibliograficas")
        or key.startswith("referencias e notas")
        or key.startswith("references and notes")
        or key.startswith("notes and references")
        or key.startswith("bibliographic references")
    ):
        return True
    if (
        key.startswith("referencias")
        or key.startswith("references")
        or key.startswith("bibliografia")
        or key.startswith("bibliography")
    ):
        return True
    return False


def is_abstract_label(text: str) -> bool:
    """Return True if a block is only an abstract heading."""

    key = normalize_key(text).strip(": ")
    return len(key) <= 25 and key in {normalize_key(item) for item in ABSTRACT_LABELS}


def is_keyword_block(text: str) -> bool:
    """Return True if a block is a keyword line."""

    key = normalize_key(text)
    return any(key.startswith(normalize_key(marker)) for marker in KEYWORD_MARKERS)


def strip_heading_number(key: str) -> str:
    """Remove common numeric or Roman numeral prefixes from section headings."""

    return normalize_space(
        re.sub(r"^(?:[0-9]+|[ivxlcdm]+)[\.\)]?\s+", "", key, flags=re.I)
    )


def is_body_start_heading(text: str) -> bool:
    """Identify common first body headings."""

    if len(text) > 180:
        return False
    key = strip_heading_number(normalize_key(text))
    starts = (
        "introducao",
        "introduction",
        "introduccion",
        "apresentacao",
        "presentation",
        "presentacion",
        "consideracoes iniciais",
        "consideracoes preliminares",
        "notas introdutorias",
        "nota introdutoria",
    )
    return any(key.startswith(item) for item in starts)


def is_probable_heading(text: str) -> bool:
    """Heuristic for short body section headings when no introduction exists."""

    clean = normalize_space(text)
    if len(clean) > 120 or word_count(clean) > 12:
        return False
    if clean.endswith("."):
        return False
    key = normalize_key(clean)
    if is_abstract_label(clean) or is_keyword_block(clean) or is_reference_heading(clean):
        return False
    return bool(key)


def similar_to_known_value(text: str, known_values: list[str]) -> bool:
    """Detect title/author lines already present in metadata."""

    key = normalize_key(text)
    if not key:
        return False
    for value in known_values:
        value_key = normalize_key(value)
        if not value_key:
            continue
        if key == value_key:
            return True
        if len(key) >= 20 and (key in value_key or value_key in key):
            return True
    return False


def remove_front_matter(
    blocks: list[str],
    title_candidates: list[str],
    author_candidates: list[str],
) -> list[str]:
    """Remove title, author, abstracts and keyword lines from section front matter."""

    known = title_candidates + author_candidates
    if author_candidates:
        known.append("; ".join(author_candidates))
        known.append(" | ".join(author_candidates))

    out = []
    i = 0
    while i < len(blocks):
        block = blocks[i]
        if i < 20 and similar_to_known_value(block, known):
            i += 1
            continue
        if i < 80 and is_abstract_label(block):
            i += 1
            skipped = 0
            while i < len(blocks) and i < 90:
                candidate = blocks[i]
                if is_body_start_heading(candidate):
                    break
                if is_abstract_label(candidate):
                    break
                if is_keyword_block(candidate):
                    i += 1
                    break
                if skipped >= 2 and is_probable_heading(candidate):
                    break
                skipped += 1
                i += 1
            continue
        if i < 80 and is_keyword_block(block):
            i += 1
            continue
        out.append(block)
        i += 1

    while out and similar_to_known_value(out[0], known):
        out.pop(0)
    return out


def truncate_at_references(blocks: list[str]) -> list[str]:
    """Remove references if they were accidentally included in the body text."""

    min_index = max(3, int(len(blocks) * 0.20))
    for index, block in enumerate(blocks):
        if index >= min_index and is_reference_heading(block):
            return blocks[:index]
    return blocks


def clean_body_blocks(
    blocks: list[str],
    title_candidates: list[str],
    author_candidates: list[str],
) -> str:
    """Clean extracted blocks into a body-only text."""

    cleaned = [normalize_space(block) for block in blocks]
    cleaned = [block for block in cleaned if block and normalize_key(block) != "none"]

    start_index = None
    for index, block in enumerate(cleaned[:80]):
        if is_body_start_heading(block):
            start_index = index
            break

    if start_index is not None:
        cleaned = cleaned[start_index:]
    else:
        cleaned = remove_front_matter(cleaned, title_candidates, author_candidates)

    cleaned = truncate_at_references(cleaned)

    deduped = []
    previous_key = ""
    for block in cleaned:
        key = normalize_key(block)
        if key and key != previous_key:
            deduped.append(block)
        previous_key = key
    return "\n\n".join(deduped).strip()


def reference_tail_ratio(text: str) -> float:
    """Share of text appearing after a reference heading, if any."""

    blocks = [block for block in text.split("\n\n") if normalize_space(block)]
    total = sum(len(block) for block in blocks)
    if total == 0:
        return 1.0
    for index, block in enumerate(blocks):
        if is_reference_heading(block):
            tail = sum(len(item) for item in blocks[index:])
            return tail / total

    return 0.0


def validation_flags(body_text: str, abstract_text: str) -> list[str]:
    """Return critical flags for extracted body text."""

    flags = []
    chars = len(body_text)
    words = word_count(body_text)
    abstract_chars = len(abstract_text)
    ref_ratio = reference_tail_ratio(body_text)
    first_block = body_text.split("\n\n", 1)[0] if body_text else ""

    if not normalize_space(body_text):
        flags.append("empty_body")
    if chars < MIN_BODY_CHARS or words < MIN_BODY_WORDS:
        flags.append("too_short_for_body")
    if abstract_chars >= 400:
        min_expected = max(MIN_BODY_CHARS, int(abstract_chars * 3.0))
        if chars < min_expected:
            flags.append("not_substantially_larger_than_abstract")
    if is_reference_heading(first_block):
        flags.append("starts_with_references")
    if ref_ratio > 0.45:
        flags.append("references_majority")
    if ref_ratio > 0.05 and chars < 15000:
        flags.append("references_in_short_text")

    abstract_key = normalize_key(abstract_text)
    body_key = normalize_key(body_text)
    if abstract_key and body_key:
        if body_key == abstract_key or (
            len(body_key) < len(abstract_key) * 1.8 and abstract_key in body_key
        ):
            flags.append("likely_abstract_only")
    if len([block for block in body_text.split("\n\n") if normalize_space(block)]) < 4:
        flags.append("too_few_body_blocks")
    return flags


def build_result(
    body_text: str,
    source_method: str,
    source_url: str,
    input_path: Path,
    retrieved_at: str,
    abstract_text: str,
) -> ExtractionResult:
    """Create an ``ExtractionResult`` with validation diagnostics."""

    flags = validation_flags(body_text, abstract_text)
    return ExtractionResult(
        body_text=body_text,
        source_method=source_method,
        source_url=source_url,
        input_path=input_path,
        input_hash=file_sha256(input_path),
        retrieved_at=retrieved_at,
        flags=flags,
        body_char_count=len(body_text),
        body_word_count=word_count(body_text),
        abstract_char_count=len(abstract_text),
        reference_tail_ratio=reference_tail_ratio(body_text),
    )


def extract_from_html_bytes(
    html_bytes: bytes,
    source_method: str,
    source_url: str,
    input_path: Path,
    retrieved_at: str,
    metadata: dict[str, str],
) -> tuple[ExtractionResult | None, dict[str, list[str]], str]:
    """Extract body from raw SciELO HTML bytes."""

    parser = lxml_html.HTMLParser(encoding="utf-8")
    doc = lxml_html.fromstring(html_bytes, parser=parser)
    meta = html_meta(doc)
    sections = html_sections(doc)
    title_candidates = meta.get("citation_title", []) + metadata_title_candidates(metadata)
    author_candidates = meta.get("citation_author", []) + metadata_author_candidates(metadata)
    abstract_text = article_abstract(metadata, meta.get("citation_abstract", []))

    best_result = None
    best_reason = "no_text_section"
    for section in sections:
        blocks = blocks_from_html_section(section)
        body_text = clean_body_blocks(blocks, title_candidates, author_candidates)
        result = build_result(
            body_text,
            source_method,
            source_url,
            input_path,
            retrieved_at,
            abstract_text,
        )
        if best_result is None or result.body_char_count > best_result.body_char_count:
            best_result = result
            best_reason = ";".join(result.flags) if result.flags else "valid"

    if best_result and not best_result.flags:
        return best_result, meta, "valid"
    return None, meta, best_reason


def extract_from_xml_bytes(
    xml_bytes: bytes,
    source_url: str,
    input_path: Path,
    retrieved_at: str,
    metadata: dict[str, str],
) -> tuple[ExtractionResult | None, str]:
    """Extract body from raw JATS XML bytes."""

    try:
        blocks, titles, authors, abstracts = blocks_from_xml_body(xml_bytes)
    except etree.XMLSyntaxError as exc:
        return None, f"xml_parse_error:{exc}"
    title_candidates = titles + metadata_title_candidates(metadata)
    author_candidates = authors + metadata_author_candidates(metadata)
    body_text = clean_body_blocks(blocks, title_candidates, author_candidates)
    abstract_text = article_abstract(metadata, abstracts)
    result = build_result(
        body_text,
        "citation_xml_body",
        source_url,
        input_path,
        retrieved_at,
        abstract_text,
    )
    if not result.flags:
        return result, "valid"
    return None, ";".join(result.flags)


def extract_text_from_pdf(path: Path, metadata: dict[str, str]) -> str:
    """Extract text from a PDF file using pdfplumber."""

    if pdfplumber is None:
        raise RuntimeError("pdfplumber não está instalado; fallback PDF indisponível.")
    blocks = []
    with pdfplumber.open(path) as pdf:
        for page in pdf.pages:
            text = page.extract_text(x_tolerance=1, y_tolerance=3) or ""
            if normalize_space(text):
                lines = [normalize_space(line) for line in text.splitlines()]
                blocks.extend(line for line in lines if line)
                blocks.append("")
    blocks = [block for block in blocks if block]
    return clean_body_blocks(
        blocks,
        metadata_title_candidates(metadata),
        metadata_author_candidates(metadata),
    )


def extract_from_pdf_file(
    path: Path,
    source_url: str,
    retrieved_at: str,
    metadata: dict[str, str],
) -> tuple[ExtractionResult | None, str]:
    """Extract and validate body text from a cached PDF."""

    try:
        body_text = extract_text_from_pdf(path, metadata)
    except Exception as exc:  # pragma: no cover - depends on PDF internals.
        return None, f"pdf_extract_error:{exc}"
    result = build_result(
        body_text,
        "pdf_text_extraction",
        source_url,
        path,
        retrieved_at,
        article_abstract(metadata),
    )
    if not result.flags:
        return result, "valid"
    return None, ";".join(result.flags)


def local_cached_html(pid: str) -> Path | None:
    """Return cached HTML path for a PID when present."""

    path = RAW_HTML_DIR / f"{pid}.html"
    return path if path.exists() else None


def html_candidate_urls(
    pid: str,
    articlemeta: dict[str, Any],
    metadata: dict[str, str],
) -> list[str]:
    """Build ordered HTML URL candidates for one PID."""

    urls = fulltext_urls(articlemeta, "html", metadata)
    urls.append(f"http://www.scielo.br/scielo.php?script=sci_arttext&pid={pid}")
    return unique_preserve_order(urls)


def xml_candidate_urls(html_meta_values: list[dict[str, list[str]]]) -> list[str]:
    """Build XML URL candidates from HTML citation metadata."""

    urls = []
    for meta in html_meta_values:
        urls.extend(meta.get("citation_xml_url", []))
    return unique_preserve_order(urls)


def pdf_candidate_urls(
    articlemeta: dict[str, Any],
    metadata: dict[str, str],
    html_meta_values: list[dict[str, list[str]]],
    final_html_urls: list[str],
) -> list[str]:
    """Build PDF URL candidates from ArticleMeta, HTML metadata and final URLs."""

    urls = fulltext_urls(articlemeta, "pdf", metadata)
    for meta in html_meta_values:
        urls.extend(meta.get("citation_pdf_url", []))
    for url in final_html_urls:
        if "scielo.br/" in url:
            urls.append(add_query_param(url, "format", "pdf"))
    return unique_preserve_order(urls)


def recover_one_pid(
    pid: str,
    metadata: dict[str, str],
    session: requests.Session,
    rate_limit: float,
    offline: bool,
    logger: logging.Logger,
) -> tuple[ExtractionResult | None, list[dict[str, str]]]:
    """Recover body text for a single PID."""

    articlemeta = load_articlemeta(pid)
    attempts = []
    retrieved_at = datetime.now(timezone.utc).isoformat()
    html_metas: list[dict[str, list[str]]] = []
    final_html_urls: list[str] = []
    html_urls = html_candidate_urls(pid, articlemeta, metadata)

    cached_html = canonical_raw_path(RAW_HTML_DIR, pid, "html")
    if cached_html.exists():
        source_hint = html_urls[0] if html_urls else "cached_html"
        html_bytes = cached_html.read_bytes()
        result, meta, reason = extract_from_html_bytes(
            html_bytes,
            "articlemeta_fulltexts_html",
            source_hint,
            cached_html,
            retrieved_at,
            metadata,
        )
        html_metas.append(meta)
        attempts.append(
            {
                "pid": pid,
                "source_method": "articlemeta_fulltexts_html",
                "source_url": source_hint,
                "status": "valid" if result else "invalid",
                "reason": reason,
                "raw_path": str(cached_html.relative_to(PROJECT_DIR)),
            }
        )
        if result:
            return result, attempts

    for url in html_urls:
        html_path = candidate_raw_path(RAW_HTML_DIR, pid, "html", url)
        final_url = url
        if html_path.exists():
            html_bytes = html_path.read_bytes()
        elif offline:
            attempts.append(
                {
                    "pid": pid,
                    "source_method": "articlemeta_fulltexts_html",
                    "source_url": url,
                    "status": "skipped",
                    "reason": "offline_no_cache",
                    "raw_path": "",
                }
            )
            continue
        else:
            try:
                content, final_url, content_type = fetch_url(
                    session, url, rate_limit, logger
                )
            except Exception as exc:
                attempts.append(
                    {
                        "pid": pid,
                        "source_method": "articlemeta_fulltexts_html",
                        "source_url": url,
                        "status": "fetch_error",
                        "reason": str(exc),
                        "raw_path": "",
                    }
                )
                continue
            if (
                "html" not in content_type.lower()
                and b"<html" not in content[:1000].lower()
            ):
                attempts.append(
                    {
                        "pid": pid,
                        "source_method": "articlemeta_fulltexts_html",
                        "source_url": final_url,
                        "status": "invalid",
                        "reason": f"not_html:{content_type}",
                        "raw_path": "",
                    }
                )
                continue
            save_raw_if_missing(html_path, content)
            write_raw_sidecar(html_path, url, final_url, content_type, retrieved_at)
            html_bytes = html_path.read_bytes()
        final_html_urls.append(final_url)
        result, meta, reason = extract_from_html_bytes(
            html_bytes,
            "articlemeta_fulltexts_html",
            final_url,
            html_path,
            retrieved_at,
            metadata,
        )
        html_metas.append(meta)
        attempts.append(
            {
                "pid": pid,
                "source_method": "articlemeta_fulltexts_html",
                "source_url": final_url,
                "status": "valid" if result else "invalid",
                "reason": reason,
                "raw_path": str(html_path.relative_to(PROJECT_DIR)),
            }
        )
        if result:
            canonical_html = canonical_raw_path(RAW_HTML_DIR, pid, "html")
            if not canonical_html.exists():
                save_raw_if_missing(canonical_html, html_bytes)
            return result, attempts

    xml_urls = xml_candidate_urls(html_metas)
    cached_xml = canonical_raw_path(RAW_XML_DIR, pid, "xml")
    if cached_xml.exists():
        xml_url = xml_urls[0] if xml_urls else "cached_xml"
        result, reason = extract_from_xml_bytes(
            cached_xml.read_bytes(), xml_url, cached_xml, retrieved_at, metadata
        )
        attempts.append(
            {
                "pid": pid,
                "source_method": "citation_xml_body",
                "source_url": xml_url,
                "status": "valid" if result else "invalid",
                "reason": reason,
                "raw_path": str(cached_xml.relative_to(PROJECT_DIR)),
            }
        )
        if result:
            return result, attempts

    for url in xml_urls:
        xml_path = candidate_raw_path(RAW_XML_DIR, pid, "xml", url)
        xml_url = url
        if xml_path.exists():
            pass
        elif offline:
            attempts.append(
                {
                    "pid": pid,
                    "source_method": "citation_xml_body",
                    "source_url": url,
                    "status": "skipped",
                    "reason": "offline_no_cache",
                    "raw_path": "",
                }
            )
            continue
        else:
            try:
                content, final_url, content_type = fetch_url(
                    session, url, rate_limit, logger
                )
            except Exception as exc:
                attempts.append(
                    {
                        "pid": pid,
                        "source_method": "citation_xml_body",
                        "source_url": url,
                        "status": "fetch_error",
                        "reason": str(exc),
                        "raw_path": "",
                    }
                )
                continue
            if "xml" not in content_type.lower() and not content.lstrip().startswith(b"<"):
                attempts.append(
                    {
                        "pid": pid,
                        "source_method": "citation_xml_body",
                        "source_url": final_url,
                        "status": "invalid",
                        "reason": f"not_xml:{content_type}",
                        "raw_path": "",
                    }
                )
                continue
            save_raw_if_missing(xml_path, content)
            write_raw_sidecar(xml_path, url, final_url, content_type, retrieved_at)
            xml_url = final_url

        result, reason = extract_from_xml_bytes(
            xml_path.read_bytes(), xml_url, xml_path, retrieved_at, metadata
        )
        attempts.append(
            {
                "pid": pid,
                "source_method": "citation_xml_body",
                "source_url": xml_url,
                "status": "valid" if result else "invalid",
                "reason": reason,
                "raw_path": str(xml_path.relative_to(PROJECT_DIR)),
            }
        )
        if result:
            canonical_xml = canonical_raw_path(RAW_XML_DIR, pid, "xml")
            if not canonical_xml.exists():
                save_raw_if_missing(canonical_xml, xml_path.read_bytes())
            return result, attempts

    pdf_urls = pdf_candidate_urls(articlemeta, metadata, html_metas, final_html_urls)
    cached_pdf = canonical_raw_path(RAW_PDF_DIR, pid, "pdf")
    if cached_pdf.exists():
        pdf_url = pdf_urls[0] if pdf_urls else "cached_pdf"
        result, reason = extract_from_pdf_file(cached_pdf, pdf_url, retrieved_at, metadata)
        attempts.append(
            {
                "pid": pid,
                "source_method": "pdf_text_extraction",
                "source_url": pdf_url,
                "status": "valid" if result else "invalid",
                "reason": reason,
                "raw_path": str(cached_pdf.relative_to(PROJECT_DIR)),
            }
        )
        if result:
            return result, attempts

    for url in pdf_urls:
        pdf_path = candidate_raw_path(RAW_PDF_DIR, pid, "pdf", url)
        pdf_url = url
        if pdf_path.exists():
            pass
        elif offline:
            attempts.append(
                {
                    "pid": pid,
                    "source_method": "pdf_text_extraction",
                    "source_url": url,
                    "status": "skipped",
                    "reason": "offline_no_cache",
                    "raw_path": "",
                }
            )
            continue
        else:
            try:
                content, final_url, content_type = fetch_url(
                    session, url, rate_limit, logger
                )
            except Exception as exc:
                attempts.append(
                    {
                        "pid": pid,
                        "source_method": "pdf_text_extraction",
                        "source_url": url,
                        "status": "fetch_error",
                        "reason": str(exc),
                        "raw_path": "",
                    }
                )
                continue
            if "pdf" not in content_type.lower() and not content.startswith(b"%PDF"):
                attempts.append(
                    {
                        "pid": pid,
                        "source_method": "pdf_text_extraction",
                        "source_url": final_url,
                        "status": "invalid",
                        "reason": f"not_pdf:{content_type}",
                        "raw_path": "",
                    }
                )
                continue
            save_raw_if_missing(pdf_path, content)
            write_raw_sidecar(pdf_path, url, final_url, content_type, retrieved_at)
            pdf_url = final_url

        result, reason = extract_from_pdf_file(pdf_path, pdf_url, retrieved_at, metadata)
        attempts.append(
            {
                "pid": pid,
                "source_method": "pdf_text_extraction",
                "source_url": pdf_url,
                "status": "valid" if result else "invalid",
                "reason": reason,
                "raw_path": str(pdf_path.relative_to(PROJECT_DIR)),
            }
        )
        if result:
            canonical_pdf = canonical_raw_path(RAW_PDF_DIR, pid, "pdf")
            if not canonical_pdf.exists():
                save_raw_if_missing(canonical_pdf, pdf_path.read_bytes())
            return result, attempts

    return None, attempts


def processed_row(
    pid: str,
    metadata: dict[str, str],
    result: ExtractionResult,
) -> dict[str, Any]:
    """Build one row for the processed fulltext CSV."""

    return {
        "pid": pid,
        "title": metadata.get("title", ""),
        "title_en": metadata.get("title_en", ""),
        "authors": metadata.get("authors", ""),
        "year": metadata.get("year", ""),
        "issn": metadata.get("issn", ""),
        "journal_title": metadata.get("journal_title", ""),
        "doi": metadata.get("doi", ""),
        "document_type": metadata.get("document_type", ""),
        "language": metadata.get("language", ""),
        "body_text": result.body_text,
        "body_char_count": result.body_char_count,
        "body_word_count": result.body_word_count,
        "source_method": result.source_method,
        "source_url": result.source_url,
        "input_hash": result.input_hash,
        "retrieved_at": result.retrieved_at,
        "abstract_char_count": result.abstract_char_count,
        "reference_tail_ratio": f"{result.reference_tail_ratio:.6f}",
        "validation_flags": ";".join(result.flags),
    }


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    """Write CSV atomically with UTF-8 encoding."""

    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(dir=path.parent, prefix=path.stem, suffix=".tmp")
    tmp_path = Path(tmp_name)
    try:
        with open(fd, "w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)
        tmp_path.replace(path)
    except BaseException:
        tmp_path.unlink(missing_ok=True)
        raise


def write_attempt_log(run_timestamp: str, attempts: list[dict[str, str]]) -> Path:
    """Write timestamped raw recovery attempt log."""

    path = LOG_DIR / f"fulltext_gold_recovery_attempts_{run_timestamp}.csv"
    fieldnames = ["pid", "source_method", "source_url", "status", "reason", "raw_path"]
    write_csv(path, attempts, fieldnames)
    return path


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description="Recover full body text for the 175 gold/pilot SciELO articles."
    )
    parser.add_argument(
        "--rate-limit",
        type=float,
        default=0.35,
        help="Seconds to sleep after each HTTP request (default: 0.35).",
    )
    parser.add_argument(
        "--offline",
        action="store_true",
        help="Use only cached raw files; do not make HTTP requests.",
    )
    parser.add_argument(
        "--allow-partial",
        action="store_true",
        help=(
            "Keep a timestamped partial/debug CSV and exit zero even if fewer "
            "than 175 PIDs validate. The canonical CSV is never overwritten by "
            "a partial run."
        ),
    )
    parser.add_argument(
        "--pid",
        action="append",
        help="Recover only the specified PID(s), for debugging.",
    )
    return parser.parse_args()


def main() -> int:
    """Run the recovery pipeline."""

    args = parse_args()
    run_timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    logger = setup_logging(run_timestamp)
    for directory in [
        RAW_HTML_DIR,
        RAW_XML_DIR,
        RAW_PDF_DIR,
        RAW_META_DIR,
        PROCESSED_DIR,
        LOG_DIR,
    ]:
        directory.mkdir(parents=True, exist_ok=True)

    gold_pids = load_gold_pids()
    is_debug_subset = bool(args.pid)
    if args.pid:
        requested = set(args.pid)
        gold_pids = [pid for pid in gold_pids if pid in requested]
        missing_requested = sorted(requested - set(gold_pids))
        if missing_requested:
            raise ValueError(f"PIDs solicitados fora do gold: {missing_requested}")

    metadata_by_pid = load_metadata_by_pid()
    session = create_session()
    processed_rows = []
    all_attempts = []

    logger.info("Iniciando recuperação de %d PIDs", len(gold_pids))
    for index, pid in enumerate(gold_pids, start=1):
        metadata = metadata_by_pid.get(pid)
        if metadata is None:
            raise ValueError(f"PID ausente em {ARTICLE_METADATA}: {pid}")
        logger.info("[%03d/%03d] PID %s", index, len(gold_pids), pid)
        result, attempts = recover_one_pid(
            pid=pid,
            metadata=metadata,
            session=session,
            rate_limit=args.rate_limit,
            offline=args.offline,
            logger=logger,
        )
        all_attempts.extend(attempts)
        if result is None:
            logger.error("Falha ao recuperar body válido para %s", pid)
            continue
        processed_rows.append(processed_row(pid, metadata, result))
        logger.info(
            "Body validado para %s via %s: %d chars, %d palavras",
            pid,
            result.source_method,
            result.body_char_count,
            result.body_word_count,
        )

    attempt_log_path = write_attempt_log(run_timestamp, all_attempts)
    logger.info("Log de tentativas salvo em: %s", attempt_log_path)

    fieldnames = [
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
        "input_hash",
        "retrieved_at",
        "abstract_char_count",
        "reference_tail_ratio",
        "validation_flags",
    ]
    canonical_ready = (
        not is_debug_subset
        and len(gold_pids) == EXPECTED_GOLD_N
        and len(processed_rows) == EXPECTED_GOLD_N
    )

    if canonical_ready:
        output_path = OUTPUT_CSV
    else:
        kind = "debug" if is_debug_subset else "partial"
        output_path = PROCESSED_DIR / f"article_texts_gold_{kind}_{run_timestamp}.csv"

    write_csv(output_path, processed_rows, fieldnames)
    logger.info("CSV processado salvo em: %s", output_path)

    if len(processed_rows) != len(gold_pids):
        missing = sorted(set(gold_pids) - {row["pid"] for row in processed_rows})
        logger.error(
            "Recuperação incompleta: %d/%d. PIDs faltantes: %s",
            len(processed_rows),
            len(gold_pids),
            ", ".join(missing),
        )
        if not args.allow_partial:
            return 1

    if not canonical_ready:
        logger.info("CSV canônico preservado: %s", OUTPUT_CSV)

    logger.info("Recuperação completa: %d/%d", len(processed_rows), len(gold_pids))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
