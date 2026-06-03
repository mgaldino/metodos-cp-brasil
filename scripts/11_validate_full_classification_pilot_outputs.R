## 11_validate_full_classification_pilot_outputs.R
## Valida JSONs dos tres subagentes e consolida uma base CSV por agente.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
})

project_dir <- normalizePath(".", mustWork = TRUE)
pilot_dir <- file.path(project_dir, "data", "processed", "full_classification_pilot")

paths <- list(
  manifest = file.path(pilot_dir, "pilot_manifest.csv"),
  issues = file.path(project_dir, "quality_reports", "full_classification_pilot_validation_issues.csv"),
  summary = file.path(project_dir, "quality_reports", "full_classification_pilot_validation_summary.md")
)

dir.create(dirname(paths$issues), showWarnings = FALSE, recursive = TRUE)

agents <- tibble(
  agent_id = c("agent_a", "agent_b", "agent_c"),
  prompt_version = c(
    "agent_a_v1+common_schema_v1",
    "agent_b_v1+common_schema_v1",
    "agent_c_v1+common_schema_v1"
  )
)

expected_classification_fields <- c(
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
  paper_uses_survey_data = c("no_survey_data", "runs_original_survey", "uses_public_available_survey"),
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

issue_rows <- list()
consolidated_rows <- list()

add_issue <- function(agent_id, pid, file = NA_character_, field = NA_character_,
                      rule, severity = "ERROR", value = NA_character_,
                      expected = NA_character_, detail = NA_character_) {
  issue_rows[[length(issue_rows) + 1L]] <<- tibble(
    agent_id = agent_id,
    pid = pid,
    file = file,
    field = field,
    rule = rule,
    severity = severity,
    value = as.character(value),
    expected = as.character(expected),
    detail = as.character(detail)
  )
}

json_value <- function(x) {
  as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null"))
}

value_label <- function(x) {
  if (is.null(x)) {
    return("<NULL>")
  }
  if (length(x) == 0) {
    return("<EMPTY>")
  }
  if (is.list(x) && !is.data.frame(x)) {
    out <- json_value(x)
  } else {
    out <- paste(as.character(x), collapse = "; ")
  }
  if (nchar(out) > 250) {
    out <- paste0(substr(out, 1, 247), "...")
  }
  out
}

field_value <- function(obj, field) {
  if (!field %in% names(obj)) {
    return(list(present = FALSE, value = NULL))
  }
  list(present = TRUE, value = obj[[field]])
}

validate_allowed <- function(obj, field, allowed_values, agent_id, pid, file, allow_null = TRUE) {
  fv <- field_value(obj, field)
  if (!fv$present) {
    add_issue(agent_id, pid, file, field, "missing_classification_field", value = field,
              expected = paste(allowed_values, collapse = "; "))
    return(invisible(FALSE))
  }
  x <- fv$value
  if (is.null(x)) {
    if (!allow_null) {
      add_issue(agent_id, pid, file, field, paste0(field, "_null"),
                value = "<NULL>", expected = paste(allowed_values, collapse = "; "))
      return(invisible(FALSE))
    }
    return(invisible(TRUE))
  }
  if (!is.character(x) || length(x) != 1 || !x %in% allowed_values) {
    add_issue(agent_id, pid, file, field, paste0(field, "_invalid"),
              value = value_label(x), expected = paste(allowed_values, collapse = "; "))
    return(invisible(FALSE))
  }
  invisible(TRUE)
}

validate_boolean <- function(obj, field, agent_id, pid, file, allow_null = TRUE) {
  fv <- field_value(obj, field)
  if (!fv$present) {
    add_issue(agent_id, pid, file, field, "missing_classification_field",
              value = field, expected = "true/false/null")
    return(invisible(FALSE))
  }
  x <- fv$value
  if (is.null(x)) {
    if (!allow_null) {
      add_issue(agent_id, pid, file, field, paste0(field, "_null"),
                value = "<NULL>", expected = "true/false")
      return(invisible(FALSE))
    }
    return(invisible(TRUE))
  }
  if (!is.logical(x) || length(x) != 1) {
    add_issue(agent_id, pid, file, field, paste0(field, "_not_boolean"),
              value = value_label(x), expected = if (allow_null) "true/false/null" else "true/false")
    return(invisible(FALSE))
  }
  invisible(TRUE)
}

validate_string_or_null <- function(obj, field, agent_id, pid, file, allow_null = TRUE,
                                    allow_empty = FALSE) {
  fv <- field_value(obj, field)
  if (!fv$present) {
    add_issue(agent_id, pid, file, field, "missing_classification_field",
              value = field, expected = "string/null")
    return(invisible(FALSE))
  }
  x <- fv$value
  if (is.null(x)) {
    if (!allow_null) {
      add_issue(agent_id, pid, file, field, paste0(field, "_null"),
                value = "<NULL>", expected = "non-empty string")
      return(invisible(FALSE))
    }
    return(invisible(TRUE))
  }
  if (!is.character(x) || length(x) != 1 || (!allow_empty && !nzchar(stringr::str_trim(x)))) {
    add_issue(agent_id, pid, file, field, paste0(field, "_invalid_string"),
              value = value_label(x), expected = if (allow_null) "string/null" else "non-empty string")
    return(invisible(FALSE))
  }
  invisible(TRUE)
}

validate_list_or_null <- function(obj, field, agent_id, pid, file) {
  fv <- field_value(obj, field)
  if (!fv$present) {
    add_issue(agent_id, pid, file, field, "missing_classification_field",
              value = field, expected = "array/object or null")
    return(invisible(FALSE))
  }
  x <- fv$value
  if (is.null(x) || is.list(x)) {
    return(invisible(TRUE))
  }
  add_issue(agent_id, pid, file, field, paste0(field, "_not_array_or_null"),
            value = value_label(x), expected = "array/object or null")
  invisible(FALSE)
}

validate_integer_or_null <- function(obj, field, agent_id, pid, file) {
  fv <- field_value(obj, field)
  if (!fv$present) {
    add_issue(agent_id, pid, file, field, "missing_classification_field",
              value = field, expected = "integer/null")
    return(invisible(FALSE))
  }
  x <- fv$value
  if (is.null(x)) {
    return(invisible(TRUE))
  }
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x != as.integer(x) || x < 0) {
    add_issue(agent_id, pid, file, field, paste0(field, "_not_nonnegative_integer"),
              value = value_label(x), expected = "integer >= 0 or null")
    return(invisible(FALSE))
  }
  invisible(TRUE)
}

