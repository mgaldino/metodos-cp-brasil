## 35_compare_credibility_prompt_v3_ab_effort.R
## Compara classificacoes xhigh canonicas com A/B gpt-5.5 high.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(stringr)
  library(tidyr)
})

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default = NULL) {
  pos <- match(flag, args)
  if (is.na(pos) || pos == length(args)) {
    return(default)
  }
  args[[pos + 1]]
}

project_dir <- normalizePath(".", mustWork = TRUE)

paths <- list(
  sample_manifest = get_arg(
    "--manifest",
    file.path(
      project_dir,
      "data", "processed", "credibility_prompt_v3_full_corpus",
      "batch_manifests", "ab_gpt55_high_50.csv"
    )
  ),
  baseline_csv = get_arg(
    "--baseline",
    file.path(
      project_dir,
      "data", "processed", "credibility_prompt_v3_integral_reading",
      "full_corpus", "combined", "classifications_integral_reading.csv"
    )
  ),
  treatment_csv = get_arg(
    "--treatment",
    file.path(
      project_dir,
      "data", "processed", "credibility_prompt_v3_integral_reading",
      "full_corpus_ab", "gpt55_high", "combined",
      "classifications_integral_reading_ab_gpt55_high_50.csv"
    )
  ),
  baseline_reading_dir = get_arg(
    "--baseline-reading-dir",
    file.path(
      project_dir,
      "data", "processed", "credibility_prompt_v3_integral_reading",
      "full_corpus", "reading_logs"
    )
  ),
  treatment_reading_dir = get_arg(
    "--treatment-reading-dir",
    file.path(
      project_dir,
      "data", "processed", "credibility_prompt_v3_integral_reading",
      "full_corpus_ab", "gpt55_high", "reading_logs"
    )
  ),
  out_report = get_arg(
    "--out-report",
    file.path(
      project_dir,
      "quality_reports", "credibility_prompt_v3_ab_gpt55_high_vs_xhigh.md"
    )
  ),
  out_disagreements = get_arg(
    "--out-disagreements",
    file.path(
      project_dir,
      "data", "processed", "credibility_prompt_v3_integral_reading",
      "full_corpus_ab", "gpt55_high", "combined",
      "ab_gpt55_high_disagreements.csv"
    )
  )
)

dir.create(dirname(paths$out_report), showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(paths$out_disagreements), showWarnings = FALSE, recursive = TRUE)

priority_fields <- c(
  "is_empirical_paper",
  "empirical_evidence_type",
  "is_empirical_quant_paper_torreblanca",
  "is_empirical_qual_paper",
  "quantitative_analysis_type",
  "has_statistical_inference",
  "causal_or_explanatory_claim_present",
  "credibility_revolution_screen_applicable",
  "credibility_revolution_screen_reason",
  "credibility_revolution_method_present",
  "credibility_revolution_method_type",
  "tough_call"
)

screen_method_fields <- c(
  "credibility_revolution_screen_applicable",
  "credibility_revolution_screen_reason",
  "credibility_revolution_method_present",
  "credibility_revolution_method_type"
)

boolean_fields <- c(
  "is_empirical_paper",
  "is_empirical_quant_paper_torreblanca",
  "is_empirical_qual_paper",
  "has_statistical_inference",
  "causal_or_explanatory_claim_present",
  "credibility_revolution_screen_applicable",
  "credibility_revolution_method_present",
  "tough_call"
)

