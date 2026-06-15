## 30_confirm_pilot_v3_adjusted_general_check.R
## Confirma estatísticas gerais do piloto v3 com ajuste manual do caso A017.

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
  report = file.path(
    project_dir,
    "quality_reports", "credibility_prompt_v3_integral_pilot_adjusted_check.md"
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

decode_angle_byte_sequences <- function(line) {
  matches <- gregexpr("(<[0-9A-Fa-f]{2}>)+", line, perl = TRUE)[[1]]
  if (matches[[1]] == -1) {
    return(line)
  }
  lengths <- attr(matches, "match.length")
  for (i in rev(seq_along(matches))) {
    token <- substr(line, matches[[i]], matches[[i]] + lengths[[i]] - 1)
    hex <- regmatches(token, gregexpr("[0-9A-Fa-f]{2}", token, perl = TRUE))[[1]]
    decoded <- tryCatch({
      value <- rawToChar(as.raw(strtoi(hex, base = 16L)))
      Encoding(value) <- "UTF-8"
      value
    }, error = function(e) token)
    line <- paste0(
      substr(line, 1, matches[[i]] - 1),
      decoded,
      substr(line, matches[[i]] + lengths[[i]], nchar(line))
    )
  }
  line
}

write_utf8_lines <- function(lines, path) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  for (line in lines) {
    line <- enc2utf8(line)
    line <- decode_angle_byte_sequences(line)
    writeBin(charToRaw(line), con)
    writeBin(charToRaw("\n"), con)
  }
}

