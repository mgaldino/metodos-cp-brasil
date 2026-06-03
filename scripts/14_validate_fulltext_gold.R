## 14_validate_fulltext_gold.R
## Valida a recuperação de body integral dos 175 artigos gold/piloto.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringi)
  library(stringr)
  library(tibble)
  library(tidyr)
})

project_dir <- normalizePath(".", mustWork = TRUE)

paths <- list(
  gold = file.path(project_dir, "data", "processed", "classifications_llm_main_analysis.csv"),
  metadata = file.path(project_dir, "data", "raw", "articles_2005_2025.csv"),
  fulltext = file.path(project_dir, "data", "processed", "fulltext_gold", "article_texts_gold.csv"),
  inventory = file.path(project_dir, "quality_reports", "fulltext_gold_inventory.csv"),
  report = file.path(project_dir, "quality_reports", "fulltext_gold_recovery_report.md")
)

dir.create(dirname(paths$inventory), showWarnings = FALSE, recursive = TRUE)

expected_n <- 175L
min_body_chars <- 3000L
min_body_words <- 600L

normalize_key <- function(x) {
  x |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", " ") |>
    stringr::str_squish()
}

word_count <- function(x) {
  stringr::str_count(dplyr::coalesce(x, ""), "[A-Za-zÀ-ÖØ-öø-ÿ0-9]+")
}

reference_heading_pattern <- paste(
  c(
    "^referencias$",
    "^referencias bibliograficas$",
    "^references$",
    "^bibliografia$",
    "^bibliography$",
    "^bibliographic references$"
  ),
  collapse = "|"
)

starts_with_references <- function(x) {
  first_block <- stringr::str_split(dplyr::coalesce(x, ""), "\\n\\n", n = 2, simplify = TRUE)[, 1]
  stringr::str_detect(normalize_key(first_block), reference_heading_pattern)
}

reference_tail_ratio_calc <- function(x) {
  purrr::map_dbl(dplyr::coalesce(x, ""), function(text) {
    blocks <- stringr::str_split(text, "\\n\\n", simplify = FALSE)[[1]]
    blocks <- blocks[stringr::str_squish(blocks) != ""]
    if (length(blocks) == 0) {
      return(1)
    }
    total_chars <- sum(nchar(blocks))
    ref_index <- which(stringr::str_detect(normalize_key(blocks), reference_heading_pattern))[1]
    if (is.na(ref_index)) {
      return(0)
    }
    sum(nchar(blocks[ref_index:length(blocks)])) / total_chars
  })
}

collapse_flags <- function(...) {
  values <- c(...)
  values <- values[!is.na(values) & values != ""]
  if (length(values) == 0) {
    return("")
  }
  paste(unique(values), collapse = ";")
}

gold <- readr::read_csv(paths$gold, show_col_types = FALSE) |>
  dplyr::select(pid)

metadata <- readr::read_csv(paths$metadata, show_col_types = FALSE) |>
  dplyr::select(
    pid,
    title,
    title_en,
    authors,
    year,
    issn,
    journal_title,
    abstract_pt,
    abstract_en,
    doi,
    document_type,
    language
  ) |>
  dplyr::mutate(
    abstract_pt = dplyr::coalesce(abstract_pt, ""),
    abstract_en = dplyr::coalesce(abstract_en, ""),
    abstract_char_count_expected = pmax(nchar(abstract_pt), nchar(abstract_en)),
    abstract_word_count_expected = pmax(word_count(abstract_pt), word_count(abstract_en))
  ) |>
  dplyr::select(
    pid,
    title,
    title_en,
    authors,
    year,
    issn,
    journal_title,
    abstract_char_count_expected,
    abstract_word_count_expected,
    doi,
    document_type,
    language
  )

if (!file.exists(paths$fulltext)) {
  stop("Arquivo processado ausente: ", paths$fulltext)
}

fulltext <- readr::read_csv(paths$fulltext, show_col_types = FALSE) |>
  dplyr::mutate(
    body_text = dplyr::coalesce(body_text, ""),
    body_char_count = as.integer(body_char_count),
    body_word_count = as.integer(body_word_count),
    abstract_char_count = as.integer(abstract_char_count),
    reference_tail_ratio = as.numeric(reference_tail_ratio)
  )

