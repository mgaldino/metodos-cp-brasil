## 34_build_preliminary_credibility_analysis.R
## Constroi bases, tabelas e figuras para analise preliminar do corpus classificado.

options(scipen = 999, encoding = "UTF-8")
set.seed(20260616)

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

required_repo_files <- c(
  "scripts/34_build_preliminary_credibility_analysis.R",
  "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"
)

missing_repo_files <- required_repo_files[!file.exists(path(required_repo_files))]
if (length(missing_repo_files) > 0) {
  stop(
    "Execute este script a partir da raiz do repositório. Arquivos esperados ausentes: ",
    paste(missing_repo_files, collapse = ", ")
  )
}

classifications_path <- path(
  "data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv"
)
manifest_path <- path(
  "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"
)
reading_logs_dir <- path(
  "data/processed/credibility_prompt_v3_integral_reading/full_corpus/reading_logs"
)
failed_dir <- path(
  "data/processed/credibility_prompt_v3_integral_reading/full_corpus/failed"
)
analysis_dir <- path(
  "data/processed/credibility_prompt_v3_integral_reading/preliminary_analysis"
)
tables_dir <- path("output/tables/preliminary_credibility")
figures_dir <- path("output/figures/preliminary_credibility")
quality_dir <- path("quality_reports")

