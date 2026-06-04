# Performance dos agentes v2 contra classificação manual/gold

Gerado em 2026-06-03 22:21:16 -03

## Fonte da ground truth

- `README.md` documenta `data/processed/classifications_llm_main_analysis.csv` como base operacional da amostra classificada de 175 artigos após exclusões.
- `docs/full_classification_pilot_architecture.md` documenta o mesmo arquivo como gold/piloto validado dos 175 artigos elegíveis, usado para seleção e comparação posterior.
- Nesta avaliação, esse arquivo foi tratado como ground truth manual para `makes_explicit_causal_claim` e `makes_implicit_causal_claim`.

## Interpretação das métricas

- Métricas binárias usam `TRUE` como positivo e tratam `FALSE`/`NULL` do agente como negativo.
- Casos com gold `NULL` são excluídos das métricas binárias.
- `strict_exact_accuracy` exige igualdade exata entre `TRUE`, `FALSE` e `NULL`; por isso penaliza agentes que usaram `NULL` onde o gold manual tem `FALSE`.

## Performance por agente e campo

| agent_id | field | n_binary | gold_true | gold_false | gold_null | pred_true | pred_false | pred_null | pred_coverage_non_null | tp | fp | tn | fn | binary_accuracy | precision | recall_sensitivity | specificity | f1 | balanced_accuracy | strict_exact_accuracy |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| agent_b | makes_explicit_causal_claim | 171,000 | 5,000 | 166,000 | 4,000 | 32,000 | 143,000 | 0,000 | 100,0% | 5,000 | 27,000 | 139,000 | 0,000 | 84,2% | 15,6% | 100,0% | 83,7% | 27,0% | 91,9% | 82,3% |
| agent_c | makes_explicit_causal_claim | 171,000 | 5,000 | 166,000 | 4,000 | 11,000 | 18,000 | 146,000 | 16,6% | 2,000 | 9,000 | 157,000 | 3,000 | 93,0% | 18,2% | 40,0% | 94,6% | 25,0% | 67,3% | 13,1% |
| agent_a | makes_explicit_causal_claim | 171,000 | 5,000 | 166,000 | 4,000 | 7,000 | 103,000 | 65,000 | 62,9% | 1,000 | 6,000 | 160,000 | 4,000 | 94,2% | 14,3% | 20,0% | 96,4% | 16,7% | 58,2% | 56,0% |
| agent_c | makes_implicit_causal_claim | 171,000 | 33,000 | 138,000 | 4,000 | 24,000 | 4,000 | 147,000 | 16,0% | 17,000 | 7,000 | 131,000 | 16,000 | 86,5% | 70,8% | 51,5% | 94,9% | 59,6% | 73,2% | 14,3% |
| agent_a | makes_implicit_causal_claim | 171,000 | 33,000 | 138,000 | 4,000 | 27,000 | 83,000 | 65,000 | 62,9% | 16,000 | 11,000 | 127,000 | 17,000 | 83,6% | 59,3% | 48,5% | 92,0% | 53,3% | 70,3% | 48,0% |
| agent_b | makes_implicit_causal_claim | 171,000 | 33,000 | 138,000 | 4,000 | 4,000 | 171,000 | 0,000 | 100,0% | 3,000 | 1,000 | 137,000 | 30,000 | 81,9% | 75,0% | 9,1% | 99,3% | 16,2% | 54,2% | 80,0% |

## Matriz de confusão binária

| agent_id | field | outcome | n |
| --- | --- | --- | --- |
| agent_a | makes_explicit_causal_claim | FN | 4 |
| agent_a | makes_explicit_causal_claim | FP | 6 |
| agent_a | makes_explicit_causal_claim | TN | 160 |
| agent_a | makes_explicit_causal_claim | TP | 1 |
| agent_b | makes_explicit_causal_claim | FN | 0 |
| agent_b | makes_explicit_causal_claim | FP | 27 |
| agent_b | makes_explicit_causal_claim | TN | 139 |
| agent_b | makes_explicit_causal_claim | TP | 5 |
| agent_c | makes_explicit_causal_claim | FN | 3 |
| agent_c | makes_explicit_causal_claim | FP | 9 |
| agent_c | makes_explicit_causal_claim | TN | 157 |
| agent_c | makes_explicit_causal_claim | TP | 2 |
| agent_a | makes_implicit_causal_claim | FN | 17 |
| agent_a | makes_implicit_causal_claim | FP | 11 |
| agent_a | makes_implicit_causal_claim | TN | 127 |
| agent_a | makes_implicit_causal_claim | TP | 16 |
| agent_b | makes_implicit_causal_claim | FN | 30 |
| agent_b | makes_implicit_causal_claim | FP | 1 |
| agent_b | makes_implicit_causal_claim | TN | 137 |
| agent_b | makes_implicit_causal_claim | TP | 3 |
| agent_c | makes_implicit_causal_claim | FN | 16 |
| agent_c | makes_implicit_causal_claim | FP | 7 |
| agent_c | makes_implicit_causal_claim | TN | 131 |
| agent_c | makes_implicit_causal_claim | TP | 17 |

## Consenso automático v2 contra ground truth manual

Para campos críticos, o consenso automático só aceita unanimidade; por isso a cobertura é baixa.

| field | n_articles | n_consensus_accepted | accepted_coverage | n_matches_previous | agreement_rate |
| --- | --- | --- | --- | --- | --- |
| makes_explicit_causal_claim | 175,000 | 18,000 | 10,3% | 13,000 | 72,2% |
| makes_implicit_causal_claim | 175,000 | 8,000 | 4,6% | 7,000 | 87,5% |

## Arquivos gerados

- `data/processed/full_classification_pilot_v2/comparison/manual_gold_causal_claim_performance_by_agent_field.csv`
- `data/processed/full_classification_pilot_v2/comparison/manual_gold_causal_claim_confusion_by_agent_field.csv`
- `data/processed/full_classification_pilot_v2/comparison/manual_gold_causal_claim_predictions_long.csv`
- `data/processed/full_classification_pilot_v2/comparison/manual_gold_causal_claim_consensus_performance.csv`
