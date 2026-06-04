## 20_evaluate_full_classification_pilot_v2_all_fields_against_manual_gold.R
## Avalia todos os campos do piloto v2 contra a classificacao manual/gold.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(tidyr)
})

project_dir <- normalizePath(".", mustWork = TRUE)
pilot_dir <- file.path(project_dir, "data", "processed", "full_classification_pilot_v2")
comparison_dir <- file.path(pilot_dir, "comparison")
quality_dir <- file.path(project_dir, "quality_reports")
dir.create(comparison_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(quality_dir, showWarnings = FALSE, recursive = TRUE)

paths <- list(
  gold = file.path(project_dir, "data", "processed", "classifications_llm_main_analysis.csv"),
  manifest = file.path(pilot_dir, "pilot_manifest.csv"),
  all_field_summary = file.path(comparison_dir, "manual_gold_all_fields_performance_by_agent_field.csv"),
  binary_summary = file.path(comparison_dir, "manual_gold_binary_fields_performance_by_agent_field.csv"),
  prediction_long = file.path(comparison_dir, "manual_gold_all_fields_predictions_long.csv"),
  agent_overall = file.path(comparison_dir, "manual_gold_all_fields_agent_overall_summary.csv"),
  field_overall = file.path(comparison_dir, "manual_gold_all_fields_field_overall_summary.csv"),
  report = file.path(quality_dir, "full_classification_pilot_v2_manual_gold_all_fields_performance.md")
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

binary_fields <- c(
  "is_empirical_quant_paper",
  "seeks_determinants",
  "placebo_test",
  "makes_explicit_causal_claim",
  "makes_implicit_causal_claim",
  "strong_non_causal_causal_qualification",
  "claims_any_statistically_significant_results",
  "references_power_analysis",
  "clearly_defined_explanatory_variable",
  "clear_causal_quantity_of_interest",
  "specifies_estimate_equations",
  "discusses_threats_to_causality",
  "statement_of_identification_assumptions",
  "mentions_pre_registered_design_and_analysis_plan"
)

field_type <- tibble::tibble(
  field = classification_fields,
  field_type = dplyr::case_when(
    field %in% binary_fields ~ "binary",
    field %in% c(
      "subfield", "general_goal_of_analysis", "main_causal_research_design",
      "other_research_design", "effort_to_explore_mechanisms",
      "evidence_type", "method_status", "error_in_raw_text",
      "single_country_study", "single_region", "paper_uses_survey_data",
      "uses_original_dataset"
    ) ~ "categorical",
    TRUE ~ "text_or_structured_exact"
  )
)

read_csv_char <- function(path) {
  if (!file.exists(path)) {
    stop("Arquivo ausente: ", path)
  }
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    na = c("", "NA"),
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "UTF-8")
  )
}

normalize_label <- function(x) {
  x <- stringr::str_squish(as.character(x))
  x[is.na(x) | !nzchar(x) | toupper(x) == "NA"] <- NA_character_
  x_lower <- tolower(x)
  x <- dplyr::case_when(
    is.na(x) ~ "NULL",
    x_lower == "true" ~ "TRUE",
    x_lower == "false" ~ "FALSE",
    x_lower == "null" ~ "NULL",
    TRUE ~ x
  )
  x
}

as_positive <- function(label) {
  label == "TRUE"
}

safe_div <- function(num, den) {
  ifelse(den > 0, num / den, NA_real_)
}

fmt_pct <- function(x, digits = 1) {
  ifelse(
    is.na(x),
    "NA",
    paste0(formatC(100 * x, format = "f", digits = digits, decimal.mark = ","), "%")
  )
}

fmt_num <- function(x, digits = 3) {
  ifelse(
    is.na(x),
    "NA",
    formatC(x, format = "f", digits = digits, decimal.mark = ",")
  )
}