flatten_classification <- function(envelope, manifest_row) {
  cls <- envelope$classification
  row <- c(
    list(
      pid = envelope$pid,
      agent_id = envelope$agent_id,
      prompt_version = envelope$prompt_version,
      model = envelope$model,
      run_timestamp = envelope$run_timestamp,
      input_text_hash = envelope$input_text_hash,
      source_file = envelope$source_file,
      raw_response_path = if (is.null(envelope$raw_response_path)) NA_character_ else envelope$raw_response_path,
      manifest_title = manifest_row$title,
      manifest_year = manifest_row$year,
      manifest_journal_title = manifest_row$journal_title
    ),
    purrr::map(expected_classification_fields, function(field) {
      if (!field %in% names(cls) || is.null(cls[[field]])) {
        return(NA)
      }
      if (is.list(cls[[field]]) && !is.data.frame(cls[[field]])) {
        return(json_value(cls[[field]]))
      }
      cls[[field]]
    }) |>
      stats::setNames(expected_classification_fields)
  )
  tibble::as_tibble(row)
}

if (!file.exists(paths$manifest)) {
  stop("Manifest ausente. Rode scripts/10_prepare_full_classification_pilot.R primeiro.")
}

manifest <- readr::read_csv(paths$manifest, show_col_types = FALSE, progress = FALSE)

