## 17_validate_fulltext_corpus.R
## Valida a recuperação de body integral do corpus SciELO elegível completo.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringi)
  library(stringr)
})

project_dir <- normalizePath(".", mustWork = TRUE)

paths <- list(
  corpus = file.path(project_dir, "data", "raw", "articles_2005_2025.csv"),
  excluded_journals = file.path(project_dir, "data", "processed", "excluded_journals.csv"),
  excluded_articles = file.path(project_dir, "data", "processed", "excluded_articles.csv"),
  fulltext = file.path(project_dir, "data", "processed", "fulltext_corpus", "article_texts_corpus.csv"),
  inventory = file.path(project_dir, "quality_reports", "fulltext_corpus_inventory.csv"),
  report = file.path(project_dir, "quality_reports", "fulltext_corpus_recovery_report.md")
)

dir.create(dirname(paths$inventory), showWarnings = FALSE, recursive = TRUE)

expected_plan_n <- 6672L
min_body_chars <- 3000L
min_body_words <- 600L

is_true <- function(x) {
  stringr::str_to_lower(stringr::str_trim(dplyr::coalesce(as.character(x), ""))) %in%
    c("true", "1", "yes", "y", "sim")
}

normalize_key <- function(x) {
  x |>
    dplyr::coalesce("") |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", " ") |>
    stringr::str_squish()
}

word_count <- function(x) {
  stringr::str_count(dplyr::coalesce(x, ""), "[A-Za-zÀ-ÖØ-öø-ÿ0-9]+")
}

file_sha256 <- function(path) {
  if (is.na(path) || path == "" || !file.exists(path)) {
    return(NA_character_)
  }
  digest::digest(path, algo = "sha256", file = TRUE)
}

text_sha256 <- function(x) {
  purrr::map_chr(dplyr::coalesce(x, ""), digest::digest, algo = "sha256")
}

reference_heading_keys <- normalize_key(c(
  "referencias",
  "referências",
  "references",
  "bibliografia",
  "bibliography",
  "referencias bibliograficas",
  "referências bibliográficas",
  "referencias e notas",
  "referências e notas",
  "references and notes",
  "notes and references",
  "bibliographic references"
))

reference_heading_prefixes <- normalize_key(c(
  "referencias bibliograficas",
  "referências bibliográficas",
  "referencias e notas",
  "referências e notas",
  "references and notes",
  "notes and references",
  "bibliographic references"
))

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
  is_reference_heading_block(first_block)
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
    ref_index <- which(is_reference_heading_block(blocks))[1]
    if (is.na(ref_index)) {
      return(0)
    }
    sum(nchar(blocks[ref_index:length(blocks)])) / total_chars
  })
}

is_reference_heading_block <- function(text) {
  key <- normalize_key(text)
  exact_match <- key %in% reference_heading_keys
  short_heading <- word_count(key) <= 8 & nchar(key) <= 100
  prefix_pattern <- paste0("^(", paste(reference_heading_prefixes, collapse = "|"), ")\\b")
  prefix_match <- short_heading & stringr::str_detect(key, prefix_pattern)
  exact_match | prefix_match
}

collapse_flags <- function(...) {
  values <- c(...)
  values <- values[!is.na(values) & values != ""]
  if (length(values) == 0) {
    return("")
  }
  paste(unique(values), collapse = ";")
}

if (stringr::str_detect(paths$fulltext, "fulltext_gold")) {
  stop("A validação do corpus não pode apontar para caminhos fulltext_gold.")
}

articles <- readr::read_csv(paths$corpus, show_col_types = FALSE) |>
  dplyr::mutate(
    raw_row_order = dplyr::row_number(),
    year_num = suppressWarnings(as.integer(year)),
    title_key_for_exclusion = normalize_key(journal_title),
    issn_key_for_exclusion = normalize_key(issn),
    article_pid_excluded = FALSE
  )

excluded_journals <- readr::read_csv(paths$excluded_journals, show_col_types = FALSE) |>
  dplyr::filter(is_true(exclude_from_analysis)) |>
  dplyr::mutate(
    title_key_for_exclusion = normalize_key(journal_title),
    issn_key_for_exclusion = normalize_key(issn),
    journal_pair_key = paste(title_key_for_exclusion, issn_key_for_exclusion, sep = "||")
  ) |>
  dplyr::select(title_key_for_exclusion, issn_key_for_exclusion, journal_pair_key)

