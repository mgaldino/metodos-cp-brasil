## 31_prepare_credibility_prompt_v3_full_corpus_manifest.R
## Prepara manifest e task packets para classificar o corpus completo restante.

options(scipen = 999)

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(stringr)
})

args <- commandArgs(trailingOnly = TRUE)
include_pilot <- "--include-pilot" %in% args

project_dir <- normalizePath(".", mustWork = TRUE)

paths <- list(
  corpus_texts = file.path(project_dir, "data", "processed", "fulltext_corpus", "article_texts_corpus.csv"),
  corpus_inventory = file.path(project_dir, "quality_reports", "fulltext_corpus_inventory.csv"),
  pilot_manifest = file.path(project_dir, "data", "processed", "full_classification_pilot_v2", "pilot_manifest.csv"),
  excluded_journals = file.path(project_dir, "data", "processed", "excluded_journals.csv"),
  excluded_articles = file.path(project_dir, "data", "processed", "excluded_articles.csv"),
  out_dir = file.path(project_dir, "data", "processed", "credibility_prompt_v3_full_corpus"),
  packets_dir = file.path(project_dir, "data", "processed", "credibility_prompt_v3_full_corpus", "task_packets"),
  manifest = file.path(project_dir, "data", "processed", "credibility_prompt_v3_full_corpus", "full_corpus_manifest.csv"),
  metadata = file.path(project_dir, "data", "processed", "credibility_prompt_v3_full_corpus", "full_corpus_manifest_metadata.json"),
  summary = file.path(project_dir, "quality_reports", "credibility_prompt_v3_full_corpus_manifest_summary.md")
)

dir.create(paths$out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(paths$packets_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(paths$summary), showWarnings = FALSE, recursive = TRUE)

read_csv_utf8 <- function(path) {
  if (!file.exists(path)) {
    stop("Arquivo ausente: ", path)
  }
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    locale = readr::locale(encoding = "UTF-8")
  )
}

relative_path <- function(path) {
  stringr::str_remove(
    normalizePath(path, mustWork = FALSE),
    paste0("^", stringr::fixed(project_dir), "/?")
  )
}

decode_angle_byte_sequences <- function(line) {
  matches <- gregexpr("(<[0-9A-Fa-f]{2}>)+", line, perl = TRUE)[[1]]
  if (matches[[1]] == -1) {
    return(line)
  }
  lengths <- attr(matches, "match.length")
  for (i in rev(seq_along(matches))) {
    token <- substr(line, matches[[i]], matches[[i]] + lengths[[i]] - 1)
    hex <- regmatches(token, gregexpr("[0-9A-Fa-f]{2}", token, perl = TRUE))[[1]]
    decoded <- tryCatch({
      value <- rawToChar(as.raw(strtoi(hex, base = 16L)))
      Encoding(value) <- "UTF-8"
      value
    }, error = function(e) token)
    line <- paste0(
      substr(line, 1, matches[[i]] - 1),
      decoded,
      substr(line, matches[[i]] + lengths[[i]], nchar(line))
    )
  }
  line
}

write_utf8_lines <- function(lines, path, decode_byte_markers = FALSE) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  for (line in lines) {
    line <- enc2utf8(dplyr::coalesce(as.character(line), ""))
    if (decode_byte_markers) {
      line <- decode_angle_byte_sequences(line)
    }
    writeBin(charToRaw(line), con)
    writeBin(charToRaw("\n"), con)
  }
}

sha256_text <- function(x) {
  vapply(enc2utf8(x), digest::digest, character(1), algo = "sha256", serialize = FALSE)
}

sha256_text_inventory_style <- function(x) {
  vapply(enc2utf8(x), digest::digest, character(1), algo = "sha256")
}

parse_bool <- function(x) {
  if (is.logical(x)) {
    return(dplyr::coalesce(x, FALSE))
  }
  stringr::str_to_upper(stringr::str_trim(dplyr::coalesce(as.character(x), ""))) == "TRUE"
}

md_table <- function(data) {
  if (nrow(data) == 0) {
    return("_Nenhum caso._")
  }
  header <- paste(names(data), collapse = " | ")
  separator <- paste(rep("---", ncol(data)), collapse = " | ")
  rows <- apply(data, 1, function(row) paste(row, collapse = " | "))
  paste(c(header, separator, rows), collapse = "\n")
}

