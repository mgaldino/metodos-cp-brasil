## 34_select_credibility_integral_next_batch.R
## Seleciona um bloco congelado de PIDs ainda não concluídos no manifesto ativo.

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
limit <- as.integer(get_arg("--limit", "100"))
label <- get_arg("--label", paste0("active_next_", format(Sys.time(), "%Y%m%d_%H%M%S")))
batch_manifest_out <- get_arg(
  "--out",
  file.path("data/processed/credibility_prompt_v3_full_corpus/batch_manifests", paste0(label, ".csv"))
)
report_out <- get_arg(
  "--report-out",
  file.path("quality_reports", paste0("credibility_prompt_v3_", label, "_selection.md"))
)
journal_title_filter <- get_arg("--journal-title", NULL)

utf8_key <- function(values) {
  vapply(
    as.character(values),
    function(value) {
      Encoding(value) <- "UTF-8"
      paste(as.integer(charToRaw(value)), collapse = ":")
    },
    character(1)
  )
}

if (is.na(limit) || limit <= 0) {
  stop("--limit deve ser um inteiro positivo.")
}

if (!file.exists(manifest_path)) {
  stop("Manifest ausente: ", manifest_path)
}

if (!dir.exists(out_dir)) {
  stop("Diretório de outputs ausente: ", out_dir)
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

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE, progress = FALSE)

status <- manifest |>
  dplyr::mutate(
    reading_log_file = file.path(out_dir, "reading_logs", paste0(pid, ".json")),
    classification_file = file.path(out_dir, "classifications", paste0(pid, ".json")),
    already_complete = file.exists(reading_log_file) & file.exists(classification_file)
  )

selection_pool <- status |>
  dplyr::filter(!already_complete)
if (!is.null(journal_title_filter)) {
  journal_title_filter_key <- utf8_key(journal_title_filter)
  selection_pool <- selection_pool |>
    dplyr::filter(utf8_key(journal_title) == journal_title_filter_key)
}
selected <- selection_pool |>
  dplyr::slice_head(n = limit)

if (nrow(selected) == 0) {
  stop("Nenhum PID pendente encontrado no manifesto ativo.")
}

batch_manifest <- selected |>
  dplyr::select(-reading_log_file, -classification_file, -already_complete)

dir.create(dirname(batch_manifest_out), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(report_out), recursive = TRUE, showWarnings = FALSE)

readr::write_csv(batch_manifest, batch_manifest_out, na = "")

journal_counts <- batch_manifest |>
  dplyr::count(journal_title, name = "n") |>
  dplyr::arrange(dplyr::desc(n), journal_title)

selection_bounds <- batch_manifest |>
  dplyr::summarise(
    first_eligible_order = min(eligible_order),
    last_eligible_order = max(eligible_order),
    first_pid = dplyr::first(pid),
    last_pid = dplyr::last(pid)
  )

summary_table <- tibble::tibble(
  indicador = c(
    "artigos no manifesto ativo",
    "artigos já completos no manifesto ativo",
    "artigos pendentes antes deste bloco",
    "artigos selecionados neste bloco"
  ),
  valor = c(
    as.character(nrow(status)),
    as.character(sum(status$already_complete, na.rm = TRUE)),
    as.character(sum(!status$already_complete, na.rm = TRUE)),
    as.character(nrow(batch_manifest))
  )
)

report_lines <- c(
  paste0("# Seleção de batch: ", label),
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Tabela 1. Síntese",
  "",
  md_table(summary_table),
  "",
  "## Tabela 2. Limites do bloco",
  "",
  md_table(selection_bounds),
  "",
  "## Tabela 3. Periódicos no bloco",
  "",
  md_table(journal_counts),
  "",
  "## Arquivos",
  "",
  paste0("- Manifesto ativo: `", manifest_path, "`."),
  paste0("- Manifesto congelado do bloco: `", batch_manifest_out, "`.")
)

writeLines(enc2utf8(report_lines), report_out, useBytes = TRUE)

cat("Manifesto do bloco escrito em:", batch_manifest_out, "\n")
cat("Relatório escrito em:", report_out, "\n")
cat("Selecionados:", nrow(batch_manifest), "\n")
