#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

options(scipen = 999)

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) == 1) sub("^--file=", "", file_arg) else file.path("scripts", "22_prepare_credibility_prompt_v3_test.R")
project_dir <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

read_csv_utf8 <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE, locale = readr::locale(encoding = "UTF-8"))
}

paths <- list(
  corpus_texts = file.path(project_dir, "data", "processed", "fulltext_corpus", "article_texts_corpus.csv"),
  manual_gold = file.path(project_dir, "data", "processed", "classifications_llm_main_analysis.csv"),
  out_dir = file.path(project_dir, "data", "processed", "credibility_prompt_v3_test"),
  packets_dir = file.path(project_dir, "data", "processed", "credibility_prompt_v3_test", "task_packets")
)

dir.create(paths$out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(paths$packets_dir, recursive = TRUE, showWarnings = FALSE)

test_papers <- tibble::tribble(
  ~test_order, ~pid, ~selection_source, ~selection_note,
  1L, "S0104-62762025000100200", "user_selected", "Why democracy does not work for everyone",
  2L, "S0104-62762025000100206", "user_selected", "Sobre balas, biblias e modelos estatisticos",
  3L, "S0104-62762025000100215", "user_selected", "Conferencias nacionais e (des)democratizacao",
  4L, "S0102-69092020000100502", "user_selected", "Sistemas nacionais de politicas publicas e seus efeitos",
  5L, "S0104-62762021000100230", "user_selected", "Efeitos diretos e indiretos do Programa Bolsa Familia",
  6L, "S0011-52582010000200002", "codex_selected_pilot", "manual gold: theoretical-normative",
  7L, "S0011-52582018000200463", "codex_selected_pilot", "manual gold: qualitative",
  8L, "S1981-38212015000100003", "codex_selected_pilot", "manual gold: theoretical-normative",
  9L, "S1981-38212024000200201", "codex_selected_pilot", "manual gold: qualitative",
  10L, "S0102-85292021000100199", "codex_selected_pilot", "manual gold: theoretical-normative"
)

corpus <- read_csv_utf8(paths$corpus_texts)
gold <- read_csv_utf8(paths$manual_gold) |>
  dplyr::select(pid, manual_gold_evidence_type = evidence_type, manual_gold_method_status = method_status)

missing_pids <- setdiff(test_papers$pid, corpus$pid)
if (length(missing_pids) > 0) {
  stop("Missing PIDs in corpus: ", paste(missing_pids, collapse = ", "))
}

manifest <- test_papers |>
  dplyr::left_join(
    corpus |>
      dplyr::select(
        pid, title, title_en, authors, year, issn, journal_title, doi, document_type,
        language, body_word_count, body_char_count, source_method, source_url,
        input_text_hash = input_hash
      ),
    by = "pid"
  ) |>
  dplyr::left_join(gold, by = "pid") |>
  dplyr::mutate(
    task_packet_file = file.path(
      "data", "processed", "credibility_prompt_v3_test", "task_packets",
      paste0(stringr::str_pad(test_order, 2, pad = "0"), "_", pid, ".md")
    )
  ) |>
  dplyr::arrange(test_order)

manifest_path <- file.path(paths$out_dir, "manifest_10_papers.csv")
readr::write_csv(manifest, manifest_path)

body_lookup <- corpus |>
  dplyr::select(pid, body_text)

for (i in seq_len(nrow(manifest))) {
  row <- manifest[i, ]
  body <- body_lookup$body_text[match(row$pid, body_lookup$pid)]
  packet_path <- file.path(project_dir, row$task_packet_file)
  packet_lines <- c(
    "---",
    paste0("test_order: ", row$test_order),
    paste0("pid: ", row$pid),
    paste0("title: ", row$title),
    paste0("title_en: ", ifelse(is.na(row$title_en), "", row$title_en)),
    paste0("authors: ", row$authors),
    paste0("year: ", row$year),
    paste0("journal_title: ", row$journal_title),
    paste0("doi: ", ifelse(is.na(row$doi), "", row$doi)),
    paste0("language: ", row$language),
    paste0("input_text_hash: ", row$input_text_hash),
    paste0("selection_source: ", row$selection_source),
    paste0("selection_note: ", row$selection_note),
    paste0("manual_gold_evidence_type: ", ifelse(is.na(row$manual_gold_evidence_type), "", row$manual_gold_evidence_type)),
    paste0("manual_gold_method_status: ", ifelse(is.na(row$manual_gold_method_status), "", row$manual_gold_method_status)),
    "---",
    "",
    "# Article Body",
    "",
    body
  )
  readr::write_lines(packet_lines, packet_path)
}

cat("Wrote manifest:", manifest_path, "\n")
cat("Wrote task packets:", paths$packets_dir, "\n")
print(
  manifest |>
    dplyr::select(
      test_order, pid, title, year, journal_title, doi, selection_source,
      manual_gold_evidence_type, manual_gold_method_status, task_packet_file
    ),
  n = Inf,
  width = Inf
)
