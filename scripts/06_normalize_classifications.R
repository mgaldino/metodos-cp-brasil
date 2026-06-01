## 06_normalize_classifications.R
## Normalização controlada das classificações LLM.
##
## Este script preserva os JSONs originais em data/processed/classifications/
## e escreve uma versão candidata normalizada em:
## - data/processed/classifications_normalized/
## - data/processed/classifications_llm_normalized.csv
##
## Toda mudança e toda pendência manual são registradas em quality_reports/.

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

paths <- list(
  source_dir = file.path(project_dir, "data", "processed", "classifications"),
  normalized_dir = file.path(project_dir, "data", "processed", "classifications_normalized"),
  normalized_csv = file.path(project_dir, "data", "processed", "classifications_llm_normalized.csv"),
  original_issues = file.path(project_dir, "quality_reports", "classification_validation_issues.csv"),
  normalized_issues = file.path(project_dir, "quality_reports", "classification_validation_issues_normalized.csv"),
  normalized_summary = file.path(project_dir, "quality_reports", "classification_validation_summary_normalized.md"),
  normalization_log = file.path(project_dir, "quality_reports", "classification_normalization_log.csv"),
  normalization_summary = file.path(project_dir, "quality_reports", "classification_normalization_summary.md"),
  reconciliation = file.path(project_dir, "quality_reports", "classification_normalization_reconciliation.csv")
)

dir.create(paths$normalized_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(paths$normalization_log), showWarnings = FALSE, recursive = TRUE)

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

log_rows <- list()

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

is_false_scalar <- function(x) {
  is.logical(x) && length(x) == 1 && !is.na(x) && !x
}

is_true_scalar <- function(x) {
  is.logical(x) && length(x) == 1 && !is.na(x) && x
}

is_blankish <- function(x) {
  is.character(x) && length(x) == 1 &&
    str_to_lower(str_trim(x)) %in% c("", "na", "n/a", "none", "null")
}

is_string_list <- function(x) {
  is.list(x) &&
    length(x) > 0 &&
    all(vapply(x, function(y) is.character(y) && length(y) == 1, logical(1)))
}

string_list_to_scalar <- function(x) {
  paste(vapply(x, as.character, character(1)), collapse = "; ")
}

countries_count <- function(x) {
  if (is.null(x)) {
    return(0L)
  }
  if (is.character(x) && length(x) == 1) {
    if (!nzchar(str_trim(x))) {
      return(0L)
    }
    return(length(str_split(x, ";|,")[[1]] |> str_trim() |> discard(~ .x == "")))
  }
  if (is_string_list(x)) {
    return(length(x))
  }
  0L
}

field_from_rule <- function(rule, value) {
  if (rule %in% c("missing_field", "extra_field")) {
    return(as.character(value))
  }
  matches <- expected_json_fields[vapply(
    expected_json_fields,
    function(field) startsWith(rule, paste0(field, "_")),
    logical(1)
  )]
  if (length(matches) == 0) {
    return(NA_character_)
  }
  matches[which.max(nchar(matches))]
}

issue_rule_for_invalid <- function(field, suffix = "invalid") {
  paste0(field, "_", suffix)
}

add_log <- function(pid, file, field, action, manual_review, issue_rule,
                    old_value, new_value, reason, confidence) {
  old_label <- value_label(old_value)
  new_label <- value_label(new_value)
  old_json_value <- as.character(json_value(old_value))
  new_json_value <- as.character(json_value(new_value))
  log_rows[[length(log_rows) + 1L]] <<- tibble(
    pid = pid,
    file = file,
    field = field,
    action = action,
    manual_review = manual_review,
    issue_rule = issue_rule,
    old_type = value_type(old_value),
    new_type = value_type(new_value),
    old_value = old_label,
    new_value = new_label,
    old_json = old_json_value,
    new_json = new_json_value,
    reason = reason,
    confidence = confidence
  )
}