write_task_packet <- function(row) {
  packet_path <- file.path(paths$packets_dir, paste0(row$eligible_order, "_", row$pid, ".md"))
  packet_lines <- c(
    paste0("# Article task packet full corpus: ", row$pid),
    "",
    "This packet is derived from `data/processed/fulltext_corpus/article_texts_corpus.csv`.",
    "Use only the `body_text` below plus the metadata in this packet for substantive classification.",
    "",
    "## Metadata",
    "",
    paste0("- eligible_order: ", row$eligible_order),
    paste0("- pid: ", row$pid),
    paste0("- title: ", row$title),
    paste0("- title_en: ", dplyr::coalesce(row$title_en, "")),
    paste0("- authors: ", dplyr::coalesce(row$authors, "")),
    paste0("- year: ", row$year),
    paste0("- journal_title: ", row$journal_title),
    paste0("- language: ", row$language),
    paste0("- doi: ", dplyr::coalesce(row$doi, "")),
    paste0("- canonical_source_file: ", relative_path(paths$corpus_texts)),
    "- canonical_source_column: body_text",
    paste0("- input_text_hash: ", row$input_text_hash),
    "",
    "## Body Text",
    "",
    row$body_text
  )
  write_utf8_lines(packet_lines, packet_path)
  relative_path(packet_path)
}

corpus <- read_csv_utf8(paths$corpus_texts)
inventory <- read_csv_utf8(paths$corpus_inventory)
pilot_manifest <- read_csv_utf8(paths$pilot_manifest)
excluded_journals <- read_csv_utf8(paths$excluded_journals) |>
  dplyr::filter(parse_bool(exclude_from_analysis)) |>
  dplyr::mutate(
    journal_title = stringr::str_squish(journal_title),
    issn = stringr::str_squish(dplyr::coalesce(as.character(issn), "")),
    exclusion_key = paste(journal_title, issn, sep = "||")
  ) |>
  dplyr::distinct(journal_title, issn, exclusion_key, .keep_all = TRUE)

excluded_articles <- read_csv_utf8(paths$excluded_articles) |>
  dplyr::filter(parse_bool(exclude_from_analysis)) |>
  dplyr::distinct(pid, .keep_all = TRUE)

required_corpus_cols <- c(
  "pid", "title", "authors", "year", "issn", "journal_title", "language",
  "body_text", "body_char_count", "body_word_count", "source_method",
  "source_url", "input_hash", "retrieved_at", "abstract_char_count",
  "reference_tail_ratio", "validation_flags"
)

missing_corpus_cols <- setdiff(required_corpus_cols, names(corpus))
if (length(missing_corpus_cols) > 0) {
  stop("Colunas ausentes em article_texts_corpus.csv: ", paste(missing_corpus_cols, collapse = ", "))
}

pass_pids <- inventory |>
  dplyr::filter(validation_status == "PASS") |>
  dplyr::distinct(pid)

pass_inventory_hashes <- inventory |>
  dplyr::filter(validation_status == "PASS") |>
  dplyr::select(
    pid,
    inventory_input_hash = input_hash,
    inventory_input_hash_recomputed = input_hash_recomputed,
    inventory_body_hash = body_hash
  )

pilot_pids <- pilot_manifest |>
  dplyr::distinct(pid)

manifest_source <- corpus |>
  dplyr::semi_join(pass_pids, by = "pid") |>
  dplyr::left_join(pass_inventory_hashes, by = "pid") |>
  dplyr::mutate(
    body_text = enc2utf8(body_text),
    body_present = !is.na(body_text) & nzchar(stringr::str_trim(body_text)),
    input_text_hash = sha256_text(body_text),
    input_hash_matches_source = input_hash == inventory_input_hash &
      input_hash == inventory_input_hash_recomputed,
    body_hash_matches_inventory = sha256_text_inventory_style(body_text) == inventory_body_hash,
    excluded_pilot = pid %in% pilot_pids$pid,
    journal_exclusion_key = paste(
      stringr::str_squish(journal_title),
      stringr::str_squish(dplyr::coalesce(as.character(issn), "")),
      sep = "||"
    ),
    excluded_by_journal = journal_exclusion_key %in% excluded_journals$exclusion_key,
    excluded_by_article = pid %in% excluded_articles$pid
  )

if (!include_pilot) {
  manifest_source <- manifest_source |>
    dplyr::filter(!excluded_pilot)
}

scope_counts <- manifest_source |>
  dplyr::summarise(
    excluded_by_journal = sum(excluded_by_journal, na.rm = TRUE),
    excluded_by_article = sum(excluded_by_article, na.rm = TRUE)
  )

manifest_source <- manifest_source |>
  dplyr::filter(!excluded_by_journal, !excluded_by_article)

if (any(!manifest_source$body_present)) {
  missing_pids <- manifest_source |>
    dplyr::filter(!body_present) |>
    dplyr::pull(pid)
  stop("Body ausente para PIDs: ", paste(missing_pids, collapse = ", "))
}

if (anyDuplicated(manifest_source$pid) > 0) {
  stop("PIDs duplicados no manifest fonte.")
}

if (any(!manifest_source$input_hash_matches_source, na.rm = TRUE)) {
  bad_pids <- manifest_source |>
    dplyr::filter(!input_hash_matches_source) |>
    dplyr::pull(pid)
  stop("input_hash diverge do hash bruto validado no inventário para PIDs: ", paste(utils::head(bad_pids, 20), collapse = ", "))
}

