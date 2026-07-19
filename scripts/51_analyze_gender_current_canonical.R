#!/usr/bin/env Rscript

## Produz uma análise descritiva de gênero da autoria no CSV canônico corrente.
## Gênero é inferido pelo pacote genderBR a partir do primeiro nome e dos dados
## de nomes do Censo Demográfico 2022 do IBGE. Casos ambíguos ficam não classificados.

options(scipen = 999, encoding = "UTF-8")
set.seed(20260719)

required_packages <- c("dplyr", "genderBR", "ggplot2", "jsonlite", "readr", "stringr", "tidyr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]
if (length(missing_packages) > 0) {
  stop(
    "Pacotes ausentes: ", paste(missing_packages, collapse = ", "),
    ". Instale-os antes de executar o script; para genderBR, use install.packages('genderBR')."
  )
}

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

classifications_path <- path(
  "data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv"
)
manifest_path <- path("data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv")
processed_dir <- path("data/processed/gender_analysis")
tables_dir <- path("output/tables/gender_analysis")
figures_dir <- path("output/figures/gender_analysis")
report_path <- path("quality_reports/gender_analysis_current_canonical.md")

dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

required_files <- c(classifications_path, manifest_path)
if (!all(file.exists(required_files))) {
  stop("Arquivos ausentes: ", paste(required_files[!file.exists(required_files)], collapse = "; "))
}

gender_threshold <- 0.90
gender_census_year <- 2022L
period_levels <- c("2005-2011", "2012-2018", "2019-2025")
metric_levels <- c(
  "Artigos empíricos",
  "Análise quantitativa",
  "Inferência estatística",
  "Linguagem causal ou explicativa",
  "Examinados para identificação",
  "Estratégia explícita de identificação"
)

## As duas primeiras exclusões são regras permanentes do projeto; as duas últimas
## foram solicitadas especificamente para esta análise adicional.
excluded_journal_rules <- tibble::tribble(
  ~journal_title, ~exclusion_basis,
  "Brazilian Journal of Political Economy", "Regra permanente de escopo do projeto",
  "Civitas - Revista de Ciências Sociais", "Regra permanente de escopo do projeto",
  "Lua Nova: Revista de Cultura e Política", "Exclusão solicitada para esta análise",
  "Novos estudos CEBRAP", "Exclusão solicitada para esta análise"
) |>
  dplyr::mutate(journal_key = stringr::str_to_lower(stringr::str_squish(journal_title)))

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

fmt_int <- function(x) {
  format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

fmt_pct <- function(x, digits = 1) {
  ifelse(
    is.na(x),
    "-",
    paste0(format(round(x, digits), decimal.mark = ",", nsmall = digits, trim = TRUE), "%")
  )
}

fmt_pp <- function(x, digits = 1) {
  ifelse(
    is.na(x),
    "-",
    paste0(
      ifelse(round(x, digits) > 0, "+", ""),
      format(round(x, digits), decimal.mark = ",", nsmall = digits, trim = TRUE),
      " p.p."
    )
  )
}

write_utf8_lines <- function(lines, file) {
  connection <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(connection), add = TRUE)
  writeLines(enc2utf8(lines), con = connection, useBytes = TRUE)
}

escape_md <- function(x) {
  x |>
    as.character() |>
    stringr::str_replace_all("\\|", "\\\\|") |>
    stringr::str_replace_all("\\r?\\n", " ")
}

markdown_table <- function(data) {
  data_chr <- data |>
    dplyr::mutate(dplyr::across(dplyr::everything(), ~ escape_md(dplyr::coalesce(as.character(.x), "-"))))
  header <- paste0("| ", paste(names(data_chr), collapse = " | "), " |")
  separator <- paste0("| ", paste(rep("---", ncol(data_chr)), collapse = " | "), " |")
  rows <- apply(data_chr, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  c(header, separator, rows)
}

safe_rate <- function(numerator, denominator) {
  dplyr::if_else(denominator > 0, 100 * numerator / denominator, NA_real_)
}

classifications_source <- readr::read_csv(classifications_path, show_col_types = FALSE)
classifications <- classifications_source |>
  dplyr::distinct()
n_exact_duplicate_rows <- nrow(classifications_source) - nrow(classifications)

duplicate_classifications <- classifications |>
  dplyr::count(pid, name = "n_rows") |>
  dplyr::filter(n_rows > 1)
if (nrow(duplicate_classifications) > 0) {
  stop("O CSV canônico contém PIDs repetidos com linhas distintas; a análise foi interrompida.")
}

manifest_source <- readr::read_csv(manifest_path, show_col_types = FALSE)
duplicate_manifest <- manifest_source |>
  dplyr::count(pid, name = "n_rows") |>
  dplyr::filter(n_rows > 1)
if (nrow(duplicate_manifest) > 0) {
  stop("O manifest contém PIDs repetidos; a análise foi interrompida.")
}

canonical_without_metadata <- classifications |>
  dplyr::anti_join(manifest_source |> dplyr::select(pid), by = "pid")
if (nrow(canonical_without_metadata) > 0) {
  stop(
    "Há ", nrow(canonical_without_metadata),
    " artigos canônicos sem metadados no manifest; a análise de autoria foi interrompida."
  )
}

canonical_scope <- classifications |>
  dplyr::mutate(
    journal_key = stringr::str_to_lower(stringr::str_squish(journal_title)),
    is_empirical_paper = parse_bool(is_empirical_paper),
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    has_statistical_inference = parse_bool(has_statistical_inference),
    causal_or_explanatory_claim_present = parse_bool(causal_or_explanatory_claim_present),
    credibility_revolution_screen_applicable = parse_bool(credibility_revolution_screen_applicable),
    method_type = lapply(credibility_revolution_method_type, parse_method_types)
  ) |>
  dplyr::anti_join(excluded_journal_rules |> dplyr::select(journal_key), by = "journal_key") |>
  dplyr::left_join(
    manifest_source |>
      dplyr::transmute(
        pid,
        authors,
        year = as.integer(year),
        language = as.character(language),
        manifest_journal_title = journal_title
      ),
    by = "pid"
  ) |>
  dplyr::mutate(
    journal_title = dplyr::coalesce(journal_title, manifest_journal_title),
    period_3 = period_3(year)
  )

invalid_years <- canonical_scope |>
  dplyr::filter(is.na(year) | !dplyr::between(year, 2005L, 2025L)) |>
  dplyr::select(pid, year)
if (nrow(invalid_years) > 0) {
  stop("Há anos ausentes ou fora de 2005-2025 na base analítica; a análise foi interrompida.")
}

method_long <- canonical_scope |>
  dplyr::select(pid, method_type) |>
  tidyr::unnest(method_type, keep_empty = FALSE)

strict_pids <- method_long |>
  dplyr::filter(method_type %in% strict_design_methods) |>
  dplyr::pull(pid) |>
  unique()

canonical_scope <- canonical_scope |>
  dplyr::mutate(strict_design_method = pid %in% strict_pids)

author_occurrences <- canonical_scope |>
  dplyr::select(pid, authors) |>
  dplyr::mutate(author_list = stringr::str_split(dplyr::coalesce(authors, ""), stringr::fixed(";"))) |>
  tidyr::unnest_longer(author_list, indices_to = "author_position") |>
  dplyr::transmute(
    pid,
    author_position = as.integer(author_position),
    author_name = stringr::str_squish(author_list)
  ) |>
  dplyr::filter(author_name != "")

unique_author_names <- author_occurrences |>
  dplyr::distinct(author_name) |>
  dplyr::arrange(author_name)

female_probability <- genderBR::get_gender(
  unique_author_names$author_name,
  prob = TRUE,
  threshold = gender_threshold,
  internal = TRUE,
  year = gender_census_year
)

author_dictionary <- unique_author_names |>
  dplyr::mutate(
    female_probability = as.numeric(female_probability),
    inferred_gender = dplyr::case_when(
      female_probability > gender_threshold ~ "Feminino",
      female_probability < (1 - gender_threshold) ~ "Masculino",
      TRUE ~ "Não classificado"
    ),
    classifier = "genderBR::get_gender",
    classifier_version = as.character(utils::packageVersion("genderBR")),
    census_year = gender_census_year,
    threshold = gender_threshold
  )

author_gender <- author_occurrences |>
  dplyr::left_join(author_dictionary, by = "author_name") |>
  dplyr::left_join(
    canonical_scope |>
      dplyr::select(pid, title, journal_title, year, period_3),
    by = "pid"
  ) |>
  dplyr::select(
    pid,
    title,
    journal_title,
    year,
    period_3,
    author_position,
    author_name,
    inferred_gender,
    female_probability,
    classifier,
    classifier_version,
    census_year,
    threshold
  )

article_gender <- canonical_scope |>
  dplyr::left_join(
    author_gender |>
      dplyr::filter(author_position == 1L) |>
      dplyr::select(
        pid,
        first_author_name = author_name,
        first_author_gender = inferred_gender,
        first_author_female_probability = female_probability
      ),
    by = "pid"
  ) |>
  dplyr::left_join(
    author_gender |>
      dplyr::group_by(pid) |>
      dplyr::summarise(
        n_authors = dplyr::n(),
        n_female_authors = sum(inferred_gender == "Feminino"),
        n_male_authors = sum(inferred_gender == "Masculino"),
        n_unclassified_authors = sum(inferred_gender == "Não classificado"),
        .groups = "drop"
      ),
    by = "pid"
  ) |>
  dplyr::mutate(
    first_author_gender = dplyr::coalesce(first_author_gender, "Não classificado"),
    n_authors = dplyr::coalesce(n_authors, 0L),
    n_female_authors = dplyr::coalesce(n_female_authors, 0L),
    n_male_authors = dplyr::coalesce(n_male_authors, 0L),
    n_unclassified_authors = dplyr::coalesce(n_unclassified_authors, 0L),
    first_author_classification_status = dplyr::case_when(
      first_author_gender %in% c("Feminino", "Masculino") ~ "Classificado",
      n_authors == 0L ~ "Autoria ausente",
      is.na(first_author_female_probability) ~ "Prenome não encontrado",
      TRUE ~ "Ambíguo no limiar"
    ),
    team_gender_composition = dplyr::case_when(
      n_authors == 0L | n_unclassified_authors > 0L ~ "Indeterminada",
      n_female_authors > 0L & n_male_authors > 0L ~ "Mista",
      n_female_authors == n_authors ~ "Somente mulheres",
      n_male_authors == n_authors ~ "Somente homens",
      TRUE ~ "Indeterminada"
    )
  )

metric_summary <- function(data, group_var) {
  data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_var))) |>
    dplyr::summarise(
      n_articles = dplyr::n(),
      n_empirical = sum(is_empirical_paper %in% TRUE),
      n_quantitative = sum(is_empirical_paper %in% TRUE & is_empirical_quant_paper_torreblanca %in% TRUE),
      n_quantitative_observed = sum(is_empirical_paper %in% TRUE & !is.na(is_empirical_quant_paper_torreblanca)),
      n_inference = sum(is_empirical_quant_paper_torreblanca %in% TRUE & has_statistical_inference %in% TRUE),
      n_inference_observed = sum(is_empirical_quant_paper_torreblanca %in% TRUE & !is.na(has_statistical_inference)),
      n_claim = sum(is_empirical_paper %in% TRUE & causal_or_explanatory_claim_present %in% TRUE),
      n_claim_observed = sum(is_empirical_paper %in% TRUE & !is.na(causal_or_explanatory_claim_present)),
      n_screen = sum(credibility_revolution_screen_applicable %in% TRUE),
      n_screen_observed = sum(!is.na(credibility_revolution_screen_applicable)),
      n_strict = sum(credibility_revolution_screen_applicable %in% TRUE & strict_design_method),
      .groups = "drop"
    ) |>
    tidyr::pivot_longer(
      cols = -dplyr::all_of(group_var),
      names_to = "statistic",
      values_to = "value"
    ) |>
    tidyr::pivot_wider(names_from = statistic, values_from = value) |>
    tidyr::crossing(metric = factor(metric_levels, levels = metric_levels)) |>
    dplyr::mutate(
      numerator = dplyr::case_when(
        metric == "Artigos empíricos" ~ n_empirical,
        metric == "Análise quantitativa" ~ n_quantitative,
        metric == "Inferência estatística" ~ n_inference,
        metric == "Linguagem causal ou explicativa" ~ n_claim,
        metric == "Examinados para identificação" ~ n_screen,
        metric == "Estratégia explícita de identificação" ~ n_strict
      ),
      denominator = dplyr::case_when(
        metric == "Artigos empíricos" ~ n_articles,
        metric == "Análise quantitativa" ~ n_quantitative_observed,
        metric == "Inferência estatística" ~ n_inference_observed,
        metric == "Linguagem causal ou explicativa" ~ n_claim_observed,
        metric == "Examinados para identificação" ~ n_screen_observed,
        metric == "Estratégia explícita de identificação" ~ n_screen
      ),
      percent = safe_rate(numerator, denominator),
      denominator_definition = dplyr::case_when(
        metric == "Artigos empíricos" ~ "todos os artigos",
        metric == "Análise quantitativa" ~ "artigos empíricos com classificação quantitativa observada",
        metric == "Inferência estatística" ~ "artigos empíricos quantitativos com inferência observada",
        metric == "Linguagem causal ou explicativa" ~ "artigos empíricos com claim observado",
        metric == "Examinados para identificação" ~ "todos os artigos com screen observado",
        metric == "Estratégia explícita de identificação" ~ "artigos examinados para identificação"
      )
    ) |>
    dplyr::select(dplyr::all_of(group_var), metric, numerator, denominator, percent, denominator_definition)
}