markdown_table <- function(df, digits = 3, max_rows = Inf) {
  if (nrow(df) == 0) {
    return("_Nenhum registro._")
  }
  df2 <- as.data.frame(utils::head(df, max_rows))
  df2[] <- lapply(df2, function(x) {
    if (is.numeric(x)) {
      fmt_num(x, digits = digits)
    } else {
      as.character(x)
    }
  })
  header <- paste0("| ", paste(names(df2), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df2)), collapse = " | "), " |")
  rows <- apply(df2, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

gold <- read_csv_char(paths$gold)
manifest <- read_csv_char(paths$manifest) |>
  dplyr::select(pid, title, year, journal_title)

missing_gold_fields <- setdiff(c("pid", classification_fields), names(gold))
if (length(missing_gold_fields) > 0L) {
  stop("Colunas ausentes no gold: ", paste(missing_gold_fields, collapse = ", "))
}

gold_long <- gold |>
  dplyr::select(pid, dplyr::all_of(classification_fields)) |>
  tidyr::pivot_longer(
    cols = dplyr::all_of(classification_fields),
    names_to = "field",
    values_to = "gold_raw"
  ) |>
  dplyr::mutate(
    gold_label = normalize_label(gold_raw),
    gold_non_null = gold_label != "NULL"
  )

read_agent_long <- function(agent_id) {
  path <- file.path(pilot_dir, paste0(agent_id, "_classifications.csv"))
  agent_data <- read_csv_char(path)
  missing_agent_fields <- setdiff(c("pid", classification_fields), names(agent_data))
  if (length(missing_agent_fields) > 0L) {
    stop("Colunas ausentes em ", path, ": ", paste(missing_agent_fields, collapse = ", "))
  }
  agent_data |>
    dplyr::select(pid, dplyr::all_of(classification_fields)) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(classification_fields),
      names_to = "field",
      values_to = "pred_raw"
    ) |>
    dplyr::mutate(
      agent_id = agent_id,
      pred_label = normalize_label(pred_raw),
      pred_non_null = pred_label != "NULL"
    )
}

predictions <- dplyr::bind_rows(lapply(agents, read_agent_long)) |>
  dplyr::left_join(gold_long, by = c("pid", "field")) |>
  dplyr::left_join(field_type, by = "field") |>
  dplyr::left_join(manifest, by = "pid") |>
  dplyr::mutate(
    exact_match = pred_label == gold_label,
    labeled_match = gold_non_null & exact_match,
    binary_evaluable = field %in% binary_fields & gold_label %in% c("TRUE", "FALSE"),
    gold_positive = as_positive(gold_label),
    pred_positive = as_positive(pred_label),
    binary_match = binary_evaluable & pred_positive == gold_positive,
    binary_outcome = dplyr::case_when(
      !binary_evaluable ~ "not_binary_evaluable",
      pred_positive & gold_positive ~ "TP",
      pred_positive & !gold_positive ~ "FP",
      !pred_positive & !gold_positive ~ "TN",
      !pred_positive & gold_positive ~ "FN",
      TRUE ~ "other"
    )
  ) |>
  dplyr::select(
    pid, title, year, journal_title, agent_id, field, field_type,
    gold_label, pred_label, exact_match, labeled_match,
    gold_non_null, pred_non_null,
    binary_evaluable, gold_positive, pred_positive,
    binary_match, binary_outcome
  )

all_field_summary <- predictions |>
  dplyr::group_by(agent_id, field, field_type) |>
  dplyr::summarise(
    n_total = dplyr::n(),
    gold_non_null_n = sum(gold_non_null),
    gold_null_n = sum(!gold_non_null),
    pred_non_null_n = sum(pred_non_null),
    pred_null_n = sum(!pred_non_null),
    pred_coverage_non_null = pred_non_null_n / n_total,
    exact_matches = sum(exact_match),
    exact_accuracy_all = exact_matches / n_total,
    exact_matches_when_gold_non_null = sum(labeled_match),
    exact_accuracy_gold_non_null = safe_div(exact_matches_when_gold_non_null, gold_non_null_n),
    gold_distinct_values = dplyr::n_distinct(gold_label),
    pred_distinct_values = dplyr::n_distinct(pred_label),
    .groups = "drop"
  ) |>
  dplyr::arrange(field_type, field, dplyr::desc(exact_accuracy_all), agent_id)

