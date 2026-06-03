## 15_write_fulltext_scaling_plan.R
## Gera plano de escala para recuperar body no corpus elegível completo.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

project_dir <- normalizePath(".", mustWork = TRUE)

paths <- list(
  articles = file.path(project_dir, "data", "raw", "articles_2005_2025.csv"),
  excluded_journals = file.path(project_dir, "data", "processed", "excluded_journals.csv"),
  excluded_articles = file.path(project_dir, "data", "processed", "excluded_articles.csv"),
  inventory = file.path(project_dir, "quality_reports", "fulltext_gold_inventory.csv"),
  report = file.path(project_dir, "quality_reports", "fulltext_scaling_plan.md")
)

dir.create(dirname(paths$report), showWarnings = FALSE, recursive = TRUE)

expected_gold_n <- 175L

normalize_label <- function(x) {
  x |>
    stringr::str_to_lower() |>
    stringr::str_squish()
}

articles <- readr::read_csv(paths$articles, show_col_types = FALSE)

excluded_journals <- readr::read_csv(paths$excluded_journals, show_col_types = FALSE)
excluded_articles <- readr::read_csv(paths$excluded_articles, show_col_types = FALSE)

excluded_journals_active <- excluded_journals |>
  dplyr::filter(dplyr::coalesce(exclude_from_analysis, TRUE))

excluded_articles_active <- excluded_articles |>
  dplyr::filter(dplyr::coalesce(exclude_from_analysis, TRUE))

if ("journal_title" %in% names(excluded_journals)) {
  excluded_journal_names <- excluded_journals_active |>
    dplyr::pull(journal_title)
} else if ("title" %in% names(excluded_journals)) {
  excluded_journal_names <- excluded_journals_active |>
    dplyr::pull(title)
} else {
  excluded_journal_names <- c(
    "Brazilian Journal of Political Economy",
    "Civitas - Revista de Ciências Sociais"
  )
}

excluded_journal_names <- unique(c(
  excluded_journal_names,
  "Brazilian Journal of Political Economy",
  "Civitas - Revista de Ciências Sociais"
))
excluded_journal_keys <- normalize_label(excluded_journal_names)

excluded_article_pids <- if ("pid" %in% names(excluded_articles)) {
  excluded_articles_active |> dplyr::pull(pid)
} else {
  character()
}

eligible <- articles |>
  dplyr::mutate(journal_title_key = normalize_label(journal_title)) |>
  dplyr::filter(
    !journal_title_key %in% excluded_journal_keys,
    !pid %in% excluded_article_pids,
    dplyr::coalesce(document_type, "") == "research-article"
  ) |>
  dplyr::select(-journal_title_key)

journal_counts <- eligible |>
  dplyr::count(journal_title, name = "n") |>
  dplyr::arrange(dplyr::desc(n), journal_title)

median_seconds_per_article <- 1.0
if (!file.exists(paths$inventory)) {
  stop("Inventário gold ausente; rode scripts/14_validate_fulltext_gold.R antes: ", paths$inventory)
}

inventory <- readr::read_csv(paths$inventory, show_col_types = FALSE)
required_inventory_cols <- c("pid", "validation_status", "source_method")
missing_inventory_cols <- setdiff(required_inventory_cols, names(inventory))
if (length(missing_inventory_cols) > 0) {
  stop("Colunas ausentes no inventário gold: ", paste(missing_inventory_cols, collapse = ", "))
}

validated_gold <- sum(inventory$validation_status == "PASS")
if (nrow(inventory) != expected_gold_n ||
    dplyr::n_distinct(inventory$pid) != expected_gold_n ||
    validated_gold != expected_gold_n) {
  stop(
    "Inventário gold não está validado 175/175: rows=", nrow(inventory),
    ", unique_pids=", dplyr::n_distinct(inventory$pid),
    ", pass=", validated_gold
  )
}

method_counts <- inventory |>
  dplyr::filter(validation_status == "PASS") |>
  dplyr::count(source_method, name = "n") |>
  dplyr::arrange(dplyr::desc(n), source_method)

eligible_n <- nrow(eligible)
batch_size <- 250L
batch_n <- ceiling(eligible_n / batch_size)
estimated_minutes_serial <- ceiling(eligible_n * median_seconds_per_article / 60)
estimated_minutes_parallel_4 <- ceiling(eligible_n * median_seconds_per_article / 4 / 60)

journal_lines <- paste0("- ", journal_counts$journal_title, ": ", journal_counts$n)
method_lines <- paste0("- ", method_counts$source_method, ": ", method_counts$n)

