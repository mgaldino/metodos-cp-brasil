#!/usr/bin/env Rscript

## Reconstrói replication_files/ com os scripts e as entradas necessárias para
## reproduzir o paper a partir do CSV canônico já classificado.

options(scipen = 999, encoding = "UTF-8")

file_arg <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", file_arg[grepl("^--file=", file_arg)])
if (length(file_arg) != 1) {
  stop("Não foi possível identificar o caminho deste script.")
}

project_dir <- normalizePath(file.path(dirname(file_arg), ".."), mustWork = TRUE)
bundle_dir <- file.path(project_dir, "replication_files")

files_to_copy <- c(
  "scripts/45_build_current_paper_analysis.R",
  "scripts/48_expand_statistical_inference_analysis.R",
  "scripts/51_analyze_gender_current_canonical.R",
  "scripts/52_analyze_area_current_canonical.R",
  "scripts/54_bayesian_area_hierarchical_model.R",
  "scripts/54_fit_bayesian_gender_hierarchical.R",
  "scripts/56_reconcile_gender_to_paper_scope.R",
  "scripts/57_replicate_paper.R",
  "scripts/58_build_replication_files.R",
  "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv",
  "data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv",
  "data/processed/credibility_prompt_v3_integral_reading/prompts/classifier_prompt_v3_integral_reading.md",
  "data/processed/credibility_prompt_v3_test/prompts/classifier_prompt_v3.md",
  "data/processed/excluded_articles.csv",
  "data/processed/excluded_journals.csv",
  "data/raw/torreblanca_2026/source_v2/main.tex",
  "paper/paper.Rmd",
  "paper/preamble.tex",
  "references.bib"
)

source_paths <- file.path(project_dir, files_to_copy)
missing_sources <- files_to_copy[!file.exists(source_paths)]
if (length(missing_sources) > 0) {
  stop("Arquivos-fonte ausentes: ", paste(missing_sources, collapse = "; "))
}

dir.create(bundle_dir, recursive = TRUE, showWarnings = FALSE)

for (relative_path in files_to_copy) {
  source <- file.path(project_dir, relative_path)
  destination <- file.path(bundle_dir, relative_path)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  copied <- file.copy(source, destination, overwrite = TRUE, copy.mode = TRUE, copy.date = TRUE)
  if (!copied) {
    stop("Falha ao copiar: ", relative_path)
  }
}

checksum_candidates <- list.files(
  bundle_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
checksum_candidates <- checksum_candidates[
  file.info(checksum_candidates)$isdir %in% FALSE &
    basename(checksum_candidates) != "MD5SUMS"
]
relative_candidates <- substring(checksum_candidates, nchar(bundle_dir) + 2L)
checksums <- unname(tools::md5sum(checksum_candidates))
checksum_lines <- paste(checksums, relative_candidates)
writeLines(checksum_lines, file.path(bundle_dir, "MD5SUMS"), useBytes = TRUE)

message("Pacote de replicação atualizado em: ", bundle_dir)
message("Arquivos copiados: ", length(files_to_copy))
message("Arquivos com checksum: ", length(checksum_candidates))

