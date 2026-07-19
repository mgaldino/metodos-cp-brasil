#!/usr/bin/env Rscript

## Modelos logísticos hierárquicos para diferenças entre as categorias
## feminina e masculina inferidas do primeiro prenome. Artigos (nível 1)
## estão agrupados em periódicos permutáveis (nível 2).

options(scipen = 999, encoding = "UTF-8")
set.seed(20260719)

required_packages <- c("brms", "cmdstanr", "dplyr", "ggplot2", "posterior", "readr", "stringr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]
if (length(missing_packages) > 0) stop("Pacotes ausentes: ", paste(missing_packages, collapse = ", "))

suppressPackageStartupMessages({
  library(brms)
  library(dplyr)
  library(ggplot2)
  library(posterior)
  library(readr)
  library(stringr)
})

file_arg <- commandArgs(trailingOnly = FALSE) |>
  stringr::str_subset("^--file=") |>
  stringr::str_remove("^--file=")
if (length(file_arg) != 1) stop("Não foi possível identificar o caminho do script.")
project_dir <- normalizePath(file.path(dirname(file_arg), ".."), mustWork = TRUE)
path <- function(...) file.path(project_dir, ...)

input_path <- path("data/processed/gender_analysis/current_canonical_article_gender.csv")
models_dir <- path("data/processed/gender_analysis/bayesian_models")
tables_dir <- path("output/tables/gender_analysis")
figures_dir <- path("output/figures/gender_analysis")
report_path <- path("quality_reports/gender_analysis_bayesian_hierarchical.md")
for (directory in c(models_dir, tables_dir, figures_dir)) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
}
if (!file.exists(input_path)) {
  stop("Execute primeiro scripts/51_analyze_gender_current_canonical.R.")
}

chains <- as.integer(Sys.getenv("GENDER_BAYES_CHAINS", "4"))
iter <- as.integer(Sys.getenv("GENDER_BAYES_ITER", "2000"))
warmup <- as.integer(Sys.getenv("GENDER_BAYES_WARMUP", "1000"))
parallel_chains <- min(chains, as.integer(Sys.getenv("GENDER_BAYES_PARALLEL_CHAINS", as.character(chains))))
adapt_delta <- as.numeric(Sys.getenv("GENDER_BAYES_ADAPT_DELTA", "0.99"))
max_treedepth <- as.integer(Sys.getenv("GENDER_BAYES_MAX_TREEDEPTH", "12"))
seed <- 20260719L
rope_pp <- 2
if (any(is.na(c(chains, iter, warmup, parallel_chains, max_treedepth))) ||
    chains < 2 || iter <= warmup || warmup < 1 || parallel_chains < 1) {
  stop("Configuração MCMC inválida nas variáveis GENDER_BAYES_*.")
}

period_levels <- c("2005-2011", "2012-2018", "2019-2025")
metric_levels <- c(
  "Artigos empíricos", "Análise quantitativa", "Inferência estatística",
  "Linguagem causal ou explicativa", "Examinados para identificação",
  "Estratégia explícita de identificação"
)
metric_slugs <- c(
  "Artigos empíricos" = "empirical", "Análise quantitativa" = "quantitative",
  "Inferência estatística" = "inference", "Linguagem causal ou explicativa" = "causal_language",
  "Examinados para identificação" = "screened_identification",
  "Estratégia explícita de identificação" = "strict_identification"
)
challenging_metrics <- c(
  "Análise quantitativa",
  "Linguagem causal ou explicativa",
  "Estratégia explícita de identificação"
)
denominator_definitions <- c(
  "Artigos empíricos" = "todos os artigos com primeiro prenome classificado",
  "Análise quantitativa" = "artigos empíricos com classificação quantitativa observada",
  "Inferência estatística" = "artigos quantitativos com inferência observada",
  "Linguagem causal ou explicativa" = "artigos empíricos com linguagem observada",
  "Examinados para identificação" = "artigos com screen observado",
  "Estratégia explícita de identificação" = "artigos examinados para identificação"
)