first_author_distribution <- article_gender |>
  dplyr::count(first_author_gender, name = "n_articles") |>
  dplyr::mutate(percent = 100 * n_articles / sum(n_articles)) |>
  dplyr::arrange(factor(first_author_gender, levels = c("Feminino", "Masculino", "Não classificado")))

first_author_failure_distribution <- article_gender |>
  dplyr::count(first_author_classification_status, name = "n_articles") |>
  dplyr::mutate(percent = 100 * n_articles / sum(n_articles)) |>
  dplyr::arrange(
    factor(
      first_author_classification_status,
      levels = c("Classificado", "Ambíguo no limiar", "Prenome não encontrado", "Autoria ausente")
    )
  )

gender_coverage_by_journal <- article_gender |>
  dplyr::group_by(journal_title) |>
  dplyr::summarise(
    n_articles = dplyr::n(),
    n_classified = sum(first_author_classification_status == "Classificado"),
    n_unclassified = n_articles - n_classified,
    coverage_percent = 100 * n_classified / n_articles,
    .groups = "drop"
  ) |>
  dplyr::arrange(coverage_percent, journal_title)

gender_coverage_by_language <- article_gender |>
  dplyr::mutate(language = dplyr::coalesce(language, "ausente")) |>
  dplyr::group_by(language) |>
  dplyr::summarise(
    n_articles = dplyr::n(),
    n_classified = sum(first_author_classification_status == "Classificado"),
    n_unclassified = n_articles - n_classified,
    coverage_percent = 100 * n_classified / n_articles,
    .groups = "drop"
  ) |>
  dplyr::arrange(coverage_percent, language)