change_field <- function(obj, pid, file, field, new_value, action,
                         issue_rule, reason, confidence = "high",
                         manual_review = FALSE) {
  old_value <- field_value(obj, field)
  obj <- set_field(obj, field, new_value)
  add_log(pid, file, field, action, manual_review, issue_rule,
          old_value, new_value, reason, confidence)
  obj
}

manual_issue <- function(pid, file, field, obj, issue_rule, reason,
                         confidence = "none") {
  value <- field_value(obj, field)
  add_log(pid, file, field, "no_change_manual", TRUE, issue_rule,
          value, value, reason, confidence)
  obj
}

normalize_error_in_raw_text <- function(obj, pid, file) {
  field <- "error_in_raw_text"
  x <- field_value(obj, field)
  if (is.null(x)) {
    has_context <- !is.null(field_value(obj, "subfield")) &&
      is.character(field_value(obj, "subfield")) &&
      nzchar(str_trim(field_value(obj, "subfield"))) &&
      !is.null(field_value(obj, "brief_justification")) &&
      is.character(field_value(obj, "brief_justification")) &&
      nzchar(str_trim(field_value(obj, "brief_justification")))
    if (has_context) {
      return(change_field(
        obj, pid, file, field, "No Error", "normalize_null_to_no_error",
        "error_in_raw_text_null",
        "Null raw-text error flag with non-empty subfield and justification.",
        "medium"
      ))
    }
    return(manual_issue(
      pid, file, field, obj, "error_in_raw_text_null",
      "Null raw-text error flag without enough context for safe normalization."
    ))
  }
  if (is_false_scalar(x)) {
    return(change_field(
      obj, pid, file, field, "No Error", "normalize_false_to_no_error",
      "error_in_raw_text_invalid",
      "Legacy logical FALSE denotes no raw-text error.",
      "high"
    ))
  }
  if (is.character(x) && length(x) == 1 && x %in% allowed$error_in_raw_text) {
    return(obj)
  }
  manual_issue(pid, file, field, obj, "error_in_raw_text_invalid",
               "Raw-text error value is not a safe alias.")
}

normalize_general_goal <- function(obj, pid, file) {
  field <- "general_goal_of_analysis"
  x <- field_value(obj, field)
  if (is.null(x) || (is.character(x) && length(x) == 1 && x %in% allowed$general_goal_of_analysis)) {
    return(obj)
  }
  if (is_blankish(x)) {
    return(change_field(obj, pid, file, field, NULL, "blank_to_null",
                        "general_goal_of_analysis_invalid",
                        "Blank/NA-like value in nullable field.", "high"))
  }
  if (is.character(x) && length(x) == 1 && str_to_lower(str_trim(x)) == "descriptive") {
    return(change_field(obj, pid, file, field, "Describe", "normalize_alias",
                        "general_goal_of_analysis_invalid",
                        "Exact descriptive alias normalized to Describe.", "high"))
  }
  change_field(obj, pid, file, field, NULL, "text_to_null_manual",
               "general_goal_of_analysis_invalid",
               "Free-text goal cannot be mapped safely to Describe/Predict/Explain.",
               "none", manual_review = TRUE)
}

normalize_single_country <- function(obj, pid, file) {
  field <- "single_country_study"
  x <- field_value(obj, field)
  if (is.null(x) || (is.character(x) && length(x) == 1 && x %in% allowed$single_country_study)) {
    return(obj)
  }
  if (is_true_scalar(x)) {
    return(change_field(obj, pid, file, field, "single_country", "normalize_true_to_single_country",
                        "single_country_study_invalid",
                        "Legacy logical TRUE is a direct alias for single_country.",
                        "high"))
  }
  if (is_false_scalar(x) && countries_count(field_value(obj, "countries_of_focus")) > 1) {
    return(change_field(obj, pid, file, field, "multiple_countries", "normalize_false_with_multiple_countries",
                        "single_country_study_invalid",
                        "Legacy logical FALSE plus multiple countries indicates multiple_countries.",
                        "medium"))
  }
  manual_issue(pid, file, field, obj, "single_country_study_invalid",
               "Cannot infer single vs multiple countries safely.")
}