if (any(!manifest_source$body_hash_matches_inventory, na.rm = TRUE)) {
  bad_pids <- manifest_source |>
    dplyr::filter(!body_hash_matches_inventory) |>
    dplyr::pull(pid)
  stop("Hash do body_text diverge do body_hash validado no inventário para PIDs: ", paste(utils::head(bad_pids, 20), collapse = ", "))
}

manifest <- manifest_source |>
  dplyr::mutate(lua_nova_last = journal_title == "Lua Nova: Revista de Cultura e Política") |>
  dplyr::arrange(lua_nova_last, journal_title, year, pid) |>
  dplyr::mutate(
    eligible_order = dplyr::row_number(),
    source_file = relative_path(paths$corpus_texts),
    source_file_exists = file.exists(paths$corpus_texts),
    source_column = "body_text",
    fulltext_validation_status = "PASS",
    pilot_exclusion_policy = if_else(include_pilot, "include_pilot_175", "exclude_pilot_175"),
    scope_exclusion_policy = "exclude_analysis_ledger_journals_and_articles",
    ordering_policy = "journal_year_pid_with_lua_nova_last"
  )

manifest$task_packet_file <- vapply(seq_len(nrow(manifest)), function(i) {
  write_task_packet(manifest[i, ])
}, character(1))

manifest_out <- manifest |>
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
    source_file,
    source_file_exists,
    source_column,
    task_packet_file,
    input_text_hash,
    input_hash,
    input_hash_matches_source,
    body_hash_matches_inventory,
    body_char_count,
    body_word_count,
    source_method,
    source_url,
    retrieved_at,
    abstract_char_count,
    reference_tail_ratio,
    validation_flags,
    fulltext_validation_status,
    pilot_exclusion_policy,
    scope_exclusion_policy,
    ordering_policy
  )

readr::write_csv(manifest_out, paths$manifest, na = "")

metadata <- list(
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  objective = "Manifest para classificacao credibility_prompt_v3 por leitura integral no corpus completo restante.",
  include_pilot_175 = include_pilot,
  canonical_body_source = relative_path(paths$corpus_texts),
  fulltext_inventory = relative_path(paths$corpus_inventory),
  pilot_manifest = relative_path(paths$pilot_manifest),
  excluded_journals = relative_path(paths$excluded_journals),
  excluded_articles = relative_path(paths$excluded_articles),
  n_articles = nrow(manifest_out),
  n_fulltext_pass = nrow(pass_pids),
  n_pilot_pids = nrow(pilot_pids),
  n_excluded_by_journal_after_pilot_filter = scope_counts$excluded_by_journal[[1]],
  n_excluded_by_article_after_pilot_filter = scope_counts$excluded_by_article[[1]],
  ordering_policy = "Lua Nova: Revista de Cultura e Política last; remaining journals sorted by journal_title, year, pid",
  manifest = relative_path(paths$manifest),
  task_packets = relative_path(paths$packets_dir)
)

jsonlite::write_json(metadata, paths$metadata, pretty = TRUE, auto_unbox = TRUE, null = "null")

journal_counts <- manifest_out |>
  dplyr::count(journal_title, name = "n") |>
  dplyr::arrange(dplyr::desc(n), journal_title)

report_lines <- c(
  "# Manifest do corpus completo restante para credibility_prompt_v3",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Síntese",
  "",
  paste0("- Artigos PASS no inventário de fulltext: ", nrow(pass_pids), "."),
  paste0("- PIDs do piloto excluídos por padrão: ", ifelse(include_pilot, 0, nrow(pilot_pids)), "."),
  paste0("- Artigos excluídos por periódico no ledger: ", scope_counts$excluded_by_journal[[1]], "."),
  paste0("- Artigos excluídos individualmente no ledger: ", scope_counts$excluded_by_article[[1]], "."),
  paste0("- Artigos no manifest gerado: ", nrow(manifest_out), "."),
  paste0("- Manifest: `", relative_path(paths$manifest), "`."),
  paste0("- Task packets: `", relative_path(paths$packets_dir), "/`."),
  "",
  "Regra de ordenação: `Lua Nova: Revista de Cultura e Política` fica no fim do manifest; os demais periódicos são ordenados por `journal_title`, `year` e `pid`.",
  "",
  "Este script não altera dados brutos nem o corpus processado. Ele apenas cria task packets derivados do `body_text` canônico para execução do classificador por leitura integral.",
  "",
  "## Tabela 1. Artigos por periódico no manifest",
  "",
  md_table(journal_counts)
)

write_utf8_lines(report_lines, paths$summary, decode_byte_markers = TRUE)

cat("Manifest escrito em:", paths$manifest, "\n")
cat("Task packets escritos em:", paths$packets_dir, "\n")
cat("Relatório escrito em:", paths$summary, "\n")
cat("N artigos:", nrow(manifest_out), "\n")
