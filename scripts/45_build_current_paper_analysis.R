#!/usr/bin/env Rscript

## Atualiza os artefatos analíticos do paper a partir do CSV canônico corrente.
## Separa resultados descritivos de cobertura parcial de resultados censitários
## para periódicos cuja classificação está completa.

options(scipen = 999, encoding = "UTF-8")
set.seed(20260713)

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(jsonlite)
  library(readr)
  library(stringr)
  library(tidyr)
})

file_arg <- commandArgs(trailingOnly = FALSE) |>
  stringr::str_subset("^--file=") |>
  stringr::str_remove("^--file=")
if (length(file_arg) != 1) {
  stop("Não foi possível identificar o caminho do script.")
}

project_dir <- normalizePath(file.path(dirname(file_arg), ".."), mustWork = TRUE)
path <- function(...) file.path(project_dir, ...)

manifest_path <- path("data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv")
classifications_path <- path(
  "data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv"
)
excluded_articles_path <- path("data/processed/excluded_articles.csv")
excluded_journals_path <- path("data/processed/excluded_journals.csv")

analysis_dir <- path("data/processed/paper_analysis")
tables_dir <- path("output/tables/paper")
figures_dir <- path("output/figures/paper")
audit_dir <- path("quality_reports/paper_variable_audit")

dir.create(analysis_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(audit_dir, recursive = TRUE, showWarnings = FALSE)

required_files <- c(
  manifest_path,
  classifications_path,
  excluded_articles_path,
  excluded_journals_path
)
if (!all(file.exists(required_files))) {
  stop("Arquivos canônicos ausentes: ", paste(required_files[!file.exists(required_files)], collapse = "; "))
}

period_levels <- c("2005-2011", "2012-2018", "2019-2025")
evidence_levels <- c("none", "qualitative_only", "quantitative_only", "mixed_empirical", "unclear")
quantitative_levels <- c(
  "none",
  "descriptive_statistics_only",
  "bivariate_tests_or_correlations_only",
  "statistical_modeling",
  "unclear"
)

parse_bool <- function(x) {
  value <- stringr::str_to_upper(stringr::str_trim(dplyr::coalesce(as.character(x), "")))
  dplyr::case_when(
    value == "TRUE" ~ TRUE,
    value == "FALSE" ~ FALSE,
    TRUE ~ NA
  )
}

parse_method_types <- function(x) {
  if (is.na(x) || stringr::str_trim(x) == "") {
    return(character())
  }
  parsed <- tryCatch(jsonlite::fromJSON(x), error = function(e) NULL)
  if (is.null(parsed)) {
    return(NA_character_)
  }
  as.character(parsed)
}

period_3 <- function(year) {
  factor(
    dplyr::case_when(
      dplyr::between(year, 2005L, 2011L) ~ "2005-2011",
      dplyr::between(year, 2012L, 2018L) ~ "2012-2018",
      dplyr::between(year, 2019L, 2025L) ~ "2019-2025",
      TRUE ~ NA_character_
    ),
    levels = period_levels
  )
}

map_journal_area <- function(journal_title) {
  dplyr::case_when(
    journal_title %in% c(
      "Brazilian Political Science Review",
      "Revista Brasileira de Ciência Política",
      "Opinião Pública",
      "Revista de Sociologia e Política"
    ) ~ "Ciência Política",
    journal_title %in% c(
      "Contexto Internacional",
      "Revista Brasileira de Política Internacional"
    ) ~ "Relações Internacionais",
    journal_title == "Cadernos Gestão Pública e Cidadania" ~ "Administração Pública",
    journal_title %in% c(
      "Dados",
      "Lua Nova: Revista de Cultura e Política",
      "Novos estudos CEBRAP",
      "Revista Brasileira de Ciências Sociais"
    ) ~ "Ciência Política e Ciências Sociais",
    TRUE ~ "Área a revisar"
  )
}

fmt_pct <- function(n, d) {
  denominator <- rep(d, length.out = length(n))
  value <- round(100 * n / denominator, 1)
  value[is.na(denominator) | denominator == 0] <- NA_real_
  value
}

fmt_n <- function(x) {
  format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE)
}

fmt_pct_label <- function(x) {
  ifelse(
    is.na(x),
    "-",
    paste0(format(x, decimal.mark = ",", nsmall = 1, trim = TRUE), "%")
  )
}

write_utf8_lines <- function(lines, file) {
  connection <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(connection), add = TRUE)
  writeLines(enc2utf8(lines), con = connection, useBytes = TRUE)
}

strict_design_methods <- c(
  "experiment_field",
  "experiment_survey",
  "experiment_lab",
  "experiment_list",
  "difference_in_differences",
  "event_study",
  "instrumental_variables",
  "regression_discontinuity",
  "regression_kink",
  "synthetic_control",
  "synthetic_difference_in_differences",
  "matching_or_weighting",
  "dag_or_formal_causal_graph",
  "doubly_robust",
  "causal_trees_or_forests",
  "causal_discovery"
)

diagnostic_not_design_methods <- c(
  "observational_regression_with_causal_claim_no_design",
  "fixed_effects_causal_panel_claim",
  "none_detected"
)

method_labels <- c(
  experiment_field = "Experimento de campo",
  experiment_survey = "Experimento em survey",
  experiment_lab = "Experimento de laboratório",
  experiment_list = "Experimento de lista",
  difference_in_differences = "Diferenças-em-diferenças",
  event_study = "Event study",
  instrumental_variables = "Variáveis instrumentais",
  regression_discontinuity = "Regressão descontínua",
  regression_kink = "Regression kink",
  synthetic_control = "Controle sintético",
  synthetic_difference_in_differences = "Diferenças-em-diferenças sintéticas",
  matching_or_weighting = "Pareamento/ponderação",
  dag_or_formal_causal_graph = "DAG/grafo causal formal",
  doubly_robust = "Estimador duplamente robusto",
  causal_trees_or_forests = "Árvores/florestas causais",
  causal_discovery = "Descoberta causal"
)

metric_labels <- c(
  empirical = "Artigos empíricos",
  quantitative = "Componente quantitativo",
  inference = "Inferência estatística",
  claim = "Afirmação causal/explicativa",
  screen = "Identificação relevante",
  strict = "Estratégia explícita"
)

metric_denominators <- c(
  empirical = "todos os artigos",
  quantitative = "artigos empíricos",
  inference = "empíricos quantitativos",
  claim = "artigos empíricos",
  screen = "todos os artigos",
  strict = "casos relevantes para identificação"
)

manifest_raw <- readr::read_csv(manifest_path, show_col_types = FALSE) |>
  dplyr::mutate(
    year = as.integer(year),
    period_3 = period_3(year),
    journal_area = map_journal_area(journal_title),
    body_word_count = as.numeric(body_word_count)
  )

excluded_articles <- readr::read_csv(excluded_articles_path, show_col_types = FALSE) |>
  dplyr::mutate(exclude_from_analysis = parse_bool(exclude_from_analysis)) |>
  dplyr::filter(dplyr::coalesce(exclude_from_analysis, FALSE)) |>
  dplyr::select(pid, exclusion_reason)

excluded_journals <- readr::read_csv(excluded_journals_path, show_col_types = FALSE) |>
  dplyr::mutate(exclude_from_analysis = parse_bool(exclude_from_analysis)) |>
  dplyr::filter(dplyr::coalesce(exclude_from_analysis, FALSE)) |>
  dplyr::distinct(journal_title, exclusion_reason) |>
  dplyr::select(journal_title, exclusion_reason)

eligible_manifest <- manifest_raw |>
  dplyr::anti_join(excluded_articles |> dplyr::select(pid), by = "pid")

classifications_source <- readr::read_csv(classifications_path, show_col_types = FALSE)

duplicate_pid_rows <- classifications_source |>
  dplyr::add_count(pid, name = "pid_rows") |>
  dplyr::filter(pid_rows > 1) |>
  dplyr::arrange(pid) |>
  dplyr::select(-pid_rows)

