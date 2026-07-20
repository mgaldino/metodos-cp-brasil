#!/usr/bin/env Rscript

## Reproduz todos os resultados e o PDF do paper a partir do CSV canônico já
## existente. Este script não coleta textos, não executa LLMs e não consolida
## batches de classificação.

options(scipen = 999, encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
allowed_args <- c("--help", "--preflight", "--skip-render")
unknown_args <- setdiff(args, allowed_args)
if (length(unknown_args) > 0) {
  stop("Argumentos desconhecidos: ", paste(unknown_args, collapse = "; "))
}

if ("--help" %in% args) {
  cat(
    "Uso: Rscript scripts/57_replicate_paper.R [--preflight] [--skip-render]\n\n",
    "  --preflight    Valida ambiente e entradas sem executar análises.\n",
    "  --skip-render  Executa todas as análises sem recompilar paper/paper.pdf.\n",
    sep = ""
  )
  quit(save = "no", status = 0)
}

preflight_only <- "--preflight" %in% args
skip_render <- "--skip-render" %in% args

file_arg <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", file_arg[grepl("^--file=", file_arg)])
if (length(file_arg) != 1) {
  stop("Não foi possível identificar o caminho do script mestre.")
}

project_dir <- normalizePath(file.path(dirname(file_arg), ".."), mustWork = TRUE)
path <- function(...) file.path(project_dir, ...)

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
log_dir <- path("quality_reports", "replication")
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
log_path <- file.path(log_dir, paste0("replicate_paper_", timestamp, ".log"))

append_log <- function(...) {
  line <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"), " | ", paste0(..., collapse = ""))
  cat(line, "\n")
  cat(line, "\n", file = log_path, append = TRUE)
}

stop_logged <- function(...) {
  message_text <- paste0(..., collapse = "")
  append_log("ERRO | ", message_text)
  stop(message_text, call. = FALSE)
}

required_inputs <- c(
  path("data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"),
  path("data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv"),
  path("data/processed/excluded_articles.csv"),
  path("data/processed/excluded_journals.csv"),
  path("data/raw/torreblanca_2026/source_v2/main.tex"),
  path("data/processed/credibility_prompt_v3_integral_reading/prompts/classifier_prompt_v3_integral_reading.md"),
  path("data/processed/credibility_prompt_v3_test/prompts/classifier_prompt_v3.md"),
  path("paper/paper.Rmd"),
  path("paper/preamble.tex"),
  path("references.bib")
)

required_packages <- c(
  "brms", "cmdstanr", "dplyr", "genderBR", "ggplot2", "jsonlite",
  "knitr", "patchwork", "posterior", "readr", "rmarkdown", "stringr",
  "tibble", "tidyr"
)

validate_preflight <- function() {
  append_log("PREFLIGHT | início")

  missing_inputs <- required_inputs[!file.exists(required_inputs)]
  if (length(missing_inputs) > 0) {
    stop_logged("Entradas ausentes: ", paste(missing_inputs, collapse = "; "))
  }

  missing_packages <- required_packages[
    !vapply(required_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
  ]
  missing_preflight_packages <- intersect(missing_packages, c("cmdstanr", "dplyr", "readr"))
  if (length(missing_preflight_packages) > 0) {
    stop_logged(
      "Pacotes necessários ao próprio preflight ausentes: ",
      paste(missing_preflight_packages, collapse = "; ")
    )
  }

  if (!nzchar(Sys.which("xelatex"))) {
    stop_logged("Executável xelatex não encontrado no PATH.")
  }

  cmdstan_path <- tryCatch(cmdstanr::cmdstan_path(), error = function(error) "")
  if (!nzchar(cmdstan_path) || !dir.exists(cmdstan_path)) {
    stop_logged("Instalação do CmdStan não encontrada.")
  }
  cmdstan_version <- as.character(cmdstanr::cmdstan_version())
  if (!identical(cmdstan_version, "2.37.0")) {
    append_log("AVISO | CmdStan ", cmdstan_version, "; versão testada: 2.37.0")
  }

  manifest <- readr::read_csv(required_inputs[[1]], show_col_types = FALSE) |>
    dplyr::select(pid, journal_title)
  classifications <- readr::read_csv(required_inputs[[2]], show_col_types = FALSE) |>
    dplyr::select(pid, journal_title)

  if (anyDuplicated(manifest$pid) > 0) {
    stop_logged("O manifesto contém PIDs duplicados.")
  }
  if (anyDuplicated(classifications$pid) > 0) {
    stop_logged("O CSV canônico contém PIDs duplicados.")
  }

  outside_manifest <- setdiff(classifications$pid, manifest$pid)
  if (length(outside_manifest) > 0) {
    stop_logged(
      "O CSV canônico contém ", length(outside_manifest),
      " PID(s) fora do manifesto."
    )
  }

  append_log(
    "PREFLIGHT | dados válidos | manifesto=", nrow(manifest),
    " | classificações canônicas=", nrow(classifications)
  )

  if (length(missing_packages) > 0) {
    stop_logged("Pacotes R ausentes: ", paste(missing_packages, collapse = "; "))
  }

  append_log(
    "PREFLIGHT | PASS | manifesto=", nrow(manifest),
    " | classificações canônicas=", nrow(classifications),
    " | CmdStan=", cmdstan_version
  )
}

run_r_script <- function(label, script, expected_outputs) {
  script_path <- path("scripts", script)
  if (!file.exists(script_path)) {
    stop_logged(label, " | script ausente: ", script_path)
  }

  append_log(label, " | início | ", script)
  started_at <- Sys.time()
  output <- suppressWarnings(
    system2(
      file.path(R.home("bin"), "Rscript"),
      args = script_path,
      stdout = TRUE,
      stderr = TRUE
    )
  )
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  if (length(output) > 0) {
    cat(paste0("  ", output), sep = "\n", file = log_path, append = TRUE)
    cat("\n", file = log_path, append = TRUE)
  }
  if (!identical(as.integer(status), 0L)) {
    stop_logged(label, " | falhou com status ", status, ". Consulte ", log_path)
  }

  missing_outputs <- expected_outputs[!file.exists(expected_outputs)]
  if (length(missing_outputs) > 0) {
    stop_logged(label, " | outputs ausentes: ", paste(missing_outputs, collapse = "; "))
  }

  stale_outputs <- expected_outputs[
    file.info(expected_outputs)$mtime < (started_at - 2)
  ]
  if (length(stale_outputs) > 0) {
    stop_logged(label, " | outputs não atualizados: ", paste(stale_outputs, collapse = "; "))
  }

  append_log(label, " | PASS | outputs=", length(expected_outputs))
}

steps <- list(
  list(
    label = "01 análise principal",
    script = "45_build_current_paper_analysis.R",
    outputs = c(
      path("data/processed/paper_analysis/paper_analysis_dataset_current.csv"),
      path("output/tables/paper/denominator_summary.csv"),
      path("output/tables/paper/table_1_corpus_description.csv"),
      path("output/tables/paper/table_2_methodological_dimensions.csv"),
      path("output/tables/paper/table_3_causality_credibility.csv"),
      path("output/tables/paper/table_4_complete_journal_profile.csv"),
      path("output/tables/paper/table_5_claim_method_alignment.csv"),
      path("output/tables/paper/table_8_qualitative_complete_summary.csv"),
      path("output/figures/paper/figure_1_corpus_funnel.pdf"),
      path("output/figures/paper/figure_2_journal_dimension_matrix.pdf"),
      path("output/figures/paper/figure_3_period_variation.pdf"),
      path("output/figures/paper/figure_4_journal_period_coverage.pdf"),
      path("output/figures/paper/figure_5_claim_method_alignment.pdf"),
      path("output/figures/paper/figure_6_strict_method_distribution.pdf"),
      path("output/figures/paper/figure_7_year_variation.pdf")
    )
  ),
  list(
    label = "02 inferência estatística",
    script = "48_expand_statistical_inference_analysis.R",
    outputs = c(
      path("output/tables/paper/statistical_inference_key_numbers.csv"),
      path("output/tables/paper/statistical_inference_torreblanca_benchmark.csv"),
      path("output/tables/paper/statistical_inference_by_causal_language.csv"),
      path("output/figures/paper/figure_statistical_inference_benchmark.pdf")
    )
  ),
  list(
    label = "03 análise por área",
    script = "52_analyze_area_current_canonical.R",
    outputs = c(
      path("output/tables/area_analysis/area_profile.csv"),
      path("output/tables/area_analysis/source_area_profile.csv"),
      path("output/tables/area_analysis/area_period_profile.csv"),
      path("data/processed/area_analysis/area_analysis_checks.csv")
    )
  ),
  list(
    label = "04 modelo bayesiano por área",
    script = "54_bayesian_area_hierarchical_model.R",
    outputs = c(
      path("output/tables/area_analysis/bayesian_area_posterior_summary.csv"),
      path("output/tables/area_analysis/bayesian_area_prior_summary.csv"),
      path("output/tables/area_analysis/bayesian_area_diagnostics.csv"),
      path("output/tables/area_analysis/bayesian_area_prior_predictive_summary.csv")
    )
  ),
  list(
    label = "05 análise de gênero",
    script = "51_analyze_gender_current_canonical.R",
    outputs = c(
      path("data/processed/gender_analysis/current_canonical_article_gender.csv"),
      path("output/tables/gender_analysis/table_4_evidence_by_first_author_gender.csv")
    )
  ),
  list(
    label = "06 reconciliação de gênero",
    script = "56_reconcile_gender_to_paper_scope.R",
    outputs = c(
      path("data/processed/gender_analysis/current_canonical_article_gender_paper_scope.csv"),
      path("output/tables/gender_analysis/table_3_methodological_indicators_by_first_author_gender_paper_scope.csv"),
      path("output/tables/gender_analysis/table_7_standardized_comparison_journal_period_paper_scope.csv")
    )
  ),
  list(
    label = "07 modelo bayesiano de gênero",
    script = "54_fit_bayesian_gender_hierarchical.R",
    outputs = c(
      path("output/tables/gender_analysis/table_13_bayesian_hierarchical_gender_effects.csv"),
      path("output/tables/gender_analysis/table_15_bayesian_model_diagnostics.csv")
    )
  )
)

paper_dependencies <- c(
  unlist(lapply(steps, function(step) step$outputs), use.names = FALSE),
  path("output/tables/paper/period_equal_weight_profile.csv"),
  path("output/tables/paper/period_article_weight_profile.csv"),
  path("output/tables/paper/period_complete_journal_profile.csv"),
  path("output/tables/paper/tough_call_profile.csv"),
  path("output/tables/paper/coverage_by_journal.csv")
)

render_paper <- function() {
  missing_dependencies <- paper_dependencies[!file.exists(paper_dependencies)]
  if (length(missing_dependencies) > 0) {
    stop_logged("RENDER | dependências ausentes: ", paste(missing_dependencies, collapse = "; "))
  }

  paper_path <- path("paper", "paper.Rmd")
  pdf_path <- path("paper", "paper.pdf")
  append_log("08 renderização | início | paper/paper.Rmd")
  started_at <- Sys.time()
  rendered <- tryCatch(
    rmarkdown::render(
      input = paper_path,
      output_format = "pdf_document",
      quiet = TRUE,
      envir = new.env(parent = globalenv())
    ),
    error = function(error) error
  )
  if (inherits(rendered, "error")) {
    stop_logged("RENDER | ", conditionMessage(rendered))
  }
  if (!file.exists(pdf_path) || file.info(pdf_path)$mtime < (started_at - 2)) {
    stop_logged("RENDER | paper/paper.pdf não foi atualizado.")
  }
  append_log("08 renderização | PASS | ", pdf_path)
}

append_log("REPLICAÇÃO | início | projeto=", project_dir)
validate_preflight()

if (preflight_only) {
  append_log("REPLICAÇÃO | preflight concluído; nenhuma análise foi executada")
  quit(save = "no", status = 0)
}

for (step in steps) {
  run_r_script(step$label, step$script, step$outputs)
}

if (skip_render) {
  append_log("REPLICAÇÃO | análises concluídas; renderização omitida por --skip-render")
} else {
  render_paper()
  append_log("REPLICAÇÃO | PASS | paper reproduzido integralmente")
}