normalize_single_region <- function(obj, pid, file) {
  field <- "single_region"
  x <- field_value(obj, field)
  if (is.null(x) || (is.character(x) && length(x) == 1 && x %in% allowed$single_region)) {
    return(obj)
  }
  if (is_true_scalar(x)) {
    return(change_field(obj, pid, file, field, "single_region", "normalize_true_to_single_region",
                        "single_region_invalid",
                        "Legacy logical TRUE is a direct alias for single_region.",
                        "high"))
  }
  manual_issue(pid, file, field, obj, "single_region_invalid",
               "Cannot infer regional scope safely from this value.")
}

normalize_countries_of_focus <- function(obj, pid, file) {
  field <- "countries_of_focus"
  x <- field_value(obj, field)
  if (is.null(x) || (is.character(x) && length(x) == 1 && nzchar(str_trim(x)))) {
    return(obj)
  }
  if (is.list(x) && length(x) == 0) {
    return(change_field(obj, pid, file, field, NULL, "empty_list_to_null",
                        "countries_of_focus_invalid_string",
                        "Empty list in nullable country field.", "high"))
  }
  if (is_string_list(x)) {
    return(change_field(obj, pid, file, field, string_list_to_scalar(x),
                        "string_list_to_semicolon_string",
                        "countries_of_focus_invalid_string",
                        "List of country strings flattened with semicolon separator.",
                        "high"))
  }
  if (is_blankish(x)) {
    return(change_field(obj, pid, file, field, NULL, "blank_to_null",
                        "countries_of_focus_invalid_string",
                        "Blank/NA-like value in nullable field.", "high"))
  }
  manual_issue(pid, file, field, obj, "countries_of_focus_invalid_string",
               "Country field is neither scalar string, list of strings, nor null.")
}

normalize_survey_data <- function(obj, pid, file) {
  field <- "paper_uses_survey_data"
  x <- field_value(obj, field)
  if (is.character(x) && length(x) == 1 && x %in% allowed$paper_uses_survey_data) {
    return(obj)
  }
  if (is_false_scalar(x)) {
    return(change_field(obj, pid, file, field, "no_survey_data", "normalize_false_to_no_survey",
                        "paper_uses_survey_data_invalid",
                        "Legacy logical FALSE is a direct alias for no_survey_data.",
                        "high"))
  }
  manual_issue(pid, file, field, obj,
               if (is.null(x)) "paper_uses_survey_data_null" else "paper_uses_survey_data_invalid",
               "Cannot infer original/public survey category safely.")
}

normalize_original_dataset <- function(obj, pid, file) {
  field <- "uses_original_dataset"
  x <- field_value(obj, field)
  if (is.null(x) || (is.character(x) && length(x) == 1 && x %in% allowed$uses_original_dataset)) {
    return(obj)
  }
  if (is_false_scalar(x)) {
    return(change_field(obj, pid, file, field, "not_original", "normalize_false_to_not_original",
                        "uses_original_dataset_invalid",
                        "Legacy logical FALSE is a direct alias for not_original.",
                        "high"))
  }
  manual_issue(pid, file, field, obj, "uses_original_dataset_invalid",
               "Original-data category cannot be inferred safely.")
}

normalize_causal_design <- function(obj, pid, file) {
  field <- "main_causal_research_design"
  x <- field_value(obj, field)
  if (is.null(x) || (is.character(x) && length(x) == 1 && x %in% allowed$main_causal_research_design)) {
    return(obj)
  }
  if (is_blankish(x)) {
    return(change_field(obj, pid, file, field, NULL, "blank_to_null",
                        "main_causal_research_design_invalid",
                        "None/NA-like value in nullable causal-design field.", "high"))
  }
  if (is.character(x) && length(x) == 1 && str_to_lower(str_trim(x)) == "instrumental variables") {
    return(change_field(obj, pid, file, field, "Instrumental Variable", "normalize_alias",
                        "main_causal_research_design_invalid",
                        "Exact plural alias normalized to schema category.",
                        "high"))
  }
  manual_issue(pid, file, field, obj, "main_causal_research_design_invalid",
               "Causal design is not a safe schema alias.")
}

