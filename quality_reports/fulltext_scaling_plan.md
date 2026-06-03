# Fulltext scaling plan

Generated at: 2026-06-03 20:38:39 -03

## Universe

- Raw SciELO corpus 2005-2025: 8400 article records.
- Eligible corpus after exclusions and `research-article` filter: 6672 records.
- Planned batches at 250 PIDs per batch: 27 batches.
- Gold/pilot bodies validated so far: 175/175.

Eligible records by journal:

- Revista de Administração Pública: 1161
- Revista Brasileira de Ciências Sociais: 727
- Revista de Sociologia e Política: 654
- Dados: 642
- Novos estudos CEBRAP: 600
- Lua Nova: Revista de Cultura e Política: 536
- Revista Brasileira de Política Internacional: 507
- Opinião Pública: 480
- Contexto Internacional: 472
- Revista Brasileira de Ciência Política: 403
- Brazilian Political Science Review: 283
- Cadernos Gestão Pública e Cidadania: 124
- Sur. Revista Internacional de Direitos Humanos: 83

## Exclusions before extraction

- Exclude `Brazilian Journal of Political Economy` before fulltext recovery for the analytic corpus.
- Exclude `Civitas - Revista de Ciências Sociais` before fulltext recovery for the analytic corpus.
- Apply `data/processed/excluded_articles.csv` before extraction so editorials, reviews, errata and other out-of-scope records do not consume scraping budget.
- Preserve raw metadata for excluded records; exclusion is analytic, not deletion.

## Source order

Use the same source hierarchy as the gold recovery script:

1. `fulltexts.html` URLs in cached ArticleMeta JSONs under `data/raw/api_responses/articles/`.
2. SciELO HTML body selectors `.articleSection[data-anchor="Text"]` and `.articleSection[data-anchor="Texto"]`.
3. `citation_xml_url`, only when the XML has a real `<body>`.
4. SciELO PDF fallback, with text extracted from the preserved PDF.

Gold recovery method counts:

- articlemeta_fulltexts_html: 171
- pdf_text_extraction: 3
- citation_xml_body: 1

## Batching and resume

- Generate a manifest CSV with one row per eligible PID, source URL candidates, expected language, and output paths.
- Process batches of 250 PIDs by default. For each PID, write raw HTML/XML/PDF only if absent, then append a timestamped attempt log in `data/raw/logs/`.
- A resumed run should skip PIDs whose processed row passes validation and whose raw `input_hash` still matches the inventory.
- Failed PIDs should remain in a retry queue with method-specific causes, not disappear from the processed output silently.

## Rate limit and parallelism

- Start with 0.35 seconds after each HTTP request per worker.
- Use at most 4 workers against SciELO until 429/5xx rates are known to be low.
- Parallelize by PID, not by source within PID, so fallback order remains deterministic.
- Increase backoff on 429, 500, 502, 503 and 504 responses; never retry tight loops.

## Validation gates

- Every eligible PID must have exactly one processed row.
- `body_text` must be non-empty, at least 3,000 characters and 600 words.
- `body_text` must be substantially larger than the longest available abstract.
- Text starting with `Referências`, `References`, `Bibliografia` or equivalent fails.
- Reference-tail share above 45% fails; 25-45% is suspicious and should enter manual QA.
- Abstract, metadata, keywords and references must never be promoted to `body_text` in silence.

## Implementation checklist for corpus-wide run

- Create a corpus-wide recovery script, preferably `scripts/16_recover_fulltext_corpus.py`, by generalizing `scripts/13_recover_fulltext_gold.py`; do not repurpose the gold output paths.
- The corpus script must build its eligible PID manifest from `data/raw/articles_2005_2025.csv`, `data/processed/excluded_journals.csv`, and `data/processed/excluded_articles.csv`, applying journal/article exclusions and `document_type == "research-article"` before any HTTP request.
- The corpus script must write raw cache only under `data/raw/fulltext_corpus/` and processed text only under `data/processed/fulltext_corpus/article_texts_corpus.csv`.
- Preserve the same deterministic fallback order, provenance fields, hashes, resume behavior, and validation flags used by the gold recovery.
- Add an offline/resume mode that reconstructs the processed CSV from preserved raw files without network access, analogous to `python3 scripts/13_recover_fulltext_gold.py --offline`.
- Create a corpus-wide validation script, preferably `scripts/17_validate_fulltext_corpus.R`, by generalizing `scripts/14_validate_fulltext_gold.R`; it must fail when any eligible PID is missing, duplicated, too short, front-matter-only, references-only, or lacks provenance.
- After recovery, regenerate inventory/report outputs and update `README.md`, `data/README.md`, and `scripts/README.md` if paths, counts, or source behavior changed.

Recommended verification sequence after implementation:

```bash
python3 scripts/16_recover_fulltext_corpus.py --workers 4 --batch-size 250
python3 scripts/16_recover_fulltext_corpus.py --offline
Rscript --vanilla scripts/17_validate_fulltext_corpus.R
python3 -m pytest scripts
```

## Estimated runtime

- Serial estimate at about one second per PID: 112 minutes for 6672 records.
- Four-worker estimate under the same assumption: 28 minutes, plus retries and PDF extraction overhead.
- PDF fallback is slower and should be rare if HTML/XML coverage resembles the gold sample.

## Canonical outputs for scale

- Raw cache: `data/raw/fulltext_corpus/html/`, `data/raw/fulltext_corpus/xml/`, `data/raw/fulltext_corpus/pdf/`.
- Processed corpus text: `data/processed/fulltext_corpus/article_texts_corpus.csv`.
- Inventory and QA report: `quality_reports/fulltext_corpus_inventory.csv` and `quality_reports/fulltext_corpus_recovery_report.md`.
- The 175-gold canonical file remains `data/processed/fulltext_gold/article_texts_gold.csv`; do not mix it with the future corpus-wide file.