dir.create(analysis_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(quality_dir, recursive = TRUE, showWarnings = FALSE)

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

write_utf8_lines <- function(lines, file) {
  con <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  writeLines(enc2utf8(lines), con = con, useBytes = TRUE)
}

label_value <- function(x, labels) {
  dplyr::recode(as.character(x), !!!labels, .default = stringr::str_replace_all(as.character(x), "_", " "))
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
  causal_discovery = "Descoberta causal",
  other_modern_causal_method = "Outro método causal moderno",
  observational_regression_with_causal_claim_no_design = "Regressão observacional com linguagem causal",
  fixed_effects_causal_panel_claim = "Painel com efeitos fixos e linguagem causal",
  none_detected = "Nenhum método detectado"
)

evidence_labels <- c(
  none = "Não empírico",
  qualitative_only = "Somente qualitativo",
  quantitative_only = "Somente quantitativo",
  mixed_empirical = "Misto"
)

quantitative_labels <- c(
  none = "sem análise quantitativa",
  descriptive_statistics_only = "estatística descritiva",
  bivariate_tests_or_correlations_only = "testes bivariados/correlação",
  statistical_modeling = "modelagem estatística"
)

screen_reason_labels <- c(
  descriptive_quantitative_only = "Quantitativo descritivo",
  qualitative_only = "Somente qualitativo",
  not_empirical = "Não empírico",
  statistical_modeling_screen = "Modelagem estatística",
  explicit_causal_design_screen = "Desenho causal explícito",
  causal_claim_with_quantitative_analysis_screen = "Alegação causal + análise quantitativa",
  bivariate_or_correlation_screen = "Bivariado/correlação"
)

excluded_main_journals <- c(
  "Brazilian Journal of Political Economy",
  "Civitas - Revista de Ciências Sociais"
)

required_classification_cols <- c(
  "pid",
  "title",
  "journal_title",
  "input_text_hash",
  "is_empirical_paper",
  "empirical_evidence_type",
  "is_empirical_quant_paper_torreblanca",
  "is_empirical_qual_paper",
  "quantitative_analysis_type",
  "has_statistical_inference",
  "causal_or_explanatory_claim_present",
  "credibility_revolution_screen_applicable",
  "credibility_revolution_screen_reason",
  "credibility_revolution_method_present",
  "credibility_revolution_method_type",
  "causal_design_quote",
  "tough_call",
  "tough_call_reason",
  "brief_justification"
)

required_manifest_cols <- c(
  "eligible_order",
  "pid",
  "input_text_hash",
  "year",
  "journal_title",
  "document_type",
  "language",
  "body_word_count",
  "fulltext_validation_status",
  "pilot_exclusion_policy"
)

classifications_raw <- readr::read_csv(classifications_path, show_col_types = FALSE)
manifest_raw <- readr::read_csv(manifest_path, show_col_types = FALSE)

missing_classification_cols <- setdiff(required_classification_cols, names(classifications_raw))
missing_manifest_cols <- setdiff(required_manifest_cols, names(manifest_raw))

if (length(missing_classification_cols) > 0) {
  stop("Colunas ausentes no CSV de classificações: ", paste(missing_classification_cols, collapse = ", "))
}

if (length(missing_manifest_cols) > 0) {
  stop("Colunas ausentes no manifest: ", paste(missing_manifest_cols, collapse = ", "))
}

classifications <- classifications_raw |>
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

manifest <- manifest_raw |>
  dplyr::mutate(
    eligible_order = as.integer(eligible_order),
    year = as.integer(year),
    body_word_count = as.numeric(body_word_count)
  )

manifest_meta <- manifest |>
  dplyr::select(
    pid,
    manifest_input_text_hash = input_text_hash,
    eligible_order,
    year,
    manifest_journal_title = journal_title,
    document_type,
    language,
    body_word_count,
    fulltext_validation_status,
    pilot_exclusion_policy
  )

analysis_df <- classifications |>
  dplyr::left_join(manifest_meta, by = "pid") |>
  dplyr::mutate(
    year = as.integer(year),
    journal_title = dplyr::coalesce(journal_title, manifest_journal_title),
    block_offset = floor((eligible_order - 1L) / 100L) * 100L
  )

method_long <- analysis_df |>
  dplyr::select(
    pid,
    title,
    journal_title,
    year,
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
    has_strict_credibility_method = pid %in% strict_pids,
    has_other_modern_causal_method = pid %in% other_modern_pids,
    has_diagnostic_not_design_method = pid %in% diagnostic_pids,
    conservative_credibility_design = dplyr::coalesce(credibility_revolution_method_present, FALSE) &
      has_strict_credibility_method,
    other_modern_audit_queue = dplyr::coalesce(credibility_revolution_method_present, FALSE) &
      has_other_modern_causal_method,
    other_modern_overlap_with_strict = other_modern_audit_queue & conservative_credibility_design,
    other_modern_broad_only = other_modern_audit_queue & !conservative_credibility_design,
    inclusive_credibility_design = conservative_credibility_design | other_modern_audit_queue
  )

reading_logs_dir_exists <- dir.exists(reading_logs_dir)
failed_dir_exists <- dir.exists(failed_dir)
reading_log_files <- if (reading_logs_dir_exists) {
  list.files(reading_logs_dir, pattern = "\\.json$", full.names = FALSE)
} else {
  character()
}
reading_log_pids <- sub("\\.json$", "", reading_log_files)
failed_files <- if (failed_dir_exists) {
  list.files(failed_dir, full.names = TRUE)
} else {
  character()
}

core_bool_fields <- c(
  "is_empirical_paper",
  "is_empirical_quant_paper_torreblanca",
  "is_empirical_qual_paper",
  "causal_or_explanatory_claim_present",
  "credibility_revolution_screen_applicable",
  "tough_call"
)

core_bool_na_counts <- vapply(
  analysis_df[core_bool_fields],
  function(x) sum(is.na(x)),
  integer(1)
)

method_present_expected <- dplyr::case_when(
  analysis_df$credibility_revolution_screen_applicable == TRUE ~ !is.na(analysis_df$credibility_revolution_method_present),
  analysis_df$credibility_revolution_screen_applicable == FALSE ~ is.na(analysis_df$credibility_revolution_method_present),
  TRUE ~ FALSE
)

statistical_inference_expected <- analysis_df$quantitative_analysis_type == "none" |
  !is.na(analysis_df$has_statistical_inference)

hash_matches <- !is.na(analysis_df$classification_input_text_hash) &
  !is.na(analysis_df$manifest_input_text_hash) &
  analysis_df$classification_input_text_hash == analysis_df$manifest_input_text_hash

all_true <- function(x) isTRUE(all(x))
none_true <- function(x) isTRUE(!any(x))

validation_summary <- tibble::tibble(
  check = c(
    "classification_rows_positive",
    "classification_pids_unique",
    "manifest_pids_unique",
    "classified_pids_in_manifest",
    "join_has_no_missing_manifest_order",
    "input_text_hash_matches_manifest",
    "core_boolean_fields_not_na",
    "statistical_inference_not_na_when_quantitative",
    "method_present_null_consistent_with_screen",
    "reading_logs_directory_exists",
    "reading_log_for_each_classified_pid",
    "failed_directory_exists",
    "failed_directory_empty",
    "years_in_expected_range",
    "excluded_journals_absent",
    "document_type_research_article",
    "fulltext_validation_pass"
  ),
  status = c(
    nrow(analysis_df) > 0,
    nrow(analysis_df) == dplyr::n_distinct(analysis_df$pid),
    nrow(manifest) == dplyr::n_distinct(manifest$pid),
    all_true(analysis_df$pid %in% manifest$pid),
    all_true(!is.na(analysis_df$eligible_order)),
    all_true(hash_matches),
    all(core_bool_na_counts == 0),
    all_true(statistical_inference_expected),
    all_true(method_present_expected),
    reading_logs_dir_exists,
    reading_logs_dir_exists && all_true(analysis_df$pid %in% reading_log_pids),
    failed_dir_exists,
    failed_dir_exists && length(failed_files) == 0,
    all_true(!is.na(analysis_df$year) & dplyr::between(analysis_df$year, 2005, 2025)),
    all_true(!is.na(analysis_df$journal_title)) &&
      none_true(analysis_df$journal_title %in% excluded_main_journals),
    all_true(!is.na(analysis_df$document_type) & analysis_df$document_type == "research-article"),
    all_true(!is.na(analysis_df$fulltext_validation_status) & analysis_df$fulltext_validation_status == "PASS")
  ),
  value = c(
    as.character(nrow(analysis_df)),
    paste0(dplyr::n_distinct(analysis_df$pid), " únicos em ", nrow(analysis_df), " linhas"),
    paste0(dplyr::n_distinct(manifest$pid), " únicos em ", nrow(manifest), " linhas"),
    as.character(sum(analysis_df$pid %in% manifest$pid)),
    as.character(sum(is.na(analysis_df$eligible_order))),
    paste0(sum(!hash_matches), " divergências; ", sum(is.na(analysis_df$classification_input_text_hash)), " hashes de classificação ausentes; ", sum(is.na(analysis_df$manifest_input_text_hash)), " hashes de manifest ausentes"),
    paste(names(core_bool_na_counts), core_bool_na_counts, sep = "=", collapse = "; "),
    paste0(sum(!statistical_inference_expected), " inconsistências; ", sum(is.na(analysis_df$has_statistical_inference)), " NAs totais"),
    paste0(sum(!method_present_expected), " inconsistências"),
    as.character(reading_logs_dir_exists),
    paste0(sum(analysis_df$pid %in% reading_log_pids), " de ", nrow(analysis_df)),
    as.character(failed_dir_exists),
    as.character(length(failed_files)),
    paste0(min(analysis_df$year, na.rm = TRUE), "-", max(analysis_df$year, na.rm = TRUE), "; NA=", sum(is.na(analysis_df$year))),
    paste(sort(intersect(unique(analysis_df$journal_title), excluded_main_journals)), collapse = "; "),
    paste0(paste(sort(unique(analysis_df$document_type)), collapse = "; "), "; NA=", sum(is.na(analysis_df$document_type))),
    paste0(paste(sort(unique(analysis_df$fulltext_validation_status)), collapse = "; "), "; NA=", sum(is.na(analysis_df$fulltext_validation_status)))
  ),
  expected = c(
    "> 0",
    "uma linha por PID classificado",
    "uma linha por PID no manifest",
    "todos os PIDs classificados no manifest",
    "0",
    "0 divergências e 0 hashes ausentes",
    "0 NA em campos booleanos centrais",
    "0 inconsistências fora de quantitative_analysis_type == none",
    "0 inconsistências",
    "TRUE",
    "um reading log por PID classificado",
    "TRUE",
    "0",
    "2005-2025",
    "nenhum periódico excluído",
    "research-article",
    "PASS"
  )
) |>
  dplyr::mutate(status = if_else(status, "PASS", "FAIL"))

if (any(validation_summary$status == "FAIL")) {
  readr::write_csv(validation_summary, file.path(analysis_dir, "validation_summary.csv"))
  stop("Validação preliminar falhou. Veja data/processed/credibility_prompt_v3_integral_reading/preliminary_analysis/validation_summary.csv")
}

n_classified <- nrow(analysis_df)
n_manifest <- nrow(manifest)

metric_row <- function(indicator, n, denominator = n_classified, note = "") {
  tibble::tibble(
    indicator = indicator,
    n = as.integer(n),
    denominator = as.integer(denominator),
    percent = round(100 * n / denominator, 1),
    note = note
  )
}

indicator_summary <- dplyr::bind_rows(
  metric_row("Artigos classificados", n_classified, n_manifest, "Cobertura preliminar do manifest completo"),
  metric_row("Artigos empíricos", sum(analysis_df$is_empirical_paper, na.rm = TRUE)),
  metric_row("Quantitativos Torreblanca", sum(analysis_df$is_empirical_quant_paper_torreblanca, na.rm = TRUE)),
  metric_row("Qualitativos", sum(analysis_df$is_empirical_qual_paper, na.rm = TRUE)),
  metric_row("Screen de credibilidade aplicável", sum(analysis_df$credibility_revolution_screen_applicable, na.rm = TRUE)),
  metric_row("Método estrito de credibilidade", sum(analysis_df$conservative_credibility_design, na.rm = TRUE), note = "Numerador principal/conservador"),
  metric_row("other_modern_causal_method", sum(analysis_df$other_modern_audit_queue, na.rm = TRUE), note = "Fila de auditoria manual; pode sobrepor métodos estritos"),
  metric_row("other_modern_causal_method sem método estrito", sum(analysis_df$other_modern_broad_only, na.rm = TRUE), note = "Casos residuais adicionais a adjudicar"),
  metric_row("Medida inclusiva de sensibilidade", sum(analysis_df$inclusive_credibility_design, na.rm = TRUE), note = "União de artigos únicos: métodos estritos ou other_modern_causal_method"),
  metric_row("Tough calls", sum(analysis_df$tough_call, na.rm = TRUE))
)

sensitivity_summary <- tibble::tibble(
  measure = c(
    "Principal/conservadora",
    "Fila other_modern_causal_method",
    "other_modern sem método estrito",
    "Inclusiva (união de artigos únicos)"
  ),
  n = c(
    sum(analysis_df$conservative_credibility_design, na.rm = TRUE),
    sum(analysis_df$other_modern_audit_queue, na.rm = TRUE),
    sum(analysis_df$other_modern_broad_only, na.rm = TRUE),
    sum(analysis_df$inclusive_credibility_design, na.rm = TRUE)
  ),
  denominator = n_classified,
  percent = round(100 * n / denominator, 1),
  interpretation = c(
    "Conta apenas métodos estritos de identificação causal.",
    "Não entra automaticamente no numerador principal; pode sobrepor casos estritos.",
    "Subconjunto residual ainda não capturado por método estrito.",
    "União de artigos únicos com método estrito ou other_modern_causal_method."
  )
)

manifest_progress <- manifest |>
  dplyr::mutate(block_offset = floor((eligible_order - 1L) / 100L) * 100L) |>
  dplyr::count(block_offset, name = "manifest_n")

classified_progress <- analysis_df |>
  dplyr::count(block_offset, name = "classified_n")

progress_by_block <- manifest_progress |>
  dplyr::left_join(classified_progress, by = "block_offset") |>
  dplyr::mutate(
    classified_n = dplyr::coalesce(classified_n, 0L),
    percent_classified = round(100 * classified_n / manifest_n, 1),
    block_label = paste0(block_offset, "-", block_offset + manifest_n - 1L)
  ) |>
  dplyr::arrange(block_offset)

coverage_by_journal <- manifest |>
  dplyr::count(journal_title, name = "manifest_n") |>
  dplyr::left_join(
    analysis_df |> dplyr::count(journal_title, name = "classified_n"),
    by = "journal_title"
  ) |>
  dplyr::mutate(
    classified_n = dplyr::coalesce(classified_n, 0L),
    remaining_n = manifest_n - classified_n,
    percent_classified = round(100 * classified_n / manifest_n, 1)
  ) |>
  dplyr::arrange(dplyr::desc(classified_n), journal_title)

coverage_by_year <- manifest |>
  dplyr::count(year, name = "manifest_n") |>
  dplyr::left_join(
    analysis_df |> dplyr::count(year, name = "classified_n"),
    by = "year"
  ) |>
  dplyr::mutate(
    classified_n = dplyr::coalesce(classified_n, 0L),
    remaining_n = manifest_n - classified_n,
    percent_classified = round(100 * classified_n / manifest_n, 1)
  ) |>
  dplyr::arrange(year)

evidence_distribution <- analysis_df |>
  dplyr::count(empirical_evidence_type, quantitative_analysis_type, name = "n") |>
  dplyr::mutate(percent = round(100 * n / sum(n), 1)) |>
  dplyr::arrange(dplyr::desc(n), empirical_evidence_type, quantitative_analysis_type)

evidence_distribution_display <- evidence_distribution |>
  dplyr::mutate(
    tipo_de_evidencia = label_value(empirical_evidence_type, evidence_labels),
    tipo_de_analise_quantitativa = label_value(quantitative_analysis_type, quantitative_labels),
    categoria = paste0(tipo_de_evidencia, " / ", tipo_de_analise_quantitativa)
  ) |>
  dplyr::select(categoria, tipo_de_evidencia, tipo_de_analise_quantitativa, n, percent)

screen_distribution <- analysis_df |>
  dplyr::count(credibility_revolution_screen_applicable, credibility_revolution_screen_reason, name = "n") |>
  dplyr::mutate(percent = round(100 * n / sum(n), 1)) |>
  dplyr::arrange(dplyr::desc(n), credibility_revolution_screen_reason)

screen_distribution_display <- screen_distribution |>
  dplyr::mutate(
    screen = if_else(credibility_revolution_screen_applicable, "Entra no screen", "Fora do screen"),
    razao = label_value(credibility_revolution_screen_reason, screen_reason_labels)
  ) |>
  dplyr::select(screen, razao, n, percent)

method_distribution <- method_long |>
  dplyr::count(method_class, method_type, name = "n") |>
  dplyr::arrange(method_class, dplyr::desc(n), method_type)

method_distribution_display <- method_distribution |>
  dplyr::mutate(
    classe = dplyr::case_when(
      method_class == "strict_design_method" ~ "Método estrito",
      method_class == "broad_other_modern_causal_method" ~ "Fila other_modern",
      method_class == "diagnostic_not_design" ~ "Diagnóstico",
      TRUE ~ "Não classificado"
    ),
    metodo = label_value(method_type, method_labels)
  ) |>
  dplyr::select(classe, metodo, n)

strict_method_counts <- tibble::tibble(method_type = strict_design_methods) |>
  dplyr::left_join(
    method_long |>
      dplyr::filter(method_class == "strict_design_method") |>
      dplyr::count(method_type, name = "n"),
    by = "method_type"
  ) |>
  dplyr::mutate(
    n = dplyr::coalesce(n, 0L),
    metodo = label_value(method_type, method_labels),
    status = if_else(n > 0, "Detectado", "Zero casos")
  ) |>
  dplyr::arrange(dplyr::desc(n), metodo)

method_long_with_flags <- method_long |>
  dplyr::left_join(
    analysis_df |>
      dplyr::select(
        pid,
        conservative_credibility_design,
        other_modern_audit_queue,
        other_modern_overlap_with_strict,
        other_modern_broad_only
      ),
    by = "pid"
  )

strict_method_cases <- method_long_with_flags |>
  dplyr::filter(method_class == "strict_design_method", conservative_credibility_design) |>
  dplyr::select(
    pid,
    title,
    journal_title,
    year,
    eligible_order,
    method_type,
    causal_design_quote,
    tough_call_reason
  ) |>
  dplyr::arrange(eligible_order, pid, method_type)

strict_method_cases_display <- strict_method_cases |>
  dplyr::mutate(
    metodo = label_value(method_type, method_labels),
    titulo = stringr::str_trunc(title, width = 68),
    evidencia = stringr::str_trunc(causal_design_quote, width = 90)
  ) |>
  dplyr::select(pid, year, journal_title, metodo, titulo, evidencia)

other_modern_audit_queue <- method_long_with_flags |>
  dplyr::filter(method_class == "broad_other_modern_causal_method", other_modern_audit_queue) |>
  dplyr::select(
    pid,
    title,
    journal_title,
    year,
    eligible_order,
    method_type,
    other_modern_overlap_with_strict,
    other_modern_broad_only,
    causal_design_quote,
    tough_call_reason
  ) |>
  dplyr::arrange(eligible_order, pid, method_type)

other_modern_audit_queue_display <- other_modern_audit_queue |>
  dplyr::mutate(
    titulo = stringr::str_trunc(title, width = 68),
    tambem_tem_metodo_estrito = if_else(other_modern_overlap_with_strict, "Sim", "Não"),
    evidencia = stringr::str_trunc(causal_design_quote, width = 90)
  ) |>
  dplyr::select(pid, year, journal_title, tambem_tem_metodo_estrito, titulo, evidencia)

tough_call_queue <- analysis_df |>
  dplyr::filter(tough_call) |>
  dplyr::select(
    pid,
    title,
    journal_title,
    year,
    eligible_order,
    empirical_evidence_type,
    quantitative_analysis_type,
    credibility_revolution_screen_reason,
    tough_call_reason
  ) |>
  dplyr::arrange(eligible_order, pid)

tough_call_summary <- tough_call_queue |>
  dplyr::count(empirical_evidence_type, quantitative_analysis_type, name = "n") |>
  dplyr::mutate(
    categoria = paste0(
      label_value(empirical_evidence_type, evidence_labels),
      " / ",
      label_value(quantitative_analysis_type, quantitative_labels)
    ),
    percent = round(100 * n / sum(n), 1)
  ) |>
  dplyr::arrange(dplyr::desc(n)) |>
  dplyr::select(categoria, n, percent)

tough_call_queue_display <- tough_call_queue |>
  dplyr::mutate(
    titulo = stringr::str_trunc(title, width = 68),
    razao_do_screen = label_value(credibility_revolution_screen_reason, screen_reason_labels),
    motivo = stringr::str_trunc(tough_call_reason, width = 100)
  ) |>
  dplyr::select(pid, year, journal_title, titulo, razao_do_screen, motivo)

annual_indicators <- analysis_df |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    classified_n = dplyr::n(),
    pct_quantitative_torreblanca = round(100 * mean(is_empirical_quant_paper_torreblanca, na.rm = TRUE), 1),
    pct_screen_credibility = round(100 * mean(credibility_revolution_screen_applicable, na.rm = TRUE), 1),
    pct_conservative_credibility = round(100 * mean(conservative_credibility_design, na.rm = TRUE), 1),
    pct_inclusive_credibility = round(100 * mean(inclusive_credibility_design, na.rm = TRUE), 1),
    .groups = "drop"
  ) |>
  dplyr::arrange(year)