read_csv_utf8_chr <- function(path) {
  if (!file.exists(path)) {
    stop("Arquivo ausente: ", path)
  }
  readr::read_csv(
    path,
    col_types = readr::cols(.default = readr::col_character()),
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
  value <- stringr::str_to_upper(stringr::str_trim(dplyr::coalesce(as.character(x), "")))
  dplyr::case_when(
    value == "TRUE" ~ "TRUE",
    value == "FALSE" ~ "FALSE",
    TRUE ~ "NA"
  )
}

parse_method_types <- function(x) {
  if (is.na(x) || stringr::str_trim(x) == "") {
    return(character())
  }
  parsed <- tryCatch(jsonlite::fromJSON(x), error = function(e) character())
  sort(unique(as.character(parsed)))
}

normalize_field <- function(field, value) {
  if (field %in% boolean_fields) {
    return(parse_bool(value))
  }
  if (field == "credibility_revolution_method_type") {
    return(vapply(value, function(x) paste(parse_method_types(x), collapse = "; "), character(1)))
  }
  stringr::str_squish(dplyr::coalesce(as.character(value), ""))
}

format_rate <- function(x) {
  if (is.na(x)) {
    return(NA_character_)
  }
  paste0(sprintf("%.1f", 100 * x), "%")
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

null_coalesce <- function(x, default) {
  if (is.null(x) || length(x) == 0) {
    return(default)
  }
  x
}

reading_log_metrics <- function(pid, reading_dir) {
  path <- file.path(reading_dir, paste0(pid, ".json"))
  if (!file.exists(path)) {
    return(data.frame(
      pid = pid,
      log_exists = FALSE,
      input_text_hash = NA_character_,
      full_body_read = NA,
      status = NA_character_,
      n_sections = NA_integer_,
      total_summary_chars = NA_integer_,
      avg_summary_chars = NA_real_,
      first_sections = NA_character_
    ))
  }
  record <- tryCatch(
    jsonlite::fromJSON(path, simplifyVector = FALSE),
    error = function(e) NULL
  )
  if (is.null(record)) {
    return(data.frame(
      pid = pid,
      log_exists = TRUE,
      input_text_hash = NA_character_,
      full_body_read = NA,
      status = "unparseable",
      n_sections = NA_integer_,
      total_summary_chars = NA_integer_,
      avg_summary_chars = NA_real_,
      first_sections = NA_character_
    ))
  }
  sections <- null_coalesce(record$section_reading_log, list())
  summaries <- vapply(
    sections,
    function(section) null_coalesce(section$section_summary, ""),
    character(1)
  )
  titles <- vapply(
    sections,
    function(section) null_coalesce(section$section_title, ""),
    character(1)
  )
  data.frame(
    pid = pid,
    log_exists = TRUE,
    input_text_hash = null_coalesce(record$input_text_hash, NA_character_),
    full_body_read = isTRUE(record$full_body_read),
    status = null_coalesce(record$status, NA_character_),
    n_sections = length(sections),
    total_summary_chars = sum(nchar(summaries), na.rm = TRUE),
    avg_summary_chars = if (length(summaries) > 0) mean(nchar(summaries), na.rm = TRUE) else NA_real_,
    first_sections = paste(utils::head(titles, 4), collapse = "; ")
  )
}

sample_manifest <- read_csv_utf8_chr(paths$sample_manifest)
baseline <- read_csv_utf8_chr(paths$baseline_csv)
treatment <- read_csv_utf8_chr(paths$treatment_csv)

assert_unique(sample_manifest, "pid", "Manifesto A/B")
assert_unique(baseline, "pid", "Baseline xhigh")
assert_unique(treatment, "pid", "Tratamento high")

missing_priority_baseline <- setdiff(priority_fields, names(baseline))
missing_priority_treatment <- setdiff(priority_fields, names(treatment))
if (length(missing_priority_baseline) > 0) {
  stop("Campos ausentes no baseline: ", paste(missing_priority_baseline, collapse = ", "))
}
if (length(missing_priority_treatment) > 0) {
  stop("Campos ausentes no tratamento: ", paste(missing_priority_treatment, collapse = ", "))
}

expected_pids <- sample_manifest$pid
baseline_sample <- baseline |>
  dplyr::semi_join(sample_manifest |> dplyr::select(pid), by = "pid")

missing_in_baseline <- setdiff(expected_pids, baseline_sample$pid)
missing_in_treatment <- setdiff(expected_pids, treatment$pid)
extra_in_treatment <- setdiff(treatment$pid, expected_pids)

baseline_hash_mismatches <- baseline_sample |>
  dplyr::select(pid, baseline_input_text_hash = input_text_hash) |>
  dplyr::left_join(
    sample_manifest |> dplyr::select(pid, manifest_input_text_hash = input_text_hash),
    by = "pid"
  ) |>
  dplyr::filter(baseline_input_text_hash != manifest_input_text_hash)

treatment_hash_mismatches <- treatment |>
  dplyr::semi_join(sample_manifest |> dplyr::select(pid), by = "pid") |>
  dplyr::select(pid, treatment_input_text_hash = input_text_hash) |>
  dplyr::left_join(
    sample_manifest |> dplyr::select(pid, manifest_input_text_hash = input_text_hash),
    by = "pid"
  ) |>
  dplyr::filter(treatment_input_text_hash != manifest_input_text_hash)

if (nrow(baseline_hash_mismatches) > 0) {
  stop("Hash baseline vs manifesto diverge para PIDs: ", paste(baseline_hash_mismatches$pid, collapse = ", "))
}
if (nrow(treatment_hash_mismatches) > 0) {
  stop("Hash tratamento vs manifesto diverge para PIDs: ", paste(treatment_hash_mismatches$pid, collapse = ", "))
}

comparison <- baseline_sample |>
  dplyr::inner_join(treatment, by = "pid", suffix = c("_xhigh", "_high")) |>
  dplyr::arrange(match(pid, expected_pids))

normalized_xhigh <- as.data.frame(
  setNames(
    lapply(priority_fields, function(field) normalize_field(field, comparison[[paste0(field, "_xhigh")]])),
    priority_fields
  ),
  stringsAsFactors = FALSE
)

normalized_high <- as.data.frame(
  setNames(
    lapply(priority_fields, function(field) normalize_field(field, comparison[[paste0(field, "_high")]])),
    priority_fields
  ),
  stringsAsFactors = FALSE
)

diff_matrix <- normalized_xhigh != normalized_high
diff_matrix[is.na(diff_matrix)] <- FALSE

field_agreement <- lapply(priority_fields, function(field) {
  agree <- normalized_xhigh[[field]] == normalized_high[[field]]
  agree[is.na(agree)] <- FALSE
  data.frame(
    field = field,
    n_compared = length(agree),
    n_agree = sum(agree),
    n_disagree = sum(!agree),
    agreement_rate = if (length(agree) > 0) mean(agree) else NA_real_,
    agreement_percent = format_rate(if (length(agree) > 0) mean(agree) else NA_real_)
  )
}) |>
  dplyr::bind_rows()

any_disagreement <- rowSums(diff_matrix) > 0
disagreement_base <- comparison |>
  dplyr::mutate(
    title = dplyr::coalesce(title_xhigh, title_high),
    journal_title = dplyr::coalesce(journal_title_xhigh, journal_title_high),
    fields_disagree = apply(diff_matrix, 1, function(row) {
      fields <- names(row)[row]
      if (length(fields) == 0) "" else paste(fields, collapse = "; ")
    })
  ) |>
  dplyr::filter(any_disagreement) |>
  dplyr::select(pid, title, journal_title, fields_disagree)

disagreements <- disagreement_base
for (field in priority_fields) {
  disagreements[[paste0(field, "_xhigh")]] <- normalized_xhigh[[field]][any_disagreement]
  disagreements[[paste0(field, "_high")]] <- normalized_high[[field]][any_disagreement]
}

readr::write_csv(disagreements, paths$out_disagreements, na = "")

screen_method_disagreement <- disagreements |>
  dplyr::filter(stringr::str_detect(fields_disagree, paste(screen_method_fields, collapse = "|"))) |>
  dplyr::select(
    pid,
    title,
    fields_disagree,
    credibility_revolution_screen_applicable_xhigh,
    credibility_revolution_screen_applicable_high,
    credibility_revolution_screen_reason_xhigh,
    credibility_revolution_screen_reason_high,
    credibility_revolution_method_present_xhigh,
    credibility_revolution_method_present_high,
    credibility_revolution_method_type_xhigh,
    credibility_revolution_method_type_high
  )

all_xhigh_logs <- lapply(expected_pids, reading_log_metrics, reading_dir = paths$baseline_reading_dir) |>
  dplyr::bind_rows() |>
  dplyr::rename_with(~ paste0("xhigh_", .x), -pid)

all_high_logs <- lapply(expected_pids, reading_log_metrics, reading_dir = paths$treatment_reading_dir) |>
  dplyr::bind_rows() |>
  dplyr::rename_with(~ paste0("high_", .x), -pid)

all_log_assessment <- sample_manifest |>
  dplyr::select(pid, title, journal_title, manifest_input_text_hash = input_text_hash) |>
  dplyr::left_join(all_xhigh_logs, by = "pid") |>
  dplyr::left_join(all_high_logs, by = "pid") |>
  dplyr::mutate(
    high_to_xhigh_section_ratio = high_n_sections / xhigh_n_sections,
    high_to_xhigh_summary_ratio = high_total_summary_chars / xhigh_total_summary_chars,
    high_log_assessment = dplyr::case_when(
      pid %in% missing_in_treatment ~ "Classificação high ausente.",
      !high_log_exists ~ "Log high ausente.",
      !dplyr::coalesce(high_full_body_read, FALSE) ~ "High não registrou leitura integral.",
      high_input_text_hash != manifest_input_text_hash ~ "Hash do log high diverge do manifesto.",
      is.na(high_n_sections) | high_n_sections == 0 ~ "High sem seções registradas.",
      !is.na(xhigh_n_sections) & high_n_sections < pmax(3, 0.6 * xhigh_n_sections) ~
        "Possível superficialidade: bem menos seções que xhigh.",
      !is.na(xhigh_total_summary_chars) &
        high_total_summary_chars < 0.6 * xhigh_total_summary_chars ~
        "Possível superficialidade: resumos bem mais curtos que xhigh.",
      TRUE ~ "Sem sinal mecânico de superficialidade no reading log."
    )
  )

log_issue_distribution <- all_log_assessment |>
  dplyr::count(high_log_assessment, name = "n") |>
  dplyr::arrange(dplyr::desc(n), high_log_assessment)

log_assessment <- all_log_assessment |>
  dplyr::semi_join(disagreements |> dplyr::select(pid), by = "pid") |>
  dplyr::left_join(disagreements |> dplyr::select(pid, fields_disagree), by = "pid") |>
  dplyr::select(
    pid,
    fields_disagree,
    xhigh_status,
    high_status,
    xhigh_full_body_read,
    high_full_body_read,
    xhigh_n_sections,
    high_n_sections,
    xhigh_total_summary_chars,
    high_total_summary_chars,
    high_to_xhigh_section_ratio,
    high_to_xhigh_summary_ratio,
    high_first_sections,
    high_log_assessment
  )

mean_agreement <- mean(field_agreement$agreement_rate, na.rm = TRUE)
min_agreement <- min(field_agreement$agreement_rate, na.rm = TRUE)
n_screen_method_disagreement <- nrow(screen_method_disagreement)
n_superficial_flags <- sum(
  stringr::str_detect(
    all_log_assessment$high_log_assessment,
    "ausente|não registrou|sem seções|Possível|Hash do log high diverge"
  ),
  na.rm = TRUE
)

recommendation <- dplyr::case_when(
  length(missing_in_treatment) > 0 ~
    "Manter xhigh até o A/B high completar todos os PIDs selecionados.",
  mean_agreement >= 0.95 & n_screen_method_disagreement == 0 & n_superficial_flags == 0 ~
    "Usar high nos próximos blocos, mantendo auditoria amostral.",
  mean_agreement >= 0.90 & n_screen_method_disagreement <= 3 & n_superficial_flags <= 1 ~
    "Usar regra híbrida: high como default, xhigh para casos de screen/método, tough_call ou reading log suspeito.",
  TRUE ~
    "Manter xhigh como default; high ainda gera divergência substantiva demais para substituir."
)

pid_disagreement_table <- disagreements |>
  dplyr::select(pid, title, journal_title, fields_disagree)

top_agreement <- field_agreement |>
  dplyr::arrange(agreement_rate, field)

report_lines <- c(
  "# A/B gpt-5.5 high vs xhigh: credibility_prompt_v3",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Escopo",
  "",
  paste0("- Manifesto congelado: `", paths$sample_manifest, "`"),
  paste0("- Baseline xhigh: `", paths$baseline_csv, "`"),
  paste0("- Tratamento high: `", paths$treatment_csv, "`"),
  paste0("- CSV de desacordos: `", paths$out_disagreements, "`"),
  paste0("- N no manifesto: ", length(expected_pids)),
  paste0("- N baseline no manifesto: ", nrow(baseline_sample)),
  paste0("- N tratamento high: ", nrow(treatment)),
  paste0("- N comparado: ", nrow(comparison)),
  paste0("- PIDs ausentes no baseline: ", length(missing_in_baseline)),
  paste0("- PIDs ausentes no high: ", length(missing_in_treatment)),
  paste0("- PIDs extras no high fora do manifesto: ", length(extra_in_treatment)),
  "- Validações: PIDs únicos em manifesto/baseline/high e `input_text_hash` idêntico entre manifesto, baseline e tratamento nos PIDs comparados.",
  "",
  "## Tabela 1. Concordância por campo prioritário",
  "",
  md_table(top_agreement),
  "",
  "## Tabela 2. PIDs com desacordo substantivo",
  "",
  md_table(pid_disagreement_table),
  "",
  "## Tabela 3. Desacordos em screen/method",
  "",
  md_table(screen_method_disagreement),
  "",
  "## Tabela 4. Cobertura dos reading logs high em todos os PIDs",
  "",
  md_table(log_issue_distribution),
  "",
  "## Tabela 5. Avaliação curta dos reading logs em casos divergentes",
  "",
  md_table(log_assessment),
  "",
  "## Recomendação",
  "",
  paste0("- Concordância média nos campos prioritários: ", format_rate(mean_agreement)),
  paste0("- Menor concordância de campo: ", format_rate(min_agreement)),
  paste0("- PIDs com desacordo screen/method: ", n_screen_method_disagreement),
  paste0("- PIDs com sinal mecânico de superficialidade no high: ", n_superficial_flags),
  paste0("- Recomendação: ", recommendation),
  "",
  "A avaliação dos `section_reading_log` é uma checagem reprodutível de cobertura, não uma leitura substantiva humana. Ela marca superficialidade apenas quando o log high está ausente, incompleto, com hash divergente, ou muito mais curto que o xhigh."
)

write_utf8_lines(report_lines, paths$out_report)

cat("Relatório A/B escrito em:", paths$out_report, "\n")
cat("CSV de desacordos escrito em:", paths$out_disagreements, "\n")
cat("N comparado:", nrow(comparison), "\n")
cat("PIDs divergentes:", nrow(disagreements), "\n")
cat("Recomendação:", recommendation, "\n")
