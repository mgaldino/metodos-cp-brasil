## 37_audit_paper_corpus_completeness.R
## Gate 0 audit for the paper-writing workflow.

options(scipen = 999, encoding = "UTF-8")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
})

project_dir <- normalizePath(".", mustWork = TRUE)
path <- function(...) file.path(project_dir, ...)

manifest_path <- path("data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv")
classifications_path <- path("data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv")
reading_logs_dir <- path("data/processed/credibility_prompt_v3_integral_reading/full_corpus/reading_logs")
fulltext_path <- path("data/processed/fulltext_corpus/article_texts_corpus.csv")

analysis_dir <- path("data/processed/paper_analysis")
audit_dir <- path("quality_reports/paper_variable_audit")
dir.create(analysis_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(audit_dir, recursive = TRUE, showWarnings = FALSE)

required_files <- c(manifest_path, classifications_path, fulltext_path)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  stop("Arquivos obrigatórios ausentes: ", paste(missing_files, collapse = ", "))
}

parse_bool <- function(x) {
  value <- stringr::str_to_upper(stringr::str_trim(dplyr::coalesce(as.character(x), "")))
  dplyr::case_when(
    value == "TRUE" ~ TRUE,
    value == "FALSE" ~ FALSE,
    TRUE ~ NA
  )
}

period_3 <- function(year) {
  dplyr::case_when(
    dplyr::between(year, 2005L, 2011L) ~ "2005-2011",
    dplyr::between(year, 2012L, 2018L) ~ "2012-2018",
    dplyr::between(year, 2019L, 2025L) ~ "2019-2025",
    TRUE ~ NA_character_
  )
}

fmt_pct <- function(n, d) {
  if (is.na(d) || d == 0) {
    return("NA")
  }
  paste0(round(100 * n / d, 1), "%")
}

write_utf8_lines <- function(lines, file) {
  con <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  writeLines(enc2utf8(lines), con = con, useBytes = TRUE)
}

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE) |>
  dplyr::mutate(
    year = as.integer(year),
    period_3 = period_3(year)
  )

classifications <- readr::read_csv(classifications_path, show_col_types = FALSE) |>
  dplyr::mutate(
    is_empirical_paper = parse_bool(is_empirical_paper),
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    causal_or_explanatory_claim_present = parse_bool(causal_or_explanatory_claim_present),
    credibility_revolution_screen_applicable = parse_bool(credibility_revolution_screen_applicable),
    credibility_revolution_method_present = parse_bool(credibility_revolution_method_present)
  )

fulltext <- readr::read_csv(
  fulltext_path,
  col_select = c(pid, year, journal_title, document_type, body_word_count, input_hash),
  show_col_types = FALSE
) |>
  dplyr::mutate(year = as.integer(year))

reading_log_files <- if (dir.exists(reading_logs_dir)) {
  list.files(reading_logs_dir, pattern = "\\.json$", full.names = FALSE)
} else {
  character()
}
reading_log_pids <- sub("\\.json$", "", reading_log_files)

excluded_main_journals <- c(
  "Brazilian Journal of Political Economy",
  "Civitas - Revista de Ciências Sociais"
)

classified_in_manifest <- classifications |>
  dplyr::semi_join(manifest |> dplyr::select(pid), by = "pid")

classified_not_in_manifest <- classifications |>
  dplyr::anti_join(manifest |> dplyr::select(pid), by = "pid") |>
  dplyr::select(pid, title, journal_title)

manifest_not_classified <- manifest |>
  dplyr::anti_join(classifications |> dplyr::select(pid), by = "pid") |>
  dplyr::select(pid, title, journal_title, year, period_3, eligible_order)

classified_no_log <- classified_in_manifest |>
  dplyr::filter(!pid %in% reading_log_pids) |>
  dplyr::select(pid, title, journal_title)

manifest_no_fulltext <- manifest |>
  dplyr::anti_join(fulltext |> dplyr::select(pid), by = "pid") |>
  dplyr::select(pid, title, journal_title, year, period_3, eligible_order)

n_manifest <- dplyr::n_distinct(manifest$pid)
n_classified <- dplyr::n_distinct(classified_in_manifest$pid)
n_classified_raw <- dplyr::n_distinct(classifications$pid)
n_fulltext_total <- dplyr::n_distinct(fulltext$pid)
n_fulltext_manifest <- dplyr::n_distinct(dplyr::semi_join(fulltext, manifest |> dplyr::select(pid), by = "pid")$pid)
n_empirical_classified <- sum(classified_in_manifest$is_empirical_paper, na.rm = TRUE)
n_quant_classified <- sum(classified_in_manifest$is_empirical_quant_paper_torreblanca, na.rm = TRUE)
n_causal_classified <- sum(classified_in_manifest$causal_or_explanatory_claim_present, na.rm = TRUE)
n_screen_classified <- sum(classified_in_manifest$credibility_revolution_screen_applicable, na.rm = TRUE)

