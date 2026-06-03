## 12_compare_full_classification_pilot.R
## Compara classificacoes dos tres subagentes e valida consenso contra gold/piloto.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

project_dir <- normalizePath(".", mustWork = TRUE)
pilot_dir <- file.path(project_dir, "data", "processed", "full_classification_pilot")
comparison_dir <- file.path(pilot_dir, "comparison")
dir.create(comparison_dir, showWarnings = FALSE, recursive = TRUE)

paths <- list(
  manifest = file.path(pilot_dir, "pilot_manifest.csv"),
  gold = file.path(project_dir, "data", "processed", "classifications_llm_main_analysis.csv"),
  validation_issues = file.path(project_dir, "quality_reports", "full_classification_pilot_validation_issues.csv"),
  agreement = file.path(comparison_dir, "agent_field_agreement.csv"),
  consensus_long = file.path(comparison_dir, "consensus_field_decisions.csv"),
  consensus_wide = file.path(comparison_dir, "consensus_classifications.csv"),
  conflicts = file.path(comparison_dir, "conflicts.csv"),
  adjudication = file.path(comparison_dir, "adjudication_queue.csv"),
  gold_agent = file.path(comparison_dir, "gold_agreement_by_agent_field.csv"),
  gold_consensus = file.path(comparison_dir, "gold_agreement_consensus_by_field.csv"),
  gold_disagreements = file.path(comparison_dir, "gold_disagreements.csv"),
  agent_bias = file.path(comparison_dir, "agent_bias_summary.csv"),
  report = file.path(project_dir, "quality_reports", "full_classification_pilot_agreement_report.md")
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

if (!file.exists(paths$manifest)) {
  stop("Manifest ausente. Rode scripts/10_prepare_full_classification_pilot.R primeiro.")
}
if (!file.exists(paths$gold)) {
  stop("Gold/piloto ausente: ", paths$gold)
}

manifest <- readr::read_csv(paths$manifest, show_col_types = FALSE, progress = FALSE)
gold <- readr::read_csv(paths$gold, show_col_types = FALSE, progress = FALSE)
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

agent_wide <- agent_long |>
  dplyr::select(pid, agent_id, field, value, valid_value) |>
  tidyr::pivot_wider(
    names_from = agent_id,
    values_from = c(value, valid_value),
    names_sep = "__"
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

gold_long <- gold |>
  dplyr::select(pid, dplyr::all_of(classification_fields)) |>
  dplyr::mutate(
    dplyr::across(
      dplyr::all_of(classification_fields),
      ~ dplyr::if_else(is.na(.x), "<NULL>", as.character(.x))
    )
  ) |>
  tidyr::pivot_longer(cols = -pid, names_to = "field", values_to = "gold_value")

agent_gold_long <- agent_long |>
  dplyr::left_join(gold_long, by = c("pid", "field")) |>
  dplyr::mutate(matches_gold = valid_value & value == gold_value)

gold_agent <- agent_gold_long |>
  dplyr::group_by(agent_id, field) |>
  dplyr::summarise(
    n_articles = dplyr::n(),
    n_valid = sum(valid_value),
    n_matches_gold = sum(matches_gold, na.rm = TRUE),
    agreement_rate = dplyr::if_else(n_valid > 0, n_matches_gold / n_valid, NA_real_),
    .groups = "drop"
  ) |>
  dplyr::arrange(agent_id, agreement_rate, field)

readr::write_csv(gold_agent, paths$gold_agent, na = "")

gold_consensus <- consensus_long |>
  dplyr::left_join(gold_long, by = c("pid", "field")) |>
  dplyr::mutate(
    consensus_matches_gold = !is.na(consensus_value) & consensus_value == gold_value
  ) |>
  dplyr::group_by(field, critical_field) |>
  dplyr::summarise(
    n_articles = dplyr::n(),
    n_consensus_accepted = sum(!is.na(consensus_value)),
    n_matches_gold = sum(consensus_matches_gold, na.rm = TRUE),
    agreement_rate = dplyr::if_else(n_consensus_accepted > 0, n_matches_gold / n_consensus_accepted, NA_real_),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(critical_field), agreement_rate, field)

readr::write_csv(gold_consensus, paths$gold_consensus, na = "")

gold_disagreements <- agent_gold_long |>
  dplyr::filter(valid_value, !matches_gold) |>
  dplyr::left_join(
    manifest |>
      dplyr::select(pid, title, year, journal_title),
    by = "pid"
  ) |>
  dplyr::select(pid, title, year, journal_title, agent_id, field, value, gold_value) |>
  dplyr::arrange(field, pid, agent_id)

readr::write_csv(gold_disagreements, paths$gold_disagreements, na = "")

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

gold_distribution <- gold_long |>
  dplyr::filter(field %in% agent_bias_fields) |>
  dplyr::count(field, value = gold_value, name = "gold_n") |>
  dplyr::group_by(field) |>
  dplyr::mutate(gold_share = gold_n / sum(gold_n)) |>
  dplyr::ungroup()

agent_bias <- agent_long |>
  dplyr::filter(field %in% agent_bias_fields, valid_value) |>
  dplyr::count(agent_id, field, value, name = "agent_n") |>
  dplyr::group_by(agent_id, field) |>
  dplyr::mutate(agent_share = agent_n / sum(agent_n)) |>
  dplyr::ungroup() |>
  dplyr::left_join(gold_distribution, by = c("field", "value")) |>
  dplyr::mutate(
    gold_n = dplyr::coalesce(gold_n, 0L),
    gold_share = dplyr::coalesce(gold_share, 0),
    share_minus_gold = agent_share - gold_share
  ) |>
  dplyr::arrange(field, value, agent_id)

readr::write_csv(agent_bias, paths$agent_bias, na = "")

overall <- tibble(
  metric = c(
    "pid_artigos",
    "campos_classificacao",
    "decisoes_pid_campo",
    "unanimidade",
    "maioria_2_contra_1_nao_critica",
    "adjudicacao_total",
    "adjudicacao_campos_criticos",
    "json_errors_validation"
  ),
  value = c(
    nrow(manifest),
    length(classification_fields),
    nrow(consensus_long),
    sum(consensus_long$consensus_level == "unanimity"),
    sum(consensus_long$consensus_level == "majority"),
    sum(consensus_long$decision != "accept_provisionally"),
    sum(consensus_long$decision != "accept_provisionally" & consensus_long$critical_field),
    sum(validation_issues$severity == "ERROR", na.rm = TRUE)
  )
) |>
  dplyr::mutate(rate = value / dplyr::case_when(
    metric %in% c("unanimidade", "maioria_2_contra_1_nao_critica", "adjudicacao_total") ~ nrow(consensus_long),
    metric == "adjudicacao_campos_criticos" ~ sum(consensus_long$critical_field),
    TRUE ~ NA_real_
  ))

input_quality <- tibble(
  metric = c(
    "xml_fonte_presentes",
    "xml_fonte_com_body",
    "raw_fulltext_presentes",
    "raw_fulltext_identico_ao_xml_fonte",
    "raw_fulltext_com_body"
  ),
  value = c(
    sum(manifest$source_file_exists, na.rm = TRUE),
    if ("source_has_body" %in% names(manifest)) sum(manifest$source_has_body, na.rm = TRUE) else NA_integer_,
    if ("raw_fulltext_file_exists" %in% names(manifest)) sum(manifest$raw_fulltext_file_exists, na.rm = TRUE) else NA_integer_,
    if ("raw_fulltext_same_hash" %in% names(manifest)) sum(manifest$raw_fulltext_same_hash, na.rm = TRUE) else NA_integer_,
    if ("raw_fulltext_has_body" %in% names(manifest)) sum(manifest$raw_fulltext_has_body, na.rm = TRUE) else NA_integer_
  )
)

critical_gold_rates <- gold_consensus |>
  dplyr::filter(critical_field, !is.na(agreement_rate)) |>
  dplyr::pull(agreement_rate)

critical_gold_min <- if (length(critical_gold_rates) == 0L) {
  NA_real_
} else {
  min(critical_gold_rates)
}

critical_adjudication_rate <- sum(consensus_long$decision != "accept_provisionally" & consensus_long$critical_field) /
  sum(consensus_long$critical_field)

recommendation <- dplyr::case_when(
  sum(validation_issues$severity == "ERROR", na.rm = TRUE) > 0 ~ "nao_escalar_outputs_incompletos_ou_invalidos",
  is.na(critical_gold_min) ~ "nao_escalar_sem_consenso_validado_contra_gold",
  critical_adjudication_rate > 0.10 ~ "revisar_manualmente_campos_criticos",
  critical_gold_min < 0.90 ~ "ajustar_prompt_schema",
  TRUE ~ "escalar"
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

gold_weak_fields <- gold_consensus |>
  dplyr::filter(is.na(agreement_rate) | agreement_rate < 0.90) |>
  dplyr::arrange(dplyr::desc(critical_field), agreement_rate, field) |>
  dplyr::select(field, critical_field, n_consensus_accepted, agreement_rate)

agent_bias_highlights <- agent_bias |>
  dplyr::filter(abs(share_minus_gold) >= 0.10) |>
  dplyr::arrange(dplyr::desc(abs(share_minus_gold)), field, value, agent_id) |>
  dplyr::select(agent_id, field, value, agent_share, gold_share, share_minus_gold)

report_lines <- c(
  "# Relatorio do piloto de classificacao tripla",
  "",
  paste("Gerado em", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Recomendacao objetiva",
  "",
  paste0("`", recommendation, "`"),
  "",
  "Regra documentada: nao escalar enquanto houver JSON ausente/invalido, fila critica relevante, ou acordo contra gold abaixo do patamar operacional nos campos criticos.",
  "",
  "## Snapshot geral",
  "",
  markdown_table(overall),
  "",
  "## Qualidade do insumo textual",
  "",
  markdown_table(input_quality),
  "",
  "Interpretacao: se `xml_fonte_com_body` e `raw_fulltext_com_body` forem zero, o piloto avaliou classificacoes feitas sobre o texto local disponivel nos XMLs, nao sobre o corpo integral dos artigos.",
  "",
  "## Acordo por campo",
  "",
  markdown_table(agreement, max_rows = 40),
  "",
  "## Campos instaveis",
  "",
  markdown_table(unstable_fields, max_rows = 40),
  "",
  "## Comparacao do consenso contra gold",
  "",
  markdown_table(gold_consensus, max_rows = 40),
  "",
  "## Campos com acordo fraco contra gold",
  "",
  markdown_table(gold_weak_fields, max_rows = 40),
  "",
  "## Sinais de rigor/permissividade por agente",
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
  paste0("- `", stringr::str_remove(paths$gold_agent, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$gold_consensus, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$gold_disagreements, paste0("^", stringr::fixed(project_dir), "/?")), "`"),
  paste0("- `", stringr::str_remove(paths$agent_bias, paste0("^", stringr::fixed(project_dir), "/?")), "`")
)

writeLines(report_lines, paths$report, useBytes = TRUE)

cat("Comparacao concluida.\n")
cat("Recomendacao:", recommendation, "\n")
cat("Relatorio:", paths$report, "\n")
