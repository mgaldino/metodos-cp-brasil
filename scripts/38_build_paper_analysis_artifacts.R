## 38_build_paper_analysis_artifacts.R
## Build preliminary paper dataset, variable audit, tables, and figures.

options(scipen = 999, encoding = "UTF-8")
set.seed(20260708)

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(jsonlite)
  library(readr)
  library(stringr)
  library(tidyr)
})

project_dir <- normalizePath(".", mustWork = TRUE)
path <- function(...) file.path(project_dir, ...)
period_3_levels <- c("2005-2011", "2012-2018", "2019-2025")

manifest_path <- path("data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv")
classifications_path <- path("data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv")

analysis_dir <- path("data/processed/paper_analysis")
tables_dir <- path("output/tables/paper")
figures_dir <- path("output/figures/paper")
audit_dir <- path("quality_reports/paper_variable_audit")
dir.create(analysis_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(audit_dir, recursive = TRUE, showWarnings = FALSE)

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
  parsed <- tryCatch(jsonlite::fromJSON(x), error = function(e) character())
  as.character(parsed)
}

method_type_parse_status <- function(x) {
  if (is.na(x) || stringr::str_trim(x) == "") {
    return("empty")
  }
  parsed <- tryCatch(jsonlite::fromJSON(x), error = function(e) NULL)
  if (is.null(parsed)) {
    return("parse_error")
  }
  "parsed"
}

period_3 <- function(year) {
  factor(dplyr::case_when(
    dplyr::between(year, 2005L, 2011L) ~ "2005-2011",
    dplyr::between(year, 2012L, 2018L) ~ "2012-2018",
    dplyr::between(year, 2019L, 2025L) ~ "2019-2025",
    TRUE ~ NA_character_
  ), levels = period_3_levels)
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
    journal_title %in% c(
      "Revista de Administração Pública",
      "Cadernos EBAPE.BR",
      "Cadernos Gestão Pública e Cidadania"
    ) ~ "Administração Pública",
    journal_title %in% c(
      "Dados",
      "DADOS - Revista de Ciências Sociais",
      "Lua Nova: Revista de Cultura e Política",
      "Novos Estudos CEBRAP",
      "Novos estudos CEBRAP",
      "Revista Brasileira de Ciências Sociais"
    ) ~ "Ciência Política e Ciências Sociais",
    TRUE ~ "Área a revisar"
  )
}

fmt_pct <- function(n, d) {
  dplyr::if_else(is.na(d) | d == 0, NA_real_, round(100 * n / d, 1))
}

write_utf8_lines <- function(lines, file) {
  con <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  writeLines(enc2utf8(lines), con = con, useBytes = TRUE)
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

metric_labels <- c(
  pct_empirical = "Artigos empíricos",
  pct_quantitative = "Empíricos quantitativos",
  pct_statistical_inference = "Inferência estatística",
  pct_causal_claim = "Claim causal/explicativo",
  pct_screen = "Screen de credibilidade",
  pct_strict_design = "Desenho estrito"
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
  causal_discovery = "Descoberta causal",
  other_modern_causal_method = "Outro método causal moderno",
  observational_regression_with_causal_claim_no_design = "Regressão observacional com linguagem causal",
  fixed_effects_causal_panel_claim = "Painel com efeitos fixos e linguagem causal",
  none_detected = "Nenhum método detectado"
)

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE) |>
  dplyr::mutate(
    year = as.integer(year),
    period_3 = period_3(year),
    journal_area = map_journal_area(journal_title),
    body_word_count = as.numeric(body_word_count)
  )

classifications <- readr::read_csv(classifications_path, show_col_types = FALSE) |>
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
    method_type_parse_status = vapply(
      credibility_revolution_method_type,
      method_type_parse_status,
      character(1)
    ),
    method_type = lapply(credibility_revolution_method_type, parse_method_types),
    sample_or_data_source_present = !is.na(sample_or_data_source) &
      stringr::str_squish(sample_or_data_source) != "" &
      stringr::str_to_lower(stringr::str_squish(sample_or_data_source)) != "none"
  )