normalize_causal_quantity <- function(obj, pid, file) {
  field <- "clear_causal_quantity_of_interest"
  x <- field_value(obj, field)
  if (is.null(x) || (is.character(x) && length(x) == 1 && x %in% allowed$clear_causal_quantity_of_interest)) {
    return(obj)
  }
  if (is_false_scalar(x)) {
    return(change_field(obj, pid, file, field, "FALSE", "normalize_false_to_false_category",
                        "clear_causal_quantity_of_interest_invalid",
                        "Legacy logical FALSE is a direct alias for schema category FALSE.",
                        "high"))
  }
  if (is_blankish(x)) {
    return(change_field(obj, pid, file, field, NULL, "blank_to_null",
                        "clear_causal_quantity_of_interest_invalid",
                        "Blank/NA-like value in nullable causal-quantity field.",
                        "high"))
  }
  manual_issue(pid, file, field, obj, "clear_causal_quantity_of_interest_invalid",
               "Cannot infer causal estimand safely.")
}

normalize_mechanisms <- function(obj, pid, file) {
  field <- "effort_to_explore_mechanisms"
  x <- field_value(obj, field)
  if (is.null(x) || (is.character(x) && length(x) == 1 && x %in% allowed$effort_to_explore_mechanisms)) {
    return(obj)
  }
  if (is_blankish(x)) {
    return(change_field(obj, pid, file, field, NULL, "blank_to_null",
                        "effort_to_explore_mechanisms_invalid",
                        "Blank/NA-like value in nullable mechanisms field.", "high"))
  }
  manual_issue(pid, file, field, obj, "effort_to_explore_mechanisms_invalid",
               "Mechanism-exploration level cannot be inferred safely from a logical value.")
}

normalize_evidence_type <- function(obj, pid, file) {
  field <- "evidence_type"
  x <- field_value(obj, field)
  if (is.character(x) && length(x) == 1 && x %in% allowed$evidence_type) {
    return(obj)
  }
  if (is.character(x) && length(x) == 1) {
    alias <- str_to_lower(str_trim(x))
    if (alias == "qualitative") {
      return(change_field(obj, pid, file, field, "qualitative", "normalize_alias",
                          "evidence_type_invalid",
                          "Capitalization-only qualitative alias.", "high"))
    }
    if (alias %in% c("theoretical", "theoretical/normative", "theoretical-normative", "theoretical/ normative")) {
      return(change_field(obj, pid, file, field, "theoretical-normative", "normalize_alias",
                          "evidence_type_invalid",
                          "Obvious theoretical-normative alias.", "high"))
    }
  }
  manual_issue(pid, file, field, obj,
               if (is.null(x)) "evidence_type_null" else "evidence_type_invalid",
               "Evidence type cannot be mapped safely.")
}

normalize_method_status <- function(obj, pid, file) {
  field <- "method_status"
  x <- field_value(obj, field)
  if (is.character(x) && length(x) == 1 && x %in% allowed$method_status) {
    return(obj)
  }
  if (is_blankish(x)) {
    return(manual_issue(pid, file, field, obj, "method_status_invalid",
                        "Method-status blank/NA-like value requires review."))
  }
  manual_issue(pid, file, field, obj,
               if (is.null(x)) "method_status_null" else "method_status_invalid",
               "Method status is not a safe alias of explicit/essayistic.")
}

normalize_list_field <- function(obj, pid, file, field) {
  x <- field_value(obj, field)
  if (is.null(x) || is.list(x)) {
    return(obj)
  }
  suffix <- if (field %in% c("independent_variables", "dependent_variables", "main_variable_relationship")) {
    "not_array_or_null"
  } else {
    "invalid"
  }
  rule <- paste0(field, "_", suffix)
  if (is_blankish(x)) {
    return(change_field(obj, pid, file, field, NULL, "blank_to_null",
                        rule, "NA-like value in nullable list field.", "high"))
  }
  manual_issue(pid, file, field, obj, rule,
               "Free-text value cannot be transformed safely into a structured array.")
}