annual_indicator_long <- annual_indicators |>
  tidyr::pivot_longer(
    cols = c(
      pct_quantitative_torreblanca,
      pct_screen_credibility,
      pct_conservative_credibility,
      pct_inclusive_credibility
    ),
    names_to = "indicator",
    values_to = "percent"
  ) |>
  dplyr::mutate(
    indicator = dplyr::recode(
      indicator,
      pct_quantitative_torreblanca = "Quantitativos Torreblanca",
      pct_screen_credibility = "Screen de credibilidade",
      pct_conservative_credibility = "Credibilidade conservadora",
      pct_inclusive_credibility = "Credibilidade inclusiva"
    )
  )

readr::write_csv(analysis_df, file.path(analysis_dir, "analysis_dataset_preliminary.csv"))
readr::write_csv(validation_summary, file.path(analysis_dir, "validation_summary.csv"))
readr::write_csv(indicator_summary, file.path(tables_dir, "indicator_summary.csv"))
readr::write_csv(sensitivity_summary, file.path(tables_dir, "sensitivity_summary.csv"))
readr::write_csv(progress_by_block, file.path(tables_dir, "progress_by_block.csv"))
readr::write_csv(coverage_by_journal, file.path(tables_dir, "coverage_by_journal.csv"))
readr::write_csv(coverage_by_year, file.path(tables_dir, "coverage_by_year.csv"))
readr::write_csv(evidence_distribution, file.path(tables_dir, "evidence_distribution.csv"))
readr::write_csv(evidence_distribution_display, file.path(tables_dir, "evidence_distribution_display.csv"))
readr::write_csv(screen_distribution, file.path(tables_dir, "screen_distribution.csv"))
readr::write_csv(screen_distribution_display, file.path(tables_dir, "screen_distribution_display.csv"))
readr::write_csv(method_distribution, file.path(tables_dir, "method_distribution.csv"))
readr::write_csv(method_distribution_display, file.path(tables_dir, "method_distribution_display.csv"))
readr::write_csv(strict_method_counts, file.path(tables_dir, "strict_method_counts.csv"))
readr::write_csv(strict_method_cases, file.path(tables_dir, "strict_method_cases.csv"))
readr::write_csv(strict_method_cases_display, file.path(tables_dir, "strict_method_cases_display.csv"))
readr::write_csv(other_modern_audit_queue, file.path(tables_dir, "other_modern_audit_queue.csv"))
readr::write_csv(other_modern_audit_queue_display, file.path(tables_dir, "other_modern_audit_queue_display.csv"))
readr::write_csv(tough_call_queue, file.path(tables_dir, "tough_call_queue.csv"))
readr::write_csv(tough_call_summary, file.path(tables_dir, "tough_call_summary.csv"))
readr::write_csv(tough_call_queue_display, file.path(tables_dir, "tough_call_queue_display.csv"))
readr::write_csv(annual_indicators, file.path(tables_dir, "annual_indicators.csv"))
readr::write_csv(annual_indicator_long, file.path(tables_dir, "annual_indicator_long.csv"))