duplicate_pid_status <- if (nrow(duplicate_pid_rows) == 0) {
  tibble::tibble(
    pid = character(),
    rows = integer(),
    distinct_rows = integer(),
    exact_duplicates_only = logical()
  )
} else {
  duplicate_pid_rows |>
    dplyr::group_by(pid) |>
    dplyr::group_modify(~ tibble::tibble(
      rows = nrow(.x),
      distinct_rows = nrow(dplyr::distinct(.x)),
      exact_duplicates_only = nrow(dplyr::distinct(.x)) == 1
    )) |>
    dplyr::ungroup()
}

if (any(!duplicate_pid_status$exact_duplicates_only)) {
  readr::write_csv(duplicate_pid_rows, file.path(analysis_dir, "current_duplicate_pid_rows.csv"))
  readr::write_csv(duplicate_pid_status, file.path(analysis_dir, "current_duplicate_pid_status.csv"))
  stop("Há PIDs repetidos com classificações não idênticas; a análise foi interrompida.")
}

classifications_raw <- classifications_source |>
  dplyr::distinct() |>
  dplyr::rename(classification_input_text_hash = input_text_hash) |>
  dplyr::mutate(
    is_empirical_paper = parse_bool(is_empirical_paper),
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    is_empirical_qual_paper = parse_bool(is_empirical_qual_paper),
    has_statistical_inference = parse_bool(has_statistical_inference),
    causal_or_explanatory_claim_present = parse_bool(causal_or_explanatory_claim_present),
    credibility_revolution_screen_applicable = parse_bool(credibility_revolution_screen_applicable),
    credibility_revolution_method_present = parse_bool(credibility_revolution_method_present),
    tough_call = parse_bool(tough_call),
    method_type = lapply(credibility_revolution_method_type, parse_method_types)
  )

classified_outside_manifest <- classifications_raw |>
  dplyr::anti_join(manifest_raw |> dplyr::select(pid), by = "pid") |>
  dplyr::select(pid, title, journal_title)

classified_excluded_by_ledger <- classifications_raw |>
  dplyr::semi_join(excluded_articles |> dplyr::select(pid), by = "pid") |>
  dplyr::left_join(excluded_articles, by = "pid") |>
  dplyr::select(pid, title, journal_title, exclusion_reason)

excluded_journals_in_manifest <- manifest_raw |>
  dplyr::semi_join(excluded_journals |> dplyr::select(journal_title), by = "journal_title") |>
  dplyr::distinct(pid, journal_title)

excluded_journals_in_classifications <- classifications_raw |>
  dplyr::semi_join(excluded_journals |> dplyr::select(journal_title), by = "journal_title") |>
  dplyr::distinct(pid, journal_title)

journal_title_mismatches <- classifications_raw |>
  dplyr::inner_join(
    eligible_manifest |> dplyr::select(pid, manifest_journal_title = journal_title),
    by = "pid"
  ) |>
  dplyr::filter(
    !is.na(journal_title),
    !is.na(manifest_journal_title),
    journal_title != manifest_journal_title
  ) |>
  dplyr::select(pid, classification_journal_title = journal_title, manifest_journal_title)

analysis_df <- classifications_raw |>
  dplyr::semi_join(eligible_manifest |> dplyr::select(pid), by = "pid") |>
  dplyr::left_join(
    eligible_manifest |>
      dplyr::select(
        pid,
        manifest_input_text_hash = input_text_hash,
        eligible_order,
        year,
        period_3,
        journal_area,
        manifest_journal_title = journal_title,
        document_type,
        language,
        body_word_count,
        fulltext_validation_status
      ),
    by = "pid"
  ) |>
  dplyr::mutate(
    journal_title = dplyr::coalesce(journal_title, manifest_journal_title),
    journal_area = dplyr::coalesce(journal_area, map_journal_area(journal_title)),
    empirical_evidence_type = factor(empirical_evidence_type, levels = evidence_levels),
    quantitative_analysis_type = factor(quantitative_analysis_type, levels = quantitative_levels),
    qualitative_goal_clarity = dplyr::case_when(
      qualitative_goal_clarity == "clear" ~ "Clara",
      qualitative_goal_clarity == "ambiguous_tough_call" ~ "Ambígua/caso difícil",
      is_empirical_qual_paper & (is.na(qualitative_goal_clarity) | qualitative_goal_clarity == "") ~ "Não registrada",
      TRUE ~ NA_character_
    )
  )

method_long <- analysis_df |>
  dplyr::select(
    pid,
    title,
    journal_title,
    journal_area,
    year,
    period_3,
    credibility_revolution_screen_applicable,
    credibility_revolution_method_present,
    method_type,
    causal_design_quote,
    tough_call
  ) |>
  tidyr::unnest(method_type, keep_empty = FALSE) |>
  dplyr::mutate(
    method_class = dplyr::case_when(
      method_type %in% strict_design_methods ~ "strict_design_method",
      method_type == "other_modern_causal_method" ~ "other_modern_causal_method",
      method_type %in% diagnostic_not_design_methods ~ "diagnostic_not_design",
      is.na(method_type) ~ "parse_error",
      TRUE ~ "unclassified"
    )
  )

strict_pids <- method_long |>
  dplyr::filter(method_class == "strict_design_method") |>
  dplyr::pull(pid) |>
  unique()

diagnostic_pids <- method_long |>
  dplyr::filter(method_class == "diagnostic_not_design") |>
  dplyr::pull(pid) |>
  unique()

other_modern_pids <- method_long |>
  dplyr::filter(method_class == "other_modern_causal_method") |>
  dplyr::pull(pid) |>
  unique()

analysis_df <- analysis_df |>
  dplyr::mutate(
    strict_design_method = pid %in% strict_pids,
    diagnostic_not_design = pid %in% diagnostic_pids,
    other_modern_causal_method = pid %in% other_modern_pids
  )

coverage_by_journal <- eligible_manifest |>
  dplyr::count(journal_area, journal_title, name = "eligible_n") |>
  dplyr::left_join(
    analysis_df |>
      dplyr::count(journal_area, journal_title, name = "classified_n"),
    by = c("journal_area", "journal_title")
  ) |>
  dplyr::mutate(
    classified_n = dplyr::coalesce(classified_n, 0L),
    remaining_n = eligible_n - classified_n,
    coverage_percent = fmt_pct(classified_n, eligible_n),
    coverage_status = dplyr::case_when(
      remaining_n == 0 ~ "Completo",
      classified_n == 0 ~ "Não iniciado",
      TRUE ~ "Parcial"
    )
  ) |>
  dplyr::arrange(dplyr::desc(coverage_percent), journal_title)

complete_journals <- coverage_by_journal |>
  dplyr::filter(coverage_status == "Completo") |>
  dplyr::pull(journal_title)

coverage_by_journal_period <- eligible_manifest |>
  dplyr::count(journal_title, period_3, name = "eligible_n") |>
  tidyr::complete(
    journal_title,
    period_3 = factor(period_levels, levels = period_levels),
    fill = list(eligible_n = 0L)
  ) |>
  dplyr::left_join(
    analysis_df |>
      dplyr::count(journal_title, period_3, name = "classified_n"),
    by = c("journal_title", "period_3")
  ) |>
  dplyr::mutate(
    classified_n = dplyr::coalesce(classified_n, 0L),
    remaining_n = eligible_n - classified_n,
    coverage_percent = dplyr::if_else(eligible_n > 0, fmt_pct(classified_n, eligible_n), NA_real_)
  )

temporal_complete_journals <- coverage_by_journal_period |>
  dplyr::filter(journal_title %in% complete_journals) |>
  dplyr::group_by(journal_title) |>
  dplyr::summarise(
    has_all_periods = all(eligible_n > 0),
    complete_all_periods = all(eligible_n == classified_n),
    .groups = "drop"
  ) |>
  dplyr::filter(has_all_periods, complete_all_periods) |>
  dplyr::pull(journal_title)

analysis_df <- analysis_df |>
  dplyr::mutate(
    complete_journal = journal_title %in% complete_journals,
    temporal_complete_journal = journal_title %in% temporal_complete_journals
  )

complete_df <- analysis_df |>
  dplyr::filter(complete_journal)

temporal_df <- analysis_df |>
  dplyr::filter(temporal_complete_journal)

