## 19_evaluate_full_classification_pilot_v2_against_manual_gold.R
## Avalia agentes do piloto v2 contra a classificacao manual/gold dos 175 artigos.

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
  agent_summary = file.path(comparison_dir, "manual_gold_causal_claim_performance_by_agent_field.csv"),
  confusion = file.path(comparison_dir, "manual_gold_causal_claim_confusion_by_agent_field.csv"),
  prediction_long = file.path(comparison_dir, "manual_gold_causal_claim_predictions_long.csv"),
  consensus_summary = file.path(comparison_dir, "manual_gold_causal_claim_consensus_performance.csv"),
  report = file.path(quality_dir, "full_classification_pilot_v2_manual_gold_causal_claim_performance.md")
)

fields <- c("makes_explicit_causal_claim", "makes_implicit_causal_claim")
agents <- c("agent_a", "agent_b", "agent_c")

read_csv_utf8 <- function(path) {
  if (!file.exists(path)) {
    stop("Arquivo ausente: ", path)
  }
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    na = c("", "NA"),
    locale = readr::locale(encoding = "UTF-8")
  )
}

label_value <- function(x) {
  dplyr::case_when(
    is.na(x) ~ "NULL",
    x == TRUE ~ "TRUE",
    x == FALSE ~ "FALSE",
    TRUE ~ as.character(x)
  )
}

as_positive <- function(x) {
  out <- x == TRUE
  out[is.na(out)] <- FALSE
  out
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

markdown_table <- function(df, digits = 3) {
  if (nrow(df) == 0) {
    return("_Nenhum registro._")
  }
  df2 <- df
  df2[] <- lapply(df2, function(x) {
    if (is.numeric(x)) {
      ifelse(is.na(x), NA_character_, formatC(x, format = "f", digits = digits, decimal.mark = ","))
    } else {
      as.character(x)
    }
  })
  header <- paste0("| ", paste(names(df2), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df2)), collapse = " | "), " |")
  rows <- apply(df2, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

gold <- read_csv_utf8(paths$gold)
manifest <- read_csv_utf8(paths$manifest) |>
  dplyr::select(pid, title, year, journal_title)

missing_gold_fields <- setdiff(c("pid", fields), names(gold))
if (length(missing_gold_fields) > 0L) {
  stop("Colunas ausentes no gold: ", paste(missing_gold_fields, collapse = ", "))
}

gold_long <- gold |>
  dplyr::select(pid, dplyr::all_of(fields)) |>
  tidyr::pivot_longer(
    cols = dplyr::all_of(fields),
    names_to = "field",
    values_to = "gold_value"
  ) |>
  dplyr::mutate(
    gold_label = label_value(gold_value),
    gold_positive = as_positive(gold_value),
    gold_labeled = !is.na(gold_value)
  )

read_agent_long <- function(agent_id) {
  path <- file.path(pilot_dir, paste0(agent_id, "_classifications.csv"))
  agent_data <- read_csv_utf8(path)
  missing_agent_fields <- setdiff(c("pid", fields), names(agent_data))
  if (length(missing_agent_fields) > 0L) {
    stop("Colunas ausentes em ", path, ": ", paste(missing_agent_fields, collapse = ", "))
  }
  agent_data |>
    dplyr::select(pid, dplyr::all_of(fields)) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(fields),
      names_to = "field",
      values_to = "pred_value"
    ) |>
    dplyr::mutate(
      agent_id = agent_id,
      pred_label = label_value(pred_value),
      pred_positive = as_positive(pred_value),
      pred_non_null = !is.na(pred_value)
    )
}

predictions <- dplyr::bind_rows(lapply(agents, read_agent_long)) |>
  dplyr::left_join(gold_long, by = c("pid", "field")) |>
  dplyr::left_join(manifest, by = "pid") |>
  dplyr::mutate(
    exact_match = pred_label == gold_label,
    binary_evaluable = gold_labeled,
    binary_match = binary_evaluable & pred_positive == gold_positive,
    outcome = dplyr::case_when(
      !binary_evaluable ~ "gold_null",
      pred_positive & gold_positive ~ "TP",
      pred_positive & !gold_positive ~ "FP",
      !pred_positive & !gold_positive ~ "TN",
      !pred_positive & gold_positive ~ "FN",
      TRUE ~ "other"
    )
  ) |>
  dplyr::select(
    pid, title, year, journal_title, agent_id, field,
    gold_label, pred_label, exact_match,
    gold_positive, pred_positive, pred_non_null,
    binary_evaluable, binary_match, outcome
  )

