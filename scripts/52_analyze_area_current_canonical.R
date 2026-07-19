#!/usr/bin/env Rscript

## Analisa diferenças descritivas entre Ciência Política e Relações Internacionais
## no corpus analítico corrente. A unidade é o artigo; os denominadores variam
## conforme a dimensão e são preservados nas tabelas de saída.

options(scipen = 999, encoding = "UTF-8")
set.seed(20260719)

required_packages <- c("dplyr", "readr", "stringr", "tibble", "tidyr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]
if (length(missing_packages) > 0) {
  stop("Pacotes ausentes: ", paste(missing_packages, collapse = ", "))
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
})

file_arg <- commandArgs(trailingOnly = FALSE) |>
  stringr::str_subset("^--file=") |>
  stringr::str_remove("^--file=")
if (length(file_arg) != 1) {
  stop("Não foi possível identificar o caminho do script.")
}

project_dir <- normalizePath(file.path(dirname(file_arg), ".."), mustWork = TRUE)
path <- function(...) file.path(project_dir, ...)

input_path <- path("data/processed/paper_analysis/paper_analysis_dataset_current.csv")
tables_dir <- path("output/tables/area_analysis")
processed_dir <- path("data/processed/area_analysis")
report_path <- path("quality_reports/area_analysis_current_canonical.md")
session_path <- path("data/processed/area_analysis/area_analysis_session_info.txt")

dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_path)) {
  stop("Dataset analítico ausente: ", input_path)
}

period_levels <- c("2005-2011", "2012-2018", "2019-2025")
comparison_area_levels <- c(
  "Ciência Política (inclui escopo compartilhado)",
  "Relações Internacionais"
)

parse_bool <- function(x) {
  value <- stringr::str_to_upper(stringr::str_trim(as.character(x)))
  dplyr::case_when(
    value == "TRUE" ~ TRUE,
    value == "FALSE" ~ FALSE,
    TRUE ~ NA
  )
}

as_true <- function(x) {
  !is.na(x) & x
}

safe_pct <- function(numerator, denominator) {
  ifelse(denominator > 0, round(100 * numerator / denominator, 1), NA_real_)
}

fmt_int <- function(x) {
  format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

fmt_pct <- function(x) {
  ifelse(
    is.na(x),
    "-",
    paste0(format(x, decimal.mark = ",", nsmall = 1, trim = TRUE), "%")
  )
}

escape_md <- function(x) {
  as.character(x) |>
    stringr::str_replace_all("\\|", "\\\\|") |>
    stringr::str_replace_all("\\r?\\n", " ")
}

markdown_table <- function(data) {
  data_chr <- data |>
    dplyr::mutate(
      dplyr::across(
        dplyr::everything(),
        ~ escape_md(dplyr::coalesce(as.character(.x), "-"))
      )
    )
  header <- paste0("| ", paste(names(data_chr), collapse = " | "), " |")
  separator <- paste0("| ", paste(rep("---", ncol(data_chr)), collapse = " | "), " |")
  rows <- apply(data_chr, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  c(header, separator, rows)
}

write_utf8_lines <- function(lines, file) {
  connection <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(connection), add = TRUE)
  writeLines(enc2utf8(lines), con = connection, useBytes = TRUE)
}

analysis_df <- readr::read_csv(input_path, show_col_types = FALSE) |>
  dplyr::mutate(
    is_empirical_paper = parse_bool(is_empirical_paper),
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    has_statistical_inference = parse_bool(has_statistical_inference),
    credibility_revolution_screen_applicable = parse_bool(credibility_revolution_screen_applicable),
    strict_design_method = parse_bool(strict_design_method),
    journal_area_source = journal_area,
    area_group = dplyr::case_when(
      journal_area %in% c("Ciência Política", "Ciência Política e Ciências Sociais") ~
        comparison_area_levels[1],
      journal_area == "Relações Internacionais" ~ comparison_area_levels[2],
      TRUE ~ NA_character_
    ),
    period_3 = as.character(period_3)
  )

required_columns <- c(
  "pid", "journal_title", "journal_area_source", "area_group", "period_3",
  "is_empirical_paper", "is_empirical_quant_paper_torreblanca",
  "has_statistical_inference", "credibility_revolution_screen_applicable",
  "strict_design_method"
)
missing_columns <- setdiff(required_columns, names(analysis_df))
if (length(missing_columns) > 0) {
  stop("Colunas ausentes no dataset analítico: ", paste(missing_columns, collapse = ", "))
}

if (anyDuplicated(analysis_df$pid) > 0) {
  stop("O dataset analítico contém PIDs duplicados.")
}

if (any(!analysis_df$period_3 %in% period_levels)) {
  stop("Há períodos fora da classificação 2005-2011/2012-2018/2019-2025.")
}

summarize_area <- function(data, groups) {
  data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(groups))) |>
    dplyr::summarise(
      journals_n = dplyr::n_distinct(journal_title),
      articles_n = dplyr::n(),
      empirical_n = sum(as_true(is_empirical_paper)),
      quantitative_n = sum(as_true(is_empirical_quant_paper_torreblanca)),
      quantitative_den_empirical = empirical_n,
      inference_n = sum(as_true(has_statistical_inference) &
        as_true(is_empirical_quant_paper_torreblanca)),
      inference_den_observed = sum(
        as_true(is_empirical_quant_paper_torreblanca) & !is.na(has_statistical_inference)
      ),
      inference_missing_n = sum(
        as_true(is_empirical_quant_paper_torreblanca) & is.na(has_statistical_inference)
      ),
      screen_n = sum(as_true(credibility_revolution_screen_applicable)),
      strict_n = sum(as_true(strict_design_method)),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      pct_empirical = safe_pct(empirical_n, articles_n),
      pct_quantitative_empirical = safe_pct(quantitative_n, quantitative_den_empirical),
      pct_inference_quantitative_observed = safe_pct(inference_n, inference_den_observed),
      pct_screen_all = safe_pct(screen_n, articles_n),
      pct_strict_screen = safe_pct(strict_n, screen_n)
    )
}

