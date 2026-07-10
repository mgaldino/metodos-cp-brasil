## Compara três configurações GPT-5.6 com o baseline GPT-5.5 xhigh.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(stringr)
  library(tidyr)
})

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default) {
  pos <- match(flag, args)
  if (is.na(pos) || pos == length(args)) {
    return(default)
  }
  args[[pos + 1]]
}

project_dir <- normalizePath(".", mustWork = TRUE)
benchmark_root <- get_arg(
  "--benchmark-root",
  file.path(
    project_dir, "data", "processed", "credibility_prompt_v3_integral_reading",
    "full_corpus_ab", "gpt56_model_benchmark_10"
  )
)
manifest_path <- get_arg(
  "--manifest",
  file.path(
    project_dir, "data", "processed", "credibility_prompt_v3_full_corpus",
    "batch_manifests", "ab_gpt56_models_10.csv"
  )
)
baseline_path <- get_arg(
  "--baseline",
  file.path(
    project_dir, "data", "processed", "credibility_prompt_v3_integral_reading",
    "full_corpus", "combined", "classifications_integral_reading.csv"
  )
)
historical_high_path <- get_arg(
  "--historical-high",
  file.path(
    project_dir, "data", "processed", "credibility_prompt_v3_integral_reading",
    "full_corpus_ab", "gpt55_high", "combined",
    "classifications_integral_reading_ab_gpt55_high_50.csv"
  )
)
timings_path <- get_arg(
  "--timings",
  file.path(benchmark_root, "benchmark_timings.csv")
)
out_report <- get_arg(
  "--out-report",
  file.path(project_dir, "quality_reports", "credibility_prompt_v3_ab_gpt56_model_benchmark_10.md")
)
out_comparison <- get_arg(
  "--out-comparison",
  file.path(benchmark_root, "combined", "benchmark_model_comparison.csv")
)

configurations <- tibble::tribble(
  ~label, ~display_name, ~model, ~effort, ~csv_path, ~reading_dir, ~is_new,
  "gpt55_high", "GPT-5.5 high (histórico)",
  NA_character_, NA_character_, historical_high_path,
  file.path(
    project_dir, "data", "processed", "credibility_prompt_v3_integral_reading",
    "full_corpus_ab", "gpt55_high", "reading_logs"
  ), FALSE,
  "sol_medium", "GPT-5.6 Sol medium",
  "gpt-5.6-sol", "medium",
  file.path(benchmark_root, "sol_medium", "combined", "classifications_integral_reading_sol_medium_10.csv"),
  file.path(benchmark_root, "sol_medium", "reading_logs"), TRUE,
  "terra_medium", "GPT-5.6 Terra medium",
  "gpt-5.6-terra", "medium",
  file.path(benchmark_root, "terra_medium", "combined", "classifications_integral_reading_terra_medium_10.csv"),
  file.path(benchmark_root, "terra_medium", "reading_logs"), TRUE,
  "terra_xhigh", "GPT-5.6 Terra xhigh",
  "gpt-5.6-terra", "xhigh",
  file.path(benchmark_root, "terra_xhigh", "combined", "classifications_integral_reading_terra_xhigh_10.csv"),
  file.path(benchmark_root, "terra_xhigh", "reading_logs"), TRUE
)

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

