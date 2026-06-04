## 12_compare_full_classification_pilot_v2.R
## Compara classificacoes v2, audita consenso e produz diagnostico contra a rodada antiga.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(digest)
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
  previous_classification = file.path(project_dir, "data", "processed", "classifications_llm_main_analysis.csv"),
  validation_issues = file.path(project_dir, "quality_reports", "full_classification_pilot_v2_validation_issues.csv"),
  fidelity_validation_issues = file.path(project_dir, "quality_reports", "full_classification_pilot_v2_fidelity_validation_issues.csv"),
  agreement = file.path(comparison_dir, "agent_field_agreement.csv"),
  consensus_long = file.path(comparison_dir, "consensus_field_decisions.csv"),
  consensus_wide = file.path(comparison_dir, "consensus_classifications.csv"),
  conflicts = file.path(comparison_dir, "conflicts.csv"),
  adjudication = file.path(comparison_dir, "adjudication_queue.csv"),
  prioritized_adjudication = file.path(comparison_dir, "adjudication_queue_prioritized.csv"),
  previous_agent = file.path(comparison_dir, "previous_classification_agreement_by_agent_field.csv"),
  previous_consensus = file.path(comparison_dir, "previous_classification_agreement_consensus_by_field.csv"),
  previous_disagreements = file.path(comparison_dir, "previous_classification_disagreements.csv"),
  agent_bias_diagnostic = file.path(comparison_dir, "agent_bias_against_previous_diagnostic.csv"),
  agent_permissiveness = file.path(comparison_dir, "agent_permissiveness_summary.csv"),
  fidelity_file_audits = file.path(comparison_dir, "fidelity_file_audits.csv"),
  fidelity_field_audits = file.path(comparison_dir, "fidelity_field_audits.csv"),
  fidelity_agent_summary = file.path(comparison_dir, "fidelity_supported_rates_by_agent.csv"),
  fidelity_agent_field_summary = file.path(comparison_dir, "fidelity_supported_rates_by_agent_field.csv"),
  fidelity_risk_fields = file.path(comparison_dir, "fidelity_high_risk_fields.csv"),
  fidelity_severe_failures = file.path(comparison_dir, "fidelity_severe_failures.csv"),
  report = file.path(project_dir, "quality_reports", "full_classification_pilot_v2_final_report.md")
)

agents <- c("agent_a", "agent_b", "agent_c")

