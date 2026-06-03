## 09_apply_manual_review_decisions.R
## Aplica decisões manuais validadas às classificações normalizadas.
##
## Entradas principais:
## - quality_reports/manual_review_decisions_validated.csv
## - data/processed/manual_review_relationship_overrides.json
## - data/processed/classifications_normalized/
##
## Saídas principais:
## - data/processed/classifications_final/
## - data/processed/classifications_llm.csv
## - data/processed/classifications_llm_main_analysis.csv
## - quality_reports/manual_review_application_log.csv
## - quality_reports/manual_review_application_summary.md
## - quality_reports/classification_validation_*_final.*

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
  library(purrr)
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
  source_dir = file.path(project_dir, "data", "processed", "classifications_normalized"),
  final_dir = file.path(project_dir, "data", "processed", "classifications_final"),
  final_csv = file.path(project_dir, "data", "processed", "classifications_llm.csv"),
  final_main_csv = file.path(project_dir, "data", "processed", "classifications_llm_main_analysis.csv"),
  pre_manual_snapshot = file.path(project_dir, "data", "processed", "classifications_llm_pre_manual_review.csv"),
  manual_decisions = file.path(project_dir, "quality_reports", "manual_review_decisions_validated.csv"),
  relationship_overrides = file.path(project_dir, "data", "processed", "manual_review_relationship_overrides.json"),
  sample = file.path(project_dir, "data", "processed", "sample_validation.csv"),
  excluded_journals = file.path(project_dir, "data", "processed", "excluded_journals.csv"),
  excluded_articles = file.path(project_dir, "data", "processed", "excluded_articles.csv"),
  application_log = file.path(project_dir, "quality_reports", "manual_review_application_log.csv"),
  application_summary = file.path(project_dir, "quality_reports", "manual_review_application_summary.md"),
  validation_issues = file.path(project_dir, "quality_reports", "classification_validation_issues_final.csv"),
  validation_summary = file.path(project_dir, "quality_reports", "classification_validation_summary_final.md")
)

dir.create(paths$final_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(paths$application_log), showWarnings = FALSE, recursive = TRUE)

required_files <- unlist(paths[c(
  "manual_decisions",
  "relationship_overrides",
  "sample",
  "excluded_journals",
  "excluded_articles"
)])
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  stop("Arquivos ausentes: ", paste(missing_files, collapse = "; "))
}
if (!dir.exists(paths$source_dir)) {
  stop("Diretório ausente: ", paths$source_dir)
}

expected_json_fields <- c(
  "pid",
  "error_in_raw_text",
  "subfield",
  "is_empirical_quant_paper",
  "general_goal_of_analysis",
  "single_country_study",
  "single_region",
  "countries_of_focus",
  "paper_uses_survey_data",
  "uses_original_dataset",
  "seeks_determinants",
  "main_causal_research_design",
  "other_research_design",
  "instrumental_variable_instrument",
  "placebo_test",
  "independent_variables",
  "dependent_variables",
  "main_variable_relationship",
  "makes_explicit_causal_claim",
  "makes_implicit_causal_claim",
  "strong_non_causal_causal_qualification",
  "sample_size",
  "sample_size_quote",
  "claims_any_statistically_significant_results",
  "references_power_analysis",
  "clearly_defined_explanatory_variable",
  "clear_causal_quantity_of_interest",
  "specifies_estimate_equations",
  "discusses_threats_to_causality",
  "statement_of_identification_assumptions_quote",
  "statement_of_identification_assumptions",
  "effort_to_explore_mechanisms",
  "mentions_pre_registered_design_and_analysis_plan",
  "evidence_type",
  "method_status",
  "brief_justification"
)

required_not_null_fields <- c(
  "pid",
  "error_in_raw_text",
  "subfield",
  "is_empirical_quant_paper",
  "paper_uses_survey_data",
  "evidence_type",
  "method_status",
  "brief_justification"
)

