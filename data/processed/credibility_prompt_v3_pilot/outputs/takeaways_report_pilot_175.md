# Relatório de takeaways - piloto v3 (175 artigos)

Gerado em: 2026-06-04 14:04:09 -03

Este relatório resume a expansão do classificador metodológico `credibility_prompt_v3` para o conjunto completo do piloto. A classificação foi feita sem API keys e sem runners de API, usando o `body_text` canônico e o consenso full-body v2 apenas como guarda conservadora contra falsos positivos.

## Takeaways principais

- O piloto ficou com **108/175 artigos empíricos** (61.7%) e **67 não empíricos** (38.3%).
- A variável Torreblanca ampla identifica **52 artigos com alguma análise quantitativa original ou reanálise** (29.7%).
- O módulo qualitativo identifica **74 artigos com evidência qualitativa substantiva** (42.3%).
- Apenas **35 artigos** (20.0%) entram na triagem de métodos da revolução da credibilidade.
- Só **1 artigo** foi classificado com método moderno de credibilidade: `S0104-62762018000100209`, por `other_modern_causal_method`.
- Houve **51 tough calls** (29.1%). A maioria é esperada: artigos qualitativos com números contextuais e modelos observacionais com linguagem causal, mas sem desenho moderno.

## Distribuições finais

### Artigo empírico
|is_empirical_paper |   n|percentual |
|:------------------|---:|:----------|
|TRUE               | 108|61.7%      |
|FALSE              |  67|38.3%      |

### Tipo de evidência empírica
|empirical_evidence_type |  n|percentual |
|:-----------------------|--:|:----------|
|none                    | 67|38.3%      |
|qualitative_only        | 56|32.0%      |
|quantitative_only       | 34|19.4%      |
|mixed_empirical         | 18|10.3%      |

### Tipo de análise quantitativa
|quantitative_analysis_type           |   n|percentual |
|:------------------------------------|---:|:----------|
|none                                 | 123|70.3%      |
|statistical_modeling                 |  22|12.6%      |
|descriptive_statistics_only          |  17|9.7%       |
|bivariate_tests_or_correlations_only |  13|7.4%       |

### Triagem de revolução da credibilidade
|credibility_revolution_screen_applicable |   n|percentual |
|:----------------------------------------|---:|:----------|
|FALSE                                    | 140|80.0%      |
|TRUE                                     |  35|20.0%      |

## O que funcionou

- **A regra anti-falso-positivo foi indispensável.** Depois da auditoria, artigos qualitativos que só mencionavam estatísticas externas ou números contextuais deixaram de virar quantitativos.
- **A separação entre Torreblanca amplo e tipo quantitativo brasileiro ficou operacional.** O classificador distingue `descriptive_statistics_only` de `bivariate_tests_or_correlations_only` e `statistical_modeling`.
- **A triagem causal ficou conservadora.** Dos 175 artigos, 35 entram no screen; entre eles, quase todos são regressões/modelos observacionais sem desenho moderno explícito.
- **O reaproveitamento dos 5 objetos v3 já classificados funcionou.** Eles entraram diretamente no CSV/JSONL final sem reclassificação por regra.
- **As validações automáticas pegaram problemas reais.** O CSV tem 175 linhas, 175 PIDs únicos e nenhum caso de inferência estatística marcada como verdadeira sem citação.

## O que não deu certo na primeira passada

A primeira versão das regras era permissiva demais. Ela capturava palavras soltas como `modelo`, `correlação`, `base de dados`, `survey` e `regressões`, mesmo quando apareciam em sentido conceitual, em revisão de literatura ou em dados de terceiros. A auditoria manual dos falsos positivos levou a estes ajustes:

|indicador                                | pre_auditoria| final|interpretacao                                                                                                      |
|:----------------------------------------|-------------:|-----:|:------------------------------------------------------------------------------------------------------------------|
|mixed_empirical                          |            44|    18|A regra inicial superestimava artigos mistos quando textos qualitativos mencionavam dados ou surveys de terceiros. |
|quantitative_analysis_type == none       |            94|   123|A auditoria aumentou a proteção contra falsos positivos quantitativos.                                             |
|statistical_modeling                     |            41|    22|Termos vagos como modelo, regressões e correlação foram apertados.                                                 |
|credibility_revolution_screen_applicable |            57|    35|A fila de triagem causal ficou menor e mais defensável.                                                            |

Também apareceram dois falsos positivos metodológicos importantes durante a auditoria:

- `matching` em texto sobre mercado de trabalho foi lido inicialmente como pareamento causal; a regra foi restringida para `propensity score`, `pareamento`, grupos de tratamento/controle e expressões equivalentes.
- Menções a `2SLS`/procedimentos de mediação em um artigo sobre violência e democracia não foram tratadas automaticamente como IV; o caso final ficou como `other_modern_causal_method` por mediação causal.

## Métodos de credibilidade detectados

|pid                     |title                                             |quantitative_analysis_type |credibility_revolution_method_type |
|:-----------------------|:-------------------------------------------------|:--------------------------|:----------------------------------|
|S0104-62762018000100209 |Violência e satisfação com a democracia no Brasil |statistical_modeling       |["other_modern_causal_method"]     |

## Tough calls

Foram marcados **51 tough calls**. A distribuição por tipo de ambiguidade foi:

|bucket                                      |  n|percentual_dos_tough_calls |
|:-------------------------------------------|--:|:--------------------------|
|Qualitativo com números contextuais         | 30|58.8%                      |
|Modelagem observacional sem desenho moderno | 21|41.2%                      |

Interpretação: os tough calls não indicam necessariamente erro. Eles identificam a fila que deve ser revisada por humano antes de usar a classificação como gold ou como base para estimar métricas substantivas.

## Checagens de integridade

|checagem                                        |resultado |
|:-----------------------------------------------|:---------|
|Linhas no CSV                                   |175       |
|PIDs únicos                                     |175       |
|Artigos com inferência estatística sem citação  |0         |
|Objetos v3 reaproveitados do teste de 10 papers |5         |

## Recomendação

O prompt e o schema estão prontos para a próxima rodada de validação humana, mas ainda não estão prontos para classificação automática em escala sem auditoria. Para escalar com segurança, eu manteria três filas obrigatórias de revisão: `tough_call == true`, `credibility_revolution_screen_applicable == true` e todos os casos com `credibility_revolution_method_present == true`.

A principal revisão de prompt recomendada é tornar ainda mais explícito que: números contextuais, estatísticas de outros estudos, menções a surveys externos e uso conceitual de palavras como modelo ou correlação não contam como análise quantitativa original.
