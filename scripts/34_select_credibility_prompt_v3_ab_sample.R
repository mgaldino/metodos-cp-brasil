## 34_select_credibility_prompt_v3_ab_sample.R
## Seleciona amostra estratificada congelada para A/B de esforco de raciocinio.

options(scipen = 999)

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(stringr)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- normalizePath(".", mustWork = TRUE)

paths <- list(
  baseline_csv = file.path(
    project_dir,
    "data", "processed", "credibility_prompt_v3_integral_reading",
    "full_corpus", "combined", "classifications_integral_reading.csv"
  ),
  full_manifest = file.path(
    project_dir,
    "data", "processed", "credibility_prompt_v3_full_corpus", "full_corpus_manifest.csv"
  ),
  out_manifest = file.path(
    project_dir,
    "data", "processed", "credibility_prompt_v3_full_corpus",
    "batch_manifests", "ab_gpt55_high_50.csv"
  ),
  out_report = file.path(
    project_dir,
    "quality_reports", "credibility_prompt_v3_ab_gpt55_high_selection.md"
  )
)

dir.create(dirname(paths$out_manifest), showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(paths$out_report), showWarnings = FALSE, recursive = TRUE)

quotas <- c(
  positive_or_diagnostic_method = 5L,
  credibility_screen = 10L,
  tough_call = 15L,
  quant_torreblanca_no_positive_method = 10L,
  qualitative_or_non_empirical = 10L
)

priority_levels <- names(quotas)

strict_design_methods <- c(
  "experiment_field",
  "experiment_survey",
  "experiment_lab",
  "experiment_list",
  "difference_in_differences",
  "event_study",
  "instrumental_variables",
  "regression_discontinuity",
  "regression_kink",
  "synthetic_control",
  "synthetic_difference_in_differences",
  "matching_or_weighting",
  "dag_or_formal_causal_graph",
  "doubly_robust",
  "causal_trees_or_forests",
  "causal_discovery",
  "other_modern_causal_method"
)

diagnostic_methods <- c(
  "observational_regression_with_causal_claim_no_design",
  "fixed_effects_causal_panel_claim",
  "none_detected"
)

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

assert_unique <- function(data, key, label) {
  duplicates <- data[[key]][duplicated(data[[key]])]
  if (length(duplicates) > 0) {
    stop(label, " tem PIDs duplicados: ", paste(unique(duplicates), collapse = ", "))
  }
}

parse_bool <- function(x) {
  if (is.logical(x)) {
    return(x)
  }
  value <- stringr::str_to_upper(stringr::str_trim(dplyr::coalesce(as.character(x), "")))
  dplyr::case_when(
    value == "TRUE" ~ TRUE,
    value == "FALSE" ~ FALSE,
    TRUE ~ NA
  )
}

parse_method_types <- function(x) {
  if (is.na(x) || stringr::str_trim(x) == "") {
    return(character())
  }
  parsed <- tryCatch(jsonlite::fromJSON(x), error = function(e) character())
  as.character(parsed)
}

has_any_method <- function(methods, targets) {
  vapply(methods, function(x) any(x %in% targets), logical(1))
}

candidate_strata_text <- function(method, screen, tough, quant, qual_none) {
  labels <- character()
  if (isTRUE(method)) labels <- c(labels, "positive_or_diagnostic_method")
  if (isTRUE(screen)) labels <- c(labels, "credibility_screen")
  if (isTRUE(tough)) labels <- c(labels, "tough_call")
  if (isTRUE(quant)) labels <- c(labels, "quant_torreblanca_no_positive_method")
  if (isTRUE(qual_none)) labels <- c(labels, "qualitative_or_non_empirical")
  if (length(labels) == 0) return(NA_character_)
  paste(labels, collapse = "; ")
}

selection_hash <- function(pid, stratum) {
  vapply(
    paste(pid, stratum, "ab_gpt55_high_20260616", sep = "||"),
    digest::digest,
    character(1),
    algo = "sha256",
    serialize = FALSE
  )
}

format_cell <- function(x) {
  x <- dplyr::coalesce(as.character(x), "")
  x <- stringr::str_replace_all(x, "\\|", "\\\\|")
  x <- stringr::str_replace_all(x, "[\r\n]+", " ")
  stringr::str_squish(x)
}

