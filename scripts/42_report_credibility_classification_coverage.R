#!/usr/bin/env Rscript

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

manifest_path <- file.path(
  project_dir,
  "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"
)
classifications_path <- file.path(
  project_dir,
  "data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv"
)
excluded_path <- file.path(project_dir, "data/processed/excluded_articles.csv")
csv_out <- file.path(project_dir, "quality_reports/credibility_classification_coverage_by_journal.csv")
md_out <- file.path(project_dir, "quality_reports/credibility_classification_coverage_by_journal.md")

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE) |>
  dplyr::select(pid, journal_title)

classifications <- readr::read_csv(classifications_path, show_col_types = FALSE) |>
  dplyr::select(pid) |>
  dplyr::distinct()

excluded <- readr::read_csv(excluded_path, show_col_types = FALSE) |>
  dplyr::filter(exclude_from_analysis) |>
  dplyr::select(pid, exclusion_reason)

coverage <- manifest |>
  dplyr::left_join(classifications |> dplyr::mutate(classified = TRUE), by = "pid") |>
  dplyr::left_join(excluded |> dplyr::mutate(excluded = TRUE), by = "pid") |>
  dplyr::mutate(
    classified = dplyr::coalesce(classified, FALSE),
    excluded = dplyr::coalesce(excluded, FALSE),
    analysis_eligible = !excluded
  ) |>
  dplyr::group_by(journal_title) |>
  dplyr::summarise(
    manifest_n = dplyr::n(),
    excluded_n = sum(excluded),
    analysis_eligible_n = sum(analysis_eligible),
    classified_n = sum(classified & analysis_eligible),
    remaining_n = sum(!classified & analysis_eligible),
    coverage_percent = round(100 * classified_n / analysis_eligible_n, 1),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    status = dplyr::case_when(
      remaining_n == 0 ~ "completo",
      classified_n == 0 ~ "não iniciado",
      TRUE ~ "parcial"
    )
  ) |>
  dplyr::arrange(dplyr::desc(coverage_percent), journal_title)

readr::write_csv(coverage, csv_out, na = "")

totals <- coverage |>
  dplyr::summarise(
    manifest_n = sum(manifest_n),
    excluded_n = sum(excluded_n),
    analysis_eligible_n = sum(analysis_eligible_n),
    classified_n = sum(classified_n),
    remaining_n = sum(remaining_n)
  )

table_lines <- c(
  "periódico | elegíveis | classificados | faltantes | cobertura | status",
  "--- | ---: | ---: | ---: | ---: | ---",
  sprintf(
    "%s | %d | %d | %d | %.1f%% | %s",
    coverage$journal_title,
    coverage$analysis_eligible_n,
    coverage$classified_n,
    coverage$remaining_n,
    coverage$coverage_percent,
    coverage$status
  )
)

report <- c(
  "# Cobertura atual da classificação por periódico",
  "",
  sprintf("Gerado em: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Totais",
  "",
  sprintf("- Registros no manifesto: %d", totals$manifest_n),
  sprintf("- Exclusões documentadas presentes no manifesto: %d", totals$excluded_n),
  sprintf("- Artigos elegíveis para análise: %d", totals$analysis_eligible_n),
  sprintf("- Artigos classificados: %d", totals$classified_n),
  sprintf("- Artigos ainda não classificados: %d", totals$remaining_n),
  "",
  "## Tabela 1. Cobertura por periódico",
  "",
  table_lines,
  "",
  "## Regra",
  "",
  "A contagem parte do manifesto integral, remove os PIDs com `exclude_from_analysis = TRUE` no ledger canônico e considera classificado apenas o PID presente no CSV combinado validado. `Completo` significa zero faltantes após exclusões documentadas.",
  ""
)

writeLines(report, md_out, useBytes = TRUE)
message("CSV escrito em: ", csv_out)
message("Relatório escrito em: ", md_out)