analysis_df <- classifications |>
  dplyr::semi_join(manifest |> dplyr::select(pid), by = "pid") |>
  dplyr::left_join(
    manifest |>
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
        fulltext_validation_status,
        pilot_exclusion_policy,
        scope_exclusion_policy
      ),
    by = "pid"
  ) |>
  dplyr::mutate(
    journal_title = dplyr::coalesce(journal_title, manifest_journal_title),
    journal_area = dplyr::coalesce(journal_area, map_journal_area(journal_title))
  )

method_long <- analysis_df |>
  dplyr::select(
    pid,
    title,
    journal_title,
    journal_area,
    year,
    period_3,
    eligible_order,
    credibility_revolution_method_present,
    method_type,
    causal_design_quote,
    tough_call_reason
  ) |>
  tidyr::unnest(method_type, keep_empty = FALSE) |>
  dplyr::mutate(
    method_class = dplyr::case_when(
      method_type %in% strict_design_methods ~ "strict_design_method",
      method_type == "other_modern_causal_method" ~ "broad_other_modern_causal_method",
      method_type %in% diagnostic_not_design_methods ~ "diagnostic_not_design",
      TRUE ~ "unclassified"
    )
  )

strict_pids <- method_long |>
  dplyr::filter(method_class == "strict_design_method") |>
  dplyr::pull(pid) |>
  unique()

other_modern_pids <- method_long |>
  dplyr::filter(method_class == "broad_other_modern_causal_method") |>
  dplyr::pull(pid) |>
  unique()

diagnostic_pids <- method_long |>
  dplyr::filter(method_class == "diagnostic_not_design") |>
  dplyr::pull(pid) |>
  unique()

analysis_df <- analysis_df |>
  dplyr::mutate(
    strict_design_method = pid %in% strict_pids,
    diagnostic_not_design = pid %in% diagnostic_pids,
    other_modern_causal_method = pid %in% other_modern_pids,
    inclusive_design_or_other_modern = strict_design_method | other_modern_causal_method
  )

n_manifest <- dplyr::n_distinct(manifest$pid)
n_classified <- dplyr::n_distinct(analysis_df$pid)
n_empirical <- sum(analysis_df$is_empirical_paper, na.rm = TRUE)
n_quant <- sum(analysis_df$is_empirical_quant_paper_torreblanca, na.rm = TRUE)
n_causal <- sum(analysis_df$causal_or_explanatory_claim_present, na.rm = TRUE)
n_screen <- sum(analysis_df$credibility_revolution_screen_applicable, na.rm = TRUE)
n_strict <- sum(analysis_df$strict_design_method, na.rm = TRUE)
hash_matches <- !is.na(analysis_df$classification_input_text_hash) &
  !is.na(analysis_df$manifest_input_text_hash) &
  analysis_df$classification_input_text_hash == analysis_df$manifest_input_text_hash

screen_without_causal_claim <- analysis_df |>
  dplyr::filter(
    dplyr::coalesce(credibility_revolution_screen_applicable, FALSE),
    !dplyr::coalesce(causal_or_explanatory_claim_present, FALSE)
  ) |>
  dplyr::select(
    pid,
    title,
    journal_title,
    year,
    quantitative_analysis_type,
    credibility_revolution_screen_reason,
    credibility_revolution_method_present,
    credibility_revolution_method_type
  )

screen_reason_diagnostics <- analysis_df |>
  dplyr::filter(dplyr::coalesce(credibility_revolution_screen_applicable, FALSE)) |>
  dplyr::count(
    credibility_revolution_screen_reason,
    causal_or_explanatory_claim_present,
    is_empirical_quant_paper_torreblanca,
    name = "n"
  ) |>
  dplyr::arrange(credibility_revolution_screen_reason, causal_or_explanatory_claim_present)