lines <- c(
  "# Fulltext scaling plan",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Universe",
  "",
  paste0("- Raw SciELO corpus 2005-2025: ", nrow(articles), " article records."),
  paste0("- Eligible corpus after exclusions and `research-article` filter: ", eligible_n, " records."),
  paste0("- Planned batches at ", batch_size, " PIDs per batch: ", batch_n, " batches."),
  paste0("- Gold/pilot bodies validated so far: ", validated_gold, "/175."),
  "",
  "Eligible records by journal:",
  "",
  journal_lines,
  "",
  "## Exclusions before extraction",
  "",
  "- Exclude `Brazilian Journal of Political Economy` before fulltext recovery for the analytic corpus.",
  "- Exclude `Civitas - Revista de Ciências Sociais` before fulltext recovery for the analytic corpus.",
  "- Apply `data/processed/excluded_articles.csv` before extraction so editorials, reviews, errata and other out-of-scope records do not consume scraping budget.",
  "- Preserve raw metadata for excluded records; exclusion is analytic, not deletion.",
  "",
  "## Source order",
  "",
  "Use the same source hierarchy as the gold recovery script:",
  "",
  "1. `fulltexts.html` URLs in cached ArticleMeta JSONs under `data/raw/api_responses/articles/`.",
  "2. SciELO HTML body selectors `.articleSection[data-anchor=\"Text\"]` and `.articleSection[data-anchor=\"Texto\"]`.",
  "3. `citation_xml_url`, only when the XML has a real `<body>`.",
  "4. SciELO PDF fallback, with text extracted from the preserved PDF.",
  "",
  "Gold recovery method counts:",
  "",
  method_lines,
  "",
  "## Batching and resume",
  "",
  "- Generate a manifest CSV with one row per eligible PID, source URL candidates, expected language, and output paths.",
  "- Process batches of 250 PIDs by default. For each PID, write raw HTML/XML/PDF only if absent, then append a timestamped attempt log in `data/raw/logs/`.",
  "- A resumed run should skip PIDs whose processed row passes validation and whose raw `input_hash` still matches the inventory.",
  "- Failed PIDs should remain in a retry queue with method-specific causes, not disappear from the processed output silently.",
  "",
  "## Rate limit and parallelism",
  "",
  "- Start with 0.35 seconds after each HTTP request per worker.",
  "- Use at most 4 workers against SciELO until 429/5xx rates are known to be low.",
  "- Parallelize by PID, not by source within PID, so fallback order remains deterministic.",
  "- Increase backoff on 429, 500, 502, 503 and 504 responses; never retry tight loops.",
  "",
  "## Validation gates",
  "",
  "- Every eligible PID must have exactly one processed row.",
  "- `body_text` must be non-empty, at least 3,000 characters and 600 words.",
  "- `body_text` must be substantially larger than the longest available abstract.",
  "- Text starting with `Referências`, `References`, `Bibliografia` or equivalent fails.",
  "- Reference-tail share above 45% fails; 25-45% is suspicious and should enter manual QA.",
  "- Abstract, metadata, keywords and references must never be promoted to `body_text` in silence.",
  "",
  "## Implementation checklist for corpus-wide run",
  "",
  "- Create a corpus-wide recovery script, preferably `scripts/16_recover_fulltext_corpus.py`, by generalizing `scripts/13_recover_fulltext_gold.py`; do not repurpose the gold output paths.",
  "- The corpus script must build its eligible PID manifest from `data/raw/articles_2005_2025.csv`, `data/processed/excluded_journals.csv`, and `data/processed/excluded_articles.csv`, applying journal/article exclusions and `document_type == \"research-article\"` before any HTTP request.",
  "- The corpus script must write raw cache only under `data/raw/fulltext_corpus/` and processed text only under `data/processed/fulltext_corpus/article_texts_corpus.csv`.",
  "- Preserve the same deterministic fallback order, provenance fields, hashes, resume behavior, and validation flags used by the gold recovery.",
  "- Add an offline/resume mode that reconstructs the processed CSV from preserved raw files without network access, analogous to `python3 scripts/13_recover_fulltext_gold.py --offline`.",
  "- Create a corpus-wide validation script, preferably `scripts/17_validate_fulltext_corpus.R`, by generalizing `scripts/14_validate_fulltext_gold.R`; it must fail when any eligible PID is missing, duplicated, too short, front-matter-only, references-only, or lacks provenance.",
  "- After recovery, regenerate inventory/report outputs and update `README.md`, `data/README.md`, and `scripts/README.md` if paths, counts, or source behavior changed.",
  "",
  "Recommended verification sequence after implementation:",
  "",
  "```bash",
  "python3 scripts/16_recover_fulltext_corpus.py --workers 4 --batch-size 250",
  "python3 scripts/16_recover_fulltext_corpus.py --offline",
  "Rscript --vanilla scripts/17_validate_fulltext_corpus.R",
  "python3 -m pytest scripts",
  "```",
  "",
  "## Estimated runtime",
  "",
  paste0("- Serial estimate at about one second per PID: ", estimated_minutes_serial, " minutes for ", eligible_n, " records."),
  paste0("- Four-worker estimate under the same assumption: ", estimated_minutes_parallel_4, " minutes, plus retries and PDF extraction overhead."),
  "- PDF fallback is slower and should be rare if HTML/XML coverage resembles the gold sample.",
  "",
  "## Canonical outputs for scale",
  "",
  "- Raw cache: `data/raw/fulltext_corpus/html/`, `data/raw/fulltext_corpus/xml/`, `data/raw/fulltext_corpus/pdf/`.",
  "- Processed corpus text: `data/processed/fulltext_corpus/article_texts_corpus.csv`.",
  "- Inventory and QA report: `quality_reports/fulltext_corpus_inventory.csv` and `quality_reports/fulltext_corpus_recovery_report.md`.",
  "- The 175-gold canonical file remains `data/processed/fulltext_gold/article_texts_gold.csv`; do not mix it with the future corpus-wide file."
)

writeLines(lines, paths$report, useBytes = TRUE)

message("Fulltext scaling plan written to: ", paths$report)
