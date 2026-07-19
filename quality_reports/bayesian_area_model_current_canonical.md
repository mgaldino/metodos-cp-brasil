# Modelo bayesiano hierárquico da diferença CP–RI

Gerado em: 2026-07-19 08:00:01 -0300

## Especificação

A unidade de verossimilhança é o periódico. Para cada periódico, `y` é o número de artigos quantitativos com inferência estatística e `n` é o número de quantitativos com rótulo de inferência observado. A verossimilhança é binomial, com logit da probabilidade explicado por um indicador de Relações Internacionais e um intercepto aleatório por periódico.

O modelo principal usa priors `Normal(0, 1,5)` para o intercepto e o efeito de área e `Student-t(3, 0, 1)` para o desvio-padrão dos interceptos aleatórios. A sensibilidade substitui os dois primeiros priors por `Student-t(3, 0, 2,5)`. Os priors são próprios e fracamente informativos; a escolha é motivada por Gelman et al. (2008), que recomendam regularização própria em regressões logísticas, especialmente diante de separação e esparsidade.

## Dados

O conjunto tem 8 periódicos: 6 de CP e 2 de RI. Os denominadores somam 1.919 artigos quantitativos com rótulo de inferência observado.

| Área | Periódico | Sucessos | Denominador (N) | Proporção observada |
| --- | --- | --- | --- | --- |
| Ciência Política (inclui escopo compartilhado) | Brazilian Political Science Review | 85 | 171 | 49,7% |
| Ciência Política (inclui escopo compartilhado) | Dados | 142 | 340 | 41,8% |
| Ciência Política (inclui escopo compartilhado) | Opinião Pública | 238 | 388 | 61,3% |
| Ciência Política (inclui escopo compartilhado) | Revista Brasileira de Ciência Política | 60 | 183 | 32,8% |
| Ciência Política (inclui escopo compartilhado) | Revista Brasileira de Ciências Sociais | 68 | 235 | 28,9% |
| Ciência Política (inclui escopo compartilhado) | Revista de Sociologia e Política | 114 | 333 | 34,2% |
| Relações Internacionais | Contexto Internacional | 8 | 111 | 7,2% |
| Relações Internacionais | Revista Brasileira de Política Internacional | 14 | 158 | 8,9% |

## Posterior

| Priori | Parâmetro | Mediana | Quantil 2,5% | Quantil 97,5% |
| --- | --- | --- | --- | --- |
| Normal(0, 1.5) | P(inferência \| CP, periódico médio) | 0.405591030624705 | 0.286731307610421 | 0.529072533567712 |
| Normal(0, 1.5) | P(inferência \| RI, periódico médio) | 0.0928974369630876 | 0.0420601331166015 | 0.215468587524709 |
| Normal(0, 1.5) | Diferença CP - RI | 0.30960152761468 | 0.137726316154943 | 0.436565437997125 |
| Normal(0, 1.5) | Razão de chances RI/CP | 0.150366566157004 | 0.0598460443657437 | 0.468650898884191 |
| Normal(0, 1.5) | beta_area_ri | -1.8946792 | -2.815979945 | -0.75789716525 |
| Normal(0, 1.5) | P(delta > 0) | 0.996625 | - | - |
| Normal(0, 1.5) | P(beta_area_ri < 0) | 0.996625 | - | - |
| Student-t(3, 0, 2.5) | P(inferência \| CP, periódico médio) | 0.41033680744855 | 0.288502961516802 | 0.535616211189542 |
| Student-t(3, 0, 2.5) | P(inferência \| RI, periódico médio) | 0.0842721982219583 | 0.0359813007449802 | 0.195148389776123 |
| Student-t(3, 0, 2.5) | Diferença CP - RI | 0.321966975023877 | 0.165668286240786 | 0.451547013952394 |
| Student-t(3, 0, 2.5) | Razão de chances RI/CP | 0.132447684854904 | 0.0490565650608103 | 0.392327022633159 |
| Student-t(3, 0, 2.5) | beta_area_ri | -2.02156755 | -3.014781705 | -0.935659649750001 |
| Student-t(3, 0, 2.5) | P(delta > 0) | 0.998875 | - | - |
| Student-t(3, 0, 2.5) | P(beta_area_ri < 0) | 0.998875 | - | - |

Prior Normal: mediana 31,0 p.p.; intervalo de credibilidade de 95% 13,8 p.p. a 43,7 p.p.; P(delta > 0) = 0,997.
Prior Student-t: mediana 32,2 p.p.; intervalo de credibilidade de 95% 16,6 p.p. a 45,2 p.p.; P(delta > 0) = 0,999.

Os valores de delta são diferenças entre as probabilidades previstas para um periódico médio, mantendo o intercepto aleatório no valor médio da distribuição. Não são efeitos causais da área.

## Diagnósticos

| prior | max_rhat | min_ess_bulk | min_ess_tail | divergences |
| --- | --- | --- | --- | --- |
| Normal(0, 1.5) | 1.00148731340734 | 1814.61710279053 | 2507.45452492933 | 0 |
| Student-t(3, 0, 2.5) | 1.00211602236734 | 1641.79031340164 | 2504.09760757321 | 0 |

No modelo Normal, 8 dos 8 periódicos têm a proporção observada dentro do intervalo preditivo de 95% para a taxa do periódico.

## Interpretação e limite

A análise bayesiana substitui a pergunta binária sobre um p-valor por uma distribuição posterior para a diferença. Como a área é constante dentro do periódico e há apenas dois periódicos de RI, o resultado ainda depende da informação de poucos clusters. A análise deve ser apresentada como quantificação hierárquica da diferença descritiva, não como identificação de um efeito disciplinar.

## Artefatos

- `output/tables/area_analysis/bayesian_area_journal_data.csv`
- `output/tables/area_analysis/bayesian_area_posterior_summary.csv`
- `output/tables/area_analysis/bayesian_area_posterior_draws_normal.csv`
- `output/tables/area_analysis/bayesian_area_diagnostics.csv`
- `output/tables/area_analysis/bayesian_area_ppc_journal_rates.csv`
- `data/processed/area_analysis/bayesian_area_normal.rds`
- `data/processed/area_analysis/bayesian_area_student.rds`
