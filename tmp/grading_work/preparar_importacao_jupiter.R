suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringi)
})

base_dir <- "tmp/grading_work"
turmas_path <- file.path(base_dir, "jupiter_turmas_oficiais_2026.csv")
notas_path <- file.path(base_dir, "notas_frequencias_esperadas.csv")

normalizar_nome <- function(x) {
  x |>
    stringi::stri_trans_general("Latin-ASCII") |>
    tolower() |>
    gsub("[^a-z0-9]+", " ", x = _) |>
    trimws()
}

turmas <- readr::read_csv(
  turmas_path,
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE
) |>
  dplyr::mutate(
    NUSP = as.character(NUSP),
    Nome_normalizado_jupiter = normalizar_nome(Nome)
  )

notas <- readr::read_csv(
  notas_path,
  col_types = readr::cols(NUSP = readr::col_character()),
  show_col_types = FALSE
) |>
  dplyr::mutate(
    NUSP = as.character(NUSP),
    Nome_normalizado_planilha = normalizar_nome(Nome)
  )

reconciliacao <- turmas |>
  dplyr::rename(Nome_Jupiter = Nome) |>
  dplyr::left_join(
    notas |>
      dplyr::select(
        NUSP,
        Nome_planilha = Nome,
        Nome_normalizado_planilha,
        Nota_final,
        Frequencia,
        Resultado
      ),
    by = "NUSP"
  ) |>
  dplyr::mutate(
    NUSP_encontrado = !is.na(Nota_final),
    Nome_confere = Nome_normalizado_jupiter == Nome_normalizado_planilha
  ) |>
  dplyr::arrange(Turma, Nome_Jupiter)

nao_matriculados <- notas |>
  dplyr::anti_join(turmas |> dplyr::select(NUSP), by = "NUSP") |>
  dplyr::select(Nome, NUSP, Nota_final, Frequencia, Resultado) |>
  dplyr::arrange(Nome)

stopifnot(
  nrow(turmas) == 62L,
  dplyr::n_distinct(turmas$NUSP) == 62L,
  sum(turmas$Turma == "2026101") == 41L,
  sum(turmas$Turma == "2026102") == 21L,
  nrow(notas) == 74L,
  all(reconciliacao$NUSP_encontrado),
  all(reconciliacao$Nome_confere),
  all(!is.na(reconciliacao$Nota_final)),
  all(!is.na(reconciliacao$Frequencia)),
  nrow(nao_matriculados) == 12L
)

criar_importacao <- function(codigo_turma, sufixo) {
  reconciliacao |>
    dplyr::filter(Turma == codigo_turma) |>
    dplyr::transmute(
      `Numero USP` = NUSP,
      Frequencia = as.integer(Frequencia),
      Nota = as.numeric(Nota_final)
    ) |>
    readr::write_csv(file.path(base_dir, paste0("jupiter_", codigo_turma, "_", sufixo, ".csv")))
}

criar_importacao("2026101", "noturno")
criar_importacao("2026102", "diurno")
readr::write_csv(reconciliacao, file.path(base_dir, "jupiter_reconciliacao.csv"))
readr::write_csv(nao_matriculados, file.path(base_dir, "jupiter_nao_matriculados.csv"))

resumo <- list(
  matriculados_jupiter = nrow(reconciliacao),
  noturno_2026101 = sum(reconciliacao$Turma == "2026101"),
  diurno_2026102 = sum(reconciliacao$Turma == "2026102"),
  nao_matriculados_no_jupiter = nrow(nao_matriculados),
  nomes_conferem = all(reconciliacao$Nome_confere),
  notas_e_frequencias_completas = all(reconciliacao$NUSP_encontrado),
  lara_nota = reconciliacao$Nota_final[reconciliacao$NUSP == "14586921"],
  lara_frequencia = reconciliacao$Frequencia[reconciliacao$NUSP == "14586921"]
)

print(resumo)