theme_preliminary <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      plot.title.position = "plot",
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey30"),
      axis.title = ggplot2::element_text(color = "grey20"),
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank()
    )
}

figure_progress <- progress_by_block |>
  dplyr::filter(classified_n > 0 | block_offset <= 500) |>
  ggplot2::ggplot(ggplot2::aes(x = block_offset, y = classified_n, fill = "Artigos classificados")) +
  ggplot2::geom_col(width = 82) +
  ggplot2::geom_hline(yintercept = 100, linetype = "dashed", color = "grey45") +
  ggplot2::scale_x_continuous(breaks = seq(0, max(progress_by_block$block_offset), by = 100)) +
  ggplot2::scale_fill_manual(values = c("Artigos classificados" = "#2A6F97")) +
  ggplot2::labs(
    title = "Progresso da classificação por bloco",
    subtitle = "Cada bloco planejado tem até 100 artigos; barras zeradas indicam blocos ainda não processados.",
    x = "Offset do bloco no manifest",
    y = "Artigos classificados",
    fill = "Legenda",
    caption = "Legenda: barras mostram artigos classificados por bloco; linha tracejada marca o alvo de 100 artigos por bloco completo."
  ) +
  theme_preliminary()

ggplot2::ggsave(
  file.path(figures_dir, "figure_1_progress_by_block.png"),
  figure_progress,
  width = 9,
  height = 4.8,
  dpi = 320
)

