## 29_check_credibility_positive_cases.R
## Identifica candidatos positivos de método de credibilidade no piloto v3 integral.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(stringr)
  library(tidyr)
})

project_dir <- normalizePath(".", mustWork = TRUE)

paths <- list(
  classifications = file.path(
    project_dir,
    "data", "processed", "credibility_prompt_v3_integral_reading",
    "pilot_175", "combined", "classifications_integral_reading.csv"
  ),
  audit_sheet = file.path(
    project_dir,
    "quality_reports", "credibility_prompt_v3_integral_manual_audit_sample.csv"
  ),
  candidate_csv = file.path(
    project_dir,
    "quality_reports", "credibility_prompt_v3_positive_case_check.csv"
  ),
  report = file.path(
    project_dir,
    "quality_reports", "credibility_prompt_v3_positive_case_check.md"
  )
)

parse_bool <- function(x) {
  value <- stringr::str_to_upper(stringr::str_trim(dplyr::coalesce(as.character(x), "")))
  dplyr::case_when(
    value == "TRUE" ~ TRUE,
    value == "FALSE" ~ FALSE,
    TRUE ~ NA
  )
}

parse_method_types <- function(x) {
  if (is.na(x) || stringr::str_trim(x) == "") {
    return(character())
  }
  parsed <- tryCatch(jsonlite::fromJSON(x), error = function(e) character())
  as.character(parsed)
}

md_table <- function(data) {
  if (nrow(data) == 0) {
    return("_Nenhum caso._")
  }
  header <- paste(names(data), collapse = " | ")
  separator <- paste(rep("---", ncol(data)), collapse = " | ")
  rows <- apply(data, 1, function(row) paste(row, collapse = " | "))
  paste(c(header, separator, rows), collapse = "\n")
}

write_utf8_lines <- function(lines, path) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  for (line in lines) {
    writeBin(charToRaw(line), con)
    writeBin(charToRaw("\n"), con)
  }
}

strict_design_methods <- c(
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
  "causal_discovery"
)

diagnostic_not_design_methods <- c(
  "observational_regression_with_causal_claim_no_design",
  "fixed_effects_causal_panel_claim",
  "none_detected"
)

classifications <- readr::read_csv(paths$classifications, show_col_types = FALSE) |>
  dplyr::mutate(
    credibility_revolution_method_present = parse_bool(credibility_revolution_method_present),
    method_type = lapply(credibility_revolution_method_type, parse_method_types)
  )

audit_ids <- readr::read_csv(paths$audit_sheet, show_col_types = FALSE) |>
  dplyr::select(audit_id, pid, paper_url)

method_long <- classifications |>
  dplyr::select(
    pid,
    title,
    journal_title,
    credibility_revolution_method_present,
    credibility_revolution_method_type,
    causal_design_quote,
    tough_call_reason,
    method_type
  ) |>
  tidyr::unnest(method_type, keep_empty = FALSE) |>
  dplyr::mutate(
    method_class = dplyr::case_when(
      method_type %in% strict_design_methods ~ "strict_design_method",
      method_type == "other_modern_causal_method" ~ "broad_other_modern_causal_method",
      method_type %in% diagnostic_not_design_methods ~ "diagnostic_not_design",
      TRUE ~ "unclassified"
    )
  )

candidate_cases <- method_long |>
  dplyr::filter(
    credibility_revolution_method_present %in% TRUE |
      method_class %in% c("strict_design_method", "broad_other_modern_causal_method")
  ) |>
  dplyr::left_join(audit_ids, by = "pid") |>
  dplyr::arrange(
    dplyr::desc(method_class == "strict_design_method"),
    dplyr::desc(method_class == "broad_other_modern_causal_method"),
    audit_id,
    method_type
  ) |>
  dplyr::select(
    audit_id,
    pid,
    title,
    journal_title,
    method_type,
    method_class,
    credibility_revolution_method_present,
    causal_design_quote,
    tough_call_reason,
    paper_url
  )

summary_by_class <- method_long |>
  dplyr::count(method_class, method_type, name = "n") |>
  dplyr::arrange(method_class, dplyr::desc(n), method_type)

strict_cases <- candidate_cases |>
  dplyr::filter(method_class == "strict_design_method")

broad_cases <- candidate_cases |>
  dplyr::filter(method_class == "broad_other_modern_causal_method")

readr::write_csv(candidate_cases, paths$candidate_csv, na = "")

report_lines <- c(
  "# Checagem de casos positivos de método de credibilidade no piloto v3",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Síntese",
  "",
  paste0("- Casos com método clássico/estrito de identificação causal: ", dplyr::n_distinct(strict_cases$pid), "."),
  paste0("- Casos com `other_modern_causal_method`: ", dplyr::n_distinct(broad_cases$pid), "."),
  paste0("- Casos candidatos exportados: ", dplyr::n_distinct(candidate_cases$pid), "."),
  "",
  "Métodos estritos incluem experimentos, DiD/event study, IV, RDD/RKD, synthetic control, matching/weighting, DAG causal, doubly robust, causal trees/forests e causal discovery. `other_modern_causal_method` fica separado porque requer validação substantiva da identificação.",
  "",
  "## Tabela 1. Tipos de método encontrados no piloto",
  "",
  md_table(summary_by_class),
  "",
  "## Tabela 2. Candidatos positivos a validar",
  "",
  md_table(
    candidate_cases |>
      dplyr::select(audit_id, pid, title, method_type, method_class)
  ),
  "",
  "## Nota para A017",
  "",
  "O único caso em `other_modern_causal_method` é A017. Se a auditoria manual decidir que a aplicação de mediação causal/SEM não justifica a hipótese de identificação relevante, o caso deve sair do numerador de métodos de credibilidade."
)

write_utf8_lines(report_lines, paths$report)

cat("Candidatos escritos em:", paths$candidate_csv, "\n")
cat("Relatório escrito em:", paths$report, "\n")
