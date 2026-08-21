suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(readxl)
})

options(scipen = 999)

round_half_up <- function(x, digits = 0) {
  factor <- 10^digits
  floor(x * factor + 0.5) / factor
}

# Este script consolida as notas já adotadas pelo docente e aplica, de modo
# reproduzível, as regras de ajuste por entrega e de atribuição de frequência.
work_dir <- "tmp/grading_work"

grades_raw <- readr::read_csv(
  file.path(work_dir, "final_grade_records.csv"),
  col_types = readr::cols(
    Nome = readr::col_character(),
    Email = readr::col_character(),
    NUSP = readr::col_character(),
    Lista_1 = readr::col_double(),
    Lista_2 = readr::col_double(),
    Nota_listas = readr::col_double(),
    Trabalho_final = readr::col_double(),
    Situacao = readr::col_character(),
    Fonte_entrega = readr::col_character(),
    Justificativa = readr::col_character(),
    Status_Moodle = readr::col_character(),
    Modificado_Moodle = readr::col_character()
  ),
  show_col_types = FALSE
)

# A planilha anterior é a fonte autoritativa das justificativas já atualizadas
# após as releituras. A seleção por posição evita depender da codificação local
# dos acentos nos nomes das colunas importadas pelo readxl.
prior_workbook <- readxl::read_excel(
  "outputs/01a02455-4428-7e10-b65c-4328cbb55411/notas_metodos_III_2026.xlsx",
  sheet = "Notas",
  skip = 6,
  .name_repair = "minimal"
) |>
  dplyr::select(1, 2, 7, 10)
names(prior_workbook) <- c(
  "Nome_planilha_anterior",
  "NUSP",
  "Nota_planilha_anterior",
  "Justificativa_adotada"
)
prior_workbook <- prior_workbook |>
  dplyr::mutate(
    Nome_planilha_anterior = as.character(Nome_planilha_anterior),
    NUSP = as.character(NUSP),
    Nota_planilha_anterior = as.numeric(Nota_planilha_anterior),
    Justificativa_adotada = as.character(Justificativa_adotada)
  )

independent <- readr::read_csv(
  file.path(work_dir, "independent_review_results.csv"),
  col_types = readr::cols(
    NUSP = readr::col_character(),
    nota_independente = readr::col_double(),
    C1 = readr::col_double(),
    C2 = readr::col_double(),
    C3 = readr::col_double(),
    C4 = readr::col_double(),
    C5 = readr::col_double(),
    C6 = readr::col_double(),
    C7 = readr::col_double(),
    C8 = readr::col_double(),
    confianca = readr::col_character()
  ),
  show_col_types = FALSE
) |>
  dplyr::select(NUSP, nota_independente)

ai_penalties <- tibble::tribble(
  ~NUSP, ~Penalidade_IA,
  "14573451", 1.5,
  "15442662", 1.5
)

inputs <- grades_raw |>
  dplyr::left_join(independent, by = "NUSP") |>
  dplyr::left_join(ai_penalties, by = "NUSP") |>
  dplyr::left_join(prior_workbook, by = "NUSP") |>
  dplyr::mutate(
    Nome = dplyr::coalesce(Nome_planilha_anterior, Nome),
    Penalidade_IA = dplyr::coalesce(Penalidade_IA, 0),
    Nota_releitura = dplyr::case_when(
      NUSP == "4725594" ~ 5.0,
      !is.na(nota_independente) ~ nota_independente,
      TRUE ~ Trabalho_final
    ),
    Nota_trabalho_adotada = round(
      pmax(0, pmin(10, Nota_releitura - Penalidade_IA)),
      1
    ),
    Trabalho_entregue = Fonte_entrega != "Sem envio",
    Todas_listas = Lista_1 == 10 & Lista_2 == 10,
    Alguma_lista = Lista_1 == 10 | Lista_2 == 10,
    Entregou_tudo = Trabalho_entregue & Todas_listas,
    Justificativa = dplyr::coalesce(Justificativa_adotada, Justificativa)
  ) |>
  dplyr::arrange(Nome) |>
  dplyr::select(
    Nome,
    NUSP,
    Email,
    Fonte_entrega,
    Lista_1,
    Lista_2,
    Nota_trabalho_adotada,
    Justificativa,
    Trabalho_entregue,
    Todas_listas,
    Alguma_lista,
    Entregou_tudo,
    Penalidade_IA
  )

