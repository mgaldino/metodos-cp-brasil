# Checagem de casos positivos de método de credibilidade no piloto v3

Gerado em: 2026-06-15 17:04:41 -0300

## Síntese

- Casos com método clássico/estrito de identificação causal: 0.
- Casos com `other_modern_causal_method`: 1.
- Casos candidatos exportados: 2.

Métodos estritos incluem experimentos, DiD/event study, IV, RDD/RKD, synthetic control, matching/weighting, DAG causal, doubly robust, causal trees/forests e causal discovery. `other_modern_causal_method` fica separado porque requer validação substantiva da identificação.

## Tabela 1. Tipos de método encontrados no piloto

method_class | method_type | n
--- | --- | ---
broad_other_modern_causal_method | other_modern_causal_method |  1
diagnostic_not_design | none_detected | 20
diagnostic_not_design | observational_regression_with_causal_claim_no_design | 14

## Tabela 2. Candidatos positivos a validar

audit_id | pid | title | method_type | method_class
--- | --- | --- | --- | ---
A017 | S0104-62762018000100209 | Violência e satisfação com a democracia no Brasil | other_modern_causal_method | broad_other_modern_causal_method
A012 | S0104-62762006000200005 | Os militantes são mais informados? Desigualdade e informação política nas eleições de 2002 | observational_regression_with_causal_claim_no_design | diagnostic_not_design
A017 | S0104-62762018000100209 | Violência e satisfação com a democracia no Brasil | observational_regression_with_causal_claim_no_design | diagnostic_not_design

## Nota para A017

O único caso em `other_modern_causal_method` é A017. Se a auditoria manual decidir que a aplicação de mediação causal/SEM não justifica a hipótese de identificação relevante, o caso deve sair do numerador de métodos de credibilidade.