binary_summary <- predictions |>
  dplyr::filter(field %in% binary_fields) |>
  dplyr::group_by(agent_id, field) |>
  dplyr::summarise(
    n_total = dplyr::n(),
    n_binary = sum(binary_evaluable),
    gold_true = sum(binary_evaluable & gold_label == "TRUE"),
    gold_false = sum(binary_evaluable & gold_label == "FALSE"),
    gold_null_or_nonbinary = n_total - n_binary,
    pred_true = sum(pred_label == "TRUE"),
    pred_false = sum(pred_label == "FALSE"),
    pred_null_or_nonbinary = sum(!pred_label %in% c("TRUE", "FALSE")),
    tp = sum(binary_outcome == "TP"),
    fp = sum(binary_outcome == "FP"),
    tn = sum(binary_outcome == "TN"),
    fn = sum(binary_outcome == "FN"),
    binary_accuracy = safe_div(tp + tn, n_binary),
    precision = safe_div(tp, tp + fp),
    recall_sensitivity = safe_div(tp, tp + fn),
    specificity = safe_div(tn, tn + fp),
    negative_predictive_value = safe_div(tn, tn + fn),
    f1 = safe_div(2 * precision * recall_sensitivity, precision + recall_sensitivity),
    balanced_accuracy = (recall_sensitivity + specificity) / 2,
    false_positive_rate = safe_div(fp, fp + tn),
    false_negative_rate = safe_div(fn, fn + tp),
    .groups = "drop"
  ) |>
  dplyr::arrange(field, dplyr::desc(f1), dplyr::desc(balanced_accuracy), agent_id)

