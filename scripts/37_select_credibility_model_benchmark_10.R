## Seleciona casos difíceis do A/B gpt-5.5 high vs xhigh para benchmark de modelos.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default) {
  pos <- match(flag, args)
  if (is.na(pos) || pos == length(args)) {
    return(default)
  }
  args[[pos + 1]]
}

project_dir <- normalizePath(".", mustWork = TRUE)
manifest_path <- get_arg(
  "--source-manifest",
  file.path(
    project_dir, "data", "processed", "credibility_prompt_v3_full_corpus",
    "batch_manifests", "ab_gpt55_high_50.csv"
  )
)
disagreements_path <- get_arg(
  "--disagreements",
  file.path(
    project_dir, "data", "processed", "credibility_prompt_v3_integral_reading",
    "full_corpus_ab", "gpt55_high", "combined", "ab_gpt55_high_disagreements.csv"
  )
)
out_manifest <- get_arg(
  "--out-manifest",
  file.path(
    project_dir, "data", "processed", "credibility_prompt_v3_full_corpus",
    "batch_manifests", "ab_gpt56_models_10.csv"
  )
)
out_report <- get_arg(
  "--out-report",
  file.path(project_dir, "quality_reports", "credibility_prompt_v3_ab_gpt56_models_10_selection.md")
)

read_utf8 <- function(path) {
  if (!file.exists(path)) {
    stop("Arquivo ausente: ", path)
  }
  readr::read_csv(
    path,
    col_types = readr::cols(.default = readr::col_character()),
    progress = FALSE,
    locale = readr::locale(encoding = "UTF-8")
  )
}

format_cell <- function(x) {
  x <- dplyr::coalesce(as.character(x), "")
  x <- stringr::str_replace_all(x, "\\|", "\\\\|")
  x <- stringr::str_replace_all(x, "[\r\n]+", " ")
  stringr::str_squish(x)
}

md_table <- function(data) {
  data_chr <- as.data.frame(lapply(data, format_cell), stringsAsFactors = FALSE)
  header <- paste(names(data_chr), collapse = " | ")
  separator <- paste(rep("---", ncol(data_chr)), collapse = " | ")
  rows <- apply(data_chr, 1, function(row) paste(row, collapse = " | "))
  paste(c(header, separator, rows), collapse = "\n")
}

write_utf8_lines <- function(lines, path) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  for (line in lines) {
    writeBin(charToRaw(enc2utf8(line)), con)
    writeBin(charToRaw("\n"), con)
  }
}

manifest <- read_utf8(manifest_path)
disagreements <- read_utf8(disagreements_path)

if (anyDuplicated(manifest$pid)) {
  stop("Manifesto de origem contém PIDs duplicados.")
}
if (anyDuplicated(disagreements$pid)) {
  stop("CSV de desacordos contém PIDs duplicados.")
}
if (!all(disagreements$pid %in% manifest$pid)) {
  stop("Há PIDs de desacordo ausentes no manifesto de origem.")
}

ranked <- disagreements |>
  dplyr::mutate(
    n_fields_disagree = stringr::str_count(fields_disagree, ";") + 1L,
    screen_method_issue = stringr::str_detect(
      fields_disagree,
      "credibility_revolution_(screen|method)"
    ),
    structural_issue = stringr::str_detect(
      fields_disagree,
      paste(
        c(
          "is_empirical_paper", "empirical_evidence_type",
          "is_empirical_qual_paper", "causal_or_explanatory_claim_present"
        ),
        collapse = "|"
      )
    ),
    tough_call_issue = stringr::str_detect(fields_disagree, "tough_call")
  )

screen_selected <- ranked |>
  dplyr::filter(screen_method_issue) |>
  dplyr::arrange(dplyr::desc(n_fields_disagree), pid) |>
  dplyr::slice_head(n = 7) |>
  dplyr::mutate(selection_reason = "Desacordo anterior em screen/método")

structural_selected <- ranked |>
  dplyr::filter(structural_issue, !pid %in% screen_selected$pid) |>
  dplyr::arrange(dplyr::desc(n_fields_disagree), pid) |>
  dplyr::slice_head(n = 2) |>
  dplyr::mutate(selection_reason = "Desacordo anterior sobre empirismo/evidência")

tough_selected <- ranked |>
  dplyr::filter(
    tough_call_issue,
    !pid %in% c(screen_selected$pid, structural_selected$pid)
  ) |>
  dplyr::arrange(dplyr::desc(n_fields_disagree), pid) |>
  dplyr::slice_head(n = 1) |>
  dplyr::mutate(selection_reason = "Desacordo anterior em tough_call")

selection <- dplyr::bind_rows(screen_selected, structural_selected, tough_selected)

if (nrow(selection) != 10 || anyDuplicated(selection$pid)) {
  stop("A seleção não produziu exatamente 10 PIDs únicos.")
}

selected_manifest <- selection |>
  dplyr::select(pid, selection_reason, fields_disagree, n_fields_disagree) |>
  dplyr::left_join(manifest, by = "pid")

required_paths <- selected_manifest$task_packet_file
missing_packets <- required_paths[
  !file.exists(file.path(project_dir, required_paths))
]
if (length(missing_packets) > 0) {
  stop("Task packets ausentes: ", paste(missing_packets, collapse = ", "))
}

dir.create(dirname(out_manifest), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(out_report), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(selected_manifest, out_manifest, na = "")

selection_table <- selected_manifest |>
  dplyr::select(pid, title, journal_title, selection_reason, fields_disagree)

report_lines <- c(
  "# Seleção do benchmark GPT-5.6: 10 casos difíceis",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Critério",
  "",
  "Foram selecionados 7 casos com desacordo anterior em screen/método, 2 com desacordo estrutural sobre empirismo/evidência e 1 com desacordo em `tough_call`. Dentro de cada grupo, casos com mais campos divergentes têm prioridade; empates são resolvidos por PID.",
  "",
  paste0("- Manifesto de origem: `", manifest_path, "`"),
  paste0("- Desacordos de origem: `", disagreements_path, "`"),
  paste0("- Manifesto congelado: `", out_manifest, "`"),
  "- PIDs selecionados: 10",
  "- PIDs únicos: 10",
  "- Task packets ausentes: 0",
  "",
  "## Tabela 1. Artigos selecionados para o benchmark",
  "",
  md_table(selection_table)
)

write_utf8_lines(report_lines, out_report)

cat("Manifesto escrito em:", out_manifest, "\n")
cat("Relatório escrito em:", out_report, "\n")
cat("PIDs selecionados:", nrow(selected_manifest), "\n")
