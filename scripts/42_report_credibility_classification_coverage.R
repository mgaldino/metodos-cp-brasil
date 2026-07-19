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
excluded_journals_path <- file.path(project_dir, "data/processed/excluded_journals.csv")
csv_out <- file.path(project_dir, "quality_reports/credibility_classification_coverage_by_journal.csv")
md_out <- file.path(project_dir, "quality_reports/credibility_classification_coverage_by_journal.md")

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE) |>
  dplyr::select(pid, journal_title)

classifications <- readr::read_csv(classifications_path, show_col_types = FALSE) |>
  dplyr::select(pid) |>
  dplyr::distinct()

excluded <- readr::read_csv(excluded_path, show_col_types = FALSE) |>
  dplyr::filter(exclude_from_analysis) |>
  dplyr::select(pid)

excluded_journals <- readr::read_csv(excluded_journals_path, show_col_types = FALSE) |>
  dplyr::filter(exclude_from_analysis) |>
  dplyr::select(journal_title, exclusion_reason, notes) |>
  dplyr::distinct(journal_title, .keep_all = TRUE)

coverage <- manifest |>
  dplyr::left_join(classifications |> dplyr::mutate(classified = TRUE), by = "pid") |>
  dplyr::left_join(excluded |> dplyr::mutate(article_excluded = TRUE), by = "pid") |>
  dplyr::left_join(
    excluded_journals |> dplyr::mutate(journal_excluded = TRUE),
    by = "journal_title"
  ) |>
  dplyr::mutate(
    classified = dplyr::coalesce(classified, FALSE),
    article_excluded = dplyr::coalesce(article_excluded, FALSE),
    journal_excluded = dplyr::coalesce(journal_excluded, FALSE),
    analysis_eligible = !article_excluded & !journal_excluded
  ) |>
  dplyr::group_by(journal_title, journal_excluded, exclusion_reason, notes) |>
  dplyr::summarise(
    manifest_n = dplyr::n(),
    article_excluded_n = sum(article_excluded),
    journal_excluded_n = sum(journal_excluded & !article_excluded),
    preserved_classified_n = sum(classified),
    analysis_eligible_n = sum(analysis_eligible),
    classified_n = sum(classified & analysis_eligible),
    remaining_n = sum(!classified & analysis_eligible),
    future_pending_n = dplyr::if_else(
      dplyr::first(journal_excluded),
      sum(!classified & !article_excluded),
      0L
    ),
    coverage_percent = dplyr::if_else(
      analysis_eligible_n > 0,
      round(100 * classified_n / analysis_eligible_n, 1),
      NA_real_
    ),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    status = dplyr::case_when(
      journal_excluded ~ "não elegível por ora",
      remaining_n == 0 ~ "completo",
      classified_n == 0 ~ "não iniciado",
      TRUE ~ "parcial"
    )
  ) |>
  dplyr::arrange(journal_excluded, dplyr::desc(coverage_percent), journal_title)

readr::write_csv(coverage, csv_out, na = "")

totals <- coverage |>
  dplyr::summarise(
    manifest_n = sum(manifest_n),
    article_excluded_n = sum(article_excluded_n),
    journal_excluded_n = sum(journal_excluded_n),
    preserved_classified_n = sum(preserved_classified_n),
    analysis_eligible_n = sum(analysis_eligible_n),
    classified_n = sum(classified_n),
    remaining_n = sum(remaining_n)
  )

active_coverage <- coverage |>
  dplyr::filter(!journal_excluded)

future_pending <- coverage |>
  dplyr::filter(journal_excluded, manifest_n > 0)

table_lines <- c(
  "periódico | elegíveis | classificados | faltantes | cobertura | status",
  "--- | ---: | ---: | ---: | ---: | ---",
  sprintf(
    "%s | %d | %d | %d | %.1f%% | %s",
    active_coverage$journal_title,
    active_coverage$analysis_eligible_n,
    active_coverage$classified_n,
    active_coverage$remaining_n,
    active_coverage$coverage_percent,
    active_coverage$status
  )
)

future_lines <- c(
  "periódico | universo preservado | classificados preservados | pendência futura | status",
  "--- | ---: | ---: | ---: | ---",
  sprintf(
    "%s | %d | %d | %d | %s",
    future_pending$journal_title,
    future_pending$manifest_n - future_pending$article_excluded_n,
    future_pending$preserved_classified_n,
    future_pending$future_pending_n,
    future_pending$status
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
  sprintf("- Classificações preservadas no CSV canônico: %d", totals$preserved_classified_n),
  sprintf("- Exclusões documentadas por artigo presentes no manifesto: %d", totals$article_excluded_n),
  sprintf("- Registros não elegíveis por periódico nesta versão: %d", totals$journal_excluded_n),
  sprintf("- Artigos elegíveis para análise: %d", totals$analysis_eligible_n),
  sprintf("- Artigos classificados: %d", totals$classified_n),
  sprintf("- Artigos ainda não classificados: %d", totals$remaining_n),
  "",
  "## Tabela 1. Cobertura por periódico",
  "",
  table_lines,
  "",
  "## Tabela 2. Periódicos não elegíveis por ora e preservados para classificação futura",
  "",
  future_lines,
  "",
  "## Regra",
  "",
  "A contagem parte do manifesto integral, aplica os ledgers canônicos de exclusões por artigo e por periódico e considera classificado apenas o PID presente no CSV combinado validado. Os periódicos marcados como `não elegível por ora` permanecem integralmente preservados no manifesto, nos textos e no CSV canônico, mas ficam fora do denominador analítico desta versão. `Completo` significa zero faltantes entre os artigos atualmente elegíveis.",
  ""
)

writeLines(report, md_out, useBytes = TRUE)
message("CSV escrito em: ", csv_out)
message("Relatório escrito em: ", md_out)