agent_overall <- all_field_summary |>
  dplyr::group_by(agent_id, field_type) |>
  dplyr::summarise(
    fields = dplyr::n(),
    mean_exact_accuracy_all = mean(exact_accuracy_all, na.rm = TRUE),
    median_exact_accuracy_all = stats::median(exact_accuracy_all, na.rm = TRUE),
    mean_exact_accuracy_gold_non_null = mean(exact_accuracy_gold_non_null, na.rm = TRUE),
    mean_pred_coverage_non_null = mean(pred_coverage_non_null, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::arrange(field_type, dplyr::desc(mean_exact_accuracy_all), agent_id)

field_overall <- all_field_summary |>
  dplyr::group_by(field, field_type) |>
  dplyr::summarise(
    mean_exact_accuracy_all = mean(exact_accuracy_all, na.rm = TRUE),
    max_exact_accuracy_all = max(exact_accuracy_all, na.rm = TRUE),
    best_agent = agent_id[which.max(exact_accuracy_all)][[1]],
    mean_exact_accuracy_gold_non_null = mean(exact_accuracy_gold_non_null, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::arrange(mean_exact_accuracy_all, field)

readr::write_csv(all_field_summary, paths$all_field_summary, na = "")
readr::write_csv(binary_summary, paths$binary_summary, na = "")
readr::write_csv(predictions, paths$prediction_long, na = "")
readr::write_csv(agent_overall, paths$agent_overall, na = "")
readr::write_csv(field_overall, paths$field_overall, na = "")

display_agent_overall <- agent_overall |>
  dplyr::mutate(
    mean_exact_accuracy_all = fmt_pct(mean_exact_accuracy_all),
    median_exact_accuracy_all = fmt_pct(median_exact_accuracy_all),
    mean_exact_accuracy_gold_non_null = fmt_pct(mean_exact_accuracy_gold_non_null),
    mean_pred_coverage_non_null = fmt_pct(mean_pred_coverage_non_null)
  )

display_all_top <- all_field_summary |>
  dplyr::arrange(field_type, field, dplyr::desc(exact_accuracy_all)) |>
  dplyr::mutate(
    pred_coverage_non_null = fmt_pct(pred_coverage_non_null),
    exact_accuracy_all = fmt_pct(exact_accuracy_all),
    exact_accuracy_gold_non_null = fmt_pct(exact_accuracy_gold_non_null)
  ) |>
  dplyr::select(
    agent_id, field, field_type, gold_non_null_n, pred_non_null_n,
    pred_coverage_non_null, exact_matches, exact_accuracy_all,
    exact_accuracy_gold_non_null
  )

display_binary <- binary_summary |>
  dplyr::mutate(
    binary_accuracy = fmt_pct(binary_accuracy),
    precision = fmt_pct(precision),
    recall_sensitivity = fmt_pct(recall_sensitivity),
    specificity = fmt_pct(specificity),
    f1 = fmt_pct(f1),
    balanced_accuracy = fmt_pct(balanced_accuracy)
  ) |>
  dplyr::select(
    agent_id, field, n_binary, gold_true, gold_false,
    tp, fp, tn, fn, binary_accuracy, precision,
    recall_sensitivity, specificity, f1, balanced_accuracy
  )

display_weak_fields <- field_overall |>
  dplyr::mutate(
    mean_exact_accuracy_all = fmt_pct(mean_exact_accuracy_all),
    max_exact_accuracy_all = fmt_pct(max_exact_accuracy_all),
    mean_exact_accuracy_gold_non_null = fmt_pct(mean_exact_accuracy_gold_non_null)
  ) |>
  dplyr::select(
    field, field_type, best_agent, mean_exact_accuracy_all,
    max_exact_accuracy_all, mean_exact_accuracy_gold_non_null
  ) |>
  dplyr::slice_head(n = 20)

display_best_binary <- binary_summary |>
  dplyr::group_by(field) |>
  dplyr::slice_max(order_by = f1, n = 1, with_ties = FALSE) |>
  dplyr::ungroup() |>
  dplyr::arrange(field) |>
  dplyr::mutate(
    precision = fmt_pct(precision),
    recall_sensitivity = fmt_pct(recall_sensitivity),
    specificity = fmt_pct(specificity),
    f1 = fmt_pct(f1),
    balanced_accuracy = fmt_pct(balanced_accuracy)
  ) |>
  dplyr::select(
    field, best_agent = agent_id, n_binary, gold_true, gold_false,
    tp, fp, tn, fn, precision, recall_sensitivity,
    specificity, f1, balanced_accuracy
  )

report_lines <- c(
  "# Performance dos agentes v2 contra classifica\u00e7\u00e3o manual/gold: todos os campos",
  "",
  paste0("Gerado em ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Fonte da ground truth",
  "",
  "- Ground truth: `data/processed/classifications_llm_main_analysis.csv`.",
  "- A documenta\u00e7\u00e3o descreve esse arquivo como a amostra classificada validada de 175 artigos ap\u00f3s exclus\u00f5es e como gold/piloto para avalia\u00e7\u00e3o do piloto triplo.",
  "",
  "## Como ler",
  "",
  "- Para todos os campos, `exact_accuracy_all` mede igualdade literal entre agente e ground truth, incluindo `NULL`.",
  "- Para campos textuais ou estruturados (`independent_variables`, `dependent_variables`, `brief_justification`, quotes etc.), igualdade literal \u00e9 uma m\u00e9trica muito dura e deve ser lida como diagn\u00f3stico operacional, n\u00e3o como qualidade sem\u00e2ntica final.",
  "- Para campos bin\u00e1rios, `TRUE` \u00e9 o positivo; `FALSE` e `NULL` do agente contam como negativo nas m\u00e9tricas bin\u00e1rias quando o gold \u00e9 `TRUE`/`FALSE`.",
  "",
  "## Resumo por agente e tipo de campo",
  "",
  markdown_table(display_agent_overall, digits = 3),
  "",
  "## Melhor agente por campo bin\u00e1rio",
  "",
  markdown_table(display_best_binary, digits = 3),
  "",
  "## M\u00e9tricas bin\u00e1rias por agente e campo",
  "",
  markdown_table(display_binary, digits = 3),
  "",
  "## Campos com menor acur\u00e1cia exata m\u00e9dia",
  "",
  markdown_table(display_weak_fields, digits = 3),
  "",
  "## Acur\u00e1cia exata por agente e campo",
  "",
  markdown_table(display_all_top, digits = 3),
  "",
  "## Arquivos gerados",
  "",
  paste0("- `", sub(paste0("^", project_dir, "/?"), "", paths$all_field_summary), "`"),
  paste0("- `", sub(paste0("^", project_dir, "/?"), "", paths$binary_summary), "`"),
  paste0("- `", sub(paste0("^", project_dir, "/?"), "", paths$prediction_long), "`"),
  paste0("- `", sub(paste0("^", project_dir, "/?"), "", paths$agent_overall), "`"),
  paste0("- `", sub(paste0("^", project_dir, "/?"), "", paths$field_overall), "`")
)

writeLines(report_lines, paths$report, useBytes = TRUE)

cat("Gold:", sub(paste0("^", project_dir, "/?"), "", paths$gold), "\n")
cat("Resumo all-fields:", sub(paste0("^", project_dir, "/?"), "", paths$all_field_summary), "\n")
cat("Resumo binary:", sub(paste0("^", project_dir, "/?"), "", paths$binary_summary), "\n")
cat("Relatorio:", sub(paste0("^", project_dir, "/?"), "", paths$report), "\n")
