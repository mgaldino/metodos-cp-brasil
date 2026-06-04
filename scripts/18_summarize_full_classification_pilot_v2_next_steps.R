# -*- coding: UTF-8 -*-
## 18_summarize_full_classification_pilot_v2_next_steps.R
## Consolida estatisticas do piloto v2 para relatorio de proximos passos.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(tibble)
})

project_dir <- normalizePath(".", mustWork = TRUE)
pilot_dir <- file.path(project_dir, "data", "processed", "full_classification_pilot_v2")
comparison_dir <- file.path(pilot_dir, "comparison")

paths <- list(
  metadata = file.path(pilot_dir, "pilot_manifest_metadata.json"),
  manifest = file.path(pilot_dir, "pilot_manifest.csv"),
  validation_issues = file.path(project_dir, "quality_reports", "full_classification_pilot_v2_validation_issues.csv"),
  fidelity_validation_issues = file.path(project_dir, "quality_reports", "full_classification_pilot_v2_fidelity_validation_issues.csv"),
  agreement = file.path(comparison_dir, "agent_field_agreement.csv"),
  adjudication_queue = file.path(comparison_dir, "adjudication_queue_prioritized.csv"),
  fidelity_file_audits = file.path(comparison_dir, "fidelity_file_audits_validated.csv"),
  fidelity_field_audits = file.path(comparison_dir, "fidelity_field_audits_validated.csv"),
  fidelity_by_agent = file.path(comparison_dir, "fidelity_supported_rates_by_agent.csv"),
  fidelity_by_agent_field = file.path(comparison_dir, "fidelity_supported_rates_by_agent_field.csv"),
  fidelity_high_risk = file.path(comparison_dir, "fidelity_high_risk_fields.csv"),
  agent_permissiveness = file.path(comparison_dir, "agent_permissiveness_summary.csv"),
  previous_consensus = file.path(comparison_dir, "previous_classification_agreement_consensus_by_field.csv")
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

fmt_int <- function(x) {
  formatC(as.integer(round(x)), format = "d", big.mark = ".", decimal.mark = ",")
}

fmt_pct <- function(x, digits = 1) {
  ifelse(
    is.na(x),
    NA_character_,
    paste0(formatC(100 * x, format = "f", digits = digits, decimal.mark = ","), "%")
  )
}

fmt_num <- function(x, digits = 1) {
  formatC(x, format = "f", digits = digits, decimal.mark = ",")
}

count_jsons <- function(dir) {
  if (!dir.exists(dir)) {
    return(0L)
  }
  length(list.files(dir, pattern = "[.]json$", full.names = TRUE))
}

metadata <- jsonlite::fromJSON(paths$metadata, simplifyVector = TRUE)
manifest <- read_csv_utf8(paths$manifest)
validation_issues <- read_csv_utf8(paths$validation_issues)
fidelity_validation_issues <- read_csv_utf8(paths$fidelity_validation_issues)
agreement <- read_csv_utf8(paths$agreement)
adjudication_queue <- read_csv_utf8(paths$adjudication_queue)
fidelity_file_audits <- read_csv_utf8(paths$fidelity_file_audits)
fidelity_field_audits <- read_csv_utf8(paths$fidelity_field_audits)
fidelity_by_agent <- read_csv_utf8(paths$fidelity_by_agent)
fidelity_by_agent_field <- read_csv_utf8(paths$fidelity_by_agent_field)
fidelity_high_risk <- read_csv_utf8(paths$fidelity_high_risk)
agent_permissiveness <- read_csv_utf8(paths$agent_permissiveness)
previous_consensus <- read_csv_utf8(paths$previous_consensus)

agents <- c("agent_a", "agent_b", "agent_c")
n_articles <- nrow(manifest)
n_fields <- nrow(agreement)
n_critical_fields <- sum(agreement$critical_field)
n_noncritical_fields <- n_fields - n_critical_fields

json_counts <- tibble::tibble(
  tipo = c(rep("classificacao", length(agents)), rep("fidelidade", length(agents))),
  agente = c(agents, agents),
  esperado = n_articles,
  presente = c(
    vapply(agents, function(agent) count_jsons(file.path(pilot_dir, agent)), integer(1)),
    vapply(agents, function(agent) count_jsons(file.path(pilot_dir, "fidelity_checker", agent)), integer(1))
  )
) |>
  dplyr::mutate(completo = presente == esperado)

classification_schema_errors <- sum(validation_issues$severity == "ERROR", na.rm = TRUE)
classification_schema_warnings <- sum(validation_issues$severity == "WARN", na.rm = TRUE)
fidelity_schema_errors <- sum(fidelity_validation_issues$severity == "ERROR", na.rm = TRUE)
fidelity_schema_warnings <- sum(fidelity_validation_issues$severity == "WARN", na.rm = TRUE)

decisions_total <- sum(agreement$n_articles)
unanimity_total <- sum(agreement$unanimity_n)
majority_total <- sum(agreement$majority_n)
adjudication_total <- sum(agreement$adjudication_n)
critical_decisions <- n_articles * n_critical_fields
noncritical_decisions <- n_articles * n_noncritical_fields
critical_adjudication <- sum(agreement$adjudication_n[agreement$critical_field])
noncritical_adjudication <- sum(agreement$adjudication_n[!agreement$critical_field])

field_audit_total <- nrow(fidelity_field_audits)
supported_total <- sum(fidelity_field_audits$status == "supported_by_text", na.rm = TRUE)
contradicted_total <- sum(fidelity_field_audits$status == "contradicted_by_text", na.rm = TRUE)
not_found_total <- sum(fidelity_field_audits$status == "not_found_in_text", na.rm = TRUE)
high_severity_total <- sum(fidelity_field_audits$severity == "high", na.rm = TRUE)
medium_severity_total <- sum(fidelity_field_audits$severity == "medium", na.rm = TRUE)
low_severity_total <- sum(fidelity_field_audits$severity == "low", na.rm = TRUE)
high_severity_pids <- length(unique(fidelity_field_audits$pid[fidelity_field_audits$severity == "high"]))

high_priority_queue <- adjudication_queue |>
  dplyr::filter(priority_score >= 14)

snapshot <- tibble::tibble(
  metrica = c(
    "artigos elegiveis no manifest",
    "campos de classificacao",
    "decisoes artigo-campo A/B/C",
    "unanimidade A/B/C",
    "maioria 2 contra 1 A/B/C",
    "adjudicacao por desacordo A/B/C",
    "adjudicacao em campos criticos",
    "adjudicacao em campos nao criticos",
    "JSONs de classificacao presentes",
    "JSONs de auditoria D presentes",
    "erros de schema A/B/C",
    "warnings de schema A/B/C",
    "erros de schema D",
    "warnings de schema D",
    "campos factuais auditados por D",
    "campos factuais suportados pelo texto",
    "campos contraditos pelo texto",
    "campos nao encontrados no texto",
    "falhas de severidade alta",
    "PIDs com ao menos uma falha alta",
    "itens na fila priorizada",
    "PIDs na fila priorizada",
    "itens com prioridade >= 14",
    "PIDs com prioridade >= 14"
  ),
  valor = c(
    fmt_int(n_articles),
    fmt_int(n_fields),
    fmt_int(decisions_total),
    fmt_int(unanimity_total),
    fmt_int(majority_total),
    fmt_int(adjudication_total),
    fmt_int(critical_adjudication),
    fmt_int(noncritical_adjudication),
    paste0(fmt_int(sum(json_counts$presente[json_counts$tipo == "classificacao"])), "/", fmt_int(n_articles * length(agents))),
    paste0(fmt_int(sum(json_counts$presente[json_counts$tipo == "fidelidade"])), "/", fmt_int(n_articles * length(agents))),
    fmt_int(classification_schema_errors),
    fmt_int(classification_schema_warnings),
    fmt_int(fidelity_schema_errors),
    fmt_int(fidelity_schema_warnings),
    fmt_int(field_audit_total),
    fmt_int(supported_total),
    fmt_int(contradicted_total),
    fmt_int(not_found_total),
    fmt_int(high_severity_total),
    fmt_int(high_severity_pids),
    fmt_int(nrow(adjudication_queue)),
    fmt_int(length(unique(adjudication_queue$pid))),
    fmt_int(nrow(high_priority_queue)),
    fmt_int(length(unique(high_priority_queue$pid)))
  ),
  taxa = c(
    NA_character_,
    NA_character_,
    NA_character_,
    fmt_pct(unanimity_total / decisions_total),
    fmt_pct(majority_total / decisions_total),
    fmt_pct(adjudication_total / decisions_total),
    fmt_pct(critical_adjudication / critical_decisions),
    fmt_pct(noncritical_adjudication / noncritical_decisions),
    fmt_pct(sum(json_counts$presente[json_counts$tipo == "classificacao"]) / (n_articles * length(agents))),
    fmt_pct(sum(json_counts$presente[json_counts$tipo == "fidelidade"]) / (n_articles * length(agents))),
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    fmt_pct(supported_total / field_audit_total),
    fmt_pct(contradicted_total / field_audit_total),
    fmt_pct(not_found_total / field_audit_total),
    fmt_pct(high_severity_total / field_audit_total),
    fmt_pct(high_severity_pids / n_articles),
    NA_character_,
    fmt_pct(length(unique(adjudication_queue$pid)) / n_articles),
    NA_character_,
    fmt_pct(length(unique(high_priority_queue$pid)) / n_articles)
  )
)

agreement_top <- agreement |>
  dplyr::arrange(dplyr::desc(adjudication_rate), dplyr::desc(adjudication_n)) |>
  dplyr::mutate(
    campo_critico = ifelse(critical_field, "sim", "nao"),
    unanimidade = fmt_pct(unanimity_rate),
    maioria = fmt_pct(majority_rate),
    adjudicacao = fmt_pct(adjudication_rate)
  ) |>
  dplyr::select(
    campo = field,
    campo_critico,
    artigos = n_articles,
    unanimidade,
    maioria,
    itens_para_adjudicar = adjudication_n,
    adjudicacao
  )

critical_agreement <- agreement |>
  dplyr::filter(critical_field) |>
  dplyr::arrange(dplyr::desc(adjudication_rate)) |>
  dplyr::mutate(
    unanimidade = fmt_pct(unanimity_rate),
    adjudicacao = fmt_pct(adjudication_rate)
  ) |>
  dplyr::select(
    campo = field,
    unanimidade,
    itens_para_adjudicar = adjudication_n,
    adjudicacao
  )

fidelity_by_agent_report <- fidelity_by_agent |>
  dplyr::arrange(dplyr::desc(factual_support_rate)) |>
  dplyr::mutate(
    taxa_de_suporte = fmt_pct(factual_support_rate),
    contraditos = contradicted_n,
    nao_encontrados = not_found_n,
    severidade_alta = high_severity_n,
    severidade_media = medium_severity_n
  ) |>
  dplyr::select(
    agente = audited_agent_id,
    campos_auditados = audited_fields,
    campos_suportados = supported_factual_fields,
    taxa_de_suporte,
    contraditos,
    nao_encontrados,
    severidade_alta,
    severidade_media
  )

fidelity_file_status <- fidelity_file_audits |>
  dplyr::count(audited_agent_id, overall_fidelity_status, name = "n") |>
  tidyr::pivot_wider(
    names_from = overall_fidelity_status,
    values_from = n,
    values_fill = 0
  ) |>
  dplyr::mutate(total = pass + pass_with_warnings + fail) |>
  dplyr::select(
    agente = audited_agent_id,
    pass,
    pass_with_warnings,
    fail,
    total
  )

high_risk_fields <- fidelity_high_risk |>
  dplyr::arrange(factual_support_rate) |>
  dplyr::mutate(taxa_de_suporte = fmt_pct(factual_support_rate)) |>
  dplyr::select(
    campo = field,
    auditados = audited_fields,
    suportados = supported_factual_fields,
    taxa_de_suporte,
    contraditos = contradicted_n,
    nao_encontrados = not_found_n,
    severidade_alta = high_severity_n,
    severidade_media = medium_severity_n
  )

high_severity_by_field <- fidelity_field_audits |>
  dplyr::filter(severity == "high") |>
  dplyr::count(field, sort = TRUE, name = "falhas_altas") |>
  dplyr::rename(campo = field)

high_severity_by_agent <- fidelity_field_audits |>
  dplyr::filter(severity == "high") |>
  dplyr::count(audited_agent_id, sort = TRUE, name = "falhas_altas") |>
  dplyr::rename(agente = audited_agent_id)

queue_reason_summary <- adjudication_queue |>
  dplyr::count(adjudication_reason, sort = TRUE, name = "itens") |>
  dplyr::mutate(parcela = fmt_pct(itens / sum(itens))) |>
  dplyr::select(razao = adjudication_reason, itens, parcela)

high_priority_fields <- high_priority_queue |>
  dplyr::count(field, sort = TRUE, name = "itens_prioridade_alta") |>
  dplyr::rename(campo = field)

top_priority_items <- adjudication_queue |>
  dplyr::arrange(dplyr::desc(priority_score), field, pid) |>
  dplyr::mutate(
    titulo = substr(title, 1, 90),
    campo_critico = ifelse(critical_field, "sim", "nao")
  ) |>
  dplyr::select(
    pid,
    titulo,
    campo = field,
    campo_critico,
    consenso = consensus_level,
    prioridade = priority_score,
    razao = adjudication_reason,
    agentes_com_falha = fidelity_agents_with_issue
  ) |>
  dplyr::slice_head(n = 20)

previous_divergence <- previous_consensus |>
  dplyr::arrange(agreement_rate) |>
  dplyr::mutate(
    campo_critico = ifelse(critical_field, "sim", "nao"),
    acordo_com_v1 = fmt_pct(agreement_rate)
  ) |>
  dplyr::select(
    campo = field,
    campo_critico,
    consensos_v2_aceitos = n_consensus_accepted,
    acordo_com_v1
  )

permissiveness <- agent_permissiveness |>
  dplyr::arrange(dplyr::desc(permissive_signal_rate)) |>
  dplyr::mutate(taxa_permissiva = fmt_pct(permissive_signal_rate)) |>
  dplyr::select(
    agente = agent_id,
    slots_auditados = audited_signal_slots,
    sinais_permissivos = permissive_signal_n,
    taxa_permissiva
  )

report_data <- list(
  metadata = metadata,
  snapshot = snapshot,
  json_counts = json_counts,
  agreement_top = agreement_top,
  critical_agreement = critical_agreement,
  fidelity_by_agent = fidelity_by_agent_report,
  fidelity_file_status = fidelity_file_status,
  high_risk_fields = high_risk_fields,
  high_severity_by_field = high_severity_by_field,
  high_severity_by_agent = high_severity_by_agent,
  queue_reason_summary = queue_reason_summary,
  high_priority_fields = high_priority_fields,
  top_priority_items = top_priority_items,
  previous_divergence = previous_divergence,
  permissiveness = permissiveness,
  raw = list(
    n_articles = n_articles,
    decisions_total = decisions_total,
    adjudication_total = adjudication_total,
    critical_adjudication = critical_adjudication,
    field_audit_total = field_audit_total,
    supported_total = supported_total,
    high_severity_total = high_severity_total,
    high_severity_pids = high_severity_pids,
    high_priority_items = nrow(high_priority_queue),
    high_priority_pids = length(unique(high_priority_queue$pid))
  )
)