fmt_int <- function(x) format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
fmt_num <- function(x, digits = 1) format(round(x, digits), decimal.mark = ",", nsmall = digits, trim = TRUE)
fmt_pp <- function(x, digits = 1) paste0(ifelse(x > 0, "+", ""), fmt_num(x, digits), " p.p.")
fmt_prob <- function(x) ifelse(x > 0.999, "> 0,999", ifelse(x < 0.001, "< 0,001", fmt_num(x, 3)))
escape_md <- function(x) x |> as.character() |> stringr::str_replace_all("\\|", "\\\\|") |> stringr::str_replace_all("\\r?\\n", " ")
markdown_table <- function(data) {
  data_chr <- data |>
    dplyr::mutate(dplyr::across(dplyr::everything(), ~ escape_md(dplyr::coalesce(as.character(.x), "-"))))
  c(
    paste0("| ", paste(names(data_chr), collapse = " | "), " |"),
    paste0("| ", paste(rep("---", ncol(data_chr)), collapse = " | "), " |"),
    apply(data_chr, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  )
}
write_utf8_lines <- function(lines, file) {
  connection <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(connection), add = TRUE)
  writeLines(enc2utf8(lines), con = connection, useBytes = TRUE)
}

article_gender <- readr::read_csv(input_path, show_col_types = FALSE) |>
  dplyr::mutate(
    period_3 = factor(period_3, levels = period_levels),
    journal_title = factor(journal_title),
    female = dplyr::case_when(
      first_author_gender == "Feminino" ~ 1,
      first_author_gender == "Masculino" ~ 0,
      TRUE ~ NA_real_
    ),
    author_id = factor(stringr::str_to_lower(stringr::str_squish(first_author_name)))
  )
if (anyDuplicated(article_gender$pid) > 0) stop("A base contém PIDs duplicados.")
if (any(is.na(article_gender$period_3))) stop("Há períodos ausentes ou inválidos.")
if (dplyr::n_distinct(article_gender$journal_title) != 9) stop("Esperavam-se nove periódicos elegíveis.")
binary_gender <- article_gender |> dplyr::filter(!is.na(female))

build_metric_data <- function(data, metric_name) {
  if (metric_name == "Artigos empíricos") {
    eligible <- !is.na(data$is_empirical_paper); outcome <- data$is_empirical_paper
  } else if (metric_name == "Análise quantitativa") {
    eligible <- data$is_empirical_paper %in% TRUE & !is.na(data$is_empirical_quant_paper_torreblanca)
    outcome <- data$is_empirical_quant_paper_torreblanca
  } else if (metric_name == "Inferência estatística") {
    eligible <- data$is_empirical_quant_paper_torreblanca %in% TRUE & !is.na(data$has_statistical_inference)
    outcome <- data$has_statistical_inference
  } else if (metric_name == "Linguagem causal ou explicativa") {
    eligible <- data$is_empirical_paper %in% TRUE & !is.na(data$causal_or_explanatory_claim_present)
    outcome <- data$causal_or_explanatory_claim_present
  } else if (metric_name == "Examinados para identificação") {
    eligible <- !is.na(data$credibility_revolution_screen_applicable)
    outcome <- data$credibility_revolution_screen_applicable
  } else if (metric_name == "Estratégia explícita de identificação") {
    eligible <- data$credibility_revolution_screen_applicable %in% TRUE
    outcome <- data$strict_design_method
  } else stop("Indicador desconhecido: ", metric_name)
  data |>
    dplyr::mutate(eligible = eligible, outcome = as.integer(outcome)) |>
    dplyr::filter(eligible, !is.na(outcome)) |>
    dplyr::select(pid, author_id, journal_title, period_3, female, outcome) |>
    droplevels()
}

model_formula <- brms::bf(
  outcome ~ 1 + female + period_3 + (1 + female | journal_title) + (1 | author_id),
  family = bernoulli(link = "logit")
)
model_priors <- c(
  brms::prior(student_t(3, 0, 2.5), class = "Intercept"),
  brms::prior(normal(0, 0.75), class = "b"),
  brms::prior(student_t(3, 0, 1), class = "sd"),
  brms::prior(lkj(2), class = "cor")
)