method_overlap_summary <- tibble::tibble(
  overlap = c(
    "strict_and_diagnostic",
    "strict_and_other_modern",
    "diagnostic_and_other_modern",
    "strict_diagnostic_other_modern"
  ),
  n = c(
    sum(analysis_df$strict_design_method & analysis_df$diagnostic_not_design, na.rm = TRUE),
    sum(analysis_df$strict_design_method & analysis_df$other_modern_causal_method, na.rm = TRUE),
    sum(analysis_df$diagnostic_not_design & analysis_df$other_modern_causal_method, na.rm = TRUE),
    sum(analysis_df$strict_design_method & analysis_df$diagnostic_not_design & analysis_df$other_modern_causal_method, na.rm = TRUE)
  ),
  note = c(
    "Categorias de método não são mutuamente exclusivas; um artigo pode registrar desenho estrito e diagnóstico.",
    "Categorias de método não são mutuamente exclusivas; other_modern pode coexistir com desenho estrito.",
    "Categorias de método não são mutuamente exclusivas.",
    "Sobreposição tripla."
  )
)

artifact_validation_checks <- tibble::tibble(
  check = c(
    "classified_rows_positive",
    "strict_design_subset_of_screen",
    "screen_has_quant_or_causal_trigger",
    "screen_without_causal_claim_documented",
    "method_type_json_no_parse_errors",
    "method_type_present_when_method_present",
    "classification_hash_matches_manifest",
    "classified_fulltext_validation_pass",
    "journal_area_mapped"
  ),
  status = c(
    n_classified > 0,
    all(!analysis_df$strict_design_method | dplyr::coalesce(analysis_df$credibility_revolution_screen_applicable, FALSE)),
    all(!dplyr::coalesce(analysis_df$credibility_revolution_screen_applicable, FALSE) |
      dplyr::coalesce(analysis_df$is_empirical_quant_paper_torreblanca, FALSE) |
      dplyr::coalesce(analysis_df$causal_or_explanatory_claim_present, FALSE)),
    TRUE,
    !any(analysis_df$method_type_parse_status == "parse_error"),
    all(!dplyr::coalesce(analysis_df$credibility_revolution_method_present, FALSE) |
      lengths(analysis_df$method_type) > 0),
    all(hash_matches),
    all(analysis_df$fulltext_validation_status == "PASS"),
    !any(analysis_df$journal_area == "Área a revisar")
  ),
  value = c(
    as.character(n_classified),
    paste0(sum(analysis_df$strict_design_method & !dplyr::coalesce(analysis_df$credibility_revolution_screen_applicable, FALSE)), " exceções"),
    paste0(sum(dplyr::coalesce(analysis_df$credibility_revolution_screen_applicable, FALSE) &
      !dplyr::coalesce(analysis_df$is_empirical_quant_paper_torreblanca, FALSE) &
      !dplyr::coalesce(analysis_df$causal_or_explanatory_claim_present, FALSE)), " exceções"),
    paste0(nrow(screen_without_causal_claim), " casos screen=TRUE sem claim causal/explicativo; ver screen_without_causal_claim.csv"),
    paste0(sum(analysis_df$method_type_parse_status == "parse_error"), " erros de parse"),
    paste0(sum(dplyr::coalesce(analysis_df$credibility_revolution_method_present, FALSE) & lengths(analysis_df$method_type) == 0), " métodos presentes sem tipo parseado"),
    paste0(sum(!hash_matches), " divergências"),
    paste0(sum(analysis_df$fulltext_validation_status != "PASS"), " casos sem PASS"),
    paste0(sum(analysis_df$journal_area == "Área a revisar"), " linhas")
  ),
  implication = c(
    "Há artigos classificados para gerar artefatos preliminares.",
    "Todo desenho estrito deve pertencer ao screen de credibilidade.",
    "O screen pode ser acionado por critério quantitativo/modelagem ou por claim causal/explicativo.",
    "Casos de screen sem claim causal/explicativo são diagnóstico documentado, não falha automática.",
    "Tipos de método devem ser JSON válido ou vazio.",
    "Casos com método presente devem ter ao menos um tipo de método parseado.",
    "Classificações e manifest devem apontar para o mesmo texto de entrada.",
    "Artigos classificados devem ter texto integral validado como PASS no manifest.",
    "Todos os periódicos do manifest atual devem ter área mapeada."
  )
) |>
  dplyr::mutate(status = if_else(status, "PASS", "FAIL"))

