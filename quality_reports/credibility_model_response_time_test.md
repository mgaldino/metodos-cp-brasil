# Teste de igualdade dos tempos de resposta

Gerado em: 2026-07-11 11:03:59 -0300

Foi usada uma resposta efetiva bem-sucedida por PID e modelo. Falhas, retries e execuções `SKIP` foram excluídos; quando havia mais de uma execução bem-sucedida para o mesmo PID, foi mantida a de maior duração, correspondente à chamada efetiva e não ao checkpoint instantâneo.

## Tempos médios

modelo | n | média (s) | mediana (s) | desvio-padrão (s)
--- | ---: | ---: | ---: | ---:
Sol medium | 10 | 100.84 | 78.69 | 69.19
Terra medium | 10 | 163.18 | 62.07 | 231.20
Terra xhigh | 10 | 76.72 | 75.15 | 10.99
Luna xhigh | 10 | 71.49 | 92.44 | 65.21

## Testes

A hipótese nula é que os quatro modelos têm o mesmo tempo médio de resposta. Como os mesmos 10 PIDs foram usados em todos os modelos, o teste principal é uma ANOVA de medidas repetidas com PID como bloco.

- ANOVA de medidas repetidas: F = 1.070; p-valor = 0.378262.
- Friedman: chi-quadrado = 3.720; p-valor = 0.293330.

O p-valor não mede diferença de qualidade classificatória; testa apenas igualdade dos tempos entre os modelos nestes 10 casos.