allowed <- list(
  error_in_raw_text = c("No Error", "Missing/Corrupt", "Title/Text Mismatch"),
  subfield = c(
    "Brazilian Politics",
    "Comparative Politics",
    "International Relations",
    "Methodology and Formal Theory",
    "Political Theory and Philosophy",
    "Public Policy/Administration",
    "Other"
  ),
  general_goal_of_analysis = c("Describe", "Predict", "Explain"),
  single_country_study = c("single_country", "multiple_countries"),
  single_region = c("single_region", "multiple_region"),
  paper_uses_survey_data = c(
    "no_survey_data",
    "runs_original_survey",
    "uses_public_available_survey"
  ),
  uses_original_dataset = c(
    "original_survey",
    "field_experiment",
    "field_study",
    "structure_systematize",
    "procure_original_data",
    "other_original_data",
    "not_original"
  ),
  main_causal_research_design = c(
    "Field Experiment",
    "Survey Experiment",
    "Lab Experiment",
    "Diff-in-Diff",
    "Instrumental Variable",
    "Regression Discontinuity Design",
    "Regression Kink Design",
    "Synthetic Control",
    "Matching/Weighting/Balancing",
    "Kitchen Sink Linear Model",
    "Multiple Designs",
    "Other"
  ),
  clear_causal_quantity_of_interest = c("ATE", "ATT", "ATC", "LATE", "CATE", "ITT", "FALSE"),
  effort_to_explore_mechanisms = c(
    "No Mention of Mechanisms/Channels",
    "Mechanisms/Channels Mentioned But Not Explored",
    "Mechanisms/Channels Mentioned With Substantial Exploration"
  ),
  evidence_type = c("quantitative", "qualitative", "mixed", "theoretical-normative"),
  method_status = c("explicit", "essayistic")
)

nullable_fields <- setdiff(expected_json_fields, required_not_null_fields)
boolean_fields <- c(
  "is_empirical_quant_paper",
  "seeks_determinants",
  "placebo_test",
  "makes_explicit_causal_claim",
  "makes_implicit_causal_claim",
  "strong_non_causal_causal_qualification",
  "claims_any_statistically_significant_results",
  "references_power_analysis",
  "clearly_defined_explanatory_variable",
  "specifies_estimate_equations",
  "discusses_threats_to_causality",
  "statement_of_identification_assumptions",
  "mentions_pre_registered_design_and_analysis_plan"
)
list_fields <- c("independent_variables", "dependent_variables", "main_variable_relationship")

excluded_schema_defaults <- list(
  error_in_raw_text = "No Error",
  subfield = "Other",
  is_empirical_quant_paper = FALSE,
  paper_uses_survey_data = "no_survey_data",
  evidence_type = "theoretical-normative",
  method_status = "essayistic"
)

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

json_value <- function(x) {
  jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null")
}

value_type <- function(x) {
  if (is.null(x)) {
    return("null")
  }
  if (is.logical(x) && length(x) == 1) {
    return("logical")
  }
  if (is.character(x) && length(x) == 1) {
    return("character")
  }
  if (is.numeric(x) && length(x) == 1) {
    return("numeric")
  }
  if (is.list(x) && !is.data.frame(x)) {
    return("list")
  }
  paste(class(x), collapse = "/")
}

value_label <- function(x) {
  if (is.null(x)) {
    return("<NULL>")
  }
  if (length(x) == 0) {
    return("<EMPTY>")
  }
  if (is.list(x) && !is.data.frame(x)) {
    out <- as.character(json_value(x))
  } else {
    out <- paste(as.character(x), collapse = "; ")
  }
  if (nchar(out) > 180) {
    out <- paste0(substr(out, 1, 177), "...")
  }
  out
}

scalar_text <- function(value) {
  if (is.null(value) || length(value) != 1 || is.na(value)) {
    return("")
  }
  stringr::str_trim(as.character(value))
}