excluded_articles <- readr::read_csv(paths$excluded_articles, show_col_types = FALSE) |>
  dplyr::filter(is_true(exclude_from_analysis)) |>
  dplyr::select(pid)

excluded_title_keys <- unique(excluded_journals$title_key_for_exclusion)
excluded_issn_keys <- unique(excluded_journals$issn_key_for_exclusion)
excluded_pair_keys <- unique(excluded_journals$journal_pair_key)
excluded_article_pids <- unique(excluded_articles$pid)

metadata <- articles |>
  dplyr::mutate(
    journal_pair_key = paste(title_key_for_exclusion, issn_key_for_exclusion, sep = "||"),
    journal_excluded = title_key_for_exclusion %in% excluded_title_keys |
      issn_key_for_exclusion %in% excluded_issn_keys |
      journal_pair_key %in% excluded_pair_keys,
    article_pid_excluded = pid %in% excluded_article_pids,
    abstract_pt = dplyr::coalesce(abstract_pt, ""),
    abstract_en = dplyr::coalesce(abstract_en, ""),
    abstract_char_count_expected = pmax(nchar(abstract_pt), nchar(abstract_en)),
    abstract_word_count_expected = pmax(word_count(abstract_pt), word_count(abstract_en))
  )

eligible <- metadata |>
  dplyr::filter(
    document_type == "research-article",
    !journal_excluded,
    !article_pid_excluded
  ) |>
  dplyr::mutate(eligible_order = dplyr::row_number()) |>
  dplyr::select(
    eligible_order,
    pid,
    title,
    title_en,
    authors,
    year,
    year_num,
    issn,
    journal_title,
    abstract_char_count_expected,
    abstract_word_count_expected,
    doi,
    document_type,
    language,
    journal_excluded,
    article_pid_excluded
  )

expected_n <- nrow(eligible)

if (!file.exists(paths$fulltext)) {
  stop("Arquivo processado ausente: ", paths$fulltext)
}

fulltext_raw <- readr::read_csv(
  paths$fulltext,
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE
)
required_processed_cols <- c(
  "pid",
  "title",
  "title_en",
  "authors",
  "year",
  "issn",
  "journal_title",
  "doi",
  "document_type",
  "language",
  "body_text",
  "body_char_count",
  "body_word_count",
  "source_method",
  "source_url",
  "input_path",
  "input_hash",
  "retrieved_at",
  "abstract_char_count",
  "reference_tail_ratio",
  "validation_flags"
)
missing_processed_cols <- setdiff(required_processed_cols, names(fulltext_raw))
for (col in missing_processed_cols) {
  fulltext_raw[[col]] <- NA_character_
}

fulltext <- fulltext_raw |>
  dplyr::mutate(
    body_text = dplyr::coalesce(as.character(body_text), ""),
    source_method = dplyr::coalesce(as.character(source_method), ""),
    source_url = dplyr::coalesce(as.character(source_url), ""),
    input_path = dplyr::coalesce(as.character(input_path), ""),
    input_hash = dplyr::coalesce(as.character(input_hash), ""),
    retrieved_at = dplyr::coalesce(as.character(retrieved_at), ""),
    validation_flags = dplyr::coalesce(as.character(validation_flags), ""),
    body_char_count = as.integer(body_char_count),
    body_word_count = as.integer(body_word_count),
    abstract_char_count = as.integer(abstract_char_count),
    reference_tail_ratio = as.numeric(reference_tail_ratio)
  )

eligible_duplicate_pids <- eligible |>
  dplyr::count(pid, name = "n") |>
  dplyr::filter(n > 1) |>
  dplyr::pull(pid)

processed_duplicate_pids <- fulltext |>
  dplyr::count(pid, name = "n") |>
  dplyr::filter(n > 1) |>
  dplyr::pull(pid)

processed_extra_pids <- setdiff(fulltext$pid, eligible$pid)
processed_missing_pids <- setdiff(eligible$pid, fulltext$pid)

processed_unique_names <- names(which(table(fulltext$pid) == 1))

