suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
})

project_root <- "/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP"
input_path <- file.path(project_root, "tmp/grading_work/final_grade_records.csv")
output_dir <- file.path(
  project_root,
  "outputs/01a02455-4428-7e10-b65c-4328cbb55411"
)
figure_path <- file.path(output_dir, "histograma_notas_trabalho_final.png")
selection_path <- file.path(project_root, "tmp/grading_work/selected_pdfs.csv")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

grades <- readr::read_csv(input_path, show_col_types = FALSE) |>
  dplyr::select(Nome, Email, NUSP, Trabalho_final, Situacao, Fonte_entrega)

stopifnot(
  nrow(grades) == 74L,
  !anyDuplicated(grades$NUSP),
  !anyNA(grades$Trabalho_final),
  all(dplyr::between(grades$Trabalho_final, 0, 10)),
  sum(grades$Situacao == "Sem envio localizado") == 17L
)

submitted <- grades |>
  dplyr::filter(Situacao != "Sem envio localizado")

submitted_median <- stats::median(submitted$Trabalho_final)
submitted_mean <- mean(submitted$Trabalho_final)

top_three <- submitted |>
  dplyr::arrange(dplyr::desc(Trabalho_final), Nome) |>
  dplyr::slice_head(n = 3L) |>
  dplyr::mutate(Grupo = "Melhores")

median_three <- submitted |>
  dplyr::mutate(distancia_mediana = abs(Trabalho_final - submitted_median)) |>
  dplyr::arrange(distancia_mediana, Nome) |>
  dplyr::slice_head(n = 3L) |>
  dplyr::select(-distancia_mediana) |>
  dplyr::mutate(Grupo = "Próximas da mediana")

bottom_three <- submitted |>
  dplyr::arrange(Trabalho_final, Nome) |>
  dplyr::slice_head(n = 3L) |>
  dplyr::mutate(Grupo = "Piores entre os entregues")

selected <- dplyr::bind_rows(top_three, median_three, bottom_three) |>
  dplyr::select(Grupo, Nome, NUSP, Trabalho_final, Fonte_entrega, Email)

readr::write_csv(selected, selection_path)

all_mean <- mean(grades$Trabalho_final)
all_median <- stats::median(grades$Trabalho_final)

plot_histogram <- ggplot2::ggplot(grades, ggplot2::aes(x = Trabalho_final)) +
  ggplot2::geom_histogram(
    binwidth = 1,
    boundary = 0,
    closed = "left",
    fill = "#0F766E",
    color = "white",
    linewidth = 0.7
  ) +
  ggplot2::stat_bin(
    binwidth = 1,
    boundary = 0,
    closed = "left",
    geom = "text",
    ggplot2::aes(label = ggplot2::after_stat(count)),
    vjust = -0.45,
    color = "#17324D",
    fontface = "bold",
    size = 3.6
  ) +
  ggplot2::geom_vline(
    xintercept = all_mean,
    color = "#D6A84B",
    linewidth = 1,
    linetype = "longdash"
  ) +
  ggplot2::annotate(
    "text",
    x = all_mean + 0.12,
    y = Inf,
    label = sprintf("Média = %.2f", all_mean),
    hjust = 0,
    vjust = 1.5,
    color = "#8A6418",
    fontface = "bold",
    size = 3.8
  ) +
  ggplot2::scale_x_continuous(
    breaks = 0:10,
    limits = c(0, 10),
    expand = ggplot2::expansion(mult = c(0.01, 0.02))
  ) +
  ggplot2::scale_y_continuous(
    breaks = scales::breaks_width(5),
    expand = ggplot2::expansion(mult = c(0, 0.12))
  ) +
  ggplot2::labs(
    title = "Figura 1. Distribuição das notas do trabalho final",
    subtitle = "Concentração entre 8 e 10; os 17 zeros correspondem a ausências de entrega",
    x = "Nota do trabalho final (0–10)",
    y = "Número de estudantes",
    caption = paste0(
      "Fonte: correção dos trabalhos de Métodos III, 21/08/2026.\n",
      "N = 74 estudantes; 57 entregas e 17 ausências. ",
      "Média geral = ", sprintf("%.2f", all_mean),
      "; mediana geral = ", sprintf("%.2f", all_median),
      "; média entre os entregues = ", sprintf("%.2f", submitted_mean), "."
    )
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold", color = "#17324D", size = 15),
    plot.subtitle = ggplot2::element_text(color = "#4D5B68", size = 11),
    plot.caption = ggplot2::element_text(color = "#5B6773", hjust = 0, size = 9),
    axis.title = ggplot2::element_text(face = "bold", color = "#273746"),
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_line(color = "#DCE4EA", linewidth = 0.4),
    plot.margin = ggplot2::margin(12, 18, 12, 12)
  )

ggplot2::ggsave(
  filename = figure_path,
  plot = plot_histogram,
  width = 8,
  height = 5.6,
  units = "in",
  dpi = 150,
  bg = "white"
)

summary_payload <- list(
  figure_path = figure_path,
  selection_path = selection_path,
  submitted_median = submitted_median,
  submitted_mean = submitted_mean,
  all_mean = all_mean,
  all_median = all_median,
  selected = selected
)

dput(summary_payload)