variable_mapping <- tibble::tribble(
  ~variable, ~status, ~source, ~derivation_rule, ~used_in_main_text, ~classification_complement_needed,
  "is_empirical_paper", "available", "classifications_integral_reading.csv", "Classifier v3 boolean parsed from TRUE/FALSE.", TRUE, FALSE,
  "method_explicitness", "missing", "not available", "No defensible derivation from current schema without a complementary classification of method/data/analytic-strategy explicitness.", FALSE, TRUE,
  "empirical_evidence_type", "available", "classifications_integral_reading.csv", "Classifier v3 categorical field.", TRUE, FALSE,
  "quantitative_analysis_type", "available", "classifications_integral_reading.csv", "Classifier v3 categorical field.", TRUE, FALSE,
  "has_statistical_inference", "available", "classifications_integral_reading.csv", "Classifier v3 boolean parsed from TRUE/FALSE; interpreted only for quantitative articles.", TRUE, FALSE,
  "empirical_article_format", "missing", "not available", "Section reading logs are evidence for a future classifier, but the current logs do not encode IMRaD/essayistic format as a validated variable.", FALSE, TRUE,
  "causal_or_explanatory_claim_present", "available", "classifications_integral_reading.csv", "Classifier v3 boolean parsed from TRUE/FALSE.", TRUE, FALSE,
  "strict_design_method", "derived", "credibility_revolution_method_type", "TRUE if any method type is in the conservative strict-design list; SEM, mediation, observational regression and fixed effects without explicit design do not count.", TRUE, FALSE,
  "journal_title", "available", "manifest and classifications", "Use classification value when present, coalesced with manifest title.", TRUE, FALSE,
  "journal_area", "derived", "journal_title", "Hand-coded journal-title map in this script; unknown journals flagged as 'Área a revisar'.", TRUE, TRUE,
  "period_3", "derived", "year", "2005-2011, 2012-2018, 2019-2025.", TRUE, FALSE
)

denominator_summary <- tibble::tibble(
  denominator = c(
    "Corpus completo elegível",
    "Artigos classificados por leitura integral",
    "Artigos ainda não classificados",
    "Artigos empíricos classificados",
    "Artigos empíricos quantitativos classificados",
    "Artigos com claim causal ou explicativo classificados",
    "Artigos no screen de credibilidade classificados",
    "Artigos classificados com desenho estrito"
  ),
  n = c(
    n_manifest,
    n_classified,
    n_manifest - n_classified,
    n_empirical,
    n_quant,
    n_causal,
    n_screen,
    n_strict
  ),
  denominator_reference = c(
    "manifest completo",
    "manifest completo",
    "manifest completo",
    "classificados",
    "classificados",
    "classificados",
    "classificados",
    "classificados"
  ),
  denominator_n = c(
    n_manifest,
    n_manifest,
    n_manifest,
    n_classified,
    n_classified,
    n_classified,
    n_classified,
    n_classified
  ),
  percent = c(
    100,
    fmt_pct(n_classified, n_manifest),
    fmt_pct(n_manifest - n_classified, n_manifest),
    fmt_pct(n_empirical, n_classified),
    fmt_pct(n_quant, n_classified),
    fmt_pct(n_causal, n_classified),
    fmt_pct(n_screen, n_classified),
    fmt_pct(n_strict, n_classified)
  )
)

table_1_corpus_description <- manifest |>
  dplyr::count(journal_area, journal_title, period_3, name = "manifest_n") |>
  dplyr::left_join(
    analysis_df |>
      dplyr::count(journal_area, journal_title, period_3, name = "classified_n"),
    by = c("journal_area", "journal_title", "period_3")
  ) |>
  dplyr::mutate(
    classified_n = dplyr::coalesce(classified_n, 0L),
    coverage_percent = fmt_pct(classified_n, manifest_n)
  ) |>
  dplyr::select(-coverage_percent) |>
  tidyr::pivot_wider(
    names_from = period_3,
    values_from = c(manifest_n, classified_n),
    values_fill = 0
  ) |>
  dplyr::mutate(
    manifest_total = `manifest_n_2005-2011` + `manifest_n_2012-2018` + `manifest_n_2019-2025`,
    classified_total = `classified_n_2005-2011` + `classified_n_2012-2018` + `classified_n_2019-2025`,
    coverage_percent = fmt_pct(classified_total, manifest_total)
  ) |>
  dplyr::select(
    journal_area,
    journal_title,
    `manifest_n_2005-2011`,
    `manifest_n_2012-2018`,
    `manifest_n_2019-2025`,
    `classified_n_2005-2011`,
    `classified_n_2012-2018`,
    `classified_n_2019-2025`,
    manifest_total,
    classified_total,
    coverage_percent
  ) |>
  dplyr::arrange(journal_area, journal_title)