metric_summary <- function(data, groups = character()) {
  data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(groups))) |>
    dplyr::summarise(
      n_articles = dplyr::n(),
      n_empirical = sum(dplyr::coalesce(is_empirical_paper, FALSE)),
      n_quantitative = sum(
        dplyr::coalesce(is_empirical_paper, FALSE) &
          dplyr::coalesce(is_empirical_quant_paper_torreblanca, FALSE)
      ),
      n_inference = sum(
        dplyr::coalesce(is_empirical_quant_paper_torreblanca, FALSE) &
          has_statistical_inference %in% TRUE
      ),
      n_inference_observed = sum(
        dplyr::coalesce(is_empirical_quant_paper_torreblanca, FALSE) &
          !is.na(has_statistical_inference)
      ),
      n_inference_missing = sum(
        dplyr::coalesce(is_empirical_quant_paper_torreblanca, FALSE) &
          is.na(has_statistical_inference)
      ),
      n_claim = sum(dplyr::coalesce(causal_or_explanatory_claim_present, FALSE)),
      n_empirical_claim = sum(
        dplyr::coalesce(is_empirical_paper, FALSE) &
          dplyr::coalesce(causal_or_explanatory_claim_present, FALSE)
      ),
      n_screen = sum(dplyr::coalesce(credibility_revolution_screen_applicable, FALSE)),
      n_strict = sum(
        dplyr::coalesce(credibility_revolution_screen_applicable, FALSE) &
          strict_design_method
      ),
      pct_empirical = fmt_pct(n_empirical, n_articles),
      pct_quantitative = fmt_pct(n_quantitative, n_empirical),
      pct_inference = fmt_pct(n_inference, n_inference_observed),
      pct_claim = fmt_pct(n_empirical_claim, n_empirical),
      pct_claim_all = fmt_pct(n_claim, n_articles),
      pct_screen = fmt_pct(n_screen, n_articles),
      pct_strict = fmt_pct(n_strict, n_screen),
      .groups = "drop"
    )
}

n_manifest <- dplyr::n_distinct(eligible_manifest$pid)
n_classified <- dplyr::n_distinct(analysis_df$pid)
n_remaining <- n_manifest - n_classified
n_complete_journal_articles <- dplyr::n_distinct(complete_df$pid)
n_complete_journals <- length(complete_journals)

overall_metrics <- metric_summary(analysis_df)
complete_metrics <- metric_summary(complete_df)

denominator_summary <- tibble::tibble(
  denominator = c(
    "Corpus completo elegível",
    "Artigos classificados por leitura integral",
    "Artigos ainda não classificados",
    "Periódicos com classificação completa",
    "Artigos dos periódicos completos",
    "Artigos empíricos classificados",
    "Artigos empíricos quantitativos classificados",
    "Artigos empíricos quantitativos com inferência classificada",
    "Artigos empíricos quantitativos sem classificação de inferência",
    "Artigos com afirmação causal ou explicativa classificados",
    "Artigos em que a identificação é especialmente relevante",
    "Artigos com estratégia explícita de identificação causal"
  ),
  n = c(
    n_manifest,
    n_classified,
    n_remaining,
    n_complete_journals,
    n_complete_journal_articles,
    overall_metrics$n_empirical,
    overall_metrics$n_quantitative,
    overall_metrics$n_inference_observed,
    overall_metrics$n_inference_missing,
    overall_metrics$n_claim,
    overall_metrics$n_screen,
    overall_metrics$n_strict
  ),
  denominator_reference = c(
    "manifest elegível reconciliado",
    "manifest elegível reconciliado",
    "manifest elegível reconciliado",
    "periódicos do manifest",
    "artigos classificados",
    "artigos classificados",
    "artigos empíricos classificados",
    "artigos empíricos quantitativos classificados",
    "artigos empíricos quantitativos classificados",
    "artigos classificados",
    "artigos classificados",
    "casos relevantes para identificação"
  ),
  denominator_n = c(
    n_manifest,
    n_manifest,
    n_manifest,
    dplyr::n_distinct(eligible_manifest$journal_title),
    n_classified,
    n_classified,
    overall_metrics$n_empirical,
    overall_metrics$n_quantitative,
    overall_metrics$n_quantitative,
    n_classified,
    n_classified,
    overall_metrics$n_screen
  ),
  percent = c(
    100,
    fmt_pct(n_classified, n_manifest),
    fmt_pct(n_remaining, n_manifest),
    fmt_pct(n_complete_journals, dplyr::n_distinct(eligible_manifest$journal_title)),
    fmt_pct(n_complete_journal_articles, n_classified),
    overall_metrics$pct_empirical,
    overall_metrics$pct_quantitative,
    fmt_pct(overall_metrics$n_inference_observed, overall_metrics$n_quantitative),
    fmt_pct(overall_metrics$n_inference_missing, overall_metrics$n_quantitative),
    overall_metrics$pct_claim_all,
    overall_metrics$pct_screen,
    overall_metrics$pct_strict
  )
)

table_1_corpus_description <- eligible_manifest |>
  dplyr::count(journal_area, journal_title, period_3, name = "eligible_n") |>
  dplyr::left_join(
    analysis_df |>
      dplyr::count(journal_area, journal_title, period_3, name = "classified_n"),
    by = c("journal_area", "journal_title", "period_3")
  ) |>
  dplyr::mutate(classified_n = dplyr::coalesce(classified_n, 0L)) |>
  tidyr::pivot_wider(
    names_from = period_3,
    values_from = c(eligible_n, classified_n),
    values_fill = 0,
    names_expand = TRUE
  ) |>
  dplyr::left_join(
    coverage_by_journal |>
      dplyr::select(journal_title, eligible_total = eligible_n, classified_total = classified_n, coverage_percent, coverage_status),
    by = "journal_title"
  ) |>
  dplyr::select(
    journal_area,
    journal_title,
    `eligible_n_2005-2011`,
    `eligible_n_2012-2018`,
    `eligible_n_2019-2025`,
    `classified_n_2005-2011`,
    `classified_n_2012-2018`,
    `classified_n_2019-2025`,
    eligible_total,
    classified_total,
    coverage_percent,
    coverage_status
  ) |>
  dplyr::arrange(journal_area, journal_title)

table_2_methodological_dimensions <- tibble::tribble(
  ~dimension, ~category, ~n, ~denominator, ~denominator_n, ~percent, ~note,
  "Evidência", "Artigo empírico", overall_metrics$n_empirical, "artigos classificados", n_classified, overall_metrics$pct_empirical, "Cobertura parcial; não representa o corpus completo.",
  "Evidência", "Somente qualitativo", sum(analysis_df$empirical_evidence_type == "qualitative_only", na.rm = TRUE), "artigos empíricos", overall_metrics$n_empirical, fmt_pct(sum(analysis_df$empirical_evidence_type == "qualitative_only", na.rm = TRUE), overall_metrics$n_empirical), "Categoria exclusiva entre artigos empíricos.",
  "Evidência", "Somente quantitativo", sum(analysis_df$empirical_evidence_type == "quantitative_only", na.rm = TRUE), "artigos empíricos", overall_metrics$n_empirical, fmt_pct(sum(analysis_df$empirical_evidence_type == "quantitative_only", na.rm = TRUE), overall_metrics$n_empirical), "Categoria exclusiva entre artigos empíricos.",
  "Evidência", "Misto", sum(analysis_df$empirical_evidence_type == "mixed_empirical", na.rm = TRUE), "artigos empíricos", overall_metrics$n_empirical, fmt_pct(sum(analysis_df$empirical_evidence_type == "mixed_empirical", na.rm = TRUE), overall_metrics$n_empirical), "Categoria exclusiva entre artigos empíricos.",
  "Quantificação", "Componente quantitativo", overall_metrics$n_quantitative, "artigos empíricos", overall_metrics$n_empirical, overall_metrics$pct_quantitative, "Subconjunto quantitativo comparável ao estudo de referência.",
  "Quantificação", "Modelagem estatística", sum(analysis_df$quantitative_analysis_type == "statistical_modeling", na.rm = TRUE), "empíricos quantitativos", overall_metrics$n_quantitative, fmt_pct(sum(analysis_df$quantitative_analysis_type == "statistical_modeling", na.rm = TRUE), overall_metrics$n_quantitative), "Tipo de análise quantitativa.",
  "Quantificação", "Inferência estatística", overall_metrics$n_inference, "empíricos quantitativos com inferência classificada", overall_metrics$n_inference_observed, overall_metrics$pct_inference, paste0("Testes, intervalos, erros-padrão ou inferência equivalente; ", overall_metrics$n_inference_missing, " casos quantitativos sem classificação são excluídos do denominador."),
  "Explicitação", "method_explicitness", NA_integer_, "não disponível", NA_integer_, NA_real_, "Exige classificação complementar; não é resultado substantivo.",
  "Formato", "empirical_article_format", NA_integer_, "não disponível", NA_integer_, NA_real_, "Exige classificação complementar; não é resultado substantivo."
)