summarize_contrast <- function(draws) {
  tibble::tibble(
    posterior_mean_pp = mean(draws), posterior_median_pp = stats::median(draws),
    credible_interval_95_low_pp = stats::quantile(draws, 0.025, names = FALSE),
    credible_interval_95_high_pp = stats::quantile(draws, 0.975, names = FALSE),
    posterior_probability_positive = mean(draws > 0),
    posterior_probability_negative = mean(draws < 0),
    posterior_probability_in_rope = mean(abs(draws) <= rope_pp),
    posterior_probability_above_positive_rope = mean(draws > rope_pp),
    posterior_probability_below_negative_rope = mean(draws < -rope_pp)
  )
}

contrast_draws <- function(fit, model_data, current_journal = NULL) {
  cells <- model_data
  if (!is.null(current_journal)) cells <- cells |> dplyr::filter(journal_title == current_journal)
  cells <- cells |>
    dplyr::count(journal_title, period_3, name = "n") |>
    dplyr::mutate(weight = n / sum(n)) |>
    dplyr::arrange(journal_title, period_3)
  female_cells <- cells |> dplyr::mutate(female = 1) |> dplyr::select(journal_title, period_3, female)
  male_cells <- cells |> dplyr::mutate(female = 0) |> dplyr::select(journal_title, period_3, female)
  journal_re_formula <- stats::as.formula("~ (1 + female | journal_title)")
  p_female <- brms::posterior_epred(fit, newdata = female_cells, re_formula = journal_re_formula)
  p_male <- brms::posterior_epred(fit, newdata = male_cells, re_formula = journal_re_formula)
  as.numeric(100 * ((p_female - p_male) %*% cells$weight))
}

extract_diagnostics <- function(fit, metric_name, model_data, model_iter, model_warmup) {
  convergence <- posterior::summarise_draws(posterior::as_draws_array(fit))
  nuts <- brms::nuts_params(fit)
  n_divergent <- nuts |> dplyr::filter(Parameter == "divergent__") |> dplyr::summarise(n = sum(Value > 0)) |> dplyr::pull(n)
  n_max_treedepth <- nuts |> dplyr::filter(Parameter == "treedepth__") |> dplyr::summarise(n = sum(Value >= max_treedepth)) |> dplyr::pull(n)
  y_rep <- brms::posterior_predict(fit, ndraws = min(500L, chains * (iter - warmup)))
  rep_prevalence <- rowMeans(y_rep)
  tibble::tibble(
    metric = metric_name, n_articles = nrow(model_data), n_events = sum(model_data$outcome),
    iterations_per_chain = model_iter, warmup_per_chain = model_warmup,
    n_authors = dplyr::n_distinct(model_data$author_id),
    n_journals = dplyr::n_distinct(model_data$journal_title), observed_prevalence = mean(model_data$outcome),
    posterior_predictive_mean = mean(rep_prevalence),
    posterior_predictive_low = stats::quantile(rep_prevalence, 0.025, names = FALSE),
    posterior_predictive_high = stats::quantile(rep_prevalence, 0.975, names = FALSE),
    max_rhat = max(convergence$rhat, na.rm = TRUE), min_ess_bulk = min(convergence$ess_bulk, na.rm = TRUE),
    min_ess_tail = min(convergence$ess_tail, na.rm = TRUE), divergent_transitions = n_divergent,
    max_treedepth_transitions = n_max_treedepth
  )
}

extract_grouped_ppc <- function(fit, metric_name, model_data) {
  y_rep <- brms::posterior_predict(fit, ndraws = min(300L, chains * (iter - warmup)))
  group_ids <- list(
    `Categoria do prenome` = ifelse(model_data$female == 1, "Feminino", "Masculino"),
    Periódico = as.character(model_data$journal_title),
    Período = as.character(model_data$period_3),
    `Periódico × categoria × período` = interaction(
      model_data$journal_title,
      ifelse(model_data$female == 1, "Feminino", "Masculino"),
      model_data$period_3,
      drop = TRUE,
      sep = " | "
    )
  )
  lapply(names(group_ids), function(grouping_name) {
    current_groups <- group_ids[[grouping_name]]
    lapply(sort(unique(current_groups)), function(group_label) {
      index <- which(current_groups == group_label)
      replicated_rate <- rowMeans(y_rep[, index, drop = FALSE])
      observed_rate <- mean(model_data$outcome[index])
      tibble::tibble(
        metric = metric_name,
        grouping = grouping_name,
        group = group_label,
        n_articles = length(index),
        observed_rate = observed_rate,
        posterior_predictive_mean = mean(replicated_rate),
        posterior_predictive_low = stats::quantile(replicated_rate, 0.025, names = FALSE),
        posterior_predictive_high = stats::quantile(replicated_rate, 0.975, names = FALSE),
        observed_within_interval = observed_rate >= posterior_predictive_low &
          observed_rate <= posterior_predictive_high
      )
    }) |>
      dplyr::bind_rows()
  }) |>
    dplyr::bind_rows()
}