duplicate_input_hashes <- fulltext |>
  dplyr::filter(!is.na(input_hash), input_hash != "") |>
  dplyr::distinct(pid, input_hash) |>
  dplyr::add_count(input_hash, name = "input_hash_pid_count") |>
  dplyr::filter(input_hash_pid_count > 1)

duplicate_body_hashes <- fulltext |>
  dplyr::mutate(body_hash = text_sha256(body_text)) |>
  dplyr::filter(body_text != "") |>
  dplyr::distinct(pid, body_hash) |>
  dplyr::add_count(body_hash, name = "body_hash_pid_count") |>
  dplyr::filter(body_hash_pid_count > 1)

duplicate_input_hash_pids <- unique(duplicate_input_hashes$pid)
duplicate_body_hash_pids <- unique(duplicate_body_hashes$pid)

inventory <- eligible |>
  dplyr::left_join(
    fulltext |>
      dplyr::select(
        pid,
        body_text,
        body_char_count,
        body_word_count,
        source_method,
        source_url,
        input_path,
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
    pid_is_unique_in_processed = pid %in% processed_unique_names,
    body_text_nonempty = present_in_processed & stringr::str_squish(body_text) != "",
    body_hash = text_sha256(body_text),
    body_char_count_recomputed = nchar(dplyr::coalesce(body_text, "")),
    body_word_count_recomputed = word_count(body_text),
    body_block_count = body_block_count(body_text),
    body_char_count_matches = present_in_processed & body_char_count == body_char_count_recomputed,
    body_word_count_matches = present_in_processed & body_word_count == body_word_count_recomputed,
    source_method_ok = source_method %in% c(
      "articlemeta_fulltexts_html",
      "citation_xml_body",
      "pdf_text_extraction"
    ),
    source_url_ok = !is.na(source_url) & stringr::str_squish(source_url) != "",
    input_hash_format_ok = !is.na(input_hash) & stringr::str_detect(input_hash, "^[a-f0-9]{64}$"),
    retrieved_at_ok = !is.na(retrieved_at) &
      stringr::str_detect(retrieved_at, "^\\d{4}-\\d{2}-\\d{2}T"),
    input_path_corpus_ok = !is.na(input_path) &
      stringr::str_detect(input_path, "^data/raw/fulltext_corpus/(html|xml|pdf)/"),
    input_path_abs = dplyr::if_else(
      input_path_corpus_ok,
      file.path(project_dir, input_path),
      NA_character_
    )
  )

inventory$raw_input_exists <- vapply(
  inventory$input_path_abs,
  function(path) !is.na(path) && file.exists(path),
  logical(1)
)
inventory$input_hash_recomputed <- vapply(inventory$input_path_abs, file_sha256, character(1))

inventory <- inventory |>
  dplyr::mutate(
    input_hash_matches_raw = present_in_processed &
      raw_input_exists &
      input_hash_format_ok &
      input_hash == input_hash_recomputed,
    input_hash_unique_across_pids = !present_in_processed |
      !(pid %in% duplicate_input_hash_pids),
    body_hash_unique_across_pids = !present_in_processed |
      !(pid %in% duplicate_body_hash_pids),
    source_provenance_ok = present_in_processed &
      source_method_ok &
      source_url_ok &
      input_path_corpus_ok &
      input_hash_matches_raw &
      retrieved_at_ok,
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
    logical_year_ok = !is.na(year_num) & year_num >= 2005L & year_num <= 2025L,
    logical_document_type_ok = document_type == "research-article",
    logical_exclusion_ok = !journal_excluded & !article_pid_excluded,
    no_gold_path = !stringr::str_detect(dplyr::coalesce(input_path, ""), "fulltext_gold"),
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
      body_not_frontmatter &
        input_hash_unique_across_pids &
        body_hash_unique_across_pids &
      logical_year_ok &
        logical_document_type_ok &
        logical_exclusion_ok &
        no_gold_path,
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
        reference_tail_ratio_recomputed,
        input_hash_unique_across_pids,
        body_hash_unique_across_pids,
        logical_year_ok,
        logical_document_type_ok,
        logical_exclusion_ok,
        no_gold_path
      ),
      function(present, unique_pid, nonempty, chars_match, words_match,
               provenance_ok, minimum_size, min_blocks, larger_than_abstract,
               starts_refs, starts_front, ref_ratio, input_hash_unique,
               body_hash_unique, year_ok, document_type_ok, exclusion_ok, no_gold) {
        collapse_flags(
          if (!present) "missing_pid",
          if (present && !isTRUE(unique_pid)) "duplicate_pid",
          if (present && !isTRUE(nonempty)) "empty_body",
          if (present && !isTRUE(chars_match)) "body_char_count_mismatch",
          if (present && !isTRUE(words_match)) "body_word_count_mismatch",
          if (present && !isTRUE(provenance_ok)) "missing_or_invalid_provenance",
          if (present && !isTRUE(minimum_size)) "too_short_for_body",
          if (present && !isTRUE(min_blocks)) "too_few_body_blocks",
          if (present && !isTRUE(larger_than_abstract)) "not_substantially_larger_than_abstract",
          if (present && isTRUE(starts_front)) "starts_with_front_matter",
          if (present && isTRUE(starts_refs)) "starts_with_references",
          if (present && !is.na(ref_ratio) && ref_ratio > 0.45) "references_majority",
          if (present && !isTRUE(input_hash_unique)) "duplicate_input_hash_across_pids",
          if (present && !isTRUE(body_hash_unique)) "duplicate_body_hash_across_pids",
          if (!isTRUE(year_ok)) "year_outside_2005_2025_or_missing",
          if (!isTRUE(document_type_ok)) "document_type_not_research_article",
          if (!isTRUE(exclusion_ok)) "excluded_record_in_eligible_manifest",
          if (!isTRUE(no_gold)) "input_path_points_to_fulltext_gold"
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

invalid_year_pids <- eligible |>
  dplyr::filter(is.na(year_num) | year_num < 2005L | year_num > 2025L) |>
  dplyr::pull(pid)

global_failures <- c(
  if (expected_n != expected_plan_n) {
    paste0("eligible_row_count_not_", expected_plan_n, ": ", expected_n)
  },
  if (dplyr::n_distinct(eligible$pid) != expected_n) {
    paste0("eligible_unique_pid_count_mismatch: ", dplyr::n_distinct(eligible$pid), "/", expected_n)
  },
  if (length(eligible_duplicate_pids) > 0) {
    paste0("eligible_duplicate_pids: ", paste(eligible_duplicate_pids, collapse = ", "))
  },
  if (length(invalid_year_pids) > 0) {
    paste0("eligible_year_outside_2005_2025: ", paste(invalid_year_pids, collapse = ", "))
  },
  if (length(missing_processed_cols) > 0) {
    paste0("processed_missing_required_columns: ", paste(missing_processed_cols, collapse = ", "))
  },
  if (nrow(fulltext) != expected_n) paste0("processed_row_count_not_", expected_n, ": ", nrow(fulltext)),
  if (dplyr::n_distinct(fulltext$pid) != expected_n) {
    paste0("processed_unique_pid_count_not_", expected_n, ": ", dplyr::n_distinct(fulltext$pid))
  },
  if (length(processed_duplicate_pids) > 0) {
    paste0("processed_duplicate_pids: ", paste(processed_duplicate_pids, collapse = ", "))
  },
  if (length(processed_extra_pids) > 0) {
    paste0("processed_extra_pids: ", paste(head(processed_extra_pids, 50), collapse = ", "))
  },
  if (length(processed_missing_pids) > 0) {
    paste0("processed_missing_pids: ", paste(head(processed_missing_pids, 50), collapse = ", "))
  },
  if (nrow(duplicate_input_hashes) > 0) {
    paste0(
      "duplicate_input_hash_across_pids: ",
      paste(head(unique(duplicate_input_hashes$pid), 50), collapse = ", ")
    )
  },
  if (nrow(duplicate_body_hashes) > 0) {
    paste0(
      "duplicate_body_hash_across_pids: ",
      paste(head(unique(duplicate_body_hashes$pid), 50), collapse = ", ")
    )
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
      eligible_order,
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
      input_path,
      input_hash,
      input_hash_recomputed,
      body_hash,
      retrieved_at,
      body_char_count = body_char_count_recomputed,
      body_word_count = body_word_count_recomputed,
      abstract_char_count_expected,
      reference_tail_ratio = reference_tail_ratio_recomputed,
      present_in_processed,
      pid_is_unique_in_processed,
      body_text_nonempty,
      source_provenance_ok,
      input_path_corpus_ok,
      raw_input_exists,
      input_hash_matches_raw,
      input_hash_unique_across_pids,
      body_hash_unique_across_pids,
      body_block_count,
      body_minimum_size_ok,
      body_has_min_blocks,
      body_substantially_larger_than_abstract,
      references_not_majority,
      body_not_frontmatter,
      logical_year_ok,
      logical_document_type_ok,
      logical_exclusion_ok,
      no_gold_path,
      validation_status,
      suspect_flags,
      nonblocking_flags
    ),
  paths$inventory
)

failure_lines <- if (length(global_failures) == 0 && nrow(failures) == 0) {
  "None. All eligible corpus PIDs have validated body text."
} else {
  c(
    if (length(global_failures) > 0) paste0("- ", global_failures),
    if (nrow(failures) > 0) {
      paste0(
        "- `", head(failures$pid, 100), "` (",
        head(failures$journal_title, 100), ", ", head(failures$year, 100),
        "): ", head(failures$suspect_flags, 100)
      )
    },
    if (nrow(failures) > 100) {
      paste0("- ... ", nrow(failures) - 100, " additional failures in `", paths$inventory, "`")
    }
  )
}

suspect_lines <- if (nrow(suspects) == 0) {
  "No nonblocking suspicious cases under the current thresholds."
} else {
  c(
    paste0(
      "- `", head(suspects$pid, 100), "`: ",
      head(suspects$body_word_count_recomputed, 100),
      " words via ", head(suspects$source_method, 100),
      " (", head(suspects$nonblocking_flags, 100), ")"
    ),
    if (nrow(suspects) > 100) {
      paste0("- ... ", nrow(suspects) - 100, " additional suspicious cases in `", paths$inventory, "`")
    }
  )
}

report_lines <- c(
  "# Fulltext corpus recovery report",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Summary",
  "",
  paste0("- Expected eligible PIDs from plan: ", expected_plan_n),
  paste0("- Eligible PIDs rebuilt from ledgers: ", expected_n),
  paste0("- Rows in processed corpus fulltext CSV: ", nrow(fulltext)),
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
  failure_lines,
  "",
  "## Nonblocking suspicious cases",
  "",
  suspect_lines,
  "",
  "## Validation rules",
  "",
  paste0("- All ", expected_n, " eligible PIDs rebuilt from raw metadata and exclusion ledgers must be present."),
  "- PIDs must be unique in the processed fulltext CSV.",
  "- `document_type` must be exactly `research-article`; excluded journals and article PIDs must be absent.",
  "- Publication year must be compatible with the 2005-2025 corpus window.",
  "- `body_text` must be non-empty and at least 3,000 characters / 600 words.",
  "- Provenance fields (`source_method`, `source_url`, `input_path`, `input_hash`, `retrieved_at`) are mandatory.",
  "- `input_path` must point to `data/raw/fulltext_corpus/`, and `input_hash` must match the preserved raw file.",
  "- `input_hash` and `body_hash` must not be reused by multiple PIDs.",
  "- `body_text` must contain at least four text blocks and cannot start with abstract/keyword front matter.",
  "- `body_text` must be substantially larger than the longest available abstract.",
  "- Text starting with references or composed mostly of a reference tail fails.",
  "- Abstract, metadata, keywords and references are not accepted as body substitutes.",
  "- Corpus validation fails if any processed row points to `fulltext_gold`.",
  "",
  "## Outputs",
  "",
  paste0("- Processed body text: `", paths$fulltext, "`"),
  paste0("- Inventory: `", paths$inventory, "`")
)

writeLines(report_lines, paths$report, useBytes = TRUE)

if (length(global_failures) > 0 || nrow(failures) > 0) {
  failure_msg <- paste(c(global_failures, head(failures$pid, 100)), collapse = "; ")
  stop("Fulltext corpus validation failed: ", failure_msg)
}

message("Fulltext corpus validation passed: ", expected_n, "/", expected_n, " bodies.")
