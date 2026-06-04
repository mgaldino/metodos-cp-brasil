## 10_prepare_full_classification_pilot_v2.R
## Prepara manifest reprodutivel para o piloto v2 usando body integral canonico.

options(scipen = 999)

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(stringr)
  library(tibble)
})

project_dir <- normalizePath(".", mustWork = TRUE)

paths <- list(
  body_gold = file.path(project_dir, "data", "processed", "fulltext_gold", "article_texts_gold.csv"),
  excluded_journals = file.path(project_dir, "data", "processed", "excluded_journals.csv"),
  excluded_articles = file.path(project_dir, "data", "processed", "excluded_articles.csv"),
  pilot_dir = file.path(project_dir, "data", "processed", "full_classification_pilot_v2"),
  prompts_dir = file.path(project_dir, "data", "processed", "full_classification_pilot_v2", "prompts"),
  task_packet_dir = file.path(project_dir, "data", "processed", "full_classification_pilot_v2", "task_packets"),
  manifest = file.path(project_dir, "data", "processed", "full_classification_pilot_v2", "pilot_manifest.csv"),
  metadata = file.path(project_dir, "data", "processed", "full_classification_pilot_v2", "pilot_manifest_metadata.json"),
  summary = file.path(project_dir, "quality_reports", "full_classification_pilot_v2_manifest_summary.md")
)

