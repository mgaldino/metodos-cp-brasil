suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

input_original <- "tmp/grading_work/final_grade_records.csv"
input_loop <- "tmp/grading_work/independent_review_results.csv"
output_dir <- "outputs/01a02455-4428-7e10-b65c-4328cbb55411"
output_csv <- file.path(output_dir, "comparacao_notas_original_loop.csv")
output_md <- file.path(output_dir, "comparacao_notas_original_loop.md")

original <- readr::read_csv(
  input_original,
  col_types = readr::cols(NUSP = readr::col_character()),
  show_col_types = FALSE
) %>%
  dplyr::select(Nome, NUSP, nota_original = Trabalho_final, justificativa_original = Justificativa)

loop <- readr::read_csv(
  input_loop,
  col_types = readr::cols(NUSP = readr::col_character()),
  show_col_types = FALSE
)

comparacao <- loop %>%
  dplyr::left_join(original, by = "NUSP") %>%
  dplyr::mutate(
    Nome = dplyr::if_else(NUSP == "4725594", "Mariana Araujo Püschel", Nome),
    discrepancia = round(nota_independente - nota_original, 1),
    discrepancia_abs = abs(discrepancia),
    classe = dplyr::case_when(
      discrepancia_abs <= 0.5 ~ "consistente",
      discrepancia_abs <= 1.0 ~ "moderada",
      TRUE ~ "material"
    ),
    nota_adotada = dplyr::if_else(NUSP == "4725594", 5.0, nota_independente)
  ) %>%
  dplyr::select(
    Nome,
    NUSP,
    nota_original,
    nota_independente,
    discrepancia,
    classe,
    nota_adotada,
    C1:C8,
    confianca,
    justificativa_original
  )

stopifnot(nrow(comparacao) == 14L)
stopifnot(!any(is.na(comparacao$Nome)))
stopifnot(all(abs(rowSums(comparacao %>% dplyr::select(C1:C8)) - comparacao$nota_independente) <= 0.051))

readr::write_excel_csv(comparacao, output_csv, na = "")

formatar_numero <- function(x) {
  formatC(x, format = "f", digits = 1, decimal.mark = ",")
}

formatar_delta <- function(x) {
  x[abs(x) < 0.05] <- 0
  sinal <- ifelse(x > 0, "+", "")
  paste0(sinal, formatar_numero(x))
}

linhas_tabela <- comparacao %>%
  dplyr::transmute(
    linha = paste0(
      "| ", Nome,
      " | ", NUSP,
      " | ", formatar_numero(nota_original),
      " | ", formatar_numero(nota_independente),
      " | ", formatar_delta(discrepancia),
      " | ", classe,
      " | ", formatar_numero(nota_adotada),
      " |"
    )
  ) %>%
  dplyr::pull(linha)

resumo_classes <- comparacao %>%
  dplyr::count(classe, name = "n")

obter_n <- function(rotulo) {
  valor <- resumo_classes %>%
    dplyr::filter(classe == rotulo) %>%
    dplyr::pull(n)
  ifelse(length(valor) == 0, 0L, valor)
}

media_original <- mean(comparacao$nota_original)
media_loop <- mean(comparacao$nota_independente)
media_delta <- mean(comparacao$discrepancia)
mediana_abs <- median(abs(comparacao$discrepancia))

relatorio <- c(
  "# Comparação entre notas originais e loop independente",
  "",
  "## Regra de normalização",
  "",
  "Todas as releituras usaram a mesma rubrica de 0 a 10. A soma dos oito critérios foi arredondada para uma casa decimal, sem reescalonamento posterior. A discrepância é `nota independente − nota original`. Classificação: até 0,5 ponto, consistente; de 0,6 a 1,0, moderada; acima de 1,0, material. A nota adotada é a do loop independente, exceto para Mariana Araujo Püschel (NUSP 4725594), ajustada pelo docente de 4,2 para 5,0.",
  "",
  "A marcação separada de suspeita de assistência por IA não foi incorporada às notas deste arquivo.",
  "",
  "## Tabela 1. Comparação das notas",
  "",
  "| Estudante | NUSP | Original | Loop | Diferença | Classe | Adotada |",
  "|---|---:|---:|---:|---:|---|---:|",
  linhas_tabela,
  "",
  "## Síntese",
  "",
  paste0("- Consistentes: ", obter_n("consistente"), " de 14."),
  paste0("- Moderadas: ", obter_n("moderada"), " de 14."),
  paste0("- Materiais: ", obter_n("material"), " de 14."),
  paste0("- Média original: ", formatar_numero(media_original), "."),
  paste0("- Média do loop: ", formatar_numero(media_loop), "."),
  paste0("- Mudança média: ", formatar_delta(media_delta), " ponto."),
  paste0("- Mediana da discrepância absoluta: ", formatar_numero(mediana_abs), " ponto."),
  "",
  "## Discrepâncias materiais",
  "",
  "### Luiz Antonio Eleutério de Lima: 8,8 → 7,7 (−1,1)",
  "",
  "A justificativa original classificava os testes centrais como corretos. A releitura identificou que a limpeza reduziu indevidamente o MinC a 309/351, em vez de 312/354, e que o texto do segundo teste primeiro rejeita H0 com `p = 0,03889` e logo depois afirma o oposto. A nota independente preserva crédito pela identificação, pelo segundo teste numericamente correto, pelas decisões de 10% e 1% e pela estrutura reprodutível, mas aplica descontos aos erros de limpeza e à contradição decisória.",
  "",
  "### Lincoln Antonio Andrade de Moura: 6,2 → 8,3 (+2,1)",
  "",
  "A justificativa original afirmava que a tabela e o teste de alto nível estavam incorretos. A inspeção independente encontrou a construção correta de `alto_nivel`, as contagens 187/525 e 155/365 e `p = 0,0388873`, com decisão correta a 5%. No primeiro teste, o MinC está limpo como 309/351, mas o teste t sobre a variável binária produz `p = 0,0607`, dentro da faixa defensável do protocolo, e leva à decisão correta a 5%. Permanecem descontos pela unidade imprecisa, limpeza parcial, confusão conceitual na explicação do p-valor, ausência de avaliação substantiva e falta de quantificação por `1/√2`. A diferença material decorre principalmente de a correção original ter tratado como incorreta uma segunda análise que o PDF mostra estar correta.",
  "",
  "## Proveniência",
  "",
  "- Notas originais: `tmp/grading_work/final_grade_records.csv`.",
  "- Resultados cegos do loop: `tmp/grading_work/independent_review_results.csv`.",
  "- Justificativas completas: `outputs/01a02455-4428-7e10-b65c-4328cbb55411/reavaliacoes_independentes_loop.md`.",
  "- Ajuste docente: Mariana Araujo Püschel, nota final 5,0; o resultado bruto do loop (4,2) permanece preservado.",
  "- Script gerador: `tmp/grading_work/compare_independent_loop.R`."
)

writeLines(enc2utf8(relatorio), output_md, useBytes = TRUE)

cat("Comparação concluída:\n")
cat("-", output_csv, "\n")
cat("-", output_md, "\n")