for (agent_idx in seq_len(nrow(agents))) {
  agent_id <- agents$agent_id[[agent_idx]]
  expected_prompt <- agents$prompt_version[[agent_idx]]
  agent_dir <- file.path(pilot_dir, agent_id)
  dir.create(agent_dir, showWarnings = FALSE, recursive = TRUE)

  for (row_idx in seq_len(nrow(manifest))) {
    item <- manifest[row_idx, ]
    pid <- item$pid[[1]]
    json_file <- file.path(agent_dir, paste0(pid, ".json"))
    rel_json_file <- stringr::str_remove(json_file, paste0("^", stringr::fixed(project_dir), "/?"))

    if (!file.exists(json_file)) {
      add_issue(agent_id, pid, rel_json_file, NA_character_, "missing_agent_json",
                value = rel_json_file, expected = "one JSON per manifest pid")
      next
    }

    envelope <- tryCatch(
      jsonlite::fromJSON(json_file, simplifyVector = FALSE),
      error = function(e) e
    )

    if (inherits(envelope, "error")) {
      add_issue(agent_id, pid, rel_json_file, NA_character_, "json_parse_error",
                value = envelope$message, expected = "valid JSON")
      next
    }

    envelope_required <- c(
      "pid", "agent_id", "prompt_version", "model", "run_timestamp",
      "input_text_hash", "source_file", "classification", "raw_response_path"
    )
    missing_envelope <- setdiff(envelope_required, names(envelope))
    purrr::walk(missing_envelope, function(field) {
      add_issue(agent_id, pid, rel_json_file, field, "missing_envelope_field",
                value = field, expected = paste(envelope_required, collapse = "; "))
    })

    extra_envelope <- setdiff(names(envelope), envelope_required)
    purrr::walk(extra_envelope, function(field) {
      add_issue(agent_id, pid, rel_json_file, field, "extra_envelope_field", "WARN",
                value = field, expected = paste(envelope_required, collapse = "; "))
    })

    if (!identical(envelope$pid, pid)) {
      add_issue(agent_id, pid, rel_json_file, "pid", "pid_mismatch",
                value = value_label(envelope$pid), expected = pid)
    }
    if (!identical(envelope$agent_id, agent_id)) {
      add_issue(agent_id, pid, rel_json_file, "agent_id", "agent_id_mismatch",
                value = value_label(envelope$agent_id), expected = agent_id)
    }
    if (!identical(envelope$prompt_version, expected_prompt)) {
      add_issue(agent_id, pid, rel_json_file, "prompt_version", "prompt_version_mismatch",
                value = value_label(envelope$prompt_version), expected = expected_prompt)
    }
    if (!identical(envelope$input_text_hash, item$input_text_hash[[1]])) {
      add_issue(agent_id, pid, rel_json_file, "input_text_hash", "input_text_hash_mismatch",
                value = value_label(envelope$input_text_hash), expected = item$input_text_hash[[1]])
    }
    if (!identical(envelope$source_file, item$source_file[[1]])) {
      add_issue(agent_id, pid, rel_json_file, "source_file", "source_file_mismatch",
                value = value_label(envelope$source_file), expected = item$source_file[[1]])
    }
    if (!"classification" %in% names(envelope) || !is.list(envelope$classification)) {
      add_issue(agent_id, pid, rel_json_file, "classification", "classification_missing_or_not_object",
                value = value_label(envelope$classification), expected = "object")
      next
    }

    cls <- envelope$classification
    extra_fields <- setdiff(names(cls), expected_classification_fields)
    missing_fields <- setdiff(expected_classification_fields, names(cls))
    purrr::walk(extra_fields, function(field) {
      add_issue(agent_id, pid, rel_json_file, field, "extra_classification_field", "WARN",
                value = field, expected = paste(expected_classification_fields, collapse = "; "))
    })
    purrr::walk(missing_fields, function(field) {
      add_issue(agent_id, pid, rel_json_file, field, "missing_classification_field",
                value = field, expected = paste(expected_classification_fields, collapse = "; "))
    })

    validate_allowed(cls, "error_in_raw_text", allowed$error_in_raw_text, agent_id, pid, rel_json_file, allow_null = FALSE)
    validate_allowed(cls, "subfield", allowed$subfield, agent_id, pid, rel_json_file, allow_null = FALSE)
    validate_boolean(cls, "is_empirical_quant_paper", agent_id, pid, rel_json_file, allow_null = FALSE)
    validate_allowed(cls, "general_goal_of_analysis", allowed$general_goal_of_analysis, agent_id, pid, rel_json_file)
    validate_allowed(cls, "single_country_study", allowed$single_country_study, agent_id, pid, rel_json_file)
    validate_allowed(cls, "single_region", allowed$single_region, agent_id, pid, rel_json_file)
    validate_string_or_null(cls, "countries_of_focus", agent_id, pid, rel_json_file)
    validate_allowed(cls, "paper_uses_survey_data", allowed$paper_uses_survey_data, agent_id, pid, rel_json_file, allow_null = FALSE)
    validate_allowed(cls, "uses_original_dataset", allowed$uses_original_dataset, agent_id, pid, rel_json_file)
    validate_boolean(cls, "seeks_determinants", agent_id, pid, rel_json_file)
    validate_allowed(cls, "main_causal_research_design", allowed$main_causal_research_design, agent_id, pid, rel_json_file)
    validate_string_or_null(cls, "other_research_design", agent_id, pid, rel_json_file)
    validate_string_or_null(cls, "instrumental_variable_instrument", agent_id, pid, rel_json_file)
    validate_boolean(cls, "placebo_test", agent_id, pid, rel_json_file)
    validate_list_or_null(cls, "independent_variables", agent_id, pid, rel_json_file)
    validate_list_or_null(cls, "dependent_variables", agent_id, pid, rel_json_file)
    validate_list_or_null(cls, "main_variable_relationship", agent_id, pid, rel_json_file)
    validate_boolean(cls, "makes_explicit_causal_claim", agent_id, pid, rel_json_file)
    validate_boolean(cls, "makes_implicit_causal_claim", agent_id, pid, rel_json_file)
    validate_boolean(cls, "strong_non_causal_causal_qualification", agent_id, pid, rel_json_file)
    validate_integer_or_null(cls, "sample_size", agent_id, pid, rel_json_file)
    validate_string_or_null(cls, "sample_size_quote", agent_id, pid, rel_json_file)
    validate_boolean(cls, "claims_any_statistically_significant_results", agent_id, pid, rel_json_file)
    validate_boolean(cls, "references_power_analysis", agent_id, pid, rel_json_file)
    validate_boolean(cls, "clearly_defined_explanatory_variable", agent_id, pid, rel_json_file)
    validate_allowed(cls, "clear_causal_quantity_of_interest", allowed$clear_causal_quantity_of_interest, agent_id, pid, rel_json_file)
    validate_boolean(cls, "specifies_estimate_equations", agent_id, pid, rel_json_file)
    validate_boolean(cls, "discusses_threats_to_causality", agent_id, pid, rel_json_file)
    validate_string_or_null(cls, "statement_of_identification_assumptions_quote", agent_id, pid, rel_json_file)
    validate_boolean(cls, "statement_of_identification_assumptions", agent_id, pid, rel_json_file)
    validate_allowed(cls, "effort_to_explore_mechanisms", allowed$effort_to_explore_mechanisms, agent_id, pid, rel_json_file)
    validate_boolean(cls, "mentions_pre_registered_design_and_analysis_plan", agent_id, pid, rel_json_file)
    validate_allowed(cls, "evidence_type", allowed$evidence_type, agent_id, pid, rel_json_file, allow_null = FALSE)
    validate_allowed(cls, "method_status", allowed$method_status, agent_id, pid, rel_json_file, allow_null = FALSE)
    validate_string_or_null(cls, "brief_justification", agent_id, pid, rel_json_file, allow_null = FALSE)

    consolidated_rows[[length(consolidated_rows) + 1L]] <- flatten_classification(envelope, item)
  }
}