fit_one_model <- function(model_data, metric_name) {
  sampling_suffix <- if (metric_name %in% challenging_metrics) "_long" else ""
  model_path <- file.path(
    models_dir,
    paste0("gender_", unname(metric_slugs[[metric_name]]), sampling_suffix)
  )
  model_iter <- if (metric_name %in% challenging_metrics) 2L * iter else iter
  model_warmup <- if (metric_name %in% challenging_metrics) 2L * warmup else warmup
  brms::brm(
    formula = model_formula, data = model_data, prior = model_priors, backend = "cmdstanr",
    chains = chains, iter = model_iter, warmup = model_warmup, cores = parallel_chains,
    seed = seed, sample_prior = "yes",
    control = list(adapt_delta = adapt_delta, max_treedepth = max_treedepth),
    refresh = 200, file = model_path, file_refit = "on_change"
  )
}

model_data_list <- lapply(metric_levels, function(x) build_metric_data(binary_gender, x))
names(model_data_list) <- metric_levels
for (metric_name in metric_levels) {
  current <- model_data_list[[metric_name]]
  if (nrow(current) == 0 || length(unique(current$outcome)) != 2) stop("Desfecho sem variação: ", metric_name)
  if (dplyr::n_distinct(current$journal_title) != 9) stop("Periódicos ausentes em: ", metric_name)
}

fits <- overall_draws <- overall_results <- journal_results <- diagnostic_results <- grouped_ppc_results <- list()
for (metric_name in metric_levels) {
  message("Ajustando modelo: ", metric_name)
  current_data <- model_data_list[[metric_name]]
  current_fit <- fit_one_model(current_data, metric_name)
  model_iter <- if (metric_name %in% challenging_metrics) 2L * iter else iter
  model_warmup <- if (metric_name %in% challenging_metrics) 2L * warmup else warmup
  fits[[metric_name]] <- current_fit
  overall_draws[[metric_name]] <- contrast_draws(current_fit, current_data)
  overall_results[[metric_name]] <- summarize_contrast(overall_draws[[metric_name]]) |>
    dplyr::mutate(
      metric = metric_name, denominator_definition = unname(denominator_definitions[[metric_name]]),
      n_articles = nrow(current_data), n_events = sum(current_data$outcome),
      raw_percent_female = 100 * mean(current_data$outcome[current_data$female == 1]),
      raw_percent_male = 100 * mean(current_data$outcome[current_data$female == 0]), .before = 1
    )
  journal_results[[metric_name]] <- lapply(levels(current_data$journal_title), function(current_journal) {
    summarize_contrast(contrast_draws(current_fit, current_data, current_journal)) |>
      dplyr::mutate(
        metric = metric_name, journal_title = current_journal,
        n_articles = sum(current_data$journal_title == current_journal), .before = 1
      )
  }) |> dplyr::bind_rows()
  diagnostic_results[[metric_name]] <- extract_diagnostics(
    current_fit, metric_name, current_data, model_iter, model_warmup
  )
  grouped_ppc_results[[metric_name]] <- extract_grouped_ppc(current_fit, metric_name, current_data)
}

overall_summary <- dplyr::bind_rows(overall_results) |>
  dplyr::mutate(metric = factor(metric, levels = metric_levels)) |> dplyr::arrange(metric)