inventory <- gold |>
  dplyr::left_join(metadata, by = "pid") |>
  dplyr::left_join(
    fulltext |>
      dplyr::select(
        pid,
        body_text,
        body_char_count,
        body_word_count,
        source_method,
        source_url,
        input_hash,
        retrieved_at,
        abstract_char_count,
        reference_tail_ratio,
        validation_flags
      ),
    by = "pid"
  ) |>
  dplyr::mutate(
    present_in_processed = !is.na(body_text),
    pid_is_unique_in_processed = pid %in% names(which(table(fulltext$pid) == 1)),
    body_text_nonempty = present_in_processed & stringr::str_squish(body_text) != "",
    body_char_count_recomputed = nchar(dplyr::coalesce(body_text, "")),
    body_word_count_recomputed = word_count(body_text),
    body_char_count_matches = body_char_count == body_char_count_recomputed,
    body_word_count_matches = body_word_count == body_word_count_recomputed,
    body_minimum_size_ok = body_char_count_recomputed >= min_body_chars &
      body_word_count_recomputed >= min_body_words,
    abstract_chars_for_rule = pmax(
      abstract_char_count_expected,
      dplyr::coalesce(abstract_char_count, 0L),
      na.rm = TRUE
    ),
    body_substantially_larger_than_abstract = dplyr::case_when(
      abstract_chars_for_rule >= 400 ~ body_char_count_recomputed >=
        pmax(min_body_chars, abstract_chars_for_rule * 3),
      TRUE ~ body_char_count_recomputed >= min_body_chars
    ),
    starts_with_references = starts_with_references(body_text),
    reference_tail_ratio_recomputed = reference_tail_ratio_calc(body_text),
    references_not_majority = !starts_with_references &
      reference_tail_ratio_recomputed <= 0.45,
    validation_status = dplyr::if_else(
      present_in_processed &
        pid_is_unique_in_processed &
        body_text_nonempty &
        body_char_count_matches &
        body_word_count_matches &
        body_minimum_size_ok &
        body_substantially_larger_than_abstract &
        references_not_majority,
      "PASS",
      "FAIL"
    ),
    suspect_flags = purrr::pmap_chr(
      list(
        present_in_processed,
        pid_is_unique_in_processed,
        body_text_nonempty,
        body_char_count_matches,
        body_word_count_matches,
        body_minimum_size_ok,
        body_substantially_larger_than_abstract,
        starts_with_references,
        reference_tail_ratio_recomputed
      ),
      function(present, unique_pid, nonempty, chars_match, words_match,
               minimum_size, larger_than_abstract, starts_refs, ref_ratio) {
        collapse_flags(
          if (!present) "missing_pid",
          if (present && !unique_pid) "duplicate_pid",
          if (present && !nonempty) "empty_body",
          if (present && !chars_match) "body_char_count_mismatch",
          if (present && !words_match) "body_word_count_mismatch",
          if (present && !minimum_size) "too_short_for_body",
          if (present && !larger_than_abstract) "not_substantially_larger_than_abstract",
          if (present && starts_refs) "starts_with_references",
          if (present && ref_ratio > 0.45) "references_majority"
        )
      }
    ),
    nonblocking_flags = purrr::pmap_chr(
      list(
        present_in_processed,
        body_char_count_recomputed,
        body_word_count_recomputed,
        reference_tail_ratio_recomputed,
        abstract_chars_for_rule
      ),
      function(present, chars, words, ref_ratio, abstract_chars) {
        collapse_flags(
          if (present && chars < 5000) "short_but_valid",
          if (present && words < 1200) "low_word_count_but_valid",
          if (present && ref_ratio > 0.25) "large_reference_tail",
          if (present && abstract_chars >= 400 && chars < abstract_chars * 4) {
            "near_abstract_size_threshold"
          }
        )
      }
    )
  )