validation_checks <- tibble::tibble(
  check = c(
    "manifest_exists",
    "manifest_pid_unique",
    "classifications_pid_unique",
    "classified_pids_in_manifest",
    "reading_log_for_each_classified_pid",
    "fulltext_for_each_manifest_pid",
    "excluded_main_journals_absent_from_manifest",
    "excluded_main_journals_absent_from_classifications",
    "manifest_years_2005_2025",
    "classified_years_2005_2025",
    "classification_covers_full_manifest"
  ),
  status = c(
    file.exists(manifest_path),
    nrow(manifest) == n_manifest,
    nrow(classifications) == n_classified_raw,
    nrow(classified_not_in_manifest) == 0,
    nrow(classified_no_log) == 0,
    nrow(manifest_no_fulltext) == 0,
    !any(manifest$journal_title %in% excluded_main_journals),
    !any(classified_in_manifest$journal_title %in% excluded_main_journals),
    all(!is.na(manifest$year) & dplyr::between(manifest$year, 2005L, 2025L)),
    all(!is.na(dplyr::left_join(classified_in_manifest |> dplyr::select(pid), manifest |> dplyr::select(pid, year), by = "pid")$year) &
      dplyr::between(dplyr::left_join(classified_in_manifest |> dplyr::select(pid), manifest |> dplyr::select(pid, year), by = "pid")$year, 2005L, 2025L)),
    n_classified == n_manifest
  ),
  value = c(
    manifest_path,
    paste0(n_manifest, " PIDs únicos em ", nrow(manifest), " linhas"),
    paste0(n_classified_raw, " PIDs únicos em ", nrow(classifications), " linhas"),
    paste0(nrow(classified_not_in_manifest), " PIDs classificados fora do manifest"),
    paste0(n_classified - nrow(classified_no_log), " de ", n_classified, " classificados com log"),
    paste0(n_fulltext_manifest, " de ", n_manifest, " PIDs do manifest com texto integral"),
    paste(sort(intersect(unique(manifest$journal_title), excluded_main_journals)), collapse = "; "),
    paste(sort(intersect(unique(classified_in_manifest$journal_title), excluded_main_journals)), collapse = "; "),
    paste0(min(manifest$year, na.rm = TRUE), "-", max(manifest$year, na.rm = TRUE)),
    paste0(
      min(dplyr::left_join(classified_in_manifest |> dplyr::select(pid), manifest |> dplyr::select(pid, year), by = "pid")$year, na.rm = TRUE),
      "-",
      max(dplyr::left_join(classified_in_manifest |> dplyr::select(pid), manifest |> dplyr::select(pid, year), by = "pid")$year, na.rm = TRUE)
    ),
    paste0(n_classified, " de ", n_manifest, " PIDs classificados (", fmt_pct(n_classified, n_manifest), ")")
  ),
  implication = c(
    "Manifest canônico encontrado.",
    "O manifest tem uma linha por PID.",
    "O CSV combinado tem uma linha por PID.",
    "Classificações combinadas estão dentro do escopo analítico atual.",
    "Cada classificação integrada deve ter evidência de leitura integral.",
    "Todo PID do manifest deve ter texto integral rastreável.",
    "BJPE e Civitas não entram na base analítica do paper.",
    "BJPE e Civitas não entram nos resultados do paper.",
    "O escopo temporal do manifest está correto.",
    "O escopo temporal das classificações está correto.",
    "Se FAIL, os resultados do paper precisam ser explicitamente preliminares."
  )
) |>
  dplyr::mutate(status = if_else(status, "PASS", "FAIL"))

denominator_summary <- tibble::tibble(
  denominator = c(
    "corpus_completo_elegivel",
    "artigos_classificados_com_leitura_integral",
    "artigos_a_classificar",
    "artigos_empiricos_classificados",
    "artigos_empiricos_quantitativos_classificados",
    "artigos_com_claim_causal_ou_explicativo_classificados",
    "artigos_no_screen_de_credibilidade_classificados"
  ),
  n = c(
    n_manifest,
    n_classified,
    n_manifest - n_classified,
    n_empirical_classified,
    n_quant_classified,
    n_causal_classified,
    n_screen_classified
  ),
  denominator_reference = c(
    "manifest completo",
    "manifest completo",
    "manifest completo",
    "classificados",
    "classificados",
    "classificados",
    "classificados"
  ),
  denominator_n = c(
    n_manifest,
    n_manifest,
    n_manifest,
    n_classified,
    n_classified,
    n_classified,
    n_classified
  ),
  percent = c(
    100,
    round(100 * n_classified / n_manifest, 1),
    round(100 * (n_manifest - n_classified) / n_manifest, 1),
    round(100 * n_empirical_classified / n_classified, 1),
    round(100 * n_quant_classified / n_classified, 1),
    round(100 * n_causal_classified / n_classified, 1),
    round(100 * n_screen_classified / n_classified, 1)
  )
)

