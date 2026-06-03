## 14_validate_fulltext_gold.R
## Valida a recuperação de body integral dos 175 artigos gold/piloto.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringi)
  library(stringr)
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
    "^referencias( bibliograficas| e notas)?\\b",
    "^references( and notes)?\\b",
    "^notes and references\\b",
    "^bibliografia\\b",
    "^bibliography\\b",
    "^bibliographic references\\b"
  ),
  collapse = "|"
)

front_matter_pattern <- paste(
  c(
    "^abstract\\b",
    "^resumo\\b",
    "^resumen\\b",
    "^resume\\b",
    "^palavras chave\\b",
    "^keywords\\b",
    "^key words\\b",
    "^palabras clave\\b",
    "^mots cles\\b"
  ),
  collapse = "|"
)

starts_with_references <- function(x) {
  first_block <- stringr::str_split(dplyr::coalesce(x, ""), "\\n\\n", n = 2, simplify = TRUE)[, 1]
  stringr::str_detect(normalize_key(first_block), reference_heading_pattern)
}

starts_with_front_matter <- function(x) {
  first_block <- stringr::str_split(dplyr::coalesce(x, ""), "\\n\\n", n = 2, simplify = TRUE)[, 1]
  stringr::str_detect(normalize_key(first_block), front_matter_pattern)
}

body_block_count <- function(x) {
  purrr::map_int(dplyr::coalesce(x, ""), function(text) {
    blocks <- stringr::str_split(text, "\\n\\n", simplify = FALSE)[[1]]
    sum(stringr::str_squish(blocks) != "")
  })
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

gold_duplicate_pids <- gold |>
  dplyr::count(pid, name = "n") |>
  dplyr::filter(n > 1) |>
  dplyr::pull(pid)

processed_duplicate_pids <- fulltext |>
  dplyr::count(pid, name = "n") |>
  dplyr::filter(n > 1) |>
  dplyr::pull(pid)

processed_extra_pids <- setdiff(fulltext$pid, gold$pid)
processed_missing_pids <- setdiff(gold$pid, fulltext$pid)

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
    body_block_count = body_block_count(body_text),
    body_char_count_matches = body_char_count == body_char_count_recomputed,
    body_word_count_matches = body_word_count == body_word_count_recomputed,
    source_provenance_ok = present_in_processed &
      source_method %in% c("articlemeta_fulltexts_html", "citation_xml_body", "pdf_text_extraction") &
      !is.na(source_url) & stringr::str_squish(source_url) != "" &
      !is.na(input_hash) & stringr::str_detect(input_hash, "^[a-f0-9]{64}$") &
      !is.na(retrieved_at) & stringr::str_squish(retrieved_at) != "",
    body_minimum_size_ok = body_char_count_recomputed >= min_body_chars &
      body_word_count_recomputed >= min_body_words,
    body_has_min_blocks = body_block_count >= 4,
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
    starts_with_front_matter = starts_with_front_matter(body_text),
    reference_tail_ratio_recomputed = reference_tail_ratio_calc(body_text),
    references_not_majority = !starts_with_references &
      reference_tail_ratio_recomputed <= 0.45,
    body_not_frontmatter = !starts_with_front_matter,
    validation_status = dplyr::if_else(
      present_in_processed &
        pid_is_unique_in_processed &
        body_text_nonempty &
        source_provenance_ok &
        body_char_count_matches &
        body_word_count_matches &
        body_minimum_size_ok &
        body_has_min_blocks &
        body_substantially_larger_than_abstract &
        references_not_majority &
        body_not_frontmatter,
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
        source_provenance_ok,
        body_minimum_size_ok,
        body_has_min_blocks,
        body_substantially_larger_than_abstract,
        starts_with_references,
        starts_with_front_matter,
        reference_tail_ratio_recomputed
      ),
      function(present, unique_pid, nonempty, chars_match, words_match,
               provenance_ok, minimum_size, min_blocks, larger_than_abstract,
               starts_refs, starts_front, ref_ratio) {
        collapse_flags(
          if (!present) "missing_pid",
          if (present && !unique_pid) "duplicate_pid",
          if (present && !nonempty) "empty_body",
          if (present && !chars_match) "body_char_count_mismatch",
          if (present && !words_match) "body_word_count_mismatch",
          if (present && !provenance_ok) "missing_or_invalid_provenance",
          if (present && !minimum_size) "too_short_for_body",
          if (present && !min_blocks) "too_few_body_blocks",
          if (present && !larger_than_abstract) "not_substantially_larger_than_abstract",
          if (present && starts_front) "starts_with_front_matter",
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

global_failures <- c(
  if (nrow(gold) != expected_n) paste0("gold_row_count_not_", expected_n, ": ", nrow(gold)),
  if (dplyr::n_distinct(gold$pid) != expected_n) {
    paste0("gold_unique_pid_count_not_", expected_n, ": ", dplyr::n_distinct(gold$pid))
  },
  if (length(gold_duplicate_pids) > 0) {
    paste0("gold_duplicate_pids: ", paste(gold_duplicate_pids, collapse = ", "))
  },
  if (nrow(fulltext) != expected_n) paste0("processed_row_count_not_", expected_n, ": ", nrow(fulltext)),
  if (dplyr::n_distinct(fulltext$pid) != expected_n) {
    paste0("processed_unique_pid_count_not_", expected_n, ": ", dplyr::n_distinct(fulltext$pid))
  },
  if (length(processed_duplicate_pids) > 0) {
    paste0("processed_duplicate_pids: ", paste(processed_duplicate_pids, collapse = ", "))
  },
  if (length(processed_extra_pids) > 0) {
    paste0("processed_extra_pids: ", paste(processed_extra_pids, collapse = ", "))
  },
  if (length(processed_missing_pids) > 0) {
    paste0("processed_missing_pids: ", paste(processed_missing_pids, collapse = ", "))
  }
)
global_failures <- global_failures[!is.na(global_failures) & global_failures != ""]

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
      source_provenance_ok,
      body_block_count,
      body_minimum_size_ok,
      body_has_min_blocks,
      body_substantially_larger_than_abstract,
      references_not_majority,
      body_not_frontmatter,
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
  paste0("- Row-level failed or missing bodies: ", nrow(failures)),
  paste0("- Global validation failures: ", length(global_failures)),
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
  if (length(global_failures) == 0 && nrow(failures) == 0) {
    "None. All 175 gold/pilot PIDs have validated body text."
  } else {
    c(
      if (length(global_failures) > 0) paste0("- ", global_failures),
      if (nrow(failures) > 0) {
        paste0(
          "- `", failures$pid, "` (", failures$journal_title, ", ", failures$year,
          "): ", failures$suspect_flags
        )
      }
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
  "- Provenance fields (`source_method`, `source_url`, `input_hash`, `retrieved_at`) are mandatory.",
  "- `body_text` must contain at least four text blocks and cannot start with abstract/keyword front matter.",
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

if (length(global_failures) > 0 || nrow(failures) > 0) {
  failure_msg <- paste(c(global_failures, failures$pid), collapse = "; ")
  stop("Fulltext gold validation failed: ", failure_msg)
}

message("Fulltext gold validation passed: ", expected_n, "/", expected_n, " bodies.")
