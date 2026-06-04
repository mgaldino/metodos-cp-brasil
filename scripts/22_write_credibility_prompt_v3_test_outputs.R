## 22_write_credibility_prompt_v3_test_outputs.R
## Valida classificacoes do teste prompt v3 e gera CSV + relatorio Markdown.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(tibble)
})

project_dir <- normalizePath(".", mustWork = TRUE)

paths <- list(
  jsonl = file.path(project_dir, "data", "processed", "credibility_prompt_v3_test", "outputs", "classifications_10_papers.jsonl"),
  csv = file.path(project_dir, "data", "processed", "credibility_prompt_v3_test", "outputs", "classifications_10_papers.csv"),
  report = file.path(project_dir, "data", "processed", "credibility_prompt_v3_test", "outputs", "classification_report_10_papers.md")
)

required_fields <- c(
  "pid",
  "title",
  "journal_title",
  "input_text_hash",
  "is_empirical_paper",
  "empirical_evidence_type",
  "is_empirical_quant_paper_torreblanca",
  "is_empirical_qual_paper",
  "quantitative_analysis_type",
  "quantitative_analysis_evidence_quote",
  "has_statistical_inference",
  "statistical_inference_quote",
  "qualitative_analysis_goal",
  "qualitative_goal_clarity",
  "qualitative_goal_quote",
  "causal_or_explanatory_claim_present",
  "causal_or_explanatory_claim_quote",
  "credibility_revolution_screen_applicable",
  "credibility_revolution_screen_reason",
  "credibility_revolution_method_present",
  "credibility_revolution_method_type",
  "causal_design_quote",
  "main_variables_or_relationship",
  "sample_or_data_source",
  "tough_call",
  "tough_call_reason",
  "brief_justification"
)

allowed <- list(
  empirical_evidence_type = c("none", "quantitative_only", "qualitative_only", "mixed_empirical", "unclear"),
  quantitative_analysis_type = c("none", "descriptive_statistics_only", "bivariate_tests_or_correlations_only", "statistical_modeling", "unclear"),
  qualitative_analysis_goal = c("descriptive_reconstruction", "explanatory_why", "interpretive_meaning", "mixed_descriptive_explanatory", "unclear"),
  qualitative_goal_clarity = c("clear", "ambiguous_tough_call", "internally_inconsistent"),
  credibility_revolution_screen_reason = c(
    "not_empirical",
    "qualitative_only",
    "descriptive_quantitative_only",
    "bivariate_or_correlation_screen",
    "statistical_modeling_screen",
    "explicit_causal_design_screen",
    "causal_claim_with_quantitative_analysis_screen",
    "unclear"
  ),
  credibility_revolution_method_type = c(
    "experiment_field",
    "experiment_survey",
    "experiment_lab",
    "experiment_list",
    "difference_in_differences",
    "event_study",
    "instrumental_variables",
    "regression_discontinuity",
    "regression_kink",
    "synthetic_control",
    "synthetic_difference_in_differences",
    "matching_or_weighting",
    "dag_or_formal_causal_graph",
    "doubly_robust",
    "causal_trees_or_forests",
    "causal_discovery",
    "other_modern_causal_method",
    "fixed_effects_causal_panel_claim",
    "observational_regression_with_causal_claim_no_design",
    "none_detected"
  )
)