issues <- if (length(issue_rows) == 0L) {
  tibble(
    agent_id = character(),
    pid = character(),
    file = character(),
    field = character(),
    rule = character(),
    severity = character(),
    value = character(),
    expected = character(),
    detail = character()
  )
} else {
  dplyr::bind_rows(issue_rows)
}

readr::write_csv(issues, paths$issues, na = "")

empty_consolidated <- tibble(
  pid = character(),
  agent_id = character(),
  prompt_version = character(),
  model = character(),
  run_timestamp = character(),
  input_text_hash = character(),
  source_file = character(),
  raw_response_path = character(),
  manifest_title = character(),
  manifest_year = numeric(),
  manifest_journal_title = character()
)
for (field in expected_classification_fields) {
  empty_consolidated[[field]] <- character()
}

consolidated <- if (length(consolidated_rows) == 0L) {
  empty_consolidated
} else {
  dplyr::bind_rows(consolidated_rows)
}

for (agent_id in agents$agent_id) {
  out <- consolidated |>
    dplyr::filter(agent_id == .env$agent_id)
  out_file <- file.path(pilot_dir, paste0(agent_id, "_classifications.csv"))
  readr::write_csv(out, out_file, na = "")
}

markdown_table <- function(df, max_rows = Inf) {
  if (nrow(df) == 0) {
    return("_Nenhum registro._")
  }
  df <- utils::head(df, max_rows)
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- apply(df, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

issue_counts <- issues |>
  dplyr::count(agent_id, severity, name = "n") |>
  tidyr::pivot_wider(names_from = severity, values_from = n, values_fill = 0)
if (!"ERROR" %in% names(issue_counts)) {
  issue_counts$ERROR <- integer(nrow(issue_counts))
}
if (!"WARN" %in% names(issue_counts)) {
  issue_counts$WARN <- integer(nrow(issue_counts))
}

summary_by_agent <- agents |>
  dplyr::left_join(
    consolidated |>
      dplyr::count(agent_id, name = "parsed_jsons"),
    by = "agent_id"
  ) |>
  dplyr::left_join(
    issue_counts,
    by = "agent_id"
  ) |>
  dplyr::mutate(
    parsed_jsons = dplyr::coalesce(parsed_jsons, 0L),
    ERROR = dplyr::coalesce(ERROR, 0L),
    WARN = dplyr::coalesce(WARN, 0L)
  ) |>
  dplyr::select(agent_id, prompt_version, parsed_jsons, ERROR, WARN)

top_rules <- issues |>
  dplyr::count(severity, rule, name = "n") |>
  dplyr::arrange(dplyr::desc(n), severity, rule)

summary_lines <- c(
  "# Validacao dos JSONs do piloto de classificacao tripla",
  "",
  paste("Gerado em", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Snapshot por agente",
  "",
  markdown_table(summary_by_agent),
  "",
  "## Principais issues",
  "",
  markdown_table(top_rules, max_rows = 30),
  "",
  "## Arquivos gerados",
  "",
  paste0("- `", stringr::str_remove(paths$issues, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  "- `data/processed/full_classification_pilot/agent_a_classifications.csv`",
  "- `data/processed/full_classification_pilot/agent_b_classifications.csv`",
  "- `data/processed/full_classification_pilot/agent_c_classifications.csv`"
)

writeLines(summary_lines, paths$summary, useBytes = TRUE)

cat("Validacao concluida.\n")
cat("Issues:", nrow(issues), "\n")
cat("Errors:", sum(issues$severity == "ERROR"), "\n")
cat("Warnings:", sum(issues$severity == "WARN"), "\n")
cat("Relatorio:", paths$summary, "\n")
