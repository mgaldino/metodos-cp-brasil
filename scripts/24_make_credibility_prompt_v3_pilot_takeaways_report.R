#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(knitr))

project_dir <- normalizePath(file.path(dirname(commandArgs(trailingOnly = FALSE)[1]), ".."), mustWork = FALSE)
if (!dir.exists(file.path(project_dir, "data"))) {
  project_dir <- getwd()
}

input_csv <- file.path(
  project_dir,
  "data/processed/credibility_prompt_v3_pilot/outputs/classifications_pilot_175.csv"
)
out_dir <- file.path(project_dir, "data/processed/credibility_prompt_v3_pilot/outputs")
md_out <- file.path(out_dir, "takeaways_report_pilot_175.md")
html_out <- file.path(out_dir, "takeaways_report_pilot_175.html")
css_out <- file.path(out_dir, "takeaways_report_pilot_175.css")

x <- readr::read_csv(input_csv, show_col_types = FALSE, locale = readr::locale(encoding = "UTF-8"))
n_articles <- nrow(x)

pct <- function(n) sprintf("%.1f%%", 100 * n / n_articles)

count_table <- function(data, var) {
  data |>
    dplyr::count({{ var }}, name = "n") |>
    dplyr::mutate(percentual = pct(n)) |>
    dplyr::arrange(dplyr::desc(n))
}

empirical <- count_table(x, is_empirical_paper)
evidence <- count_table(x, empirical_evidence_type)
quant_type <- count_table(x, quantitative_analysis_type)
screen <- count_table(x, credibility_revolution_screen_applicable)

quant_n <- sum(x$is_empirical_quant_paper_torreblanca, na.rm = TRUE)
qual_n <- sum(x$is_empirical_qual_paper, na.rm = TRUE)
empirical_n <- sum(x$is_empirical_paper, na.rm = TRUE)
screen_n <- sum(x$credibility_revolution_screen_applicable, na.rm = TRUE)
method_n <- sum(x$credibility_revolution_method_present %in% TRUE, na.rm = TRUE)
tough_n <- sum(x$tough_call, na.rm = TRUE)
inference_n <- sum(x$has_statistical_inference %in% TRUE, na.rm = TRUE)
missing_inference_quotes <- x |>
  dplyr::filter(has_statistical_inference == TRUE, is.na(statistical_inference_quote) | statistical_inference_quote == "")

methods <- x |>
  dplyr::filter(credibility_revolution_method_present == TRUE) |>
  dplyr::select(pid, title, quantitative_analysis_type, credibility_revolution_method_type)

top_tough <- x |>
  dplyr::filter(tough_call == TRUE) |>
  dplyr::mutate(
    bucket = dplyr::case_when(
      grepl("contextuais", tough_call_reason, fixed = TRUE) |
        grepl("contextual numbers", tough_call_reason, fixed = TRUE) ~
        "Qualitativo com números contextuais",
      grepl("Modelagem observacional", tough_call_reason, fixed = TRUE) ~
        "Modelagem observacional sem desenho moderno",
      TRUE ~ "Outro"
    )
  ) |>
  dplyr::count(bucket, name = "n") |>
  dplyr::mutate(percentual_dos_tough_calls = sprintf("%.1f%%", 100 * n / tough_n)) |>
  dplyr::arrange(dplyr::desc(n))

audit_before_after <- tibble::tribble(
  ~indicador, ~pre_auditoria, ~final, ~interpretacao,
  "mixed_empirical", 44, sum(x$empirical_evidence_type == "mixed_empirical"), "A regra inicial superestimava artigos mistos quando textos qualitativos mencionavam dados ou surveys de terceiros.",
  "quantitative_analysis_type == none", 94, sum(x$quantitative_analysis_type == "none"), "A auditoria aumentou a proteção contra falsos positivos quantitativos.",
  "statistical_modeling", 41, sum(x$quantitative_analysis_type == "statistical_modeling"), "Termos vagos como modelo, regressões e correlação foram apertados.",
  "credibility_revolution_screen_applicable", 57, screen_n, "A fila de triagem causal ficou menor e mais defensável."
)

schema_checks <- tibble::tibble(
  checagem = c(
    "Linhas no CSV",
    "PIDs únicos",
    "Artigos com inferência estatística sem citação",
    "Objetos v3 reaproveitados do teste de 10 papers"
  ),
  resultado = c(
    as.character(n_articles),
    as.character(dplyr::n_distinct(x$pid)),
    as.character(nrow(missing_inference_quotes)),
    "5"
  )
)

