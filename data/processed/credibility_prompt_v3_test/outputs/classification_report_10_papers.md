# Classificação metodológica - prompt v3 - 10 papers

Gerado em: 2026-06-04T13:17:57Z

## Escopo

Foram classificados 10 artigos do manifest `data/processed/credibility_prompt_v3_test/manifest_10_papers.csv`.

As decisões usaram apenas os task packets com body integral em `data/processed/credibility_prompt_v3_test/task_packets/`. Não houve uso de API keys, API runners ou classificações antigas como evidência substantiva.

## Distribuições

### is_empirical_paper

| value | n |
| --- | --- |
| FALSE | 3 |
| TRUE | 7 |

### empirical_evidence_type

| value | n |
| --- | --- |
| mixed_empirical | 1 |
| none | 3 |
| qualitative_only | 2 |
| quantitative_only | 4 |

### quantitative_analysis_type

| value | n |
| --- | --- |
| bivariate_tests_or_correlations_only | 1 |
| descriptive_statistics_only | 1 |
| none | 5 |
| statistical_modeling | 3 |

### credibility_revolution_screen_applicable

| value | n |
| --- | --- |
| FALSE | 6 |
| TRUE | 4 |

## Artigos com método de revolução da credibilidade

| pid | title | credibility_revolution_method_type |
| --- | --- | --- |
| S0104-62762025000100206 | Sobre balas, bíblias e modelos estatísticos: explorando atalhos eleitorais | ["matching_or_weighting"] |

## Tough calls

| pid | title | tough_call_reason |
| --- | --- | --- |
| S0104-62762025000100200 | Por que a democracia não funciona para todos: estatuto social e apoio à democracia na Europa | The article uses multilevel observational models and causal language about status affecting democratic support, but no experimental or quasi-experimental identification design is stated. |
| S0104-62762025000100215 | Conferências nacionais e (des)democratização: uma análise da trajetória brasileira (1941-2022) | The article makes explanatory historical claims and uses an original quantitative inventory, but the quantitative analysis itself is descriptive counts, percentages, tables, and graphs without inferential tests or causal design. |
| S0104-62762021000100230 | Efeitos diretos e indiretos do Programa Bolsa Família nas eleições presidenciais brasileiras | The article estimates direct and indirect effects using multivariable logistic regressions and marginal effects, but the body text does not state a quasi-experimental or other credibility-revolution identification design. |
| S1981-38212024000200201 | The African Agenda of Evangelical Christians in Brazilian Foreign Policy: The Crisis of the Universal Church of the Kingdom of God in Angola | The article mentions contextual numbers and outside survey/census figures, but the body does not present original quantitative analysis; the empirical contribution is qualitative case-study evidence. |

## Falsos positivos e falsos negativos prováveis

Principais riscos de falso positivo: classificar como quantitativos artigos qualitativos que citam números contextuais de terceiros, especialmente o estudo sobre a UCKG em Angola; e classificar como método de credibilidade artigos com regressão observacional e linguagem de efeito, como status social e Bolsa Família.

Principais riscos de falso negativo: reduzir a importância empírica de artigos mistos quando o componente quantitativo é apenas descritivo, como o levantamento das conferências nacionais. A regra anti-falso-positivo recomenda manter esses casos como quantitativos descritivos, mas fora da triagem de métodos de credibilidade quando não há teste, modelo ou desenho causal.

## Recomendação sobre o prompt

O prompt está quase pronto para escala. A principal revisão recomendada é explicitar a decisão para casos de regressão observacional com linguagem causal: `credibility_revolution_method_present` deve ser `false`, mas `credibility_revolution_method_type` pode registrar `observational_regression_with_causal_claim_no_design`. Também vale explicitar que artigos mistos com levantamento quantitativo descritivo e narrativa causal-histórica ficam em `descriptive_quantitative_only`, salvo quando a inferência causal estiver associada a teste, modelo ou desenho quantitativo.