normalize_sample_size <- function(obj, pid, file) {
  field <- "sample_size"
  x <- field_value(obj, field)
  if (is.null(x) || (is.numeric(x) && length(x) == 1 && !is.na(x) && x == as.integer(x) && x >= 0)) {
    return(obj)
  }
  if (is_blankish(x)) {
    return(change_field(obj, pid, file, field, NULL, "blank_to_null",
                        "sample_size_not_nonnegative_integer",
                        "NA-like sample size in nullable field.", "high"))
  }
  manual_issue(pid, file, field, obj, "sample_size_not_nonnegative_integer",
               "Sample size is not a safe non-negative integer.")
}

normalize_blank_nullable_string <- function(obj, pid, file, field, issue_rule) {
  x <- field_value(obj, field)
  if (is_blankish(x)) {
    return(change_field(obj, pid, file, field, NULL, "blank_to_null",
                        issue_rule, "Blank/NA-like value in nullable string field.", "high"))
  }
  obj
}

drop_extra_fields <- function(obj, pid, file) {
  extra_fields <- setdiff(names(obj), expected_json_fields)
  for (field in extra_fields) {
    old_value <- obj[[field]]
    obj[[field]] <- NULL
    add_log(pid, file, field, "drop_extra_field", FALSE, "extra_field",
            old_value, NULL, "Field is outside official classification schema.", "high")
  }
  obj
}

add_missing_fields <- function(obj, pid, file) {
  missing_fields <- setdiff(expected_json_fields, names(obj))
  for (field in missing_fields) {
    issue_rule <- if (field %in% required_not_null_fields) {
      paste0(field, "_null")
    } else {
      "missing_field"
    }
    manual <- field %in% required_not_null_fields
    obj <- set_field(obj, field, NULL)
    add_log(pid, file, field, "add_missing_null", manual, issue_rule,
            NULL, NULL, "Missing official-schema field added as JSON null.",
            if (manual) "none" else "high")
  }
  obj
}

