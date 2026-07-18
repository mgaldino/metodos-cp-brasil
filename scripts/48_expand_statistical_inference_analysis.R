#!/usr/bin/env Rscript

## Amplia a análise de inferência estatística e constrói um benchmark
## reproduzível com a tabela de periódicos de Torreblanca et al. (2026).

options(scipen = 999, encoding = "UTF-8")

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
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

analysis_path <- path("data/processed/paper_analysis/paper_analysis_dataset_current.csv")
complete_profile_path <- path("output/tables/paper/table_4_complete_journal_profile.csv")
torreblanca_tex_path <- path("data/raw/torreblanca_2026/source_v2/main.tex")
analysis_dir <- path("data/processed/paper_analysis")
tables_dir <- path("output/tables/paper")
figures_dir <- path("output/figures/paper")

required_files <- c(analysis_path, complete_profile_path, torreblanca_tex_path)
if (!all(file.exists(required_files))) {
  stop("Arquivos ausentes: ", paste(required_files[!file.exists(required_files)], collapse = "; "))
}

dir.create(analysis_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

fmt_pct <- function(n, denominator) {
  ifelse(denominator > 0, round(100 * n / denominator, 1), NA_real_)
}

format_percent_label <- function(x) {
  stringr::str_replace(sprintf("%.1f", x), stringr::fixed("."), ",")
}

format_count_label <- function(x) {
  format(
    x,
    big.mark = ".",
    decimal.mark = ",",
    scientific = FALSE
  )
}

analysis_df <- readr::read_csv(analysis_path, show_col_types = FALSE)
complete_profile <- readr::read_csv(complete_profile_path, show_col_types = FALSE)
complete_journals <- complete_profile$journal_title
expected_complete_journals <- c(
  "Brazilian Political Science Review",
  "Cadernos Gestão Pública e Cidadania",
  "Contexto Internacional",
  "Dados",
  "Opinião Pública",
  "Revista Brasileira de Ciência Política"
)
excluded_journals <- c(
  "Brazilian Journal of Political Economy",
  "Civitas - Revista de Ciências Sociais"
)

required_columns <- c(
  "pid",
  "journal_title",
  "year",
  "period_3",
  "is_empirical_quant_paper_torreblanca",
  "quantitative_analysis_type",
  "has_statistical_inference",
  "causal_or_explanatory_claim_present"
)
missing_columns <- setdiff(required_columns, names(analysis_df))
if (length(missing_columns) > 0) {
  stop("Colunas ausentes na base analítica: ", paste(missing_columns, collapse = "; "))
}

if (dplyr::n_distinct(analysis_df$pid) != nrow(analysis_df)) {
  stop("A base analítica contém PIDs duplicados.")
}
if (!setequal(complete_journals, expected_complete_journals)) {
  stop("A lista dos seis periódicos completos diverge do escopo esperado.")
}
if (any(analysis_df$journal_title %in% excluded_journals)) {
  stop("A base analítica contém periódico excluído da análise substantiva.")
}

quantitative_df <- analysis_df |>
  dplyr::filter(is_empirical_quant_paper_torreblanca %in% TRUE)

inference_summary <- function(data, scope, scope_type) {
  observed <- sum(!is.na(data$has_statistical_inference))
  positive <- sum(data$has_statistical_inference %in% TRUE)
  tibble::tibble(
    scope_type = scope_type,
    scope = scope,
    quantitative_n = nrow(data),
    inference_observed_n = observed,
    inference_missing_n = sum(is.na(data$has_statistical_inference)),
    inference_n = positive,
    inference_percent = fmt_pct(positive, observed)
  )
}

inference_by_scope <- dplyr::bind_rows(
  inference_summary(quantitative_df, "Cobertura classificada", "Agregado"),
  inference_summary(
    quantitative_df |> dplyr::filter(journal_title %in% complete_journals),
    "Seis periódicos integralmente classificados",
    "Agregado"
  ),
  lapply(complete_journals, function(journal) {
    inference_summary(
      quantitative_df |> dplyr::filter(journal_title == journal),
      journal,
      "Periódico completo"
    )
  }) |>
    dplyr::bind_rows()
)

quantitative_type_labels <- c(
  descriptive_statistics_only = "Estatística descritiva",
  bivariate_tests_or_correlations_only = "Testes bivariados ou correlações",
  statistical_modeling = "Modelagem estatística",
  unclear = "Classificação quantitativa incerta"
)

summarise_inference_by_type <- function(data, scope_label) {
  data |>
    dplyr::mutate(
    quantitative_type = dplyr::recode(
      quantitative_analysis_type,
      !!!quantitative_type_labels,
      .default = quantitative_analysis_type
    )
  ) |>
  dplyr::filter(!is.na(has_statistical_inference)) |>
    dplyr::group_by(quantitative_type) |>
  dplyr::summarise(
    inference_observed_n = dplyr::n(),
    inference_n = sum(has_statistical_inference %in% TRUE),
    inference_percent = fmt_pct(inference_n, inference_observed_n),
    .groups = "drop"
  ) |>
    dplyr::mutate(scope = scope_label) |>
    dplyr::select(scope, quantitative_type, inference_observed_n, inference_n, inference_percent)
}

inference_by_quantitative_type <- dplyr::bind_rows(
  summarise_inference_by_type(quantitative_df, "Cobertura classificada"),
  summarise_inference_by_type(
    quantitative_df |> dplyr::filter(journal_title %in% complete_journals),
    "Seis periódicos integralmente classificados"
  )
)

temporal_complete_journals <- analysis_df |>
  dplyr::filter(journal_title %in% complete_journals) |>
  dplyr::distinct(journal_title, period_3) |>
  dplyr::count(journal_title, name = "periods_n") |>
  dplyr::filter(periods_n == 3) |>
  dplyr::pull(journal_title)

if (length(temporal_complete_journals) != 5) {
  stop("O suporte temporal comum deveria conter cinco periódicos completos.")
}

inference_by_period_complete <- quantitative_df |>
  dplyr::filter(journal_title %in% temporal_complete_journals, !is.na(has_statistical_inference)) |>
  dplyr::group_by(period_3) |>
  dplyr::summarise(
    journals_n = dplyr::n_distinct(journal_title),
    quantitative_n = dplyr::n(),
    inference_n = sum(has_statistical_inference %in% TRUE),
    inference_percent = fmt_pct(inference_n, quantitative_n),
    .groups = "drop"
  ) |>
  dplyr::arrange(factor(period_3, levels = c("2005-2011", "2012-2018", "2019-2025")))

tex_lines <- readr::read_lines(
  torreblanca_tex_path,
  locale = readr::locale(encoding = "UTF-8"),
  progress = FALSE
)
table_start <- grep("^Quarterly Journal of Political Science &", tex_lines)
if (length(table_start) != 1) {
  stop("Não foi possível localizar o início da tabela de top 20 no TeX de Torreblanca et al.")
}
table_end_candidates <- which(seq_along(tex_lines) > table_start & stringr::str_detect(tex_lines, fixed("\\bottomrule")))
if (length(table_end_candidates) == 0) {
  stop("Não foi possível localizar o fim da tabela de top 20 no TeX de Torreblanca et al.")
}
table_end <- min(table_end_candidates)
top20_lines <- tex_lines[table_start:(table_end - 1)]

top20_design_based <- stringr::str_split_fixed(top20_lines, " & ", 7) |>
  as.data.frame(stringsAsFactors = FALSE) |>
  tibble::as_tibble() |>
  rlang::set_names(c(
    "journal",
    "sjr_rank",
    "n_explanatory_quantitative",
    "design_based_percent",
    "design_based_se",
    "design_based_excluding_survey_percent",
    "design_based_excluding_survey_se"
  )) |>
  dplyr::mutate(
    dplyr::across(dplyr::everything(), stringr::str_trim),
    design_based_excluding_survey_se = stringr::str_remove(
      design_based_excluding_survey_se,
      stringr::fixed(" \\\\")
    ),
    sjr_rank = as.integer(sjr_rank),
    n_explanatory_quantitative = readr::parse_number(n_explanatory_quantitative),
    design_based_percent = as.numeric(design_based_percent),
    design_based_se = readr::parse_number(design_based_se),
    design_based_excluding_survey_percent = as.numeric(design_based_excluding_survey_percent),
    design_based_excluding_survey_se = readr::parse_number(design_based_excluding_survey_se),
    source = "Torreblanca et al. (2026), Supplementary Table: Design-based share by journal"
  )

if (nrow(top20_design_based) != 20 || anyNA(top20_design_based$design_based_percent)) {
  stop("A extração da tabela de top 20 não produziu 20 linhas válidas.")
}
if (any(top20_design_based$design_based_percent < 0 | top20_design_based$design_based_percent > 100)) {
  stop("Percentuais inválidos na tabela de Torreblanca et al.")
}

top_three_names <- c(
  "American Political Science Review",
  "American Journal of Political Science",
  "Journal of Politics"
)
top_three <- top20_design_based |>
  dplyr::filter(journal %in% top_three_names)
if (nrow(top_three) != 3) {
  stop("A tabela extraída não contém APSR, AJPS e Journal of Politics.")
}

top_three_weighted_percent <- stats::weighted.mean(
  top_three$design_based_percent,
  w = top_three$n_explanatory_quantitative
)
complete_aggregate <- inference_by_scope |>
  dplyr::filter(scope == "Seis periódicos integralmente classificados")

benchmark_summary <- dplyr::bind_rows(
  tibble::tibble(
    source_group = "Brasil",
    publication = "Seis periódicos integralmente classificados",
    measure = "Inferência estatística",
    denominator_definition = "Artigos empíricos quantitativos com rótulo de inferência observado",
    denominator_n = complete_aggregate$inference_observed_n,
    percent = complete_aggregate$inference_percent
  ),
  top_three |>
    dplyr::transmute(
      source_group = "Torreblanca et al. (2026)",
      publication = journal,
      measure = "Desenho causal (design-based)",
      denominator_definition = "Artigos empíricos quantitativos explicativos",
      denominator_n = n_explanatory_quantitative,
      percent = design_based_percent
    ),
  tibble::tibble(
    source_group = "Torreblanca et al. (2026)",
    publication = "Média ponderada: APSR, AJPS e Journal of Politics",
    measure = "Desenho causal (design-based)",
    denominator_definition = "Artigos empíricos quantitativos explicativos",
    denominator_n = sum(top_three$n_explanatory_quantitative),
    percent = round(top_three_weighted_percent, 1)
  )
) |>
  dplyr::mutate(
    difference_from_brazil_pp = round(percent - complete_aggregate$inference_percent, 1)
  )

complete_quantitative_observed <- quantitative_df |>
  dplyr::filter(journal_title %in% complete_journals, !is.na(has_statistical_inference))

complete_claim_inference_observed <- complete_quantitative_observed |>
  dplyr::filter(!is.na(causal_or_explanatory_claim_present))

inference_claim_cross <- complete_claim_inference_observed |>
  dplyr::mutate(
    causal_language = dplyr::if_else(
      causal_or_explanatory_claim_present,
      "Com linguagem causal ou explicativa",
      "Sem linguagem causal ou explicativa"
    ),
    inference_status = dplyr::if_else(
      has_statistical_inference,
      "Com inferência estatística",
      "Sem inferência estatística"
    )
  ) |>
  dplyr::count(causal_language, inference_status, name = "n") |>
  dplyr::group_by(causal_language) |>
  dplyr::mutate(
    language_denominator_n = sum(n),
    percent_within_language = fmt_pct(n, language_denominator_n),
    cross_denominator_n = nrow(complete_claim_inference_observed),
    percent_of_cross = fmt_pct(n, cross_denominator_n)
  ) |>
  dplyr::ungroup() |>
  dplyr::select(
    causal_language,
    inference_status,
    n,
    language_denominator_n,
    percent_within_language,
    cross_denominator_n,
    percent_of_cross
  )

if (
  nrow(inference_claim_cross) != 4 ||
    sum(inference_claim_cross$n) != nrow(complete_claim_inference_observed)
) {
  stop("O cruzamento entre linguagem causal e inferência não produziu quatro combinações válidas.")
}

descriptive_inference_conflicts <- complete_quantitative_observed |>
  dplyr::filter(
    quantitative_analysis_type == "descriptive_statistics_only",
    has_statistical_inference %in% TRUE
  ) |>
  dplyr::select(
    pid,
    journal_title,
    year,
    quantitative_analysis_type,
    has_statistical_inference
  )

complete_descriptive_without_inference <- complete_quantitative_observed |>
  dplyr::filter(
    quantitative_analysis_type == "descriptive_statistics_only",
    has_statistical_inference %in% FALSE
  )

complete_formal_analysis_all <- quantitative_df |>
  dplyr::filter(
    journal_title %in% complete_journals,
    quantitative_analysis_type %in% c(
      "statistical_modeling",
      "bivariate_tests_or_correlations_only"
    )
  )
complete_formal_analysis_observed <- complete_formal_analysis_all |>
  dplyr::filter(!is.na(has_statistical_inference))
complete_formal_analysis_n <- sum(
  complete_formal_analysis_observed$has_statistical_inference %in% TRUE
)

inference_key_numbers <- dplyr::bind_rows(
  tibble::tibble(
    metric = "Inferência estatística na cobertura classificada",
    n = inference_by_scope$inference_n[inference_by_scope$scope == "Cobertura classificada"],
    denominator_n = inference_by_scope$inference_observed_n[inference_by_scope$scope == "Cobertura classificada"],
    percent = inference_by_scope$inference_percent[inference_by_scope$scope == "Cobertura classificada"]
  ),
  tibble::tibble(
    metric = "Inferência estatística nos seis periódicos completos",
    n = complete_aggregate$inference_n,
    denominator_n = complete_aggregate$inference_observed_n,
    percent = complete_aggregate$inference_percent
  ),
  tibble::tibble(
    metric = "Artigos classificados como descritivos e sem inferência nos seis periódicos completos",
    n = nrow(complete_descriptive_without_inference),
    denominator_n = complete_aggregate$inference_observed_n,
    percent = fmt_pct(nrow(complete_descriptive_without_inference), complete_aggregate$inference_observed_n)
  ),
  tibble::tibble(
    metric = "Conflitos entre categoria descritiva e inferência positiva nos seis periódicos completos",
    n = nrow(descriptive_inference_conflicts),
    denominator_n = complete_aggregate$inference_observed_n,
    percent = fmt_pct(nrow(descriptive_inference_conflicts), complete_aggregate$inference_observed_n)
  ),
  tibble::tibble(
    metric = "Inferência entre testes bivariados ou modelagem com rótulo observado nos seis periódicos completos",
    n = complete_formal_analysis_n,
    denominator_n = nrow(complete_formal_analysis_observed),
    percent = fmt_pct(complete_formal_analysis_n, nrow(complete_formal_analysis_observed))
  ),
  tibble::tibble(
    metric = "Testes bivariados ou modelagem sem rótulo de inferência nos seis periódicos completos",
    n = sum(is.na(complete_formal_analysis_all$has_statistical_inference)),
    denominator_n = nrow(complete_formal_analysis_all),
    percent = fmt_pct(sum(is.na(complete_formal_analysis_all$has_statistical_inference)), nrow(complete_formal_analysis_all))
  ),
  inference_by_period_complete |>
    dplyr::transmute(
      metric = paste0("Inferência no suporte temporal comum: ", period_3),
      n = inference_n,
      denominator_n = quantitative_n,
      percent = inference_percent
    ),
  tibble::tibble(
    metric = "Desenho causal: média ponderada de APSR, AJPS e Journal of Politics",
    n = NA_real_,
    denominator_n = sum(top_three$n_explanatory_quantitative),
    percent = round(top_three_weighted_percent, 1)
  )
)

journal_abbreviations <- c(
  "Brazilian Political Science Review" = "BPSR",
  "Cadernos Gestão Pública e Cidadania" = "CGPC",
  "Contexto Internacional" = "Contexto Internacional",
  "Dados" = "Dados",
  "Opinião Pública" = "Opinião Pública",
  "Revista Brasileira de Ciência Política" = "RBCP",
  "American Political Science Review" = "APSR",
  "American Journal of Political Science" = "AJPS",
  "Journal of Politics" = "Journal of Politics"
)

brazil_plot_data <- inference_by_scope |>
  dplyr::filter(scope_type == "Periódico completo") |>
  dplyr::transmute(
    panel = "Com inferência estatística\nentre artigos quantitativos",
    label = dplyr::recode(scope, !!!journal_abbreviations, .default = scope),
    percent = inference_percent,
    value_label = paste0(
      inference_n,
      "/",
      inference_observed_n,
      " (",
      format_percent_label(inference_percent),
      "%)"
    )
  )

international_plot_data <- top_three |>
  dplyr::transmute(
    panel = "Abordagem baseada em desenho\nentre quantitativos explicativos",
    label = dplyr::recode(journal, !!!journal_abbreviations, .default = journal),
    percent = design_based_percent,
    value_label = paste0(
      format_percent_label(design_based_percent),
      "% (N = ",
      format(
        n_explanatory_quantitative,
        big.mark = ".",
        decimal.mark = ",",
        scientific = FALSE
      ),
      ")"
    )
  )

plot_data <- dplyr::bind_rows(brazil_plot_data, international_plot_data) |>
  dplyr::mutate(
    panel = factor(
      panel,
      levels = c(
        "Com inferência estatística\nentre artigos quantitativos",
        "Abordagem baseada em desenho\nentre quantitativos explicativos"
      )
    ),
    label_hjust = ifelse(percent >= 55, 1.08, -0.08),
    label = factor(
      label,
      levels = rev(c(
        "Opinião Pública", "BPSR", "Dados", "RBCP", "CGPC", "Contexto Internacional",
        "APSR", "AJPS", "Journal of Politics"
      ))
    )
  )

cross_plot_data <- inference_claim_cross |>
  dplyr::mutate(
    combination = dplyr::case_when(
      causal_language == "Com linguagem causal ou explicativa" &
        inference_status == "Com inferência estatística" ~
        "Linguagem causal ou explicativa\ncom inferência estatística",
      causal_language == "Com linguagem causal ou explicativa" &
        inference_status == "Sem inferência estatística" ~
        "Linguagem causal ou explicativa\nsem inferência estatística",
      causal_language == "Sem linguagem causal ou explicativa" &
        inference_status == "Com inferência estatística" ~
        "Sem linguagem causal ou explicativa,\ncom inferência estatística",
      TRUE ~ "Sem linguagem causal ou explicativa\ne sem inferência estatística"
    ),
    panel = "Combinações nos seis periódicos brasileiros",
    percent = percent_of_cross,
    value_label = paste0(
      format_count_label(n),
      "/",
      format_count_label(cross_denominator_n),
      " (",
      format_percent_label(percent_of_cross),
      "%)"
    ),
    label_hjust = ifelse(percent >= 50, 1.08, -0.08),
    combination = factor(
      combination,
      levels = rev(c(
        "Linguagem causal ou explicativa\ncom inferência estatística",
        "Linguagem causal ou explicativa\nsem inferência estatística",
        "Sem linguagem causal ou explicativa,\ncom inferência estatística",
        "Sem linguagem causal ou explicativa\ne sem inferência estatística"
      ))
    )
  )

theme_paper <- function() {
  ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      plot.title = ggplot2::element_blank(),
      plot.subtitle = ggplot2::element_blank(),
      plot.caption = ggplot2::element_blank(),
      legend.position = "none",
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold")
    )
}

