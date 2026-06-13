## 27_summarize_integral_reading_pilot.R
## Resume o piloto v3 de leitura integral após consolidação 175/175.

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
  reading_logs_dir = file.path(
    project_dir,
    "data", "processed", "credibility_prompt_v3_integral_reading",
    "pilot_175", "reading_logs"
  ),
  failed_dir = file.path(
    project_dir,
    "data", "processed", "credibility_prompt_v3_integral_reading",
    "pilot_175", "failed"
  ),
  report = file.path(project_dir, "quality_reports", "credibility_prompt_v3_integral_pilot_summary.md"),
  tough_calls = file.path(project_dir, "quality_reports", "credibility_prompt_v3_integral_tough_calls.csv"),
  methods = file.path(project_dir, "quality_reports", "credibility_prompt_v3_integral_methods_detected.csv")
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

classifications <- readr::read_csv(paths$classifications, show_col_types = FALSE) |>
  dplyr::mutate(
    is_empirical_paper = parse_bool(is_empirical_paper),
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    is_empirical_qual_paper = parse_bool(is_empirical_qual_paper),
    credibility_revolution_screen_applicable = parse_bool(credibility_revolution_screen_applicable),
    credibility_revolution_method_present = parse_bool(credibility_revolution_method_present),
    tough_call = parse_bool(tough_call)
  )

reading_log_count <- length(list.files(paths$reading_logs_dir, pattern = "\\.json$", full.names = TRUE))
failed_count <- length(list.files(paths$failed_dir, pattern = "\\.txt$", full.names = TRUE))

evidence_distribution <- classifications |>
  dplyr::count(empirical_evidence_type, quantitative_analysis_type, name = "n") |>
  dplyr::mutate(percent = round(100 * n / sum(n), 1)) |>
  dplyr::arrange(dplyr::desc(n), empirical_evidence_type, quantitative_analysis_type)

screen_distribution <- classifications |>
  dplyr::count(
    credibility_revolution_screen_applicable,
    credibility_revolution_screen_reason,
    name = "n"
  ) |>
  dplyr::mutate(percent = round(100 * n / sum(n), 1)) |>
  dplyr::arrange(dplyr::desc(n), credibility_revolution_screen_reason)

empirical_flags <- classifications |>
  dplyr::summarise(
    total = dplyr::n(),
    empirical = sum(is_empirical_paper, na.rm = TRUE),
    torreblanca_quant = sum(is_empirical_quant_paper_torreblanca, na.rm = TRUE),
    qualitative = sum(is_empirical_qual_paper, na.rm = TRUE),
    credibility_screen_applicable = sum(credibility_revolution_screen_applicable, na.rm = TRUE),
    credibility_method_present = sum(credibility_revolution_method_present, na.rm = TRUE),
    tough_calls = sum(tough_call, na.rm = TRUE)
  )

methods_detected <- classifications |>
  dplyr::filter(credibility_revolution_method_present %in% TRUE) |>
  dplyr::select(pid, title, credibility_revolution_method_type) |>
  dplyr::mutate(method_type = lapply(credibility_revolution_method_type, parse_method_types)) |>
  tidyr::unnest(method_type, keep_empty = FALSE) |>
  dplyr::filter(!is.na(method_type), method_type != "", method_type != "none_detected") |>
  dplyr::count(method_type, name = "n") |>
  dplyr::arrange(dplyr::desc(n), method_type)

credibility_specific_methods <- methods_detected |>
  dplyr::filter(method_type != "observational_regression_with_causal_claim_no_design")

method_articles <- classifications |>
  dplyr::filter(credibility_revolution_method_present %in% TRUE) |>
  dplyr::select(pid, title, journal_title, credibility_revolution_method_type, causal_design_quote) |>
  dplyr::mutate(method_type = lapply(credibility_revolution_method_type, parse_method_types)) |>
  tidyr::unnest(method_type, keep_empty = FALSE) |>
  dplyr::filter(!is.na(method_type), method_type != "", method_type != "none_detected") |>
  dplyr::arrange(method_type, pid)

tough_calls <- classifications |>
  dplyr::filter(tough_call %in% TRUE) |>
  dplyr::select(pid, title, journal_title, empirical_evidence_type, quantitative_analysis_type, tough_call_reason) |>
  dplyr::arrange(journal_title, title)

readr::write_csv(tough_calls, paths$tough_calls, na = "")
readr::write_csv(method_articles, paths$methods, na = "")

report_lines <- c(
  "# Piloto v3 por leitura integral: síntese pós-consolidação",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Integridade",
  "",
  paste0("- Classificações no CSV consolidado: ", nrow(classifications), "."),
  paste0("- Reading logs: ", reading_log_count, "."),
  paste0("- Arquivos de falha: ", failed_count, "."),
  paste0("- Tough calls: ", empirical_flags$tough_calls, "."),
  "",
  "## Tabela 1. Indicadores agregados do piloto v3 integral",
  "",
  md_table(empirical_flags),
  "",
  "## Tabela 2. Distribuição por tipo de evidência e análise quantitativa",
  "",
  md_table(evidence_distribution),
  "",
  "## Tabela 3. Distribuição do screen de revolução da credibilidade",
  "",
  md_table(screen_distribution),
  "",
  "## Tabela 4. Rótulos de método nos casos com `method_present == TRUE`",
  "",
  md_table(methods_detected),
  "",
  "`observational_regression_with_causal_claim_no_design` é um rótulo diagnóstico conservador, não um método de credibilidade em sentido estrito.",
  "",
  "## Tabela 5. Rótulos compatíveis com método de credibilidade em sentido estrito",
  "",
  md_table(credibility_specific_methods),
  "",
  "## Tabela 6. Tough calls por tipo de evidência",
  "",
  md_table(
    tough_calls |>
      dplyr::count(empirical_evidence_type, quantitative_analysis_type, name = "n") |>
      dplyr::arrange(dplyr::desc(n), empirical_evidence_type)
  ),
  "",
  "## Arquivos derivados",
  "",
  paste0("- Tough calls: `", "quality_reports/credibility_prompt_v3_integral_tough_calls.csv", "`."),
  paste0("- Artigos com método detectado: `", "quality_reports/credibility_prompt_v3_integral_methods_detected.csv", "`."),
  "",
  "## Nota metodológica",
  "",
  "Esta síntese apenas resume o piloto integral consolidado. Ela não declara o conjunto como gold; antes disso, ainda é necessário auditar manualmente uma amostra dos reading logs e das tough calls."
)

write_utf8_lines(report_lines, paths$report)

cat("Relatório escrito em:", paths$report, "\n")
cat("Tough calls escritos em:", paths$tough_calls, "\n")
cat("Métodos detectados escritos em:", paths$methods, "\n")