table_3_causality_credibility <- tibble::tribble(
  ~panel, ~category, ~n, ~denominator, ~denominator_n, ~percent, ~note,
  "Afirmações", "Afirmação causal ou explicativa", overall_metrics$n_claim, "artigos classificados", n_classified, overall_metrics$pct_claim_all, "A categoria combina afirmações causais e explicativas e também pode marcar textos não empíricos.",
  "Afirmações", "Afirmação causal ou explicativa em artigo empírico", overall_metrics$n_empirical_claim, "artigos empíricos", overall_metrics$n_empirical, overall_metrics$pct_claim, "O subconjunto empírico ainda não equivale a uma afirmação causal explícita.",
  "Seleção analítica", "Casos relevantes para avaliar identificação", overall_metrics$n_screen, "artigos classificados", n_classified, overall_metrics$pct_screen, "Inclui artigos com afirmação causal ou explicativa e evidência empírica, além de modelagem quantitativa relevante.",
  "Identificação", "Estratégia explícita de identificação causal", overall_metrics$n_strict, "casos relevantes para identificação", overall_metrics$n_screen, overall_metrics$pct_strict, "Contagem conservadora de famílias de método explicitamente mencionadas.",
  "Diagnóstico não exclusivo", "Método quantitativo sem estratégia explícita", sum(analysis_df$diagnostic_not_design & dplyr::coalesce(analysis_df$credibility_revolution_screen_applicable, FALSE)), "casos relevantes para identificação", overall_metrics$n_screen, fmt_pct(sum(analysis_df$diagnostic_not_design & dplyr::coalesce(analysis_df$credibility_revolution_screen_applicable, FALSE)), overall_metrics$n_screen), "A categoria pode coexistir com uma estratégia explícita.",
  "Diagnóstico não exclusivo", "Outro método moderno a auditar", sum(analysis_df$other_modern_causal_method & dplyr::coalesce(analysis_df$credibility_revolution_screen_applicable, FALSE)), "casos relevantes para identificação", overall_metrics$n_screen, fmt_pct(sum(analysis_df$other_modern_causal_method & dplyr::coalesce(analysis_df$credibility_revolution_screen_applicable, FALSE)), overall_metrics$n_screen), "Categoria conservadora que exige auditoria adicional."
)

complete_journal_profile <- metric_summary(complete_df, "journal_title") |>
  dplyr::arrange(journal_title)

complete_journal_profile_long <- complete_journal_profile |>
  dplyr::select(
    journal_title,
    n_articles,
    pct_empirical,
    pct_quantitative,
    pct_inference,
    pct_claim,
    pct_screen,
    pct_strict
  ) |>
  tidyr::pivot_longer(
    cols = dplyr::starts_with("pct_"),
    names_to = "metric",
    values_to = "percent"
  ) |>
  dplyr::mutate(
    metric = stringr::str_remove(metric, "^pct_"),
    metric_label = unname(metric_labels[metric]),
    denominator = unname(metric_denominators[metric])
  )

claim_method_alignment <- analysis_df |>
  dplyr::mutate(
    alignment_category = dplyr::case_when(
      strict_design_method & dplyr::coalesce(causal_or_explanatory_claim_present, FALSE) ~ "Afirmação e estratégia explícita de identificação",
      strict_design_method & !dplyr::coalesce(causal_or_explanatory_claim_present, FALSE) ~ "Estratégia explícita sem afirmação codificada",
      dplyr::coalesce(is_empirical_paper, FALSE) & dplyr::coalesce(causal_or_explanatory_claim_present, FALSE) & dplyr::coalesce(is_empirical_quant_paper_torreblanca, FALSE) ~ "Afirmação empírica e componente quantitativo, sem estratégia explícita",
      dplyr::coalesce(is_empirical_paper, FALSE) & dplyr::coalesce(causal_or_explanatory_claim_present, FALSE) & !dplyr::coalesce(is_empirical_quant_paper_torreblanca, FALSE) ~ "Afirmação empírica sem componente quantitativo",
      !dplyr::coalesce(is_empirical_paper, FALSE) & dplyr::coalesce(causal_or_explanatory_claim_present, FALSE) ~ "Afirmação em artigo não empírico",
      !dplyr::coalesce(causal_or_explanatory_claim_present, FALSE) & dplyr::coalesce(is_empirical_quant_paper_torreblanca, FALSE) ~ "Componente quantitativo sem afirmação",
      TRUE ~ "Sem afirmação ou componente quantitativo"
    )
  ) |>
  dplyr::count(alignment_category, name = "n") |>
  dplyr::mutate(
    denominator = "artigos classificados",
    denominator_n = n_classified,
    percent = fmt_pct(n, denominator_n)
  ) |>
  dplyr::arrange(dplyr::desc(n))

claim_evidence_matrix <- analysis_df |>
  dplyr::mutate(
    empirical_evidence_type = as.character(empirical_evidence_type),
    claim_status = if_else(
      dplyr::coalesce(causal_or_explanatory_claim_present, FALSE),
      "Com afirmação causal/explicativa",
      "Sem afirmação causal/explicativa"
    )
  ) |>
  dplyr::count(empirical_evidence_type, claim_status, strict_design_method, name = "n") |>
  dplyr::group_by(empirical_evidence_type) |>
  dplyr::mutate(
    evidence_denominator_n = sum(n),
    percent_within_evidence = fmt_pct(n, evidence_denominator_n)
  ) |>
  dplyr::ungroup()

qualitative_profile <- analysis_df |>
  dplyr::filter(dplyr::coalesce(is_empirical_qual_paper, FALSE)) |>
  dplyr::count(journal_title, qualitative_goal_clarity, name = "n") |>
  dplyr::group_by(journal_title) |>
  dplyr::mutate(
    denominator = "artigos com evidência qualitativa",
    denominator_n = sum(n),
    percent = fmt_pct(n, denominator_n)
  ) |>
  dplyr::ungroup() |>
  dplyr::arrange(journal_title, dplyr::desc(n))

qualitative_complete_summary <- complete_df |>
  dplyr::filter(dplyr::coalesce(is_empirical_qual_paper, FALSE)) |>
  dplyr::count(qualitative_goal_clarity, name = "n") |>
  dplyr::mutate(
    denominator = "artigos qualitativos ou mistos nos periódicos completos",
    denominator_n = sum(n),
    percent = fmt_pct(n, denominator_n)
  ) |>
  dplyr::arrange(dplyr::desc(n))

period_journal_profile <- metric_summary(temporal_df, c("journal_title", "period_3")) |>
  dplyr::arrange(journal_title, period_3)

period_equal_weight_profile <- period_journal_profile |>
  dplyr::group_by(period_3) |>
  dplyr::summarise(
    journals_n = dplyr::n_distinct(journal_title),
    articles_n = sum(n_articles),
    pct_empirical = round(mean(pct_empirical), 1),
    pct_quantitative = round(mean(pct_quantitative), 1),
    pct_inference = round(mean(pct_inference), 1),
    pct_claim = round(mean(pct_claim), 1),
    pct_screen = round(mean(pct_screen), 1),
    pct_strict = round(mean(pct_strict), 1),
    weighting = "média simples das proporções dos periódicos completos nos três períodos",
    .groups = "drop"
  )

period_article_weight_profile <- metric_summary(temporal_df, "period_3") |>
  dplyr::mutate(
    journals_n = length(temporal_complete_journals),
    weighting = "proporção agrupada dos artigos nos periódicos completos com suporte temporal comum"
  ) |>
  dplyr::select(
    period_3,
    journals_n,
    articles_n = n_articles,
    pct_empirical,
    pct_quantitative,
    pct_inference,
    pct_claim,
    pct_screen,
    pct_strict,
    weighting
  )

