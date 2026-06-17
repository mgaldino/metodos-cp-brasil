## 33_estimate_credibility_integral_runtime.R
## Estima tempo operacional do batch integral a partir dos artefatos por PID.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default = NULL) {
  pos <- match(flag, args)
  if (is.na(pos) || pos == length(args)) {
    return(default)
  }
  args[[pos + 1]]
}

manifest_path <- get_arg(
  "--manifest",
  "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"
)
out_dir <- get_arg(
  "--out-dir",
  "data/processed/credibility_prompt_v3_integral_reading/full_corpus"
)
csv_out <- get_arg(
  "--csv-out",
  file.path(out_dir, "combined", "runtime_estimate_completed_articles.csv")
)
report_out <- get_arg(
  "--report-out",
  "quality_reports/credibility_prompt_v3_full_corpus_runtime_estimate.md"
)

required_paths <- c(manifest_path, out_dir)
missing_paths <- required_paths[!file.exists(required_paths)]
if (length(missing_paths) > 0) {
  stop("Caminhos obrigatórios ausentes: ", paste(missing_paths, collapse = ", "))
}

fmt_duration <- function(seconds) {
  if (is.na(seconds)) {
    return(NA_character_)
  }
  total_seconds <- as.numeric(round(seconds))
  days <- total_seconds %/% 86400
  rem <- total_seconds %% 86400
  hours <- rem %/% 3600
  rem <- rem %% 3600
  minutes <- rem %/% 60
  secs <- rem %% 60
  if (days > 0) {
    return(sprintf("%dd %02dh %02dm %02ds", days, hours, minutes, secs))
  }
  sprintf("%02dh %02dm %02ds", hours, minutes, secs)
}

md_table <- function(data) {
  if (nrow(data) == 0) {
    return("_Nenhum caso._")
  }
  data_chr <- data |>
    dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  header <- paste(names(data_chr), collapse = " | ")
  separator <- paste(rep("---", ncol(data_chr)), collapse = " | ")
  rows <- apply(data_chr, 1, function(row) paste(row, collapse = " | "))
  paste(c(header, separator, rows), collapse = "\n")
}

file_mtime <- function(path) {
  if (!file.exists(path)) {
    return(as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC"))
  }
  file.info(path)$mtime[[1]]
}

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE) |>
  dplyr::mutate(manifest_index = dplyr::row_number())

timings <- manifest |>
  dplyr::mutate(
    prompt_file = file.path(out_dir, "prompts", paste0(pid, ".prompt.md")),
    classification_file = file.path(out_dir, "classifications", paste0(pid, ".json")),
    reading_log_file = file.path(out_dir, "reading_logs", paste0(pid, ".json")),
    prompt_time = as.POSIXct(vapply(prompt_file, file_mtime, as.POSIXct(NA), USE.NAMES = FALSE), origin = "1970-01-01", tz = "UTC"),
    classification_time = as.POSIXct(vapply(classification_file, file_mtime, as.POSIXct(NA), USE.NAMES = FALSE), origin = "1970-01-01", tz = "UTC"),
    reading_log_time = as.POSIXct(vapply(reading_log_file, file_mtime, as.POSIXct(NA), USE.NAMES = FALSE), origin = "1970-01-01", tz = "UTC"),
    completed = file.exists(classification_file) & file.exists(reading_log_file),
    has_prompt = file.exists(prompt_file),
    duration_seconds = as.numeric(difftime(classification_time, prompt_time, units = "secs")),
    duration_seconds = dplyr::if_else(completed & has_prompt & duration_seconds >= 0, duration_seconds, NA_real_),
    duration_minutes = duration_seconds / 60,
    block_offset = ((manifest_index - 1L) %/% 100L) * 100L
  ) |>
  dplyr::select(
    manifest_index,
    block_offset,
    pid,
    title,
    journal_title,
    completed,
    has_prompt,
    prompt_time,
    classification_time,
    reading_log_time,
    duration_seconds,
    duration_minutes
  )

completed_timings <- timings |>
  dplyr::filter(completed, !is.na(duration_seconds))

total_articles <- nrow(manifest)
completed_articles <- sum(timings$completed, na.rm = TRUE)
completed_with_time <- nrow(completed_timings)
remaining_articles <- total_articles - completed_articles