area_profile <- analysis_df |>
  dplyr::filter(!is.na(area_group)) |>
  summarize_area("area_group") |>
  dplyr::mutate(area_group = factor(area_group, levels = comparison_area_levels)) |>
  dplyr::arrange(area_group) |>
  dplyr::mutate(area_group = as.character(area_group))

source_area_profile <- analysis_df |>
  summarize_area("journal_area_source") |>
  dplyr::arrange(journal_area_source)

area_period_profile <- analysis_df |>
  dplyr::filter(!is.na(area_group)) |>
  summarize_area(c("area_group", "period_3")) |>
  dplyr::mutate(
    area_group = factor(area_group, levels = comparison_area_levels),
    period_3 = factor(period_3, levels = period_levels)
  ) |>
  dplyr::arrange(area_group, period_3) |>
  dplyr::mutate(
    area_group = as.character(area_group),
    period_3 = as.character(period_3)
  )

journal_composition <- analysis_df |>
  dplyr::filter(!is.na(area_group)) |>
  dplyr::count(area_group, journal_area_source, journal_title, name = "articles_n") |>
  dplyr::mutate(area_group = factor(area_group, levels = comparison_area_levels)) |>
  dplyr::arrange(area_group, journal_title) |>
  dplyr::mutate(area_group = as.character(area_group))