table_2_methodological_dimensions <- tibble::tribble(
  ~dimension, ~category, ~n, ~denominator, ~denominator_n, ~percent, ~note,
  "Evidência", "Artigo empírico", n_empirical, "classificados", n_classified, fmt_pct(n_empirical, n_classified), "Variável disponível no classificador atual.",
  "Evidência", "Somente qualitativo", sum(analysis_df$empirical_evidence_type == "qualitative_only", na.rm = TRUE), "classificados", n_classified, fmt_pct(sum(analysis_df$empirical_evidence_type == "qualitative_only", na.rm = TRUE), n_classified), "Variável disponível no classificador atual.",
  "Evidência", "Somente quantitativo", sum(analysis_df$empirical_evidence_type == "quantitative_only", na.rm = TRUE), "classificados", n_classified, fmt_pct(sum(analysis_df$empirical_evidence_type == "quantitative_only", na.rm = TRUE), n_classified), "Variável disponível no classificador atual.",
  "Evidência", "Misto", sum(analysis_df$empirical_evidence_type == "mixed_empirical", na.rm = TRUE), "classificados", n_classified, fmt_pct(sum(analysis_df$empirical_evidence_type == "mixed_empirical", na.rm = TRUE), n_classified), "Variável disponível no classificador atual.",
  "Quantificação", "Modelagem estatística", sum(analysis_df$quantitative_analysis_type == "statistical_modeling", na.rm = TRUE), "classificados", n_classified, fmt_pct(sum(analysis_df$quantitative_analysis_type == "statistical_modeling", na.rm = TRUE), n_classified), "Variável disponível no classificador atual.",
  "Quantificação", "Inferência estatística", sum(analysis_df$has_statistical_inference, na.rm = TRUE), "classificados", n_classified, fmt_pct(sum(analysis_df$has_statistical_inference, na.rm = TRUE), n_classified), "Variável disponível no classificador atual.",
  "Explicitação", "method_explicitness", NA_integer_, "não disponível", NA_integer_, NA_real_, "Não usada como resultado; exige classificação complementar.",
  "Formato", "empirical_article_format", NA_integer_, "não disponível", NA_integer_, NA_real_, "Não usada como resultado; exige classificação complementar."
)

table_3_causality_credibility <- tibble::tribble(
  ~panel, ~dimension, ~category, ~n, ~denominator, ~denominator_n, ~percent, ~note,
  "Claims e screen", "Causalidade", "Claim causal ou explicativo", n_causal, "classificados", n_classified, fmt_pct(n_causal, n_classified), "Variável disponível no classificador atual.",
  "Claims e screen", "Causalidade", "Screen de credibilidade aplicável", n_screen, "classificados", n_classified, fmt_pct(n_screen, n_classified), "Screen pode ser acionado por modelagem/critério quantitativo ou por claim causal/explicativo.",
  "Claims e screen", "Credibilidade", "Desenho estrito de identificação", n_strict, "screen de credibilidade", n_screen, fmt_pct(n_strict, n_screen), "Numerador conservador do paper; também corresponde a 2,3% dos classificados.",
  "Diagnóstico de método (não exclusivo)", "Credibilidade", "Diagnóstico, não desenho", sum(analysis_df$diagnostic_not_design, na.rm = TRUE), "classificados", n_classified, fmt_pct(sum(analysis_df$diagnostic_not_design, na.rm = TRUE), n_classified), "Categorias de método não são mutuamente exclusivas; inclui regressão observacional causal, efeitos fixos sem desenho ou nenhum método detectado.",
  "Diagnóstico de método (não exclusivo)", "Credibilidade", "Outro método moderno a auditar", sum(analysis_df$other_modern_causal_method, na.rm = TRUE), "classificados", n_classified, fmt_pct(sum(analysis_df$other_modern_causal_method, na.rm = TRUE), n_classified), "Categorias de método não são mutuamente exclusivas; fila conservadora de auditoria."
)