dir.create(paths$pilot_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(paths$prompts_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(paths$task_packet_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(paths$summary), showWarnings = FALSE, recursive = TRUE)
purrr::walk(c("agent_a", "agent_b", "agent_c", "comparison", "fidelity_checker", "logs"), function(x) {
  dir.create(file.path(paths$pilot_dir, x), showWarnings = FALSE, recursive = TRUE)
})
purrr::walk(c("agent_a", "agent_b", "agent_c"), function(x) {
  dir.create(file.path(paths$pilot_dir, "fidelity_checker", x), showWarnings = FALSE, recursive = TRUE)
})

read_required_csv <- function(path) {
  if (!file.exists(path)) {
    stop("Arquivo ausente: ", path)
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

relative_path <- function(path) {
  stringr::str_remove(normalizePath(path, mustWork = FALSE), paste0("^", stringr::fixed(project_dir), "/?"))
}

markdown_table <- function(df, max_rows = Inf) {
  if (nrow(df) == 0) {
    return("_Nenhum registro._")
  }
  df <- utils::head(df, max_rows)
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- apply(df, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

sha256_text <- function(x) {
  vapply(enc2utf8(x), digest::digest, character(1), algo = "sha256", serialize = FALSE)
}

write_task_packet <- function(row) {
  packet_path <- file.path(paths$task_packet_dir, paste0(row$pid, ".md"))
  lines <- c(
    paste0("# Article task packet v2: ", row$pid),
    "",
    "This packet is derived from `data/processed/fulltext_gold/article_texts_gold.csv`.",
    "Use only the `body_text` below plus the metadata in this packet for substantive classification.",
    "",
    "## Metadata",
    "",
    paste0("- pid: ", row$pid),
    paste0("- title: ", row$title),
    paste0("- title_en: ", ifelse(is.na(row$title_en), "", row$title_en)),
    paste0("- authors: ", row$authors),
    paste0("- year: ", row$year),
    paste0("- journal_title: ", row$journal_title),
    paste0("- language: ", row$language),
    paste0("- doi: ", ifelse(is.na(row$doi), "", row$doi)),
    paste0("- canonical_source_file: ", relative_path(paths$body_gold)),
    "- canonical_source_column: body_text",
    paste0("- input_text_hash: ", row$input_text_hash),
    "",
    "## Body Text",
    "",
    row$body_text
  )
  writeLines(lines, packet_path, useBytes = TRUE)
  relative_path(packet_path)
}

body_gold <- read_required_csv(paths$body_gold)
excluded_journals <- read_required_csv(paths$excluded_journals)
excluded_articles <- read_required_csv(paths$excluded_articles)

required_body_cols <- c(
  "pid", "title", "authors", "year", "issn", "journal_title", "language",
  "body_text", "body_char_count", "body_word_count", "input_hash"
)
missing_body_cols <- setdiff(required_body_cols, names(body_gold))
if (length(missing_body_cols) > 0) {
  stop("Colunas ausentes em article_texts_gold.csv: ", paste(missing_body_cols, collapse = ", "))
}

if (nrow(body_gold) != 175) {
  stop("Esperava 175 artigos no body gold; encontrado: ", nrow(body_gold))
}

if (anyDuplicated(body_gold$pid) > 0) {
  stop("PIDs duplicados em article_texts_gold.csv.")
}

body_gold <- body_gold |>
  dplyr::mutate(
    body_text = enc2utf8(body_text),
    body_present = !is.na(body_text) & nzchar(stringr::str_trim(body_text)),
    input_text_hash = sha256_text(body_text),
    input_text_bytes = nchar(body_text, type = "bytes", allowNA = TRUE)
  )

if (any(!body_gold$body_present)) {
  missing_pids <- body_gold |>
    dplyr::filter(!body_present) |>
    dplyr::pull(pid)
  stop("Body canonico ausente para PIDs: ", paste(missing_pids, collapse = ", "))
}

journal_exclusions <- excluded_journals |>
  dplyr::filter(exclude_from_analysis %in% c(TRUE, "TRUE", "true", 1, "1")) |>
  dplyr::select(journal_title, issn, exclusion_reason)

article_exclusions <- excluded_articles |>
  dplyr::filter(exclude_from_analysis %in% c(TRUE, "TRUE", "true", 1, "1")) |>
  dplyr::select(pid, article_exclusion_reason = exclusion_reason)

excluded_pids <- body_gold |>
  dplyr::left_join(article_exclusions, by = "pid") |>
  dplyr::filter(!is.na(article_exclusion_reason))

excluded_journal_rows <- body_gold |>
  dplyr::semi_join(journal_exclusions, by = "journal_title")

if (nrow(excluded_pids) > 0) {
  stop("Manifest v2 conteria artigos excluidos: ", paste(excluded_pids$pid, collapse = ", "))
}

if (nrow(excluded_journal_rows) > 0) {
  stop("Manifest v2 conteria periodicos excluidos: ", paste(unique(excluded_journal_rows$journal_title), collapse = "; "))
}

manifest <- body_gold |>
  dplyr::arrange(pid) |>
  dplyr::mutate(
    source_file = relative_path(paths$body_gold),
    source_file_exists = file.exists(paths$body_gold),
    source_column = "body_text",
    canonical_gold_input_hash = input_hash,
    body_hash_matches_gold_input_hash = input_text_hash == canonical_gold_input_hash,
    agent_a_prompt_version = "agent_a_v2+common_schema_v2",
    agent_b_prompt_version = "agent_b_v2+common_schema_v2",
    agent_c_prompt_version = "agent_c_v2+common_schema_v2",
    agent_d_prompt_version = "agent_d_v1+fidelity_schema_v1"
  )

manifest$task_packet_file <- vapply(seq_len(nrow(manifest)), function(i) {
  write_task_packet(manifest[i, ])
}, character(1))

manifest <- manifest |>
  dplyr::select(
    pid, title, title_en, authors, year, issn, journal_title, doi, document_type,
    language, source_file, source_file_exists, source_column, task_packet_file,
    input_text_hash, input_text_bytes, body_char_count, body_word_count,
    canonical_gold_input_hash, body_hash_matches_gold_input_hash,
    source_method, source_url, retrieved_at, abstract_char_count,
    reference_tail_ratio, validation_flags,
    agent_a_prompt_version, agent_b_prompt_version, agent_c_prompt_version,
    agent_d_prompt_version
  )

if (!all(manifest$source_file_exists)) {
  stop("Fonte canonica ausente: ", relative_path(paths$body_gold))
}

readr::write_csv(manifest, paths$manifest, na = "")

metadata <- list(
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  objective = "Piloto v2 de classificacao tripla independente nos 175 artigos elegiveis usando body integral canonico.",
  canonical_body_source = relative_path(paths$body_gold),
  canonical_body_column = "body_text",
  n_articles = nrow(manifest),
  excluded_journals_rule = relative_path(paths$excluded_journals),
  excluded_articles_rule = relative_path(paths$excluded_articles),
  manifest = relative_path(paths$manifest),
  task_packets = relative_path(paths$task_packet_dir),
  prompt_versions = list(
    common = "common_schema_v2",
    agent_a = "agent_a_v2+common_schema_v2",
    agent_b = "agent_b_v2+common_schema_v2",
    agent_c = "agent_c_v2+common_schema_v2",
    agent_d = "agent_d_v1+fidelity_schema_v1"
  ),
  no_api_runner = TRUE,
  forbidden_substantive_inputs = c(
    "data/processed/sample_xmls/",
    "data/raw/articles_fulltext/",
    "data/processed/classifications_llm_main_analysis.csv",
    "data/processed/classifications_final/",
    "data/processed/classifications/",
    "data/processed/classifications_normalized/"
  )
)

jsonlite::write_json(metadata, paths$metadata, pretty = TRUE, auto_unbox = TRUE, null = "null")

journal_counts <- manifest |>
  dplyr::count(journal_title, name = "n") |>
  dplyr::arrange(dplyr::desc(n), journal_title)

summary_lines <- c(
  "# Manifest do piloto v2 de classificacao tripla",
  "",
  paste("Gerado em", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Decisao operacional",
  "",
  "Este manifest usa os 175 PIDs presentes em `data/processed/fulltext_gold/article_texts_gold.csv`, com o `body_text` integral canonico como unica fonte textual substantiva.",
  "",
  "A classificacao tripla anterior foi feita sem `<body>` integral e fica preservada. Artefatos antigos so devem entrar depois como comparacao diagnostica.",
  "",
  "Nao ha chamada de API neste piloto. As classificacoes substantivas devem ser feitas por tres subagentes Codex locais independentes.",
  "",
  "## Snapshot",
  "",
  markdown_table(tibble(
    item = c(
      "artigos no manifest",
      "fonte canonica presente",
      "body canonico preenchido",
      "hash SHA-256 do body preenchido",
      "hash SHA-256 igual ao input_hash do gold",
      "pacotes derivados gerados",
      "periodicos"
    ),
    value = c(
      nrow(manifest),
      sum(manifest$source_file_exists),
      nrow(manifest),
      sum(!is.na(manifest$input_text_hash)),
      sum(manifest$body_hash_matches_gold_input_hash, na.rm = TRUE),
      sum(file.exists(file.path(project_dir, manifest$task_packet_file))),
      length(unique(manifest$journal_title))
    )
  )),
  "",
  "## Artigos por periodico",
  "",
  markdown_table(journal_counts),
  "",
  "## Arquivos gerados",
  "",
  paste0("- `", relative_path(paths$manifest), "`"),
  paste0("- `", relative_path(paths$metadata), "`"),
  paste0("- `", relative_path(paths$task_packet_dir), "/`")
)

writeLines(summary_lines, paths$summary, useBytes = TRUE)

cat("Manifest v2 preparado.\n")
cat("Artigos:", nrow(manifest), "\n")
cat("Fonte canonica:", relative_path(paths$body_gold), "\n")
cat("Arquivo:", paths$manifest, "\n")
