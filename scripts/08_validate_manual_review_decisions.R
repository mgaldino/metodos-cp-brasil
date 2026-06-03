## 08_validate_manual_review_decisions.R
## Valida o snapshot da planilha de revisão manual contra as filas locais
## e checa overrides estruturados necessários para pendências JSON.

options(scipen = 999)

for (locale_name in c("pt_BR.UTF-8", "en_US.UTF-8", "C.UTF-8")) {
  locale_result <- try(Sys.setlocale("LC_CTYPE", locale_name), silent = TRUE)
  if (!inherits(locale_result, "try-error") && !is.na(locale_result)) {
    break
  }
}

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(stringr)
  library(tibble)
})

find_project_dir <- function() {
  file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  candidates <- c()
  if (length(file_arg) > 0) {
    script_path <- sub("^--file=", "", file_arg[1])
    candidates <- c(candidates, dirname(normalizePath(script_path, mustWork = TRUE)))
  }
  candidates <- c(candidates, normalizePath(getwd(), mustWork = TRUE))

  for (candidate in candidates) {
    current <- candidate
    repeat {
      if (file.exists(file.path(current, "metodos_CP.Rproj"))) {
        return(normalizePath(current, mustWork = TRUE))
      }
      parent <- dirname(current)
      if (identical(parent, current)) {
        break
      }
      current <- parent
    }
  }
  stop("Não foi possível localizar a raiz do projeto.")
}

project_dir <- find_project_dir()

paths <- list(
  sheet_snapshot = file.path(project_dir, "data", "processed", "manual_review_decisions_google_sheet.csv"),
  normalization_log = file.path(project_dir, "quality_reports", "classification_normalization_log.csv"),
  queue = file.path(project_dir, "quality_reports", "manual_review_queue.csv"),
  excluded_queue = file.path(project_dir, "quality_reports", "manual_review_queue_excluded_journals.csv"),
  excluded_article_queue = file.path(project_dir, "quality_reports", "manual_review_queue_excluded_articles.csv"),
  relationship_overrides = file.path(project_dir, "data", "processed", "manual_review_relationship_overrides.json"),
  validated = file.path(project_dir, "quality_reports", "manual_review_decisions_validated.csv"),
  issues = file.path(project_dir, "quality_reports", "manual_review_decisions_issues.csv"),
  summary = file.path(project_dir, "quality_reports", "manual_review_decisions_validation_summary.md")
)

sheet_url <- "https://docs.google.com/spreadsheets/d/1DZgnyu9StUDLE0szvkWFutqA1hI-_QqOlqvRO5dBH4k/edit?usp=sharing"
csv_export_url <- "https://docs.google.com/spreadsheets/d/1DZgnyu9StUDLE0szvkWFutqA1hI-_QqOlqvRO5dBH4k/gviz/tq?tqx=out:csv&sheet=manual_review_queue"

required_files <- unlist(paths[c(
  "sheet_snapshot",
  "normalization_log",
  "queue",
  "excluded_queue",
  "excluded_article_queue",
  "relationship_overrides"
)])
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  stop("Arquivos ausentes: ", paste(missing_files, collapse = "; "))
}

decode_angle_hex_text <- function(value) {
  if (!is.character(value)) {
    return(value)
  }
  decode_one <- function(text) {
    if (is.na(text)) {
      return(NA_character_)
    }
    matches <- gregexpr("(<[0-9A-Fa-f]{2}>)+", text, perl = TRUE)
    matched_text <- regmatches(text, matches)
    if (length(matched_text[[1]]) == 0) {
      return(text)
    }
    replacements <- lapply(matched_text, function(items) {
      vapply(items, function(item) {
        hex <- regmatches(item, gregexpr("[0-9A-Fa-f]{2}", item, perl = TRUE))[[1]]
        rawToChar(as.raw(strtoi(hex, base = 16L)))
      }, character(1))
    })
    regmatches(text, matches) <- replacements
    text
  }
  vapply(value, decode_one, character(1), USE.NAMES = FALSE)
}

read_csv_utf8 <- function(path) {
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    locale = readr::locale(encoding = "UTF-8")
  ) |>
    dplyr::mutate(dplyr::across(where(is.character), decode_angle_hex_text))
}