read_utf8 <- function(path) {
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

parse_bool <- function(x) {
  value <- stringr::str_to_upper(stringr::str_trim(dplyr::coalesce(as.character(x), "")))
  dplyr::case_when(
    value == "TRUE" ~ "TRUE",
    value == "FALSE" ~ "FALSE",
    value == "" ~ "<NA>",
    TRUE ~ "<INVALID>"
  )
}

parse_method_types <- function(x) {
  if (is.na(x) || stringr::str_trim(x) == "") {
    return(character())
  }
  parsed <- tryCatch(jsonlite::fromJSON(x), error = function(e) "<INVALID_JSON>")
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
  ifelse(is.na(x), "", paste0(sprintf("%.1f", 100 * x), "%"))
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

validate_classification <- function(data, label) {
  missing_fields <- setdiff(priority_fields, names(data))
  if (length(missing_fields) > 0) {
    stop(label, " sem campos prioritários: ", paste(missing_fields, collapse = ", "))
  }
  required_boolean_fields <- setdiff(
    boolean_fields,
    c("has_statistical_inference", "credibility_revolution_method_present")
  )
  invalid_required <- lapply(required_boolean_fields, function(field) {
    values <- parse_bool(data[[field]])
    data$pid[!values %in% c("TRUE", "FALSE")]
  }) |>
    unlist(use.names = FALSE) |>
    unique()
  if (length(invalid_required) > 0) {
    stop(label, " tem booleanos obrigatórios inválidos: ", paste(invalid_required, collapse = ", "))
  }
  invalid_json <- vapply(
    data$credibility_revolution_method_type,
    function(value) "<INVALID_JSON>" %in% parse_method_types(value),
    logical(1)
  )
  if (any(invalid_json)) {
    stop(label, " tem JSON inválido em method_type: ", paste(data$pid[invalid_json], collapse = ", "))
  }
}

read_log_status <- function(pid, reading_dir, expected_hash, expected_title, expected_journal) {
  path <- file.path(reading_dir, paste0(pid, ".json"))
  if (!file.exists(path)) {
    return("log_ausente")
  }
  record <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(record)) {
    return("log_inválido")
  }
  if (!identical(record$status, "complete")) {
    return("status_incompleto")
  }
  if (!identical(record$pid, pid)) {
    return("pid_divergente")
  }
  if (!identical(record$title, expected_title) || !identical(record$journal_title, expected_journal)) {
    return("metadados_divergentes")
  }
  sections <- record$section_reading_log
  if (!isTRUE(record$full_body_read)) {
    return("leitura_integral_falsa")
  }
  if (!identical(record$input_text_hash, expected_hash)) {
    return("hash_divergente")
  }
  if (is.null(sections) || length(sections) == 0) {
    return("sem_seções")
  }
  summaries <- vapply(
    sections,
    function(section) {
      if (!is.list(section) || is.null(section$section_summary)) "" else section$section_summary
    },
    character(1)
  )
  if (any(stringr::str_trim(summaries) == "")) {
    return("resumo_de_seção_vazio")
  }
  "válido"
}

manifest <- read_utf8(manifest_path)
baseline <- read_utf8(baseline_path) |>
  dplyr::semi_join(manifest |> dplyr::select(pid), by = "pid")
timings <- read_utf8(timings_path) |>
  dplyr::mutate(
    elapsed_seconds = as.numeric(elapsed_seconds),
    return_code = as.integer(return_code)
  )

if (nrow(manifest) != 10 || anyDuplicated(manifest$pid)) {
  stop("Manifesto deve conter exatamente 10 PIDs únicos.")
}
if (nrow(baseline) != 10 || anyDuplicated(baseline$pid)) {
  stop("Baseline GPT-5.5 xhigh não cobre os 10 PIDs de forma única.")
}
validate_classification(baseline, "Baseline GPT-5.5 xhigh")
baseline_hash_check <- baseline |>
  dplyr::select(pid, baseline_hash = input_text_hash) |>
  dplyr::left_join(manifest |> dplyr::select(pid, manifest_hash = input_text_hash), by = "pid") |>
  dplyr::filter(is.na(baseline_hash) | baseline_hash == "" | baseline_hash != manifest_hash)
if (nrow(baseline_hash_check) > 0) {
  stop("Baseline GPT-5.5 xhigh tem hashes ausentes ou divergentes.")
}

expected_timing_configs <- configurations |>
  dplyr::filter(is_new) |>
  dplyr::select(label, expected_model = model, expected_effort = effort)
if (!setequal(unique(timings$label), expected_timing_configs$label)) {
  stop("Labels do timing não correspondem aos três braços novos.")
}
timing_validated <- timings |>
  dplyr::left_join(expected_timing_configs, by = "label")
if (any(!timing_validated$pid %in% manifest$pid)) {
  stop("Timing contém PIDs fora do manifesto.")
}
if (any(
  timing_validated$model != timing_validated$expected_model |
    timing_validated$effort != timing_validated$expected_effort
)) {
  stop("Timing contém combinação label/model/effort incompatível.")
}
if (any(!is.finite(timing_validated$elapsed_seconds) | timing_validated$elapsed_seconds < 0)) {
  stop("Timing contém duração inválida.")
}
success_counts <- timing_validated |>
  dplyr::filter(status == "complete", return_code == 0L) |>
  dplyr::count(label, pid, name = "n_success")
expected_success <- tidyr::crossing(
  label = expected_timing_configs$label,
  pid = manifest$pid
) |>
  dplyr::left_join(success_counts, by = c("label", "pid")) |>
  dplyr::mutate(n_success = dplyr::coalesce(n_success, 0L))
if (any(expected_success$n_success != 1L)) {
  stop("Cada combinação label/PID deve ter exatamente um timing bem-sucedido.")
}

baseline_normalized <- baseline |>
  dplyr::arrange(match(pid, manifest$pid))
for (field in priority_fields) {
  baseline_normalized[[field]] <- normalize_field(field, baseline_normalized[[field]])
}

comparison_rows <- list()
field_rows <- list()
disagreement_rows <- list()
log_rows <- list()

for (index in seq_len(nrow(configurations))) {
  config <- configurations[index, ]
  candidate <- read_utf8(config$csv_path) |>
    dplyr::semi_join(manifest |> dplyr::select(pid), by = "pid") |>
    dplyr::arrange(match(pid, manifest$pid))

  if (anyDuplicated(candidate$pid)) {
    stop(config$display_name, " contém PIDs duplicados.")
  }
  if (nrow(candidate) != 10 || !setequal(candidate$pid, manifest$pid)) {
    stop(config$display_name, " não cobre exatamente os 10 PIDs.")
  }
  validate_classification(candidate, config$display_name)
  missing_pids <- setdiff(manifest$pid, candidate$pid)
  hash_mismatches <- candidate |>
    dplyr::select(pid, candidate_hash = input_text_hash) |>
    dplyr::left_join(manifest |> dplyr::select(pid, manifest_hash = input_text_hash), by = "pid") |>
    dplyr::filter(
      is.na(candidate_hash) | candidate_hash == "" | candidate_hash != manifest_hash
    )
  if (nrow(hash_mismatches) > 0) {
    stop(config$display_name, " tem hashes divergentes.")
  }

  joined <- baseline_normalized |>
    dplyr::select(pid, title, journal_title, dplyr::all_of(priority_fields)) |>
    dplyr::inner_join(candidate, by = "pid", suffix = c("_baseline", "_candidate"))

  diff_by_field <- list()
  for (field in priority_fields) {
    baseline_values <- joined[[paste0(field, "_baseline")]]
    candidate_values <- normalize_field(field, joined[[paste0(field, "_candidate")]])
    differs <- baseline_values != candidate_values
    differs[is.na(differs)] <- TRUE
    diff_by_field[[field]] <- differs
    field_rows[[length(field_rows) + 1L]] <- data.frame(
      label = config$label,
      display_name = config$display_name,
      field = field,
      n_compared = length(differs),
      n_disagree = sum(differs),
      agreement_rate = mean(!differs)
    )
  }

  diff_matrix <- as.data.frame(diff_by_field)
  fields_disagree <- apply(diff_matrix, 1, function(row) {
    fields <- names(row)[row]
    if (length(fields) == 0) "" else paste(fields, collapse = "; ")
  })
  any_diff <- fields_disagree != ""
  critical_diff <- apply(diff_matrix[, screen_method_fields, drop = FALSE], 1, any)

  if (any(any_diff)) {
    disagreement_rows[[length(disagreement_rows) + 1L]] <- data.frame(
      label = config$label,
      display_name = config$display_name,
      pid = joined$pid[any_diff],
      title = joined$title_baseline[any_diff],
      fields_disagree = fields_disagree[any_diff],
      screen_method_disagreement = critical_diff[any_diff]
    )
  }

  for (pid in manifest$pid) {
    expected_hash <- manifest$input_text_hash[manifest$pid == pid]
    manifest_row <- manifest[manifest$pid == pid, ]
    log_rows[[length(log_rows) + 1L]] <- data.frame(
      label = config$label,
      pid = pid,
      log_status = read_log_status(
        pid,
        config$reading_dir,
        expected_hash,
        manifest_row$title,
        manifest_row$journal_title
      )
    )
  }

  comparison_rows[[length(comparison_rows) + 1L]] <- data.frame(
    label = config$label,
    display_name = config$display_name,
    n_complete = nrow(candidate),
    n_missing = length(missing_pids),
    n_pids_any_disagreement = sum(any_diff),
    n_pids_screen_method_disagreement = sum(critical_diff),
    mean_field_agreement = mean(!as.matrix(diff_matrix)),
    is_new = config$is_new
  )
}

baseline_reading_dir <- file.path(
  project_dir, "data", "processed", "credibility_prompt_v3_integral_reading",
  "full_corpus", "reading_logs"
)
for (pid in manifest$pid) {
  manifest_row <- manifest[manifest$pid == pid, ]
  log_rows[[length(log_rows) + 1L]] <- data.frame(
    label = "gpt55_xhigh_baseline",
    pid = pid,
    log_status = read_log_status(
      pid,
      baseline_reading_dir,
      manifest_row$input_text_hash,
      manifest_row$title,
      manifest_row$journal_title
    )
  )
}

comparison <- dplyr::bind_rows(comparison_rows)
field_agreement <- dplyr::bind_rows(field_rows)
disagreements <- dplyr::bind_rows(disagreement_rows)
log_status <- dplyr::bind_rows(log_rows) |>
  dplyr::count(label, log_status, name = "n")

speed <- timing_validated |>
  dplyr::group_by(label, model, effort) |>
  dplyr::summarise(
    n_attempts = dplyr::n(),
    n_failed_attempts = sum(status != "complete"),
    total_elapsed_seconds = sum(elapsed_seconds),
    median_success_seconds = median(elapsed_seconds[status == "complete"]),
    mean_success_seconds = mean(elapsed_seconds[status == "complete"]),
    .groups = "drop"
  )

new_log_failures <- log_status |>
  dplyr::filter(label %in% configurations$label[configurations$is_new], log_status != "válido") |>
  dplyr::group_by(label) |>
  dplyr::summarise(n_invalid_logs = sum(n), .groups = "drop")

decision <- comparison |>
  dplyr::filter(is_new) |>
  dplyr::left_join(speed, by = "label") |>
  dplyr::left_join(new_log_failures, by = "label") |>
  dplyr::mutate(n_invalid_logs = dplyr::coalesce(n_invalid_logs, 0L)) |>
  dplyr::mutate(
    passes_historical_floor =
      n_pids_screen_method_disagreement <=
        comparison$n_pids_screen_method_disagreement[comparison$label == "gpt55_high"] &
      mean_field_agreement >=
        comparison$mean_field_agreement[comparison$label == "gpt55_high"]
  ) |>
  dplyr::arrange(
    n_missing,
    n_invalid_logs,
    n_pids_screen_method_disagreement,
    dplyr::desc(mean_field_agreement),
    total_elapsed_seconds
  )

eligible_decision <- decision |>
  dplyr::filter(n_missing == 0, n_invalid_logs == 0, passes_historical_floor)
if (nrow(eligible_decision) == 0) {
  recommendation <- paste0(
    "Manter GPT-5.5 xhigh: nenhum braço GPT-5.6 passou simultaneamente pelos gates ",
    "de integridade e pelo piso de qualidade do GPT-5.5 high nos mesmos 10 casos."
  )
} else {
  winner <- eligible_decision[1, ]
  recommendation <- paste0(
    "Escolher ", winner$display_name,
    " entre os braços testados: passou os gates e liderou a ordenação lexicográfica por desacordos críticos, concordância geral e tempo."
  )
}

comparison_export <- comparison |>
  dplyr::left_join(speed, by = "label") |>
  dplyr::mutate(mean_field_agreement_percent = format_rate(mean_field_agreement))

dir.create(dirname(out_comparison), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(out_report), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(comparison_export, out_comparison, na = "")

summary_table <- comparison_export |>
  dplyr::select(
    configuracao = display_name,
    completos = n_complete,
    faltantes = n_missing,
    pids_com_algum_desacordo = n_pids_any_disagreement,
    pids_com_desacordo_screen_metodo = n_pids_screen_method_disagreement,
    concordancia_media = mean_field_agreement_percent,
    tentativas = n_attempts,
    falhas_transitorias = n_failed_attempts,
    tempo_total_segundos = total_elapsed_seconds,
    mediana_por_artigo_segundos = median_success_seconds
  )

field_table <- field_agreement |>
  dplyr::mutate(concordancia = format_rate(agreement_rate)) |>
  dplyr::select(
    configuracao = display_name,
    campo = field,
    n_comparado = n_compared,
    discordancias = n_disagree,
    concordancia
  )

disagreement_table <- disagreements |>
  dplyr::arrange(dplyr::desc(screen_method_disagreement), label, pid) |>
  dplyr::select(
    configuracao = display_name,
    pid,
    titulo = title,
    campos_divergentes = fields_disagree,
    divergencia_screen_metodo = screen_method_disagreement
  )

speed_table <- speed |>
  dplyr::mutate(
    total_elapsed_seconds = round(total_elapsed_seconds, 1),
    median_success_seconds = round(median_success_seconds, 1),
    mean_success_seconds = round(mean_success_seconds, 1)
  ) |>
  dplyr::select(
    configuracao = label,
    modelo = model,
    esforco = effort,
    tentativas = n_attempts,
    falhas = n_failed_attempts,
    tempo_total_segundos = total_elapsed_seconds,
    mediana_segundos = median_success_seconds,
    media_segundos = mean_success_seconds
  )

log_table <- log_status |>
  dplyr::left_join(configurations |> dplyr::select(label, display_name), by = "label") |>
  dplyr::mutate(
    display_name = dplyr::if_else(
      label == "gpt55_xhigh_baseline",
      "GPT-5.5 xhigh (baseline)",
      display_name
    )
  ) |>
  dplyr::select(configuracao = display_name, status_do_log = log_status, n)

report_lines <- c(
  "# Benchmark de modelos GPT-5.6 para classificação integral",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Escopo e regra de decisão",
  "",
  paste0("- Manifesto congelado: `", manifest_path, "`"),
  "- Baseline de consistência: GPT-5.5 xhigh já classificado.",
  "- Benchmark histórico incorporado: GPT-5.5 high nos mesmos PIDs.",
  "- Novos braços: GPT-5.6 Sol medium, Terra medium e Terra xhigh.",
  "- Velocidade solicitada: standard/default em todos os braços; o `codex exec` não expõe a velocidade efetiva.",
  "- Execução sequencial com rotação da ordem dos braços por PID.",
  "- Regra lexicográfica: completude e logs válidos; menos desacordos screen/método; maior concordância média; menor tempo total.",
  "- Piso histórico: um braço novo não pode ter mais desacordos críticos nem menor concordância média que o GPT-5.5 high nos mesmos 10 casos.",
  "- O tempo total inclui tentativas falhas porque mede latência fim a fim, inclusive reparos e retries.",
  "- A concordância com o baseline mede continuidade classificatória, não verdade substantiva.",
  "",
  "## Tabela 1. Resultado geral por configuração",
  "",
  md_table(summary_table),
  "",
  "## Tabela 2. Velocidade observada nos novos braços",
  "",
  md_table(speed_table),
  "",
  "## Tabela 3. Concordância por campo prioritário",
  "",
  md_table(field_table),
  "",
  "## Tabela 4. PIDs e campos divergentes do baseline GPT-5.5 xhigh",
  "",
  md_table(disagreement_table),
  "",
  "## Tabela 5. Integridade dos reading logs",
  "",
  md_table(log_table),
  "",
  "## Recomendação",
  "",
  paste0("- ", recommendation),
  "- Esta é uma calibração direcionada a 10 casos difíceis; antes de trocar o modelo em todo o corpus, a configuração vencedora deve permanecer sob auditoria amostral independente."
)

write_utf8_lines(report_lines, out_report)

cat("Relatório escrito em:", out_report, "\n")
cat("Comparação CSV escrita em:", out_comparison, "\n")
cat("Recomendação:", recommendation, "\n")
