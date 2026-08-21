suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(readr)
})

work_dir <- "tmp/grading_work"

monitor_raw <- jsonlite::fromJSON(
  file.path(work_dir, "monitor_rows.json"),
  simplifyVector = FALSE
)
monitor_header <- unlist(monitor_raw[[1]], use.names = FALSE)
monitor <- dplyr::bind_rows(lapply(monitor_raw[-1], function(row) {
  values <- unlist(row, use.names = FALSE)
  as.data.frame(
    as.list(stats::setNames(values, monitor_header)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
})) %>%
  transmute(
    Nome = as.character(nome),
    Email = as.character(email),
    NUSP = as.character(NUSP),
    Lista_1 = as.numeric(`Lista 1`),
    Lista_2 = as.numeric(`Lista 2`)
  )

moodle <- jsonlite::fromJSON(
  file.path(work_dir, "moodle_roster_and_submissions.json"),
  simplifyDataFrame = TRUE
)$participants %>%
  transmute(
    NUSP = as.character(nusp),
    Status_Moodle = as.character(status),
    Modificado_Moodle = as.character(modified)
  )

manual <- readr::read_csv(
  file.path(work_dir, "manual_grades.csv"),
  col_types = cols(
    NUSP = col_character(),
    Trabalho_final = col_double(),
    Fonte_entrega = col_character(),
    Justificativa = col_character()
  ),
  show_col_types = FALSE
)

final <- monitor %>%
  left_join(moodle, by = "NUSP") %>%
  left_join(manual, by = "NUSP") %>%
  mutate(
    Nota_listas = (Lista_1 + Lista_2) / 2,
    Trabalho_final = dplyr::coalesce(Trabalho_final, 0),
    Fonte_entrega = dplyr::coalesce(Fonte_entrega, "Sem envio"),
    Situacao = case_when(
      Fonte_entrega == "Moodle" ~ "Entregue no Moodle",
      Fonte_entrega == "E-mail" ~ "Entregue por e-mail",
      TRUE ~ "Sem envio localizado"
    ),
    Justificativa = dplyr::coalesce(
      Justificativa,
      "Nenhum envio localizado no Moodle nem entre as entregas excepcionais por e-mail."
    )
  ) %>%
  arrange(Nome) %>%
  dplyr::select(
    Nome,
    Email,
    NUSP,
    Lista_1,
    Lista_2,
    Nota_listas,
    Trabalho_final,
    Situacao,
    Fonte_entrega,
    Justificativa,
    Status_Moodle,
    Modificado_Moodle
  )

stopifnot(
  nrow(monitor) == 74L,
  dplyr::n_distinct(monitor$NUSP) == 74L,
  nrow(moodle) == 74L,
  dplyr::n_distinct(moodle$NUSP) == 74L,
  nrow(manual) == 57L,
  dplyr::n_distinct(manual$NUSP) == 57L,
  sum(moodle$Status_Moodle == "Enviado") == 56L,
  all(moodle$NUSP[moodle$Status_Moodle == "Enviado"] %in% manual$NUSP),
  sum(final$Fonte_entrega == "E-mail") == 1L,
  sum(final$Fonte_entrega == "Moodle") == 56L,
  sum(final$Fonte_entrega == "Sem envio") == 17L,
  all(final$Trabalho_final >= 0 & final$Trabalho_final <= 10),
  all(final$Lista_1 %in% c(0, 10)),
  all(final$Lista_2 %in% c(0, 10))
)

readr::write_csv(final, file.path(work_dir, "final_grade_records.csv"), na = "")

validation <- list(
  generated_at = format(Sys.time(), tz = "America/Sao_Paulo", usetz = TRUE),
  students = nrow(final),
  moodle_submissions = sum(final$Fonte_entrega == "Moodle"),
  email_submissions = sum(final$Fonte_entrega == "E-mail"),
  no_submission = sum(final$Fonte_entrega == "Sem envio"),
  min_submitted_grade = min(final$Trabalho_final[final$Fonte_entrega != "Sem envio"]),
  max_submitted_grade = max(final$Trabalho_final[final$Fonte_entrega != "Sem envio"]),
  mean_submitted_grade = mean(final$Trabalho_final[final$Fonte_entrega != "Sem envio"]),
  all_checks_passed = TRUE
)
jsonlite::write_json(
  validation,
  file.path(work_dir, "grading_validation.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

print(validation)
