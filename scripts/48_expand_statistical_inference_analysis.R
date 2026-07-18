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

analysis_df <- readr::read_csv(analysis_path, show_col_types = FALSE)
complete_profile <- readr::read_csv(complete_profile_path, show_col_types = FALSE)
complete_journals <- complete_profile$journal_title

required_columns <- c(
  "pid",
  "journal_title",
  "year",
  "period_3",
  "is_empirical_quant_paper_torreblanca",
  "quantitative_analysis_type",
  "has_statistical_inference"
)
missing_columns <- setdiff(required_columns, names(analysis_df))
if (length(missing_columns) > 0) {
  stop("Colunas ausentes na base analítica: ", paste(missing_columns, collapse = "; "))
}

if (dplyr::n_distinct(analysis_df$pid) != nrow(analysis_df)) {
  stop("A base analítica contém PIDs duplicados.")
}
if (length(complete_journals) != 6) {
  stop("O estrato completo deveria conter seis periódicos.")
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
    quantitative_n = dplyr::n(),
    inference_n = sum(has_statistical_inference %in% TRUE),
    inference_percent = fmt_pct(inference_n, quantitative_n),
    .groups = "drop"
  ) |>
    dplyr::mutate(scope = scope_label) |>
    dplyr::select(scope, quantitative_type, quantitative_n, inference_n, inference_percent)
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

tex_lines <- readLines(torreblanca_tex_path, encoding = "UTF-8", warn = FALSE)
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
    panel = "Inferência estatística\n(periódicos brasileiros)",
    label = dplyr::recode(scope, !!!journal_abbreviations, .default = scope),
    percent = inference_percent,
    value_label = paste0(inference_n, "/", inference_observed_n, " (", sprintf("%.1f", inference_percent), "%)")
  )

international_plot_data <- top_three |>
  dplyr::transmute(
    panel = "Desenho causal\n(Torreblanca et al.)",
    label = dplyr::recode(journal, !!!journal_abbreviations, .default = journal),
    percent = design_based_percent,
    value_label = paste0(sprintf("%.1f", design_based_percent), "% (N=", n_explanatory_quantitative, ")")
  )

plot_data <- dplyr::bind_rows(brazil_plot_data, international_plot_data) |>
  dplyr::mutate(
    panel = factor(
      panel,
      levels = c(
        "Inferência estatística\n(periódicos brasileiros)",
        "Desenho causal\n(Torreblanca et al.)"
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

figure_inference_benchmark <- plot_data |>
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
    limits = c(0, 78),
    breaks = seq(0, 70, 10),
    labels = function(x) paste0(x, "%")
  ) +
  ggplot2::labs(x = "Artigos (%)", y = NULL) +
  theme_paper()

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

ggplot2::ggsave(
  file.path(figures_dir, "figure_statistical_inference_benchmark.pdf"),
  figure_inference_benchmark,
  width = 7,
  height = 4.4,
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