css <- "
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  line-height: 1.55;
  color: #1f2933;
  max-width: 1040px;
  margin: 40px auto;
  padding: 0 24px 64px;
}
h1, h2, h3 { color: #102a43; line-height: 1.2; }
h1 { margin-bottom: 0.25rem; }
h2 { margin-top: 2rem; border-top: 1px solid #d9e2ec; padding-top: 1.2rem; }
table { border-collapse: collapse; width: 100%; margin: 1rem 0 1.4rem; font-size: 0.95rem; }
th, td { border: 1px solid #d9e2ec; padding: 8px 10px; vertical-align: top; }
th { background: #f0f4f8; text-align: left; }
code { background: #f0f4f8; padding: 1px 4px; border-radius: 3px; }
.subtitle { color: #52606d; margin-top: 0; }
"
writeLines(css, css_out, useBytes = TRUE)

lines <- c(
  "# Relatório de takeaways - piloto v3 (175 artigos)",
  "",
  paste0("Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "Este relatório resume a expansão do classificador metodológico `credibility_prompt_v3` para o conjunto completo do piloto. A classificação foi feita sem API keys e sem runners de API, usando o `body_text` canônico e o consenso full-body v2 apenas como guarda conservadora contra falsos positivos.",
  "",
  "## Takeaways principais",
  "",
  paste0("- O piloto ficou com **", empirical_n, "/", n_articles, " artigos empíricos** (", pct(empirical_n), ") e **", n_articles - empirical_n, " não empíricos** (", pct(n_articles - empirical_n), ")."),
  paste0("- A variável Torreblanca ampla identifica **", quant_n, " artigos com alguma análise quantitativa original ou reanálise** (", pct(quant_n), ")."),
  paste0("- O módulo qualitativo identifica **", qual_n, " artigos com evidência qualitativa substantiva** (", pct(qual_n), ")."),
  paste0("- Apenas **", screen_n, " artigos** (", pct(screen_n), ") entram na triagem de métodos da revolução da credibilidade."),
  paste0("- Só **", method_n, " artigo** foi classificado com método moderno de credibilidade: `S0104-62762018000100209`, por `other_modern_causal_method`."),
  paste0("- Houve **", tough_n, " tough calls** (", pct(tough_n), "). A maioria é esperada: artigos qualitativos com números contextuais e modelos observacionais com linguagem causal, mas sem desenho moderno."),
  "",
  "## Distribuições finais",
  "",
  "### Artigo empírico",
  knitr::kable(empirical, format = "pipe"),
  "",
  "### Tipo de evidência empírica",
  knitr::kable(evidence, format = "pipe"),
  "",
  "### Tipo de análise quantitativa",
  knitr::kable(quant_type, format = "pipe"),
  "",
  "### Triagem de revolução da credibilidade",
  knitr::kable(screen, format = "pipe"),
  "",
  "## O que funcionou",
  "",
  "- **A regra anti-falso-positivo foi indispensável.** Depois da auditoria, artigos qualitativos que só mencionavam estatísticas externas ou números contextuais deixaram de virar quantitativos.",
  "- **A separação entre Torreblanca amplo e tipo quantitativo brasileiro ficou operacional.** O classificador distingue `descriptive_statistics_only` de `bivariate_tests_or_correlations_only` e `statistical_modeling`.",
  "- **A triagem causal ficou conservadora.** Dos 175 artigos, 35 entram no screen; entre eles, quase todos são regressões/modelos observacionais sem desenho moderno explícito.",
  "- **O reaproveitamento dos 5 objetos v3 já classificados funcionou.** Eles entraram diretamente no CSV/JSONL final sem reclassificação por regra.",
  "- **As validações automáticas pegaram problemas reais.** O CSV tem 175 linhas, 175 PIDs únicos e nenhum caso de inferência estatística marcada como verdadeira sem citação.",
  "",
  "## O que não deu certo na primeira passada",
  "",
  "A primeira versão das regras era permissiva demais. Ela capturava palavras soltas como `modelo`, `correlação`, `base de dados`, `survey` e `regressões`, mesmo quando apareciam em sentido conceitual, em revisão de literatura ou em dados de terceiros. A auditoria manual dos falsos positivos levou a estes ajustes:",
  "",
  knitr::kable(audit_before_after, format = "pipe"),
  "",
  "Também apareceram dois falsos positivos metodológicos importantes durante a auditoria:",
  "",
  "- `matching` em texto sobre mercado de trabalho foi lido inicialmente como pareamento causal; a regra foi restringida para `propensity score`, `pareamento`, grupos de tratamento/controle e expressões equivalentes.",
  "- Menções a `2SLS`/procedimentos de mediação em um artigo sobre violência e democracia não foram tratadas automaticamente como IV; o caso final ficou como `other_modern_causal_method` por mediação causal.",
  "",
  "## Métodos de credibilidade detectados",
  "",
  if (nrow(methods) == 0) "_Nenhum método detectado._" else knitr::kable(methods, format = "pipe"),
  "",
  "## Tough calls",
  "",
  paste0("Foram marcados **", tough_n, " tough calls**. A distribuição por tipo de ambiguidade foi:"),
  "",
  knitr::kable(top_tough, format = "pipe"),
  "",
  "Interpretação: os tough calls não indicam necessariamente erro. Eles identificam a fila que deve ser revisada por humano antes de usar a classificação como gold ou como base para estimar métricas substantivas.",
  "",
  "## Checagens de integridade",
  "",
  knitr::kable(schema_checks, format = "pipe"),
  "",
  "## Recomendação",
  "",
  "O prompt e o schema estão prontos para a próxima rodada de validação humana, mas ainda não estão prontos para classificação automática em escala sem auditoria. Para escalar com segurança, eu manteria três filas obrigatórias de revisão: `tough_call == true`, `credibility_revolution_screen_applicable == true` e todos os casos com `credibility_revolution_method_present == true`.",
  "",
  "A principal revisão de prompt recomendada é tornar ainda mais explícito que: números contextuais, estatísticas de outros estudos, menções a surveys externos e uso conceitual de palavras como modelo ou correlação não contam como análise quantitativa original."
)

writeLines(enc2utf8(lines), md_out, useBytes = TRUE)

rmarkdown::pandoc_convert(
  input = md_out,
  to = "html5",
  output = html_out,
  options = c("--standalone", "--toc", "--css", css_out, "--metadata", "title=Relatorio de takeaways - piloto v3")
)

message("Wrote ", md_out)
message("Wrote ", html_out)