figure_benchmark_panels <- plot_data |>
  ggplot2::ggplot(ggplot2::aes(x = percent, y = label)) +
  ggplot2::geom_segment(
    ggplot2::aes(x = 0, xend = percent, yend = label),
    color = "grey80",
    linewidth = 0.7
  ) +
  ggplot2::geom_point(color = "#2F6B8A", size = 2.8) +
  ggplot2::geom_text(
    ggplot2::aes(label = value_label, hjust = label_hjust),
    size = 2.8
  ) +
  ggplot2::facet_wrap(~ panel, ncol = 2, scales = "free_y") +
  ggplot2::scale_x_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20),
    labels = function(x) paste0(x, "%")
  ) +
  ggplot2::labs(x = "Parcela de artigos (%)", y = NULL) +
  theme_paper()

figure_claim_inference_cross <- cross_plot_data |>
  ggplot2::ggplot(ggplot2::aes(x = percent, y = combination)) +
  ggplot2::geom_segment(
    ggplot2::aes(x = 0, xend = percent, yend = combination),
    color = "grey80",
    linewidth = 0.7
  ) +
  ggplot2::geom_point(color = "#2F6B8A", size = 2.8) +
  ggplot2::geom_text(
    ggplot2::aes(label = value_label, hjust = label_hjust),
    size = 2.8
  ) +
  ggplot2::facet_wrap(~ panel, ncol = 1) +
  ggplot2::scale_x_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20),
    labels = function(x) paste0(x, "%")
  ) +
  ggplot2::labs(x = "Parcela dos artigos quantitativos (%)", y = NULL) +
  theme_paper()