markdown_table <- function(df) {
  if (nrow(df) == 0) {
    return("_Nenhum registro._")
  }
  df <- as.data.frame(df)
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- apply(df, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

as_csv_value <- function(x) {
  if (is.null(x)) {
    return(NA_character_)
  }
  if (is.list(x) || length(x) > 1) {
    return(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null"))
  }
  if (is.logical(x)) {
    return(as.character(x))
  }
  as.character(x)
}

lines <- readLines(paths$jsonl, warn = FALSE, encoding = "UTF-8")
records <- lapply(lines[nzchar(lines)], jsonlite::fromJSON, simplifyVector = FALSE)

if (length(records) != 10) {
  stop("Esperava 10 objetos JSON; encontrado: ", length(records))
}

invisible(lapply(records, function(record) {
  missing <- setdiff(required_fields, names(record))
  extra <- setdiff(names(record), required_fields)
  if (length(missing) > 0) {
    stop("Campos ausentes em ", record$pid, ": ", paste(missing, collapse = ", "))
  }
  if (length(extra) > 0) {
    stop("Campos extras em ", record$pid, ": ", paste(extra, collapse = ", "))
  }
  invisible(TRUE)
}))

df <- tibble::as_tibble(do.call(rbind, lapply(records, function(record) {
  stats::setNames(
    as.data.frame(as.list(vapply(required_fields, function(field) as_csv_value(record[[field]]), character(1))), stringsAsFactors = FALSE),
    required_fields
  )
})))

logical_fields <- c(
  "is_empirical_paper",
  "is_empirical_quant_paper_torreblanca",
  "is_empirical_qual_paper",
  "has_statistical_inference",
  "causal_or_explanatory_claim_present",
  "credibility_revolution_screen_applicable",
  "credibility_revolution_method_present",
  "tough_call"
)

df <- df |>
  dplyr::mutate(dplyr::across(dplyr::all_of(logical_fields), ~ dplyr::case_when(
    .x == "TRUE" ~ TRUE,
    .x == "FALSE" ~ FALSE,
    TRUE ~ NA
  )))

validate_allowed <- function(field, values) {
  observed <- df[[field]]
  observed <- observed[!is.na(observed)]
  invalid <- setdiff(unique(observed), values)
  if (length(invalid) > 0) {
    stop("Valores invalidos em ", field, ": ", paste(invalid, collapse = ", "))
  }
}

validate_allowed("empirical_evidence_type", allowed$empirical_evidence_type)
validate_allowed("quantitative_analysis_type", allowed$quantitative_analysis_type)
validate_allowed("credibility_revolution_screen_reason", allowed$credibility_revolution_screen_reason)
validate_allowed("qualitative_analysis_goal", allowed$qualitative_analysis_goal)
validate_allowed("qualitative_goal_clarity", allowed$qualitative_goal_clarity)

method_values <- df$credibility_revolution_method_type
method_values <- method_values[!is.na(method_values)]
if (length(method_values) > 0) {
  parsed_methods <- unlist(lapply(method_values, function(x) jsonlite::fromJSON(x, simplifyVector = TRUE)))
  invalid_methods <- setdiff(unique(parsed_methods), allowed$credibility_revolution_method_type)
  if (length(invalid_methods) > 0) {
    stop("Valores invalidos em credibility_revolution_method_type: ", paste(invalid_methods, collapse = ", "))
  }
}

readr::write_csv(df, paths$csv, na = "")

dist_table <- function(field) {
  df |>
    dplyr::count(.data[[field]], name = "n") |>
    dplyr::mutate(value = ifelse(is.na(.data[[field]]), "NA", as.character(.data[[field]]))) |>
    dplyr::select(value, n)
}

method_present <- df |>
  dplyr::filter(credibility_revolution_method_present %in% TRUE) |>
  dplyr::select(pid, title, credibility_revolution_method_type)

tough_calls <- df |>
  dplyr::filter(tough_call %in% TRUE) |>
  dplyr::select(pid, title, tough_call_reason)

report_lines <- c(
  "# Classificação metodológica - prompt v3 - 10 papers",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
  "",
  "## Escopo",
  "",
  paste0("Foram classificados ", nrow(df), " artigos do manifest `data/processed/credibility_prompt_v3_test/manifest_10_papers.csv`."),
  "",
  "As decisões usaram apenas os task packets com body integral em `data/processed/credibility_prompt_v3_test/task_packets/`. Não houve uso de API keys, API runners ou classificações antigas como evidência substantiva.",
  "",
  "## Distribuições",
  "",
  "### is_empirical_paper",
  "",
  markdown_table(dist_table("is_empirical_paper")),
  "",
  "### empirical_evidence_type",
  "",
  markdown_table(dist_table("empirical_evidence_type")),
  "",
  "### quantitative_analysis_type",
  "",
  markdown_table(dist_table("quantitative_analysis_type")),
  "",
  "### credibility_revolution_screen_applicable",
  "",
  markdown_table(dist_table("credibility_revolution_screen_applicable")),
  "",
  "## Artigos com método de revolução da credibilidade",
  "",
  markdown_table(method_present),
  "",
  "## Tough calls",
  "",
  markdown_table(tough_calls),
  "",
  "## Falsos positivos e falsos negativos prováveis",
  "",
  "Principais riscos de falso positivo: classificar como quantitativos artigos qualitativos que citam números contextuais de terceiros, especialmente o estudo sobre a UCKG em Angola; e classificar como método de credibilidade artigos com regressão observacional e linguagem de efeito, como status social e Bolsa Família.",
  "",
  "Principais riscos de falso negativo: reduzir a importância empírica de artigos mistos quando o componente quantitativo é apenas descritivo, como o levantamento das conferências nacionais. A regra anti-falso-positivo recomenda manter esses casos como quantitativos descritivos, mas fora da triagem de métodos de credibilidade quando não há teste, modelo ou desenho causal.",
  "",
  "## Recomendação sobre o prompt",
  "",
  "O prompt está quase pronto para escala. A principal revisão recomendada é explicitar a decisão para casos de regressão observacional com linguagem causal: `credibility_revolution_method_present` deve ser `false`, mas `credibility_revolution_method_type` pode registrar `observational_regression_with_causal_claim_no_design`. Também vale explicitar que artigos mistos com levantamento quantitativo descritivo e narrativa causal-histórica ficam em `descriptive_quantitative_only`, salvo quando a inferência causal estiver associada a teste, modelo ou desenho quantitativo."
)

writeLines(report_lines, paths$report, useBytes = TRUE)

message("Escreveu: ", paths$csv)
message("Escreveu: ", paths$report)
