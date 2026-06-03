## 07_prepare_manual_review_queue.R
## Prepara a fila de revisão manual das classificações normalizadas.

options(scipen = 999)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

project_dir <- normalizePath(".", mustWork = TRUE)

paths <- list(
  normalization_log = file.path(project_dir, "quality_reports", "classification_normalization_log.csv"),
  sample_sheet = file.path(project_dir, "data", "processed", "sample_validation_sheet.csv"),
  sample_validation = file.path(project_dir, "data", "processed", "sample_validation.csv"),
  normalized_csv = file.path(project_dir, "data", "processed", "classifications_llm_normalized.csv"),
  excluded_journals = file.path(project_dir, "data", "processed", "excluded_journals.csv"),
  excluded_articles = file.path(project_dir, "data", "processed", "excluded_articles.csv"),
  queue = file.path(project_dir, "quality_reports", "manual_review_queue.csv"),
  excluded_queue = file.path(project_dir, "quality_reports", "manual_review_queue_excluded_journals.csv"),
  excluded_article_queue = file.path(project_dir, "quality_reports", "manual_review_queue_excluded_articles.csv"),
  queue_by_article = file.path(project_dir, "quality_reports", "manual_review_queue_by_article.csv"),
  codebook = file.path(project_dir, "quality_reports", "manual_review_codebook.md"),
  summary = file.path(project_dir, "quality_reports", "manual_review_queue_summary.md")
)

required_files <- c(paths$normalization_log, paths$sample_sheet, paths$sample_validation, paths$normalized_csv)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  stop("Arquivos ausentes: ", paste(missing_files, collapse = "; "))
}

allowed_values <- list(
  error_in_raw_text = c("No Error", "Missing/Corrupt", "Title/Text Mismatch"),
  is_empirical_quant_paper = c("TRUE", "FALSE"),
  paper_uses_survey_data = c("no_survey_data", "runs_original_survey", "uses_public_available_survey"),
  uses_original_dataset = c("original_survey", "field_experiment", "field_study", "structure_systematize", "procure_original_data", "other_original_data", "not_original", "<NULL>"),
  general_goal_of_analysis = c("Describe", "Predict", "Explain", "<NULL>"),
  single_country_study = c("single_country", "multiple_countries", "<NULL>"),
  single_region = c("single_region", "multiple_region", "<NULL>"),
  evidence_type = c("quantitative", "qualitative", "mixed", "theoretical-normative"),
  method_status = c("explicit", "essayistic"),
  effort_to_explore_mechanisms = c("No Mention of Mechanisms/Channels", "Mechanisms/Channels Mentioned But Not Explored", "Mechanisms/Channels Mentioned With Substantial Exploration", "<NULL>"),
  main_variable_relationship = c("<NULL>", "structured_json_required")
)

field_priority <- c(
  error_in_raw_text = 1,
  is_empirical_quant_paper = 2,
  paper_uses_survey_data = 3,
  evidence_type = 4,
  method_status = 5,
  general_goal_of_analysis = 6,
  single_country_study = 7,
  single_region = 8,
  uses_original_dataset = 9,
  effort_to_explore_mechanisms = 10,
  main_variable_relationship = 11
)

collapse_allowed <- function(field) {
  vals <- allowed_values[[field]]
  if (is.null(vals)) {
    return("")
  }
  paste(vals, collapse = " | ")
}

decision_hint <- function(field, old_value, reason) {
  dplyr::case_when(
    field == "general_goal_of_analysis" ~ "Escolha Describe/Predict/Explain só se o objetivo analítico estiver claro; caso contrário use <NULL>.",
    field == "method_status" ~ "Use explicit se o artigo declara método/procedimento; use essayistic se não há método explícito.",
    field == "evidence_type" ~ "Classifique a evidência principal do artigo: quantitative, qualitative, mixed ou theoretical-normative.",
    field == "effort_to_explore_mechanisms" ~ "Marque No Mention se não houver mecanismos; Mentioned But Not Explored se só menciona; Substantial Exploration se analisa mecanismos.",
    field == "single_country_study" ~ "Use single_country para um país focal; multiple_countries para comparação cross-country; <NULL> se não aplicável.",
    field == "single_region" ~ "Use single_region/multiple_region apenas para escopo regional claro; <NULL> se não aplicável.",
    field == "paper_uses_survey_data" ~ "Se TRUE antigo: decidir entre runs_original_survey e uses_public_available_survey; se não há survey, no_survey_data.",
    field == "uses_original_dataset" ~ "Decida tipo de dado original; use not_original se não há dados originais; <NULL> se não aplicável.",
    field == "error_in_raw_text" ~ "Checar se texto/XML está ausente, corrompido ou incompatível com título.",
    field == "is_empirical_quant_paper" ~ "TRUE apenas se há análise própria de dados quantitativos observacionais/experimentais.",
    field == "main_variable_relationship" ~ "Use <NULL> salvo se for codificar JSON estruturado com IV/DV/relação.",
    TRUE ~ reason
  )
}