team_distribution <- article_gender |>
  dplyr::count(team_gender_composition, name = "n_articles") |>
  dplyr::mutate(percent = 100 * n_articles / sum(n_articles)) |>
  dplyr::arrange(
    factor(
      team_gender_composition,
      levels = c("Somente mulheres", "Somente homens", "Mista", "Indeterminada")
    )
  )

binary_gender_df <- article_gender |>
  dplyr::filter(first_author_gender %in% c("Feminino", "Masculino"))

metrics_by_first_author <- metric_summary(binary_gender_df, "first_author_gender")
metrics_by_team <- metric_summary(article_gender, "team_gender_composition")

metric_comparison <- metrics_by_first_author |>
  dplyr::select(first_author_gender, metric, numerator, denominator, percent) |>
  tidyr::pivot_wider(
    names_from = first_author_gender,
    values_from = c(numerator, denominator, percent),
    names_glue = "{.value}_{first_author_gender}"
  ) |>
  dplyr::mutate(
    metric = factor(metric, levels = metric_levels),
    difference_pp_female_minus_male = percent_Feminino - percent_Masculino
  ) |>
  dplyr::arrange(metric)

standardized_comparison <- metric_summary(
  binary_gender_df,
  c("first_author_gender", "journal_title", "period_3")
) |>
  dplyr::select(first_author_gender, journal_title, period_3, metric, denominator, percent) |>
  tidyr::pivot_wider(
    names_from = first_author_gender,
    values_from = c(denominator, percent),
    names_glue = "{.value}_{first_author_gender}"
  ) |>
  dplyr::filter(
    denominator_Feminino > 0,
    denominator_Masculino > 0,
    !is.na(percent_Feminino),
    !is.na(percent_Masculino)
  ) |>
  dplyr::group_by(metric) |>
  dplyr::mutate(
    pooled_denominator = denominator_Feminino + denominator_Masculino,
    standardization_weight = pooled_denominator / sum(pooled_denominator)
  ) |>
  dplyr::summarise(
    n_common_strata = dplyr::n(),
    standardized_percent_female = sum(standardization_weight * percent_Feminino),
    standardized_percent_male = sum(standardization_weight * percent_Masculino),
    standardized_difference_pp = standardized_percent_female - standardized_percent_male,
    .groups = "drop"
  ) |>
  dplyr::mutate(metric = factor(metric, levels = metric_levels)) |>
  dplyr::arrange(metric)

