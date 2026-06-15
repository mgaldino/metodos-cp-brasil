## 32_summarize_credibility_integral_batch.R
## Resume um CSV consolidado de classificações por leitura integral.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(stringr)
  library(tidyr)
})

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default = NULL) {
  pos <- match(flag, args)
  if (is.na(pos) || pos == length(args)) {
    return(default)
  }
  args[[pos + 1]]
}

csv_path <- get_arg("--csv")
out_path <- get_arg("--out")
label <- get_arg("--label", "batch")

if (is.null(csv_path)) {
  stop("Uso: Rscript --vanilla scripts/32_summarize_credibility_integral_batch.R --csv <classifications.csv> [--out <report.md>] [--label <label>]")
}

if (is.null(out_path)) {
  out_path <- sub("\\.csv$", "_summary.md", csv_path)
}

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

classifications <- readr::read_csv(csv_path, show_col_types = FALSE) |>
  dplyr::mutate(
    is_empirical_paper = parse_bool(is_empirical_paper),
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    is_empirical_qual_paper = parse_bool(is_empirical_qual_paper),
    credibility_revolution_screen_applicable = parse_bool(credibility_revolution_screen_applicable),
    credibility_revolution_method_present = parse_bool(credibility_revolution_method_present),
    tough_call = parse_bool(tough_call),
    method_type = lapply(credibility_revolution_method_type, parse_method_types)
  )

n_total <- nrow(classifications)

indicator_table <- classifications |>
  dplyr::summarise(
    artigos = dplyr::n(),
    empiricos = sum(is_empirical_paper, na.rm = TRUE),
    quantitativos_torreblanca = sum(is_empirical_quant_paper_torreblanca, na.rm = TRUE),
    qualitativos = sum(is_empirical_qual_paper, na.rm = TRUE),
    screen_credibilidade = sum(credibility_revolution_screen_applicable, na.rm = TRUE),
    method_present_raw = sum(credibility_revolution_method_present, na.rm = TRUE),
    tough_calls = sum(tough_call, na.rm = TRUE)
  ) |>
  tidyr::pivot_longer(cols = dplyr::everything(), names_to = "indicador", values_to = "n") |>
  dplyr::mutate(percent = if (n_total > 0) round(100 * n / n_total, 1) else NA_real_)

evidence_distribution <- classifications |>
  dplyr::count(empirical_evidence_type, quantitative_analysis_type, name = "n") |>
  dplyr::mutate(percent = round(100 * n / sum(n), 1)) |>
  dplyr::arrange(dplyr::desc(n), empirical_evidence_type, quantitative_analysis_type)

screen_distribution <- classifications |>
  dplyr::count(credibility_revolution_screen_applicable, credibility_revolution_screen_reason, name = "n") |>
  dplyr::mutate(percent = round(100 * n / sum(n), 1)) |>
  dplyr::arrange(dplyr::desc(n), credibility_revolution_screen_reason)

method_long <- classifications |>
  dplyr::select(pid, title, journal_title, credibility_revolution_method_present, method_type, causal_design_quote, tough_call_reason) |>
  tidyr::unnest(method_type, keep_empty = FALSE) |>
  dplyr::mutate(
    method_class = dplyr::case_when(
      method_type %in% strict_design_methods ~ "strict_design_method",
      method_type == "other_modern_causal_method" ~ "broad_other_modern_causal_method",
      method_type %in% diagnostic_not_design_methods ~ "diagnostic_not_design",
      TRUE ~ "unclassified"
    )
  )

method_distribution <- method_long |>
  dplyr::count(method_class, method_type, name = "n") |>
  dplyr::arrange(method_class, dplyr::desc(n), method_type)

positive_candidates <- method_long |>
  dplyr::filter(method_class %in% c("strict_design_method", "broad_other_modern_causal_method")) |>
  dplyr::select(pid, title, journal_title, method_type, method_class, causal_design_quote, tough_call_reason) |>
  dplyr::arrange(method_class, pid)

report_lines <- c(
  paste0("# Síntese do batch: ", label),
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Tabela 1. Indicadores básicos",
  "",
  md_table(indicator_table),
  "",
  "## Tabela 2. Tipo de evidência e análise quantitativa",
  "",
  md_table(evidence_distribution),
  "",
  "## Tabela 3. Screen de revolução da credibilidade",
  "",
  md_table(screen_distribution),
  "",
  "## Tabela 4. Tipos de método detectados",
  "",
  md_table(method_distribution),
  "",
  "## Tabela 5. Candidatos positivos a validar manualmente",
  "",
  md_table(positive_candidates),
  "",
  "## Regra de interpretação",
  "",
  "Rótulos diagnósticos como `observational_regression_with_causal_claim_no_design`, `fixed_effects_causal_panel_claim` e `none_detected` não contam como desenho de revolução da credibilidade. `other_modern_causal_method` só deve entrar no numerador após validação manual da discussão de identificação causal."
)

write_utf8_lines(report_lines, out_path)

cat("Relatório escrito em:", out_path, "\n")
