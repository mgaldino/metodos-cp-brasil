## 28_build_integral_manual_audit_sheet.R
## Gera planilha reprodutível para auditoria manual do piloto v3 integral.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

args <- commandArgs(trailingOnly = FALSE)
script_arg <- args[stringr::str_detect(args, "^--file=")]
project_dir <- if (length(script_arg) > 0) {
  script_path <- stringr::str_remove(script_arg[[1]], "^--file=")
  normalizePath(file.path(dirname(normalizePath(script_path, mustWork = TRUE)), ".."), mustWork = TRUE)
} else {
  normalizePath(".", mustWork = TRUE)
}

audit_seed <- 20260613
tough_outside_screen_target <- 20
control_target <- 10

paths <- list(
  classifications = file.path(
    project_dir,
    "data", "processed", "credibility_prompt_v3_integral_reading",
    "pilot_175", "combined", "classifications_integral_reading.csv"
  ),
  manifest = file.path(
    project_dir,
    "data", "processed", "full_classification_pilot_v2", "pilot_manifest.csv"
  ),
  reading_logs_dir = file.path(
    project_dir,
    "data", "processed", "credibility_prompt_v3_integral_reading",
    "pilot_175", "reading_logs"
  ),
  classification_json_dir = file.path(
    project_dir,
    "data", "processed", "credibility_prompt_v3_integral_reading",
    "pilot_175", "classifications"
  ),
  audit_csv = file.path(
    project_dir,
    "quality_reports", "credibility_prompt_v3_integral_manual_audit_sample.csv"
  ),
  audit_report = file.path(
    project_dir,
    "quality_reports", "credibility_prompt_v3_integral_manual_audit_sample.md"
  )
)

parse_bool <- function(x) {
  value <- stringr::str_to_upper(stringr::str_trim(dplyr::coalesce(as.character(x), "")))
  dplyr::case_when(
    value == "TRUE" ~ TRUE,
    value == "FALSE" ~ FALSE,
    TRUE ~ NA
  )
}

empty_if_na <- function(x) {
  dplyr::coalesce(as.character(x), "")
}

bool_label <- function(x, missing_label = "NA_IN_SOURCE") {
  dplyr::case_when(
    x %in% TRUE ~ "TRUE",
    x %in% FALSE ~ "FALSE",
    TRUE ~ missing_label
  )
}

method_present_label <- function(method_present, screen_applicable) {
  dplyr::case_when(
    method_present %in% TRUE ~ "TRUE",
    method_present %in% FALSE ~ "FALSE",
    is.na(method_present) & screen_applicable %in% FALSE ~ "NOT_APPLICABLE_SCREEN_FALSE",
    is.na(method_present) & is.na(screen_applicable) ~ "NA_IN_SOURCE",
    TRUE ~ "NA_IN_SOURCE"
  )
}

make_doi_url <- function(doi) {
  doi_clean <- stringr::str_trim(dplyr::coalesce(as.character(doi), ""))
  dplyr::case_when(
    doi_clean == "" ~ "",
    stringr::str_detect(doi_clean, "^https?://") ~ doi_clean,
    TRUE ~ paste0("https://doi.org/", doi_clean)
  )
}

first_nonempty <- function(x, y) {
  dplyr::coalesce(na_if(stringr::str_trim(as.character(x)), ""), y)
}