duration_stats <- completed_timings |>
  dplyr::summarise(
    artigos_com_tempo = dplyr::n(),
    media_seg = mean(duration_seconds),
    mediana_seg = median(duration_seconds),
    p10_seg = unname(stats::quantile(duration_seconds, 0.10, names = FALSE)),
    p90_seg = unname(stats::quantile(duration_seconds, 0.90, names = FALSE)),
    p95_seg = unname(stats::quantile(duration_seconds, 0.95, names = FALSE)),
    min_seg = min(duration_seconds),
    max_seg = max(duration_seconds),
    soma_seg = sum(duration_seconds)
  )

mean_seconds <- duration_stats$media_seg[[1]]
median_seconds <- duration_stats$mediana_seg[[1]]
p90_seconds <- duration_stats$p90_seg[[1]]

estimate_table <- tibble::tibble(
  cenário = c("mediana observada", "média observada", "p90 observado"),
  segundos_por_artigo = c(median_seconds, mean_seconds, p90_seconds),
  tempo_total_manifesto = vapply(segundos_por_artigo * total_articles, fmt_duration, character(1)),
  tempo_restante = vapply(segundos_por_artigo * remaining_articles, fmt_duration, character(1))
) |>
  dplyr::mutate(segundos_por_artigo = round(segundos_por_artigo, 1))

block_table <- completed_timings |>
  dplyr::group_by(block_offset) |>
  dplyr::summarise(
    artigos = dplyr::n(),
    media_seg = round(mean(duration_seconds), 1),
    mediana_seg = round(median(duration_seconds), 1),
    p90_seg = round(unname(stats::quantile(duration_seconds, 0.90, names = FALSE)), 1),
    soma = fmt_duration(sum(duration_seconds)),
    .groups = "drop"
  ) |>
  dplyr::arrange(block_offset)

summary_table <- tibble::tibble(
  indicador = c(
    "artigos no manifesto",
    "artigos concluídos",
    "artigos restantes",
    "artigos concluídos com tempo estimável",
    "tempo observado somado",
    "média por artigo",
    "mediana por artigo",
    "p90 por artigo",
    "p95 por artigo"
  ),
  valor = c(
    as.character(total_articles),
    as.character(completed_articles),
    as.character(remaining_articles),
    as.character(completed_with_time),
    fmt_duration(duration_stats$soma_seg[[1]]),
    paste0(round(mean_seconds, 1), " s"),
    paste0(round(median_seconds, 1), " s"),
    paste0(round(p90_seconds, 1), " s"),
    paste0(round(duration_stats$p95_seg[[1]], 1), " s")
  )
)

report_lines <- c(
  "# Estimativa de tempo: credibility_prompt_v3 full corpus",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Método",
  "",
  paste0(
    "A duração por artigo é calculada como a diferença entre o `mtime` de ",
    "`prompts/<pid>.prompt.md`, escrito imediatamente antes da chamada `codex exec`, ",
    "e o `mtime` de `classifications/<pid>.json`, escrito após validação do JSON."
  ),
  "",
  "A estimativa exclui pausas manuais entre blocos, tempo de dry-run, tentativas que falharam antes do sucesso e tempo de espera por autorização após cada bloco de 100 artigos.",
  "",
  "## Tabela 1. Status e tempos observados",
  "",
  md_table(summary_table),
  "",
  "## Tabela 2. Projeção serial para o corpus completo",
  "",
  md_table(estimate_table),
  "",
  "## Tabela 3. Tempo por bloco concluído",
  "",
  md_table(block_table),
  "",
  "## Interpretação operacional",
  "",
  paste0(
    "Usando a média observada, os ", total_articles,
    " artigos exigiriam cerca de ", estimate_table$tempo_total_manifesto[estimate_table$cenário == "média observada"],
    " de processamento serial efetivo. Como ", completed_articles,
    " já estão concluídos, o restante exigiria cerca de ",
    estimate_table$tempo_restante[estimate_table$cenário == "média observada"],
    " de processamento efetivo, antes de retries e pausas de governança."
  ),
  "",
  paste0("CSV por artigo: `", csv_out, "`.")
)

dir.create(dirname(csv_out), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(report_out), recursive = TRUE, showWarnings = FALSE)

readr::write_csv(timings, csv_out, na = "")
writeLines(enc2utf8(report_lines), report_out, useBytes = TRUE)

cat("CSV escrito em:", csv_out, "\n")
cat("Relatório escrito em:", report_out, "\n")
