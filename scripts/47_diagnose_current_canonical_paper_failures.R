#!/usr/bin/env Rscript

## Diagnostica, sem alterar dados, inconsistências do CSV canônico que
## bloqueiam a atualização dos artefatos analíticos do paper.

options(scipen = 999, encoding = "UTF-8")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
})

file_arg <- commandArgs(trailingOnly = FALSE) |>
  stringr::str_subset("^--file=") |>
  stringr::str_remove("^--file=")
if (length(file_arg) != 1L) {
  stop("Não foi possível identificar o caminho do script.")
}

project_dir <- normalizePath(file.path(dirname(file_arg), ".."), mustWork = TRUE)
path <- function(...) file.path(project_dir, ...)

canonical_path <- path(
  "data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv"
)
manifest_path <- path("data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv")
excluded_articles_path <- path("data/processed/excluded_articles.csv")
excluded_journals_path <- path("data/processed/excluded_journals.csv")
output_dir <- path("quality_reports/paper_variable_audit")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(canonical_path), file.exists(manifest_path))

parse_bool <- function(x) {
  value <- stringr::str_to_upper(stringr::str_trim(dplyr::coalesce(as.character(x), "")))
  dplyr::case_when(
    value == "TRUE" ~ TRUE,
    value == "FALSE" ~ FALSE,
    TRUE ~ NA
  )
}

quantitative_levels <- c(
  "none",
  "descriptive_statistics_only",
  "bivariate_tests_or_correlations_only",
  "statistical_modeling"
)

canonical <- readr::read_csv(canonical_path, show_col_types = FALSE)
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)

excluded_pids <- if (file.exists(excluded_articles_path)) {
  readr::read_csv(excluded_articles_path, show_col_types = FALSE) |>
    dplyr::pull(pid)
} else {
  character()
}

excluded_journals <- if (file.exists(excluded_journals_path)) {
  readr::read_csv(excluded_journals_path, show_col_types = FALSE) |>
    dplyr::pull(journal_title)
} else {
  character()
}

eligible_pids <- manifest |>
  dplyr::filter(
    !pid %in% excluded_pids,
    !journal_title %in% excluded_journals
  ) |>
  dplyr::pull(pid)

diagnostic_base <- canonical |>
  dplyr::filter(pid %in% eligible_pids) |>
  dplyr::mutate(
    quant_flag = parse_bool(is_empirical_quant_paper_torreblanca),
    inference_flag = parse_bool(has_statistical_inference),
    quantitative_analysis_type = stringr::str_trim(quantitative_analysis_type)
  )

diagnostics <- diagnostic_base |>
  dplyr::mutate(
    statistical_inference_without_quantitative_flag =
      dplyr::coalesce(inference_flag, FALSE) & !dplyr::coalesce(quant_flag, FALSE),
    statistical_inference_without_quantitative_analysis =
      dplyr::coalesce(inference_flag, FALSE) & quantitative_analysis_type == "none",
    statistical_inference_missing_within_quantitative =
      dplyr::coalesce(quant_flag, FALSE) & is.na(inference_flag),
    unknown_quantitative_level =
      !is.na(quantitative_analysis_type) &
      quantitative_analysis_type != "" &
      !quantitative_analysis_type %in% quantitative_levels
  ) |>
  tidyr::pivot_longer(
    cols = dplyr::all_of(c(
      "statistical_inference_without_quantitative_flag",
      "statistical_inference_without_quantitative_analysis",
      "statistical_inference_missing_within_quantitative",
      "unknown_quantitative_level"
    )),
    names_to = "failed_check",
    values_to = "failed"
  ) |>
  dplyr::filter(failed) |>
  dplyr::select(
    failed_check,
    pid,
    title,
    journal_title,
    is_empirical_paper,
    empirical_evidence_type,
    is_empirical_quant_paper_torreblanca,
    quantitative_analysis_type,
    quantitative_analysis_evidence_quote,
    has_statistical_inference,
    statistical_inference_quote,
    tough_call,
    tough_call_reason,
    brief_justification
  ) |>
  dplyr::arrange(failed_check, journal_title, pid)

level_counts <- diagnostic_base |>
  dplyr::count(quantitative_analysis_type, sort = TRUE, name = "n") |>
  dplyr::mutate(
    known_level = quantitative_analysis_type %in% quantitative_levels,
    missing_level = is.na(quantitative_analysis_type) | quantitative_analysis_type == ""
  ) |>
  dplyr::arrange(known_level, missing_level, dplyr::desc(n), quantitative_analysis_type)

check_summary <- diagnostics |>
  dplyr::count(failed_check, name = "failure_rows") |>
  dplyr::arrange(failed_check)

readr::write_csv(
  diagnostics,
  file.path(output_dir, "current_canonical_failure_diagnostics.csv")
)
readr::write_csv(
  level_counts,
  file.path(output_dir, "current_canonical_quantitative_level_counts.csv")
)

diagnostic_lines <- c(
  "# Diagnóstico das falhas do CSV canônico na análise do paper",
  "",
  paste0("- Data de execução: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  paste0("- CSV canônico: `", canonical_path, "`"),
  paste0("- Dimensão do CSV: ", format(nrow(canonical), big.mark = "."), " linhas x ", ncol(canonical), " colunas"),
  paste0("- PIDs elegíveis classificados: ", dplyr::n_distinct(diagnostic_base$pid)),
  paste0("- PIDs distintos com ao menos uma falha: ", dplyr::n_distinct(diagnostics$pid)),
  "",
  "## Contagem por validação",
  "",
  if (nrow(check_summary) == 0L) {
    "Nenhuma falha encontrada."
  } else {
    paste0("- `", check_summary$failed_check, "`: ", check_summary$failure_rows)
  },
  "",
  "## Níveis de `quantitative_analysis_type`",
  "",
  paste0(
    "- `",
    ifelse(is.na(level_counts$quantitative_analysis_type) | level_counts$quantitative_analysis_type == "", "<ausente>", level_counts$quantitative_analysis_type),
    "`: ",
    level_counts$n,
    ifelse(level_counts$known_level, " (previsto)", ifelse(level_counts$missing_level, " (ausente)", " (fora da taxonomia)"))
  ),
  "",
  "## Artefatos",
  "",
  "- `quality_reports/paper_variable_audit/current_canonical_failure_diagnostics.csv`",
  "- `quality_reports/paper_variable_audit/current_canonical_quantitative_level_counts.csv`"
)

writeLines(
  enc2utf8(diagnostic_lines),
  con = file.path(output_dir, "current_canonical_failure_diagnostics.md"),
  useBytes = TRUE
)

message(
  "Diagnóstico concluído: ",
  dplyr::n_distinct(diagnostics$pid),
  " PIDs distintos com falhas."
)
