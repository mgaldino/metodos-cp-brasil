#!/usr/bin/env Rscript

## Reconcile the previously generated gender classification with the paper's
## current eligibility ledger. This does not reclassify names; it removes only
## PIDs already marked as ineligible by the canonical ledger.

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
if (length(file_arg) != 1) stop("Não foi possível identificar o caminho do script.")
project_dir <- normalizePath(file.path(dirname(file_arg), ".."), mustWork = TRUE)
path <- function(...) file.path(project_dir, ...)

input_path <- path("data/processed/gender_analysis/current_canonical_article_gender.csv")
ledger_path <- path("data/processed/excluded_articles.csv")
output_path <- path("data/processed/gender_analysis/current_canonical_article_gender_paper_scope.csv")
summary_path <- path("output/tables/gender_analysis/table_3_methodological_indicators_by_first_author_gender_paper_scope.csv")
standardized_path <- path("output/tables/gender_analysis/table_7_standardized_comparison_journal_period_paper_scope.csv")
report_path <- path("quality_reports/gender_analysis_paper_scope_reconciliation.md")

if (!all(file.exists(c(input_path, ledger_path)))) {
  stop("Arquivos de entrada ausentes.")
}

parse_bool <- function(x) {
  value <- stringr::str_to_upper(stringr::str_trim(dplyr::coalesce(as.character(x), "")))
  dplyr::case_when(value == "TRUE" ~ TRUE, value == "FALSE" ~ FALSE, TRUE ~ NA)
}

article_gender <- readr::read_csv(input_path, show_col_types = FALSE) |>
  dplyr::mutate(
    is_empirical_paper = parse_bool(is_empirical_paper),
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    has_statistical_inference = parse_bool(has_statistical_inference),
    causal_or_explanatory_claim_present = parse_bool(causal_or_explanatory_claim_present),
    credibility_revolution_screen_applicable = parse_bool(credibility_revolution_screen_applicable),
    strict_design_method = parse_bool(strict_design_method)
  )
excluded_articles <- readr::read_csv(ledger_path, show_col_types = FALSE) |>
  dplyr::mutate(exclude_from_analysis = parse_bool(exclude_from_analysis)) |>
  dplyr::filter(dplyr::coalesce(exclude_from_analysis, FALSE)) |>
  dplyr::select(pid, exclusion_reason)

paper_scope <- article_gender |>
  dplyr::anti_join(excluded_articles |> dplyr::select(pid), by = "pid")

if (anyDuplicated(paper_scope$pid) > 0) stop("A base reconciliada contém PIDs duplicados.")
if (nrow(paper_scope) != 4144L) {
  stop("O universo reconciliado deveria conter 4.144 artigos; encontrou ", nrow(paper_scope), ".")
}
if (dplyr::n_distinct(paper_scope$journal_title) != 9L) {
  stop("O universo reconciliado deveria conter nove periódicos.")
}

metric_levels <- c(
  "Artigos empíricos", "Análise quantitativa", "Inferência estatística",
  "Linguagem causal ou explicativa", "Examinados para identificação",
  "Estratégia explícita de identificação"
)
binary <- paper_scope |>
  dplyr::filter(first_author_gender %in% c("Feminino", "Masculino"))

