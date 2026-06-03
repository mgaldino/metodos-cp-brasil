## 10_prepare_full_classification_pilot.R
## Prepara manifest reprodutivel para o piloto de classificacao tripla independente.

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
  gold = file.path(project_dir, "data", "processed", "classifications_llm_main_analysis.csv"),
  sample_sheet = file.path(project_dir, "data", "processed", "sample_validation_sheet.csv"),
  sample_xml_dir = file.path(project_dir, "data", "processed", "sample_xmls"),
  excluded_journals = file.path(project_dir, "data", "processed", "excluded_journals.csv"),
  excluded_articles = file.path(project_dir, "data", "processed", "excluded_articles.csv"),
  pilot_dir = file.path(project_dir, "data", "processed", "full_classification_pilot"),
  manifest = file.path(project_dir, "data", "processed", "full_classification_pilot", "pilot_manifest.csv"),
  metadata = file.path(project_dir, "data", "processed", "full_classification_pilot", "pilot_manifest_metadata.json"),
  summary = file.path(project_dir, "quality_reports", "full_classification_pilot_manifest_summary.md")
)

dir.create(paths$pilot_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(paths$summary), showWarnings = FALSE, recursive = TRUE)
purrr::walk(c("agent_a", "agent_b", "agent_c", "comparison", "logs"), function(x) {
  dir.create(file.path(paths$pilot_dir, x), showWarnings = FALSE, recursive = TRUE)
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

file_has_body <- function(path) {
  if (!file.exists(path)) {
    return(FALSE)
  }
  any(grepl("<body[ >]", readLines(path, warn = FALSE, encoding = "UTF-8")))
}

gold <- read_required_csv(paths$gold)
sample_sheet <- read_required_csv(paths$sample_sheet)
excluded_journals <- read_required_csv(paths$excluded_journals)
excluded_articles <- read_required_csv(paths$excluded_articles)

if (!"pid" %in% names(gold)) {
  stop("Gold/piloto sem coluna pid: ", paths$gold)
}

if (nrow(gold) != 175) {
  stop("Esperava 175 artigos no gold/piloto elegivel; encontrado: ", nrow(gold))
}

if (anyDuplicated(gold$pid) > 0) {
  stop("PIDs duplicados no gold/piloto.")
}

metadata_cols <- c("pid", "title", "authors", "year", "journal_title", "language", "url_scielo")
missing_metadata_cols <- setdiff(metadata_cols, names(sample_sheet))
if (length(missing_metadata_cols) > 0) {
  stop("Colunas ausentes em sample_validation_sheet.csv: ", paste(missing_metadata_cols, collapse = ", "))
}

manifest <- gold |>
  dplyr::select(pid) |>
  dplyr::left_join(
    sample_sheet |>
      dplyr::select(dplyr::all_of(metadata_cols)),
    by = "pid"
  ) |>
  dplyr::mutate(
    source_file = file.path("data", "processed", "sample_xmls", paste0(pid, ".xml")),
    source_file_abs = file.path(project_dir, source_file),
    raw_fulltext_file = file.path("data", "raw", "articles_fulltext", paste0(pid, ".xml")),
    raw_fulltext_file_abs = file.path(project_dir, raw_fulltext_file),
    source_file_exists = file.exists(source_file_abs),
    raw_fulltext_file_exists = file.exists(raw_fulltext_file_abs),
    input_text_hash = dplyr::if_else(
      source_file_exists,
      vapply(source_file_abs, digest::digest, character(1), algo = "sha256", file = TRUE),
      NA_character_
    ),
    raw_fulltext_hash = dplyr::if_else(
      raw_fulltext_file_exists,
      vapply(raw_fulltext_file_abs, digest::digest, character(1), algo = "sha256", file = TRUE),
      NA_character_
    ),
    raw_fulltext_same_hash = source_file_exists & raw_fulltext_file_exists & input_text_hash == raw_fulltext_hash,
    source_has_body = vapply(source_file_abs, file_has_body, logical(1)),
    raw_fulltext_has_body = vapply(raw_fulltext_file_abs, file_has_body, logical(1)),
    input_text_bytes = dplyr::if_else(
      source_file_exists,
      as.numeric(file.info(source_file_abs)$size),
      NA_real_
    ),
    agent_a_prompt_version = "agent_a_v1+common_schema_v1",
    agent_b_prompt_version = "agent_b_v1+common_schema_v1",
    agent_c_prompt_version = "agent_c_v1+common_schema_v1"
  ) |>
  dplyr::select(
    pid, title, authors, year, journal_title, language, url_scielo,
    source_file, source_file_exists, input_text_hash, input_text_bytes, source_has_body,
    raw_fulltext_file, raw_fulltext_file_exists, raw_fulltext_hash,
    raw_fulltext_same_hash, raw_fulltext_has_body,
    agent_a_prompt_version, agent_b_prompt_version, agent_c_prompt_version
  )

missing_xml <- manifest |>
  dplyr::filter(!source_file_exists)

if (nrow(missing_xml) > 0) {
  stop("XMLs ausentes para PIDs: ", paste(missing_xml$pid, collapse = ", "))
}

journal_exclusions <- excluded_journals |>
  dplyr::filter(exclude_from_analysis %in% c(TRUE, "TRUE", "true", 1, "1")) |>
  dplyr::select(journal_title, issn, exclusion_reason)

article_exclusions <- excluded_articles |>
  dplyr::filter(exclude_from_analysis %in% c(TRUE, "TRUE", "true", 1, "1")) |>
  dplyr::select(pid, article_exclusion_reason = exclusion_reason)

excluded_pids <- manifest |>
  dplyr::left_join(article_exclusions, by = "pid") |>
  dplyr::filter(!is.na(article_exclusion_reason))

excluded_journal_rows <- manifest |>
  dplyr::semi_join(journal_exclusions, by = "journal_title")

if (nrow(excluded_pids) > 0) {
  stop("Manifest contem artigos excluidos: ", paste(excluded_pids$pid, collapse = ", "))
}

if (nrow(excluded_journal_rows) > 0) {
  stop("Manifest contem periodicos excluidos: ", paste(unique(excluded_journal_rows$journal_title), collapse = "; "))
}

readr::write_csv(manifest, paths$manifest, na = "")

metadata <- list(
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  objective = "Piloto de classificacao tripla independente nos 175 artigos gold/elegiveis.",
  source_gold_pilot = relative_path(paths$gold),
  n_articles = nrow(manifest),
  excluded_journals_rule = relative_path(paths$excluded_journals),
  excluded_articles_rule = relative_path(paths$excluded_articles),
  manifest = relative_path(paths$manifest),
  prompt_versions = list(
    common = "common_schema_v1",
    agent_a = "agent_a_v1+common_schema_v1",
    agent_b = "agent_b_v1+common_schema_v1",
    agent_c = "agent_c_v1+common_schema_v1"
  ),
  no_api_runner = TRUE
)

jsonlite::write_json(metadata, paths$metadata, pretty = TRUE, auto_unbox = TRUE, null = "null")

journal_counts <- manifest |>
  dplyr::count(journal_title, name = "n") |>
  dplyr::arrange(dplyr::desc(n), journal_title)

markdown_table <- function(df) {
  if (nrow(df) == 0) {
    return("_Nenhum registro._")
  }
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- apply(df, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

summary_lines <- c(
  "# Manifest do piloto de classificacao tripla",
  "",
  paste("Gerado em", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Decisao operacional",
  "",
  "Este manifest usa os 175 PIDs de `data/processed/classifications_llm_main_analysis.csv` apenas como gold/piloto elegivel. A classificacao substantiva do corpus completo continua pendente e nao deve usar essa base como base final do paper.",
  "",
  "Nao ha chamada de API neste piloto. As classificacoes substantivas devem ser feitas por tres subagentes locais independentes, usando os XMLs e os prompts versionados.",
  "",
  "## Snapshot",
  "",
  markdown_table(tibble(
    item = c(
      "artigos no manifest",
      "XMLs presentes",
      "hash SHA-256 preenchido",
      "XML fonte com body",
      "raw fulltext presente",
      "raw fulltext identico ao XML fonte",
      "raw fulltext com body",
      "periodicos"
    ),
    value = c(
      nrow(manifest),
      sum(manifest$source_file_exists),
      sum(!is.na(manifest$input_text_hash)),
      sum(manifest$source_has_body),
      sum(manifest$raw_fulltext_file_exists),
      sum(manifest$raw_fulltext_same_hash),
      sum(manifest$raw_fulltext_has_body),
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
  paste0("- `", relative_path(paths$metadata), "`")
)

writeLines(summary_lines, paths$summary, useBytes = TRUE)

cat("Manifest preparado.\n")
cat("Artigos:", nrow(manifest), "\n")
cat("Arquivo:", paths$manifest, "\n")
