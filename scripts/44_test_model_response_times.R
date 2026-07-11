#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
})

project_dir <- normalizePath(".", mustWork = TRUE)
original_path <- file.path(
  project_dir, "data/processed/credibility_prompt_v3_integral_reading/full_corpus_ab",
  "gpt56_model_benchmark_10", "benchmark_timings.csv"
)
luna_path <- file.path(
  project_dir, "data/processed/credibility_prompt_v3_integral_reading/full_corpus_ab",
  "gpt56_model_benchmark_10_luna_xhigh_v2", "benchmark_timings.csv"
)
out_path <- file.path(project_dir, "quality_reports/credibility_model_response_time_test.md")

read_success <- function(path, labels) {
  readr::read_csv(path, show_col_types = FALSE) |>
    dplyr::filter(status == "complete", return_code == 0L, label %in% labels) |>
    dplyr::mutate(elapsed_seconds = as.numeric(elapsed_seconds)) |>
    dplyr::group_by(label, pid) |>
    dplyr::slice_max(elapsed_seconds, n = 1, with_ties = FALSE) |>
    dplyr::ungroup()
}

times <- dplyr::bind_rows(
  read_success(original_path, c("sol_medium", "terra_medium", "terra_xhigh")),
  read_success(luna_path, "luna_xhigh")
) |>
  dplyr::mutate(
    model = factor(
      label,
      levels = c("sol_medium", "terra_medium", "terra_xhigh", "luna_xhigh"),
      labels = c("Sol medium", "Terra medium", "Terra xhigh", "Luna xhigh")
    ),
    pid = factor(pid)
  )

expected <- tidyr::crossing(
  pid = unique(times$pid),
  model = levels(times$model)
)
if (nrow(times) != 40 || !all(expected$pid %in% times$pid) || anyDuplicated(times |> dplyr::select(pid, model))) {
  stop("O teste requer exatamente uma resposta efetiva por modelo em cada um dos 10 PIDs.")
}

means <- times |>
  dplyr::group_by(model) |>
  dplyr::summarise(
    n = dplyr::n(),
    mean_seconds = mean(elapsed_seconds),
    median_seconds = median(elapsed_seconds),
    sd_seconds = sd(elapsed_seconds),
    .groups = "drop"
  )

repeated_anova <- summary(aov(elapsed_seconds ~ model + pid, data = times))[[1]]
anova_row <- repeated_anova["model", , drop = FALSE]
anova_p <- anova_row[["Pr(>F)"]]
friedman <- friedman.test(elapsed_seconds ~ model | pid, data = times)

lines <- c(
  "# Teste de igualdade dos tempos de resposta",
  "",
  sprintf("Gerado em: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "Foi usada uma resposta efetiva bem-sucedida por PID e modelo. Falhas, retries e execuções `SKIP` foram excluídos; quando havia mais de uma execução bem-sucedida para o mesmo PID, foi mantida a de maior duração, correspondente à chamada efetiva e não ao checkpoint instantâneo.",
  "",
  "## Tempos médios",
  "",
  "modelo | n | média (s) | mediana (s) | desvio-padrão (s)",
  "--- | ---: | ---: | ---: | ---:",
  sprintf(
    "%s | %d | %.2f | %.2f | %.2f",
    means$model, means$n, means$mean_seconds, means$median_seconds, means$sd_seconds
  ),
  "",
  "## Testes",
  "",
  "A hipótese nula é que os quatro modelos têm o mesmo tempo médio de resposta. Como os mesmos 10 PIDs foram usados em todos os modelos, o teste principal é uma ANOVA de medidas repetidas com PID como bloco.",
  "",
  sprintf("- ANOVA de medidas repetidas: F = %.3f; p-valor = %.6f.", anova_row[["F value"]], anova_p),
  sprintf("- Friedman: chi-quadrado = %.3f; p-valor = %.6f.", unname(friedman$statistic), friedman$p.value),
  "",
  "O p-valor não mede diferença de qualidade classificatória; testa apenas igualdade dos tempos entre os modelos nestes 10 casos.",
  ""
)

writeLines(lines, out_path, useBytes = TRUE)
message("Relatório escrito em: ", out_path)