journal_summary <- dplyr::bind_rows(journal_results) |>
  dplyr::mutate(metric = factor(metric, levels = metric_levels)) |> dplyr::arrange(metric, journal_title)
diagnostics <- dplyr::bind_rows(diagnostic_results) |>
  dplyr::mutate(
    metric = factor(metric, levels = metric_levels),
    convergence_pass = max_rhat < 1.01 & min_ess_bulk >= 400 & min_ess_tail >= 400 &
      divergent_transitions == 0 & max_treedepth_transitions == 0,
    posterior_predictive_pass = observed_prevalence >= posterior_predictive_low &
      observed_prevalence <= posterior_predictive_high
  ) |> dplyr::arrange(metric)
grouped_ppc <- dplyr::bind_rows(grouped_ppc_results) |>
  dplyr::mutate(metric = factor(metric, levels = metric_levels)) |>
  dplyr::arrange(metric, grouping, group)
rope_sensitivity <- lapply(metric_levels, function(metric_name) {
  lapply(c(1, 2, 3, 5), function(current_rope) {
    draws <- overall_draws[[metric_name]]
    tibble::tibble(
      metric = metric_name,
      rope_pp = current_rope,
      posterior_probability_in_rope = mean(abs(draws) <= current_rope),
      posterior_probability_above_positive_rope = mean(draws > current_rope),
      posterior_probability_below_negative_rope = mean(draws < -current_rope)
    )
  }) |> dplyr::bind_rows()
}) |>
  dplyr::bind_rows() |>
  dplyr::mutate(metric = factor(metric, levels = metric_levels)) |>
  dplyr::arrange(metric, rope_pp)

validation_checks <- tibble::tibble(
  check = c(
    "PIDs únicos na base de entrada", "Apenas categorias binárias entram nos modelos",
    "Nove periódicos em todos os denominadores", "Desfechos binários com variação",
    "R-hat, ESS e amostragem NUTS aprovados",
    "Prevalência observada coberta pela checagem preditiva posterior",
    "Probabilidades posteriores dentro de [0, 1]"
  ),
  value = c(
    anyDuplicated(article_gender$pid) == 0,
    all(binary_gender$first_author_gender %in% c("Feminino", "Masculino")),
    all(diagnostics$n_journals == 9),
    all(diagnostics$n_events > 0 & diagnostics$n_events < diagnostics$n_articles),
    all(diagnostics$convergence_pass), all(diagnostics$posterior_predictive_pass),
    all(dplyr::between(overall_summary$posterior_probability_positive, 0, 1) &
      dplyr::between(overall_summary$posterior_probability_in_rope, 0, 1))
  )
) |> dplyr::mutate(status = ifelse(value, "PASS", "FAIL"))

readr::write_csv(overall_summary, file.path(tables_dir, "table_13_bayesian_hierarchical_gender_effects.csv"))
readr::write_csv(journal_summary, file.path(tables_dir, "table_14_bayesian_gender_effects_by_journal.csv"))
readr::write_csv(diagnostics, file.path(tables_dir, "table_15_bayesian_model_diagnostics.csv"))
readr::write_csv(grouped_ppc, file.path(tables_dir, "table_16_bayesian_grouped_ppc.csv"))
readr::write_csv(rope_sensitivity, file.path(tables_dir, "table_17_bayesian_rope_sensitivity.csv"))
readr::write_csv(validation_checks, file.path(tables_dir, "bayesian_validation_checks.csv"))

figure_data <- overall_summary |>
  dplyr::mutate(
    metric = factor(metric, levels = rev(metric_levels)),
    direction = dplyr::case_when(
      posterior_probability_above_positive_rope >= 0.95 ~ "Maior na categoria feminina",
      posterior_probability_below_negative_rope >= 0.95 ~ "Menor na categoria feminina",
      TRUE ~ "Inconclusivo ou pequeno"
    )
  )