sensitivity_thresholds <- c(0.80, 0.90, 0.95)
sensitivity_results <- lapply(sensitivity_thresholds, function(current_threshold) {
  sensitivity_df <- article_gender |>
    dplyr::mutate(
      first_author_gender = dplyr::case_when(
        first_author_female_probability > current_threshold ~ "Feminino",
        first_author_female_probability < (1 - current_threshold) ~ "Masculino",
        TRUE ~ "Não classificado"
      )
    )

  sensitivity_metrics <- sensitivity_df |>
    dplyr::filter(first_author_gender %in% c("Feminino", "Masculino")) |>
    metric_summary("first_author_gender") |>
    dplyr::filter(metric %in% c("Análise quantitativa", "Inferência estatística")) |>
    dplyr::select(first_author_gender, metric, percent) |>
    tidyr::pivot_wider(names_from = first_author_gender, values_from = percent) |>
    dplyr::mutate(difference_pp_female_minus_male = Feminino - Masculino)

  sensitivity_metrics |>
    dplyr::mutate(
      threshold = current_threshold,
      n_binary_classified = sum(sensitivity_df$first_author_gender %in% c("Feminino", "Masculino")),
      coverage_percent = 100 * n_binary_classified / nrow(sensitivity_df)
    ) |>
    dplyr::select(
      threshold,
      n_binary_classified,
      coverage_percent,
      metric,
      Feminino,
      Masculino,
      difference_pp_female_minus_male
    )
}) |>
  dplyr::bind_rows() |>
  dplyr::mutate(metric = factor(metric, levels = metric_levels)) |>
  dplyr::arrange(threshold, metric)

evidence_by_first_author <- binary_gender_df |>
  dplyr::filter(is_empirical_paper %in% TRUE) |>
  dplyr::mutate(
    evidence_type = dplyr::case_when(
      empirical_evidence_type == "qualitative_only" ~ "Somente qualitativa",
      empirical_evidence_type == "quantitative_only" ~ "Somente quantitativa",
      empirical_evidence_type == "mixed_empirical" ~ "Mista",
      empirical_evidence_type == "none" ~ "Nenhuma",
      TRUE ~ "Incerta/ausente"
    )
  ) |>
  dplyr::count(first_author_gender, evidence_type, name = "n_articles") |>
  dplyr::group_by(first_author_gender) |>
  dplyr::mutate(
    denominator = sum(n_articles),
    percent = 100 * n_articles / denominator
  ) |>
  dplyr::ungroup()

first_author_by_period <- article_gender |>
  dplyr::count(period_3, first_author_gender, name = "n_articles") |>
  tidyr::complete(
    period_3 = factor(period_levels, levels = period_levels),
    first_author_gender = c("Feminino", "Masculino", "Não classificado"),
    fill = list(n_articles = 0L)
  ) |>
  dplyr::group_by(period_3) |>
  dplyr::mutate(
    period_total = sum(n_articles),
    percent_all = 100 * n_articles / period_total,
    binary_total = sum(n_articles[first_author_gender %in% c("Feminino", "Masculino")]),
    percent_within_binary = dplyr::if_else(
      first_author_gender %in% c("Feminino", "Masculino") & binary_total > 0,
      100 * n_articles / binary_total,
      NA_real_
    )
  ) |>
  dplyr::ungroup()

exclusion_counts <- excluded_journal_rules |>
  dplyr::select(rule_journal_title = journal_title, journal_key, exclusion_basis) |>
  dplyr::left_join(
    classifications |>
      dplyr::mutate(journal_key = stringr::str_to_lower(stringr::str_squish(journal_title))) |>
      dplyr::count(journal_key, name = "n_excluded"),
    by = "journal_key"
  ) |>
  dplyr::mutate(n_excluded = dplyr::coalesce(n_excluded, 0L)) |>
  dplyr::select(rule_journal_title, exclusion_basis, n_excluded)

method_parse_failures <- sum(vapply(
  canonical_scope$method_type,
  function(value) any(is.na(value)),
  FUN.VALUE = logical(1)
))

excluded_remaining <- canonical_scope |>
  dplyr::mutate(journal_key = stringr::str_to_lower(stringr::str_squish(journal_title))) |>
  dplyr::semi_join(excluded_journal_rules |> dplyr::select(journal_key), by = "journal_key")

metric_denominators_valid <- all(
  metrics_by_first_author$denominator > 0 &
    metrics_by_first_author$numerator >= 0 &
    metrics_by_first_author$numerator <= metrics_by_first_author$denominator
)