method_counts <- inventory |>
  dplyr::filter(validation_status == "PASS") |>
  dplyr::count(source_method, name = "n") |>
  dplyr::arrange(dplyr::desc(n), source_method)

failures <- inventory |>
  dplyr::filter(validation_status != "PASS") |>
  dplyr::select(pid, title, journal_title, year, suspect_flags, source_method, source_url)

suspects <- inventory |>
  dplyr::filter(
    validation_status == "PASS",
    nonblocking_flags != ""
  ) |>
  dplyr::select(
    pid,
    title,
    journal_title,
    year,
    body_char_count_recomputed,
    body_word_count_recomputed,
    source_method,
    nonblocking_flags
  )

readr::write_csv(
  inventory |>
    dplyr::select(
      pid,
      title,
      title_en,
      authors,
      year,
      issn,
      journal_title,
      doi,
      document_type,
      language,
      source_method,
      source_url,
      input_hash,
      retrieved_at,
      body_char_count = body_char_count_recomputed,
      body_word_count = body_word_count_recomputed,
      abstract_char_count_expected,
      reference_tail_ratio = reference_tail_ratio_recomputed,
      present_in_processed,
      pid_is_unique_in_processed,
      body_text_nonempty,
      body_minimum_size_ok,
      body_substantially_larger_than_abstract,
      references_not_majority,
      validation_status,
      suspect_flags,
      nonblocking_flags
    ),
  paths$inventory
)

report_lines <- c(
  "# Fulltext gold recovery report",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Summary",
  "",
  paste0("- Expected gold PIDs: ", expected_n),
  paste0("- Gold PIDs found in `", basename(paths$gold), "`: ", nrow(gold)),
  paste0("- Rows in processed fulltext CSV: ", nrow(fulltext)),
  paste0("- Unique processed PIDs: ", dplyr::n_distinct(fulltext$pid)),
  paste0("- Validated bodies: ", sum(inventory$validation_status == "PASS"), "/", expected_n),
  paste0("- Failed or missing bodies: ", nrow(failures)),
  "",
  "## Recovery methods",
  "",
  if (nrow(method_counts) == 0) {
    "_No validated recovery methods._"
  } else {
    paste0("- ", method_counts$source_method, ": ", method_counts$n)
  },
  "",
  "## Blocking failures",
  "",
  if (nrow(failures) == 0) {
    "None. All 175 gold/pilot PIDs have validated body text."
  } else {
    paste0(
      "- `", failures$pid, "` (", failures$journal_title, ", ", failures$year,
      "): ", failures$suspect_flags
    )
  },
  "",
  "## Nonblocking suspicious cases",
  "",
  if (nrow(suspects) == 0) {
    "No nonblocking suspicious cases under the current thresholds."
  } else {
    paste0(
      "- `", suspects$pid, "`: ", suspects$body_word_count_recomputed,
      " words via ", suspects$source_method, " (", suspects$nonblocking_flags, ")"
    )
  },
  "",
  "## Validation rules",
  "",
  paste0("- All ", expected_n, " PIDs from the gold/pilot CSV must be present."),
  "- PIDs must be unique in the processed fulltext CSV.",
  "- `body_text` must be non-empty and at least 3,000 characters / 600 words.",
  "- `body_text` must be substantially larger than the longest available abstract.",
  "- Text starting with references or composed mostly of a reference tail fails.",
  "- Abstract, metadata, keywords and references are not accepted as body substitutes.",
  "",
  "## Outputs",
  "",
  paste0("- Processed body text: `", paths$fulltext, "`"),
  paste0("- Inventory: `", paths$inventory, "`")
)

writeLines(report_lines, paths$report, useBytes = TRUE)

if (nrow(gold) != expected_n) {
  stop("Gold PID count is not ", expected_n, ": ", nrow(gold))
}

if (nrow(failures) > 0) {
  missing_msg <- paste(failures$pid, collapse = ", ")
  stop("Fulltext gold validation failed. Missing/failed PIDs: ", missing_msg)
}

message("Fulltext gold validation passed: ", expected_n, "/", expected_n, " bodies.")
