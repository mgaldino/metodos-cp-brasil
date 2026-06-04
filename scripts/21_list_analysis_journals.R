#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

options(scipen = 999)

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) == 1) sub("^--file=", "", file_arg) else file.path("scripts", "21_list_analysis_journals.R")
project_dir <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

read_csv_utf8 <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE, locale = readr::locale(encoding = "UTF-8"))
}

paths <- list(
  raw_articles = file.path(project_dir, "data", "raw", "articles_2005_2025.csv"),
  excluded_journals = file.path(project_dir, "data", "processed", "excluded_journals.csv"),
  corpus_manifest = file.path(project_dir, "data", "processed", "fulltext_corpus", "fulltext_corpus_manifest.csv"),
  corpus_texts = file.path(project_dir, "data", "processed", "fulltext_corpus", "article_texts_corpus.csv"),
  out_csv = file.path(project_dir, "quality_reports", "analysis_journals_list.csv")
)

raw_articles <- read_csv_utf8(paths$raw_articles)
excluded_journals <- read_csv_utf8(paths$excluded_journals) |>
  dplyr::filter(exclude_from_analysis) |>
  dplyr::select(journal_title, issn, exclusion_reason)

corpus_manifest <- read_csv_utf8(paths$corpus_manifest)
corpus_texts <- read_csv_utf8(paths$corpus_texts)

raw_counts <- raw_articles |>
  dplyr::count(journal_title, issn, name = "raw_articles_2005_2025")

eligible_counts <- corpus_manifest |>
  dplyr::count(journal_title, issn, name = "eligible_manifest_articles")

recovered_counts <- corpus_texts |>
  dplyr::count(journal_title, issn, name = "recovered_body_articles")

journal_list <- raw_counts |>
  dplyr::left_join(excluded_journals, by = c("journal_title", "issn")) |>
  dplyr::mutate(
    excluded_from_main_analysis = !is.na(exclusion_reason)
  ) |>
  dplyr::left_join(eligible_counts, by = c("journal_title", "issn")) |>
  dplyr::left_join(recovered_counts, by = c("journal_title", "issn")) |>
  dplyr::mutate(
    eligible_manifest_articles = dplyr::coalesce(eligible_manifest_articles, 0L),
    recovered_body_articles = dplyr::coalesce(recovered_body_articles, 0L),
    exclusion_reason = dplyr::coalesce(exclusion_reason, "")
  ) |>
  dplyr::arrange(excluded_from_main_analysis, journal_title, issn) |>
  dplyr::select(
    journal_title,
    issn,
    raw_articles_2005_2025,
    eligible_manifest_articles,
    recovered_body_articles,
    excluded_from_main_analysis,
    exclusion_reason
  )

readr::write_csv(journal_list, paths$out_csv)

cat("Wrote:", paths$out_csv, "\n")
print(journal_list, n = nrow(journal_list), width = Inf)