# A frequência varia pouco com a nota: entre estudantes que entregaram os
# mesmos componentes, cada ponto adicional de nota eleva a frequência em 0,5
# ponto percentual. A penalidade explícita por lista é aplicada em separado.
expected <- inputs |>
  dplyr::mutate(
    Ajuste_listas = dplyr::if_else(Entregou_tudo, 0.5, -0.5),
    Nota_final = round(pmax(0, pmin(10, Nota_trabalho_adotada + Ajuste_listas)), 1),
    Frequencia_base = dplyr::if_else(
      Trabalho_entregue,
      85 + 0.5 * Nota_final,
      NA_real_
    ),
    Desconto_frequencia_listas = dplyr::if_else(
      Trabalho_entregue & !Todas_listas,
      10,
      0
    ),
    Frequencia_pre_piso = Frequencia_base - Desconto_frequencia_listas,
    Frequencia = dplyr::case_when(
      !Trabalho_entregue & !Alguma_lista ~ 0,
      !Trabalho_entregue ~ 50,
      Nota_final >= 5 ~ pmax(75, Frequencia_pre_piso),
      TRUE ~ pmax(0, Frequencia_pre_piso)
    ),
    # Excel usa arredondamento aritmético em empates (por exemplo, 88,85
    # torna-se 88,9); a função explícita mantém R e Excel idênticos.
    Frequencia = round_half_up(Frequencia, 1),
    Resultado = dplyr::if_else(
      Nota_final >= 5 & Frequencia >= 75,
      "Aprovado",
      "Reprovado"
    )
  ) |>
  dplyr::select(
    Nome,
    NUSP,
    Email,
    Fonte_entrega,
    Lista_1,
    Lista_2,
    Nota_trabalho_adotada,
    Ajuste_listas,
    Nota_final,
    Frequencia_base,
    Desconto_frequencia_listas,
    Frequencia,
    Resultado,
    Justificativa,
    Trabalho_entregue,
    Todas_listas,
    Alguma_lista,
    Entregou_tudo,
    Penalidade_IA
  )

# Controles lógicos e de consistência.
stopifnot(
  nrow(inputs) == 74L,
  dplyr::n_distinct(inputs$NUSP) == 74L,
  sum(inputs$Trabalho_entregue) == 57L,
  sum(!inputs$Trabalho_entregue) == 17L,
  sum(inputs$Entregou_tudo) == 48L,
  sum(inputs$Trabalho_entregue & !inputs$Todas_listas) == 9L,
  all(abs(inputs$Nota_trabalho_adotada - prior_workbook$Nota_planilha_anterior[
    match(inputs$NUSP, prior_workbook$NUSP)
  ]) < 0.0000001),
  all(expected$Nota_final >= 0 & expected$Nota_final <= 10),
  all(expected$Frequencia >= 0 & expected$Frequencia <= 100),
  all(expected$Frequencia[expected$Resultado == "Aprovado"] >= 75),
  all(expected$Frequencia[!expected$Trabalho_entregue & !expected$Alguma_lista] == 0),
  all(expected$Frequencia[!expected$Trabalho_entregue & expected$Alguma_lista] == 50),
  all(expected$Ajuste_listas[expected$Entregou_tudo] == 0.5),
  all(expected$Ajuste_listas[!expected$Entregou_tudo] == -0.5)
)

# A nota deve ser monotônica na frequência dentro de cada grupo de entrega de
# listas; o desconto de 10 p.p. pode, por definição docente, inverter a ordem
# entre estudantes de grupos diferentes.
monotonicity <- expected |>
  dplyr::filter(Trabalho_entregue) |>
  dplyr::group_by(Todas_listas) |>
  dplyr::arrange(Nota_final, .by_group = TRUE) |>
  dplyr::summarise(
    monotona = all(diff(Frequencia) >= -0.0000001),
    .groups = "drop"
  )
stopifnot(all(monotonicity$monotona))

readr::write_csv(
  inputs,
  file.path(work_dir, "notas_frequencias_inputs.csv"),
  na = ""
)
readr::write_csv(
  expected,
  file.path(work_dir, "notas_frequencias_esperadas.csv"),
  na = ""
)

validation <- list(
  generated_at = format(Sys.time(), tz = "America/Sao_Paulo", usetz = TRUE),
  students = nrow(expected),
  submitted_work = sum(expected$Trabalho_entregue),
  no_work = sum(!expected$Trabalho_entregue),
  submitted_everything = sum(expected$Entregou_tudo),
  submitted_work_missing_lists = sum(expected$Trabalho_entregue & !expected$Todas_listas),
  no_work_no_lists = sum(!expected$Trabalho_entregue & !expected$Alguma_lista),
  no_work_some_list = sum(!expected$Trabalho_entregue & expected$Alguma_lista),
  approved = sum(expected$Resultado == "Aprovado"),
  failed = sum(expected$Resultado == "Reprovado"),
  min_approved_frequency = min(expected$Frequencia[expected$Resultado == "Aprovado"]),
  max_approved_frequency = max(expected$Frequencia[expected$Resultado == "Aprovado"]),
  grade_frequency_monotonic_within_delivery_group = all(monotonicity$monotona),
  all_checks_passed = TRUE
)

jsonlite::write_json(
  validation,
  file.path(work_dir, "validacao_notas_frequencias.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

print(validation)