metric_summary <- function(data, group_var) {
  data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_var))) |>
    dplyr::summarise(
      n_articles = dplyr::n(),
      n_empirical = sum(is_empirical_paper %in% TRUE),
      n_quantitative = sum(is_empirical_paper %in% TRUE & is_empirical_quant_paper_torreblanca %in% TRUE),
      n_quantitative_observed = sum(is_empirical_paper %in% TRUE & !is.na(is_empirical_quant_paper_torreblanca)),
      n_inference = sum(is_empirical_quant_paper_torreblanca %in% TRUE & has_statistical_inference %in% TRUE),
      n_inference_observed = sum(is_empirical_quant_paper_torreblanca %in% TRUE & !is.na(has_statistical_inference)),
      n_claim = sum(is_empirical_paper %in% TRUE & causal_or_explanatory_claim_present %in% TRUE),
      n_claim_observed = sum(is_empirical_paper %in% TRUE & !is.na(causal_or_explanatory_claim_present)),
      n_screen = sum(credibility_revolution_screen_applicable %in% TRUE),
      n_screen_observed = sum(!is.na(credibility_revolution_screen_applicable)),
      n_strict = sum(credibility_revolution_screen_applicable %in% TRUE & strict_design_method %in% TRUE),
      .groups = "drop"
    ) |>
    tidyr::crossing(metric = factor(metric_levels, levels = metric_levels)) |>
    dplyr::mutate(
      numerator = dplyr::case_when(
        metric == "Artigos empíricos" ~ n_empirical,
        metric == "Análise quantitativa" ~ n_quantitative,
        metric == "Inferência estatística" ~ n_inference,
        metric == "Linguagem causal ou explicativa" ~ n_claim,
        metric == "Examinados para identificação" ~ n_screen,
        metric == "Estratégia explícita de identificação" ~ n_strict
      ),
      denominator = dplyr::case_when(
        metric == "Artigos empíricos" ~ n_articles,
        metric == "Análise quantitativa" ~ n_quantitative_observed,
        metric == "Inferência estatística" ~ n_inference_observed,
        metric == "Linguagem causal ou explicativa" ~ n_claim_observed,
        metric == "Examinados para identificação" ~ n_screen_observed,
        metric == "Estratégia explícita de identificação" ~ n_screen
      ),
      percent = 100 * numerator / denominator
    ) |>
    dplyr::select(dplyr::all_of(group_var), metric, numerator, denominator, percent)
}

metric_comparison <- metric_summary(binary, "first_author_gender") |>
  dplyr::select(first_author_gender, metric, numerator, denominator, percent) |>
  tidyr::pivot_wider(
    names_from = first_author_gender,
    values_from = c(numerator, denominator, percent),
    names_glue = "{.value}_{first_author_gender}"
  ) |>
  dplyr::mutate(difference_pp_female_minus_male = percent_Feminino - percent_Masculino) |>
  dplyr::arrange(factor(metric, levels = metric_levels))

standardized <- metric_summary(binary, c("first_author_gender", "journal_title", "period_3")) |>
  dplyr::select(first_author_gender, journal_title, period_3, metric, denominator, percent) |>
  tidyr::pivot_wider(
    names_from = first_author_gender,
    values_from = c(denominator, percent),
    names_glue = "{.value}_{first_author_gender}"
  ) |>
  dplyr::filter(denominator_Feminino > 0, denominator_Masculino > 0, !is.na(percent_Feminino), !is.na(percent_Masculino)) |>
  dplyr::group_by(metric) |>
  dplyr::mutate(weight = (denominator_Feminino + denominator_Masculino) / sum(denominator_Feminino + denominator_Masculino)) |>
  dplyr::summarise(
    n_common_strata = dplyr::n(),
    standardized_percent_female = sum(weight * percent_Feminino),
    standardized_percent_male = sum(weight * percent_Masculino),
    standardized_difference_pp = standardized_percent_female - standardized_percent_male,
    .groups = "drop"
  ) |>
  dplyr::arrange(factor(metric, levels = metric_levels))

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(summary_path), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(paper_scope, output_path)
readr::write_csv(metric_comparison, summary_path)
readr::write_csv(standardized, standardized_path)

writeLines(c(
  "# Reconciliação da análise de gênero com o escopo do paper",
  "",
  "O relatório original de gênero partia do arquivo de autoria já classificado e removia os dois periódicos excluídos. O paper, porém, também aplica o ledger de artigos inelegíveis. Este script reproduz essa segunda etapa sem reclassificar prenomes.",
  "",
  paste0("- Base original de autoria: ", nrow(article_gender), " artigos."),
  paste0("- PIDs removidos pelo ledger: ", sum(article_gender$pid %in% excluded_articles$pid), "."),
  paste0("- Base reconciliada usada no paper: ", nrow(paper_scope), " artigos em nove periódicos."),
  paste0("- Arquivo derivado: `", sub(paste0(project_dir, "/"), "", output_path, fixed = TRUE), "`."),
  paste0("- Tabelas derivadas: `", sub(paste0(project_dir, "/"), "", summary_path, fixed = TRUE), "` e `", sub(paste0(project_dir, "/"), "", standardized_path, fixed = TRUE), "`."),
  "",
  "A classificação dos prenomes continua sendo a produzida por `scripts/51_analyze_gender_current_canonical.R`; o denominador analítico é agora idêntico ao do paper."
), report_path, useBytes = TRUE)

message("Base de gênero reconciliada: ", nrow(paper_scope), " artigos.")