journal_metrics <- analysis_df |>
  dplyr::group_by(journal_title) |>
  dplyr::summarise(
    classified_n = dplyr::n(),
    pct_empirical = fmt_pct(sum(is_empirical_paper, na.rm = TRUE), classified_n),
    pct_quantitative = fmt_pct(sum(is_empirical_quant_paper_torreblanca, na.rm = TRUE), classified_n),
    pct_statistical_inference = fmt_pct(sum(has_statistical_inference, na.rm = TRUE), classified_n),
    pct_causal_claim = fmt_pct(sum(causal_or_explanatory_claim_present, na.rm = TRUE), classified_n),
    pct_screen = fmt_pct(sum(credibility_revolution_screen_applicable, na.rm = TRUE), classified_n),
    pct_strict_design = fmt_pct(sum(strict_design_method, na.rm = TRUE), classified_n),
    .groups = "drop"
  )

period_metrics <- analysis_df |>
  dplyr::group_by(period_3) |>
  dplyr::summarise(
    classified_n = dplyr::n(),
    pct_empirical = fmt_pct(sum(is_empirical_paper, na.rm = TRUE), classified_n),
    pct_quantitative = fmt_pct(sum(is_empirical_quant_paper_torreblanca, na.rm = TRUE), classified_n),
    pct_statistical_inference = fmt_pct(sum(has_statistical_inference, na.rm = TRUE), classified_n),
    pct_causal_claim = fmt_pct(sum(causal_or_explanatory_claim_present, na.rm = TRUE), classified_n),
    pct_screen = fmt_pct(sum(credibility_revolution_screen_applicable, na.rm = TRUE), classified_n),
    pct_strict_design = fmt_pct(sum(strict_design_method, na.rm = TRUE), classified_n),
    .groups = "drop"
  )

coverage_journal_period <- manifest |>
  dplyr::count(journal_title, period_3, name = "manifest_n") |>
  dplyr::left_join(
    analysis_df |>
      dplyr::count(journal_title, period_3, name = "classified_n"),
    by = c("journal_title", "period_3")
  ) |>
  dplyr::mutate(
    classified_n = dplyr::coalesce(classified_n, 0L),
    coverage_percent = fmt_pct(classified_n, manifest_n)
  )

readr::write_csv(analysis_df |> dplyr::select(-method_type), file.path(analysis_dir, "paper_analysis_dataset_preliminary.csv"))
readr::write_csv(method_long, file.path(analysis_dir, "paper_method_long_preliminary.csv"))
readr::write_csv(artifact_validation_checks, file.path(analysis_dir, "paper_artifact_validation_checks.csv"))
readr::write_csv(screen_without_causal_claim, file.path(analysis_dir, "screen_without_causal_claim.csv"))
readr::write_csv(screen_reason_diagnostics, file.path(analysis_dir, "screen_reason_diagnostics.csv"))
readr::write_csv(method_overlap_summary, file.path(analysis_dir, "method_overlap_summary.csv"))
readr::write_csv(variable_mapping, file.path(audit_dir, "variable_mapping_final.csv"))
readr::write_csv(denominator_summary, file.path(tables_dir, "denominator_summary.csv"))
readr::write_csv(table_1_corpus_description, file.path(tables_dir, "table_1_corpus_description.csv"))
readr::write_csv(table_2_methodological_dimensions, file.path(tables_dir, "table_2_methodological_dimensions.csv"))
readr::write_csv(table_3_causality_credibility, file.path(tables_dir, "table_3_causality_credibility.csv"))
readr::write_csv(journal_metrics, file.path(tables_dir, "journal_dimension_matrix.csv"))
readr::write_csv(period_metrics, file.path(tables_dir, "period_dimension_summary.csv"))
readr::write_csv(coverage_journal_period, file.path(tables_dir, "coverage_journal_period.csv"))

theme_paper <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      plot.title.position = "plot",
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey30"),
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank()
    )
}

