## 26_triage_fulltext_corpus_validation.R
## Consolida pendências bloqueantes da validação do fulltext corpus.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringi)
  library(stringr)
})

project_dir <- normalizePath(".", mustWork = TRUE)

paths <- list(
  failure_queue = file.path(
    project_dir,
    "data", "processed", "fulltext_corpus", "fulltext_corpus_failure_queue.csv"
  ),
  inventory = file.path(project_dir, "quality_reports", "fulltext_corpus_inventory.csv"),
  triage_csv = file.path(project_dir, "quality_reports", "fulltext_corpus_validation_triage.csv"),
  report = file.path(project_dir, "quality_reports", "fulltext_corpus_validation_triage.md")
)

normalize_key <- function(x) {
  x |>
    dplyr::coalesce("") |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", " ") |>
    stringr::str_squish()
}

is_false <- function(x) {
  stringr::str_to_lower(stringr::str_trim(dplyr::coalesce(as.character(x), ""))) %in%
    c("false", "0", "no", "n", "não", "nao")
}

classify_short_text_case <- function(title) {
  title_key <- normalize_key(title)
  dplyr::case_when(
    title_key == "" ~ "manual_check_blank_title_short_text",
    stringr::str_detect(title_key, "\\berrata\\b") ~ "exclude_candidate_errata",
    stringr::str_detect(
      title_key,
      "\\bapresentacao\\b|\\bpalavras da diretora\\b|\\bnota editorial\\b|\\bnota editoial\\b"
    ) ~ "exclude_candidate_editorial_front_matter",
    stringr::str_detect(title_key, "\\bcritica\\b") ~ "exclude_candidate_review_or_critical_note",
    stringr::str_detect(
      title_key,
      "\\bin memoriam\\b|\\bhomenagem\\b|^para\\b|^eduardo kugelmas$|^maria d alva gil kinzo$"
    ) ~ "exclude_candidate_obituary_or_homage",
    TRUE ~ "manual_check_short_text"
  )
}

action_from_triage <- function(triage_class) {
  dplyr::case_when(
    stringr::str_starts(triage_class, "exclude_candidate_") ~
      "review_for_excluded_articles_ledger",
    triage_class == "duplicate_hash_manual_check" ~
      "manual_compare_duplicate_body_and_source",
    TRUE ~
      "manual_check_source_or_metadata"
  )
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

failure_queue <- readr::read_csv(paths$failure_queue, show_col_types = FALSE)
inventory <- readr::read_csv(paths$inventory, show_col_types = FALSE)

missing_or_invalid <- failure_queue |>
  dplyr::mutate(
    blocking_type = "missing_or_invalid_body",
    triage_class = classify_short_text_case(title),
    recommended_action = action_from_triage(triage_class),
    evidence_summary = paste0(last_status, ": ", last_reason)
  ) |>
  dplyr::select(
    blocking_type,
    pid,
    title,
    year,
    journal_title,
    document_type,
    language,
    triage_class,
    recommended_action,
    evidence_summary,
    last_source_method,
    last_source_url
  )

duplicate_cases <- inventory |>
  dplyr::filter(
    is_false(input_hash_unique_across_pids) |
      is_false(body_hash_unique_across_pids)
  ) |>
  dplyr::mutate(
    blocking_type = "duplicate_hash",
    triage_class = "duplicate_hash_manual_check",
    recommended_action = action_from_triage(triage_class),
    evidence_summary = paste0(
      "input_hash_unique=", input_hash_unique_across_pids,
      "; body_hash_unique=", body_hash_unique_across_pids,
      "; words=", body_word_count
    )
  ) |>
  dplyr::select(
    blocking_type,
    pid,
    title,
    year,
    journal_title,
    document_type,
    language,
    triage_class,
    recommended_action,
    evidence_summary,
    last_source_method = source_method,
    last_source_url = source_url
  )

triage <- dplyr::bind_rows(missing_or_invalid, duplicate_cases) |>
  dplyr::arrange(blocking_type, journal_title, year, pid)

summary_by_action <- triage |>
  dplyr::count(blocking_type, recommended_action, triage_class, name = "n") |>
  dplyr::arrange(blocking_type, dplyr::desc(n), triage_class)

summary_by_journal <- triage |>
  dplyr::count(blocking_type, journal_title, name = "n") |>
  dplyr::arrange(blocking_type, dplyr::desc(n), journal_title)

readr::write_csv(triage, paths$triage_csv, na = "")

report_lines <- c(
  "# Triagem da validação do fulltext corpus",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Síntese",
  "",
  paste0("- Casos bloqueantes triados: ", nrow(triage), "."),
  paste0("- PIDs sem body válido na fila de falhas: ", nrow(missing_or_invalid), "."),
  paste0("- PIDs em pares com hash duplicado: ", nrow(duplicate_cases), "."),
  paste0(
    "- Candidatos prováveis a ledger de exclusão após revisão humana: ",
    sum(stringr::str_starts(triage$triage_class, "exclude_candidate_")), "."
  ),
  paste0(
    "- Casos que exigem checagem manual de fonte/metadado ou duplicidade: ",
    sum(!stringr::str_starts(triage$triage_class, "exclude_candidate_")), "."
  ),
  "",
  "Esta triagem não altera `excluded_articles.csv` nem o corpus processado. Ela apenas organiza os bloqueios para decisão manual rastreável.",
  "",
  "## Tabela 1. Casos por tipo de bloqueio e ação recomendada",
  "",
  md_table(summary_by_action),
  "",
  "## Tabela 2. Casos por periódico",
  "",
  md_table(summary_by_journal),
  "",
  "## Próximas decisões",
  "",
  "1. Revisar os candidatos a exclusão e, se confirmado que são erratas, apresentações, notas editoriais, homenagens ou críticas curtas fora do escopo, registrar a decisão em um ledger rastreável antes de rerodar a validação.",
  "2. Checar manualmente os casos com título vazio ou curto sem marcador explícito de tipo documental.",
  "3. Comparar os pares duplicados por `source_url`, `input_hash` e conteúdo bruto para decidir se são duplicatas reais do SciELO, alias de PID ou erro de extração.",
  "4. Só declarar o fulltext corpus pronto para escala quando `scripts/17_validate_fulltext_corpus.R` não tiver bloqueios ou quando os bloqueios remanescentes estiverem documentados como exclusões metodológicas."
)

readr::write_lines(report_lines, paths$report)

cat("Triagem escrita em:", paths$triage_csv, "\n")
cat("Relatório escrito em:", paths$report, "\n")