log <- readr::read_csv(paths$normalization_log, show_col_types = FALSE, progress = FALSE)
sample_sheet <- readr::read_csv(paths$sample_sheet, show_col_types = FALSE, progress = FALSE)
sample_validation <- readr::read_csv(paths$sample_validation, show_col_types = FALSE, progress = FALSE)
normalized <- readr::read_csv(paths$normalized_csv, show_col_types = FALSE, progress = FALSE)
excluded_journals <- if (file.exists(paths$excluded_journals)) {
  readr::read_csv(paths$excluded_journals, show_col_types = FALSE, progress = FALSE) |>
    dplyr::filter(exclude_from_analysis) |>
    dplyr::select(
      issn,
      excluded_journal_title = journal_title,
      excluded_by_journal = exclude_from_analysis,
      exclusion_reason,
      exclusion_decision_by = decision_by,
      exclusion_decision_date = decision_date,
      exclusion_notes = notes
    )
} else {
  tibble(
    issn = character(),
    excluded_journal_title = character(),
    excluded_by_journal = logical(),
    exclusion_reason = character(),
    exclusion_decision_by = character(),
    exclusion_decision_date = character(),
    exclusion_notes = character()
  )
}
excluded_articles <- if (file.exists(paths$excluded_articles)) {
  readr::read_csv(paths$excluded_articles, show_col_types = FALSE, progress = FALSE) |>
    dplyr::filter(exclude_from_analysis) |>
    dplyr::select(
      pid,
      excluded_by_article = exclude_from_analysis,
      article_exclusion_reason = exclusion_reason,
      article_exclusion_decision_by = decision_by,
      article_exclusion_decision_date = decision_date,
      article_exclusion_notes = notes
    )
} else {
  tibble(
    pid = character(),
    excluded_by_article = logical(),
    article_exclusion_reason = character(),
    article_exclusion_decision_by = character(),
    article_exclusion_decision_date = character(),
    article_exclusion_notes = character()
  )
}

manual_log <- log |>
  dplyr::filter(manual_review) |>
  dplyr::mutate(
    field_priority = unname(field_priority[field]),
    field_priority = if_else(is.na(field_priority), 99, field_priority),
    allowed_values = vapply(field, collapse_allowed, character(1)),
    decision_hint = decision_hint(field, old_value, reason)
  )

context_cols <- normalized |>
  dplyr::select(
    pid,
    subfield,
    brief_justification,
    countries_of_focus,
    main_causal_research_design,
    evidence_type_current = evidence_type,
    method_status_current = method_status
  )

metadata <- sample_sheet |>
  dplyr::select(pid, title, authors, year, journal_title, language, url_scielo)

sample_context <- sample_validation |>
  dplyr::select(pid, issn, abstract_pt, abstract_en)

full_queue <- manual_log |>
  dplyr::left_join(metadata, by = "pid") |>
  dplyr::left_join(sample_context, by = "pid") |>
  dplyr::left_join(context_cols, by = "pid") |>
  dplyr::left_join(excluded_journals, by = "issn") |>
  dplyr::left_join(excluded_articles, by = "pid") |>
  dplyr::mutate(
    excluded_by_journal = dplyr::coalesce(excluded_by_journal, FALSE),
    excluded_by_article = dplyr::coalesce(excluded_by_article, FALSE),
    journal_exclusion_reason = dplyr::if_else(excluded_by_journal, exclusion_reason, ""),
    article_exclusion_reason = dplyr::if_else(excluded_by_article, article_exclusion_reason, ""),
    excluded_from_analysis = excluded_by_journal | excluded_by_article,
    exclusion_reason = dplyr::case_when(
      excluded_by_journal & excluded_by_article ~ paste(journal_exclusion_reason, article_exclusion_reason, sep = "; "),
      excluded_by_journal ~ journal_exclusion_reason,
      excluded_by_article ~ article_exclusion_reason,
      TRUE ~ ""
    ),
    decision_status = "pending",
    decision_value = "",
    decision_note = "",
    reviewer = "",
    review_date = "",
    title = stringr::str_squish(title),
    abstract_pt = stringr::str_squish(abstract_pt),
    abstract_en = stringr::str_squish(abstract_en),
    brief_justification = stringr::str_squish(brief_justification)
  ) |>
  dplyr::arrange(field_priority, field, pid) |>
  dplyr::select(
    decision_status,
    decision_value,
    decision_note,
    reviewer,
    review_date,
    pid,
    field,
    allowed_values,
    old_value,
    new_value,
    reason,
    decision_hint,
    confidence,
    title,
    authors,
    year,
    journal_title,
    issn,
    language,
    url_scielo,
    abstract_pt,
    abstract_en,
    subfield,
    evidence_type_current,
    method_status_current,
    countries_of_focus,
    main_causal_research_design,
    brief_justification,
    old_json,
    new_json,
    file,
    issue_rule,
    action,
    excluded_by_journal,
    excluded_by_article,
    excluded_from_analysis,
    exclusion_reason
  )

excluded_queue <- full_queue |>
  dplyr::filter(excluded_by_journal) |>
  dplyr::mutate(
    decision_status = "excluded_by_journal",
    decision_value = "<NULL>",
    decision_note = paste0("Excluído da análise principal por regra de periódico: ", exclusion_reason)
  )

