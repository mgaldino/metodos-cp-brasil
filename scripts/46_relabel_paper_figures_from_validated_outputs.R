#!/usr/bin/env Rscript

# Regenera figuras com ajustes editoriais a partir das tabelas
# validadas produzidas pela atualização corrente do paper. O script não lê nem
# altera o corpus canônico e não recalcula classificações ou denominadores.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(tidyr)
})

tables_dir <- file.path("output", "tables", "paper")
figures_dir <- file.path("output", "figures", "paper")

input_paths <- c(
  denominators = file.path(tables_dir, "denominator_summary.csv"),
  complete_journals = file.path(tables_dir, "table_4_complete_journal_profile.csv"),
  periods = file.path(tables_dir, "period_equal_weight_profile.csv"),
  years = file.path(tables_dir, "year_article_weight_profile.csv"),
  coverage = file.path(tables_dir, "coverage_by_journal.csv")
)

stopifnot(all(file.exists(input_paths)))

expected_md5 <- c(
  denominators = "d88f1700b4245c5c186e7e763f8f4d34",
  complete_journals = "2e0a97210b0ed1604f0f82cd38de65a1",
  periods = "a1cfbb7d34c7ff2eef451b780def8e36",
  years = "378190a17a4ccfb2f2e7984e023cfa00",
  coverage = "8fc47d6b626cd3510c341bbd8818c6be"
)

actual_md5 <- unname(tools::md5sum(unname(input_paths)))
names(actual_md5) <- names(input_paths)
stopifnot(identical(actual_md5, expected_md5))

denominators <- readr::read_csv(input_paths[["denominators"]], show_col_types = FALSE)
complete_journals <- readr::read_csv(input_paths[["complete_journals"]], show_col_types = FALSE)
periods <- readr::read_csv(input_paths[["periods"]], show_col_types = FALSE)
years <- readr::read_csv(input_paths[["years"]], show_col_types = FALSE)
coverage <- readr::read_csv(input_paths[["coverage"]], show_col_types = FALSE)

denominator_n <- function(label) {
  value <- denominators$n[denominators$denominator == label]
  stopifnot(length(value) == 1L, !is.na(value))
  value
}

n_manifest <- denominator_n("Corpus completo elegível")
n_classified <- denominator_n("Artigos classificados por leitura integral")
n_empirical <- denominator_n("Artigos empíricos classificados")
n_quantitative <- denominator_n("Artigos empíricos quantitativos classificados")
n_claim <- denominator_n("Artigos com afirmação causal ou explicativa classificados")
n_examined <- denominator_n("Artigos em que a identificação é especialmente relevante")
n_strict <- denominator_n("Artigos com estratégia explícita de identificação causal")
n_complete_journals <- denominator_n("Periódicos com classificação completa")
n_complete_articles <- denominator_n("Artigos dos periódicos completos")
n_temporal_journals <- unique(periods$journals_n)

stopifnot(
  n_manifest > 0,
  n_classified <= n_manifest,
  n_empirical <= n_classified,
  n_quantitative <= n_empirical,
  n_examined <= n_classified,
  n_strict <= n_examined,
  nrow(complete_journals) == n_complete_journals,
  sum(complete_journals$n_articles) == n_complete_articles,
  length(n_temporal_journals) == 1L,
  all(years$journals_n == n_temporal_journals),
  nrow(coverage) == 11L
)

fmt_n <- function(x) {
  format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE)
}

fmt_pct <- function(n, denominator) {
  ifelse(denominator > 0, round(100 * n / denominator, 1), NA_real_)
}

fmt_pct_label <- function(x) {
  ifelse(
    is.na(x),
    "-",
    paste0(format(x, decimal.mark = ",", nsmall = 1, trim = TRUE), "%")
  )
}

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

metric_labels <- c(
  empirical = "Artigos empíricos",
  quantitative = "Componente quantitativo",
  inference = "Inferência estatística",
  claim = "Linguagem explicativa ampla",
  screen = "Exame de identificação",
  strict = "Estratégia explícita"
)