year_journal_profile <- metric_summary(temporal_df, c("journal_title", "year")) |>
  dplyr::arrange(journal_title, year)

common_support_years <- year_journal_profile |>
  dplyr::count(year, name = "journals_n") |>
  dplyr::filter(journals_n == length(temporal_complete_journals)) |>
  dplyr::pull(year)

year_article_weight_profile <- temporal_df |>
  dplyr::filter(year %in% common_support_years) |>
  metric_summary("year") |>
  dplyr::mutate(
    journals_n = length(temporal_complete_journals),
    weighting = "proporção agrupada dos artigos dos periódicos presentes em todos os anos exibidos"
  ) |>
  dplyr::select(
    year,
    journals_n,
    articles_n = n_articles,
    pct_empirical,
    pct_quantitative,
    pct_inference,
    pct_claim,
    pct_screen,
    pct_strict,
    weighting
  )

strict_method_diffusion <- method_long |>
  dplyr::filter(
    journal_title %in% complete_journals,
    method_class == "strict_design_method"
  ) |>
  dplyr::distinct(pid, journal_title, period_3, method_type) |>
  dplyr::count(method_type, journal_title, period_3, name = "article_method_n") |>
  dplyr::mutate(method_label = dplyr::recode(method_type, !!!method_labels, .default = method_type)) |>
  dplyr::arrange(method_label, journal_title, period_3)

strict_method_totals <- strict_method_diffusion |>
  dplyr::group_by(method_type, method_label) |>
  dplyr::summarise(article_method_n = sum(article_method_n), .groups = "drop") |>
  dplyr::arrange(dplyr::desc(article_method_n), method_label)

tough_call_profile <- analysis_df |>
  dplyr::group_by(journal_title, period_3) |>
  dplyr::summarise(
    classified_n = dplyr::n(),
    tough_call_n = sum(dplyr::coalesce(tough_call, FALSE)),
    tough_call_percent = fmt_pct(tough_call_n, classified_n),
    .groups = "drop"
  ) |>
  dplyr::arrange(journal_title, period_3)

required_core_boolean_fields <- c(
  "is_empirical_paper",
  "is_empirical_quant_paper_torreblanca",
  "is_empirical_qual_paper",
  "causal_or_explanatory_claim_present",
  "credibility_revolution_screen_applicable",
  "tough_call"
)

boolean_missing_n <- analysis_df |>
  dplyr::summarise(dplyr::across(dplyr::all_of(required_core_boolean_fields), ~ sum(is.na(.x)))) |>
  tidyr::pivot_longer(dplyr::everything(), names_to = "field", values_to = "missing_n")

method_present_missing_within_screen <- sum(
  dplyr::coalesce(analysis_df$credibility_revolution_screen_applicable, FALSE) &
    is.na(analysis_df$credibility_revolution_method_present)
)

hash_matches <- !is.na(analysis_df$classification_input_text_hash) &
  !is.na(analysis_df$manifest_input_text_hash) &
  analysis_df$classification_input_text_hash == analysis_df$manifest_input_text_hash

classified_for_level_validation <- classifications_raw |>
  dplyr::semi_join(eligible_manifest |> dplyr::select(pid), by = "pid")

unknown_evidence_levels <- sum(
  !is.na(classified_for_level_validation$empirical_evidence_type) &
    classified_for_level_validation$empirical_evidence_type != "" &
    !classified_for_level_validation$empirical_evidence_type %in% evidence_levels
)

unknown_quantitative_levels <- sum(
  !is.na(classified_for_level_validation$quantitative_analysis_type) &
    classified_for_level_validation$quantitative_analysis_type != "" &
    !classified_for_level_validation$quantitative_analysis_type %in% quantitative_levels
)

inference_missing_within_quantitative <- sum(
  dplyr::coalesce(analysis_df$is_empirical_quant_paper_torreblanca, FALSE) &
    is.na(analysis_df$has_statistical_inference)
)

method_present_without_type <- sum(
  dplyr::coalesce(analysis_df$credibility_revolution_method_present, FALSE) &
    !analysis_df$pid %in% method_long$pid
)

strict_without_quote <- sum(
  analysis_df$strict_design_method &
    (is.na(analysis_df$causal_design_quote) | stringr::str_trim(analysis_df$causal_design_quote) == "")
)

coverage_exceeds_eligible <- sum(
  coverage_by_journal_period$classified_n > coverage_by_journal_period$eligible_n
)

logical_inconsistencies <- tibble::tibble(
  check = c(
    "manifest_duplicate_pids",
    "manifest_year_outside_2005_2025",
    "manifest_non_research_article",
    "non_empirical_with_empirical_evidence",
    "quantitative_without_empirical_flag",
    "quantitative_flag_with_quantitative_type_none",
    "statistical_inference_without_quantitative_flag",
    "statistical_inference_without_quantitative_analysis",
    "statistical_inference_missing_within_quantitative",
    "strict_design_outside_screen",
    "strict_design_without_method_present",
    "strict_design_without_quote",
    "method_present_without_parsed_type",
    "method_type_parse_or_unclassified",
    "unknown_evidence_level",
    "unknown_quantitative_level",
    "nonidentical_duplicate_pids",
    "classified_outside_manifest",
    "classified_excluded_by_ledger",
    "excluded_journal_in_manifest",
    "excluded_journal_in_classifications",
    "classification_manifest_journal_mismatch",
    "classified_hash_mismatch",
    "classified_fulltext_not_pass",
    "journal_area_unmapped",
    "required_core_boolean_missing",
    "method_present_missing_within_screen",
    "classified_exceeds_eligible_by_journal_period"
  ),
  n = c(
    nrow(manifest_raw) - dplyr::n_distinct(manifest_raw$pid),
    sum(is.na(manifest_raw$year) | !dplyr::between(manifest_raw$year, 2005L, 2025L)),
    sum(is.na(manifest_raw$document_type) | manifest_raw$document_type != "research-article"),
    sum(!dplyr::coalesce(analysis_df$is_empirical_paper, FALSE) & as.character(analysis_df$empirical_evidence_type) != "none", na.rm = TRUE),
    sum(
      dplyr::coalesce(analysis_df$is_empirical_quant_paper_torreblanca, FALSE) &
        !dplyr::coalesce(analysis_df$is_empirical_paper, FALSE)
    ),
    sum(dplyr::coalesce(analysis_df$is_empirical_quant_paper_torreblanca, FALSE) & analysis_df$quantitative_analysis_type == "none", na.rm = TRUE),
    sum(
      dplyr::coalesce(analysis_df$has_statistical_inference, FALSE) &
        !dplyr::coalesce(analysis_df$is_empirical_quant_paper_torreblanca, FALSE)
    ),
    sum(dplyr::coalesce(analysis_df$has_statistical_inference, FALSE) & analysis_df$quantitative_analysis_type == "none", na.rm = TRUE),
    inference_missing_within_quantitative,
    sum(analysis_df$strict_design_method & !dplyr::coalesce(analysis_df$credibility_revolution_screen_applicable, FALSE)),
    sum(
      analysis_df$strict_design_method &
        !dplyr::coalesce(analysis_df$credibility_revolution_method_present, FALSE)
    ),
    strict_without_quote,
    method_present_without_type,
    sum(method_long$method_class %in% c("parse_error", "unclassified")),
    unknown_evidence_levels,
    unknown_quantitative_levels,
    sum(!duplicate_pid_status$exact_duplicates_only),
    nrow(classified_outside_manifest),
    nrow(classified_excluded_by_ledger),
    nrow(excluded_journals_in_manifest),
    nrow(excluded_journals_in_classifications),
    nrow(journal_title_mismatches),
    sum(!hash_matches),
    sum(is.na(analysis_df$fulltext_validation_status) | analysis_df$fulltext_validation_status != "PASS"),
    sum(analysis_df$journal_area == "Área a revisar"),
    sum(boolean_missing_n$missing_n),
    method_present_missing_within_screen,
    coverage_exceeds_eligible
  ),
  expected = rep(0L, 28),
  severity = c(
    rep("error", 6),
    rep("warning", 3),
    rep("error", 19)
  ),
  implication = c(
    "O manifest deve conter um único registro por PID.",
    "Todos os artigos do manifest devem estar entre 2005 e 2025.",
    "O manifest analítico deve conter apenas research-article.",
    "Artigos não empíricos não devem carregar tipo de evidência empírica.",
    "O componente quantitativo pressupõe artigo empírico.",
    "Flag quantitativa exige tipo de análise quantitativa diferente de none.",
    "O schema permite inferência em um texto que não atende à definição de artigo quantitativo; o caso é auditado, mas não integra o numerador quantitativo.",
    "O schema permite inferência descritiva em artigo sem análise quantitativa própria; o caso é auditado, mas não integra o numerador quantitativo.",
    "O schema permite valor nulo; casos quantitativos sem classificação de inferência são excluídos desse denominador e reportados.",
    "Estratégias explícitas de identificação só são contadas nos artigos em que a identificação é especialmente relevante.",
    "Desenhos estritos exigem method_present TRUE.",
    "Desenhos estritos exigem citação textual do desenho.",
    "method_present TRUE exige ao menos um tipo de método parseado.",
    "Todo tipo de método deve pertencer à taxonomia conhecida e ter JSON válido.",
    "Todo tipo de evidência deve pertencer aos níveis previstos.",
    "Todo tipo de análise quantitativa deve pertencer aos níveis previstos.",
    "Duplicatas exatas podem ser removidas na camada analítica; classificações divergentes bloqueiam a análise.",
    "Nenhuma classificação analítica deve estar fora do manifest.",
    "Nenhuma classificação analítica deve estar no ledger de exclusões.",
    "Nenhum periódico excluído pode aparecer no manifest analítico.",
    "Nenhum periódico excluído pode aparecer nas classificações canônicas.",
    "O periódico da classificação deve coincidir com o periódico do manifest.",
    "Classificação deve apontar para o mesmo texto do manifest.",
    "Toda classificação analítica deve ter fulltext PASS.",
    "Todo periódico analítico deve ter área mapeada.",
    "Campos booleanos centrais não podem ficar ausentes.",
    "A presença de método deve estar preenchida em todos os artigos selecionados para examinar identificação.",
    "Classificados não podem superar elegíveis em nenhuma célula periódico-período."
  )
) |>
  dplyr::mutate(
    status = dplyr::case_when(
      n == expected ~ "PASS",
      severity == "warning" ~ "WARN",
      TRUE ~ "FAIL"
    )
  ) |>
  dplyr::select(check, status, severity, n, expected, implication)

