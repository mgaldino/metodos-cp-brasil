#!/usr/bin/env Rscript

## Modelo bayesiano hierárquico binomial para a diferença de inferência
## estatística entre Ciência Política e Relações Internacionais.
## A verossimilhança é agregada por periódico para representar a dependência
## entre artigos publicados no mesmo periódico.

options(scipen = 999, encoding = "UTF-8")
set.seed(20260719)

required_packages <- c("brms", "cmdstanr", "dplyr", "posterior", "readr", "stringr", "tibble")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]
if (length(missing_packages) > 0) {
  stop("Pacotes ausentes: ", paste(missing_packages, collapse = ", "))
}

suppressPackageStartupMessages({
  library(brms)
  library(cmdstanr)
  library(dplyr)
  library(posterior)
  library(readr)
  library(stringr)
  library(tibble)
})

file_arg <- commandArgs(trailingOnly = FALSE) |>
  stringr::str_subset("^--file=") |>
  stringr::str_remove("^--file=")
if (length(file_arg) != 1) {
  stop("Não foi possível identificar o caminho do script.")
}

project_dir <- normalizePath(file.path(dirname(file_arg), ".."), mustWork = TRUE)
path <- function(...) file.path(project_dir, ...)

input_path <- path("data/processed/paper_analysis/paper_analysis_dataset_current.csv")
tables_dir <- path("output/tables/area_analysis")
processed_dir <- path("data/processed/area_analysis")
report_path <- path("quality_reports/bayesian_area_model_current_canonical.md")

dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_path)) {
  stop("Dataset analítico ausente: ", input_path)
}

cmdstan_version <- as.character(cmdstanr::cmdstan_version())
if (!identical(cmdstan_version, "2.37.0")) {
  warning("A versão do CmdStan não é a versão testada 2.37.0: ", cmdstan_version)
}

parse_bool <- function(x) {
  value <- stringr::str_to_upper(stringr::str_trim(as.character(x)))
  dplyr::case_when(
    value == "TRUE" ~ TRUE,
    value == "FALSE" ~ FALSE,
    TRUE ~ NA
  )
}

as_true <- function(x) {
  !is.na(x) & x
}