field_value <- function(obj, field) {
  if (!field %in% names(obj)) {
    return(NULL)
  }
  obj[[field]]
}

set_field <- function(obj, field, value) {
  obj[field] <- list(value)
  obj
}

csv_value <- function(x) {
  if (is.null(x)) {
    return("")
  }
  if (is.list(x)) {
    return(as.character(json_value(x)))
  }
  if (length(x) == 0) {
    return("")
  }
  as.character(x[[1]])
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

relative_path <- function(path) {
  abs_path <- normalizePath(path, mustWork = FALSE)
  prefix <- paste0(project_dir, .Platform$file.sep)
  if (startsWith(abs_path, prefix)) {
    return(substring(abs_path, nchar(prefix) + 1))
  }
  abs_path
}

parse_decision_value <- function(field, value) {
  value <- scalar_text(value)
  if (!nzchar(value) || value == "<NULL>") {
    return(NULL)
  }
  if (field %in% boolean_fields) {
    if (value == "TRUE") {
      return(TRUE)
    }
    if (value == "FALSE") {
      return(FALSE)
    }
    stop("Valor booleano inválido para ", field, ": ", value)
  }
  if (field == "sample_size") {
    parsed <- suppressWarnings(as.integer(value))
    if (is.na(parsed) || as.character(parsed) != value || parsed < 0) {
      stop("Valor inteiro inválido para sample_size: ", value)
    }
    return(parsed)
  }
  value
}

is_schema_padding_needed <- function(field, value, excluded_from_analysis) {
  excluded_from_analysis &&
    field %in% names(excluded_schema_defaults) &&
    (is.null(value) || (is.character(value) && length(value) == 1 && !nzchar(stringr::str_trim(value))))
}

schema_padding_value <- function(field, exclusion_reason) {
  if (field == "brief_justification") {
    reason <- if (nzchar(exclusion_reason)) exclusion_reason else "excluded_from_main_analysis"
    return(paste0("Excluído da análise principal: ", reason, ". Registro preservado no corpus."))
  }
  excluded_schema_defaults[[field]]
}

log_rows <- list()

add_log <- function(pid, file, field, queue_source, excluded_from_analysis,
                    exclusion_reason, decision_status, decision_value, action,
                    old_value, new_value, reason, reviewer, review_date,
                    decision_note) {
  log_rows[[length(log_rows) + 1L]] <<- tibble(
    pid = pid,
    file = file,
    field = field,
    queue_source = queue_source,
    excluded_from_analysis = excluded_from_analysis,
    exclusion_reason = exclusion_reason,
    decision_status = decision_status,
    decision_value = decision_value,
    action = action,
    old_type = value_type(old_value),
    new_type = value_type(new_value),
    old_value = value_label(old_value),
    new_value = value_label(new_value),
    old_json = as.character(json_value(old_value)),
    new_json = as.character(json_value(new_value)),
    reason = reason,
    reviewer = reviewer,
    review_date = review_date,
    decision_note = decision_note
  )
}

apply_field_change <- function(obj, decision, override_values) {
  pid <- decision$pid
  field <- decision$field
  file <- decision$file
  old_value <- field_value(obj, field)
  decision_status <- scalar_text(decision$decision_status)
  decision_value <- scalar_text(decision$decision_value)
  excluded_from_analysis <- isTRUE(decision$excluded_from_analysis)
  exclusion_reason <- scalar_text(decision$exclusion_reason)

  if (!field %in% expected_json_fields) {
    stop("Campo fora do schema oficial em decisão manual: ", field)
  }

  if (decision_status == "done" && decision_value == "structured_json_required") {
    override_key <- paste(pid, field, sep = "||")
    if (!override_key %in% names(override_values)) {
      stop("Override estruturado ausente para ", pid, " / ", field)
    }
    new_value <- override_values[[override_key]]
    action <- "apply_structured_override"
    reason <- "Placeholder structured_json_required substituído por override estruturado validado."
  } else if (decision_status == "done") {
    parsed_value <- parse_decision_value(field, decision_value)
    if (is_schema_padding_needed(field, parsed_value, excluded_from_analysis)) {
      new_value <- schema_padding_value(field, exclusion_reason)
      action <- "schema_padding_for_excluded_record"
      reason <- paste0(
        "Decisão manual marcou <NULL> para registro excluído da análise; ",
        "valor schema-válido usado apenas para manter validação do corpus preservado."
      )
    } else {
      new_value <- parsed_value
      action <- "apply_manual_decision"
      reason <- "Decisão manual validada aplicada ao JSON final."
    }
  } else if (excluded_from_analysis && field %in% nullable_fields) {
    new_value <- NULL
    action <- "excluded_pending_set_null"
    reason <- "Pendência dispensada por exclusão; campo nullable mantido como JSON null."
  } else if (excluded_from_analysis && field %in% required_not_null_fields) {
    new_value <- schema_padding_value(field, exclusion_reason)
    action <- "schema_padding_for_excluded_record"
    reason <- paste0(
      "Pendência dispensada por exclusão em campo obrigatório; ",
      "valor schema-válido usado apenas para manter validação do corpus preservado."
    )
  } else {
    stop("Decisão pendente em registro não excluído: ", pid, " / ", field)
  }

  obj <- set_field(obj, field, new_value)
  add_log(
    pid = pid,
    file = file,
    field = field,
    queue_source = scalar_text(decision$queue_source),
    excluded_from_analysis = excluded_from_analysis,
    exclusion_reason = exclusion_reason,
    decision_status = decision_status,
    decision_value = decision_value,
    action = action,
    old_value = old_value,
    new_value = new_value,
    reason = reason,
    reviewer = scalar_text(decision$reviewer),
    review_date = scalar_text(decision$review_date),
    decision_note = scalar_text(decision$decision_note)
  )
  obj
}

write_classifications_csv <- function(objects, output_path, pids = NULL) {
  selected_objects <- objects
  if (!is.null(pids)) {
    selected_objects <- selected_objects[names(selected_objects) %in% pids]
  }
  rows <- purrr::map_dfr(selected_objects, function(obj) {
    tibble::as_tibble(setNames(
      lapply(expected_json_fields, function(field) csv_value(field_value(obj, field))),
      expected_json_fields
    ))
  })
  readr::write_csv(rows, output_path, na = "")
  rows
}

run_validator <- function(label, dir, csv, issues, summary) {
  env <- c(
    paste0("VALIDATION_LABEL=", label),
    paste0("CLASSIFICATIONS_DIR=", dir),
    paste0("CLASSIFICATIONS_CSV=", csv),
    paste0("VALIDATION_ISSUES=", issues),
    paste0("VALIDATION_SUMMARY=", summary)
  )
  old_wd <- getwd()
  setwd(project_dir)
  on.exit(setwd(old_wd), add = TRUE)
  validator_script <- file.path(project_dir, "scripts", "05_validate_classifications.R")
  output <- tryCatch(
    system2(
      "Rscript",
      c("--vanilla", validator_script),
      env = env,
      stdout = TRUE,
      stderr = TRUE
    ),
    error = function(e) {
      stop("Falha ao executar validador: ", conditionMessage(e), call. = FALSE)
    }
  )
  status <- attr(output, "status") %||% 0
  if (!identical(status, 0)) {
    stop(
      "Validador retornou status ", status, " para ", label, ". Saída:\n",
      paste(output, collapse = "\n"),
      call. = FALSE
    )
  }
  invisible(status)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

read_issues_or_empty <- function(path) {
  if (!file.exists(path)) {
    return(tibble(
      scope = character(),
      file = character(),
      pid = character(),
      rule = character(),
      severity = character(),
      value = character(),
      expected = character(),
      detail = character()
    ))
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

decisions <- read_csv_utf8(paths$manual_decisions) |>
  dplyr::mutate(
    decision_status = stringr::str_trim(decision_status),
    decision_value = dplyr::if_else(is.na(decision_value), "", stringr::str_trim(decision_value)),
    excluded_from_analysis = dplyr::coalesce(excluded_from_analysis, FALSE),
    pending_blocks_main_analysis = dplyr::coalesce(pending_blocks_main_analysis, FALSE),
    strict_codebook_issue = dplyr::coalesce(strict_codebook_issue, FALSE),
    requires_substantive_json = dplyr::coalesce(requires_substantive_json, FALSE)
  )

blocking_decisions <- decisions |>
  dplyr::filter(
    pending_blocks_main_analysis |
      strict_codebook_issue |
      requires_substantive_json
  )
if (nrow(blocking_decisions) > 0) {
  stop(
    "Há decisões manuais bloqueantes. Reexecute scripts/08_validate_manual_review_decisions.R ",
    "e corrija antes de aplicar."
  )
}

duplicate_decisions <- decisions |>
  dplyr::count(pid, field, file, issue_rule, action, name = "n") |>
  dplyr::filter(n > 1)
if (nrow(duplicate_decisions) > 0) {
  stop("Há chaves de decisão duplicadas em ", paths$manual_decisions)
}

field_decision_groups <- decisions |>
  dplyr::group_by(pid, field, file) |>
  dplyr::summarise(
    n_rows = dplyr::n(),
    n_target_values = dplyr::n_distinct(
      decision_status,
      decision_value,
      excluded_from_analysis,
      exclusion_reason
    ),
    .groups = "drop"
  )

field_decision_conflicts <- field_decision_groups |>
  dplyr::filter(n_rows > 1, n_target_values > 1)
if (nrow(field_decision_conflicts) > 0) {
  stop(
    "Há decisões conflitantes por pid + field em ",
    paths$manual_decisions,
    ". Revise antes de aplicar."
  )
}

idempotent_field_decision_groups <- field_decision_groups |>
  dplyr::filter(n_rows > 1, n_target_values == 1)

overrides_raw <- jsonlite::fromJSON(paths$relationship_overrides, simplifyVector = FALSE)
override_values <- list()
for (item in overrides_raw) {
  override_key <- paste(scalar_text(item$pid), scalar_text(item$field), sep = "||")
  override_values[[override_key]] <- item$value
}

source_files <- list.files(paths$source_dir, pattern = "[.]json$", full.names = TRUE)
if (length(source_files) == 0) {
  stop("Nenhum JSON encontrado em ", paths$source_dir)
}

objects <- list()
for (json_file in sort(source_files)) {
  pid <- tools::file_path_sans_ext(basename(json_file))
  obj <- jsonlite::fromJSON(json_file, simplifyVector = FALSE)
  file_decisions <- decisions |>
    dplyr::filter(pid == !!pid) |>
    dplyr::arrange(field, issue_rule, action)

  if (nrow(file_decisions) > 0) {
    for (row_index in seq_len(nrow(file_decisions))) {
      obj <- apply_field_change(obj, file_decisions[row_index, ], override_values)
    }
  }

  obj <- obj[expected_json_fields]
  objects[[pid]] <- obj
  writeLines(
    jsonlite::toJSON(obj, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"),
    file.path(paths$final_dir, basename(json_file)),
    useBytes = TRUE
  )
}

stale_final_files <- setdiff(
  list.files(paths$final_dir, pattern = "[.]json$", full.names = FALSE),
  basename(source_files)
)
if (length(stale_final_files) > 0) {
  stop(
    "Arquivos JSON finais sem correspondente normalizado: ",
    paste(stale_final_files, collapse = "; ")
  )
}

if (file.exists(paths$final_csv) && !file.exists(paths$pre_manual_snapshot)) {
  copied <- file.copy(paths$final_csv, paths$pre_manual_snapshot, overwrite = FALSE)
  if (!copied) {
    stop("Não foi possível preservar snapshot pré-revisão em ", paths$pre_manual_snapshot)
  }
}

application_log <- if (length(log_rows) == 0L) {
  tibble(
    pid = character(),
    file = character(),
    field = character(),
    queue_source = character(),
    excluded_from_analysis = logical(),
    exclusion_reason = character(),
    decision_status = character(),
    decision_value = character(),
    action = character(),
    old_type = character(),
    new_type = character(),
    old_value = character(),
    new_value = character(),
    old_json = character(),
    new_json = character(),
    reason = character(),
    reviewer = character(),
    review_date = character(),
    decision_note = character()
  )
} else {
  dplyr::bind_rows(log_rows)
}
readr::write_csv(application_log, paths$application_log, na = "")

all_rows <- write_classifications_csv(objects, paths$final_csv)

sample <- read_csv_utf8(paths$sample)
excluded_journals <- read_csv_utf8(paths$excluded_journals) |>
  dplyr::filter(exclude_from_analysis) |>
  dplyr::select(journal_title, issn, journal_exclusion_reason = exclusion_reason)
excluded_articles <- read_csv_utf8(paths$excluded_articles) |>
  dplyr::filter(exclude_from_analysis) |>
  dplyr::select(pid, article_exclusion_reason = exclusion_reason)

sample_exclusion_flags <- sample |>
  dplyr::select(pid, journal_title, issn) |>
  dplyr::left_join(excluded_journals, by = c("journal_title", "issn")) |>
  dplyr::left_join(excluded_articles, by = "pid") |>
  dplyr::mutate(
    excluded_by_journal = !is.na(journal_exclusion_reason),
    excluded_by_article = !is.na(article_exclusion_reason),
    excluded_from_analysis = excluded_by_journal | excluded_by_article
  )

main_analysis_pids <- sample_exclusion_flags |>
  dplyr::filter(!excluded_from_analysis) |>
  dplyr::pull(pid)
main_rows <- write_classifications_csv(objects, paths$final_main_csv, pids = main_analysis_pids)

invisible(run_validator(
  "Classificacoes_Finais_Pos_Revisao_Manual",
  paths$final_dir,
  paths$final_csv,
  paths$validation_issues,
  paths$validation_summary
))

final_issues <- read_issues_or_empty(paths$validation_issues)
final_errors <- final_issues |>
  dplyr::filter(severity == "ERROR")
if (nrow(final_errors) > 0) {
  stop(
    "Validação final falhou: ", nrow(final_errors),
    " erro(s) em ", relative_path(paths$validation_issues)
  )
}

action_counts <- application_log |>
  dplyr::count(action, queue_source, excluded_from_analysis, name = "n") |>
  dplyr::arrange(dplyr::desc(n), action, queue_source)

field_counts <- application_log |>
  dplyr::count(field, action, name = "n") |>
  dplyr::arrange(field, action)

exclusion_counts <- sample_exclusion_flags |>
  dplyr::count(excluded_by_journal, excluded_by_article, excluded_from_analysis, name = "n") |>
  dplyr::arrange(excluded_from_analysis, excluded_by_journal, excluded_by_article)

validation_counts <- final_issues |>
  dplyr::count(severity, name = "n") |>
  dplyr::arrange(dplyr::desc(n))

snapshot <- tibble(
  item = c(
    "JSONs normalizados de entrada",
    "JSONs finais",
    "linhas no CSV final canônico",
    "linhas no CSV elegível da amostra",
    "decisões/pendências processadas",
    "decisões manuais aplicadas",
    "overrides estruturados aplicados",
    "pendências excluídas convertidas em null",
    "schema padding em registros excluídos",
    "grupos pid+field duplicados idempotentes",
    "erros na validação final",
    "avisos na validação final"
  ),
  value = c(
    length(source_files),
    length(list.files(paths$final_dir, pattern = "[.]json$")),
    nrow(all_rows),
    nrow(main_rows),
    nrow(application_log),
    sum(application_log$action == "apply_manual_decision", na.rm = TRUE),
    sum(application_log$action == "apply_structured_override", na.rm = TRUE),
    sum(application_log$action == "excluded_pending_set_null", na.rm = TRUE),
    sum(application_log$action == "schema_padding_for_excluded_record", na.rm = TRUE),
    nrow(idempotent_field_decision_groups),
    sum(final_issues$severity == "ERROR", na.rm = TRUE),
    sum(final_issues$severity == "WARN", na.rm = TRUE)
  )
)

summary_lines <- c(
  "# Aplicação das Decisões Manuais",
  "",
  "Gerado por `scripts/09_apply_manual_review_decisions.R`.",
  "",
  "## Status",
  "",
  "Dataset final validado: `scripts/05_validate_classifications.R` registrou zero `ERROR` no resultado final.",
  "",
  "`data/processed/classifications_llm.csv` agora é o CSV canônico pós-revisão manual, gerado a partir de `data/processed/classifications_normalized/`, `quality_reports/manual_review_decisions_validated.csv` e `data/processed/manual_review_relationship_overrides.json`.",
  "",
  paste0(
    "O snapshot pré-aplicação foi preservado em `",
    relative_path(paths$pre_manual_snapshot),
    "` quando o CSV canônico foi sobrescrito."
  ),
  "",
  "## Regra Operacional de Exclusões",
  "",
  "- `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` ficam fora da análise principal por regra documentada em `data/processed/excluded_journals.csv`.",
  "- Os artigos listados em `data/processed/excluded_articles.csv` ficam fora da análise principal por regra documentada no próprio ledger.",
  "- Registros excluídos são preservados no corpus e nos JSONs/CSV finais para rastreabilidade.",
  "- `data/processed/classifications_llm_main_analysis.csv` contém apenas a amostra classificada elegível pós-exclusões; use esse arquivo para validação, auditoria e desenvolvimento do pipeline, não como base final de análise substantiva.",
  "- Quando a decisão manual de um registro excluído era `<NULL>` em campo obrigatório do schema rígido, o script aplicou `schema_padding_for_excluded_record`; esses valores existem apenas para manter o registro preservado e schema-válido, não para inclusão analítica.",
  "",
  "## Snapshot",
  "",
  markdown_table(snapshot),
  "",
  "## Ações Aplicadas",
  "",
  markdown_table(action_counts),
  "",
  "## Campos Alterados",
  "",
  markdown_table(field_counts, max_rows = 50),
  "",
  "## Exclusões na Amostra de Classificação",
  "",
  markdown_table(exclusion_counts),
  "",
  "## Validação Final",
  "",
  markdown_table(validation_counts),
  "",
  "## Arquivos Gerados",
  "",
  paste0("- `", relative_path(paths$final_dir), "`"),
  paste0("- `", relative_path(paths$final_csv), "`"),
  paste0("- `", relative_path(paths$final_main_csv), "`"),
  paste0("- `", relative_path(paths$pre_manual_snapshot), "`"),
  paste0("- `", relative_path(paths$application_log), "`"),
  paste0("- `", relative_path(paths$application_summary), "`"),
  paste0("- `", relative_path(paths$validation_issues), "`"),
  paste0("- `", relative_path(paths$validation_summary), "`")
)

writeLines(summary_lines, paths$application_summary, useBytes = TRUE)

cat("Aplicação das decisões manuais concluída.\n")
cat("JSONs finais:", length(objects), "\n")
cat("Linhas no CSV final:", nrow(all_rows), "\n")
cat("Linhas elegíveis na amostra:", nrow(main_rows), "\n")
cat("Erros na validação final:", sum(final_issues$severity == "ERROR", na.rm = TRUE), "\n")
cat("Avisos na validação final:", sum(final_issues$severity == "WARN", na.rm = TRUE), "\n")
cat("Resumo:", relative_path(paths$application_summary), "\n")
