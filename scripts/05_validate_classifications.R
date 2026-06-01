## 05_validate_classifications.R
## Valida corpus, amostra e schema das classificações LLM.
##
## Saídas:
## - quality_reports/classification_validation_issues.csv
## - quality_reports/classification_validation_summary.md

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
quality_dir <- file.path(project_dir, "quality_reports")
dir.create(quality_dir, showWarnings = FALSE, recursive = TRUE)

paths <- list(
  corpus = file.path(project_dir, "data", "raw", "articles_2005_2025.csv"),
  sample = file.path(project_dir, "data", "processed", "sample_validation.csv"),
  sample_sheet = file.path(project_dir, "data", "processed", "sample_validation_sheet.csv"),
  classifications_csv = file.path(project_dir, "data", "processed", "classifications_llm.csv"),
  classifications_dir = file.path(project_dir, "data", "processed", "classifications"),
  sample_xml_dir = file.path(project_dir, "data", "processed", "sample_xmls"),
  issues = file.path(quality_dir, "classification_validation_issues.csv"),
  summary = file.path(quality_dir, "classification_validation_summary.md")
)

issue_rows <- list()

add_issue <- function(scope, file = NA_character_, pid = NA_character_,
                      rule, severity = "ERROR", value = NA_character_,
                      expected = NA_character_, detail = NA_character_) {
  issue_rows[[length(issue_rows) + 1L]] <<- tibble(
    scope = scope,
    file = file,
    pid = pid,
    rule = rule,
    severity = severity,
    value = as.character(value),
    expected = as.character(expected),
    detail = as.character(detail)
  )
}