classification_dimension_data <- tibble::tibble(
  group = factor(
    c("Cobertura", "Cobertura", "Evidência", "Quantificação", "Claims e screen", "Claims e screen", "Credibilidade"),
    levels = c("Cobertura", "Evidência", "Quantificação", "Claims e screen", "Credibilidade")
  ),
  measure = factor(
    c("Corpus elegível", "Classificados", "Empíricos", "Componente quantitativo", "Claim causal/explicativo", "Screen de credibilidade", "Desenho estrito"),
    levels = rev(c("Corpus elegível", "Classificados", "Empíricos", "Componente quantitativo", "Claim causal/explicativo", "Screen de credibilidade", "Desenho estrito"))
  ),
  n = c(n_manifest, n_classified, n_empirical, n_quant, n_causal, n_screen, n_strict),
  denominator_note = c(
    "manifest completo",
    "manifest completo",
    "classificados",
    "classificados",
    "classificados",
    "classificados",
    "screen de credibilidade"
  )
)

figure_1 <- classification_dimension_data |>
  ggplot2::ggplot(ggplot2::aes(x = n, y = measure, fill = group)) +
  ggplot2::geom_col(width = 0.68, show.legend = FALSE) +
  ggplot2::geom_text(ggplot2::aes(label = n), hjust = -0.12, size = 3.2) +
  ggplot2::facet_wrap(~group, scales = "free_x", ncol = 1) +
  ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.18))) +
  ggplot2::scale_fill_manual(values = c(
    "Cobertura" = "#22577A",
    "Evidência" = "#558B6E",
    "Quantificação" = "#DDA15E",
    "Claims e screen" = "#6D597A",
    "Credibilidade" = "#B56576"
  )) +
  ggplot2::labs(
    title = "Denominadores e dimensões da classificação disponível",
    subtitle = "Barras em painéis independentes evitam interpretar dimensões cruzadas como funil aninhado.",
    x = "Artigos",
    y = NULL,
    caption = "Denominadores: manifest para cobertura; artigos classificados por leitura integral para variáveis substantivas; screen de credibilidade para desenho estrito."
  ) +
  theme_paper()

ggplot2::ggsave(file.path(figures_dir, "figure_1_corpus_funnel.pdf"), figure_1, width = 8.5, height = 5.2)

matrix_data <- journal_metrics |>
  tidyr::pivot_longer(
    cols = dplyr::starts_with("pct_"),
    names_to = "metric",
    values_to = "percent"
  ) |>
  dplyr::mutate(
    metric_label = dplyr::recode(metric, !!!metric_labels),
    journal_label = stringr::str_wrap(journal_title, width = 32)
  )

figure_2 <- matrix_data |>
  ggplot2::ggplot(ggplot2::aes(x = metric_label, y = stats::reorder(journal_label, classified_n), fill = percent)) +
  ggplot2::geom_tile(color = "white", linewidth = 0.3) +
  ggplot2::geom_text(ggplot2::aes(label = if_else(is.na(percent), "", paste0(percent, "%"))), size = 2.7) +
  ggplot2::scale_fill_gradient(low = "#F5F1E8", high = "#22577A", na.value = "grey90", limits = c(0, 100)) +
  ggplot2::labs(
    title = "Matriz preliminar por periódico e dimensão observada",
    subtitle = "Dimensões de explicitação metodológica e formato textual não são exibidas porque ainda exigem classificação complementar.",
    x = NULL,
    y = NULL,
    fill = "%",
    caption = paste0("Denominador: artigos classificados por leitura integral em cada periódico (N total = ", n_classified, ").")
  ) +
  theme_paper() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 25, hjust = 1))

ggplot2::ggsave(file.path(figures_dir, "figure_2_journal_dimension_matrix.pdf"), figure_2, width = 9.5, height = 6.8)

period_plot_data <- period_metrics |>
  tidyr::pivot_longer(
    cols = dplyr::starts_with("pct_"),
    names_to = "metric",
    values_to = "percent"
  ) |>
  dplyr::mutate(metric_label = dplyr::recode(metric, !!!metric_labels))