classification_fields <- c(
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

critical_fields <- c(
  "is_empirical_quant_paper",
  "evidence_type",
  "method_status",
  "main_causal_research_design",
  "makes_explicit_causal_claim",
  "makes_implicit_causal_claim",
  "statement_of_identification_assumptions",
  "effort_to_explore_mechanisms"
)

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

if (!file.exists(paths$manifest)) {
  stop("Manifest v2 ausente. Rode scripts/10_prepare_full_classification_pilot_v2.R primeiro.")
}
if (!file.exists(paths$previous_classification)) {
  stop("Classificacao anterior ausente para diagnostico: ", paths$previous_classification)
}

manifest <- readr::read_csv(paths$manifest, show_col_types = FALSE, progress = FALSE)
previous_classification <- readr::read_csv(paths$previous_classification, show_col_types = FALSE, progress = FALSE)

validation_issues <- if (file.exists(paths$validation_issues)) {
  readr::read_csv(paths$validation_issues, show_col_types = FALSE, progress = FALSE)
} else {
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
}

fidelity_validation_issues <- if (file.exists(paths$fidelity_validation_issues)) {
  readr::read_csv(paths$fidelity_validation_issues, show_col_types = FALSE, progress = FALSE)
} else {
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
  out
}

read_agent_long <- function(agent_id) {
  agent_dir <- file.path(pilot_dir, agent_id)
  rows <- list()
  for (row_idx in seq_len(nrow(manifest))) {
    pid <- manifest$pid[[row_idx]]
    json_file <- file.path(agent_dir, paste0(pid, ".json"))
    if (!file.exists(json_file)) {
      rows[[length(rows) + 1L]] <- tibble(
        pid = pid,
        agent_id = agent_id,
        field = classification_fields,
        value = "<MISSING_JSON>",
        valid_value = FALSE
      )
      next
    }
    envelope <- tryCatch(
      jsonlite::fromJSON(json_file, simplifyVector = FALSE),
      error = function(e) e
    )
    if (inherits(envelope, "error") || !"classification" %in% names(envelope) || !is.list(envelope$classification)) {
      rows[[length(rows) + 1L]] <- tibble(
        pid = pid,
        agent_id = agent_id,
        field = classification_fields,
        value = "<INVALID_JSON>",
        valid_value = FALSE
      )
      next
    }
    cls <- envelope$classification
    rows[[length(rows) + 1L]] <- tibble(
      pid = pid,
      agent_id = agent_id,
      field = classification_fields,
      value = vapply(classification_fields, function(field) {
        if (!field %in% names(cls)) {
          return("<MISSING_FIELD>")
        }
        value_label(cls[[field]])
      }, character(1)),
      valid_value = TRUE
    )
  }
  dplyr::bind_rows(rows)
}

agent_long <- purrr::map_dfr(agents, read_agent_long)

error_keys <- validation_issues |>
  dplyr::filter(severity == "ERROR") |>
  dplyr::transmute(
    agent_id,
    pid,
    field = dplyr::if_else(is.na(field) | field == "", "__envelope__", field),
    has_validation_error = TRUE
  ) |>
  dplyr::distinct()

agent_long <- agent_long |>
  dplyr::left_join(
    error_keys |>
      dplyr::filter(field != "__envelope__"),
    by = c("agent_id", "pid", "field")
  ) |>
  dplyr::left_join(
    error_keys |>
      dplyr::filter(field == "__envelope__") |>
      dplyr::select(agent_id, pid, has_envelope_error = has_validation_error),
    by = c("agent_id", "pid")
  ) |>
  dplyr::mutate(
    has_validation_error = dplyr::coalesce(has_validation_error, FALSE),
    has_envelope_error = dplyr::coalesce(has_envelope_error, FALSE),
    valid_value = valid_value & !has_validation_error & !has_envelope_error
  )

consensus_long <- agent_long |>
  dplyr::group_by(pid, field) |>
  dplyr::summarise(
    critical_field = field[[1]] %in% critical_fields,
    n_agents = dplyr::n(),
    n_valid = sum(valid_value),
    n_distinct_values = dplyr::n_distinct(value[valid_value]),
    top_value = if (n_valid > 0) names(sort(table(value[valid_value]), decreasing = TRUE))[1] else NA_character_,
    top_n = if (n_valid > 0) as.integer(max(table(value[valid_value]))) else 0L,
    agent_a_value = value[agent_id == "agent_a"][1],
    agent_b_value = value[agent_id == "agent_b"][1],
    agent_c_value = value[agent_id == "agent_c"][1],
    agent_a_valid = valid_value[agent_id == "agent_a"][1],
    agent_b_valid = valid_value[agent_id == "agent_b"][1],
    agent_c_valid = valid_value[agent_id == "agent_c"][1],
    .groups = "drop"
  ) |>
  dplyr::mutate(
    consensus_level = dplyr::case_when(
      n_valid < 3 ~ "invalid_or_missing",
      n_distinct_values == 1 ~ "unanimity",
      top_n == 2 & !critical_field ~ "majority",
      top_n == 2 & critical_field ~ "critical_disagreement",
      TRUE ~ "no_majority"
    ),
    consensus_value = dplyr::if_else(
      consensus_level %in% c("unanimity", "majority"),
      top_value,
      NA_character_
    ),
    decision = dplyr::case_when(
      consensus_level %in% c("unanimity", "majority") ~ "accept_provisionally",
      consensus_level == "invalid_or_missing" ~ "reprocess_or_adjudicate",
      TRUE ~ "adjudicate"
    )
  ) |>
  dplyr::left_join(
    manifest |>
      dplyr::select(pid, title, year, journal_title, source_file, input_text_hash),
    by = "pid"
  ) |>
  dplyr::select(
    pid, title, year, journal_title, source_file, input_text_hash,
    field, critical_field, consensus_level, decision, consensus_value,
    agent_a_value, agent_b_value, agent_c_value,
    agent_a_valid, agent_b_valid, agent_c_valid,
    n_valid, n_distinct_values, top_n
  )

readr::write_csv(consensus_long, paths$consensus_long, na = "")

agreement <- consensus_long |>
  dplyr::group_by(field, critical_field) |>
  dplyr::summarise(
    n_articles = dplyr::n(),
    unanimity_n = sum(consensus_level == "unanimity"),
    unanimity_rate = unanimity_n / n_articles,
    majority_n = sum(consensus_level == "majority"),
    majority_rate = majority_n / n_articles,
    critical_disagreement_n = sum(consensus_level == "critical_disagreement"),
    invalid_or_missing_n = sum(consensus_level == "invalid_or_missing"),
    adjudication_n = sum(decision != "accept_provisionally"),
    adjudication_rate = adjudication_n / n_articles,
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(critical_field), dplyr::desc(adjudication_rate), field)

readr::write_csv(agreement, paths$agreement, na = "")

conflicts <- consensus_long |>
  dplyr::filter(consensus_level != "unanimity") |>
  dplyr::arrange(dplyr::desc(critical_field), pid, field)

adjudication <- consensus_long |>
  dplyr::filter(decision != "accept_provisionally") |>
  dplyr::arrange(dplyr::desc(critical_field), pid, field)

readr::write_csv(conflicts, paths$conflicts, na = "")
readr::write_csv(adjudication, paths$adjudication, na = "")

consensus_wide <- consensus_long |>
  dplyr::select(pid, field, consensus_value) |>
  tidyr::pivot_wider(names_from = field, values_from = consensus_value) |>
  dplyr::left_join(
    manifest |>
      dplyr::select(pid, title, year, journal_title, source_file, input_text_hash),
    by = "pid"
  ) |>
  dplyr::select(pid, title, year, journal_title, source_file, input_text_hash, dplyr::all_of(classification_fields))

readr::write_csv(consensus_wide, paths$consensus_wide, na = "")

previous_long <- previous_classification |>
  dplyr::select(pid, dplyr::all_of(classification_fields)) |>
  dplyr::mutate(
    dplyr::across(
      dplyr::all_of(classification_fields),
      ~ dplyr::if_else(is.na(.x), "<NULL>", as.character(.x))
    )
  ) |>
  tidyr::pivot_longer(cols = -pid, names_to = "field", values_to = "previous_value")

agent_previous_long <- agent_long |>
  dplyr::left_join(previous_long, by = c("pid", "field")) |>
  dplyr::mutate(matches_previous = valid_value & value == previous_value)

previous_agent <- agent_previous_long |>
  dplyr::group_by(agent_id, field) |>
  dplyr::summarise(
    n_articles = dplyr::n(),
    n_valid = sum(valid_value),
    n_matches_previous = sum(matches_previous, na.rm = TRUE),
    agreement_rate = dplyr::if_else(n_valid > 0, n_matches_previous / n_valid, NA_real_),
    .groups = "drop"
  ) |>
  dplyr::arrange(agent_id, agreement_rate, field)

readr::write_csv(previous_agent, paths$previous_agent, na = "")

previous_consensus <- consensus_long |>
  dplyr::left_join(previous_long, by = c("pid", "field")) |>
  dplyr::mutate(
    consensus_matches_previous = !is.na(consensus_value) & consensus_value == previous_value
  ) |>
  dplyr::group_by(field, critical_field) |>
  dplyr::summarise(
    n_articles = dplyr::n(),
    n_consensus_accepted = sum(!is.na(consensus_value)),
    n_matches_previous = sum(consensus_matches_previous, na.rm = TRUE),
    agreement_rate = dplyr::if_else(n_consensus_accepted > 0, n_matches_previous / n_consensus_accepted, NA_real_),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(critical_field), agreement_rate, field)

readr::write_csv(previous_consensus, paths$previous_consensus, na = "")

previous_disagreements <- agent_previous_long |>
  dplyr::filter(valid_value, !matches_previous) |>
  dplyr::left_join(
    manifest |>
      dplyr::select(pid, title, year, journal_title),
    by = "pid"
  ) |>
  dplyr::select(pid, title, year, journal_title, agent_id, field, value, previous_value) |>
  dplyr::arrange(field, pid, agent_id)

readr::write_csv(previous_disagreements, paths$previous_disagreements, na = "")

agent_bias_fields <- c(
  "is_empirical_quant_paper",
  "makes_explicit_causal_claim",
  "makes_implicit_causal_claim",
  "statement_of_identification_assumptions",
  "specifies_estimate_equations",
  "discusses_threats_to_causality",
  "evidence_type",
  "method_status",
  "main_causal_research_design"
)

previous_distribution <- previous_long |>
  dplyr::filter(field %in% agent_bias_fields) |>
  dplyr::count(field, value = previous_value, name = "previous_n") |>
  dplyr::group_by(field) |>
  dplyr::mutate(previous_share = previous_n / sum(previous_n)) |>
  dplyr::ungroup()

agent_bias_diagnostic <- agent_long |>
  dplyr::filter(field %in% agent_bias_fields, valid_value) |>
  dplyr::count(agent_id, field, value, name = "agent_n") |>
  dplyr::group_by(agent_id, field) |>
  dplyr::mutate(agent_share = agent_n / sum(agent_n)) |>
  dplyr::ungroup() |>
  dplyr::left_join(previous_distribution, by = c("field", "value")) |>
  dplyr::mutate(
    previous_n = dplyr::coalesce(previous_n, 0L),
    previous_share = dplyr::coalesce(previous_share, 0),
    share_minus_previous = agent_share - previous_share
  ) |>
  dplyr::arrange(field, value, agent_id)

readr::write_csv(agent_bias_diagnostic, paths$agent_bias_diagnostic, na = "")

agent_permissiveness <- agent_long |>
  dplyr::filter(valid_value) |>
  dplyr::mutate(
    permissive_signal = dplyr::case_when(
      field %in% c(
        "is_empirical_quant_paper",
        "seeks_determinants",
        "placebo_test",
        "makes_explicit_causal_claim",
        "makes_implicit_causal_claim",
        "claims_any_statistically_significant_results",
        "references_power_analysis",
        "clearly_defined_explanatory_variable",
        "specifies_estimate_equations",
        "discusses_threats_to_causality",
        "statement_of_identification_assumptions",
        "mentions_pre_registered_design_and_analysis_plan"
      ) ~ value == "TRUE",
      field == "paper_uses_survey_data" ~ value %in% c("runs_original_survey", "uses_public_available_survey"),
      field == "uses_original_dataset" ~ !value %in% c("<NULL>", "not_original"),
      field == "main_causal_research_design" ~ !value %in% c("<NULL>", "Other"),
      field == "clear_causal_quantity_of_interest" ~ !value %in% c("<NULL>", "FALSE"),
      field == "method_status" ~ value == "explicit",
      TRUE ~ NA
    )
  ) |>
  dplyr::filter(!is.na(permissive_signal)) |>
  dplyr::group_by(agent_id) |>
  dplyr::summarise(
    audited_signal_slots = dplyr::n(),
    permissive_signal_n = sum(permissive_signal),
    permissive_signal_rate = permissive_signal_n / audited_signal_slots,
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(permissive_signal_rate), agent_id)

readr::write_csv(agent_permissiveness, paths$agent_permissiveness, na = "")

read_fidelity_json <- function(audited_agent_id, pid) {
  audit_file <- file.path(pilot_dir, "fidelity_checker", audited_agent_id, paste0(pid, ".json"))
  rel_file <- stringr::str_remove(audit_file, paste0("^", stringr::fixed(project_dir), "/?"))
  if (!file.exists(audit_file)) {
    return(list(
      file_row = tibble(
        pid = pid,
        audited_agent_id = audited_agent_id,
        file = rel_file,
        audit_file_exists = FALSE,
        audit_file_valid = FALSE,
        overall_fidelity_status = NA_character_,
        classification_hash = NA_character_
      ),
      field_rows = tibble(
        pid = character(),
        audited_agent_id = character(),
        field = character(),
        status = character(),
        severity = character(),
        reason = character(),
        supporting_excerpt = character(),
        classification_value = character(),
        overall_fidelity_status = character(),
        file = character()
      )
    ))
  }
  obj <- tryCatch(
    jsonlite::fromJSON(audit_file, simplifyVector = FALSE),
    error = function(e) e
  )
  if (inherits(obj, "error") || !"field_audits" %in% names(obj) || !is.list(obj$field_audits)) {
    return(list(
      file_row = tibble(
        pid = pid,
        audited_agent_id = audited_agent_id,
        file = rel_file,
        audit_file_exists = TRUE,
        audit_file_valid = FALSE,
        overall_fidelity_status = NA_character_,
        classification_hash = NA_character_
      ),
      field_rows = tibble(
        pid = character(),
        audited_agent_id = character(),
        field = character(),
        status = character(),
        severity = character(),
        reason = character(),
        supporting_excerpt = character(),
        classification_value = character(),
        overall_fidelity_status = character(),
        file = character()
      )
    ))
  }
  field_rows <- purrr::map_dfr(obj$field_audits, function(item) {
    tibble(
      pid = pid,
      audited_agent_id = audited_agent_id,
      field = value_label(item$field),
      status = value_label(item$status),
      severity = value_label(item$severity),
      reason = value_label(item$reason),
      supporting_excerpt = if (is.null(item$supporting_excerpt)) NA_character_ else value_label(item$supporting_excerpt),
      classification_value = value_label(item$classification_value),
      overall_fidelity_status = value_label(obj$overall_fidelity_status),
      file = rel_file
    )
  })
  list(
    file_row = tibble(
      pid = pid,
      audited_agent_id = audited_agent_id,
      file = rel_file,
      audit_file_exists = TRUE,
      audit_file_valid = TRUE,
      overall_fidelity_status = value_label(obj$overall_fidelity_status),
      classification_hash = value_label(obj$classification_hash)
    ),
    field_rows = field_rows
  )
}

fidelity_nested <- purrr::map(agents, function(agent_id) {
  purrr::map(manifest$pid, function(pid) read_fidelity_json(agent_id, pid))
}) |>
  purrr::flatten()

fidelity_file_audits <- purrr::map_dfr(fidelity_nested, "file_row")
fidelity_field_audits <- purrr::map_dfr(fidelity_nested, "field_rows")

readr::write_csv(fidelity_file_audits, paths$fidelity_file_audits, na = "")
readr::write_csv(fidelity_field_audits, paths$fidelity_field_audits, na = "")

fidelity_agent_summary <- if (nrow(fidelity_field_audits) == 0) {
  tibble(
    audited_agent_id = agents,
    audited_fields = 0L,
    factual_fields = 0L,
    supported_factual_fields = 0L,
    factual_support_rate = NA_real_,
    contradicted_n = 0L,
    not_found_n = 0L,
    high_severity_n = 0L,
    medium_severity_n = 0L
  )
} else {
  fidelity_field_audits |>
    dplyr::mutate(
      factual_field = status != "not_a_factual_field",
      supported_factual = factual_field & status == "supported_by_text"
    ) |>
    dplyr::group_by(audited_agent_id) |>
    dplyr::summarise(
      audited_fields = dplyr::n(),
      factual_fields = sum(factual_field),
      supported_factual_fields = sum(supported_factual),
      factual_support_rate = dplyr::if_else(factual_fields > 0, supported_factual_fields / factual_fields, NA_real_),
      contradicted_n = sum(status == "contradicted_by_text"),
      not_found_n = sum(status == "not_found_in_text"),
      high_severity_n = sum(severity == "high"),
      medium_severity_n = sum(severity == "medium"),
      .groups = "drop"
    ) |>
    dplyr::arrange(factual_support_rate, audited_agent_id)
}

readr::write_csv(fidelity_agent_summary, paths$fidelity_agent_summary, na = "")

fidelity_agent_field_summary <- if (nrow(fidelity_field_audits) == 0) {
  tibble(
    audited_agent_id = character(),
    field = character(),
    audited_fields = integer(),
    factual_fields = integer(),
    supported_factual_fields = integer(),
    factual_support_rate = numeric(),
    contradicted_n = integer(),
    not_found_n = integer(),
    high_severity_n = integer(),
    medium_severity_n = integer()
  )
} else {
  fidelity_field_audits |>
    dplyr::mutate(
      factual_field = status != "not_a_factual_field",
      supported_factual = factual_field & status == "supported_by_text"
    ) |>
    dplyr::group_by(audited_agent_id, field) |>
    dplyr::summarise(
      audited_fields = dplyr::n(),
      factual_fields = sum(factual_field),
      supported_factual_fields = sum(supported_factual),
      factual_support_rate = dplyr::if_else(factual_fields > 0, supported_factual_fields / factual_fields, NA_real_),
      contradicted_n = sum(status == "contradicted_by_text"),
      not_found_n = sum(status == "not_found_in_text"),
      high_severity_n = sum(severity == "high"),
      medium_severity_n = sum(severity == "medium"),
      .groups = "drop"
    ) |>
    dplyr::arrange(factual_support_rate, dplyr::desc(high_severity_n), field, audited_agent_id)
}

readr::write_csv(fidelity_agent_field_summary, paths$fidelity_agent_field_summary, na = "")

fidelity_risk_fields <- fidelity_agent_field_summary |>
  dplyr::group_by(field) |>
  dplyr::summarise(
    audited_fields = sum(audited_fields),
    factual_fields = sum(factual_fields),
    supported_factual_fields = sum(supported_factual_fields),
    factual_support_rate = dplyr::if_else(factual_fields > 0, supported_factual_fields / factual_fields, NA_real_),
    contradicted_n = sum(contradicted_n),
    not_found_n = sum(not_found_n),
    high_severity_n = sum(high_severity_n),
    medium_severity_n = sum(medium_severity_n),
    .groups = "drop"
  ) |>
  dplyr::arrange(factual_support_rate, dplyr::desc(high_severity_n), dplyr::desc(medium_severity_n), field)

readr::write_csv(fidelity_risk_fields, paths$fidelity_risk_fields, na = "")

fidelity_severe_failures <- fidelity_field_audits |>
  dplyr::filter(
    severity %in% c("high", "medium") |
      status %in% c("contradicted_by_text", "not_found_in_text") |
      overall_fidelity_status == "fail"
  ) |>
  dplyr::left_join(
    manifest |>
      dplyr::select(pid, title, year, journal_title),
    by = "pid"
  ) |>
  dplyr::select(
    pid, title, year, journal_title, audited_agent_id, field, status, severity,
    overall_fidelity_status, reason, classification_value, supporting_excerpt, file
  ) |>
  dplyr::arrange(
    dplyr::desc(severity == "high"),
    dplyr::desc(status == "contradicted_by_text"),
    pid, audited_agent_id, field
  )

readr::write_csv(fidelity_severe_failures, paths$fidelity_severe_failures, na = "")

fidelity_priority <- fidelity_field_audits |>
  dplyr::filter(field %in% priority_factual_fields) |>
  dplyr::group_by(pid, field) |>
  dplyr::summarise(
    fidelity_issue_n = sum(status %in% c("contradicted_by_text", "not_found_in_text")),
    high_severity_n = sum(severity == "high"),
    medium_severity_n = sum(severity == "medium"),
    low_severity_n = sum(severity == "low"),
    fidelity_agents_with_issue = paste(sort(unique(audited_agent_id[status %in% c("contradicted_by_text", "not_found_in_text") | severity %in% c("high", "medium")])), collapse = "; "),
    fidelity_statuses = paste(sort(unique(status)), collapse = "; "),
    .groups = "drop"
  )

prioritized_adjudication <- consensus_long |>
  dplyr::filter(decision != "accept_provisionally" | field %in% priority_factual_fields) |>
  dplyr::left_join(fidelity_priority, by = c("pid", "field")) |>
  dplyr::mutate(
    fidelity_issue_n = dplyr::coalesce(fidelity_issue_n, 0L),
    high_severity_n = dplyr::coalesce(high_severity_n, 0L),
    medium_severity_n = dplyr::coalesce(medium_severity_n, 0L),
    low_severity_n = dplyr::coalesce(low_severity_n, 0L),
    fidelity_agents_with_issue = dplyr::coalesce(fidelity_agents_with_issue, ""),
    fidelity_statuses = dplyr::coalesce(fidelity_statuses, ""),
    disagreement_flag = decision != "accept_provisionally",
    priority_score =
      5L * high_severity_n +
      3L * medium_severity_n +
      1L * low_severity_n +
      2L * as.integer(disagreement_flag) +
      2L * as.integer(critical_field) +
      1L * fidelity_issue_n,
    adjudication_reason = dplyr::case_when(
      disagreement_flag & fidelity_issue_n > 0 ~ "desacordo_entre_agentes_e_falha_de_fidelidade",
      disagreement_flag ~ "desacordo_entre_agentes",
      fidelity_issue_n > 0 ~ "falha_de_fidelidade_textual",
      TRUE ~ "campo_factual_prioritario_sem_falha_registrada"
    )
  ) |>
  dplyr::filter(disagreement_flag | fidelity_issue_n > 0 | high_severity_n > 0 | medium_severity_n > 0) |>
  dplyr::arrange(dplyr::desc(priority_score), dplyr::desc(critical_field), pid, field)

readr::write_csv(prioritized_adjudication, paths$prioritized_adjudication, na = "")

overall <- tibble(
  metric = c(
    "artigos",
    "campos_de_classificacao",
    "decisoes_pid_campo",
    "unanimidade",
    "maioria_2_contra_1_nao_critica",
    "adjudicacao_total",
    "adjudicacao_campos_criticos",
    "erros_schema_classificacao",
    "auditorias_fidelidade_esperadas",
    "auditorias_fidelidade_presentes",
    "erros_schema_fidelidade"
  ),
  value = c(
    nrow(manifest),
    length(classification_fields),
    nrow(consensus_long),
    sum(consensus_long$consensus_level == "unanimity"),
    sum(consensus_long$consensus_level == "majority"),
    sum(consensus_long$decision != "accept_provisionally"),
    sum(consensus_long$decision != "accept_provisionally" & consensus_long$critical_field),
    sum(validation_issues$severity == "ERROR", na.rm = TRUE),
    nrow(manifest) * length(agents),
    sum(fidelity_file_audits$audit_file_exists),
    sum(fidelity_validation_issues$severity == "ERROR", na.rm = TRUE)
  )
) |>
  dplyr::mutate(rate = value / dplyr::case_when(
    metric %in% c("unanimidade", "maioria_2_contra_1_nao_critica", "adjudicacao_total") ~ nrow(consensus_long),
    metric == "adjudicacao_campos_criticos" ~ sum(consensus_long$critical_field),
    metric == "auditorias_fidelidade_presentes" ~ nrow(manifest) * length(agents),
    TRUE ~ NA_real_
  ))

input_quality <- tibble(
  metric = c(
    "fonte_canonica",
    "coluna_canonica",
    "fonte_canonica_presente",
    "body_canonico_preenchido",
    "hash_body_preenchido",
    "pacotes_derivados"
  ),
  value = c(
    unique(manifest$source_file)[1],
    unique(manifest$source_column)[1],
    as.character(sum(manifest$source_file_exists, na.rm = TRUE)),
    as.character(nrow(manifest)),
    as.character(sum(!is.na(manifest$input_text_hash))),
    as.character(sum(file.exists(file.path(project_dir, manifest$task_packet_file))))
  )
)

critical_adjudication_rate <- sum(consensus_long$decision != "accept_provisionally" & consensus_long$critical_field) /
  sum(consensus_long$critical_field)

classification_error_count <- sum(validation_issues$severity == "ERROR", na.rm = TRUE)
fidelity_error_count <- sum(fidelity_validation_issues$severity == "ERROR", na.rm = TRUE)
missing_fidelity_count <- sum(!fidelity_file_audits$audit_file_exists)
high_fidelity_count <- sum(fidelity_agent_summary$high_severity_n, na.rm = TRUE)
medium_fidelity_count <- sum(fidelity_agent_summary$medium_severity_n, na.rm = TRUE)
fidelity_fail_count <- sum(fidelity_file_audits$overall_fidelity_status == "fail", na.rm = TRUE)

recommendation <- dplyr::case_when(
  classification_error_count > 0 ~ "nao_escalar_outputs_de_classificacao_invalidos",
  fidelity_error_count > 0 | missing_fidelity_count > 0 ~ "nao_escalar_auditoria_de_fidelidade_incompleta_ou_invalida",
  fidelity_fail_count > 0 | high_fidelity_count > 0 ~ "nao_escalar_antes_de_adjudicar_falhas_graves_de_fidelidade",
  critical_adjudication_rate > 0.10 ~ "revisar_manualmente_campos_criticos_antes_de_escalar",
  medium_fidelity_count > 0 ~ "escalar_somente_com_adjudicacao_previa_dos_campos_factuais_de_risco",
  TRUE ~ "escalar_com_monitoramento_de_fidelidade_e_adjudicacao_amostral"
)

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

unstable_fields <- agreement |>
  dplyr::filter(adjudication_rate > 0 | unanimity_rate < 0.80) |>
  dplyr::arrange(dplyr::desc(critical_field), dplyr::desc(adjudication_rate), unanimity_rate) |>
  dplyr::select(field, critical_field, unanimity_rate, majority_rate, adjudication_rate, invalid_or_missing_n)

previous_weak_fields <- previous_consensus |>
  dplyr::filter(is.na(agreement_rate) | agreement_rate < 0.90) |>
  dplyr::arrange(dplyr::desc(critical_field), agreement_rate, field) |>
  dplyr::select(field, critical_field, n_consensus_accepted, agreement_rate)

agent_bias_highlights <- agent_bias_diagnostic |>
  dplyr::filter(abs(share_minus_previous) >= 0.10) |>
  dplyr::arrange(dplyr::desc(abs(share_minus_previous)), field, value, agent_id) |>
  dplyr::select(agent_id, field, value, agent_share, previous_share, share_minus_previous)

top_fidelity_failures <- fidelity_severe_failures |>
  dplyr::filter(severity == "high" | overall_fidelity_status == "fail") |>
  dplyr::select(pid, title, audited_agent_id, field, status, severity, reason)

report_lines <- c(
  "# Relatório final do piloto v2 de classificação tripla",
  "",
  paste("Gerado em", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Recomendação objetiva",
  "",
  paste0("`", recommendation, "`"),
  "",
  "Regra documentada: não escalar enquanto houver JSON ausente/inválido, auditoria de fidelidade incompleta, falha textual grave ou fila crítica relevante sem adjudicação. A classificação anterior entra apenas como diagnóstico, porque foi feita sem body integral.",
  "",
  "## Snapshot geral",
  "",
  markdown_table(overall),
  "",
  "## Qualidade do insumo textual",
  "",
  markdown_table(input_quality),
  "",
  "Interpretação: a v2 usa o `body_text` integral canônico de `article_texts_gold.csv`. Os pacotes por PID são derivados desse CSV e servem apenas para leitura pelos subagentes.",
  "",
  "## Acordo entre agentes A/B/C por campo",
  "",
  markdown_table(agreement, max_rows = 40),
  "",
  "## Campos instáveis",
  "",
  markdown_table(unstable_fields, max_rows = 40),
  "",
  "## Fidelidade textual do Agente D",
  "",
  markdown_table(fidelity_agent_summary),
  "",
  "## Campos com maior risco de invenção",
  "",
  markdown_table(fidelity_risk_fields, max_rows = 40),
  "",
  "## PIDs com falhas graves de fidelidade",
  "",
  markdown_table(top_fidelity_failures, max_rows = 40),
  "",
  "## Agentes mais permissivos",
  "",
  markdown_table(agent_permissiveness),
  "",
  "## Fila de adjudicação priorizada",
  "",
  markdown_table(
    prioritized_adjudication |>
      dplyr::select(pid, title, field, critical_field, consensus_level, priority_score, adjudication_reason, fidelity_agents_with_issue),
    max_rows = 50
  ),
  "",
  "## Comparação diagnóstica contra a classificação anterior",
  "",
  "A rodada anterior foi feita sem body integral. As tabelas abaixo medem divergência operacional, não validam a v2 contra um gold substantivo.",
  "",
  "### Acordo do consenso v2 contra a rodada anterior",
  "",
  markdown_table(previous_consensus, max_rows = 40),
  "",
  "### Campos com divergência diagnóstica elevada",
  "",
  markdown_table(previous_weak_fields, max_rows = 40),
  "",
  "### Sinais diagnósticos de rigor/permissividade contra a rodada anterior",
  "",
  markdown_table(agent_bias_highlights, max_rows = 40),
  "",
  "## Arquivos gerados",
  "",
  paste0("- `", stringr::str_remove(paths$agreement, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$consensus_long, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$consensus_wide, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$conflicts, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$adjudication, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$prioritized_adjudication, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$previous_agent, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$previous_consensus, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$previous_disagreements, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$agent_bias_diagnostic, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$agent_permissiveness, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$fidelity_file_audits, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$fidelity_field_audits, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$fidelity_agent_summary, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$fidelity_agent_field_summary, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$fidelity_risk_fields, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$fidelity_severe_failures, paste0("^", stringr::fixed(project_dir), "/?")), "`")
)

writeLines(report_lines, paths$report, useBytes = TRUE)

cat("Comparacao v2 concluida.\n")
cat("Recomendacao:", recommendation, "\n")
cat("Relatorio:", paths$report, "\n")