validation_checks <- tibble::tibble(
  check = c(
    "PIDs únicos no CSV canônico",
    "PIDs canônicos encontrados no manifest",
    "Anos entre 2005 e 2025",
    "Tamanho analítico reconciliado com as exclusões",
    "Periódicos excluídos ausentes da base analítica",
    "Missing de autoria reconciliado com o status",
    "Categorias do primeiro prenome formam partição exaustiva",
    "Probabilidades dentro do intervalo [0, 1]",
    "JSON de métodos sem falhas de parsing",
    "Numeradores não excedem denominadores"
  ),
  value = c(
    nrow(classifications) == dplyr::n_distinct(classifications$pid),
    nrow(canonical_without_metadata) == 0,
    nrow(invalid_years) == 0,
    nrow(article_gender) == nrow(classifications) - sum(exclusion_counts$n_excluded),
    nrow(excluded_remaining) == 0,
    sum(article_gender$n_authors == 0L) ==
      sum(article_gender$first_author_classification_status == "Autoria ausente"),
    sum(first_author_distribution$n_articles) == nrow(article_gender),
    all(is.na(author_dictionary$female_probability) |
      dplyr::between(author_dictionary$female_probability, 0, 1)),
    method_parse_failures == 0,
    metric_denominators_valid
  ),
  status = ifelse(value, "PASS", "FAIL")
)
if (any(validation_checks$status == "FAIL")) {
  failed_checks <- validation_checks |>
    dplyr::filter(status == "FAIL") |>
    dplyr::pull(check)
  stop(
    "Uma ou mais validações falharam: ", paste(failed_checks, collapse = "; "),
    ". A análise foi interrompida antes da escrita dos outputs."
  )
}

readr::write_csv(author_gender, file.path(processed_dir, "current_canonical_author_gender.csv"))
readr::write_csv(
  article_gender |>
    dplyr::select(
      pid,
      title,
      journal_title,
      year,
      period_3,
      language,
      authors,
      first_author_name,
      first_author_gender,
      first_author_female_probability,
      n_authors,
      n_female_authors,
      n_male_authors,
      n_unclassified_authors,
      first_author_classification_status,
      team_gender_composition,
      is_empirical_paper,
      empirical_evidence_type,
      is_empirical_quant_paper_torreblanca,
      has_statistical_inference,
      causal_or_explanatory_claim_present,
      credibility_revolution_screen_applicable,
      strict_design_method
    ),
  file.path(processed_dir, "current_canonical_article_gender.csv")
)
readr::write_csv(first_author_distribution, file.path(tables_dir, "table_1_first_author_gender.csv"))
readr::write_csv(team_distribution, file.path(tables_dir, "table_2_team_gender_composition.csv"))
readr::write_csv(metric_comparison, file.path(tables_dir, "table_3_methodological_indicators_by_first_author_gender.csv"))
readr::write_csv(evidence_by_first_author, file.path(tables_dir, "table_4_evidence_by_first_author_gender.csv"))
readr::write_csv(first_author_by_period, file.path(tables_dir, "table_5_first_author_gender_by_period.csv"))
readr::write_csv(metrics_by_team, file.path(tables_dir, "table_6_methodological_indicators_by_team.csv"))
readr::write_csv(standardized_comparison, file.path(tables_dir, "table_7_standardized_comparison_journal_period.csv"))
readr::write_csv(gender_coverage_by_journal, file.path(tables_dir, "table_8_gender_coverage_by_journal.csv"))
readr::write_csv(gender_coverage_by_language, file.path(tables_dir, "table_9_gender_coverage_by_language.csv"))
readr::write_csv(first_author_failure_distribution, file.path(tables_dir, "table_10_gender_classification_status.csv"))
readr::write_csv(sensitivity_results, file.path(tables_dir, "table_11_gender_threshold_sensitivity.csv"))
readr::write_csv(exclusion_counts, file.path(tables_dir, "excluded_journals_counts.csv"))
readr::write_csv(validation_checks, file.path(tables_dir, "validation_checks.csv"))

gender_colors <- c(
  "Feminino" = "#B33A6F",
  "Masculino" = "#285F8F",
  "Não classificado" = "#8C8C8C"
)

figure_1 <- first_author_by_period |>
  ggplot2::ggplot(
    ggplot2::aes(x = period_3, y = n_articles, fill = first_author_gender)
  ) +
  ggplot2::geom_col(position = "fill", width = 0.72) +
  ggplot2::scale_fill_manual(values = gender_colors) +
  ggplot2::scale_y_continuous(
    labels = function(x) paste0(round(100 * x), "%"),
    expand = ggplot2::expansion(mult = c(0, 0.02))
  ) +
  ggplot2::labs(
    x = "Período de publicação",
    y = "Proporção dos artigos",
    fill = "Classificação do\nprimeiro prenome"
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    legend.position = "bottom",
    panel.grid.minor = ggplot2::element_blank(),
    axis.title = ggplot2::element_text(face = "bold")
  )

ggplot2::ggsave(
  filename = file.path(figures_dir, "figure_1_first_author_gender_by_period.png"),
  plot = figure_1,
  width = 8.5,
  height = 5.4,
  dpi = 320,
  bg = "white"
)

figure_2 <- metrics_by_first_author |>
  dplyr::mutate(
    metric = factor(metric, levels = rev(metric_levels))
  ) |>
  ggplot2::ggplot(
    ggplot2::aes(x = percent, y = metric, fill = first_author_gender)
  ) +
  ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.72), width = 0.66) +
  ggplot2::geom_text(
    ggplot2::aes(label = fmt_pct(percent)),
    position = ggplot2::position_dodge(width = 0.72),
    hjust = -0.08,
    size = 3.2
  ) +
  ggplot2::scale_fill_manual(values = gender_colors[c("Feminino", "Masculino")]) +
  ggplot2::scale_x_continuous(
    limits = c(0, 105),
    breaks = seq(0, 100, 20),
    labels = function(x) paste0(x, "%"),
    expand = ggplot2::expansion(mult = c(0, 0))
  ) +
  ggplot2::labs(
    x = "Proporção no denominador relevante",
    y = NULL,
    fill = "Classificação do\nprimeiro prenome"
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    legend.position = "bottom",
    panel.grid.minor = ggplot2::element_blank(),
    axis.title.x = ggplot2::element_text(face = "bold")
  )

ggplot2::ggsave(
  filename = file.path(figures_dir, "figure_2_methodological_indicators_by_first_author_gender.png"),
  plot = figure_2,
  width = 9.5,
  height = 6.3,
  dpi = 320,
  bg = "white"
)

