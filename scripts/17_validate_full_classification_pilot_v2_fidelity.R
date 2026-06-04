## 17_validate_full_classification_pilot_v2_fidelity.R
## Valida auditorias de fidelidade textual do Agente D para o piloto v2.

options(scipen = 999)

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(jsonlite)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

project_dir <- normalizePath(".", mustWork = TRUE)
pilot_dir <- file.path(project_dir, "data", "processed", "full_classification_pilot_v2")
comparison_dir <- file.path(pilot_dir, "comparison")
dir.create(comparison_dir, showWarnings = FALSE, recursive = TRUE)

paths <- list(
  manifest = file.path(pilot_dir, "pilot_manifest.csv"),
  issues = file.path(project_dir, "quality_reports", "full_classification_pilot_v2_fidelity_validation_issues.csv"),
  summary = file.path(project_dir, "quality_reports", "full_classification_pilot_v2_fidelity_validation_summary.md"),
  file_audits = file.path(comparison_dir, "fidelity_file_audits_validated.csv"),
  field_audits = file.path(comparison_dir, "fidelity_field_audits_validated.csv")
)

agents <- c("agent_a", "agent_b", "agent_c")

priority_factual_fields <- c(
  "sample_size",
  "sample_size_quote",
  "independent_variables",
  "dependent_variables",
  "main_variable_relationship",
  "paper_uses_survey_data",
  "uses_original_dataset",
  "main_causal_research_design",
  "makes_explicit_causal_claim",
  "makes_implicit_causal_claim",
  "statement_of_identification_assumptions",
  "statement_of_identification_assumptions_quote",
  "specifies_estimate_equations",
  "effort_to_explore_mechanisms",
  "claims_any_statistically_significant_results",
  "references_power_analysis",
  "mentions_pre_registered_design_and_analysis_plan"
)

allowed_status <- c(
  "supported_by_text",
  "contradicted_by_text",
  "not_found_in_text",
  "not_a_factual_field"
)
allowed_severity <- c("none", "low", "medium", "high")
allowed_overall <- c("pass", "pass_with_warnings", "fail")

if (!file.exists(paths$manifest)) {
  stop("Manifest v2 ausente. Rode scripts/10_prepare_full_classification_pilot_v2.R primeiro.")
}

manifest <- readr::read_csv(paths$manifest, show_col_types = FALSE, progress = FALSE)

issue_rows <- list()
file_rows <- list()
field_rows <- list()

relative_path <- function(path) {
  stringr::str_remove(normalizePath(path, mustWork = FALSE), paste0("^", stringr::fixed(project_dir), "/?"))
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
  if (length(x) == 1 && is.na(x)) {
    return("<NULL>")
  }
  if (is.logical(x) && length(x) == 1) {
    return(ifelse(isTRUE(x), "TRUE", "FALSE"))
  }
  if (is.list(x) && !is.data.frame(x)) {
    return(json_value(x))
  }
  out <- paste(as.character(x), collapse = "; ")
  if (!nzchar(out)) {
    return("<NULL>")
  }
  if (nchar(out) > 500) {
    out <- paste0(substr(out, 1, 497), "...")
  }
  out
}