summary_by_agent_field <- predictions |>
  dplyr::group_by(agent_id, field) |>
  dplyr::summarise(
    n_total = dplyr::n(),
    gold_true = sum(gold_label == "TRUE"),
    gold_false = sum(gold_label == "FALSE"),
    gold_null = sum(gold_label == "NULL"),
    pred_true = sum(pred_label == "TRUE"),
    pred_false = sum(pred_label == "FALSE"),
    pred_null = sum(pred_label == "NULL"),
    pred_coverage_non_null = mean(pred_non_null),
    strict_exact_matches = sum(exact_match),
    strict_exact_accuracy = strict_exact_matches / n_total,
    n_binary = sum(binary_evaluable),
    tp = sum(outcome == "TP"),
    fp = sum(outcome == "FP"),
    tn = sum(outcome == "TN"),
    fn = sum(outcome == "FN"),
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

confusion <- predictions |>
  dplyr::filter(binary_evaluable) |>
  dplyr::count(agent_id, field, outcome, name = "n") |>
  tidyr::complete(agent_id, field, outcome = c("TP", "FP", "TN", "FN"), fill = list(n = 0L)) |>
  dplyr::arrange(field, agent_id, outcome)

consensus_path <- file.path(comparison_dir, "previous_classification_agreement_consensus_by_field.csv")
consensus_performance <- if (file.exists(consensus_path)) {
  read_csv_utf8(consensus_path) |>
    dplyr::filter(field %in% fields) |>
    dplyr::mutate(
      accepted_coverage = n_consensus_accepted / n_articles
    ) |>
    dplyr::select(
      field, n_articles, n_consensus_accepted, accepted_coverage,
      n_matches_previous, agreement_rate
    )
} else {
  tibble(
    field = character(),
    n_articles = integer(),
    n_consensus_accepted = integer(),
    accepted_coverage = numeric(),
    n_matches_previous = integer(),
    agreement_rate = numeric()
  )
}

readr::write_csv(summary_by_agent_field, paths$agent_summary, na = "")
readr::write_csv(confusion, paths$confusion, na = "")
readr::write_csv(predictions, paths$prediction_long, na = "")
readr::write_csv(consensus_performance, paths$consensus_summary, na = "")

display_summary <- summary_by_agent_field |>
  dplyr::mutate(
    pred_coverage_non_null = fmt_pct(pred_coverage_non_null),
    strict_exact_accuracy = fmt_pct(strict_exact_accuracy),
    binary_accuracy = fmt_pct(binary_accuracy),
    precision = fmt_pct(precision),
    recall_sensitivity = fmt_pct(recall_sensitivity),
    specificity = fmt_pct(specificity),
    f1 = fmt_pct(f1),
    balanced_accuracy = fmt_pct(balanced_accuracy)
  ) |>
  dplyr::select(
    agent_id, field, n_binary, gold_true, gold_false, gold_null,
    pred_true, pred_false, pred_null, pred_coverage_non_null,
    tp, fp, tn, fn, binary_accuracy, precision,
    recall_sensitivity, specificity, f1, balanced_accuracy,
    strict_exact_accuracy
  )

display_consensus <- consensus_performance |>
  dplyr::mutate(
    accepted_coverage = fmt_pct(accepted_coverage),
    agreement_rate = fmt_pct(agreement_rate)
  )

report_lines <- c(
  "# Performance dos agentes v2 contra classifica\u00e7\u00e3o manual/gold",
  "",
  paste0("Gerado em ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Fonte da ground truth",
  "",
  "- `README.md` documenta `data/processed/classifications_llm_main_analysis.csv` como base operacional da amostra classificada de 175 artigos ap\u00f3s exclus\u00f5es.",
  "- `docs/full_classification_pilot_architecture.md` documenta o mesmo arquivo como gold/piloto validado dos 175 artigos eleg\u00edveis, usado para sele\u00e7\u00e3o e compara\u00e7\u00e3o posterior.",
  "- Nesta avalia\u00e7\u00e3o, esse arquivo foi tratado como ground truth manual para `makes_explicit_causal_claim` e `makes_implicit_causal_claim`.",
  "",
  "## Interpreta\u00e7\u00e3o das m\u00e9tricas",
  "",
  "- M\u00e9tricas bin\u00e1rias usam `TRUE` como positivo e tratam `FALSE`/`NULL` do agente como negativo.",
  "- Casos com gold `NULL` s\u00e3o exclu\u00eddos das m\u00e9tricas bin\u00e1rias.",
  "- `strict_exact_accuracy` exige igualdade exata entre `TRUE`, `FALSE` e `NULL`; por isso penaliza agentes que usaram `NULL` onde o gold manual tem `FALSE`.",
  "",
  "## Performance por agente e campo",
  "",
  markdown_table(display_summary, digits = 3),
  "",
  "## Matriz de confus\u00e3o bin\u00e1ria",
  "",
  markdown_table(confusion, digits = 0),
  "",
  "## Consenso autom\u00e1tico v2 contra ground truth manual",
  "",
  "Para campos cr\u00edticos, o consenso autom\u00e1tico s\u00f3 aceita unanimidade; por isso a cobertura \u00e9 baixa.",
  "",
  markdown_table(display_consensus, digits = 3),
  "",
  "## Arquivos gerados",
  "",
  paste0("- `", sub(paste0("^", project_dir, "/?"), "", paths$agent_summary), "`"),
  paste0("- `", sub(paste0("^", project_dir, "/?"), "", paths$confusion), "`"),
  paste0("- `", sub(paste0("^", project_dir, "/?"), "", paths$prediction_long), "`"),
  paste0("- `", sub(paste0("^", project_dir, "/?"), "", paths$consensus_summary), "`")
)

writeLines(report_lines, paths$report, useBytes = TRUE)

cat("Gold:", sub(paste0("^", project_dir, "/?"), "", paths$gold), "\n")
cat("Resumo:", sub(paste0("^", project_dir, "/?"), "", paths$agent_summary), "\n")
cat("Relatorio:", sub(paste0("^", project_dir, "/?"), "", paths$report), "\n")