if (any(logical_inconsistencies$status == "FAIL")) {
  readr::write_csv(logical_inconsistencies, file.path(analysis_dir, "current_analysis_validation_checks.csv"))
  readr::write_csv(boolean_missing_n, file.path(analysis_dir, "current_boolean_missingness.csv"))
  readr::write_csv(duplicate_pid_rows, file.path(analysis_dir, "current_duplicate_pid_rows.csv"))
  readr::write_csv(duplicate_pid_status, file.path(analysis_dir, "current_duplicate_pid_status.csv"))
  stop(
    "Validações lógicas falharam: ",
    paste(logical_inconsistencies$check[logical_inconsistencies$status == "FAIL"], collapse = "; ")
  )
}

readr::write_csv(analysis_df |> dplyr::select(-method_type), file.path(analysis_dir, "paper_analysis_dataset_current.csv"))
readr::write_csv(method_long, file.path(analysis_dir, "paper_method_long_current.csv"))
readr::write_csv(logical_inconsistencies, file.path(analysis_dir, "current_analysis_validation_checks.csv"))
readr::write_csv(boolean_missing_n, file.path(analysis_dir, "current_boolean_missingness.csv"))
readr::write_csv(duplicate_pid_rows, file.path(analysis_dir, "current_duplicate_pid_rows.csv"))
readr::write_csv(duplicate_pid_status, file.path(analysis_dir, "current_duplicate_pid_status.csv"))
readr::write_csv(classified_outside_manifest, file.path(analysis_dir, "current_classified_outside_manifest.csv"))
readr::write_csv(classified_excluded_by_ledger, file.path(analysis_dir, "current_classified_excluded_by_ledger.csv"))
readr::write_csv(excluded_journals_in_manifest, file.path(analysis_dir, "current_excluded_journals_in_manifest.csv"))
readr::write_csv(excluded_journals_in_classifications, file.path(analysis_dir, "current_excluded_journals_in_classifications.csv"))
readr::write_csv(journal_title_mismatches, file.path(analysis_dir, "current_journal_title_mismatches.csv"))
readr::write_csv(coverage_by_journal_period, file.path(analysis_dir, "current_coverage_by_journal_period.csv"))

readr::write_csv(denominator_summary, file.path(tables_dir, "denominator_summary.csv"))
readr::write_csv(table_1_corpus_description, file.path(tables_dir, "table_1_corpus_description.csv"))
readr::write_csv(table_2_methodological_dimensions, file.path(tables_dir, "table_2_methodological_dimensions.csv"))
readr::write_csv(table_3_causality_credibility, file.path(tables_dir, "table_3_causality_credibility.csv"))
readr::write_csv(complete_journal_profile, file.path(tables_dir, "table_4_complete_journal_profile.csv"))
readr::write_csv(claim_method_alignment, file.path(tables_dir, "table_5_claim_method_alignment.csv"))
readr::write_csv(claim_evidence_matrix, file.path(tables_dir, "table_6_claim_evidence_matrix.csv"))
readr::write_csv(qualitative_profile, file.path(tables_dir, "table_7_qualitative_profile_by_journal.csv"))
readr::write_csv(qualitative_complete_summary, file.path(tables_dir, "table_8_qualitative_complete_summary.csv"))
readr::write_csv(period_journal_profile, file.path(tables_dir, "period_complete_journal_profile.csv"))
readr::write_csv(period_equal_weight_profile, file.path(tables_dir, "period_equal_weight_profile.csv"))
readr::write_csv(period_article_weight_profile, file.path(tables_dir, "period_article_weight_profile.csv"))
readr::write_csv(year_journal_profile, file.path(tables_dir, "year_complete_journal_profile.csv"))
readr::write_csv(year_article_weight_profile, file.path(tables_dir, "year_article_weight_profile.csv"))
readr::write_csv(strict_method_diffusion, file.path(tables_dir, "strict_method_diffusion.csv"))
readr::write_csv(strict_method_totals, file.path(tables_dir, "strict_method_totals.csv"))
readr::write_csv(tough_call_profile, file.path(tables_dir, "tough_call_profile.csv"))
readr::write_csv(coverage_by_journal, file.path(tables_dir, "coverage_by_journal.csv"))

theme_paper <- function() {
  ggplot2::theme_minimal(base_size = 10.5) +
    ggplot2::theme(
      plot.title.position = "plot",
      plot.title = ggplot2::element_text(face = "bold", size = 12),
      plot.subtitle = ggplot2::element_text(color = "grey30", size = 9.5),
      plot.caption = ggplot2::element_text(color = "grey30", hjust = 0, size = 8),
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold")
    )
}

figure_1_data <- tibble::tibble(
  group = c("Cobertura", "Cobertura", "Evidência", "Quantificação", "Afirmações", "Identificação", "Identificação"),
  measure = c(
    "Corpus elegível",
    "Classificados",
    "Empíricos",
    "Componente quantitativo",
    "Afirmação causal/explicativa",
    "Casos relevantes para identificação",
    "Estratégia explícita de identificação"
  ),
  n = c(
    n_manifest,
    n_classified,
    overall_metrics$n_empirical,
    overall_metrics$n_quantitative,
    overall_metrics$n_claim,
    overall_metrics$n_screen,
    overall_metrics$n_strict
  ),
  denominator = c(
    "manifest elegível",
    "manifest elegível",
    "classificados",
    "empíricos",
    "classificados",
    "classificados",
    "casos relevantes"
  ),
  denominator_n = c(
    n_manifest,
    n_manifest,
    n_classified,
    overall_metrics$n_empirical,
    n_classified,
    n_classified,
    overall_metrics$n_screen
  )
) |>
  dplyr::mutate(
    percent = fmt_pct(n, denominator_n),
    measure = factor(measure, levels = rev(measure)),
    label = paste0(fmt_n(n), " / ", fmt_n(denominator_n), " (", fmt_pct_label(percent), ")"),
    label_hjust = ifelse(percent >= 80, 1.08, -0.08)
  )