sample_with_stratum_floor <- function(data, target_n, strata_cols, seed) {
  if (nrow(data) == 0 || target_n <= 0) {
    return(data[0, , drop = FALSE])
  }

  if (nrow(data) <= target_n) {
    return(
      data |>
        dplyr::mutate(sample_component = "all_available")
    )
  }

  set.seed(seed)

  randomized <- data |>
    dplyr::mutate(.sample_random_key = stats::runif(dplyr::n()))

  first_pass <- randomized |>
    dplyr::group_by(dplyr::across(dplyr::all_of(strata_cols))) |>
    dplyr::slice_min(.sample_random_key, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::mutate(sample_component = "stratum_floor")

  if (nrow(first_pass) >= target_n) {
    return(
      first_pass |>
        dplyr::slice_min(.sample_random_key, n = target_n, with_ties = FALSE) |>
        dplyr::select(-.sample_random_key)
    )
  }

  fill_n <- target_n - nrow(first_pass)

  fill <- randomized |>
    dplyr::anti_join(
      first_pass |> dplyr::select(pid),
      by = "pid"
    ) |>
    dplyr::slice_min(.sample_random_key, n = fill_n, with_ties = FALSE) |>
    dplyr::mutate(sample_component = "random_fill")

  dplyr::bind_rows(first_pass, fill) |>
    dplyr::select(-.sample_random_key)
}

selection_reason <- function(screen, method, tough, group) {
  reasons <- character()
  if (isTRUE(screen)) {
    reasons <- c(reasons, "screen_applicable")
  }
  if (isTRUE(method)) {
    reasons <- c(reasons, "method_present")
  }
  if (isTRUE(tough) && group == "2_tough_outside_screen_sample") {
    reasons <- c(reasons, "tough_call_outside_screen_sample")
  }
  if (group == "3_non_tough_control_sample") {
    reasons <- c(reasons, "non_tough_control_sample")
  }
  paste(reasons, collapse = "; ")
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

write_utf8_lines <- function(lines, path) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  for (line in lines) {
    writeBin(charToRaw(line), con)
    writeBin(charToRaw("\n"), con)
  }
}

classifications <- readr::read_csv(paths$classifications, show_col_types = FALSE) |>
  dplyr::mutate(
    is_empirical_paper = parse_bool(is_empirical_paper),
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    is_empirical_qual_paper = parse_bool(is_empirical_qual_paper),
    has_statistical_inference = parse_bool(has_statistical_inference),
    causal_or_explanatory_claim_present = parse_bool(causal_or_explanatory_claim_present),
    credibility_revolution_screen_applicable = parse_bool(credibility_revolution_screen_applicable),
    credibility_revolution_method_present = parse_bool(credibility_revolution_method_present),
    tough_call = parse_bool(tough_call)
  )

manifest <- readr::read_csv(paths$manifest, show_col_types = FALSE) |>
  dplyr::select(
    pid,
    title_manifest = title,
    title_en,
    authors,
    year,
    journal_title_manifest = journal_title,
    doi,
    document_type,
    language,
    source_url,
    source_method,
    retrieved_at,
    body_word_count,
    reference_tail_ratio
  )

audit_base <- classifications |>
  dplyr::left_join(manifest, by = "pid") |>
  dplyr::mutate(
    title_candidate = first_nonempty(title_manifest, title),
    title_missing_flag = is.na(title_candidate) | stringr::str_trim(title_candidate) == "",
    title_for_audit = dplyr::case_when(
      title_missing_flag ~ paste0("[titulo ausente no manifest] ", pid),
      TRUE ~ title_candidate
    ),
    journal_title_for_audit = first_nonempty(journal_title_manifest, journal_title),
    doi_url = make_doi_url(doi),
    paper_url = dplyr::case_when(
      !is.na(source_url) & stringr::str_trim(source_url) != "" ~ source_url,
      doi_url != "" ~ doi_url,
      TRUE ~ ""
    )
  )

core_cases <- audit_base |>
  dplyr::filter(
    dplyr::coalesce(credibility_revolution_screen_applicable, FALSE) |
      dplyr::coalesce(credibility_revolution_method_present, FALSE)
  ) |>
  dplyr::mutate(
    audit_sample_group = "1_screen_or_method_core",
    sample_component = "all_screen_or_method_cases"
  )

tough_candidates <- audit_base |>
  dplyr::anti_join(core_cases |> dplyr::select(pid), by = "pid") |>
  dplyr::filter(dplyr::coalesce(tough_call, FALSE))

tough_sample <- sample_with_stratum_floor(
  tough_candidates,
  tough_outside_screen_target,
  c("empirical_evidence_type", "quantitative_analysis_type"),
  audit_seed + 1
) |>
  dplyr::mutate(audit_sample_group = "2_tough_outside_screen_sample")

control_candidates <- audit_base |>
  dplyr::anti_join(
    dplyr::bind_rows(core_cases, tough_sample) |> dplyr::select(pid),
    by = "pid"
  ) |>
  dplyr::filter(!dplyr::coalesce(tough_call, FALSE))

control_sample <- sample_with_stratum_floor(
  control_candidates,
  control_target,
  c("empirical_evidence_type", "quantitative_analysis_type"),
  audit_seed + 2
) |>
  dplyr::mutate(audit_sample_group = "3_non_tough_control_sample")

audit_sample <- dplyr::bind_rows(core_cases, tough_sample, control_sample) |>
  dplyr::arrange(audit_sample_group, journal_title_for_audit, year, title_for_audit, pid) |>
  dplyr::mutate(
    audit_id = sprintf("A%03d", dplyr::row_number()),
    selection_reason = mapply(
      selection_reason,
      credibility_revolution_screen_applicable,
      credibility_revolution_method_present,
      tough_call,
      audit_sample_group,
      USE.NAMES = FALSE
    ),
    reading_log_relative_path = file.path(
      "data", "processed", "credibility_prompt_v3_integral_reading",
      "pilot_175", "reading_logs", paste0(pid, ".json")
    ),
    classification_json_relative_path = file.path(
      "data", "processed", "credibility_prompt_v3_integral_reading",
      "pilot_175", "classifications", paste0(pid, ".json")
    )
  )

audit_sheet <- audit_sample |>
  dplyr::transmute(
    audit_id,
    audit_sample_group,
    sample_component,
    selection_reason,
    pid,
    title = title_for_audit,
    title_missing_flag = bool_label(title_missing_flag),
    title_en = empty_if_na(title_en),
    authors = empty_if_na(authors),
    year,
    journal_title = journal_title_for_audit,
    doi = empty_if_na(doi),
    doi_url,
    source_url = empty_if_na(source_url),
    paper_url,
    source_method = empty_if_na(source_method),
    retrieved_at = empty_if_na(retrieved_at),
    body_word_count,
    reference_tail_ratio,
    reading_log_relative_path,
    classification_json_relative_path,
    codex_is_empirical_paper = bool_label(is_empirical_paper),
    codex_empirical_evidence_type = empirical_evidence_type,
    codex_is_empirical_quant_paper_torreblanca = bool_label(is_empirical_quant_paper_torreblanca),
    codex_is_empirical_qual_paper = bool_label(is_empirical_qual_paper),
    codex_quantitative_analysis_type = quantitative_analysis_type,
    codex_quantitative_analysis_evidence_quote = quantitative_analysis_evidence_quote,
    codex_has_statistical_inference = bool_label(has_statistical_inference),
    codex_statistical_inference_quote = statistical_inference_quote,
    codex_qualitative_analysis_goal = qualitative_analysis_goal,
    codex_qualitative_goal_clarity = qualitative_goal_clarity,
    codex_qualitative_goal_quote = qualitative_goal_quote,
    codex_causal_or_explanatory_claim_present = bool_label(causal_or_explanatory_claim_present),
    codex_causal_or_explanatory_claim_quote = causal_or_explanatory_claim_quote,
    codex_screen_applicable = bool_label(credibility_revolution_screen_applicable),
    codex_screen_reason = credibility_revolution_screen_reason,
    codex_method_present = method_present_label(
      credibility_revolution_method_present,
      credibility_revolution_screen_applicable
    ),
    codex_method_type = credibility_revolution_method_type,
    codex_causal_design_quote = causal_design_quote,
    codex_main_variables_or_relationship = main_variables_or_relationship,
    codex_sample_or_data_source = sample_or_data_source,
    codex_tough_call = bool_label(tough_call),
    codex_tough_call_reason = tough_call_reason,
    codex_brief_justification = brief_justification,
    manual_is_empirical_paper = "",
    manual_empirical_evidence_type = "",
    manual_is_empirical_quant_paper_torreblanca = "",
    manual_is_empirical_qual_paper = "",
    manual_quantitative_analysis_type = "",
    manual_has_statistical_inference = "",
    manual_qualitative_analysis_goal = "",
    manual_qualitative_goal_clarity = "",
    manual_causal_or_explanatory_claim_present = "",
    manual_screen_applicable = "",
    manual_screen_reason = "",
    manual_method_present = "",
    manual_method_type = "",
    manual_main_variables_or_relationship = "",
    manual_sample_or_data_source = "",
    manual_tough_call = "",
    manual_decision = "",
    manual_notes = "",
    reviewer = "",
    audit_date = ""
  )

summary_by_group <- audit_sheet |>
  dplyr::count(audit_sample_group, name = "n") |>
  dplyr::arrange(audit_sample_group)

summary_by_reason <- audit_sheet |>
  dplyr::count(selection_reason, name = "n") |>
  dplyr::arrange(dplyr::desc(n), selection_reason)

summary_by_evidence <- audit_sheet |>
  dplyr::count(
    codex_empirical_evidence_type,
    codex_quantitative_analysis_type,
    audit_sample_group,
    name = "n"
  ) |>
  dplyr::arrange(
    audit_sample_group,
    codex_empirical_evidence_type,
    codex_quantitative_analysis_type
  )

readr::write_csv(audit_sheet, paths$audit_csv, na = "")

report_lines <- c(
  "# Amostra para auditoria manual do piloto v3 integral",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Síntese",
  "",
  paste0("- Arquivo CSV para Google Sheets: `", paths$audit_csv, "`."),
  paste0("- Tamanho da amostra: ", nrow(audit_sheet), " artigos."),
  paste0("- Seed reprodutível: ", audit_seed, "."),
  paste0("- Alvo de tough calls fora do screen: ", tough_outside_screen_target, "."),
  paste0("- Alvo de controles não tough-call: ", control_target, "."),
  "",
  "A amostra inclui todos os casos em que o screen de revolução da credibilidade é aplicável ou em que o classificador detectou método. Em seguida, adiciona uma amostra estratificada de tough calls fora do screen e uma amostra estratificada de controles não tough-call.",
  "",
  "Esta amostra foi desenhada para auditoria manual focalizada do classificador, não para estimar de forma representativa a taxa de erro do corpus. Os estratos do sorteio complementar são `empirical_evidence_type` e `quantitative_analysis_type`.",
  "",
  "Nos campos Codex booleanos, `NA_IN_SOURCE` indica valor ausente no CSV consolidado e `NOT_APPLICABLE_SCREEN_FALSE` indica que `method_present` estava em branco porque o screen de revolução da credibilidade não era aplicável.",
  "",
  "## Tabela 1. Artigos selecionados por grupo de amostragem",
  "",
  md_table(summary_by_group),
  "",
  "## Tabela 2. Artigos selecionados por razão de inclusão",
  "",
  md_table(summary_by_reason),
  "",
  "## Tabela 3. Artigos selecionados por tipo de evidência, análise quantitativa e grupo",
  "",
  md_table(summary_by_evidence),
  "",
  "## Colunas manuais sugeridas",
  "",
  "- `manual_is_empirical_paper`: TRUE/FALSE.",
  "- `manual_empirical_evidence_type`: `none`, `qualitative_only`, `quantitative_only` ou `mixed_empirical`.",
  "- `manual_is_empirical_quant_paper_torreblanca`: TRUE/FALSE.",
  "- `manual_is_empirical_qual_paper`: TRUE/FALSE.",
  "- `manual_quantitative_analysis_type`: `none`, `descriptive_statistics_only`, `bivariate_tests_or_correlations_only` ou `statistical_modeling`.",
  "- `manual_has_statistical_inference`: TRUE/FALSE.",
  "- `manual_causal_or_explanatory_claim_present`: TRUE/FALSE.",
  "- `manual_screen_applicable`: TRUE/FALSE.",
  "- `manual_method_present`: TRUE/FALSE.",
  "- `manual_decision`: `accept_codex`, `minor_edit`, `major_disagreement` ou `needs_second_review`.",
  "",
  "## Como usar",
  "",
  "1. Importe o CSV no Google Sheets como nova planilha.",
  "2. Congele a primeira linha e ative filtros.",
  "3. Leia o paper pelo `paper_url` e, quando necessário, compare com o `reading_log_relative_path` no repositório.",
  "4. Preencha apenas as colunas `manual_*`, `reviewer` e `audit_date`.",
  "5. Exporte a planilha auditada como CSV e salve de volta no repositório para reconciliação posterior."
)

write_utf8_lines(report_lines, paths$audit_report)

cat("CSV de auditoria escrito em:", paths$audit_csv, "\n")
cat("Relatório de auditoria escrito em:", paths$audit_report, "\n")
cat("N artigos na amostra:", nrow(audit_sheet), "\n")