normalize_one <- function(json_file) {
  file <- basename(json_file)
  pid <- tools::file_path_sans_ext(file)
  obj <- jsonlite::fromJSON(json_file, simplifyVector = FALSE)

  if (!"pid" %in% names(obj) || is.null(obj$pid) || !identical(as.character(obj$pid), pid)) {
    old_pid <- field_value(obj, "pid")
    obj <- set_field(obj, "pid", pid)
    add_log(pid, file, "pid", "normalize_pid_from_filename", FALSE, "pid_filename_mismatch",
            old_pid, pid, "Filename is the authoritative classification identifier.", "high")
  }

  obj <- drop_extra_fields(obj, pid, file)
  obj <- add_missing_fields(obj, pid, file)

  obj <- normalize_countries_of_focus(obj, pid, file)
  obj <- normalize_error_in_raw_text(obj, pid, file)
  obj <- normalize_general_goal(obj, pid, file)
  obj <- normalize_single_country(obj, pid, file)
  obj <- normalize_single_region(obj, pid, file)
  obj <- normalize_survey_data(obj, pid, file)
  obj <- normalize_original_dataset(obj, pid, file)
  obj <- normalize_causal_design(obj, pid, file)
  obj <- normalize_causal_quantity(obj, pid, file)
  obj <- normalize_mechanisms(obj, pid, file)
  obj <- normalize_evidence_type(obj, pid, file)
  obj <- normalize_method_status(obj, pid, file)
  obj <- normalize_sample_size(obj, pid, file)

  for (field in c("independent_variables", "dependent_variables", "main_variable_relationship")) {
    obj <- normalize_list_field(obj, pid, file, field)
  }

  nullable_string_rules <- c(
    other_research_design = "other_research_design_invalid_string",
    instrumental_variable_instrument = "instrumental_variable_instrument_invalid_string",
    sample_size_quote = "sample_size_quote_invalid_string",
    statement_of_identification_assumptions_quote = "statement_of_identification_assumptions_quote_invalid_string"
  )
  for (field in names(nullable_string_rules)) {
    obj <- normalize_blank_nullable_string(obj, pid, file, field, nullable_string_rules[[field]])
  }

  obj <- obj[expected_json_fields]
  out_file <- file.path(paths$normalized_dir, file)
  writeLines(
    jsonlite::toJSON(obj, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"),
    out_file,
    useBytes = TRUE
  )
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

write_normalized_csv <- function(objects) {
  rows <- purrr::map_dfr(objects, function(obj) {
    tibble::as_tibble(setNames(
      lapply(expected_json_fields, function(field) csv_value(field_value(obj, field))),
      expected_json_fields
    ))
  })
  readr::write_csv(rows, paths$normalized_csv, na = "")
}

run_validator <- function(label, dir, csv, issues, summary) {
  env <- c(
    paste0("VALIDATION_LABEL=", label),
    paste0("CLASSIFICATIONS_DIR=", dir),
    paste0("CLASSIFICATIONS_CSV=", csv),
    paste0("VALIDATION_ISSUES=", issues),
    paste0("VALIDATION_SUMMARY=", summary)
  )
  output <- tryCatch(
    system2(
      "Rscript",
      c("--vanilla", "scripts/05_validate_classifications.R"),
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
  if (!file.exists(issues) || !file.exists(summary)) {
    stop(
      "Validador não gerou os arquivos esperados para ", label, ": ",
      issues, " / ", summary,
      call. = FALSE
    )
  }
  invisible(status)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
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

json_files <- list.files(paths$source_dir, pattern = "[.]json$", full.names = TRUE)
if (length(json_files) == 0) {
  stop("Nenhum JSON encontrado em ", paths$source_dir)
}

# Garante uma validação original atualizada antes da reconciliação.
invisible(run_validator(
  "Classificacoes_Originais",
  paths$source_dir,
  file.path(project_dir, "data", "processed", "classifications_llm.csv"),
  paths$original_issues,
  file.path(project_dir, "quality_reports", "classification_validation_summary.md")
))

normalized_objects <- purrr::map(sort(json_files), normalize_one)
write_normalized_csv(normalized_objects)

normalization_log <- if (length(log_rows) == 0L) {
  tibble(
    pid = character(),
    file = character(),
    field = character(),
    action = character(),
    manual_review = logical(),
    issue_rule = character(),
    old_type = character(),
    new_type = character(),
    old_value = character(),
    new_value = character(),
    old_json = character(),
    new_json = character(),
    reason = character(),
    confidence = character()
  )
} else {
  dplyr::bind_rows(log_rows)
}
readr::write_csv(normalization_log, paths$normalization_log, na = "")

invisible(run_validator(
  "Classificacoes_Normalizadas_Candidatas",
  paths$normalized_dir,
  paths$normalized_csv,
  paths$normalized_issues,
  paths$normalized_summary
))

original_issues <- read_issues_or_empty(paths$original_issues)
normalized_issues <- read_issues_or_empty(paths$normalized_issues)

original_errors <- original_issues |>
  dplyr::filter(severity == "ERROR", scope %in% c("classification_json", "classifications_csv")) |>
  dplyr::mutate(field = purrr::map2_chr(rule, value, field_from_rule))

normalized_errors <- normalized_issues |>
  dplyr::filter(severity == "ERROR", scope %in% c("classification_json", "classifications_csv")) |>
  dplyr::mutate(field = purrr::map2_chr(rule, value, field_from_rule))

manual_log <- normalization_log |>
  dplyr::filter(manual_review) |>
  dplyr::select(pid, field, issue_rule, action, reason, confidence)

manual_keys <- manual_log |>
  dplyr::distinct(pid, field)

normalized_unexpected <- normalized_errors |>
  dplyr::anti_join(manual_keys, by = c("pid", "field"))

original_reconciliation <- original_errors |>
  dplyr::left_join(manual_keys |> dplyr::mutate(has_manual_review = TRUE),
                   by = c("pid", "field")) |>
  dplyr::left_join(
    normalized_errors |>
      dplyr::distinct(pid, field) |>
      dplyr::mutate(still_validation_error = TRUE),
    by = c("pid", "field")
  ) |>
  dplyr::mutate(
    has_manual_review = if_else(is.na(has_manual_review), FALSE, has_manual_review),
    still_validation_error = if_else(is.na(still_validation_error), FALSE, still_validation_error),
    reconciliation_status = dplyr::case_when(
      has_manual_review ~ "remaining_manual_review",
      !still_validation_error ~ "resolved_by_normalization",
      TRUE ~ "unexpected_unresolved_errors"
    )
  ) |>
  dplyr::select(scope, file, pid, field, rule, severity, value, expected, detail,
                reconciliation_status)

additional_unexpected <- normalized_unexpected |>
  dplyr::anti_join(original_reconciliation |> dplyr::select(pid, field),
                   by = c("pid", "field")) |>
  dplyr::mutate(reconciliation_status = "unexpected_unresolved_errors") |>
  dplyr::select(scope, file, pid, field, rule, severity, value, expected, detail,
                reconciliation_status)

reconciliation <- dplyr::bind_rows(original_reconciliation, additional_unexpected)
readr::write_csv(reconciliation, paths$reconciliation, na = "")

action_counts <- normalization_log |>
  dplyr::count(action, manual_review, confidence, name = "n") |>
  dplyr::arrange(dplyr::desc(n), action)

reconciliation_counts <- reconciliation |>
  dplyr::count(reconciliation_status, name = "n") |>
  dplyr::arrange(dplyr::desc(n))

validation_counts <- tibble(
  item = c(
    "JSONs originais",
    "JSONs normalizados",
    "linhas no CSV normalizado",
    "erros originais de classificação",
    "erros normalizados de classificação",
    "unexpected_unresolved_errors",
    "pendências manuais registradas no log"
  ),
  value = c(
    length(json_files),
    length(list.files(paths$normalized_dir, pattern = "[.]json$")),
    nrow(readr::read_csv(paths$normalized_csv, show_col_types = FALSE, progress = FALSE)),
    nrow(original_errors),
    nrow(normalized_errors),
    nrow(normalized_unexpected),
    sum(normalization_log$manual_review)
  )
)

summary_lines <- c(
  "# Normalização das Classificações",
  "",
  paste("Gerado em", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Status",
  "",
  if (nrow(normalized_unexpected) == 0) {
    "Critério operacional atendido: `unexpected_unresolved_errors == 0`."
  } else {
    "Critério operacional NÃO atendido: há erros inesperados não reconciliados."
  },
  "",
  "`data/processed/classifications_llm_normalized.csv` é um candidato normalizado. Casos com `manual_review=TRUE` no log ainda exigem decisão substantiva antes de análises finais.",
  "",
  "## Snapshot",
  "",
  markdown_table(validation_counts),
  "",
  "## Ações de Normalização",
  "",
  markdown_table(action_counts),
  "",
  "## Reconciliação",
  "",
  markdown_table(reconciliation_counts),
  "",
  "## Arquivos Gerados",
  "",
  paste0("- `", paths$normalized_dir, "`"),
  paste0("- `", paths$normalized_csv, "`"),
  paste0("- `", paths$normalization_log, "`"),
  paste0("- `", paths$reconciliation, "`"),
  paste0("- `", paths$normalized_issues, "`"),
  paste0("- `", paths$normalized_summary, "`")
)

writeLines(summary_lines, paths$normalization_summary, useBytes = TRUE)

cat("Normalização concluída.\n")
cat("JSONs:", length(json_files), "\n")
cat("Mudanças/log rows:", nrow(normalization_log), "\n")
cat("Manual review:", sum(normalization_log$manual_review), "\n")
cat("Unexpected unresolved errors:", nrow(normalized_unexpected), "\n")
cat("Resumo:", paths$normalization_summary, "\n")
