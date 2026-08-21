## Reconstrói os resultados numéricos usados para corrigir a avaliação final.

options(scipen = 999)

course_root <- "/Users/manoelgaldino/Documents/DCP/Cursos/stat_basica/book-stat-basica"
old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd(course_root)

source(
  "scripts/avaliacao_aulas_06_09_gabarito_calculos.R",
  encoding = "UTF-8"
)

cat("DIMENSOES\n")
print(dimensoes_base)

cat("\nAUSENTES\n")
print(tabela_ausentes)

cat("\nEXPERIENCIA_ADMINISTRATIVA\n")
print(
  tabela_exp_adm |>
    dplyr::select(
      orgao_sup,
      n,
      x,
      proporcao,
      ic_inferior,
      ic_superior,
      margem_erro
    )
)

cat("\nTESTE_EXPERIENCIA_ADMINISTRATIVA\n")
print(teste_exp_adm)

cat("\nALTO_NIVEL\n")
print(
  tabela_alto_nivel |>
    dplyr::select(
      orgao_sup,
      n,
      x,
      proporcao,
      ic_inferior,
      ic_superior,
      margem_erro
    )
)

cat("\nTESTE_ALTO_NIVEL\n")
print(teste_alto_nivel)

cat("\nVALIDACOES_LOGICAS\n")
validacoes <- tibble::tibble(
  regra = c(
    "entrada posterior a saida",
    "nivel fora de 4 a 6",
    "orgao_sup fora de mapa, mcti e minc",
    "indicacao fora das quatro categorias esperadas"
  ),
  n_inconsistencias = c(
    sum(base_original$entrada > base_original$saida, na.rm = TRUE),
    sum(!base_original$nivel %in% c(4, 5, 6), na.rm = TRUE),
    sum(!base_original$orgao_sup %in% c("mapa", "mcti", "minc"), na.rm = TRUE),
    sum(!base_original$indicacao %in% c("Bolsonaro", "Lula", "Rousseff", "Temer"), na.rm = TRUE)
  )
)
print(validacoes)
