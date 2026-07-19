#!/usr/bin/env Rscript

## Audita a elegibilidade dos encartes não assinados "Tendências".
## O script não altera dados: produz a lista documentada que deve coincidir
## exatamente com as decisões registradas no ledger canônico de exclusões.

options(scipen = 999, encoding = "UTF-8")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

file_arg <- commandArgs(trailingOnly = FALSE) |>
  stringr::str_subset("^--file=") |>
  stringr::str_remove("^--file=")
if (length(file_arg) != 1) {
  stop("Não foi possível identificar o caminho do script.")
}

project_dir <- normalizePath(file.path(dirname(file_arg), ".."), mustWork = TRUE)
corpus_path <- file.path(project_dir, "data/raw/articles_2005_2025.csv")
ledger_path <- file.path(project_dir, "data/processed/excluded_articles.csv")
output_path <- file.path(
  project_dir,
  "quality_reports/paper_variable_audit/tendencias_non_article_supplements.csv"
)

corpus <- readr::read_csv(corpus_path, show_col_types = FALSE)
ledger <- readr::read_csv(ledger_path, show_col_types = FALSE)

required_columns <- c("pid", "title", "title_en", "authors", "year", "journal_title")
missing_columns <- setdiff(required_columns, names(corpus))
if (length(missing_columns) > 0) {
  stop("Colunas ausentes no corpus: ", paste(missing_columns, collapse = "; "))
}

tendencias <- corpus |>
  dplyr::filter(
    journal_title == "Opinião Pública",
    year >= 2005,
    year <= 2012,
    stringr::str_to_lower(dplyr::coalesce(title, "")) == "tendências" |
      pid %in% c(
        "S0104-62762005000200008",
        "S0104-62762006000100008",
        "S0104-62762006000200009"
      )
  ) |>
  dplyr::mutate(
    authors_missing = is.na(authors) | stringr::str_trim(authors) == "",
    title_recovered_from_text = dplyr::if_else(
      is.na(title) | stringr::str_trim(title) == "",
      "Tendências (Encarte)",
      title
    )
  ) |>
  dplyr::left_join(
    ledger |>
      dplyr::select(pid, exclude_from_analysis, exclusion_reason, decision_date),
    by = "pid"
  ) |>
  dplyr::arrange(year, pid) |>
  dplyr::select(
    pid,
    title_recovered_from_text,
    journal_title,
    year,
    authors,
    authors_missing,
    exclude_from_analysis,
    exclusion_reason,
    decision_date
  )

expected_pids <- c(
  "S0104-62762005000200008",
  "S0104-62762006000100008",
  "S0104-62762006000200009",
  "S0104-62762008000100009",
  "S0104-62762009000200009",
  "S0104-62762010000200011",
  "S0104-62762011000100009",
  "S0104-62762012000200013"
)

if (!setequal(tendencias$pid, expected_pids)) {
  stop("A busca por encartes Tendências divergiu da lista auditada.")
}
if (any(!tendencias$authors_missing)) {
  stop("Há encarte Tendências com autoria registrada; a regra exige revisão.")
}
if (any(tendencias$exclude_from_analysis != TRUE, na.rm = TRUE) ||
    any(is.na(tendencias$exclude_from_analysis))) {
  stop("Nem todos os encartes auditados estão excluídos no ledger canônico.")
}
if (any(tendencias$exclusion_reason != "non_article_data_supplement")) {
  stop("A justificativa do ledger diverge da decisão metodológica documentada.")
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(tendencias, output_path, na = "")
message("Auditoria salva: ", output_path, " (", nrow(tendencias), " encartes).")