figure_3 <- figure_data |>
  ggplot2::ggplot(ggplot2::aes(
    x = posterior_mean_pp, y = metric, xmin = credible_interval_95_low_pp,
    xmax = credible_interval_95_high_pp, color = direction
  )) +
  ggplot2::annotate("rect", xmin = -rope_pp, xmax = rope_pp, ymin = -Inf, ymax = Inf,
    fill = "#D9D9D9", alpha = 0.35) +
  ggplot2::geom_vline(xintercept = 0, color = "#4D4D4D", linewidth = 0.45) +
  ggplot2::geom_errorbar(orientation = "y", width = 0, linewidth = 0.8) +
  ggplot2::geom_point(size = 2.8) +
  ggplot2::scale_color_manual(values = c(
    "Maior na categoria feminina" = "#B33A6F", "Menor na categoria feminina" = "#285F8F",
    "Inconclusivo ou pequeno" = "#666666"
  )) +
  ggplot2::labs(
    x = "Diferença posterior média: feminino − masculino (pontos percentuais)",
    y = NULL, color = NULL
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), legend.position = "bottom")
ggplot2::ggsave(
  file.path(figures_dir, "figure_3_bayesian_hierarchical_gender_effects.png"),
  figure_3, width = 9.2, height = 5.8, units = "in", dpi = 320
)

report_table <- overall_summary |>
  dplyr::transmute(
    Indicador = as.character(metric), N = fmt_int(n_articles),
    `Diferença posterior média F−M` = fmt_pp(posterior_mean_pp),
    `ICr 95%` = paste0("[", fmt_pp(credible_interval_95_low_pp), "; ", fmt_pp(credible_interval_95_high_pp), "]"),
    `Pr(F−M > 0)` = fmt_prob(posterior_probability_positive),
    `Pr(F−M < −2 p.p.)` = fmt_prob(posterior_probability_below_negative_rope),
    `Pr(F−M > +2 p.p.)` = fmt_prob(posterior_probability_above_positive_rope),
    `Pr(ROPE ±2 p.p.)` = fmt_prob(posterior_probability_in_rope)
  )
diagnostic_table <- diagnostics |>
  dplyr::transmute(
    Indicador = as.character(metric), N = fmt_int(n_articles), Eventos = fmt_int(n_events),
    `Iterações (warmup)` = paste0(fmt_int(iterations_per_chain), " (", fmt_int(warmup_per_chain), ")"),
    `R-hat máximo` = fmt_num(max_rhat, 3), `ESS bulk mínimo` = fmt_int(round(min_ess_bulk)),
    `ESS tail mínimo` = fmt_int(round(min_ess_tail)), `Divergências` = fmt_int(divergent_transitions),
    `Saturações de treedepth` = fmt_int(max_treedepth_transitions),
    `PPC prevalência` = ifelse(posterior_predictive_pass, "PASS", "FAIL")
  )
strong_negative <- overall_summary |> dplyr::filter(posterior_probability_below_negative_rope >= 0.95) |> dplyr::pull(metric) |> as.character()
strong_positive <- overall_summary |> dplyr::filter(posterior_probability_above_positive_rope >= 0.95) |> dplyr::pull(metric) |> as.character()
inconclusive <- setdiff(metric_levels, c(strong_negative, strong_positive))
list_metrics <- function(x) if (length(x) == 0) "nenhum indicador" else paste(x, collapse = "; ")
session_versions <- c(
  paste0("R ", getRversion()), paste0("brms ", packageVersion("brms")),
  paste0("cmdstanr ", packageVersion("cmdstanr")), paste0("posterior ", packageVersion("posterior")),
  paste0("CmdStan ", cmdstanr::cmdstan_version())
)

