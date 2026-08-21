casos <- data.frame(
  pasta = c("MAPA", "MinC"),
  x = c(187, 155),
  n = c(525, 365)
)

extrair_ic <- function(x, n, correcao) {
  unname(stats::prop.test(x, n, correct = correcao)$conf.int)
}

ics_com_correcao <- t(mapply(
  extrair_ic,
  x = casos$x,
  n = casos$n,
  MoreArgs = list(correcao = TRUE)
))

ics_sem_correcao <- t(mapply(
  extrair_ic,
  x = casos$x,
  n = casos$n,
  MoreArgs = list(correcao = FALSE)
))

resultado <- transform(
  casos,
  proporcao = x / n,
  ic_inf_com_correcao = ics_com_correcao[, 1],
  ic_sup_com_correcao = ics_com_correcao[, 2],
  ic_inf_wilson = ics_sem_correcao[, 1],
  ic_sup_wilson = ics_sem_correcao[, 2]
)

print(resultado, digits = 8, row.names = FALSE)