fmt_int <- function(x) {
  format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

fmt_pct <- function(x) {
  paste0(format(round(100 * x, 1), decimal.mark = ",", nsmall = 1, trim = TRUE), "%")
}

fmt_pp <- function(x) {
  paste0(format(round(100 * x, 1), decimal.mark = ",", nsmall = 1, trim = TRUE), " p.p.")
}

fmt_prob <- function(x) {
  ifelse(x < 0.001, "<0,001", format(round(x, 3), decimal.mark = ",", nsmall = 3, trim = TRUE))
}

escape_md <- function(x) {
  as.character(x) |>
    stringr::str_replace_all("\\|", "\\\\|") |>
    stringr::str_replace_all("\\r?\\n", " ")
}

markdown_table <- function(data) {
  data_chr <- data |>
    dplyr::mutate(
      dplyr::across(
        dplyr::everything(),
        ~ escape_md(dplyr::coalesce(as.character(.x), "-"))
      )
    )
  header <- paste0("| ", paste(names(data_chr), collapse = " | "), " |")
  separator <- paste0("| ", paste(rep("---", ncol(data_chr)), collapse = " | "), " |")
  rows <- apply(data_chr, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  c(header, separator, rows)
}

write_utf8_lines <- function(lines, file) {
  connection <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(connection), add = TRUE)
  writeLines(enc2utf8(lines), con = connection, useBytes = TRUE)
}

data <- readr::read_csv(input_path, show_col_types = FALSE) |>
  dplyr::mutate(
    is_empirical_quant_paper_torreblanca = parse_bool(is_empirical_quant_paper_torreblanca),
    has_statistical_inference = parse_bool(has_statistical_inference),
    area_group = dplyr::case_when(
      journal_area %in% c("Ciência Política", "Ciência Política e Ciências Sociais") ~
        "Ciência Política (inclui escopo compartilhado)",
      journal_area == "Relações Internacionais" ~ "Relações Internacionais",
      TRUE ~ NA_character_
    )
  ) |>
  dplyr::filter(
    !is.na(area_group),
    as_true(is_empirical_quant_paper_torreblanca),
    !is.na(has_statistical_inference)
  )

if (anyDuplicated(data$pid) > 0) {
  stop("O dataset contém PIDs duplicados.")
}

data <- data |>
  dplyr::mutate(area_ri = as.integer(area_group == "Relações Internacionais"))

journal_data <- data |>
  dplyr::group_by(area_group, area_ri, journal_title) |>
  dplyr::summarise(
    y = sum(as_true(has_statistical_inference)),
    n = dplyr::n(),
    failures = n - y,
    observed_rate = y / n,
    .groups = "drop"
  ) |>
  dplyr::arrange(area_ri, journal_title) |>
  dplyr::mutate(journal_id = factor(journal_title))

if (nrow(journal_data) != 8L || dplyr::n_distinct(journal_data$area_ri) != 2L) {
  stop("O conjunto hierárquico não contém exatamente os oito periódicos esperados.")
}

readr::write_csv(journal_data, file.path(tables_dir, "bayesian_area_journal_data.csv"))

fit_model <- function(prior_beta, prior_intercept, file_suffix) {
  priors <- c(
    brms::set_prior(prior_intercept, class = "Intercept"),
    brms::set_prior(prior_beta, class = "b", coef = "area_ri"),
    brms::set_prior("student_t(3, 0, 1)", class = "sd")
  )
  brms::brm(
    formula = brms::bf(y | trials(n) ~ 1 + area_ri + (1 | journal_id)),
    data = journal_data,
    family = stats::binomial(link = "logit"),
    prior = priors,
    backend = "cmdstanr",
    chains = 4,
    iter = 4000,
    warmup = 2000,
    cores = 4L,
    threads = brms::threading(1),
    seed = 20260719,
    refresh = 0,
    silent = 2,
    control = list(adapt_delta = 0.99, max_treedepth = 12),
    sample_prior = "yes",
    file = file.path(processed_dir, paste0("bayesian_area_", file_suffix)),
    file_refit = "on_change"
  )
}

message("Ajustando modelo com prior Normal...")
fit_normal <- fit_model(
  prior_beta = "normal(0, 1.5)",
  prior_intercept = "normal(0, 1.5)",
  file_suffix = "normal"
)

message("Ajustando modelo com prior Student-t...")
fit_student <- fit_model(
  prior_beta = "student_t(3, 0, 2.5)",
  prior_intercept = "student_t(3, 0, 2.5)",
  file_suffix = "student"
)
message("Modelos ajustados; calculando posteriores e diagnósticos...")

posterior_targets <- function(fit, prior_label) {
  draws <- posterior::as_draws_df(fit)
  alpha <- draws$b_Intercept
  beta <- draws$b_area_ri
  p_cp <- plogis(alpha)
  p_ri <- plogis(alpha + beta)
  delta <- p_cp - p_ri
  tibble::tibble(
    prior = prior_label,
    parameter = c(
      "P(inferência | CP, periódico médio)",
      "P(inferência | RI, periódico médio)",
      "Diferença CP - RI",
      "Razão de chances RI/CP",
      "beta_area_ri",
      "P(delta > 0)",
      "P(beta_area_ri < 0)"
    ),
    estimate = c(
      median(p_cp), median(p_ri), median(delta), median(exp(beta)), median(beta),
      mean(delta > 0), mean(beta < 0)
    ),
    q025 = c(
      quantile(p_cp, 0.025), quantile(p_ri, 0.025), quantile(delta, 0.025),
      quantile(exp(beta), 0.025), quantile(beta, 0.025), NA_real_, NA_real_
    ),
    q975 = c(
      quantile(p_cp, 0.975), quantile(p_ri, 0.975), quantile(delta, 0.975),
      quantile(exp(beta), 0.975), quantile(beta, 0.975), NA_real_, NA_real_
    )
  )
}

normal_targets <- posterior_targets(fit_normal, "Normal(0, 1.5)")
student_targets <- posterior_targets(fit_student, "Student-t(3, 0, 2.5)")
posterior_summary <- dplyr::bind_rows(normal_targets, student_targets)
readr::write_csv(posterior_summary, file.path(tables_dir, "bayesian_area_posterior_summary.csv"))

draws_normal <- posterior::as_draws_df(fit_normal) |>
  dplyr::transmute(
    draw = dplyr::row_number(),
    alpha = b_Intercept,
    beta_area_ri = b_area_ri,
    p_cp = plogis(alpha),
    p_ri = plogis(alpha + beta_area_ri),
    delta_cp_minus_ri = p_cp - p_ri,
    odds_ratio_ri_cp = exp(beta_area_ri)
  )
readr::write_csv(draws_normal, file.path(tables_dir, "bayesian_area_posterior_draws_normal.csv"))

diagnostics_from_fit <- function(fit, prior_label) {
  summary_draws <- posterior::summarise_draws(posterior::as_draws_array(fit))
  divergences <- tryCatch({
    nuts <- brms::nuts_params(fit)
    sum(nuts$Parameter == "divergent__" & nuts$Value == 1)
  }, error = function(e) NA_integer_)
  tibble::tibble(
    prior = prior_label,
    max_rhat = max(summary_draws$rhat, na.rm = TRUE),
    min_ess_bulk = min(summary_draws$ess_bulk, na.rm = TRUE),
    min_ess_tail = min(summary_draws$ess_tail, na.rm = TRUE),
    divergences = divergences
  )
}

diagnostics <- dplyr::bind_rows(
  diagnostics_from_fit(fit_normal, "Normal(0, 1.5)"),
  diagnostics_from_fit(fit_student, "Student-t(3, 0, 2.5)")
)
readr::write_csv(diagnostics, file.path(tables_dir, "bayesian_area_diagnostics.csv"))

ppc_rates <- function(fit) {
  yrep <- brms::posterior_predict(fit, ndraws = 1000, seed = 20260720)
  yrep / matrix(journal_data$n, nrow = nrow(yrep), ncol = nrow(journal_data), byrow = TRUE)
}

ppc_normal <- ppc_rates(fit_normal)
ppc_interval <- tibble::tibble(
  journal_title = journal_data$journal_title,
  observed_rate = journal_data$observed_rate,
  ppc_q025 = apply(ppc_normal, 2, quantile, probs = 0.025),
  ppc_q50 = apply(ppc_normal, 2, quantile, probs = 0.5),
  ppc_q975 = apply(ppc_normal, 2, quantile, probs = 0.975)
) |>
  dplyr::mutate(observed_within_ppc_95 = observed_rate >= ppc_q025 & observed_rate <= ppc_q975)
readr::write_csv(ppc_interval, file.path(tables_dir, "bayesian_area_ppc_journal_rates.csv"))

format_target_line <- function(targets, label) {
  row <- targets |>
    dplyr::filter(parameter == "Diferença CP - RI")
  prob <- targets$estimate[targets$parameter == "P(delta > 0)"]
  paste0(
    label, ": mediana ", fmt_pp(row$estimate),
    "; intervalo de credibilidade de 95% ", fmt_pp(row$q025),
    " a ", fmt_pp(row$q975),
    "; P(delta > 0) = ", fmt_prob(prob), "."
  )
}

normal_main <- normal_targets |>
  dplyr::filter(parameter == "Diferença CP - RI")

report_lines <- c(
  "# Modelo bayesiano hierárquico da diferença CP–RI",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "",
  "## Especificação",
  "",
  "A unidade de verossimilhança é o periódico. Para cada periódico, `y` é o número de artigos quantitativos com inferência estatística e `n` é o número de quantitativos com rótulo de inferência observado. A verossimilhança é binomial, com logit da probabilidade explicado por um indicador de Relações Internacionais e um intercepto aleatório por periódico.",
  "",
  "O modelo principal usa priors `Normal(0, 1,5)` para o intercepto e o efeito de área e `Student-t(3, 0, 1)` para o desvio-padrão dos interceptos aleatórios. A sensibilidade substitui os dois primeiros priors por `Student-t(3, 0, 2,5)`. Os priors são próprios e fracamente informativos; a escolha é motivada por Gelman et al. (2008), que recomendam regularização própria em regressões logísticas, especialmente diante de separação e esparsidade.",
  "",
  "## Dados",
  "",
  paste0(
    "O conjunto tem ", fmt_int(nrow(journal_data)), " periódicos: ",
    sum(journal_data$area_ri == 0), " de CP e ", sum(journal_data$area_ri == 1),
    " de RI. Os denominadores somam ", fmt_int(sum(journal_data$n)),
    " artigos quantitativos com rótulo de inferência observado."
  ),
  "",
  markdown_table(
    journal_data |>
      dplyr::transmute(
        Área = area_group,
        Periódico = journal_title,
        Sucessos = y,
        `Denominador (N)` = n,
        `Proporção observada` = fmt_pct(observed_rate)
      )
  ),
  "",
  "## Posterior",
  "",
  markdown_table(
    posterior_summary |>
      dplyr::transmute(
        Priori = prior,
        Parâmetro = parameter,
        Mediana = estimate,
        `Quantil 2,5%` = q025,
        `Quantil 97,5%` = q975
      )
  ),
  "",
  format_target_line(normal_targets, "Prior Normal"),
  format_target_line(student_targets, "Prior Student-t"),
  "",
  "Os valores de delta são diferenças entre as probabilidades previstas para um periódico médio, mantendo o intercepto aleatório no valor médio da distribuição. Não são efeitos causais da área.",
  "",
  "## Diagnósticos",
  "",
  markdown_table(diagnostics),
  "",
  paste0(
    "No modelo Normal, ", sum(ppc_interval$observed_within_ppc_95), " dos ",
    nrow(ppc_interval), " periódicos têm a proporção observada dentro do intervalo preditivo de 95% para a taxa do periódico."
  ),
  "",
  "## Interpretação e limite",
  "",
  "A análise bayesiana substitui a pergunta binária sobre um p-valor por uma distribuição posterior para a diferença. Como a área é constante dentro do periódico e há apenas dois periódicos de RI, o resultado ainda depende da informação de poucos clusters. A análise deve ser apresentada como quantificação hierárquica da diferença descritiva, não como identificação de um efeito disciplinar.",
  "",
  "## Artefatos",
  "",
  "- `output/tables/area_analysis/bayesian_area_journal_data.csv`",
  "- `output/tables/area_analysis/bayesian_area_posterior_summary.csv`",
  "- `output/tables/area_analysis/bayesian_area_posterior_draws_normal.csv`",
  "- `output/tables/area_analysis/bayesian_area_diagnostics.csv`",
  "- `output/tables/area_analysis/bayesian_area_ppc_journal_rates.csv`",
  "- `data/processed/area_analysis/bayesian_area_normal.rds`",
  "- `data/processed/area_analysis/bayesian_area_student.rds`"
)
write_utf8_lines(report_lines, report_path)

session_lines <- c(
  paste0("generated_at=", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")),
  paste0("input_path=", input_path),
  paste0("input_md5=", unname(tools::md5sum(input_path))),
  paste0("rows_article_level_filtered=", nrow(data)),
  paste0("rows_journal_level=", nrow(journal_data)),
  paste0("cmdstan_version=", cmdstan_version),
  "",
  capture.output(sessionInfo())
)
write_utf8_lines(session_lines, path("data/processed/area_analysis/bayesian_area_session_info.txt"))

message(
  "Modelo bayesiano ajustado. Diferença CP–RI (prior Normal): ",
  fmt_pp(normal_main$estimate),
  " [", fmt_pp(normal_main$q025), "; ", fmt_pp(normal_main$q975), "]"
)