report_lines <- c(
  "# Análise bayesiana hierárquica por classificação binária do primeiro prenome", "",
  "**Data de execução:** 2026-07-19", "", "## Síntese", "",
  paste0(
    "A inferência principal substitui os testes separados de proporções e o ajuste de Mantel–Haenszel por seis modelos logísticos hierárquicos. ",
    "Os artigos formam o primeiro nível; os nove periódicos elegíveis são tratados como unidades permutáveis no segundo nível. ",
    "Tanto o intercepto quanto a diferença associada à categoria feminina variam entre periódicos e recebem pooling parcial; um intercepto cruzado por primeiro autor acomoda publicações repetidas da mesma pessoa."
  ), "",
  paste0(
    "Há probabilidade posterior de pelo menos 95% de uma diferença menor que −2 p.p. para: ",
    list_metrics(strong_negative), ". Há probabilidade posterior de pelo menos 95% de uma diferença maior que +2 p.p. para: ",
    list_metrics(strong_positive), ". Os demais resultados são inconclusivos ou pequenos segundo essa margem: ",
    list_metrics(inconclusive), "."
  ), "",
  "As estimativas são descritivas e correlacionais. O modelo descreve associações condicionais a periódico e período; não identifica efeito causal de gênero.",
  "", "## Especificação", "",
  "Para cada indicador binário pré-especificado, foi ajustado:", "",
  "`logit Pr(y_iaj = 1) = α_j + β_j Feminino_iaj + γ_2 Período2_iaj + γ_3 Período3_iaj + u_a`,", "",
  "em que `(α_j, β_j)` segue uma distribuição normal multivariada entre periódicos e `u_a` é um intercepto aleatório do primeiro autor. O contraste reportado é a diferença posterior de probabilidade entre `Feminino = 1` e `Feminino = 0`, padronizada pela composição observada de periódico e período no denominador de cada indicador e avaliada em `u_a = 0` (autor típico).",
  "",
  "O pooling parcial regulariza sobretudo os contrastes de periódicos com poucos artigos ou eventos. Por isso não se corrigem p-valores para as nove comparações: elas são estimadas conjuntamente. O argumento segue Gelman, Hill e Yajima (2012), que recomendam modelagem multilevel quando efeitos relacionados são permutáveis.",
  "",
  "Aqui, permutabilidade é uma hipótese operacional de regularização entre os nove periódicos observados, não uma afirmação de que eles tenham o mesmo escopo editorial. O estimando não é generalizado a uma população abstrata de periódicos nem a títulos fora da base.",
  "",
  "Ressalva: os seis indicadores são desfechos distintos e foram estimados separadamente. O pooling entre periódicos não elimina automaticamente a multiplicidade entre desfechos; todas as seis comparações são exploratórias e não constituem uma regra de descoberta. Reportam-se a distribuição posterior, a direção e a probabilidade de diferença substantiva maior que 2 p.p.",
  "", "## Resultados", "",
  "**Tabela 1. Diferenças posteriores padronizadas entre as categorias feminina e masculina do primeiro prenome**", "",
  markdown_table(report_table), "",
  "*Nota:* F−M é feminino menos masculino. ICr é o intervalo de credibilidade posterior de 95%. A ROPE de ±2 p.p. é uma margem descritiva de equivalência prática, não um limiar universal.",
  "",
  "Como ±2 p.p. não tem a mesma importância relativa em desfechos raros e comuns, `output/tables/gender_analysis/table_17_bayesian_rope_sensitivity.csv` reapresenta as probabilidades para margens de ±1, ±2, ±3 e ±5 p.p.; o ICr e a probabilidade de direção permanecem as medidas sem dependência dessa escolha.",
  "", "![Diferenças posteriores hierárquicas](../output/figures/gender_analysis/figure_3_bayesian_hierarchical_gender_effects.png)", "",
  "*Figura 1. Diferenças posteriores padronizadas entre as categorias feminina e masculina do primeiro prenome.* As barras são ICr de 95%; a faixa cinza é a ROPE de ±2 p.p.",
  "",
  "Os contrastes parcialmente agrupados por periódico estão em `output/tables/gender_analysis/table_14_bayesian_gender_effects_by_journal.csv`. Com nove periódicos, a heterogeneidade entre eles tem incerteza relevante.",
  "", "## Priors", "",
  "Foram usadas priors fracamente informativas, não priors impróprias ou supostamente não informativas:", "",
  "- intercepto global: Student-t(3, 0, 2,5);",
  "- coeficientes globais de gênero e período: Normal(0, 0,75) na escala logit;",
  "- desvios-padrão dos efeitos aleatórios de periódico e autor: half-Student-t(3, 0, 1);",
  "- correlação entre intercepto e contraste do periódico: LKJ(2).", "",
  "A regularização segue Gelman (2006) para priors half-t em escalas hierárquicas e Gelman et al. (2008) para priors fracamente informativas em regressão logística. Priors próprias estabilizam especialmente o indicador raro de estratégia explícita de identificação.",
  "", "## Diagnósticos", "",
  "**Tabela 2. Diagnósticos dos modelos bayesianos hierárquicos**", "",
  markdown_table(diagnostic_table), "",
  paste0(
    "*Nota:* cada modelo usou ", chains, " cadeias e a quantidade de iterações indicada na tabela, ",
    "`adapt_delta = ", adapt_delta, "` e `max_treedepth = ",
    max_treedepth, "`. PASS exige R-hat < 1,01, ESS bulk e tail mínimos ≥ 400, nenhuma divergência, ",
    "nenhuma saturação de treedepth e prevalência observada dentro do intervalo preditivo posterior de 95%."
  ), "",
  "Checagens preditivas adicionais por categoria do prenome, periódico, período e pela combinação desses três eixos estão em `output/tables/gender_analysis/table_16_bayesian_grouped_ppc.csv`. Células pequenas podem ficar fora de intervalos pontuais de 95%; por isso essa tabela é diagnóstico localizado, não um novo teste múltiplo.",
  "", "## População e limites", "",
  "A entrada é derivada do CSV canônico corrente e exclui `Lua Nova: Revista de Cultura e Política`, `Novos estudos CEBRAP`, `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais`. Somente artigos cujo primeiro prenome foi classificado como feminino ou masculino entram nos modelos.",
  "",
  "A proxy não observa identidade de gênero, exclui identidades não binárias e tem não classificação diferencial. A ordem de autoria não mede contribuição. O intercepto de autor usa o nome completo normalizado como identificador aproximado: pode unir homônimos ou separar variantes da mesma pessoa. O modelo não trata a classificação como incerta e não controla subcampo, idioma ou coautoria.",
  "",
  "Os denominadores são condicionais e não diretamente comparáveis: inferência estatística é estimada entre artigos quantitativos, e estratégia explícita entre artigos examinados para identificação. Esses recortes podem introduzir seleção. A análise descritiva anterior mostrou estabilidade bruta nos limiares de classificação 0,80, 0,90 e 0,95; os modelos hierárquicos não propagam essa incerteza nem imputam os 187 casos não classificados.",
  "", "## Reprodutibilidade", "",
  "- Script gerador: `scripts/54_fit_bayesian_gender_hierarchical.R`.",
  "- Base de entrada: `data/processed/gender_analysis/current_canonical_article_gender.csv`, gerada por `scripts/51_analyze_gender_current_canonical.R`.",
  paste0("- MD5 da base de entrada: `", unname(tools::md5sum(input_path)), "`."),
  paste0("- Ambiente: `", paste(session_versions, collapse = "; "), "`."),
  "- Os objetos `brmsfit` são cache local em `data/processed/gender_analysis/bayesian_models/` e não são versionados devido ao tamanho.",
  "", "## Referências metodológicas", "",
  "- Gelman, A. (2006). Prior distributions for variance parameters in hierarchical models. *Bayesian Analysis*, 1(3), 515–534. https://doi.org/10.1214/06-BA117A",
  "- Gelman, A., Jakulin, A., Pittau, M. G., & Su, Y.-S. (2008). A weakly informative default prior distribution for logistic and other regression models. *The Annals of Applied Statistics*, 2(4), 1360–1383. https://doi.org/10.1214/08-AOAS191",
  "- Gelman, A., Hill, J., & Yajima, M. (2012). Why we (usually) don’t have to worry about multiple comparisons. *Journal of Research on Educational Effectiveness*, 5(2), 189–211. https://doi.org/10.1080/19345747.2011.618213",
  "", "## Validações automáticas", "",
  "**Tabela 3. Validações da análise bayesiana**", "",
  markdown_table(validation_checks |> dplyr::transmute(Validação = check, Status = status))
)
write_utf8_lines(report_lines, report_path)
if (any(validation_checks$status == "FAIL")) {
  failed <- validation_checks |> dplyr::filter(status == "FAIL") |> dplyr::pull(check)
  stop("Outputs escritos para auditoria, mas validações falharam: ", paste(failed, collapse = "; "))
}
message("Análise bayesiana concluída: ", report_path)