method_long_path <- path("data/processed/paper_analysis/paper_method_long_current.csv")
if (file.exists(method_long_path)) {
  strict_method_profile <- readr::read_csv(method_long_path, show_col_types = FALSE) |>
    dplyr::mutate(
      area_group = dplyr::case_when(
        journal_area %in% c("Ciência Política", "Ciência Política e Ciências Sociais") ~
          comparison_area_levels[1],
        journal_area == "Relações Internacionais" ~ comparison_area_levels[2],
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::filter(method_class == "strict_design_method", !is.na(area_group)) |>
    dplyr::count(area_group, method_type, name = "article_method_mentions") |>
    dplyr::mutate(area_group = factor(area_group, levels = comparison_area_levels)) |>
    dplyr::arrange(area_group, dplyr::desc(article_method_mentions), method_type) |>
    dplyr::mutate(area_group = as.character(area_group))
} else {
  strict_method_profile <- tibble::tibble(
    area_group = character(), method_type = character(), article_method_mentions = integer()
  )
}

readr::write_csv(area_profile, file.path(tables_dir, "area_profile.csv"))
readr::write_csv(source_area_profile, file.path(tables_dir, "source_area_profile.csv"))
readr::write_csv(area_period_profile, file.path(tables_dir, "area_period_profile.csv"))
readr::write_csv(journal_composition, file.path(tables_dir, "area_journal_composition.csv"))
readr::write_csv(strict_method_profile, file.path(tables_dir, "area_strict_method_profile.csv"))

cp <- area_profile |>
  dplyr::filter(area_group == comparison_area_levels[1])
ri <- area_profile |>
  dplyr::filter(area_group == comparison_area_levels[2])

if (nrow(cp) != 1 || nrow(ri) != 1) {
  stop("A comparação CP–RI não produziu exatamente uma linha por área.")
}

cp_period <- area_period_profile |>
  dplyr::filter(area_group == comparison_area_levels[1])
ri_period <- area_period_profile |>
  dplyr::filter(area_group == comparison_area_levels[2])

checks <- tibble::tribble(
  ~check, ~status, ~value,
  "Linhas no dataset analítico", "PASS", nrow(analysis_df),
  "PIDs únicos", "PASS", dplyr::n_distinct(analysis_df$pid),
  "Áreas de origem não mapeadas", "PASS", sum(is.na(analysis_df$journal_area_source)),
  "Artigos fora da comparação CP–RI", "INFO", sum(is.na(analysis_df$area_group)),
  "Soma dos artigos CP e RI", "PASS", cp$articles_n + ri$articles_n,
  "PIDs duplicados", "PASS", 0,
  "Períodos fora do suporte", "PASS", sum(!analysis_df$period_3 %in% period_levels),
  "Rótulos de inferência ausentes em CP", "INFO", cp$inference_missing_n,
  "Rótulos de inferência ausentes em RI", "INFO", ri$inference_missing_n
)
readr::write_csv(checks, file.path(processed_dir, "area_analysis_checks.csv"))

source_table <- source_area_profile |>
  dplyr::transmute(
    `Área de origem` = journal_area_source,
    `Periódicos` = journals_n,
    `Artigos` = articles_n,
    `Empíricos` = paste0(fmt_int(empirical_n), " (", fmt_pct(pct_empirical), ")"),
    `Quantitativos entre empíricos` = paste0(
      fmt_int(quantitative_n), " (", fmt_pct(pct_quantitative_empirical), ")"
    ),
    `Inferência entre quantitativos observados` = paste0(
      fmt_int(inference_n), " (", fmt_pct(pct_inference_quantitative_observed), ")"
    )
  )

comparison_table <- area_profile |>
  dplyr::transmute(
    Área = area_group,
    `Periódicos` = journals_n,
    `Artigos` = articles_n,
    `Empíricos` = paste0(fmt_int(empirical_n), " / ", fmt_int(articles_n),
      " (", fmt_pct(pct_empirical), ")"),
    `Quantitativos` = paste0(fmt_int(quantitative_n), " / ", fmt_int(quantitative_den_empirical),
      " (", fmt_pct(pct_quantitative_empirical), ")"),
    `Inferência` = paste0(fmt_int(inference_n), " / ", fmt_int(inference_den_observed),
      " (", fmt_pct(pct_inference_quantitative_observed), ")"),
    `Estratégia causal explícita` = paste0(fmt_int(strict_n), " / ", fmt_int(screen_n),
      " (", fmt_pct(pct_strict_screen), ")")
  )

period_table <- area_period_profile |>
  dplyr::transmute(
    Área = area_group,
    Período = period_3,
    `Artigos` = fmt_int(articles_n),
    `Inferência` = paste0(fmt_int(inference_n), " / ", fmt_int(inference_den_observed),
      " (", fmt_pct(pct_inference_quantitative_observed), ")"),
    `Estratégia causal explícita` = paste0(fmt_int(strict_n), " / ", fmt_int(screen_n),
      " (", fmt_pct(pct_strict_screen), ")")
  )

report_lines <- c(
  "# Análise por área no CSV canônico corrente",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Regra de agrupamento",
  "",
  "A comparação principal reúne como Ciência Política os periódicos classificados como Ciência Política e os dois periódicos de escopo compartilhado com Ciências Sociais (Dados e Revista Brasileira de Ciências Sociais). Relações Internacionais reúne Contexto Internacional e Revista Brasileira de Política Internacional. Cadernos Gestão Pública e Cidadania permanece preservada no perfil por área de origem, mas não entra no contraste CP–RI porque está classificada como Administração Pública.",
  "",
  "A área é uma característica editorial do periódico, não uma classificação temática artigo a artigo. As diferenças são descritivas e não estimam efeito causal da área.",
  "",
  "## Perfil por área de origem",
  "",
  markdown_table(source_table),
  "",
  "## Contraste CP–RI",
  "",
  markdown_table(comparison_table),
  "",
  "## Variação por período",
  "",
  markdown_table(period_table),
  "",
  "## Validações",
  "",
  markdown_table(checks),
  "",
  "## Artefatos",
  "",
  "- `output/tables/area_analysis/area_profile.csv`",
  "- `output/tables/area_analysis/source_area_profile.csv`",
  "- `output/tables/area_analysis/area_period_profile.csv`",
  "- `output/tables/area_analysis/area_journal_composition.csv`",
  "- `output/tables/area_analysis/area_strict_method_profile.csv`",
  "- `data/processed/area_analysis/area_analysis_checks.csv`"
)
write_utf8_lines(report_lines, report_path)

session_lines <- c(
  paste0("generated_at=", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")),
  paste0("input_path=", input_path),
  paste0("input_md5=", unname(tools::md5sum(input_path))),
  paste0("rows=", nrow(analysis_df)),
  paste0("columns=", ncol(analysis_df)),
  paste0("cp_articles=", cp$articles_n),
  paste0("ri_articles=", ri$articles_n),
  paste0("excluded_from_cp_ri=", sum(is.na(analysis_df$area_group))),
  "",
  capture.output(sessionInfo())
)
write_utf8_lines(session_lines, session_path)

message(
  "Análise por área atualizada: CP (incluindo escopo compartilhado) ",
  fmt_int(cp$articles_n), " artigos; RI ", fmt_int(ri$articles_n), " artigos."
)
message(
  "Inferência: CP ", fmt_pct(cp$pct_inference_quantitative_observed),
  " versus RI ", fmt_pct(ri$pct_inference_quantitative_observed), "."
)
