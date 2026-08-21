#!/usr/bin/env Rscript

# Constrói o conjunto de PDFs para a revisão independente solicitada.
# Regra: união da seleção anterior com todos os trabalhos entregues cuja nota
# original está no intervalo [6,0; 7,0).

grades_path <- "tmp/grading_work/final_grade_records.csv"
selected_path <- "tmp/grading_work/selected_pdfs.csv"
submissions_root <- paste0(
  "/Users/manoelgaldino/Documents/DCP/Cursos/stat_basica/",
  "trabalhos_graduacao_metodos_III_2026/entregas_moodle"
)
output_path <- "tmp/grading_work/selected_independent_reviews.csv"

grades <- read.csv(
  grades_path,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  encoding = "UTF-8"
)
selected <- read.csv(
  selected_path,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  encoding = "UTF-8"
)

grades$NUSP <- as.character(grades$NUSP)
selected$NUSP <- as.character(selected$NUSP)

six_range <- grades[
  grades$Trabalho_final >= 6 &
    grades$Trabalho_final < 7 &
    grepl("Entregue", grades$Situacao),
  c("Nome", "NUSP", "Trabalho_final", "Justificativa")
]
six_range$Grupo <- "Notas originais entre 6,0 e 6,9"

prior <- merge(
  selected[, c("Grupo", "Nome", "NUSP", "Trabalho_final")],
  grades[, c("NUSP", "Justificativa")],
  by = "NUSP",
  all.x = TRUE,
  sort = FALSE
)

combined <- rbind(
  prior[, c("Grupo", "Nome", "NUSP", "Trabalho_final", "Justificativa")],
  six_range[, c("Grupo", "Nome", "NUSP", "Trabalho_final", "Justificativa")]
)
combined <- combined[!duplicated(combined$NUSP), ]

find_pdf <- function(nusp) {
  dirs <- list.dirs(submissions_root, recursive = FALSE, full.names = TRUE)
  student_dirs <- dirs[startsWith(basename(dirs), paste0(nusp, " - "))]
  if (length(student_dirs) != 1L) {
    stop(sprintf("Esperava uma pasta para NUSP %s; encontrei %d", nusp, length(student_dirs)))
  }
  pdfs <- list.files(student_dirs, pattern = "\\.pdf$", recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
  if (length(pdfs) != 1L) {
    stop(sprintf("Esperava um PDF para NUSP %s; encontrei %d", nusp, length(pdfs)))
  }
  normalizePath(pdfs, winslash = "/", mustWork = TRUE)
}

combined$PDF <- vapply(combined$NUSP, find_pdf, character(1))
combined <- combined[order(match(combined$Grupo, unique(combined$Grupo)), -combined$Trabalho_final, combined$Nome), ]

write.csv(combined, output_path, row.names = FALSE, fileEncoding = "UTF-8")
message(sprintf("Seleção gravada: %d trabalhos em %s", nrow(combined), output_path))