figure_inference_benchmark <- patchwork::wrap_plots(
  figure_benchmark_panels,
  figure_claim_inference_cross,
  ncol = 1,
  heights = c(1.45, 1)
)

readr::write_csv(
  inference_by_scope,
  file.path(tables_dir, "statistical_inference_by_scope.csv"),
  na = ""
)
readr::write_csv(
  inference_by_quantitative_type,
  file.path(tables_dir, "statistical_inference_by_quantitative_type.csv"),
  na = ""
)
readr::write_csv(
  inference_claim_cross,
  file.path(tables_dir, "statistical_inference_by_causal_language.csv"),
  na = ""
)
readr::write_csv(
  descriptive_inference_conflicts,
  file.path(tables_dir, "statistical_inference_type_conflicts.csv"),
  na = ""
)
readr::write_csv(
  inference_by_period_complete,
  file.path(tables_dir, "statistical_inference_by_period_complete.csv"),
  na = ""
)
readr::write_csv(
  top20_design_based,
  file.path(analysis_dir, "torreblanca_top20_design_based_extracted.csv"),
  na = ""
)
readr::write_csv(
  benchmark_summary,
  file.path(tables_dir, "statistical_inference_torreblanca_benchmark.csv"),
  na = ""
)
readr::write_csv(
  inference_key_numbers,
  file.path(tables_dir, "statistical_inference_key_numbers.csv"),
  na = ""
)

ggplot2::ggsave(
  file.path(figures_dir, "figure_statistical_inference_benchmark.pdf"),
  figure_inference_benchmark,
  width = 7,
  height = 7.3,
  units = "in",
  device = grDevices::pdf
)

capture.output(sessionInfo(), file = file.path(analysis_dir, "statistical_inference_session_info.txt"))

message(
  "Inferência estatística nos seis periódicos completos: ",
  complete_aggregate$inference_n,
  "/",
  complete_aggregate$inference_observed_n,
  " (",
  sprintf("%.1f", complete_aggregate$inference_percent),
  "%). Benchmark ponderado APSR/AJPS/JOP: ",
  sprintf("%.1f", top_three_weighted_percent),
  "%."
)