markdown_table <- function(df, max_rows = Inf) {
  if (nrow(df) == 0) {
    return("_Nenhum registro._")
  }
  df <- utils::head(df, max_rows)
  df <- df |>
    dplyr::mutate(dplyr::across(
      dplyr::everything(),
      ~ stringr::str_replace_all(ifelse(is.na(.x), "", as.character(.x)), "\\|", "\\\\|")
    ))
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- apply(df, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

key_cols <- c("pid", "field", "file", "issue_rule", "action")
# Janela da rodada manual documentada neste checkpoint de validação.
review_date_min <- as.Date("2026-06-01")
review_date_max <- as.Date("2026-06-03")
relationship_required_fields <- c(
  "iv_var_name",
  "dv_var_name",
  "relationship_type",
  "statistically_significant",
  "substantively_significant"
)
relationship_types <- c("Positive", "Negative", "Non-Monotonic", "Null", "Unknown")

is_valid_relationship_value <- function(value) {
  if (!is.list(value) || length(value) == 0) {
    return(FALSE)
  }
  all(vapply(value, function(item) {
    is.list(item) &&
      all(relationship_required_fields %in% names(item)) &&
      is.character(item$iv_var_name) &&
      length(item$iv_var_name) == 1 &&
      nzchar(item$iv_var_name) &&
      is.character(item$dv_var_name) &&
      length(item$dv_var_name) == 1 &&
      nzchar(item$dv_var_name) &&
      is.character(item$relationship_type) &&
      length(item$relationship_type) == 1 &&
      item$relationship_type %in% relationship_types &&
      is.logical(item$statistically_significant) &&
      length(item$statistically_significant) == 1 &&
      is.logical(item$substantively_significant) &&
      length(item$substantively_significant) == 1
  }, logical(1)))
}

scalar_text <- function(value) {
  if (is.null(value) || length(value) != 1 || is.na(value)) {
    return("")
  }
  as.character(value)
}

valid_review_date <- function(value) {
  parsed_value <- suppressWarnings(as.Date(value))
  !is.na(parsed_value) &&
    parsed_value >= review_date_min &&
    parsed_value <= review_date_max
}

sheet <- read_csv_utf8(paths$sheet_snapshot)
normalization_log <- read_csv_utf8(paths$normalization_log)
queue <- read_csv_utf8(paths$queue) |>
  dplyr::mutate(queue_source = "main_queue")
excluded_queue <- read_csv_utf8(paths$excluded_queue) |>
  dplyr::mutate(queue_source = "excluded_journal_queue")
excluded_article_queue <- read_csv_utf8(paths$excluded_article_queue) |>
  dplyr::mutate(queue_source = "excluded_article_queue")

overrides_raw <- jsonlite::fromJSON(paths$relationship_overrides, simplifyVector = FALSE)
override_rows <- lapply(overrides_raw, function(item) {
  override_by <- scalar_text(item$decision_by)
  override_note <- scalar_text(item$decision_note)
  override_date <- scalar_text(item$decision_date)
  tibble(
    pid = scalar_text(item$pid),
    field = scalar_text(item$field),
    structured_override_json = as.character(jsonlite::toJSON(
      item$value,
      auto_unbox = TRUE,
      null = "null"
    )),
    structured_override_note = override_note,
    structured_override_by = override_by,
    structured_override_date = override_date,
    structured_override_value_valid = is_valid_relationship_value(item$value),
    structured_override_metadata_valid = nzchar(stringr::str_trim(override_by)) &&
      nzchar(stringr::str_trim(override_note)) &&
      valid_review_date(override_date)
  )
})
relationship_overrides <- dplyr::bind_rows(override_rows) |>
  dplyr::mutate(
    structured_override_valid = structured_override_value_valid &
      structured_override_metadata_valid
  )

full_queue <- dplyr::bind_rows(queue, excluded_queue, excluded_article_queue) |>
  dplyr::mutate(
    excluded_by_journal = dplyr::coalesce(excluded_by_journal, FALSE),
    excluded_by_article = dplyr::coalesce(excluded_by_article, FALSE),
    excluded_from_analysis = dplyr::coalesce(
      excluded_from_analysis,
      excluded_by_journal | excluded_by_article
    ),
    exclusion_reason = dplyr::coalesce(exclusion_reason, "")
  )

manual_log <- normalization_log |>
  dplyr::filter(manual_review) |>
  dplyr::select(dplyr::all_of(key_cols))

key_string <- function(df) {
  do.call(paste, c(df |> dplyr::select(dplyr::all_of(key_cols)), sep = "||"))
}

sheet$review_key <- key_string(sheet)

full_queue$review_key <- key_string(full_queue)

manual_log$review_key <- key_string(manual_log)

sheet_duplicate_keys <- sheet |>
  dplyr::count(review_key, name = "n") |>
  dplyr::filter(n > 1)

full_queue_duplicate_keys <- full_queue |>
  dplyr::count(review_key, name = "n") |>
  dplyr::filter(n > 1)

manual_log_duplicate_keys <- manual_log |>
  dplyr::count(review_key, name = "n") |>
  dplyr::filter(n > 1)

relationship_override_duplicates <- relationship_overrides |>
  dplyr::count(pid, field, name = "n") |>
  dplyr::filter(n > 1)

sheet_missing_from_queue <- sheet |>
  dplyr::anti_join(full_queue |> dplyr::select(review_key), by = "review_key")

queue_missing_from_sheet <- full_queue |>
  dplyr::anti_join(sheet |> dplyr::select(review_key), by = "review_key")

log_missing_from_sheet <- manual_log |>
  dplyr::anti_join(sheet |> dplyr::select(review_key), by = "review_key")

validated <- sheet |>
  dplyr::left_join(
    full_queue |>
      dplyr::select(
        review_key,
        issn,
        local_allowed_values = allowed_values,
        excluded_by_journal,
        excluded_by_article,
        excluded_from_analysis,
        exclusion_reason,
        queue_source
      ),
    by = "review_key"
  ) |>
  dplyr::left_join(
    relationship_overrides,
    by = c("pid", "field")
  ) |>
  dplyr::mutate(
    excluded_by_journal = dplyr::coalesce(excluded_by_journal, FALSE),
    excluded_by_article = dplyr::coalesce(excluded_by_article, FALSE),
    excluded_from_analysis = dplyr::coalesce(
      excluded_from_analysis,
      excluded_by_journal | excluded_by_article
    ),
    exclusion_reason = dplyr::coalesce(exclusion_reason, ""),
    decision_status = stringr::str_trim(decision_status),
    decision_value = dplyr::if_else(is.na(decision_value), "", stringr::str_trim(decision_value)),
    review_date = dplyr::if_else(is.na(review_date), "", stringr::str_trim(as.character(review_date))),
    parsed_review_date = suppressWarnings(as.Date(review_date)),
    review_date_required = decision_status == "done",
    review_date_invalid_format = review_date_required &
      (review_date == "" | is.na(parsed_review_date)),
    review_date_outside_window = review_date_required &
      !is.na(parsed_review_date) &
      (parsed_review_date < review_date_min | parsed_review_date > review_date_max),
    review_date_issue = review_date_invalid_format | review_date_outside_window,
    local_allowed_values = dplyr::if_else(is.na(local_allowed_values), "", local_allowed_values),
    structured_override_value_valid = dplyr::coalesce(structured_override_value_valid, FALSE),
    structured_override_metadata_valid = dplyr::coalesce(structured_override_metadata_valid, FALSE),
    structured_override_valid = dplyr::coalesce(structured_override_valid, FALSE),
    has_structured_override = decision_value == "structured_json_required" &
      structured_override_valid,
    local_allowed_list = stringr::str_split(local_allowed_values, fixed(" | ")),
    value_allowed_strict = mapply(
      function(value, allowed_values) {
        nzchar(value) && value %in% allowed_values
      },
      decision_value,
      local_allowed_list
    ),
    sheet_allowed_values_mismatch = allowed_values != local_allowed_values,
    pending_blocks_main_analysis = decision_status != "done" & !excluded_from_analysis,
    pending_dispensed_by_exclusion = decision_status != "done" & excluded_from_analysis,
    strict_codebook_issue = decision_status == "done" &
      !value_allowed_strict &
      !excluded_from_analysis,
    requires_substantive_json = decision_status == "done" &
      decision_value == "structured_json_required" &
      !excluded_from_analysis &
      !has_structured_override,
    validation_issue = dplyr::case_when(
      pending_blocks_main_analysis ~ "pending_nonexcluded",
      strict_codebook_issue ~ "decision_value_outside_local_codebook",
      requires_substantive_json ~ "structured_json_required_placeholder",
      review_date_invalid_format ~ "review_date_missing_or_invalid",
      review_date_outside_window ~ "review_date_outside_expected_window",
      sheet_allowed_values_mismatch ~ "sheet_allowed_values_mismatch",
      TRUE ~ ""
    )
  ) |>
  dplyr::select(
    decision_status,
    decision_value,
    decision_note,
    reviewer,
    review_date,
    pid,
    field,
    issn,
    journal_title,
    excluded_by_journal,
    excluded_by_article,
    excluded_from_analysis,
    exclusion_reason,
    queue_source,
    local_allowed_values,
    allowed_values,
    value_allowed_strict,
    sheet_allowed_values_mismatch,
    pending_blocks_main_analysis,
    pending_dispensed_by_exclusion,
    strict_codebook_issue,
    requires_substantive_json,
    review_date_issue,
    review_date_invalid_format,
    review_date_outside_window,
    has_structured_override,
    structured_override_value_valid,
    structured_override_metadata_valid,
    structured_override_valid,
    structured_override_json,
    structured_override_note,
    structured_override_by,
    structured_override_date,
    validation_issue,
    old_value,
    new_value,
    reason,
    decision_hint,
    confidence,
    title,
    authors,
    year,
    language,
    url_scielo,
    abstract_pt,
    abstract_en,
    subfield,
    evidence_type_current,
    method_status_current,
    countries_of_focus,
    main_causal_research_design,
    brief_justification,
    old_json,
    new_json,
    file,
    issue_rule,
    action
  )

issues <- validated |>
  dplyr::filter(validation_issue != "") |>
  dplyr::arrange(excluded_by_journal, validation_issue, field, pid)

required_structured_overrides <- validated |>
  dplyr::filter(
    decision_status == "done",
    decision_value == "structured_json_required",
    !excluded_from_analysis
  ) |>
  dplyr::select(pid, field) |>
  dplyr::distinct()

relationship_override_usage <- relationship_overrides |>
  dplyr::left_join(
    required_structured_overrides |>
      dplyr::mutate(override_required = TRUE),
    by = c("pid", "field")
  ) |>
  dplyr::mutate(
    override_required = dplyr::coalesce(override_required, FALSE),
    unused_override = !override_required
  )

relationship_override_issues <- relationship_override_usage |>
  dplyr::filter(
    !structured_override_value_valid |
      !structured_override_metadata_valid |
      unused_override
  ) |>
  dplyr::select(
    pid,
    field,
    structured_override_value_valid,
    structured_override_metadata_valid,
    override_required,
    unused_override,
    structured_override_by,
    structured_override_date,
    structured_override_note
  )

readr::write_csv(validated, paths$validated, na = "")
readr::write_csv(issues, paths$issues, na = "")

snapshot <- tibble(
  item = c(
    "linhas no snapshot da planilha",
    "linhas manual_review=TRUE no log",
    "linhas na fila principal local",
    "linhas dispensadas por exclusão de periódico",
    "linhas dispensadas por exclusão de artigo",
    "chaves duplicadas no snapshot",
    "chaves duplicadas nas filas locais",
    "chaves duplicadas no log manual",
    "overrides estruturados duplicados",
    "linhas do snapshot sem par local",
    "linhas locais sem par no snapshot",
    "linhas do log manual sem par no snapshot",
    "linhas principais marcadas done",
    "linhas principais ainda pending",
    "linhas pending dispensadas por exclusão",
    "valores done fora do codebook local na análise principal",
    "placeholders structured_json_required sem override",
    "overrides estruturados de main_variable_relationship",
    "overrides estruturados com valor inválido",
    "overrides estruturados com metadados inválidos",
    "overrides estruturados sem placeholder correspondente",
    "datas de revisão fora da janela esperada",
    "mismatches de allowed_values na planilha"
  ),
  value = c(
    nrow(sheet),
    nrow(manual_log),
    sum(validated$queue_source == "main_queue", na.rm = TRUE),
    sum(validated$queue_source == "excluded_journal_queue", na.rm = TRUE),
    sum(validated$queue_source == "excluded_article_queue", na.rm = TRUE),
    nrow(sheet_duplicate_keys),
    nrow(full_queue_duplicate_keys),
    nrow(manual_log_duplicate_keys),
    nrow(relationship_override_duplicates),
    nrow(sheet_missing_from_queue),
    nrow(queue_missing_from_sheet),
    nrow(log_missing_from_sheet),
    sum(validated$queue_source == "main_queue" & validated$decision_status == "done", na.rm = TRUE),
    sum(validated$pending_blocks_main_analysis, na.rm = TRUE),
    sum(validated$pending_dispensed_by_exclusion, na.rm = TRUE),
    sum(validated$strict_codebook_issue, na.rm = TRUE),
    sum(validated$requires_substantive_json, na.rm = TRUE),
    nrow(relationship_overrides),
    sum(!relationship_overrides$structured_override_value_valid, na.rm = TRUE),
    sum(!relationship_overrides$structured_override_metadata_valid, na.rm = TRUE),
    sum(relationship_override_usage$unused_override, na.rm = TRUE),
    sum(validated$review_date_issue, na.rm = TRUE),
    sum(validated$sheet_allowed_values_mismatch, na.rm = TRUE)
  )
)

status_by_scope <- validated |>
  dplyr::count(
    queue_source,
    excluded_by_journal,
    excluded_by_article,
    excluded_from_analysis,
    decision_status,
    name = "n"
  ) |>
  dplyr::arrange(queue_source, decision_status)

pending_excluded <- validated |>
  dplyr::filter(pending_dispensed_by_exclusion) |>
  dplyr::count(queue_source, journal_title, issn, exclusion_reason, name = "n") |>
  dplyr::arrange(dplyr::desc(n), journal_title)

article_excluded <- validated |>
  dplyr::filter(queue_source == "excluded_article_queue") |>
  dplyr::count(pid, title, journal_title, exclusion_reason, name = "n") |>
  dplyr::arrange(journal_title, title)

relationship_override_table <- relationship_overrides |>
  dplyr::select(
    pid,
    field,
    structured_override_value_valid,
    structured_override_metadata_valid,
    structured_override_valid,
    structured_override_note,
    structured_override_by,
    structured_override_date
  ) |>
  dplyr::arrange(pid, field)

strict_issues <- issues |>
  dplyr::filter(validation_issue %in% c(
    "decision_value_outside_local_codebook",
    "structured_json_required_placeholder"
  )) |>
  dplyr::select(
    pid,
    field,
    journal_title,
    decision_value,
    local_allowed_values,
    decision_note,
    validation_issue
  )

hard_fail <- nrow(sheet_duplicate_keys) > 0 ||
  nrow(full_queue_duplicate_keys) > 0 ||
  nrow(manual_log_duplicate_keys) > 0 ||
  nrow(relationship_override_duplicates) > 0 ||
  nrow(sheet_missing_from_queue) > 0 ||
  nrow(queue_missing_from_sheet) > 0 ||
  nrow(log_missing_from_sheet) > 0 ||
  sum(validated$pending_blocks_main_analysis, na.rm = TRUE) > 0 ||
  sum(validated$strict_codebook_issue, na.rm = TRUE) > 0 ||
  sum(validated$requires_substantive_json, na.rm = TRUE) > 0 ||
  sum(!relationship_overrides$structured_override_valid, na.rm = TRUE) > 0 ||
  sum(relationship_override_usage$unused_override, na.rm = TRUE) > 0

relative_path <- function(path) {
  abs_path <- normalizePath(path, mustWork = FALSE)
  prefix <- paste0(project_dir, .Platform$file.sep)
  if (startsWith(abs_path, prefix)) {
    return(substring(abs_path, nchar(prefix) + 1))
  }
  abs_path
}

non_blocking_warnings <- sum(validated$review_date_issue, na.rm = TRUE) +
  sum(validated$sheet_allowed_values_mismatch, na.rm = TRUE)

summary_lines <- c(
  "# Validação das Decisões Manuais",
  "",
  "Gerado por `scripts/08_validate_manual_review_decisions.R`.",
  "",
  "## Fonte",
  "",
  paste0("- Planilha Google Sheets: ", sheet_url),
  paste0("- Endpoint CSV usado para o snapshot: ", csv_export_url),
  "- Snapshot salvo em `data/processed/manual_review_decisions_google_sheet.csv`.",
  "- A validação compara chaves `pid + field + file + issue_rule + action`, não posição de linha.",
  paste0(
    "- A janela esperada de revisão manual é de `", review_date_min,
    "` a `", review_date_max, "`; datas fora da janela são avisos de auditoria, não falhas substantivas."
  ),
  "",
  "## Status",
  "",
  if (hard_fail) {
    "Há falhas bloqueantes para a fila principal. Não aplicar decisões ao CSV final antes de corrigir."
  } else {
    "Fila principal operacionalmente completa: todas as chaves foram pareadas e todos os itens não excluídos estão `done`."
  },
  "",
  paste0(
    "Observação: os placeholders de `main_variable_relationship` foram resolvidos por overrides estruturados. ",
    "Há ", non_blocking_warnings, " aviso(s) não bloqueante(s) registrado(s) em `manual_review_decisions_issues.csv`."
  ),
  "",
  "## Snapshot",
  "",
  markdown_table(snapshot),
  "",
  "## Status por Escopo",
  "",
  markdown_table(status_by_scope),
  "",
  "## Pendências Dispensadas por Exclusão",
  "",
  markdown_table(pending_excluded),
  "",
  "## Itens Dispensados por Exclusão de Artigo",
  "",
  markdown_table(article_excluded),
  "",
  "## Itens com Ressalva de Aplicação",
  "",
  markdown_table(strict_issues, max_rows = 50),
  "",
  "## Overrides Estruturados",
  "",
  markdown_table(relationship_override_table),
  "",
  "## Problemas de Overrides Estruturados",
  "",
  markdown_table(relationship_override_issues),
  "",
  "## Interpretação",
  "",
  "- `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` estão documentados em `data/processed/excluded_journals.csv` e suas pendências restantes aparecem apenas como dispensadas por periódico.",
  "- Obituário, editorial, comentário crítico, errata e nota fora de escopo estão documentados em `data/processed/excluded_articles.csv` e ficam fora da análise principal.",
  "- As decisões da fila principal estão completas, mas nem todas são diretamente aplicáveis ao schema atual sem regra adicional.",
  "- Os placeholders `structured_json_required` foram resolvidos em `data/processed/manual_review_relationship_overrides.json`.",
  "- A próxima etapa pode aplicar as decisões manuais e os overrides para regerar `classifications_llm.csv` final.",
  "- Avisos não bloqueantes permanecem documentados em `quality_reports/manual_review_decisions_issues.csv`.",
  "",
  "## Arquivos Gerados",
  "",
  paste0("- `", relative_path(paths$validated), "`"),
  paste0("- `", relative_path(paths$issues), "`"),
  paste0("- `", relative_path(paths$summary), "`")
)

writeLines(summary_lines, paths$summary, useBytes = TRUE)

cat("Validação das decisões manuais concluída.\n")
cat("Linhas no snapshot:", nrow(sheet), "\n")
cat("Fila principal done:", sum(validated$queue_source == "main_queue" & validated$decision_status == "done", na.rm = TRUE), "\n")
cat("Fila principal pending:", sum(validated$pending_blocks_main_analysis, na.rm = TRUE), "\n")
cat("Pendências dispensadas por exclusão:", sum(validated$pending_dispensed_by_exclusion, na.rm = TRUE), "\n")
cat("Ressalvas de codebook/aplicação:", nrow(strict_issues), "\n")
cat("Overrides estruturados:", nrow(relationship_overrides), "\n")
cat("Resumo:", relative_path(paths$summary), "\n")

if (hard_fail) {
  stop("Validação com falhas bloqueantes para a fila principal.")
}
