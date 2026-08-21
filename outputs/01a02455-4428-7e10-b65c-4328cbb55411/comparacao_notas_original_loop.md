# Comparação entre notas originais e loop independente

## Regra de normalização

Todas as releituras usaram a mesma rubrica de 0 a 10. A soma dos oito critérios foi arredondada para uma casa decimal, sem reescalonamento posterior. A discrepância é `nota independente − nota original`. Classificação: até 0,5 ponto, consistente; de 0,6 a 1,0, moderada; acima de 1,0, material. Conforme a instrução do docente, a nota adotada nesta comparação é a do loop independente.

A marcação separada de suspeita de assistência por IA não foi incorporada às notas deste arquivo.

## Tabela 1. Comparação das notas

| Estudante | NUSP | Original | Loop | Diferença | Classe | Adotada |
|---|---:|---:|---:|---:|---|---:|
| Fellipe Matheus Bernardino Pereira | 11330361 | 9,8 | 9,8 | 0,0 | consistente | 9,8 |
| Gabriela Yumi Fraga Assano | 14573451 | 9,8 | 9,8 | 0,0 | consistente | 9,8 |
| Murilo Rocha Souto Maior | 13636574 | 9,8 | 9,2 | -0,6 | moderada | 9,2 |
| Beatriz Pessoni | 15442662 | 8,8 | 8,3 | -0,5 | consistente | 8,3 |
| Lara Nunes de Lacerda | 14586921 | 8,8 | 9,4 | +0,6 | moderada | 9,4 |
| Luiz Antonio Eleuterio de Lima | 14759962 | 8,8 | 7,7 | -1,1 | material | 7,7 |
| Mariana Rodrigues Carneiro Silva | 14596738 | 5,8 | 6,3 | +0,5 | consistente | 6,3 |
| Ju Magalhães | 14654997 | 4,7 | 5,4 | +0,7 | moderada | 5,4 |
| Mariana Araujo Puschel | 4725594 | 4,5 | 4,2 | -0,3 | consistente | 4,2 |
| Francisco Zardo de Melo | 15452656 | 6,8 | 6,5 | -0,3 | consistente | 6,5 |
| Gustavo Lopes Rangel Madureira | 15457821 | 6,6 | 5,9 | -0,7 | moderada | 5,9 |
| Carlos Alberto Vergara | 3464981 | 6,5 | 6,3 | -0,2 | consistente | 6,3 |
| Lincoln Antonio Andrade de Moura | 14589448 | 6,2 | 8,3 | +2,1 | material | 8,3 |
| Nathan Henrique de Souza Fonseca | 16894387 | 6,1 | 5,9 | -0,2 | consistente | 5,9 |

## Síntese

- Consistentes: 8 de 14.
- Moderadas: 4 de 14.
- Materiais: 2 de 14.
- Média original: 7,4.
- Média do loop: 7,4.
- Mudança média: 0,0 ponto.
- Mediana da discrepância absoluta: 0,5 ponto.

## Discrepâncias materiais

### Luiz Antonio Eleutério de Lima: 8,8 → 7,7 (−1,1)

A justificativa original classificava os testes centrais como corretos. A releitura identificou que a limpeza reduziu indevidamente o MinC a 309/351, em vez de 312/354, e que o texto do segundo teste primeiro rejeita H0 com `p = 0,03889` e logo depois afirma o oposto. A nota independente preserva crédito pela identificação, pelo segundo teste numericamente correto, pelas decisões de 10% e 1% e pela estrutura reprodutível, mas aplica descontos aos erros de limpeza e à contradição decisória.

### Lincoln Antonio Andrade de Moura: 6,2 → 8,3 (+2,1)

A justificativa original afirmava que a tabela e o teste de alto nível estavam incorretos. A inspeção independente encontrou a construção correta de `alto_nivel`, as contagens 187/525 e 155/365 e `p = 0,0388873`, com decisão correta a 5%. No primeiro teste, o MinC está limpo como 309/351, mas o teste t sobre a variável binária produz `p = 0,0607`, dentro da faixa defensável do protocolo, e leva à decisão correta a 5%. Permanecem descontos pela unidade imprecisa, limpeza parcial, confusão conceitual na explicação do p-valor, ausência de avaliação substantiva e falta de quantificação por `1/√2`. A diferença material decorre principalmente de a correção original ter tratado como incorreta uma segunda análise que o PDF mostra estar correta.

## Proveniência

- Notas originais: `tmp/grading_work/final_grade_records.csv`.
- Resultados cegos do loop: `tmp/grading_work/independent_review_results.csv`.
- Justificativas completas: `outputs/01a02455-4428-7e10-b65c-4328cbb55411/reavaliacoes_independentes_loop.md`.
- Script gerador: `tmp/grading_work/compare_independent_loop.R`.
