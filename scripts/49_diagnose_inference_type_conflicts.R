#!/usr/bin/env Rscript

## Recupera títulos e evidências textuais dos casos classificados
## simultaneamente como análise apenas descritiva e inferência positiva.

options(scipen = 999, encoding = "UTF-8")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

file_arg <- commandArgs(trailingOnly = FALSE) |>
  stringr::str_subset("^--file=") |>
  stringr::str_remove("^--file=")
if (length(file_arg) != 1) {
  stop("Não foi possível identificar o caminho do script.")
}

project_dir <- normalizePath(file.path(dirname(file_arg), ".."), mustWork = TRUE)
input_path <- file.path(
  project_dir,
  "data/processed/paper_analysis/paper_analysis_dataset_current.csv"
)
manifest_path <- file.path(
  project_dir,
  "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"
)
output_path <- file.path(
  project_dir,
  "quality_reports/paper_variable_audit/statistical_inference_type_conflicts_detail.csv"
)

analysis_df <- readr::read_csv(input_path, show_col_types = FALSE)
manifest_titles <- readr::read_csv(manifest_path, show_col_types = FALSE) |>
  dplyr::select(
    pid,
    title_manifest = title,
    doi,
    source_url
  )

required_columns <- c(
  "pid",
  "title",
  "journal_title",
  "year",
  "complete_journal",
  "is_empirical_quant_paper_torreblanca",
  "quantitative_analysis_type",
  "quantitative_analysis_evidence_quote",
  "has_statistical_inference",
  "statistical_inference_quote"
)
missing_columns <- setdiff(required_columns, names(analysis_df))
if (length(missing_columns) > 0) {
  stop("Colunas ausentes: ", paste(missing_columns, collapse = "; "))
}

conflicts <- analysis_df |>
  dplyr::filter(
    complete_journal %in% TRUE,
    is_empirical_quant_paper_torreblanca %in% TRUE,
    quantitative_analysis_type == "descriptive_statistics_only",
    has_statistical_inference %in% TRUE
  ) |>
  dplyr::left_join(manifest_titles, by = "pid") |>
  dplyr::mutate(title = dplyr::coalesce(title, title_manifest)) |>
  dplyr::arrange(year, journal_title, pid) |>
  dplyr::select(
    pid,
    title,
    journal_title,
    year,
    doi,
    source_url,
    quantitative_analysis_type,
    quantitative_analysis_evidence_quote,
    has_statistical_inference,
    statistical_inference_quote
  )

if (nrow(conflicts) != 9) {
  stop("Esperavam-se nove conflitos; foram encontrados ", nrow(conflicts), ".")
}
if (dplyr::n_distinct(conflicts$pid) != nrow(conflicts)) {
  stop("Há PIDs duplicados no diagnóstico.")
}
if (any(is.na(conflicts$title) | conflicts$title == "")) {
  stop("Há conflito sem título.")
}
if (any(is.na(conflicts$statistical_inference_quote) | conflicts$statistical_inference_quote == "")) {
  stop("Há conflito sem citação comprobatória de inferência.")
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(conflicts, output_path, na = "")

message("Diagnóstico salvo: ", output_path, " (", nrow(conflicts), " artigos).")
