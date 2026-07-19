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
fulltext_path <- file.path(
  project_dir,
  "data/processed/fulltext_corpus/article_texts_corpus.csv"
)
ledger_path <- file.path(project_dir, "data/processed/excluded_articles.csv")
output_path <- file.path(
  project_dir,
  "quality_reports/paper_variable_audit/tendencias_non_article_supplements.csv"
)

corpus <- readr::read_csv(corpus_path, show_col_types = FALSE)
fulltext <- readr::read_csv(fulltext_path, show_col_types = FALSE) |>
  dplyr::select(pid, body_text)
ledger <- readr::read_csv(ledger_path, show_col_types = FALSE)

expected_pids <- c(
  "S0104-62762005000100009",
  "S0104-62762005000200008",
  "S0104-62762006000100008",
  "S0104-62762006000200009",
  "S0104-62762007000100008",
  "S0104-62762007000200008",
  "S0104-62762008000200010",
  "S0104-62762008000100009",
  "S0104-62762009000100010",
  "S0104-62762009000200009",
  "S0104-62762010000100010",
  "S0104-62762010000200011",
  "S0104-62762011000100009",
  "S0104-62762011000200010",
  "S0104-62762012000100012",
  "S0104-62762012000200013",
  "S0104-62762013000100010",
  "S0104-62762013000200010",
  "S0104-62762014000300523"
)

# Três membros já estavam fora do manifest por tipo documental e, por isso,
# não têm corpo utilizável na camada processada. Sua pertença à seção
# Tendências foi confirmada nos metadados/API ou XML brutos preservados.
raw_section_tendencias_pids <- c(
  "S0104-62762007000100008",
  "S0104-62762007000200008",
  "S0104-62762013000200010"
)

required_columns <- c("pid", "title", "title_en", "authors", "year", "journal_title")
missing_columns <- setdiff(required_columns, names(corpus))
if (length(missing_columns) > 0) {
  stop("Colunas ausentes no corpus: ", paste(missing_columns, collapse = "; "))
}

tendencias <- corpus |>
  dplyr::left_join(fulltext, by = "pid") |>
  dplyr::mutate(
    authors_missing = is.na(authors) | stringr::str_trim(authors) == "",
    tendencias_marker = pid %in% raw_section_tendencias_pids | stringr::str_detect(
      dplyr::coalesce(body_text, ""),
      stringr::regex("(^|\\n)\\s*TENDÊNCIAS\\s*($|\\n)|Encarte Tendências", ignore_case = TRUE)
    ) | stringr::str_detect(
      dplyr::coalesce(title, ""),
      stringr::regex("Tendências|Encarte de Dados", ignore_case = TRUE)
    ),
    title_recovered_from_text = dplyr::if_else(
      is.na(title) | stringr::str_trim(title) == "",
      "Tendências (Encarte)",
      title
    )
  ) |>
  dplyr::filter(
    journal_title == "Opinião Pública",
    authors_missing,
    tendencias_marker
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
    tendencias_marker,
    exclude_from_analysis,
    exclusion_reason,
    decision_date
  )

if (!setequal(tendencias$pid, expected_pids)) {
  stop(
    "A busca por encartes Tendências divergiu da lista auditada. Ausentes: ",
    paste(setdiff(expected_pids, tendencias$pid), collapse = "; "),
    ". Candidatos adicionais: ",
    paste(setdiff(tendencias$pid, expected_pids), collapse = "; "),
    "."
  )
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