first_author_table <- first_author_distribution |>
  dplyr::transmute(
    `Classificação do primeiro prenome` = first_author_gender,
    `Artigos` = fmt_int(n_articles),
    `Proporção do corpus` = fmt_pct(percent)
  )

team_table <- team_distribution |>
  dplyr::transmute(
    `Composição dos prenomes na equipe` = dplyr::recode(
      team_gender_composition,
      "Somente mulheres" = "Somente prenomes classificados como femininos",
      "Somente homens" = "Somente prenomes classificados como masculinos",
      "Mista" = "Prenomes classificados nas duas categorias",
      "Indeterminada" = "Indeterminada"
    ),
    `Artigos` = fmt_int(n_articles),
    `Proporção do corpus` = fmt_pct(percent)
  )

metric_table <- metric_comparison |>
  dplyr::transmute(
    Indicador = metric,
    `Feminino: n/N` = paste0(fmt_int(numerator_Feminino), "/", fmt_int(denominator_Feminino)),
    `Feminino: %` = fmt_pct(percent_Feminino),
    `Masculino: n/N` = paste0(fmt_int(numerator_Masculino), "/", fmt_int(denominator_Masculino)),
    `Masculino: %` = fmt_pct(percent_Masculino),
    `Diferença F−M` = fmt_pp(difference_pp_female_minus_male)
  )

evidence_table <- evidence_by_first_author |>
  dplyr::transmute(
    `Classificação do primeiro prenome` = first_author_gender,
    `Tipo de evidência` = evidence_type,
    `Artigos` = fmt_int(n_articles),
    `Denominador empírico` = fmt_int(denominator),
    `Proporção` = fmt_pct(percent)
  ) |>
  dplyr::arrange(`Classificação do primeiro prenome`, `Tipo de evidência`)

team_metric_table <- metrics_by_team |>
  dplyr::mutate(
    metric = factor(metric, levels = metric_levels),
    display = paste0(fmt_int(numerator), "/", fmt_int(denominator), " (", fmt_pct(percent), ")")
  ) |>
  dplyr::select(team_gender_composition, metric, display) |>
  tidyr::pivot_wider(names_from = team_gender_composition, values_from = display) |>
  dplyr::arrange(metric) |>
  dplyr::transmute(
    Indicador = as.character(metric),
    `Só prenomes femininos` = `Somente mulheres`,
    `Só prenomes masculinos` = `Somente homens`,
    `Duas categorias` = Mista,
    Indeterminada = Indeterminada
  )

standardized_table <- standardized_comparison |>
  dplyr::transmute(
    Indicador = as.character(metric),
    `Estratos comuns` = fmt_int(n_common_strata),
    `Prenome feminino padronizado` = fmt_pct(standardized_percent_female),
    `Prenome masculino padronizado` = fmt_pct(standardized_percent_male),
    `Diferença padronizada F−M` = fmt_pp(standardized_difference_pp)
  )

coverage_journal_table <- gender_coverage_by_journal |>
  dplyr::transmute(
    Periódico = journal_title,
    Artigos = fmt_int(n_articles),
    Classificados = fmt_int(n_classified),
    `Não classificados` = fmt_int(n_unclassified),
    Cobertura = fmt_pct(coverage_percent)
  )

failure_table <- first_author_failure_distribution |>
  dplyr::transmute(
    `Status da classificação` = first_author_classification_status,
    Artigos = fmt_int(n_articles),
    `Proporção do corpus` = fmt_pct(percent)
  )

exclusion_table <- exclusion_counts |>
  dplyr::transmute(
    Periódico = rule_journal_title,
    `Base da exclusão` = exclusion_basis,
    `Registros removidos do CSV` = fmt_int(n_excluded)
  )

sensitivity_table <- sensitivity_results |>
  dplyr::transmute(
    Limiar = format(threshold, decimal.mark = ",", nsmall = 2, trim = TRUE),
    Cobertura = fmt_pct(coverage_percent),
    Indicador = as.character(metric),
    `Prenome feminino` = fmt_pct(Feminino),
    `Prenome masculino` = fmt_pct(Masculino),
    `Diferença F−M` = fmt_pp(difference_pp_female_minus_male)
  )

period_table <- first_author_by_period |>
  dplyr::filter(first_author_gender == "Feminino") |>
  dplyr::transmute(
    Período = as.character(period_3),
    `Primeiro prenome classificado como feminino` = fmt_int(n_articles),
    `Primeiros prenomes classificados` = fmt_int(binary_total),
    `Proporção feminina entre classificados` = fmt_pct(percent_within_binary),
    `Primeiros prenomes não classificados` = fmt_int(
      first_author_by_period$n_articles[
        match(
          paste(period_3, "Não classificado"),
          paste(first_author_by_period$period_3, first_author_by_period$first_author_gender)
        )
      ]
    )
  )

validation_table <- validation_checks |>
  dplyr::transmute(Validação = check, Status = status)

n_canonical <- nrow(classifications)
n_analytic <- nrow(article_gender)
n_excluded <- n_canonical - n_analytic
n_binary <- nrow(binary_gender_df)
n_first_female <- sum(article_gender$first_author_gender == "Feminino")
n_first_male <- sum(article_gender$first_author_gender == "Masculino")
n_first_unknown <- sum(article_gender$first_author_gender == "Não classificado")
n_missing_authors <- sum(article_gender$n_authors == 0L)
coverage_binary <- 100 * n_binary / n_analytic
female_share_binary <- 100 * n_first_female / n_binary

quant_row <- metric_comparison |>
  dplyr::filter(metric == "Análise quantitativa")
strict_row <- metric_comparison |>
  dplyr::filter(metric == "Estratégia explícita de identificação")