excluded_article_queue <- full_queue |>
  dplyr::filter(!excluded_by_journal, excluded_by_article) |>
  dplyr::mutate(
    decision_status = "excluded_by_article",
    decision_value = "<NULL>",
    decision_note = paste0("Excluído da análise principal por regra de artigo: ", exclusion_reason)
  )

queue <- full_queue |>
  dplyr::filter(!excluded_by_journal, !excluded_by_article)

queue_by_article <- queue |>
  dplyr::group_by(pid, title, year, journal_title, url_scielo) |>
  dplyr::summarise(
    n_pending = dplyr::n(),
    fields = paste(field, collapse = "; "),
    first_fields = paste(utils::head(field, 5), collapse = "; "),
    abstract_pt = dplyr::first(abstract_pt),
    abstract_en = dplyr::first(abstract_en),
    brief_justification = dplyr::first(brief_justification),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(n_pending), year, journal_title, title)

readr::write_csv(queue, paths$queue, na = "")
readr::write_csv(excluded_queue, paths$excluded_queue, na = "")
readr::write_csv(excluded_article_queue, paths$excluded_article_queue, na = "")
readr::write_csv(queue_by_article, paths$queue_by_article, na = "")

field_counts <- queue |>
  dplyr::count(field, name = "n") |>
  dplyr::arrange(dplyr::desc(n))

article_counts <- queue_by_article |>
  dplyr::count(n_pending, name = "n_articles") |>
  dplyr::arrange(dplyr::desc(n_pending))

markdown_table <- function(df, max_rows = Inf) {
  if (nrow(df) == 0) {
    return("_Nenhum registro._")
  }
  df <- utils::head(df, max_rows)
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- apply(df, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

codebook_rows <- tibble(
  field = names(allowed_values),
  allowed_values = vapply(
    names(allowed_values),
    function(field) paste(allowed_values[[field]], collapse = "<br>"),
    character(1)
  )
)

codebook_lines <- c(
  "# Codebook da Revisão Manual",
  "",
  "Preencha `decision_value` em `quality_reports/manual_review_queue.csv` usando os valores permitidos abaixo. Use `<NULL>` quando o campo aceitar nulo e o valor substantivo não se aplicar. Use `decision_note` para justificar decisões difíceis.",
  "",
  markdown_table(codebook_rows),
  "",
  "## Regras de preenchimento",
  "",
  "- `decision_status`: deixe `pending` enquanto não decidido; use `done` quando a decisão estiver pronta.",
  "- `decision_value`: deve ser um valor permitido no codebook para o campo.",
  "- `decision_note`: registre justificativa curta quando a decisão não for óbvia.",
  "- `reviewer`: iniciais ou nome de quem revisou.",
  "- `review_date`: data em formato `YYYY-MM-DD`."
)
writeLines(codebook_lines, paths$codebook, useBytes = TRUE)

summary_lines <- c(
  "# Fila de Revisão Manual",
  "",
  paste("Gerado em", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Como usar",
  "",
  "1. Abra `quality_reports/manual_review_queue.csv`.",
  "2. Leia `title`, `abstract_pt`, `abstract_en` e `brief_justification` para decidir.",
  "3. Para cada linha, preencha `decision_value` com um valor permitido em `allowed_values`.",
  "4. Marque `decision_status` como `done` quando decidir.",
  "5. Use `decision_note` para registrar a justificativa quando houver ambiguidade.",
  "6. Depois, rode um script de aplicação das decisões para atualizar os JSONs candidatos finais.",
  "",
  "## Pendências por Campo",
  "",
  markdown_table(field_counts),
  "",
  "## Pendências dispensadas por exclusão de periódico",
  "",
  markdown_table(
    excluded_queue |>
      dplyr::count(journal_title, issn, exclusion_reason, name = "n") |>
      dplyr::arrange(dplyr::desc(n))
  ),
  "",
  "## Pendências dispensadas por exclusão de artigo",
  "",
  markdown_table(
    excluded_article_queue |>
      dplyr::count(pid, title, journal_title, exclusion_reason, name = "n") |>
      dplyr::arrange(journal_title, title)
  ),
  "",
  "## Artigos por Número de Pendências",
  "",
  markdown_table(article_counts),
  "",
  "## Arquivos Gerados",
  "",
  paste0("- `", paths$queue, "`"),
  paste0("- `", paths$excluded_queue, "`"),
  paste0("- `", paths$excluded_article_queue, "`"),
  paste0("- `", paths$queue_by_article, "`"),
  paste0("- `", paths$codebook, "`"),
  paste0("- `", paths$summary, "`")
)
writeLines(summary_lines, paths$summary, useBytes = TRUE)

cat("Fila de revisão manual preparada.\n")
cat("Linhas pendentes:", nrow(queue), "\n")
cat("Linhas dispensadas por exclusão de periódico:", nrow(excluded_queue), "\n")
cat("Linhas dispensadas por exclusão de artigo:", nrow(excluded_article_queue), "\n")
cat("Artigos com pendências:", nrow(queue_by_article), "\n")
cat("Arquivo:", paths$queue, "\n")