figure_1 <- figure_1_data |>
  ggplot2::ggplot(ggplot2::aes(x = percent, y = measure, color = group)) +
  ggplot2::geom_segment(ggplot2::aes(x = 0, xend = percent, yend = measure), linewidth = 0.7, color = "grey80") +
  ggplot2::geom_point(size = 3) +
  ggplot2::geom_text(ggplot2::aes(label = label, hjust = label_hjust), size = 3, color = "grey15") +
  ggplot2::scale_x_continuous(limits = c(0, 105), breaks = seq(0, 100, 20), labels = function(x) paste0(x, "%")) +
  ggplot2::scale_color_manual(values = c(
    Cobertura = "#4C78A8",
    Evidência = "#59A14F",
    Quantificação = "#F28E2B",
    Afirmações = "#B279A2",
    Identificação = "#E15759"
  )) +
  ggplot2::labs(
    title = "Dimensões observadas e seus denominadores",
    subtitle = "As linhas não formam um funil único: cada percentual usa o denominador indicado no rótulo.",
    x = "Percentual no denominador da linha",
    y = NULL,
    color = NULL,
    caption = "Fonte: classificação canônica por leitura integral. Corpus completo ainda parcialmente classificado."
  ) +
  theme_paper() +
  ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())

ggplot2::ggsave(
  file.path(figures_dir, "figure_1_corpus_funnel.pdf"),
  figure_1,
  width = 7,
  height = 4.5,
  units = "in",
  device = grDevices::pdf
)

figure_2 <- complete_journal_profile_long |>
  dplyr::mutate(
    journal_title = stringr::str_wrap(journal_title, 24),
    metric_label = factor(metric_label, levels = unname(metric_labels))
  ) |>
  ggplot2::ggplot(ggplot2::aes(x = metric_label, y = journal_title, fill = percent)) +
  ggplot2::geom_tile(color = "white", linewidth = 0.6) +
  ggplot2::geom_text(ggplot2::aes(label = fmt_pct_label(percent)), size = 3) +
  ggplot2::scale_fill_gradient(low = "#F2F5F8", high = "#2F6B8A", limits = c(0, 100)) +
  ggplot2::labs(
    title = "Perfil metodológico dos periódicos com classificação completa",
    subtitle = paste0(
      n_complete_journals,
      " periódicos, ",
      fmt_n(n_complete_journal_articles),
      " artigos; o denominador varia por dimensão."
    ),
    x = NULL,
    y = NULL,
    fill = "%"
  ) +
  theme_paper() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
    panel.grid = ggplot2::element_blank()
  )

ggplot2::ggsave(
  file.path(figures_dir, "figure_2_journal_dimension_matrix.pdf"),
  figure_2,
  width = 7,
  height = 4.8,
  units = "in",
  device = grDevices::pdf
)

period_plot_data <- period_equal_weight_profile |>
  dplyr::select(
    period_3,
    pct_empirical,
    pct_quantitative,
    pct_inference,
    pct_claim,
    pct_screen,
    pct_strict
  ) |>
  tidyr::pivot_longer(dplyr::starts_with("pct_"), names_to = "metric", values_to = "percent") |>
  dplyr::mutate(
    metric = stringr::str_remove(metric, "^pct_"),
    metric_label = factor(unname(metric_labels[metric]), levels = unname(metric_labels)),
    period_3 = factor(period_3, levels = period_levels)
  )

figure_3 <- period_plot_data |>
  ggplot2::ggplot(ggplot2::aes(x = period_3, y = percent, group = 1)) +
  ggplot2::geom_line(color = "#2F6B8A", linewidth = 0.8) +
  ggplot2::geom_point(color = "#2F6B8A", size = 2.2) +
  ggplot2::geom_text(ggplot2::aes(label = fmt_pct_label(percent)), vjust = -0.8, size = 2.8) +
  ggplot2::facet_wrap(~ metric_label, ncol = 3, scales = "fixed") +
  ggplot2::scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 25),
    labels = function(x) paste0(x, "%"),
    expand = ggplot2::expansion(mult = c(0, 0.05))
  ) +
  ggplot2::labs(
    title = "Variação por período em periódicos completos com suporte temporal comum",
    subtitle = paste0(
      "Média simples de ",
      length(temporal_complete_journals),
      " periódicos; composição editorial mantida constante."
    ),
    x = "Período",
    y = "Percentual",
    caption = "Descrição padronizada por periódico; não identifica efeito causal do tempo. Denominadores variam por dimensão."
  ) +
  theme_paper() +
  ggplot2::theme(legend.position = "none")

ggplot2::ggsave(
  file.path(figures_dir, "figure_3_period_variation.pdf"),
  figure_3,
  width = 7,
  height = 5.2,
  units = "in",
  device = grDevices::pdf
)

year_plot_data <- year_article_weight_profile |>
  dplyr::select(
    year,
    pct_empirical,
    pct_quantitative,
    pct_inference,
    pct_claim,
    pct_screen,
    pct_strict
  ) |>
  tidyr::pivot_longer(dplyr::starts_with("pct_"), names_to = "metric", values_to = "percent") |>
  dplyr::mutate(
    metric = stringr::str_remove(metric, "^pct_"),
    metric_label = factor(unname(metric_labels[metric]), levels = unname(metric_labels))
  )

year_axis_breaks <- sort(unique(c(
  seq(min(year_article_weight_profile$year), max(year_article_weight_profile$year), by = 3),
  max(year_article_weight_profile$year)
)))

figure_7 <- year_plot_data |>
  ggplot2::ggplot(ggplot2::aes(x = year, y = percent)) +
  ggplot2::geom_line(color = "#2F6B8A", linewidth = 0.7) +
  ggplot2::geom_point(color = "#2F6B8A", size = 1.5) +
  ggplot2::facet_wrap(~ metric_label, ncol = 3, scales = "fixed") +
  ggplot2::scale_x_continuous(breaks = year_axis_breaks) +
  ggplot2::scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 25),
    labels = function(x) paste0(x, "%"),
    expand = ggplot2::expansion(mult = c(0, 0.03))
  ) +
  ggplot2::labs(
    title = "Variação anual em periódicos completos com suporte temporal comum",
    subtitle = paste0(
      "Proporções agrupadas de ",
      length(temporal_complete_journals),
      " periódicos; ",
      min(year_article_weight_profile$year),
      " a ",
      max(year_article_weight_profile$year),
      "."
    ),
    x = "Ano",
    y = "Percentual",
    caption = paste0(
      "Apenas anos com artigos nos ",
      length(temporal_complete_journals),
      " periódicos. Série descritiva; denominadores variam por dimensão."
    )
  ) +
  theme_paper() +
  ggplot2::theme(
    legend.position = "none",
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
  )

ggplot2::ggsave(
  file.path(figures_dir, "figure_7_year_variation.pdf"),
  figure_7,
  width = 7,
  height = 5.2,
  units = "in",
  device = grDevices::pdf
)

coverage_plot_data <- coverage_by_journal |>
  dplyr::mutate(
    journal_label = stringr::str_wrap(journal_title, 28),
    journal_label = factor(journal_label, levels = rev(journal_label)),
    label = paste0(fmt_n(classified_n), "/", fmt_n(eligible_n))
  )

figure_4 <- coverage_plot_data |>
  ggplot2::ggplot(ggplot2::aes(x = coverage_percent, y = journal_label, color = coverage_status)) +
  ggplot2::geom_segment(ggplot2::aes(x = 0, xend = coverage_percent, yend = journal_label), color = "grey80", linewidth = 0.6) +
  ggplot2::geom_point(size = 2.8) +
  ggplot2::geom_text(ggplot2::aes(label = label), hjust = -0.15, size = 2.8, color = "grey15") +
  ggplot2::scale_x_continuous(limits = c(0, 116), breaks = seq(0, 100, 20), labels = function(x) paste0(x, "%")) +
  ggplot2::scale_color_manual(values = c(Completo = "#2E7D32", Parcial = "#E69F00", `Não iniciado` = "#9E9E9E")) +
  ggplot2::labs(
    title = "Cobertura da classificação por periódico",
    subtitle = "Os rótulos mostram artigos classificados sobre artigos elegíveis após o ledger de exclusões.",
    x = "Cobertura",
    y = NULL,
    color = "Status",
    caption = paste0(
      n_complete_journals,
      " periódicos completos; comparações substantivas principais são restritas a esse estrato."
    )
  ) +
  theme_paper() +
  ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())