add_issue <- function(audited_agent_id, pid, file = NA_character_, field = NA_character_,
                      rule, severity = "ERROR", value = NA_character_,
                      expected = NA_character_, detail = NA_character_) {
  issue_rows[[length(issue_rows) + 1L]] <<- tibble(
    audited_agent_id = audited_agent_id,
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

field_value <- function(obj, field) {
  if (!field %in% names(obj)) {
    return(list(present = FALSE, value = NULL))
  }
  list(present = TRUE, value = obj[[field]])
}

validate_string <- function(obj, field, audited_agent_id, pid, file, allow_null = FALSE) {
  fv <- field_value(obj, field)
  if (!fv$present) {
    add_issue(audited_agent_id, pid, file, field, "missing_field",
              value = field, expected = "string")
    return(FALSE)
  }
  x <- fv$value
  if (is.null(x)) {
    if (allow_null) {
      return(TRUE)
    }
    add_issue(audited_agent_id, pid, file, field, paste0(field, "_null"),
              value = "<NULL>", expected = "string")
    return(FALSE)
  }
  if (!is.character(x) || length(x) != 1 || !nzchar(stringr::str_trim(x))) {
    add_issue(audited_agent_id, pid, file, field, paste0(field, "_invalid_string"),
              value = value_label(x), expected = "non-empty string")
    return(FALSE)
  }
  TRUE
}

validate_allowed <- function(obj, field, allowed, audited_agent_id, pid, file) {
  if (!validate_string(obj, field, audited_agent_id, pid, file, allow_null = FALSE)) {
    return(FALSE)
  }
  x <- obj[[field]]
  if (!x %in% allowed) {
    add_issue(audited_agent_id, pid, file, field, paste0(field, "_invalid"),
              value = value_label(x), expected = paste(allowed, collapse = "; "))
    return(FALSE)
  }
  TRUE
}

validate_present <- function(obj, field, audited_agent_id, pid, file) {
  if (!field %in% names(obj)) {
    add_issue(audited_agent_id, pid, file, field, "missing_field",
              value = field, expected = "present")
    return(FALSE)
  }
  TRUE
}

classification_file_hash <- function(audited_agent_id, pid) {
  classification_file <- file.path(pilot_dir, audited_agent_id, paste0(pid, ".json"))
  if (!file.exists(classification_file)) {
    return(NA_character_)
  }
  digest::digest(classification_file, algo = "sha256", file = TRUE)
}

for (agent_id in agents) {
  for (row_idx in seq_len(nrow(manifest))) {
    item <- manifest[row_idx, ]
    pid <- item$pid[[1]]
    audit_file <- file.path(pilot_dir, "fidelity_checker", agent_id, paste0(pid, ".json"))
    rel_audit_file <- relative_path(audit_file)
    expected_classification_hash <- classification_file_hash(agent_id, pid)

    if (!file.exists(audit_file)) {
      add_issue(agent_id, pid, rel_audit_file, NA_character_, "missing_fidelity_json",
                value = rel_audit_file, expected = "one fidelity JSON per audited agent and pid")
      file_rows[[length(file_rows) + 1L]] <- tibble(
        pid = pid,
        audited_agent_id = agent_id,
        file = rel_audit_file,
        audit_file_exists = FALSE,
        audit_file_valid = FALSE,
        overall_fidelity_status = NA_character_,
        classification_hash = NA_character_,
        expected_classification_hash = expected_classification_hash,
        field_audit_count = 0L,
        priority_field_count = 0L
      )
      next
    }

    obj <- tryCatch(
      jsonlite::fromJSON(audit_file, simplifyVector = FALSE),
      error = function(e) e
    )

    if (inherits(obj, "error")) {
      add_issue(agent_id, pid, rel_audit_file, NA_character_, "json_parse_error",
                value = obj$message, expected = "valid JSON")
      file_rows[[length(file_rows) + 1L]] <- tibble(
        pid = pid,
        audited_agent_id = agent_id,
        file = rel_audit_file,
        audit_file_exists = TRUE,
        audit_file_valid = FALSE,
        overall_fidelity_status = NA_character_,
        classification_hash = NA_character_,
        expected_classification_hash = expected_classification_hash,
        field_audit_count = 0L,
        priority_field_count = 0L
      )
      next
    }

    envelope_required <- c(
      "pid", "audited_agent_id", "checker_agent_id", "input_text_hash",
      "classification_hash", "field_audits", "overall_fidelity_status",
      "brief_summary"
    )
    missing_envelope <- setdiff(envelope_required, names(obj))
    purrr::walk(missing_envelope, function(field) {
      add_issue(agent_id, pid, rel_audit_file, field, "missing_envelope_field",
                value = field, expected = paste(envelope_required, collapse = "; "))
    })
    extra_envelope <- setdiff(names(obj), envelope_required)
    purrr::walk(extra_envelope, function(field) {
      add_issue(agent_id, pid, rel_audit_file, field, "extra_envelope_field",
                value = field, expected = paste(envelope_required, collapse = "; "))
    })

    if (!identical(obj$pid, pid)) {
      add_issue(agent_id, pid, rel_audit_file, "pid", "pid_mismatch",
                value = value_label(obj$pid), expected = pid)
    }
    if (!identical(obj$audited_agent_id, agent_id)) {
      add_issue(agent_id, pid, rel_audit_file, "audited_agent_id", "audited_agent_id_mismatch",
                value = value_label(obj$audited_agent_id), expected = agent_id)
    }
    if (!identical(obj$checker_agent_id, "agent_d")) {
      add_issue(agent_id, pid, rel_audit_file, "checker_agent_id", "checker_agent_id_mismatch",
                value = value_label(obj$checker_agent_id), expected = "agent_d")
    }
    if (!identical(obj$input_text_hash, item$input_text_hash[[1]])) {
      add_issue(agent_id, pid, rel_audit_file, "input_text_hash", "input_text_hash_mismatch",
                value = value_label(obj$input_text_hash), expected = item$input_text_hash[[1]])
    }
    if (!identical(obj$classification_hash, expected_classification_hash)) {
      add_issue(agent_id, pid, rel_audit_file, "classification_hash", "classification_hash_mismatch",
                value = value_label(obj$classification_hash), expected = expected_classification_hash)
    }
    validate_allowed(obj, "overall_fidelity_status", allowed_overall, agent_id, pid, rel_audit_file)
    validate_string(obj, "brief_summary", agent_id, pid, rel_audit_file, allow_null = FALSE)

    if (!"field_audits" %in% names(obj) || !is.list(obj$field_audits)) {
      add_issue(agent_id, pid, rel_audit_file, "field_audits", "field_audits_missing_or_not_array",
                value = value_label(obj$field_audits), expected = "array")
      file_rows[[length(file_rows) + 1L]] <- tibble(
        pid = pid,
        audited_agent_id = agent_id,
        file = rel_audit_file,
        audit_file_exists = TRUE,
        audit_file_valid = FALSE,
        overall_fidelity_status = value_label(obj$overall_fidelity_status),
        classification_hash = value_label(obj$classification_hash),
        expected_classification_hash = expected_classification_hash,
        field_audit_count = 0L,
        priority_field_count = 0L
      )
      next
    }

    audited_fields <- character()
    for (field_idx in seq_along(obj$field_audits)) {
      audit <- obj$field_audits[[field_idx]]
      field_file_label <- paste0(rel_audit_file, "#field_audits[", field_idx, "]")
      item_required <- c(
        "field", "status", "severity", "reason",
        "supporting_excerpt", "classification_value"
      )
      missing_item <- setdiff(item_required, names(audit))
      purrr::walk(missing_item, function(field) {
        add_issue(agent_id, pid, field_file_label, field, "missing_field_audit_field",
                  value = field, expected = paste(item_required, collapse = "; "))
      })
      extra_item <- setdiff(names(audit), item_required)
      purrr::walk(extra_item, function(field) {
        add_issue(agent_id, pid, field_file_label, field, "extra_field_audit_field",
                  value = field, expected = paste(item_required, collapse = "; "))
      })

      validate_string(audit, "field", agent_id, pid, field_file_label, allow_null = FALSE)
      validate_allowed(audit, "status", allowed_status, agent_id, pid, field_file_label)
      validate_allowed(audit, "severity", allowed_severity, agent_id, pid, field_file_label)
      validate_string(audit, "reason", agent_id, pid, field_file_label, allow_null = FALSE)
      validate_present(audit, "supporting_excerpt", agent_id, pid, field_file_label)
      validate_present(audit, "classification_value", agent_id, pid, field_file_label)

      field_name <- if ("field" %in% names(audit)) value_label(audit$field) else NA_character_
      audited_fields <- c(audited_fields, field_name)
      field_rows[[length(field_rows) + 1L]] <- tibble(
        pid = pid,
        audited_agent_id = agent_id,
        checker_agent_id = "agent_d",
        file = rel_audit_file,
        field = field_name,
        status = if ("status" %in% names(audit)) value_label(audit$status) else NA_character_,
        severity = if ("severity" %in% names(audit)) value_label(audit$severity) else NA_character_,
        reason = if ("reason" %in% names(audit)) value_label(audit$reason) else NA_character_,
        supporting_excerpt = if (!"supporting_excerpt" %in% names(audit) || is.null(audit$supporting_excerpt)) NA_character_ else value_label(audit$supporting_excerpt),
        classification_value = if ("classification_value" %in% names(audit)) value_label(audit$classification_value) else NA_character_,
        overall_fidelity_status = if ("overall_fidelity_status" %in% names(obj)) value_label(obj$overall_fidelity_status) else NA_character_,
        input_text_hash = if ("input_text_hash" %in% names(obj)) value_label(obj$input_text_hash) else NA_character_,
        classification_hash = if ("classification_hash" %in% names(obj)) value_label(obj$classification_hash) else NA_character_
      )
    }

    missing_priority <- setdiff(priority_factual_fields, audited_fields)
    purrr::walk(missing_priority, function(field) {
      add_issue(agent_id, pid, rel_audit_file, field, "missing_priority_factual_field_audit",
                value = field, expected = paste(priority_factual_fields, collapse = "; "))
    })

    file_rows[[length(file_rows) + 1L]] <- tibble(
      pid = pid,
      audited_agent_id = agent_id,
      file = rel_audit_file,
      audit_file_exists = TRUE,
      audit_file_valid = TRUE,
      overall_fidelity_status = if ("overall_fidelity_status" %in% names(obj)) value_label(obj$overall_fidelity_status) else NA_character_,
      classification_hash = if ("classification_hash" %in% names(obj)) value_label(obj$classification_hash) else NA_character_,
      expected_classification_hash = expected_classification_hash,
      field_audit_count = length(obj$field_audits),
      priority_field_count = length(intersect(priority_factual_fields, audited_fields))
    )
  }
}

issues <- if (length(issue_rows) == 0L) {
  tibble(
    audited_agent_id = character(),
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

file_audits <- if (length(file_rows) == 0L) {
  tibble(
    pid = character(),
    audited_agent_id = character(),
    file = character(),
    audit_file_exists = logical(),
    audit_file_valid = logical(),
    overall_fidelity_status = character(),
    classification_hash = character(),
    expected_classification_hash = character(),
    field_audit_count = integer(),
    priority_field_count = integer()
  )
} else {
  dplyr::bind_rows(file_rows)
}

field_audits <- if (length(field_rows) == 0L) {
  tibble(
    pid = character(),
    audited_agent_id = character(),
    checker_agent_id = character(),
    file = character(),
    field = character(),
    status = character(),
    severity = character(),
    reason = character(),
    supporting_excerpt = character(),
    classification_value = character(),
    overall_fidelity_status = character(),
    input_text_hash = character(),
    classification_hash = character()
  )
} else {
  dplyr::bind_rows(field_rows)
}

readr::write_csv(issues, paths$issues, na = "")
readr::write_csv(file_audits, paths$file_audits, na = "")
readr::write_csv(field_audits, paths$field_audits, na = "")

markdown_table <- function(df, max_rows = Inf, digits = 3) {
  if (nrow(df) == 0) {
    return("_Nenhum registro._")
  }
  df <- utils::head(df, max_rows)
  df <- df |>
    dplyr::mutate(dplyr::across(where(is.numeric), ~ round(.x, digits)))
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- apply(df, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

issue_counts <- issues |>
  dplyr::count(audited_agent_id, severity, name = "n") |>
  tidyr::pivot_wider(names_from = severity, values_from = n, values_fill = 0)
if (!"ERROR" %in% names(issue_counts)) {
  issue_counts$ERROR <- integer(nrow(issue_counts))
}
if (!"WARN" %in% names(issue_counts)) {
  issue_counts$WARN <- integer(nrow(issue_counts))
}

summary_by_agent <- tibble(audited_agent_id = agents) |>
  dplyr::left_join(
    file_audits |>
      dplyr::group_by(audited_agent_id) |>
      dplyr::summarise(
        audit_jsons_present = sum(audit_file_exists),
        audit_jsons_valid = sum(audit_file_valid),
        pass = sum(overall_fidelity_status == "pass", na.rm = TRUE),
        pass_with_warnings = sum(overall_fidelity_status == "pass_with_warnings", na.rm = TRUE),
        fail = sum(overall_fidelity_status == "fail", na.rm = TRUE),
        .groups = "drop"
      ),
    by = "audited_agent_id"
  ) |>
  dplyr::left_join(issue_counts, by = "audited_agent_id") |>
  dplyr::mutate(
    audit_jsons_present = dplyr::coalesce(audit_jsons_present, 0L),
    audit_jsons_valid = dplyr::coalesce(audit_jsons_valid, 0L),
    pass = dplyr::coalesce(pass, 0L),
    pass_with_warnings = dplyr::coalesce(pass_with_warnings, 0L),
    fail = dplyr::coalesce(fail, 0L),
    ERROR = dplyr::coalesce(ERROR, 0L),
    WARN = dplyr::coalesce(WARN, 0L)
  ) |>
  dplyr::select(audited_agent_id, audit_jsons_present, audit_jsons_valid, pass, pass_with_warnings, fail, ERROR, WARN)

top_rules <- issues |>
  dplyr::count(severity, rule, name = "n") |>
  dplyr::arrange(dplyr::desc(n), severity, rule)

summary_lines <- c(
  "# Validação da fidelidade textual do piloto v2",
  "",
  paste("Gerado em", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Snapshot por agente auditado",
  "",
  markdown_table(summary_by_agent),
  "",
  "## Principais problemas",
  "",
  markdown_table(top_rules, max_rows = 30),
  "",
  "## Arquivos gerados",
  "",
  paste0("- `", relative_path(paths$issues), "`"),
  paste0("- `", relative_path(paths$file_audits), "`"),
  paste0("- `", relative_path(paths$field_audits), "`")
)

writeLines(summary_lines, paths$summary, useBytes = TRUE)

cat("Validação de fidelidade v2 concluída.\n")
cat("Auditorias esperadas:", nrow(manifest) * length(agents), "\n")
cat("Auditorias presentes:", sum(file_audits$audit_file_exists), "\n")
cat("Erros:", sum(issues$severity == "ERROR"), "\n")
cat("Avisos:", sum(issues$severity == "WARN"), "\n")
cat("Relatório:", paths$summary, "\n")