figure_1_data <- tibble::tibble(
  group = c("Cobertura", "Cobertura", "Evidência", "Quantificação", "Afirmações", "Identificação", "Identificação"),
  measure = c(
    "Corpus elegível",
    "Classificados",
    "Empíricos",
    "Componente quantitativo",
    "Afirmação causal/explicativa",
    "Artigos examinados para identificação",
    "Estratégia explícita de identificação"
  ),
  n = c(n_manifest, n_classified, n_empirical, n_quantitative, n_claim, n_examined, n_strict),
  denominator_n = c(n_manifest, n_manifest, n_classified, n_empirical, n_classified, n_classified, n_examined)
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
    subtitle = NULL,
    x = "Percentual",
    y = NULL,
    color = NULL,
    caption = "Fonte: classificação por leitura integral. Corpus completo ainda parcialmente classificado."
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

complete_journals_long <- complete_journals |>
  dplyr::select(
    journal_title,
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
    metric_label = factor(unname(metric_labels[metric]), levels = unname(metric_labels)),
    journal_title = stringr::str_wrap(journal_title, 24)
  )

figure_2 <- complete_journals_long |>
  ggplot2::ggplot(ggplot2::aes(x = metric_label, y = journal_title)) +
  ggplot2::geom_tile(fill = "#F2F5F8", color = "white", linewidth = 0.6) +
  ggplot2::geom_text(ggplot2::aes(label = fmt_pct_label(percent)), color = "#173B4F", size = 3) +
  ggplot2::labs(
    title = "Perfil metodológico dos periódicos com classificação completa",
    subtitle = paste0(
      fmt_n(n_complete_journals),
      " periódicos, ",
      fmt_n(n_complete_articles),
      " artigos; o denominador varia por dimensão."
    ),
    x = NULL,
    y = NULL
  ) +
  theme_paper() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
    panel.grid = ggplot2::element_blank(),
    legend.position = "none"
  )

ggplot2::ggsave(
  file.path(figures_dir, "figure_2_journal_dimension_matrix.pdf"),
  figure_2,
  width = 7,
  height = 4.8,
  units = "in",
  device = grDevices::pdf
)

period_plot_data <- periods |>
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
    period_3 = factor(period_3, levels = c("2005-2011", "2012-2018", "2019-2025"))
  )

figure_3 <- period_plot_data |>
  ggplot2::ggplot(ggplot2::aes(x = period_3, y = percent, group = 1)) +
  ggplot2::geom_line(color = "#2F6B8A", linewidth = 0.8) +
  ggplot2::geom_point(color = "#2F6B8A", size = 2.2) +
  ggplot2::geom_text(
    ggplot2::aes(label = fmt_pct_label(percent), vjust = ifelse(percent >= 90, 1.5, -0.8)),
    size = 2.8
  ) +
  ggplot2::facet_wrap(~ metric_label, ncol = 3, scales = "fixed") +
  ggplot2::scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 25),
    labels = function(x) paste0(x, "%"),
    expand = ggplot2::expansion(mult = c(0, 0.05))
  ) +
  ggplot2::labs(
    title = "Variação por período em periódicos completos presentes nos três períodos",
    subtitle = paste0(
      "Média simples de ",
      fmt_n(n_temporal_journals),
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

coverage_plot_data <- coverage |>
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
    subtitle = "Os rótulos mostram artigos classificados sobre artigos elegíveis após as exclusões documentadas.",
    x = "Cobertura",
    y = NULL,
    color = "Status",
    caption = paste0(
      fmt_n(n_complete_journals),
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

year_plot_data <- years |>
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

year_axis_breaks <- sort(unique(c(seq(min(years$year), max(years$year), by = 3), max(years$year))))

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
      fmt_n(n_temporal_journals),
      " periódicos; ",
      min(years$year),
      " a ",
      max(years$year),
      "."
    ),
    x = "Ano",
    y = "Percentual",
    caption = paste0(
      "Apenas anos com artigos nos ",
      fmt_n(n_temporal_journals),
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

message("Figuras editoriais regeneradas a partir dos outputs validados: 1, 2, 3, 4 e 7.")
