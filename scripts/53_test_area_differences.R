#!/usr/bin/env Rscript

## Testes simples de igualdade de proporções entre Ciência Política e RI.
## Os testes tratam artigos como unidades independentes; essa hipótese é
## deliberadamente simples e não substitui uma análise que modele a
## dependência entre artigos publicados no mesmo periódico.

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
  library(tibble)
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
output_dir <- path("output/tables/area_analysis")
report_path <- path("quality_reports/area_hypothesis_tests_current_canonical.md")
session_path <- path("data/processed/area_analysis/area_hypothesis_tests_session_info.txt")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(session_path), recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_path)) {
  stop("Dataset analítico ausente: ", input_path)
}

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

fmt_int <- function(x) {
  format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

fmt_pct <- function(x) {
  paste0(format(round(x, 1), decimal.mark = ",", nsmall = 1, trim = TRUE), "%")
}

fmt_pp <- function(x) {
  paste0(format(round(x, 1), decimal.mark = ",", nsmall = 1, trim = TRUE), " p.p.")
}

fmt_p <- function(x) {
  ifelse(x < 0.001, "<0,001", format(round(x, 3), decimal.mark = ",", nsmall = 3))
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

df <- readr::read_csv(input_path, show_col_types = FALSE) |>
  dplyr::mutate(
    is_empirical_paper = parse_bool(is_empirical_paper),
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    has_statistical_inference = parse_bool(has_statistical_inference),
    credibility_revolution_screen_applicable = parse_bool(credibility_revolution_screen_applicable),
    strict_design_method = parse_bool(strict_design_method),
    area_group = dplyr::case_when(
      journal_area %in% c("Ciência Política", "Ciência Política e Ciências Sociais") ~
        "Ciência Política (inclui escopo compartilhado)",
      journal_area == "Relações Internacionais" ~ "Relações Internacionais",
      TRUE ~ NA_character_
    )
  ) |>
  dplyr::filter(!is.na(area_group))

if (anyDuplicated(df$pid) > 0) {
  stop("O dataset analítico contém PIDs duplicados.")
}

cp_label <- "Ciência Política (inclui escopo compartilhado)"
ri_label <- "Relações Internacionais"

group_counts <- function(data, group) {
  z <- data$area_group == group
  empirical <- as_true(data$is_empirical_paper) & z
  quantitative <- as_true(data$is_empirical_quant_paper_torreblanca) & z
  inference <- as_true(data$has_statistical_inference) & quantitative
  inference_observed <- quantitative & !is.na(data$has_statistical_inference)
  screened <- as_true(data$credibility_revolution_screen_applicable) & z
  strict <- as_true(data$strict_design_method) & z
  tibble::tibble(
    area = group,
    journals_n = dplyr::n_distinct(data$journal_title[z]),
    articles_n = sum(z),
    empirical_n = sum(empirical),
    quantitative_n = sum(quantitative),
    inference_n = sum(inference),
    inference_den_observed = sum(inference_observed),
    screen_n = sum(screened),
    strict_n = sum(strict)
  )
}

counts <- dplyr::bind_rows(
  group_counts(df, cp_label),
  group_counts(df, ri_label)
)

journal_rates <- df |>
  dplyr::group_by(area_group, journal_title) |>
  dplyr::summarise(
    inference_n = sum(as_true(has_statistical_inference) &
      as_true(is_empirical_quant_paper_torreblanca)),
    inference_den_observed = sum(
      as_true(is_empirical_quant_paper_torreblanca) & !is.na(has_statistical_inference)
    ),
    inference_rate = inference_n / inference_den_observed,
    .groups = "drop"
  )

journal_welch <- stats::t.test(inference_rate ~ area_group, data = journal_rates)
journal_wilcoxon <- stats::wilcox.test(
  inference_rate ~ area_group,
  data = journal_rates,
  exact = FALSE
)

journal_sensitivity <- tibble::tibble(
  test = c("Welch t por periódico", "Wilcoxon por periódico"),
  n_cp_journals = sum(journal_rates$area_group == cp_label),
  n_ri_journals = sum(journal_rates$area_group == ri_label),
  cp_mean_rate = mean(journal_rates$inference_rate[journal_rates$area_group == cp_label]),
  ri_mean_rate = mean(journal_rates$inference_rate[journal_rates$area_group == ri_label]),
  p_value = c(journal_welch$p.value, journal_wilcoxon$p.value)
)

metrics <- tibble::tribble(
  ~metric, ~metric_label, ~cp_numerator, ~cp_denominator, ~ri_numerator, ~ri_denominator,
  "empirical", "Artigo empírico entre todos os artigos", counts$empirical_n[1], counts$articles_n[1], counts$empirical_n[2], counts$articles_n[2],
  "quantitative", "Análise quantitativa entre artigos empíricos", counts$quantitative_n[1], counts$empirical_n[1], counts$quantitative_n[2], counts$empirical_n[2],
  "inference", "Inferência estatística entre quantitativos com rótulo observado", counts$inference_n[1], counts$inference_den_observed[1], counts$inference_n[2], counts$inference_den_observed[2],
  "strict_causal", "Estratégia causal explícita entre artigos examinados", counts$strict_n[1], counts$screen_n[1], counts$strict_n[2], counts$screen_n[2]
)

run_proportion_test <- function(cp_numerator, cp_denominator, ri_numerator, ri_denominator) {
  prop_test <- stats::prop.test(
    x = c(cp_numerator, ri_numerator),
    n = c(cp_denominator, ri_denominator),
    correct = FALSE,
    alternative = "two.sided"
  )
  fisher_table <- matrix(
    c(
      cp_numerator, cp_denominator - cp_numerator,
      ri_numerator, ri_denominator - ri_numerator
    ),
    nrow = 2,
    byrow = TRUE,
    dimnames = list(c("CP", "RI"), c("positive", "negative"))
  )
  fisher_test <- stats::fisher.test(fisher_table, alternative = "two.sided")
  tibble::tibble(
    cp_percent = 100 * cp_numerator / cp_denominator,
    ri_percent = 100 * ri_numerator / ri_denominator,
    difference_pp = 100 * cp_numerator / cp_denominator - 100 * ri_numerator / ri_denominator,
    prop_test_p = unname(prop_test$p.value),
    prop_test_ci_low_pp = 100 * prop_test$conf.int[1],
    prop_test_ci_high_pp = 100 * prop_test$conf.int[2],
    fisher_p = fisher_test$p.value,
    fisher_odds_ratio = unname(fisher_test$estimate)
  )
}

tests <- metrics |>
  dplyr::rowwise() |>
  dplyr::mutate(test = list(run_proportion_test(
    cp_numerator, cp_denominator, ri_numerator, ri_denominator
  ))) |>
  dplyr::ungroup() |>
  tidyr::unnest(test) |>
  dplyr::mutate(
    prop_test_p_bh = stats::p.adjust(prop_test_p, method = "BH"),
    fisher_p_bh = stats::p.adjust(fisher_p, method = "BH")
  )

readr::write_csv(counts, file.path(output_dir, "area_hypothesis_test_counts.csv"))
readr::write_csv(tests, file.path(output_dir, "area_hypothesis_tests.csv"))
readr::write_csv(journal_rates, file.path(output_dir, "area_journal_inference_rates.csv"))
readr::write_csv(journal_sensitivity, file.path(output_dir, "area_journal_sensitivity_tests.csv"))

display <- tests |>
  dplyr::transmute(
    Métrica = metric_label,
    `CP (N/D)` = paste0(fmt_int(cp_numerator), "/", fmt_int(cp_denominator), " (", fmt_pct(cp_percent), ")"),
    `RI (N/D)` = paste0(fmt_int(ri_numerator), "/", fmt_int(ri_denominator), " (", fmt_pct(ri_percent), ")"),
    `Diferença (p.p.)` = fmt_pp(difference_pp),
    `IC95% da diferença` = paste0(fmt_pp(prop_test_ci_low_pp), " a ", fmt_pp(prop_test_ci_high_pp)),
    `p (duas proporções)` = vapply(prop_test_p, fmt_p, character(1)),
    `p (Fisher)` = vapply(fisher_p, fmt_p, character(1)),
    `p ajustado BH` = vapply(prop_test_p_bh, fmt_p, character(1))
  )

main_test <- tests |>
  dplyr::filter(metric == "inference")

report_lines <- c(
  "# Testes simples de diferenças entre Ciência Política e Relações Internacionais",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Hipótese e unidade",
  "",
  "A hipótese nula é igualdade das proporções entre os dois grupos editoriais. O teste principal usa `prop.test` bilateral, sem correção de continuidade, com IC de 95% para a diferença CP–RI. Fisher bilateral é reportado como checagem exata. Os testes tratam artigos como independentes; portanto, os p-valores são diagnósticos simples e não corrigem a dependência entre artigos do mesmo periódico.",
  "",
  "A comparação principal é a inferência estatística entre artigos quantitativos cujo rótulo de inferência foi observado. Os cinco quantitativos sem rótulo permanecem fora do denominador, como no paper.",
  "",
  "## Resultados",
  "",
  markdown_table(display),
  "",
  paste0(
    "Para a métrica principal, a diferença CP–RI é de ",
    fmt_pp(main_test$difference_pp),
    " (IC95%: ", fmt_pp(main_test$prop_test_ci_low_pp),
    " a ", fmt_pp(main_test$prop_test_ci_high_pp),
    "; p bilateral = ", fmt_p(main_test$prop_test_p),
    "; Fisher = ", fmt_p(main_test$fisher_p), ")."
  ),
  "",
  "Os testes confirmam uma diferença estatística muito forte na inferência e na composição quantitativa. A diferença em estratégias causais explícitas é menor em magnitude e fica próxima do limiar de 5% no teste simples; com ajuste BH para as quatro métricas, ela deixa de ser significativa a 5%. Isso não altera a descrição substantiva, mas recomenda não apresentar o resultado causal como uma separação estatística robusta sem modelar a estrutura por periódico.",
  "",
  "## Limitação decisiva",
  "",
  paste0(
    "Os artigos estão agrupados em seis periódicos de CP e dois de RI, e a área foi atribuída ao periódico. A sensibilidade que usa o periódico como unidade produz p = ",
    fmt_p(journal_welch$p.value),
    " no teste t de Welch, mas p = ",
    fmt_p(journal_wilcoxon$p.value),
    " no teste de Wilcoxon. Como há apenas dois periódicos de RI, essa divergência é esperada e impede tratar o p-valor artigo-nível como uma confirmação definitiva de um efeito de área. Uma análise confirmatória deveria trabalhar com proporções por periódico, modelos hierárquicos ou inferência por cluster; com apenas oito periódicos, essa extensão teria baixa potência e exigiria especificação cuidadosa."
  ),
  "",
  "## Artefatos",
  "",
  "- `output/tables/area_analysis/area_hypothesis_test_counts.csv`",
  "- `output/tables/area_analysis/area_hypothesis_tests.csv`",
  "- `output/tables/area_analysis/area_journal_inference_rates.csv`",
  "- `output/tables/area_analysis/area_journal_sensitivity_tests.csv`",
  "- `data/processed/area_analysis/area_hypothesis_tests_session_info.txt`"
)
write_utf8_lines(report_lines, report_path)

session_lines <- c(
  paste0("generated_at=", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")),
  paste0("input_path=", input_path),
  paste0("input_md5=", unname(tools::md5sum(input_path))),
  paste0("rows_in_comparison=", nrow(df)),
  paste0("cp_articles=", counts$articles_n[1]),
  paste0("ri_articles=", counts$articles_n[2]),
  "",
  capture.output(sessionInfo())
)
write_utf8_lines(session_lines, session_path)

message(
  "Teste principal: diferença CP–RI = ", fmt_pp(main_test$difference_pp),
  "; p = ", fmt_p(main_test$prop_test_p),
  "; Fisher = ", fmt_p(main_test$fisher_p), "."
)