coverage_by_journal_period <- manifest |>
  dplyr::count(journal_title, period_3, name = "manifest_n") |>
  dplyr::left_join(
    classified_in_manifest |>
      dplyr::left_join(manifest |> dplyr::select(pid, year, period_3), by = "pid") |>
      dplyr::count(journal_title, period_3, name = "classified_n"),
    by = c("journal_title", "period_3")
  ) |>
  dplyr::mutate(
    classified_n = dplyr::coalesce(classified_n, 0L),
    remaining_n = manifest_n - classified_n,
    coverage_percent = round(100 * classified_n / manifest_n, 1)
  ) |>
  dplyr::arrange(journal_title, period_3)

readr::write_csv(validation_checks, file.path(analysis_dir, "gate0_validation_checks.csv"))
readr::write_csv(denominator_summary, file.path(analysis_dir, "gate0_denominator_summary.csv"))
readr::write_csv(coverage_by_journal_period, file.path(analysis_dir, "gate0_coverage_by_journal_period.csv"))
readr::write_csv(classified_not_in_manifest, file.path(analysis_dir, "gate0_classified_not_in_manifest.csv"))
readr::write_csv(classified_no_log, file.path(analysis_dir, "gate0_classified_without_reading_log.csv"))
readr::write_csv(manifest_not_classified, file.path(analysis_dir, "gate0_manifest_not_classified.csv"))
readr::write_csv(manifest_no_fulltext, file.path(analysis_dir, "gate0_manifest_without_fulltext.csv"))

coverage_complete <- n_classified == n_manifest
gate_result <- if (coverage_complete) {
  "A classificação cobre o manifest completo; resultados substantivos finais são possíveis se as variáveis usadas também forem válidas."
} else {
  "A classificação ainda não cobre o manifest completo; qualquer manuscrito precisa rotular os resultados como preliminares."
}

report_lines <- c(
  "# Gate 0: auditoria de completude e escopo do paper",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Resultado do gate",
  "",
  paste0("- ", gate_result),
  paste0("- Manifest completo elegível: ", n_manifest, " PIDs."),
  paste0("- PIDs classificados com leitura integral e no manifest: ", n_classified, " (", fmt_pct(n_classified, n_manifest), " do manifest)."),
  paste0("- PIDs ainda sem classificação combinada: ", n_manifest - n_classified, "."),
  paste0("- PIDs do manifest com texto integral no corpus: ", n_fulltext_manifest, " de ", n_manifest, "."),
  paste0("- PIDs totais no arquivo de texto integral do corpus: ", n_fulltext_total, "."),
  "",
  "## Denominadores atuais",
  "",
  paste0("- Corpus completo elegível: ", n_manifest, "."),
  paste0("- Artigos classificados: ", n_classified, "."),
  paste0("- Artigos empíricos entre classificados: ", n_empirical_classified, " de ", n_classified, " (", fmt_pct(n_empirical_classified, n_classified), ")."),
  paste0("- Artigos empíricos quantitativos entre classificados: ", n_quant_classified, " de ", n_classified, " (", fmt_pct(n_quant_classified, n_classified), ")."),
  paste0("- Artigos com claim causal ou explicativo entre classificados: ", n_causal_classified, " de ", n_classified, " (", fmt_pct(n_causal_classified, n_classified), ")."),
  paste0("- Artigos no screen de credibilidade entre classificados: ", n_screen_classified, " de ", n_classified, " (", fmt_pct(n_screen_classified, n_classified), ")."),
  "",
  "## Checagens",
  "",
  paste0("- Checks PASS: ", sum(validation_checks$status == "PASS"), " de ", nrow(validation_checks), "."),
  paste0("- Checks FAIL: ", paste(validation_checks$check[validation_checks$status == "FAIL"], collapse = "; ")),
  "",
  "## Implicação para a redação",
  "",
  if (coverage_complete) {
    "O paper pode usar linguagem de resultados finais para as variáveis que passarem a auditoria de validade."
  } else {
    "O paper não pode apresentar resultados finais do corpus completo. A versão compilável deve declarar no resumo, em Dados, Resultados e Conclusão que os resultados são preliminares e cobrem apenas os PIDs já classificados por leitura integral."
  },
  "",
  "## Artefatos",
  "",
  "- `data/processed/paper_analysis/gate0_validation_checks.csv`",
  "- `data/processed/paper_analysis/gate0_denominator_summary.csv`",
  "- `data/processed/paper_analysis/gate0_coverage_by_journal_period.csv`",
  "- `data/processed/paper_analysis/gate0_manifest_not_classified.csv`"
)

write_utf8_lines(report_lines, file.path(audit_dir, "gate0_corpus_completeness_audit.md"))
capture.output(sessionInfo(), file = file.path(analysis_dir, "gate0_session_info.txt"))

cat("Gate 0 escrito em:\n")
cat("- ", file.path(audit_dir, "gate0_corpus_completeness_audit.md"), "\n", sep = "")
cat("- ", analysis_dir, "\n", sep = "")