figure_coverage_journal <- coverage_by_journal |>
  dplyr::mutate(journal_label = stringr::str_wrap(journal_title, width = 34)) |>
  ggplot2::ggplot(ggplot2::aes(x = classified_n, y = stats::reorder(journal_label, classified_n), fill = "Artigos classificados")) +
  ggplot2::geom_col() +
  ggplot2::scale_fill_manual(values = c("Artigos classificados" = "#6A994E")) +
  ggplot2::labs(
    title = "Cobertura preliminar por periódico",
    subtitle = "A cobertura reflete a ordem do manifest, não uma amostra aleatória do corpus.",
    x = "Artigos classificados",
    y = NULL,
    fill = "Legenda",
    caption = "Legenda: barras mostram quantos artigos de cada periódico já entraram na classificação preliminar."
  ) +
  theme_preliminary()

ggplot2::ggsave(
  file.path(figures_dir, "figure_2_coverage_by_journal.png"),
  figure_coverage_journal,
  width = 9,
  height = 5.6,
  dpi = 320
)

figure_annual <- annual_indicator_long |>
  ggplot2::ggplot(ggplot2::aes(x = year, y = percent, color = indicator)) +
  ggplot2::geom_line(linewidth = 0.7) +
  ggplot2::geom_point(size = 1.8) +
  ggplot2::scale_y_continuous(labels = function(x) paste0(x, "%"), limits = c(0, 100)) +
  ggplot2::scale_color_manual(values = c("#2A6F97", "#C1666B", "#6A994E", "#7B2CBF")) +
  ggplot2::labs(
    title = "Indicadores por ano nos artigos já classificados",
    subtitle = "Séries preliminares; a cobertura atual é parcial e concentrada nos primeiros 400 artigos do manifest.",
    x = "Ano",
    y = "Percentual dos classificados no ano",
    color = "Legenda",
    caption = "Legenda: cada linha mostra a proporção anual dentro dos artigos atualmente classificados, não dentro do corpus anual completo."
  ) +
  theme_preliminary()