standardized_quant_row <- standardized_comparison |>
  dplyr::filter(metric == "Análise quantitativa")
standardized_inference_row <- standardized_comparison |>
  dplyr::filter(metric == "Inferência estatística")
english_coverage_row <- gender_coverage_by_language |>
  dplyr::filter(language == "en")
portuguese_coverage_row <- gender_coverage_by_language |>
  dplyr::filter(language == "pt")
canonical_md5 <- unname(tools::md5sum(classifications_path))
canonical_mtime <- format(file.info(classifications_path)$mtime, "%Y-%m-%d %H:%M:%S %Z")
manifest_md5 <- unname(tools::md5sum(manifest_path))
manifest_mtime <- format(file.info(manifest_path)$mtime, "%Y-%m-%d %H:%M:%S %Z")
package_versions <- paste0(
  required_packages,
  " ",
  vapply(
    required_packages,
    function(package_name) as.character(utils::packageVersion(package_name)),
    FUN.VALUE = character(1)
  ),
  collapse = "; "
)
execution_date <- format(Sys.Date(), "%Y-%m-%d")

report_lines <- c(
  "# Análise adicional por classificação binária inferida dos prenomes de autoria",
  "",
  paste0("**Data de execução:** ", execution_date),
  "",
  "## Síntese",
  "",
  paste0(
    "A análise parte dos ", fmt_int(n_canonical), " PIDs distintos do CSV canônico corrente. ",
    "Após as exclusões de escopo, restam ", fmt_int(n_analytic), " artigos; ",
    fmt_int(n_excluded), " registros foram retirados. O `genderBR` classificou o primeiro prenome ",
    "como feminino ou masculino em ", fmt_int(n_binary), " casos (", fmt_pct(coverage_binary), ")."
  ),
  "",
  paste0(
    "Entre os primeiros prenomes classificados, ", fmt_int(n_first_female), " (", fmt_pct(female_share_binary),
    ") ficaram na categoria feminina e ", fmt_int(n_first_male), " na masculina. ",
    "Outros ", fmt_int(n_first_unknown), " artigos permaneceram sem classificação binária; ",
    fmt_int(n_missing_authors), " deles não tinham autoria registrada no manifest."
  ),
  "",
  paste0(
    "As diferenças brutas de composição indicam análise quantitativa em ", fmt_pct(quant_row$percent_Feminino),
    " dos artigos com primeiro prenome feminino e ", fmt_pct(quant_row$percent_Masculino),
    " daqueles com primeiro prenome masculino (", fmt_pp(quant_row$difference_pp_female_minus_male), "). ",
    "Após padronização descritiva pela distribuição conjunta de periódico e período, a diferença é ",
    fmt_pp(standardized_quant_row$standardized_difference_pp), "; para inferência estatística, é ",
    fmt_pp(standardized_inference_row$standardized_difference_pp)
  ),
  "",
  paste0(
    "Entre os artigos examinados para identificação — e somente nesse denominador — estratégias explícitas aparecem em ",
    fmt_pct(strict_row$percent_Feminino), " na categoria feminina e ",
    fmt_pct(strict_row$percent_Masculino), " na masculina."
  ),
  "",
  "Essas diferenças são descritivas e correlacionais. A classificação do prenome não observa identidade de gênero nem necessariamente o sexo de cada pessoa; tampouco os contrastes identificam preferências individuais ou efeitos de gênero.",
  "",
  "A inferência está exclusivamente no relatório bayesiano `quality_reports/gender_analysis_bayesian_hierarchical.md`; o presente relatório limita-se à descrição dos dados.",
  "",
  "## População analítica e exclusões",
  "",
  "A população de partida é o CSV canônico de classificações por leitura integral. Foram excluídos `Lua Nova: Revista de Cultura e Política` e `Novos estudos CEBRAP`, conforme solicitado. Também foram aplicadas as regras permanentes para `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais`; estes dois periódicos já tinham zero registros no CSV de partida.",
  "",
  "Os resultados descrevem somente os artigos já presentes no snapshot canônico corrente; não são extrapolados para artigos que ainda não tenham sido incorporados a esse CSV.",
  "",
  "**Tabela 1. Exclusões de periódicos aplicadas ao CSV canônico**",
  "",
  markdown_table(exclusion_table),
  "",
  "*Nota:* contagens zero indicam que a regra foi verificada, mas o periódico já não estava no CSV canônico de partida.",
  "",
  "**Tabela 2. Classificação binária inferida do primeiro prenome**",
  "",
  markdown_table(first_author_table),
  "",
  "*Nota:* a proporção usa todos os artigos da base analítica. `Não classificado` inclui autoria ausente, prenomes não encontrados e probabilidades que não ultrapassam o limiar de 90%.",
  "",
  "**Tabela 3. Composição das classificações de prenomes na equipe de autoria**",
  "",
  markdown_table(team_table),
  "",
  "*Nota:* uma equipe é `Indeterminada` quando ao menos um autor não pôde ser classificado. A regra evita atribuir composição exclusivamente feminina ou masculina com informação incompleta.",
  "",
  "![Classificação do primeiro prenome por período](../output/figures/gender_analysis/figure_1_first_author_gender_by_period.png)",
  "",
  "*Figura 1. Classificação binária inferida do primeiro prenome por período de publicação.*",
  "",
  "## Indicadores metodológicos por classificação do primeiro prenome",
  "",
  "**Tabela 4. Indicadores metodológicos segundo a classificação do primeiro prenome**",
  "",
  markdown_table(metric_table),
  "",
  "*Nota:* cada célula apresenta numerador/denominador. Os denominadores são: todos os artigos para artigos empíricos; artigos empíricos com classificação observada para análise quantitativa e linguagem causal/explicativa; artigos quantitativos com inferência observada para inferência estatística; todos os artigos com screen observado para exame de identificação; e artigos examinados para identificação para estratégia explícita. Prenomes não classificados não entram no contraste feminino–masculino.",
  "",
  "![Indicadores metodológicos por classificação do primeiro prenome](../output/figures/gender_analysis/figure_2_methodological_indicators_by_first_author_gender.png)",
  "",
  "*Figura 2. Indicadores metodológicos segundo a classificação binária inferida do primeiro prenome.*",
  "",
  "**Tabela 5. Comparação padronizada por periódico e período**",
  "",
  markdown_table(standardized_table),
  "",
  "*Nota:* em cada indicador, as taxas específicas por periódico × período são ponderadas pela distribuição conjunta dos denominadores nas duas categorias, usando somente estratos com suporte em ambas. A padronização reduz diferenças de composição nesses dois eixos, mas não controla subcampo, idioma, tamanho da equipe ou outros confundidores.",
  "",
  "**Tabela 6. Tipo de evidência entre artigos empíricos, por classificação do primeiro prenome**",
  "",
  markdown_table(evidence_table),
  "",
  "*Nota:* o denominador é o total de artigos empíricos em cada categoria do primeiro prenome.",
  "",
  "## Análise exploratória da composição da equipe",
  "",
  "**Tabela 7. Indicadores metodológicos segundo a composição das classificações de prenomes na equipe**",
  "",
  markdown_table(team_metric_table),
  "",
  "*Nota:* cada célula apresenta n/N e a proporção. A composição da equipe é confundida pelo número de autores — equipes com duas categorias são necessariamente coautoradas — e não constitui teste de robustez do contraste de primeira autoria.",
  "",
  "## Evolução temporal",
  "",
  "**Tabela 8. Categoria feminina do primeiro prenome por período**",
  "",
  markdown_table(period_table),
  "",
  "*Nota:* a proporção usa somente primeiros prenomes classificados nas categorias feminina ou masculina no período; os não classificados são apresentados separadamente.",
  "",
  "## Cobertura e sensibilidade da classificação",
  "",
  "**Tabela 9. Motivo da classificação ou não classificação do primeiro prenome**",
  "",
  markdown_table(failure_table),
  "",
  "*Nota:* `Prenome não encontrado` corresponde a probabilidade ausente no `genderBR`; `Ambíguo no limiar` tem probabilidade válida entre 10% e 90%.",
  "",
  "**Tabela 10. Cobertura da classificação binária por periódico**",
  "",
  markdown_table(coverage_journal_table),
  "",
  paste0(
    "A cobertura também varia por idioma: ", fmt_pct(english_coverage_row$coverage_percent),
    " nos artigos em inglês e ", fmt_pct(portuguese_coverage_row$coverage_percent),
    " nos artigos em português. Essa não classificação diferencial impede tratar os casos classificados como aleatórios."
  ),
  "",
  "**Tabela 11. Sensibilidade ao limiar de classificação**",
  "",
  markdown_table(sensitivity_table),
  "",
  "*Nota:* o limiar de 90% é o padrão do pacote. Os limiares de 80% e 95% alteram a cobertura, mas permitem verificar se os contrastes principais dependem dessa escolha.",
  "",
  "## Método e limites",
  "",
  paste0(
    "Os nomes foram extraídos do manifest canônico e separados por `;`. O `genderBR` ",
    as.character(utils::packageVersion("genderBR")),
    " aplicou `get_gender(..., prob = TRUE, internal = TRUE, year = 2022)` aos nomes completos e usa o primeiro prenome. ",
    "A categoria feminina exige probabilidade maior que ", fmt_pct(100 * gender_threshold, 0),
    "; a masculina, probabilidade menor que ", fmt_pct(100 * (1 - gender_threshold), 0),
    "; os demais casos ficam não classificados."
  ),
  "",
  "A proxy deriva da distribuição de prenomes registrada por sexo no IBGE. Ela não observa a identidade de gênero de cada pessoa, não representa identidades não binárias e tem cobertura menor para nomes estrangeiros, raros, coletivos ou ambíguos. A posição de primeira autoria também não mede contribuição relativa e pode refletir ordem alfabética.",
  "",
  "Documentação consultada em 2026-07-19: [manual oficial do pacote genderBR no CRAN](https://cran.r-project.org/web/packages/genderBR/refman/genderBR.html) e [nota técnica Nomes no Brasil do Censo 2022/IBGE](https://biblioteca.ibge.gov.br/index.php/biblioteca-catalogo?id=2102228&view=detalhes).",
  "",
  "## Reprodutibilidade e validação",
  "",
  "- Script gerador: `scripts/51_analyze_gender_current_canonical.R`.",
  paste0("- CSV canônico: `", sub(paste0(project_dir, "/"), "", classifications_path, fixed = TRUE), "`."),
  paste0("- MD5 e modificação do CSV canônico: `", canonical_md5, "`; `", canonical_mtime, "`."),
  paste0("- Manifest: `", sub(paste0(project_dir, "/"), "", manifest_path, fixed = TRUE), "`."),
  paste0("- MD5 e modificação do manifest: `", manifest_md5, "`; `", manifest_mtime, "`."),
  paste0("- R: `", R.version.string, "`."),
  paste0("- Pacotes: `", package_versions, "`."),
  "",
  "**Tabela 12. Validações automáticas**",
  "",
  markdown_table(validation_table),
  "",
  "*Nota:* todos os artefatos derivados são recriados pelo script acima."
)

write_utf8_lines(report_lines, report_path)

message("Análise de gênero concluída.")
message("Artigos canônicos: ", n_canonical)
message("Artigos após exclusões: ", n_analytic)
message("Cobertura binária da primeira autoria: ", round(coverage_binary, 1), "%")
message("Relatório: ", report_path)