md_table <- function(data) {
  if (nrow(data) == 0) {
    return("_Nenhum caso._")
  }
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

baseline <- read_csv_utf8(paths$baseline_csv) |>
  dplyr::mutate(
    is_empirical_paper = parse_bool(is_empirical_paper),
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    is_empirical_qual_paper = parse_bool(is_empirical_qual_paper),
    credibility_revolution_screen_applicable = parse_bool(credibility_revolution_screen_applicable),
    credibility_revolution_method_present = parse_bool(credibility_revolution_method_present),
    tough_call = parse_bool(tough_call),
    method_type_list = lapply(credibility_revolution_method_type, parse_method_types),
    has_positive_method_type = has_any_method(method_type_list, strict_design_methods),
    has_diagnostic_method_type = has_any_method(method_type_list, diagnostic_methods),
    candidate_method = has_positive_method_type |
      has_diagnostic_method_type |
      dplyr::coalesce(credibility_revolution_method_present, FALSE),
    candidate_screen = dplyr::coalesce(credibility_revolution_screen_applicable, FALSE),
    candidate_tough = dplyr::coalesce(tough_call, FALSE),
    candidate_quant_no_positive = dplyr::coalesce(is_empirical_quant_paper_torreblanca, FALSE) &
      !dplyr::coalesce(credibility_revolution_method_present, FALSE),
    candidate_qual_none = dplyr::coalesce(is_empirical_qual_paper, FALSE) |
      dplyr::coalesce(!is_empirical_paper, FALSE) |
      empirical_evidence_type %in% c("none", "qualitative_only", "unclear"),
    raw_candidate_strata = mapply(
      candidate_strata_text,
      candidate_method,
      candidate_screen,
      candidate_tough,
      candidate_quant_no_positive,
      candidate_qual_none,
      USE.NAMES = FALSE
    ),
    raw_candidate_n = stringr::str_count(dplyr::coalesce(raw_candidate_strata, ""), ";") +
      dplyr::if_else(is.na(raw_candidate_strata), 0L, 1L)
  )

manifest <- read_csv_utf8(paths$full_manifest)

assert_unique(baseline, "pid", "Baseline xhigh")
assert_unique(manifest, "pid", "Manifesto completo")

eligible <- baseline |>
  dplyr::inner_join(
    manifest |>
      dplyr::select(
        pid,
        eligible_order,
        year,
        language,
        task_packet_file,
        manifest_input_text_hash = input_text_hash
      ),
    by = "pid"
  ) |>
  dplyr::filter(!is.na(raw_candidate_strata))

hash_mismatches <- eligible |>
  dplyr::filter(input_text_hash != manifest_input_text_hash) |>
  dplyr::select(pid, input_text_hash, manifest_input_text_hash)

if (nrow(hash_mismatches) > 0) {
  stop("Hash do texto diverge entre baseline e manifesto para PIDs: ", paste(hash_mismatches$pid, collapse = ", "))
}

missing_task_packets <- eligible |>
  dplyr::mutate(task_packet_exists = file.exists(file.path(project_dir, task_packet_file))) |>
  dplyr::filter(!task_packet_exists) |>
  dplyr::select(pid, task_packet_file)

if (nrow(missing_task_packets) > 0) {
  stop("Task packets ausentes para PIDs: ", paste(missing_task_packets$pid, collapse = ", "))
}

candidate_columns <- c(
  positive_or_diagnostic_method = "candidate_method",
  credibility_screen = "candidate_screen",
  tough_call = "candidate_tough",
  quant_torreblanca_no_positive_method = "candidate_quant_no_positive",
  qualitative_or_non_empirical = "candidate_qual_none"
)

selected_list <- list()
selected_pids <- character()

for (stratum in priority_levels) {
  candidate_column <- candidate_columns[[stratum]]
  picked <- eligible |>
    dplyr::filter(.data[[candidate_column]], !pid %in% selected_pids) |>
    dplyr::mutate(
      assigned_stratum = stratum,
      selection_hash = selection_hash(pid, stratum)
    ) |>
    dplyr::arrange(selection_hash, pid) |>
    dplyr::slice_head(n = quotas[[stratum]])
  selected_list[[stratum]] <- picked
  selected_pids <- c(selected_pids, picked$pid)
}

selected_by_quota <- dplyr::bind_rows(selected_list)

if (nrow(selected_by_quota) < sum(quotas)) {
  fill_needed <- sum(quotas) - nrow(selected_by_quota)
  fill <- eligible |>
    dplyr::filter(!pid %in% selected_by_quota$pid) |>
    dplyr::mutate(
      assigned_stratum = "quota_fill",
      selection_hash = selection_hash(pid, assigned_stratum)
    ) |>
    dplyr::arrange(selection_hash, pid) |>
    dplyr::slice_head(n = fill_needed)
  selected_by_quota <- dplyr::bind_rows(selected_by_quota, fill)
}

selected <- selected_by_quota |>
  dplyr::mutate(
    assigned_stratum = factor(assigned_stratum, levels = priority_levels),
    selection_order = dplyr::row_number()
  ) |>
  dplyr::arrange(assigned_stratum, selection_hash, pid) |>
  dplyr::mutate(selection_order = dplyr::row_number())

if (nrow(selected) != sum(quotas)) {
  stop("Seleção não atingiu N esperado: ", nrow(selected), " vs ", sum(quotas))
}
if (anyDuplicated(selected$pid) > 0) {
  stop("Seleção contém PIDs duplicados.")
}

quota_check <- selected |>
  dplyr::count(assigned_stratum, name = "n") |>
  dplyr::mutate(target_n = quotas[as.character(assigned_stratum)])

quota_mismatches <- quota_check |>
  dplyr::filter(n != target_n)

if (nrow(quota_mismatches) > 0) {
  stop("Quotas não batem com alvos: ", paste(quota_mismatches$assigned_stratum, collapse = ", "))
}

selected_manifest <- selected |>
  dplyr::select(pid, selection_order) |>
  dplyr::left_join(manifest, by = "pid") |>
  dplyr::arrange(selection_order) |>
  dplyr::select(-selection_order)

readr::write_csv(selected_manifest, paths$out_manifest, na = "")

stratum_distribution <- selected |>
  dplyr::count(assigned_stratum, name = "n") |>
  dplyr::mutate(target_n = quotas[as.character(assigned_stratum)]) |>
  dplyr::select(assigned_stratum, n, target_n)

candidate_pool_distribution <- eligible |>
  dplyr::summarise(
    positive_or_diagnostic_method = sum(candidate_method, na.rm = TRUE),
    credibility_screen = sum(candidate_screen, na.rm = TRUE),
    tough_call = sum(candidate_tough, na.rm = TRUE),
    quant_torreblanca_no_positive_method = sum(candidate_quant_no_positive, na.rm = TRUE),
    qualitative_or_non_empirical = sum(candidate_qual_none, na.rm = TRUE)
  ) |>
  tidyr::pivot_longer(
    cols = dplyr::everything(),
    names_to = "candidate_stratum",
    values_to = "raw_candidate_pool_n"
  ) |>
  dplyr::mutate(candidate_stratum = factor(candidate_stratum, levels = priority_levels)) |>
  dplyr::arrange(candidate_stratum)

selected_pid_table <- selected |>
  dplyr::arrange(selection_order) |>
  dplyr::select(
    selection_order,
    pid,
    assigned_stratum,
    raw_candidate_strata,
    title,
    journal_title,
    year
  )

overlap_table <- selected |>
  dplyr::filter(raw_candidate_n > 1) |>
  dplyr::arrange(selection_order) |>
  dplyr::select(selection_order, pid, assigned_stratum, raw_candidate_strata)

report_lines <- c(
  "# Seleção A/B gpt-5.5 high vs xhigh",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Escopo",
  "",
  paste0("- Baseline xhigh: `", paths$baseline_csv, "`"),
  paste0("- Manifesto completo: `", paths$full_manifest, "`"),
  paste0("- Manifesto congelado A/B: `", paths$out_manifest, "`"),
  paste0("- N total selecionado: ", nrow(selected)),
  "- Validações: PIDs únicos, task packets existentes, hash `input_text_hash` idêntico entre baseline e manifesto, N=50 e quotas exatas.",
  "",
  "A seleção usa apenas artigos já classificados no corpus principal por leitura integral. Os estratos são escolhidos sequencialmente na ordem de prioridade: método positivo/diagnóstico, screen de credibilidade, tough call, quantitativo Torreblanca sem método positivo, qualitativo ou não empírico. Um PID já escolhido em estrato prioritário não pode ser escolhido novamente. Como os critérios se sobrepõem fortemente, esta interpretação preserva as quotas alvo sem duplicar PIDs.",
  "",
  "## Tabela 1. Distribuição por estrato selecionado",
  "",
  md_table(stratum_distribution),
  "",
  "## Tabela 2. Tamanho do pool candidato bruto por critério",
  "",
  md_table(candidate_pool_distribution),
  "",
  "## Sobreposição entre critérios",
  "",
  if (nrow(overlap_table) > 0) {
    paste0("Houve sobreposição bruta entre critérios em ", nrow(overlap_table), " dos ", nrow(selected), " PIDs selecionados. A coluna `assigned_stratum` mostra o estrato final depois da prioridade.")
  } else {
    "Não houve sobreposição bruta entre critérios nos PIDs selecionados."
  },
  "",
  "## Tabela 3. PIDs selecionados com sobreposição bruta",
  "",
  md_table(overlap_table),
  "",
  "## Tabela 4. PIDs selecionados",
  "",
  md_table(selected_pid_table),
  "",
  "## Reprodutibilidade",
  "",
  "A ordenação dentro de cada estrato é determinística: SHA-256 de `pid`, estrato e a semente textual `ab_gpt55_high_20260616`. Não há sorteio dependente de estado global do R."
  ,
  "",
  "Comando de reprodução:",
  "",
  "`LC_ALL=pt_BR.UTF-8 Rscript --vanilla scripts/34_select_credibility_prompt_v3_ab_sample.R`"
)

write_utf8_lines(report_lines, paths$out_report)

cat("Manifesto A/B escrito em:", paths$out_manifest, "\n")
cat("Relatório de seleção escrito em:", paths$out_report, "\n")
cat("N selecionado:", nrow(selected), "\n")