ggplot2::ggsave(
  file.path(figures_dir, "figure_3_annual_indicators.png"),
  figure_annual,
  width = 9,
  height = 5.2,
  dpi = 320
)

figure_evidence <- evidence_distribution_display |>
  dplyr::mutate(
    categoria_label = stringr::str_wrap(categoria, width = 38),
    tipo_de_evidencia = factor(tipo_de_evidencia, levels = unique(tipo_de_evidencia[order(n, decreasing = TRUE)]))
  ) |>
  ggplot2::ggplot(ggplot2::aes(x = n, y = stats::reorder(categoria_label, n), fill = tipo_de_evidencia)) +
  ggplot2::geom_col() +
  ggplot2::scale_fill_manual(
    values = c(
      "Misto" = "#2A6F97",
      "Somente quantitativo" = "#6A994E",
      "Somente qualitativo" = "#C1666B",
      "Não empírico" = "#8D99AE"
    )
  ) +
  ggplot2::labs(
    title = "Tipo de evidência e análise quantitativa",
    subtitle = "Antes da barra: tipo de evidência. Depois da barra: tipo de análise quantitativa.",
    x = "Artigos",
    y = NULL,
    fill = "Tipo de evidência",
    caption = "Legenda: categorias como 'Não empírico / sem análise quantitativa' substituem os códigos brutos 'none / none'."
  ) +
  theme_preliminary()