figure_3 <- period_plot_data |>
  ggplot2::ggplot(ggplot2::aes(x = period_3, y = percent, color = metric_label, group = metric_label)) +
  ggplot2::geom_line(linewidth = 0.8) +
  ggplot2::geom_point(size = 2.1) +
  ggplot2::scale_y_continuous(labels = function(x) paste0(x, "%"), limits = c(0, 100)) +
  ggplot2::scale_color_manual(values = c("#22577A", "#558B6E", "#DDA15E", "#BC6C25", "#6D597A", "#B56576")) +
  ggplot2::labs(
    title = "Variação por período entre artigos classificados",
    subtitle = "Série preliminar calculada somente sobre artigos já classificados por leitura integral.",
    x = "Período",
    y = "Percentual",
    color = "Dimensão",
    caption = paste0("Denominador: artigos classificados dentro de cada período (N total = ", n_classified, ").")
  ) +
  theme_paper()

ggplot2::ggsave(file.path(figures_dir, "figure_3_period_variation.pdf"), figure_3, width = 9, height = 5.4)

figure_4 <- coverage_journal_period |>
  dplyr::mutate(journal_label = stringr::str_wrap(journal_title, width = 32)) |>
  ggplot2::ggplot(ggplot2::aes(x = period_3, y = stats::reorder(journal_label, classified_n), fill = coverage_percent)) +
  ggplot2::geom_tile(color = "white", linewidth = 0.3) +
  ggplot2::geom_text(ggplot2::aes(label = paste0(classified_n, "/", manifest_n)), size = 2.8) +
  ggplot2::scale_fill_gradient(low = "#F5F1E8", high = "#6D597A", na.value = "grey90", limits = c(0, 100)) +
  ggplot2::labs(
    title = "Cobertura de classificação por periódico e período",
    subtitle = "Esta figura é diagnóstico de cobertura, não resultado substantivo sobre práticas metodológicas.",
    x = "Período",
    y = NULL,
    fill = "% classificado",
    caption = "Denominador: PIDs do manifest elegível em cada célula periódico-período; rótulos mostram classificados/manifest."
  ) +
  theme_paper()

ggplot2::ggsave(file.path(figures_dir, "figure_4_journal_period_coverage.pdf"), figure_4, width = 9, height = 6.8)

gap_lines <- c(
  "# Auditoria de variáveis finais do paper",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Síntese",
  "",
  paste0("- Manifest completo elegível: ", n_manifest, " PIDs."),
  paste0("- Artigos classificados por leitura integral disponíveis: ", n_classified, " (", fmt_pct(n_classified, n_manifest), "% do manifest)."),
  paste0("- O corpus completo ainda não está classificado: ", n_manifest - n_classified, " PIDs permanecem sem classificação combinada."),
  "- `method_explicitness` e `empirical_article_format` não são variáveis disponíveis no classificador atual.",
  "- Os `section_reading_log` podem subsidiar uma rodada complementar, mas não codificam sozinhos uma regra validada para essas duas dimensões.",
  "",
  "## Regra de uso no manuscrito",
  "",
  "- Resultados substantivos devem ser rotulados como preliminares.",
  "- Figuras e tabelas devem informar o denominador de artigos classificados por leitura integral.",
  "- A tese sobre baixa explicitação e baixa padronização deve aparecer como hipótese/desenho do projeto, não como resultado confirmado por esta base parcial.",
  "- SEM, mediação causal, regressão observacional e efeitos fixos não entram no numerador de `strict_design_method` sem desenho explícito de identificação.",
  "",
  "## Variáveis que exigem classificação complementar",
  "",
  "- `method_explicitness`: clear, partial, absent.",
  "- `empirical_article_format`: imrad_like, structured_non_imrad, essayistic_empirical, theoretical_or_review, unclear."
)

write_utf8_lines(gap_lines, file.path(audit_dir, "variable_gap_audit.md"))
capture.output(sessionInfo(), file = file.path(analysis_dir, "paper_analysis_session_info.txt"))

cat("Artefatos do paper escritos em:\n")
cat("- ", analysis_dir, "\n", sep = "")
cat("- ", tables_dir, "\n", sep = "")
cat("- ", figures_dir, "\n", sep = "")
cat("- ", audit_dir, "\n", sep = "")
