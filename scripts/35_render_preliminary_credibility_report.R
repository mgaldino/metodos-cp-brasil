## 35_render_preliminary_credibility_report.R
## Reconstroi os artefatos preliminares e renderiza o relatorio em PDF.

options(scipen = 999, encoding = "UTF-8")

suppressPackageStartupMessages({
  library(rmarkdown)
})

source("scripts/34_build_preliminary_credibility_analysis.R", echo = FALSE)

rmarkdown::render(
  input = "quality_reports/preliminary_credibility_analysis.Rmd",
  output_format = "pdf_document",
  output_file = "preliminary_credibility_analysis.pdf",
  output_dir = "quality_reports",
  clean = TRUE,
  envir = new.env(parent = globalenv())
)

cat("Relatório renderizado em: quality_reports/preliminary_credibility_analysis.pdf\n")

