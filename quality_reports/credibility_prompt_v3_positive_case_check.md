# Checagem de casos positivos de método de credibilidade no piloto v3

Gerado em: 2026-06-15 17:26:30 -0300

## Síntese

- Casos com método clássico/estrito de identificação causal: 0.
- Casos com `other_modern_causal_method`: 1.
- Casos positivos após ajuste manual do caso de borda A017: 0.
- Casos candidatos exportados: 2.

Métodos estritos incluem experimentos, DiD/event study, IV, RDD/RKD, synthetic control, matching/weighting, DAG causal, doubly robust, causal trees/forests e causal discovery. `other_modern_causal_method` fica separado porque requer validação substantiva da identificação.

Regra ajustada: métodos fora da lista usual de desenhos da revolução da credibilidade, como SEM, mediação causal, path analysis ou modelos estruturais observacionais, só contam como `other_modern_causal_method` positivo se o artigo discutir explicitamente a hipótese/estratégia de identificação causal e defender sua plausibilidade no contexto empírico. Sem essa discussão, o caso é classificado como modelagem causal observacional, não como desenho de revolução da credibilidade.

## Tabela 1. Tipos de método encontrados no piloto

method_class | method_type | n
--- | --- | ---
broad_other_modern_causal_method | other_modern_causal_method |  1
diagnostic_not_design | none_detected | 20
diagnostic_not_design | observational_regression_with_causal_claim_no_design | 14

## Tabela 2. Candidatos positivos a validar

audit_id | pid | title | method_type | method_class | adjusted_credibility_design | manual_adjustment
--- | --- | --- | --- | --- | --- | ---
A017 | S0104-62762018000100209 | Violência e satisfação com a democracia no Brasil | other_modern_causal_method | broad_other_modern_causal_method | FALSE | exclude_from_credibility_design
A012 | S0104-62762006000200005 | Os militantes são mais informados? Desigualdade e informação política nas eleições de 2002 | observational_regression_with_causal_claim_no_design | diagnostic_not_design | FALSE | NA
A017 | S0104-62762018000100209 | Violência e satisfação com a democracia no Brasil | observational_regression_with_causal_claim_no_design | diagnostic_not_design | FALSE | exclude_from_credibility_design

## Nota para A017

O único caso em `other_modern_causal_method` é A017. A decisão manual foi excluí-lo do numerador porque o artigo cita mediação causal/SEM, mas não discute nem justifica ignorabilidade sequencial ou hipótese equivalente de identificação.