ggplot2::ggsave(
  file.path(figures_dir, "figure_4_journal_period_coverage.pdf"),
  figure_4,
  width = 7,
  height = 5.5,
  units = "in",
  device = grDevices::pdf
)

alignment_levels <- c(
  "Afirmação e estratégia explícita de identificação",
  "Afirmação empírica e componente quantitativo, sem estratégia explícita",
  "Afirmação empírica sem componente quantitativo",
  "Afirmação em artigo não empírico",
  "Componente quantitativo sem afirmação",
  "Estratégia explícita sem afirmação codificada",
  "Sem afirmação ou componente quantitativo"
)

figure_5 <- claim_method_alignment |>
  dplyr::mutate(
    alignment_category = factor(alignment_category, levels = rev(alignment_levels)),
    label = paste0(fmt_n(n), " (", fmt_pct_label(percent), ")")
  ) |>
  ggplot2::ggplot(ggplot2::aes(x = percent, y = alignment_category)) +
  ggplot2::geom_col(fill = "#4C78A8", width = 0.7) +
  ggplot2::geom_text(ggplot2::aes(label = label), hjust = -0.08, size = 3) +
  ggplot2::scale_x_continuous(limits = c(0, 60), breaks = seq(0, 60, 10), labels = function(x) paste0(x, "%")) +
  ggplot2::labs(
    title = "Afirmações, uso de dados quantitativos e estratégias de identificação",
    subtitle = "Categorias descritivas mutuamente exclusivas entre os artigos já classificados.",
    x = "Percentual dos artigos classificados",
    y = NULL
  ) +
  theme_paper() +
  ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())

ggplot2::ggsave(
  file.path(figures_dir, "figure_5_claim_method_alignment.pdf"),
  figure_5,
  width = 7,
  height = 4.4,
  units = "in",
  device = grDevices::pdf
)

if (nrow(strict_method_totals) > 0) {
  figure_6 <- strict_method_totals |>
    dplyr::mutate(method_label = factor(method_label, levels = rev(method_label))) |>
    ggplot2::ggplot(ggplot2::aes(x = article_method_n, y = method_label)) +
    ggplot2::geom_col(fill = "#E15759", width = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = article_method_n), hjust = -0.15, size = 3) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.15))) +
    ggplot2::labs(
      title = "Métodos de identificação nos periódicos com classificação completa",
      subtitle = "Contagem artigo-método; um artigo pode mobilizar mais de uma estratégia.",
      x = "Artigos com o método",
      y = NULL,
      caption = "A contagem registra famílias de estratégia explicitamente mencionadas; não avalia sua qualidade."
    ) +
    theme_paper() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())

  ggplot2::ggsave(
    file.path(figures_dir, "figure_6_strict_method_distribution.pdf"),
    figure_6,
    width = 7,
    height = max(3.5, 0.38 * nrow(strict_method_totals) + 1.8),
    units = "in",
    device = grDevices::pdf
  )
}

audit_report <- c(
  "# Atualização analítica do paper com o CSV canônico",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Universo reconciliado",
  "",
  paste0("- Linhas no CSV canônico bruto: ", nrow(classifications_source), "."),
  paste0("- Linhas duplicadas exatas removidas apenas na camada analítica: ", nrow(classifications_source) - nrow(classifications_raw), "."),
  paste0("- Artigos elegíveis no manifest após ledger: ", n_manifest, "."),
  paste0("- Artigos elegíveis classificados: ", n_classified, " (", fmt_pct_label(fmt_pct(n_classified, n_manifest)), ")."),
  paste0("- Artigos elegíveis ainda não classificados: ", n_remaining, "."),
  paste0("- Classificações preservadas fora do manifest: ", nrow(classified_outside_manifest), "."),
  paste0("- Classificações excluídas pelo ledger: ", nrow(classified_excluded_by_ledger), "."),
  paste0("- Periódicos excluídos pelo ledger: ", paste(excluded_journals$journal_title, collapse = "; "), "."),
  paste0("- Intervalo de recuperação dos textos no manifest: ", min(manifest_raw$retrieved_at, na.rm = TRUE), " a ", max(manifest_raw$retrieved_at, na.rm = TRUE), "."),
  paste0("- MD5 do manifest: `", unname(tools::md5sum(manifest_path)), "`."),
  paste0("- MD5 do CSV canônico: `", unname(tools::md5sum(classifications_path)), "`."),
  paste0("- MD5 do ledger de artigos: `", unname(tools::md5sum(excluded_articles_path)), "`."),
  paste0("- MD5 do ledger de periódicos: `", unname(tools::md5sum(excluded_journals_path)), "`."),
  "",
  "## Estratos analíticos",
  "",
  paste0("- Periódicos completos: ", paste(complete_journals, collapse = "; "), "."),
  paste0("- Artigos nos periódicos completos: ", n_complete_journal_articles, "."),
  paste0("- Periódicos completos com artigos nos três períodos: ", paste(temporal_complete_journals, collapse = "; "), "."),
  "",
  "## Regra de interpretação",
  "",
  "Os agregados dos artigos classificados continuam preliminares para o universo de onze periódicos, porque a seleção segue a ordem operacional da classificação e não um desenho amostral representativo. Os resultados dos periódicos completos cobrem todos os artigos desses periódicos, mas os rótulos automatizados ainda não foram integralmente adjudicados por humanos. A comparação temporal usa somente periódicos completos com artigos nos três períodos e reporta tanto a média com peso igual por periódico quanto a proporção agrupada por artigo.",
  "",
  "## Validações lógicas",
  "",
  paste0("- Checks PASS: ", sum(logical_inconsistencies$status == "PASS"), " de ", nrow(logical_inconsistencies), "."),
  paste0("- Checks FAIL: ", paste(logical_inconsistencies$check[logical_inconsistencies$status == "FAIL"], collapse = "; ")), 
  "",
  "## Lacunas que permanecem",
  "",
  "- `method_explicitness` não está disponível no CSV canônico.",
  "- `empirical_article_format` não está disponível no CSV canônico.",
  "- A categoria de afirmação combina pretensões causais e explicativas; não deve ser interpretada como afirmação causal estrita.",
  "- A classificação em escala ainda carece de validação humana estratificada e adjudicação dos casos difíceis e dos métodos raros.",
  "- A proveniência de modelo e esforço de classificação ainda não está consolidada por PID; por isso, variação temporal pode refletir mudança do classificador.",
  "- Os desenhos estritos registram presença nominal de famílias de método, não qualidade de implementação nem validade da identificação.",
  "- Qualis e gênero de autoria não entram nesta atualização.",
  "",
  "## Artefatos principais",
  "",
  "- `data/processed/paper_analysis/paper_analysis_dataset_current.csv`",
  "- `output/tables/paper/table_4_complete_journal_profile.csv`",
  "- `output/tables/paper/table_5_claim_method_alignment.csv`",
  "- `output/tables/paper/table_8_qualitative_complete_summary.csv`",
  "- `output/tables/paper/period_equal_weight_profile.csv`",
  "- `output/tables/paper/period_article_weight_profile.csv`",
  "- `output/tables/paper/year_article_weight_profile.csv`",
  "- `output/figures/paper/figure_2_journal_dimension_matrix.pdf`",
  "- `output/figures/paper/figure_3_period_variation.pdf`",
  "- `output/figures/paper/figure_7_year_variation.pdf`",
  "- `output/figures/paper/figure_5_claim_method_alignment.pdf`"
)

write_utf8_lines(audit_report, file.path(audit_dir, "current_canonical_analysis_audit.md"))
capture.output(sessionInfo(), file = file.path(analysis_dir, "current_analysis_session_info.txt"))

message("Análise atualizada: ", n_classified, " artigos elegíveis classificados de ", n_manifest, ".")
message("Periódicos completos: ", paste(complete_journals, collapse = "; "))
message("Artefatos escritos em: ", tables_dir, " e ", figures_dir)