value_label <- function(x) {
  if (is.null(x)) {
    return("<NULL>")
  }
  if (length(x) == 0) {
    return("<EMPTY>")
  }
  if (is.list(x) && !is.data.frame(x)) {
    return("<LIST>")
  }
  out <- paste(as.character(x), collapse = "; ")
  if (nchar(out) > 180) {
    out <- paste0(substr(out, 1, 177), "...")
  }
  out
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

field_value <- function(obj, field) {
  if (!field %in% names(obj)) {
    return(list(present = FALSE, value = NULL))
  }
  list(present = TRUE, value = obj[[field]])
}

validate_allowed <- function(obj, field, allowed, pid, file,
                             allow_null = TRUE, severity = "ERROR") {
  fv <- field_value(obj, field)
  if (!fv$present) {
    add_issue("classification_json", file, pid, "missing_field", "ERROR",
              value = field, expected = paste(allowed, collapse = "; "))
    return(invisible(FALSE))
  }
  x <- fv$value
  if (is.null(x)) {
    if (!allow_null) {
      add_issue("classification_json", file, pid, paste0(field, "_null"), severity,
                value = "<NULL>", expected = paste(allowed, collapse = "; "))
      return(invisible(FALSE))
    }
    return(invisible(TRUE))
  }
  if (!is.character(x) || length(x) != 1 || !x %in% allowed) {
    add_issue("classification_json", file, pid, paste0(field, "_invalid"), severity,
              value = paste0(value_label(x), " [", value_type(x), "]"),
              expected = paste(allowed, collapse = "; "))
    return(invisible(FALSE))
  }
  invisible(TRUE)
}

validate_boolean <- function(obj, field, pid, file,
                             allow_null = TRUE, severity = "ERROR") {
  fv <- field_value(obj, field)
  if (!fv$present) {
    add_issue("classification_json", file, pid, "missing_field", "ERROR",
              value = field, expected = "true/false/null")
    return(invisible(FALSE))
  }
  x <- fv$value
  if (is.null(x)) {
    if (!allow_null) {
      add_issue("classification_json", file, pid, paste0(field, "_null"), severity,
                value = "<NULL>", expected = "true/false")
      return(invisible(FALSE))
    }
    return(invisible(TRUE))
  }
  if (!is.logical(x) || length(x) != 1) {
    add_issue("classification_json", file, pid, paste0(field, "_not_boolean"), severity,
              value = paste0(value_label(x), " [", value_type(x), "]"),
              expected = if (allow_null) "true/false/null" else "true/false")
    return(invisible(FALSE))
  }
  invisible(TRUE)
}

validate_string_or_null <- function(obj, field, pid, file,
                                    allow_null = TRUE, allow_empty = FALSE,
                                    severity = "ERROR") {
  fv <- field_value(obj, field)
  if (!fv$present) {
    add_issue("classification_json", file, pid, "missing_field", "ERROR",
              value = field, expected = "string/null")
    return(invisible(FALSE))
  }
  x <- fv$value
  if (is.null(x)) {
    if (!allow_null) {
      add_issue("classification_json", file, pid, paste0(field, "_null"), severity,
                value = "<NULL>", expected = "non-empty string")
      return(invisible(FALSE))
    }
    return(invisible(TRUE))
  }
  if (!is.character(x) || length(x) != 1 || (!allow_empty && !nzchar(str_trim(x)))) {
    add_issue("classification_json", file, pid, paste0(field, "_invalid_string"), severity,
              value = paste0(value_label(x), " [", value_type(x), "]"),
              expected = if (allow_null) "string/null" else "non-empty string")
    return(invisible(FALSE))
  }
  invisible(TRUE)
}

validate_list_or_null <- function(obj, field, pid, file, severity = "ERROR") {
  fv <- field_value(obj, field)
  if (!fv$present) {
    add_issue("classification_json", file, pid, "missing_field", "ERROR",
              value = field, expected = "array/object or null")
    return(invisible(FALSE))
  }
  x <- fv$value
  if (is.null(x) || is.list(x)) {
    return(invisible(TRUE))
  }
  add_issue("classification_json", file, pid, paste0(field, "_not_array_or_null"), severity,
            value = paste0(value_label(x), " [", value_type(x), "]"),
            expected = "array/object or null")
  invisible(FALSE)
}

validate_integer_or_null <- function(obj, field, pid, file, severity = "ERROR") {
  fv <- field_value(obj, field)
  if (!fv$present) {
    add_issue("classification_json", file, pid, "missing_field", "ERROR",
              value = field, expected = "integer/null")
    return(invisible(FALSE))
  }
  x <- fv$value
  if (is.null(x)) {
    return(invisible(TRUE))
  }
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x != as.integer(x) || x < 0) {
    add_issue("classification_json", file, pid, paste0(field, "_not_nonnegative_integer"), severity,
              value = paste0(value_label(x), " [", value_type(x), "]"),
              expected = "integer >= 0 or null")
    return(invisible(FALSE))
  }
  invisible(TRUE)
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

required_corpus_columns <- c(
  "pid", "title", "title_en", "authors", "affiliations", "year", "issn",
  "journal_title", "abstract_pt", "abstract_en", "doi", "document_type",
  "language", "has_fulltext_xml"
)

read_csv_safe <- function(path, scope) {
  if (!file.exists(path)) {
    add_issue(scope, basename(path), NA_character_, "file_missing", "ERROR",
              value = path, expected = "file exists")
    return(tibble())
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

corpus <- read_csv_safe(paths$corpus, "corpus")
sample_df <- read_csv_safe(paths$sample, "sample")
sample_sheet <- read_csv_safe(paths$sample_sheet, "sample_sheet")
class_csv <- read_csv_safe(paths$classifications_csv, "classifications_csv")

if (nrow(corpus) > 0) {
  missing_cols <- setdiff(required_corpus_columns, names(corpus))
  if (length(missing_cols) > 0) {
    walk(missing_cols, ~ add_issue("corpus", basename(paths$corpus), NA_character_,
                                  "missing_column", "ERROR", .x,
                                  paste(required_corpus_columns, collapse = "; ")))
  }

  corpus_pids <- corpus$pid
  duplicate_pids <- corpus |>
    dplyr::count(pid, name = "n") |>
    dplyr::filter(is.na(pid) | pid == "" | n > 1)
  if (nrow(duplicate_pids) > 0) {
    purrr::pwalk(duplicate_pids, function(pid, n) {
      add_issue("corpus", basename(paths$corpus), pid, "pid_missing_or_duplicate",
                "ERROR", n, "unique non-empty pid")
    })
  }

  bad_years <- corpus |>
    dplyr::mutate(row_id = dplyr::row_number()) |>
    dplyr::filter(is.na(year) | year < 2005 | year > 2025 | year != as.integer(year)) |>
    dplyr::select(row_id, pid, year)
  if (nrow(bad_years) > 0) {
    purrr::pwalk(bad_years, function(row_id, pid, year) {
      add_issue("corpus", basename(paths$corpus), pid, "year_out_of_range",
                "ERROR", year, "integer between 2005 and 2025",
                paste("row", row_id))
    })
  }

  bad_issn <- corpus |>
    dplyr::mutate(row_id = dplyr::row_number()) |>
    dplyr::filter(is.na(issn) | !stringr::str_detect(issn, "^[0-9]{4}-[0-9Xx]{4}$")) |>
    dplyr::select(row_id, pid, issn)
  if (nrow(bad_issn) > 0) {
    purrr::pwalk(bad_issn, function(row_id, pid, issn) {
      add_issue("corpus", basename(paths$corpus), pid, "issn_invalid",
                "ERROR", issn, "NNNN-NNNN or NNNN-NNNX", paste("row", row_id))
    })
  }

  non_article_doc_types <- corpus |>
    dplyr::filter(!document_type %in% c("research-article")) |>
    dplyr::count(document_type, name = "n") |>
    dplyr::arrange(dplyr::desc(n))
  if (nrow(non_article_doc_types) > 0) {
    purrr::pwalk(non_article_doc_types, function(document_type, n) {
      add_issue("corpus", basename(paths$corpus), NA_character_,
                "non_research_article_document_type", "WARN", n,
                "review inclusion/exclusion before final analysis",
                document_type)
    })
  }

  bad_fulltext <- corpus |>
    dplyr::filter(is.na(has_fulltext_xml) | !has_fulltext_xml %in% c(TRUE, FALSE, 0, 1, "0", "1", "TRUE", "FALSE")) |>
    dplyr::select(pid, has_fulltext_xml)
  if (nrow(bad_fulltext) > 0) {
    purrr::pwalk(bad_fulltext, function(pid, has_fulltext_xml) {
      add_issue("corpus", basename(paths$corpus), pid, "has_fulltext_xml_invalid",
                "ERROR", has_fulltext_xml, "boolean-like value")
    })
  }
}

if (nrow(sample_df) > 0) {
  sample_dups <- sample_df |>
    dplyr::count(pid, name = "n") |>
    dplyr::filter(is.na(pid) | pid == "" | n > 1)
  if (nrow(sample_dups) > 0) {
    purrr::pwalk(sample_dups, function(pid, n) {
      add_issue("sample", basename(paths$sample), pid, "pid_missing_or_duplicate",
                "ERROR", n, "unique non-empty pid")
    })
  }

  if (nrow(corpus) > 0) {
    missing_in_corpus <- setdiff(sample_df$pid, corpus$pid)
    walk(missing_in_corpus, ~ add_issue("sample", basename(paths$sample), .x,
                                        "sample_pid_not_in_corpus", "ERROR",
                                        .x, "pid present in corpus"))
  }

  missing_xml <- sample_df$pid[!file.exists(file.path(paths$sample_xml_dir, paste0(sample_df$pid, ".xml")))]
  walk(missing_xml, ~ add_issue("sample", basename(paths$sample), .x,
                                "sample_xml_missing", "ERROR", .x,
                                "data/processed/sample_xmls/<pid>.xml"))
}

json_files <- if (dir.exists(paths$classifications_dir)) {
  list.files(paths$classifications_dir, pattern = "[.]json$", full.names = TRUE)
} else {
  character()
}

if (!dir.exists(paths$classifications_dir)) {
  add_issue("classification_json", basename(paths$classifications_dir),
            NA_character_, "directory_missing", "ERROR",
            paths$classifications_dir, "directory exists")
}

parsed_json <- list()
for (json_file in sort(json_files)) {
  pid_from_file <- tools::file_path_sans_ext(basename(json_file))
  obj <- tryCatch(
    jsonlite::fromJSON(json_file, simplifyVector = FALSE),
    error = function(e) e
  )
  if (inherits(obj, "error")) {
    add_issue("classification_json", basename(json_file), pid_from_file,
              "json_parse_error", "ERROR", obj$message, "valid JSON")
    next
  }
  parsed_json[[pid_from_file]] <- obj

  json_pid <- if ("pid" %in% names(obj)) obj$pid else NULL
  if (is.null(json_pid) || !identical(as.character(json_pid), pid_from_file)) {
    add_issue("classification_json", basename(json_file), pid_from_file,
              "pid_filename_mismatch", "ERROR",
              value = value_label(json_pid), expected = pid_from_file)
  }

  extra_fields <- setdiff(names(obj), expected_json_fields)
  walk(extra_fields, ~ add_issue("classification_json", basename(json_file), pid_from_file,
                                "extra_field", "WARN", .x,
                                paste(expected_json_fields, collapse = "; ")))

  validate_allowed(obj, "error_in_raw_text", allowed$error_in_raw_text,
                   pid_from_file, basename(json_file), allow_null = FALSE)
  validate_allowed(obj, "subfield", allowed$subfield,
                   pid_from_file, basename(json_file), allow_null = FALSE)
  validate_boolean(obj, "is_empirical_quant_paper",
                   pid_from_file, basename(json_file), allow_null = FALSE)
  validate_allowed(obj, "general_goal_of_analysis", allowed$general_goal_of_analysis,
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_allowed(obj, "single_country_study", allowed$single_country_study,
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_allowed(obj, "single_region", allowed$single_region,
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_string_or_null(obj, "countries_of_focus", pid_from_file, basename(json_file),
                          allow_null = TRUE, allow_empty = FALSE)
  validate_allowed(obj, "paper_uses_survey_data", allowed$paper_uses_survey_data,
                   pid_from_file, basename(json_file), allow_null = FALSE)
  validate_allowed(obj, "uses_original_dataset", allowed$uses_original_dataset,
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_boolean(obj, "seeks_determinants",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_allowed(obj, "main_causal_research_design", allowed$main_causal_research_design,
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_string_or_null(obj, "other_research_design", pid_from_file, basename(json_file),
                          allow_null = TRUE, allow_empty = FALSE)
  validate_string_or_null(obj, "instrumental_variable_instrument", pid_from_file, basename(json_file),
                          allow_null = TRUE, allow_empty = FALSE)
  validate_boolean(obj, "placebo_test",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_list_or_null(obj, "independent_variables", pid_from_file, basename(json_file))
  validate_list_or_null(obj, "dependent_variables", pid_from_file, basename(json_file))
  validate_list_or_null(obj, "main_variable_relationship", pid_from_file, basename(json_file))
  validate_boolean(obj, "makes_explicit_causal_claim",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_boolean(obj, "makes_implicit_causal_claim",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_boolean(obj, "strong_non_causal_causal_qualification",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_integer_or_null(obj, "sample_size", pid_from_file, basename(json_file))
  validate_string_or_null(obj, "sample_size_quote", pid_from_file, basename(json_file),
                          allow_null = TRUE, allow_empty = FALSE)
  validate_boolean(obj, "claims_any_statistically_significant_results",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_boolean(obj, "references_power_analysis",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_boolean(obj, "clearly_defined_explanatory_variable",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_allowed(obj, "clear_causal_quantity_of_interest", allowed$clear_causal_quantity_of_interest,
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_boolean(obj, "specifies_estimate_equations",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_boolean(obj, "discusses_threats_to_causality",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_string_or_null(obj, "statement_of_identification_assumptions_quote",
                          pid_from_file, basename(json_file),
                          allow_null = TRUE, allow_empty = FALSE)
  validate_boolean(obj, "statement_of_identification_assumptions",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_allowed(obj, "effort_to_explore_mechanisms", allowed$effort_to_explore_mechanisms,
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_boolean(obj, "mentions_pre_registered_design_and_analysis_plan",
                   pid_from_file, basename(json_file), allow_null = TRUE)
  validate_allowed(obj, "evidence_type", allowed$evidence_type,
                   pid_from_file, basename(json_file), allow_null = FALSE)
  validate_allowed(obj, "method_status", allowed$method_status,
                   pid_from_file, basename(json_file), allow_null = FALSE)
  validate_string_or_null(obj, "brief_justification", pid_from_file, basename(json_file),
                          allow_null = FALSE, allow_empty = FALSE)
}

json_pids <- names(parsed_json)

if (nrow(sample_df) > 0) {
  missing_json <- setdiff(sample_df$pid, json_pids)
  extra_json <- setdiff(json_pids, sample_df$pid)
  walk(missing_json, ~ add_issue("classification_json", NA_character_, .x,
                                 "sample_pid_without_classification_json",
                                 "ERROR", .x, "one JSON per sample pid"))
  walk(extra_json, ~ add_issue("classification_json", NA_character_, .x,
                               "classification_json_not_in_sample",
                               "ERROR", .x, "classification pid belongs to sample"))
}

if (nrow(class_csv) > 0) {
  if ("pid" %in% names(class_csv)) {
    csv_dups <- class_csv |>
      dplyr::count(pid, name = "n") |>
      dplyr::filter(is.na(pid) | pid == "" | n > 1)
    if (nrow(csv_dups) > 0) {
      purrr::pwalk(csv_dups, function(pid, n) {
        add_issue("classifications_csv", basename(paths$classifications_csv), pid,
                  "pid_missing_or_duplicate", "ERROR", n, "unique non-empty pid")
      })
    }
    missing_in_json <- setdiff(class_csv$pid, json_pids)
    missing_in_csv <- setdiff(json_pids, class_csv$pid)
    walk(missing_in_json, ~ add_issue("classifications_csv", basename(paths$classifications_csv), .x,
                                      "csv_pid_without_json", "ERROR", .x,
                                      "pid present in classifications JSON"))
    walk(missing_in_csv, ~ add_issue("classifications_csv", basename(paths$classifications_csv), .x,
                                     "json_pid_missing_from_csv", "ERROR", .x,
                                     "pid present in consolidated CSV"))
  } else {
    add_issue("classifications_csv", basename(paths$classifications_csv),
              NA_character_, "pid_column_missing", "ERROR",
              value = paste(names(class_csv), collapse = "; "), expected = "pid")
  }

  missing_csv_cols <- setdiff(expected_json_fields, names(class_csv))
  extra_csv_cols <- setdiff(names(class_csv), expected_json_fields)
  walk(missing_csv_cols, ~ add_issue("classifications_csv", basename(paths$classifications_csv),
                                    NA_character_, "missing_column", "ERROR",
                                    .x, paste(expected_json_fields, collapse = "; ")))
  walk(extra_csv_cols, ~ add_issue("classifications_csv", basename(paths$classifications_csv),
                                  NA_character_, "extra_column", "WARN",
                                  .x, paste(expected_json_fields, collapse = "; ")))
}

issues <- if (length(issue_rows) == 0L) {
  tibble(
    scope = character(),
    file = character(),
    pid = character(),
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

count_or_zero <- function(df, var) {
  if (nrow(df) == 0) {
    return(tibble())
  }
  df |>
    dplyr::count({{ var }}, name = "n") |>
    dplyr::arrange(dplyr::desc(n))
}

severity_counts <- issues |>
  dplyr::count(severity, name = "n") |>
  dplyr::arrange(dplyr::desc(n))

rule_counts <- issues |>
  dplyr::count(severity, scope, rule, name = "n") |>
  dplyr::arrange(dplyr::desc(n), severity, scope, rule)

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

snapshot <- tibble(
  item = c(
    "artigos no corpus",
    "periódicos no corpus",
    "anos no corpus",
    "artigos na amostra",
    "linhas na planilha de validação",
    "JSONs de classificação",
    "linhas no CSV consolidado",
    "issues totais",
    "errors",
    "warnings"
  ),
  value = c(
    nrow(corpus),
    if (nrow(corpus) > 0) length(unique(corpus$journal_title)) else 0,
    if (nrow(corpus) > 0) paste(range(corpus$year, na.rm = TRUE), collapse = "-") else "NA",
    nrow(sample_df),
    nrow(sample_sheet),
    length(json_files),
    nrow(class_csv),
    nrow(issues),
    sum(issues$severity == "ERROR"),
    sum(issues$severity == "WARN")
  )
)

next_steps <- c(
  "1. Corrigir primeiro os erros de schema em `error_in_raw_text`, `paper_uses_survey_data`, `uses_original_dataset`, `single_country_study`, `single_region`, `clear_causal_quantity_of_interest` e `effort_to_explore_mechanisms`.",
  "2. Decidir se campos extras (`classified_by`, `qualitative_method`) serão incorporados ao schema oficial ou removidos antes da consolidação.",
  "3. Regerar `data/processed/classifications_llm.csv` a partir dos JSONs corrigidos.",
  "4. Só depois usar `classifications_llm.csv` para tabelas, figuras e inferências substantivas."
)

summary_lines <- c(
  "# Validação das Classificações",
  "",
  paste("Gerado em", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Snapshot",
  "",
  markdown_table(snapshot),
  "",
  "## Issues por Severidade",
  "",
  markdown_table(severity_counts),
  "",
  "## Principais Regras com Issues",
  "",
  markdown_table(rule_counts, max_rows = 25),
  "",
  "## Próximos Passos",
  "",
  next_steps,
  "",
  "## Arquivos Gerados",
  "",
  paste0("- `", paths$issues, "`"),
  paste0("- `", paths$summary, "`")
)

writeLines(summary_lines, paths$summary, useBytes = TRUE)

cat("Validação concluída.\n")
cat("Issues:", nrow(issues), "\n")
cat("Errors:", sum(issues$severity == "ERROR"), "\n")
cat("Warnings:", sum(issues$severity == "WARN"), "\n")
cat("Relatório:", paths$summary, "\n")