ggplot2::ggsave(
  file.path(figures_dir, "figure_4_evidence_distribution.png"),
  figure_evidence,
  width = 9,
  height = 5.5,
  dpi = 320
)

method_plot_data <- strict_method_counts |>
  dplyr::mutate(
    metodo = stringr::str_wrap(metodo, width = 34),
    status = factor(status, levels = c("Detectado", "Zero casos"))
  )

figure_methods <- method_plot_data |>
  ggplot2::ggplot(ggplot2::aes(x = n, y = stats::reorder(metodo, n), fill = status)) +
  ggplot2::geom_col() +
  ggplot2::geom_text(ggplot2::aes(label = n), hjust = -0.25, size = 3.3) +
  ggplot2::scale_x_continuous(limits = c(0, max(method_plot_data$n, 1) + 1)) +
  ggplot2::scale_fill_manual(values = c("Detectado" = "#2A6F97", "Zero casos" = "#B8B8B8")) +
  ggplot2::labs(
    title = "Métodos estritos de identificação causal",
    subtitle = "Todos os métodos estritos são mostrados, inclusive os que tiveram zero casos.",
    x = "Artigos",
    y = NULL,
    fill = "Legenda",
    caption = "Legenda: barras azuis indicam métodos estritos detectados; barras cinzas indicam zero casos. Controle sintético aparece como zero quando não foi detectado."
  ) +
  theme_preliminary()