fmt_pct <- function(n, denom) {
  paste0(n, "/", denom, " = ", format(round(100 * n / denom, 1), nsmall = 1), "%")
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

manual_excluded_positive_pids <- c("S0104-62762018000100209")

classifications <- readr::read_csv(paths$classifications, show_col_types = FALSE) |>
  dplyr::mutate(
    is_empirical_paper = parse_bool(is_empirical_paper),
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    is_empirical_qual_paper = parse_bool(is_empirical_qual_paper),
    credibility_revolution_screen_applicable = parse_bool(credibility_revolution_screen_applicable),
    credibility_revolution_method_present = parse_bool(credibility_revolution_method_present),
    tough_call = parse_bool(tough_call),
    method_type = lapply(credibility_revolution_method_type, parse_method_types)
  )

method_long <- classifications |>
  dplyr::select(
    pid,
    title,
    journal_title,
    credibility_revolution_method_present,
    method_type,
    causal_design_quote,
    tough_call_reason
  ) |>
  tidyr::unnest(method_type, keep_empty = FALSE) |>
  dplyr::mutate(
    method_class = dplyr::case_when(
      method_type %in% strict_design_methods ~ "strict_design_method",
      method_type == "other_modern_causal_method" ~ "broad_other_modern_causal_method",
      method_type %in% diagnostic_not_design_methods ~ "diagnostic_not_design",
      TRUE ~ "unclassified"
    ),
    adjusted_positive = dplyr::case_when(
      pid %in% manual_excluded_positive_pids ~ FALSE,
      method_class %in% c("strict_design_method", "broad_other_modern_causal_method") ~ TRUE,
      TRUE ~ FALSE
    )
  )

n_total <- nrow(classifications)
n_empirical <- sum(classifications$is_empirical_paper, na.rm = TRUE)
n_quant <- sum(classifications$is_empirical_quant_paper_torreblanca, na.rm = TRUE)
n_qual <- sum(classifications$is_empirical_qual_paper, na.rm = TRUE)
n_screen <- sum(classifications$credibility_revolution_screen_applicable, na.rm = TRUE)
n_raw_method_present <- sum(classifications$credibility_revolution_method_present, na.rm = TRUE)
n_adjusted_positive <- dplyr::n_distinct(method_long$pid[method_long$adjusted_positive])
n_strict_positive <- dplyr::n_distinct(
  method_long$pid[method_long$method_class == "strict_design_method"]
)
n_broad_raw <- dplyr::n_distinct(
  method_long$pid[method_long$method_class == "broad_other_modern_causal_method"]
)

general_stats <- tibble::tibble(
  indicador = c(
    "Artigos no piloto",
    "Empíricos",
    "Quantitativos Torreblanca",
    "Qualitativos",
    "Screen de credibilidade aplicável",
    "method_present bruto do classificador",
    "Método estrito de identificação causal",
    "other_modern_causal_method bruto",
    "Positivos ajustados após auditoria A017"
  ),
  n = c(
    n_total,
    n_empirical,
    n_quant,
    n_qual,
    n_screen,
    n_raw_method_present,
    n_strict_positive,
    n_broad_raw,
    n_adjusted_positive
  ),
  percent_total = c(
    "100.0%",
    format(round(100 * n_empirical / n_total, 1), nsmall = 1),
    format(round(100 * n_quant / n_total, 1), nsmall = 1),
    format(round(100 * n_qual / n_total, 1), nsmall = 1),
    format(round(100 * n_screen / n_total, 1), nsmall = 1),
    format(round(100 * n_raw_method_present / n_total, 1), nsmall = 1),
    format(round(100 * n_strict_positive / n_total, 1), nsmall = 1),
    format(round(100 * n_broad_raw / n_total, 1), nsmall = 1),
    format(round(100 * n_adjusted_positive / n_total, 1), nsmall = 1)
  )
) |>
  dplyr::mutate(percent_total = if_else(percent_total == "100.0%", percent_total, paste0(percent_total, "%")))

method_distribution <- method_long |>
  dplyr::count(method_class, method_type, adjusted_positive, name = "n") |>
  dplyr::arrange(method_class, dplyr::desc(n), method_type)

adjusted_positive_cases <- method_long |>
  dplyr::filter(adjusted_positive %in% TRUE) |>
  dplyr::select(pid, title, journal_title, method_type, method_class)

manual_adjustments <- method_long |>
  dplyr::filter(pid %in% manual_excluded_positive_pids) |>
  dplyr::distinct(pid, title, journal_title, method_type, method_class, adjusted_positive)

report_lines <- c(
  "# Checagem geral ajustada do piloto v3 integral",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Síntese",
  "",
  paste0("- Artigos no piloto: ", n_total, "."),
  paste0("- Quantitativos Torreblanca: ", fmt_pct(n_quant, n_total), " do total; ", fmt_pct(n_quant, n_empirical), " dos empíricos."),
  paste0("- Screen de credibilidade aplicável: ", fmt_pct(n_screen, n_total), "."),
  paste0("- Positivos ajustados de desenho de revolução da credibilidade: ", fmt_pct(n_adjusted_positive, n_total), "."),
  "",
  "Ajuste aplicado: A017 (`S0104-62762018000100209`) foi removido do numerador de métodos de revolução da credibilidade. O artigo usa SEM/mediação causal citando Imai, Keele e Tingley, mas não discute nem justifica ignorabilidade sequencial ou hipótese equivalente de identificação.",
  "",
  "Regra para a escala: métodos fora da lista usual de desenhos da revolução da credibilidade só contam como `other_modern_causal_method` positivo se houver discussão explícita da identificação causal e da plausibilidade das hipóteses de identificação.",
  "",
  "## Tabela 1. Indicadores gerais ajustados",
  "",
  md_table(general_stats),
  "",
  "## Tabela 2. Distribuição de métodos detectados",
  "",
  md_table(method_distribution),
  "",
  "## Tabela 3. Casos positivos ajustados",
  "",
  md_table(adjusted_positive_cases),
  "",
  "## Tabela 4. Ajustes manuais aplicados",
  "",
  md_table(manual_adjustments),
  "",
  "## Conclusão operacional",
  "",
  "Com a regra ajustada, o piloto v3 tem 44,6% de artigos quantitativos e 0,0% de artigos com desenho validado de revolução da credibilidade. O próximo batch deve manter `method_present = false` para regressão observacional, SEM/mediação causal ou modelos estruturais sem justificativa explícita de identificação."
)

write_utf8_lines(report_lines, paths$report)

cat("Relatório escrito em:", paths$report, "\n")
