# Testes simples de diferenças entre Ciência Política e Relações Internacionais

Gerado em: 2026-07-19 07:44:15 -0300

## Hipótese e unidade

A hipótese nula é igualdade das proporções entre os dois grupos editoriais. O teste principal usa `prop.test` bilateral, sem correção de continuidade, com IC de 95% para a diferença CP–RI. Fisher bilateral é reportado como checagem exata. Os testes tratam artigos como independentes; portanto, os p-valores são diagnósticos simples e não corrigem a dependência entre artigos do mesmo periódico.

A comparação principal é a inferência estatística entre artigos quantitativos cujo rótulo de inferência foi observado. Os cinco quantitativos sem rótulo permanecem fora do denominador, como no paper.

## Resultados

| Métrica | CP (N/D) | RI (N/D) | Diferença (p.p.) | IC95% da diferença | p (duas proporções) | p (Fisher) | p ajustado BH |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Artigo empírico entre todos os artigos | 2.529/3.078 (82,2%) | 779/946 (82,3%) | -0,2 p.p. | -3,0 p.p. a 2,6 p.p. | 0,898 | 0,923 | 0,898 |
| Análise quantitativa entre artigos empíricos | 1.655/2.529 (65,4%) | 269/779 (34,5%) | 30,9 p.p. | 27,1 p.p. a 34,7 p.p. | <0,001 | <0,001 | <0,001 |
| Inferência estatística entre quantitativos com rótulo observado | 707/1.650 (42,8%) | 22/269 (8,2%) | 34,7 p.p. | 30,6 p.p. a 38,7 p.p. | <0,001 | <0,001 | <0,001 |
| Estratégia causal explícita entre artigos examinados | 56/1.242 (4,5%) | 1/129 (0,8%) | 3,7 p.p. | 1,8 p.p. a 5,6 p.p. | 0,043 | 0,037 | 0,058 |

Para a métrica principal, a diferença CP–RI é de 34,7 p.p. (IC95%: 30,6 p.p. a 38,7 p.p.; p bilateral = <0,001; Fisher = <0,001).

Os testes confirmam uma diferença estatística muito forte na inferência e na composição quantitativa. A diferença em estratégias causais explícitas é menor em magnitude e fica próxima do limiar de 5% no teste simples; com ajuste BH para as quatro métricas, ela deixa de ser significativa a 5%. Isso não altera a descrição substantiva, mas recomenda não apresentar o resultado causal como uma separação estatística robusta sem modelar a estrutura por periódico.

## Limitação decisiva

Os artigos estão agrupados em seis periódicos de CP e dois de RI, e a área foi atribuída ao periódico. A sensibilidade que usa o periódico como unidade produz p = <0,001 no teste t de Welch, mas p = 0,067 no teste de Wilcoxon. Como há apenas dois periódicos de RI, essa divergência é esperada e impede tratar o p-valor artigo-nível como uma confirmação definitiva de um efeito de área. Uma análise confirmatória deveria trabalhar com proporções por periódico, modelos hierárquicos ou inferência por cluster; com apenas oito periódicos, essa extensão teria baixa potência e exigiria especificação cuidadosa.

## Artefatos

- `output/tables/area_analysis/area_hypothesis_test_counts.csv`
- `output/tables/area_analysis/area_hypothesis_tests.csv`
- `output/tables/area_analysis/area_journal_inference_rates.csv`
- `output/tables/area_analysis/area_journal_sensitivity_tests.csv`
- `data/processed/area_analysis/area_hypothesis_tests_session_info.txt`