ggplot2::ggsave(
  file.path(figures_dir, "figure_5_method_distribution.png"),
  figure_methods,
  width = 9,
  height = 5.5,
  dpi = 320
)

figure_sensitivity <- sensitivity_summary |>
  dplyr::mutate(measure = factor(measure, levels = measure)) |>
  ggplot2::ggplot(ggplot2::aes(x = measure, y = percent, fill = measure)) +
  ggplot2::geom_col(width = 0.68) +
  ggplot2::geom_text(
    ggplot2::aes(label = paste0(n, " (", percent, "%)")),
    vjust = -0.35,
    size = 3.6
  ) +
  ggplot2::scale_y_continuous(labels = function(x) paste0(x, "%"), limits = c(0, max(5, max(sensitivity_summary$percent) + 2))) +
  ggplot2::scale_fill_manual(values = c("#2A6F97", "#7B2CBF", "#B08968", "#6A994E")) +
  ggplot2::labs(
    title = "Medidas de métodos da revolução da credibilidade",
    subtitle = "A medida inclusiva é união de artigos únicos, não soma de ocorrências de método.",
    x = NULL,
    y = "Percentual dos classificados",
    fill = "Legenda",
    caption = "Legenda: a fila other_modern é uma lista de auditoria manual; a medida inclusiva conta artigos únicos com método estrito ou other_modern."
  ) +
  theme_preliminary() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 15, hjust = 1))

ggplot2::ggsave(
  file.path(figures_dir, "figure_6_credibility_sensitivity.png"),
  figure_sensitivity,
  width = 8,
  height = 4.8,
  dpi = 320
)

summary_lines <- c(
  "# Síntese da análise preliminar de credibilidade",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Escopo",
  "",
  paste0("- Artigos no manifest completo: ", n_manifest, "."),
  paste0("- Artigos classificados e validados: ", n_classified, "."),
  paste0("- Cobertura preliminar: ", round(100 * n_classified / n_manifest, 1), "%."),
  paste0("- Blocos completos observados: ", paste(progress_by_block$block_offset[progress_by_block$classified_n > 0], collapse = ", "), "."),
  "",
  "## Regra de contagem",
  "",
  "- Numerador principal: métodos estritos de identificação causal.",
  "- Fila de auditoria: `other_modern_causal_method`.",
  "- Sensibilidade inclusiva: união de artigos únicos com método estrito ou `other_modern_causal_method`.",
  "",
  "## Resultados preliminares",
  "",
  paste0("- Método estrito de credibilidade: ", sum(analysis_df$conservative_credibility_design, na.rm = TRUE), " artigos."),
  paste0("- Fila `other_modern_causal_method`: ", sum(analysis_df$other_modern_audit_queue, na.rm = TRUE), " artigos; destes, ", sum(analysis_df$other_modern_broad_only, na.rm = TRUE), " não têm método estrito também."),
  paste0("- Medida inclusiva de sensibilidade (união de artigos únicos): ", sum(analysis_df$inclusive_credibility_design, na.rm = TRUE), " artigos."),
  paste0("- Tough calls: ", sum(analysis_df$tough_call, na.rm = TRUE), " artigos."),
  "",
  "## Aviso de interpretação",
  "",
  "Os 400 artigos classificados correspondem aos primeiros PIDs do manifest e não formam uma amostra aleatória do corpus completo. As taxas deste relatório servem para validar o pipeline e antecipar a estrutura analítica; não devem ser usadas como estimativa substantiva final do paper.",
  "",
  "## Artefatos principais",
  "",
  "- Base analítica: `data/processed/credibility_prompt_v3_integral_reading/preliminary_analysis/analysis_dataset_preliminary.csv`.",
  "- Tabelas: `output/tables/preliminary_credibility/`.",
  "- Figuras: `output/figures/preliminary_credibility/`.",
  "- Relatório: `quality_reports/preliminary_credibility_analysis.pdf`."
)

write_utf8_lines(summary_lines, file.path(quality_dir, "preliminary_credibility_analysis_summary.md"))
capture.output(sessionInfo(), file = file.path(analysis_dir, "session_info.txt"))

cat("Análise preliminar escrita em:\n")
cat("- ", analysis_dir, "\n", sep = "")
cat("- ", tables_dir, "\n", sep = "")
cat("- ", figures_dir, "\n", sep = "")
cat("- ", file.path(quality_dir, "preliminary_credibility_analysis_summary.md"), "\n", sep = "")
