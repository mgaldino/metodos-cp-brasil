# Performance dos agentes v2 contra classificação manual/gold: todos os campos

Gerado em 2026-06-03 22:25:17 -03

## Fonte da ground truth

- Ground truth: `data/processed/classifications_llm_main_analysis.csv`.
- A documentação descreve esse arquivo como a amostra classificada validada de 175 artigos após exclusões e como gold/piloto para avaliação do piloto triplo.

## Como ler

- Para todos os campos, `exact_accuracy_all` mede igualdade literal entre agente e ground truth, incluindo `NULL`.
- Para campos textuais ou estruturados (`independent_variables`, `dependent_variables`, `brief_justification`, quotes etc.), igualdade literal é uma métrica muito dura e deve ser lida como diagnóstico operacional, não como qualidade semântica final.
- Para campos binários, `TRUE` é o positivo; `FALSE` e `NULL` do agente contam como negativo nas métricas binárias quando o gold é `TRUE`/`FALSE`.

## Resumo por agente e tipo de campo

| agent_id | field_type | fields | mean_exact_accuracy_all | median_exact_accuracy_all | mean_exact_accuracy_gold_non_null | mean_pred_coverage_non_null |
| --- | --- | --- | --- | --- | --- | --- |
| agent_b | binary | 14,000 | 71,9% | 70,0% | 47,4% | 47,6% |
| agent_a | binary | 14,000 | 63,8% | 64,6% | 39,0% | 37,1% |
| agent_c | binary | 14,000 | 58,6% | 64,9% | 22,9% | 22,8% |
| agent_a | categorical | 12,000 | 74,8% | 80,3% | 53,7% | 61,1% |
| agent_c | categorical | 12,000 | 72,2% | 74,9% | 47,8% | 55,5% |
| agent_b | categorical | 12,000 | 71,6% | 78,3% | 56,2% | 64,8% |
| agent_a | text_or_structured_exact | 9,000 | 81,1% | 89,1% | 11,0% | 23,4% |
| agent_b | text_or_structured_exact | 9,000 | 78,0% | 88,6% | 10,7% | 26,1% |
| agent_c | text_or_structured_exact | 9,000 | 73,2% | 80,0% | 22,0% | 27,4% |

## Melhor agente por campo binário

| field | best_agent | n_binary | gold_true | gold_false | tp | fp | tn | fn | precision | recall_sensitivity | specificity | f1 | balanced_accuracy |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| claims_any_statistically_significant_results | agent_c | 60,000 | 20,000 | 40,000 | 16,000 | 2,000 | 38,000 | 4,000 | 88,9% | 80,0% | 95,0% | 84,2% | 87,5% |
| clear_causal_quantity_of_interest | agent_a | 39,000 | 0,000 | 39,000 | 0,000 | 0,000 | 39,000 | 0,000 | NA | NA | 100,0% | NA | NA |
| clearly_defined_explanatory_variable | agent_c | 62,000 | 24,000 | 38,000 | 19,000 | 2,000 | 36,000 | 5,000 | 90,5% | 79,2% | 94,7% | 84,4% | 87,0% |
| discusses_threats_to_causality | agent_b | 62,000 | 2,000 | 60,000 | 2,000 | 1,000 | 59,000 | 0,000 | 66,7% | 100,0% | 98,3% | 80,0% | 99,2% |
| is_empirical_quant_paper | agent_b | 175,000 | 40,000 | 135,000 | 30,000 | 8,000 | 127,000 | 10,000 | 78,9% | 75,0% | 94,1% | 76,9% | 84,5% |
| makes_explicit_causal_claim | agent_b | 171,000 | 5,000 | 166,000 | 5,000 | 27,000 | 139,000 | 0,000 | 15,6% | 100,0% | 83,7% | 27,0% | 91,9% |
| makes_implicit_causal_claim | agent_c | 171,000 | 33,000 | 138,000 | 17,000 | 7,000 | 131,000 | 16,000 | 70,8% | 51,5% | 94,9% | 59,6% | 73,2% |
| mentions_pre_registered_design_and_analysis_plan | agent_a | 161,000 | 0,000 | 161,000 | 0,000 | 0,000 | 161,000 | 0,000 | NA | NA | 100,0% | NA | NA |
| placebo_test | agent_a | 17,000 | 0,000 | 17,000 | 0,000 | 0,000 | 17,000 | 0,000 | NA | NA | 100,0% | NA | NA |
| references_power_analysis | agent_a | 42,000 | 1,000 | 41,000 | 0,000 | 0,000 | 41,000 | 1,000 | NA | 0,0% | 100,0% | NA | 50,0% |
| seeks_determinants | agent_b | 85,000 | 24,000 | 61,000 | 20,000 | 5,000 | 56,000 | 4,000 | 80,0% | 83,3% | 91,8% | 81,6% | 87,6% |
| specifies_estimate_equations | agent_c | 42,000 | 1,000 | 41,000 | 1,000 | 1,000 | 40,000 | 0,000 | 50,0% | 100,0% | 97,6% | 66,7% | 98,8% |
| statement_of_identification_assumptions | agent_a | 62,000 | 0,000 | 62,000 | 0,000 | 0,000 | 62,000 | 0,000 | NA | NA | 100,0% | NA | NA |
| strong_non_causal_causal_qualification | agent_a | 22,000 | 0,000 | 22,000 | 0,000 | 0,000 | 22,000 | 0,000 | NA | NA | 100,0% | NA | NA |

## Métricas binárias por agente e campo

| agent_id | field | n_binary | gold_true | gold_false | tp | fp | tn | fn | binary_accuracy | precision | recall_sensitivity | specificity | f1 | balanced_accuracy |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| agent_c | claims_any_statistically_significant_results | 60,000 | 20,000 | 40,000 | 16,000 | 2,000 | 38,000 | 4,000 | 90,0% | 88,9% | 80,0% | 95,0% | 84,2% | 87,5% |
| agent_b | claims_any_statistically_significant_results | 60,000 | 20,000 | 40,000 | 15,000 | 1,000 | 39,000 | 5,000 | 90,0% | 93,8% | 75,0% | 97,5% | 83,3% | 86,2% |
| agent_a | claims_any_statistically_significant_results | 60,000 | 20,000 | 40,000 | 14,000 | 1,000 | 39,000 | 6,000 | 88,3% | 93,3% | 70,0% | 97,5% | 80,0% | 83,7% |
| agent_a | clear_causal_quantity_of_interest | 39,000 | 0,000 | 39,000 | 0,000 | 0,000 | 39,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_b | clear_causal_quantity_of_interest | 39,000 | 0,000 | 39,000 | 0,000 | 0,000 | 39,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_c | clear_causal_quantity_of_interest | 39,000 | 0,000 | 39,000 | 0,000 | 0,000 | 39,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_c | clearly_defined_explanatory_variable | 62,000 | 24,000 | 38,000 | 19,000 | 2,000 | 36,000 | 5,000 | 88,7% | 90,5% | 79,2% | 94,7% | 84,4% | 87,0% |
| agent_b | clearly_defined_explanatory_variable | 62,000 | 24,000 | 38,000 | 20,000 | 4,000 | 34,000 | 4,000 | 87,1% | 83,3% | 83,3% | 89,5% | 83,3% | 86,4% |
| agent_a | clearly_defined_explanatory_variable | 62,000 | 24,000 | 38,000 | 16,000 | 2,000 | 36,000 | 8,000 | 83,9% | 88,9% | 66,7% | 94,7% | 76,2% | 80,7% |
| agent_b | discusses_threats_to_causality | 62,000 | 2,000 | 60,000 | 2,000 | 1,000 | 59,000 | 0,000 | 98,4% | 66,7% | 100,0% | 98,3% | 80,0% | 99,2% |
| agent_c | discusses_threats_to_causality | 62,000 | 2,000 | 60,000 | 2,000 | 10,000 | 50,000 | 0,000 | 83,9% | 16,7% | 100,0% | 83,3% | 28,6% | 91,7% |
| agent_a | discusses_threats_to_causality | 62,000 | 2,000 | 60,000 | 0,000 | 0,000 | 60,000 | 2,000 | 96,8% | NA | 0,0% | 100,0% | NA | 50,0% |
| agent_b | is_empirical_quant_paper | 175,000 | 40,000 | 135,000 | 30,000 | 8,000 | 127,000 | 10,000 | 89,7% | 78,9% | 75,0% | 94,1% | 76,9% | 84,5% |
| agent_c | is_empirical_quant_paper | 175,000 | 40,000 | 135,000 | 33,000 | 15,000 | 120,000 | 7,000 | 87,4% | 68,8% | 82,5% | 88,9% | 75,0% | 85,7% |
| agent_a | is_empirical_quant_paper | 175,000 | 40,000 | 135,000 | 34,000 | 17,000 | 118,000 | 6,000 | 86,9% | 66,7% | 85,0% | 87,4% | 74,7% | 86,2% |
| agent_b | makes_explicit_causal_claim | 171,000 | 5,000 | 166,000 | 5,000 | 27,000 | 139,000 | 0,000 | 84,2% | 15,6% | 100,0% | 83,7% | 27,0% | 91,9% |
| agent_c | makes_explicit_causal_claim | 171,000 | 5,000 | 166,000 | 2,000 | 9,000 | 157,000 | 3,000 | 93,0% | 18,2% | 40,0% | 94,6% | 25,0% | 67,3% |
| agent_a | makes_explicit_causal_claim | 171,000 | 5,000 | 166,000 | 1,000 | 6,000 | 160,000 | 4,000 | 94,2% | 14,3% | 20,0% | 96,4% | 16,7% | 58,2% |
| agent_c | makes_implicit_causal_claim | 171,000 | 33,000 | 138,000 | 17,000 | 7,000 | 131,000 | 16,000 | 86,5% | 70,8% | 51,5% | 94,9% | 59,6% | 73,2% |
| agent_a | makes_implicit_causal_claim | 171,000 | 33,000 | 138,000 | 16,000 | 11,000 | 127,000 | 17,000 | 83,6% | 59,3% | 48,5% | 92,0% | 53,3% | 70,3% |
| agent_b | makes_implicit_causal_claim | 171,000 | 33,000 | 138,000 | 3,000 | 1,000 | 137,000 | 30,000 | 81,9% | 75,0% | 9,1% | 99,3% | 16,2% | 54,2% |
| agent_a | mentions_pre_registered_design_and_analysis_plan | 161,000 | 0,000 | 161,000 | 0,000 | 0,000 | 161,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_b | mentions_pre_registered_design_and_analysis_plan | 161,000 | 0,000 | 161,000 | 0,000 | 0,000 | 161,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_c | mentions_pre_registered_design_and_analysis_plan | 161,000 | 0,000 | 161,000 | 0,000 | 0,000 | 161,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_a | placebo_test | 17,000 | 0,000 | 17,000 | 0,000 | 0,000 | 17,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_b | placebo_test | 17,000 | 0,000 | 17,000 | 0,000 | 0,000 | 17,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_c | placebo_test | 17,000 | 0,000 | 17,000 | 0,000 | 0,000 | 17,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_a | references_power_analysis | 42,000 | 1,000 | 41,000 | 0,000 | 0,000 | 41,000 | 1,000 | 97,6% | NA | 0,0% | 100,0% | NA | 50,0% |
| agent_b | references_power_analysis | 42,000 | 1,000 | 41,000 | 0,000 | 0,000 | 41,000 | 1,000 | 97,6% | NA | 0,0% | 100,0% | NA | 50,0% |
| agent_c | references_power_analysis | 42,000 | 1,000 | 41,000 | 0,000 | 0,000 | 41,000 | 1,000 | 97,6% | NA | 0,0% | 100,0% | NA | 50,0% |
| agent_b | seeks_determinants | 85,000 | 24,000 | 61,000 | 20,000 | 5,000 | 56,000 | 4,000 | 89,4% | 80,0% | 83,3% | 91,8% | 81,6% | 87,6% |
| agent_c | seeks_determinants | 85,000 | 24,000 | 61,000 | 17,000 | 1,000 | 60,000 | 7,000 | 90,6% | 94,4% | 70,8% | 98,4% | 81,0% | 84,6% |
| agent_a | seeks_determinants | 85,000 | 24,000 | 61,000 | 18,000 | 6,000 | 55,000 | 6,000 | 85,9% | 75,0% | 75,0% | 90,2% | 75,0% | 82,6% |
| agent_c | specifies_estimate_equations | 42,000 | 1,000 | 41,000 | 1,000 | 1,000 | 40,000 | 0,000 | 97,6% | 50,0% | 100,0% | 97,6% | 66,7% | 98,8% |
| agent_a | specifies_estimate_equations | 42,000 | 1,000 | 41,000 | 1,000 | 3,000 | 38,000 | 0,000 | 92,9% | 25,0% | 100,0% | 92,7% | 40,0% | 96,3% |
| agent_b | specifies_estimate_equations | 42,000 | 1,000 | 41,000 | 1,000 | 3,000 | 38,000 | 0,000 | 92,9% | 25,0% | 100,0% | 92,7% | 40,0% | 96,3% |
| agent_a | statement_of_identification_assumptions | 62,000 | 0,000 | 62,000 | 0,000 | 0,000 | 62,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_b | statement_of_identification_assumptions | 62,000 | 0,000 | 62,000 | 0,000 | 0,000 | 62,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_c | statement_of_identification_assumptions | 62,000 | 0,000 | 62,000 | 0,000 | 0,000 | 62,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_a | strong_non_causal_causal_qualification | 22,000 | 0,000 | 22,000 | 0,000 | 0,000 | 22,000 | 0,000 | 100,0% | NA | NA | 100,0% | NA | NA |
| agent_b | strong_non_causal_causal_qualification | 22,000 | 0,000 | 22,000 | 0,000 | 1,000 | 21,000 | 0,000 | 95,5% | 0,0% | NA | 95,5% | NA | NA |
| agent_c | strong_non_causal_causal_qualification | 22,000 | 0,000 | 22,000 | 0,000 | 1,000 | 21,000 | 0,000 | 95,5% | 0,0% | NA | 95,5% | NA | NA |

## Campos com menor acurácia exata média

| field | field_type | best_agent | mean_exact_accuracy_all | max_exact_accuracy_all | mean_exact_accuracy_gold_non_null |
| --- | --- | --- | --- | --- | --- |
| brief_justification | text_or_structured_exact | agent_a | 0,0% | 0,0% | 0,0% |
| error_in_raw_text | categorical | agent_a | 25,7% | 25,7% | 25,7% |
| mentions_pre_registered_design_and_analysis_plan | binary | agent_b | 46,7% | 92,0% | 44,9% |
| makes_implicit_causal_claim | binary | agent_b | 47,4% | 80,0% | 47,6% |
| makes_explicit_causal_claim | binary | agent_b | 50,5% | 82,3% | 50,7% |
| uses_original_dataset | categorical | agent_c | 52,8% | 60,0% | 44,3% |
| seeks_determinants | binary | agent_c | 57,3% | 65,1% | 55,7% |
| references_power_analysis | binary | agent_b | 60,2% | 63,4% | 20,6% |
| specifies_estimate_equations | binary | agent_a | 61,9% | 65,7% | 15,1% |
| general_goal_of_analysis | categorical | agent_c | 62,3% | 68,0% | 71,0% |
| clearly_defined_explanatory_variable | binary | agent_c | 63,6% | 64,0% | 36,6% |
| clear_causal_quantity_of_interest | binary | agent_c | 67,2% | 70,3% | 15,4% |
| claims_any_statistically_significant_results | binary | agent_a | 67,6% | 69,7% | 33,3% |
| discusses_threats_to_causality | binary | agent_a | 69,9% | 70,3% | 28,5% |
| statement_of_identification_assumptions | binary | agent_c | 71,4% | 73,7% | 33,9% |
| effort_to_explore_mechanisms | categorical | agent_c | 72,2% | 77,1% | 14,4% |
| strong_non_causal_causal_qualification | binary | agent_c | 72,4% | 82,3% | 24,2% |
| evidence_type | categorical | agent_a | 72,6% | 77,7% | 72,6% |
| single_region | categorical | agent_a | 74,1% | 74,9% | 11,1% |
| countries_of_focus | text_or_structured_exact | agent_b | 74,3% | 79,4% | 68,8% |

## Acurácia exata por agente e campo

| agent_id | field | field_type | gold_non_null_n | pred_non_null_n | pred_coverage_non_null | exact_matches | exact_accuracy_all | exact_accuracy_gold_non_null |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| agent_a | claims_any_statistically_significant_results | binary | 60,000 | 34,000 | 19,4% | 122,000 | 69,7% | 31,7% |
| agent_b | claims_any_statistically_significant_results | binary | 60,000 | 38,000 | 21,7% | 120,000 | 68,6% | 33,3% |
| agent_c | claims_any_statistically_significant_results | binary | 60,000 | 48,000 | 27,4% | 113,000 | 64,6% | 35,0% |
| agent_c | clear_causal_quantity_of_interest | binary | 39,000 | 21,000 | 12,0% | 123,000 | 70,3% | 10,3% |
| agent_a | clear_causal_quantity_of_interest | binary | 39,000 | 34,000 | 19,4% | 118,000 | 67,4% | 20,5% |
| agent_b | clear_causal_quantity_of_interest | binary | 39,000 | 36,000 | 20,6% | 112,000 | 64,0% | 15,4% |
| agent_c | clearly_defined_explanatory_variable | binary | 62,000 | 49,000 | 28,0% | 112,000 | 64,0% | 35,5% |
| agent_a | clearly_defined_explanatory_variable | binary | 62,000 | 51,000 | 29,1% | 111,000 | 63,4% | 35,5% |
| agent_b | clearly_defined_explanatory_variable | binary | 62,000 | 57,000 | 32,6% | 111,000 | 63,4% | 38,7% |
| agent_a | discusses_threats_to_causality | binary | 62,000 | 34,000 | 19,4% | 123,000 | 70,3% | 33,9% |
| agent_b | discusses_threats_to_causality | binary | 62,000 | 36,000 | 20,6% | 122,000 | 69,7% | 35,5% |
| agent_c | discusses_threats_to_causality | binary | 62,000 | 21,000 | 12,0% | 122,000 | 69,7% | 16,1% |
| agent_b | is_empirical_quant_paper | binary | 175,000 | 175,000 | 100,0% | 157,000 | 89,7% | 89,7% |
| agent_c | is_empirical_quant_paper | binary | 175,000 | 175,000 | 100,0% | 153,000 | 87,4% | 87,4% |
| agent_a | is_empirical_quant_paper | binary | 175,000 | 175,000 | 100,0% | 152,000 | 86,9% | 86,9% |
| agent_b | makes_explicit_causal_claim | binary | 171,000 | 175,000 | 100,0% | 144,000 | 82,3% | 84,2% |
| agent_a | makes_explicit_causal_claim | binary | 171,000 | 110,000 | 62,9% | 98,000 | 56,0% | 56,7% |
| agent_c | makes_explicit_causal_claim | binary | 171,000 | 29,000 | 16,6% | 23,000 | 13,1% | 11,1% |
| agent_b | makes_implicit_causal_claim | binary | 171,000 | 175,000 | 100,0% | 140,000 | 80,0% | 81,9% |
| agent_a | makes_implicit_causal_claim | binary | 171,000 | 110,000 | 62,9% | 84,000 | 48,0% | 48,5% |
| agent_c | makes_implicit_causal_claim | binary | 171,000 | 28,000 | 16,0% | 25,000 | 14,3% | 12,3% |
| agent_b | mentions_pre_registered_design_and_analysis_plan | binary | 161,000 | 175,000 | 100,0% | 161,000 | 92,0% | 100,0% |
| agent_a | mentions_pre_registered_design_and_analysis_plan | binary | 161,000 | 51,000 | 29,1% | 65,000 | 37,1% | 31,7% |
| agent_c | mentions_pre_registered_design_and_analysis_plan | binary | 161,000 | 5,000 | 2,9% | 19,000 | 10,9% | 3,1% |
| agent_c | placebo_test | binary | 17,000 | 3,000 | 1,7% | 155,000 | 88,6% | 0,0% |
| agent_a | placebo_test | binary | 17,000 | 16,000 | 9,1% | 148,000 | 84,6% | 17,6% |
| agent_b | placebo_test | binary | 17,000 | 36,000 | 20,6% | 132,000 | 75,4% | 29,4% |
| agent_b | references_power_analysis | binary | 42,000 | 38,000 | 21,7% | 111,000 | 63,4% | 19,0% |
| agent_a | references_power_analysis | binary | 42,000 | 51,000 | 29,1% | 103,000 | 58,9% | 23,8% |
| agent_c | references_power_analysis | binary | 42,000 | 48,000 | 27,4% | 102,000 | 58,3% | 19,0% |
| agent_c | seeks_determinants | binary | 85,000 | 53,000 | 30,3% | 114,000 | 65,1% | 42,4% |
| agent_a | seeks_determinants | binary | 85,000 | 110,000 | 62,9% | 94,000 | 53,7% | 60,0% |
| agent_b | seeks_determinants | binary | 85,000 | 116,000 | 66,3% | 93,000 | 53,1% | 64,7% |
| agent_a | specifies_estimate_equations | binary | 42,000 | 33,000 | 18,9% | 115,000 | 65,7% | 14,3% |
| agent_b | specifies_estimate_equations | binary | 42,000 | 38,000 | 21,7% | 108,000 | 61,7% | 11,9% |
| agent_c | specifies_estimate_equations | binary | 42,000 | 48,000 | 27,4% | 102,000 | 58,3% | 19,0% |
| agent_c | statement_of_identification_assumptions | binary | 62,000 | 20,000 | 11,4% | 129,000 | 73,7% | 29,0% |
| agent_a | statement_of_identification_assumptions | binary | 62,000 | 34,000 | 19,4% | 123,000 | 70,3% | 35,5% |
| agent_b | statement_of_identification_assumptions | binary | 62,000 | 36,000 | 20,6% | 123,000 | 70,3% | 37,1% |
| agent_c | strong_non_causal_causal_qualification | binary | 22,000 | 10,000 | 5,7% | 144,000 | 82,3% | 0,0% |
| agent_b | strong_non_causal_causal_qualification | binary | 22,000 | 36,000 | 20,6% | 128,000 | 73,1% | 22,7% |
| agent_a | strong_non_causal_causal_qualification | binary | 22,000 | 67,000 | 38,3% | 108,000 | 61,7% | 50,0% |
| agent_c | effort_to_explore_mechanisms | categorical | 37,000 | 16,000 | 9,1% | 135,000 | 77,1% | 10,8% |
| agent_a | effort_to_explore_mechanisms | categorical | 37,000 | 34,000 | 19,4% | 126,000 | 72,0% | 5,4% |
| agent_b | effort_to_explore_mechanisms | categorical | 37,000 | 57,000 | 32,6% | 118,000 | 67,4% | 27,0% |
| agent_a | error_in_raw_text | categorical | 175,000 | 175,000 | 100,0% | 45,000 | 25,7% | 25,7% |
| agent_b | error_in_raw_text | categorical | 175,000 | 175,000 | 100,0% | 45,000 | 25,7% | 25,7% |
| agent_c | error_in_raw_text | categorical | 175,000 | 175,000 | 100,0% | 45,000 | 25,7% | 25,7% |
| agent_a | evidence_type | categorical | 175,000 | 175,000 | 100,0% | 136,000 | 77,7% | 77,7% |
| agent_b | evidence_type | categorical | 175,000 | 175,000 | 100,0% | 133,000 | 76,0% | 76,0% |
| agent_c | evidence_type | categorical | 175,000 | 175,000 | 100,0% | 112,000 | 64,0% | 64,0% |
| agent_c | general_goal_of_analysis | categorical | 69,000 | 87,000 | 49,7% | 119,000 | 68,0% | 66,7% |
| agent_a | general_goal_of_analysis | categorical | 69,000 | 110,000 | 62,9% | 107,000 | 61,1% | 71,0% |
| agent_b | general_goal_of_analysis | categorical | 69,000 | 117,000 | 66,9% | 101,000 | 57,7% | 75,4% |
| agent_a | main_causal_research_design | categorical | 21,000 | 16,000 | 9,1% | 165,000 | 94,3% | 61,9% |
| agent_c | main_causal_research_design | categorical | 21,000 | 20,000 | 11,4% | 164,000 | 93,7% | 61,9% |
| agent_b | main_causal_research_design | categorical | 21,000 | 36,000 | 20,6% | 151,000 | 86,3% | 66,7% |
| agent_b | method_status | categorical | 175,000 | 175,000 | 100,0% | 149,000 | 85,1% | 85,1% |
| agent_a | method_status | categorical | 175,000 | 175,000 | 100,0% | 148,000 | 84,6% | 84,6% |
| agent_c | method_status | categorical | 175,000 | 175,000 | 100,0% | 135,000 | 77,1% | 77,1% |
| agent_a | other_research_design | categorical | 7,000 | 3,000 | 1,7% | 166,000 | 94,9% | 0,0% |
| agent_c | other_research_design | categorical | 7,000 | 7,000 | 4,0% | 162,000 | 92,6% | 0,0% |
| agent_b | other_research_design | categorical | 7,000 | 22,000 | 12,6% | 149,000 | 85,1% | 0,0% |
| agent_b | paper_uses_survey_data | categorical | 175,000 | 175,000 | 100,0% | 163,000 | 93,1% | 93,1% |
| agent_a | paper_uses_survey_data | categorical | 175,000 | 175,000 | 100,0% | 161,000 | 92,0% | 92,0% |
| agent_c | paper_uses_survey_data | categorical | 175,000 | 175,000 | 100,0% | 159,000 | 90,9% | 90,9% |
| agent_a | single_country_study | categorical | 128,000 | 124,000 | 70,9% | 151,000 | 86,3% | 87,5% |
| agent_b | single_country_study | categorical | 128,000 | 107,000 | 61,1% | 141,000 | 80,6% | 75,8% |
| agent_c | single_country_study | categorical | 128,000 | 79,000 | 45,1% | 119,000 | 68,0% | 57,8% |
| agent_a | single_region | categorical | 27,000 | 27,000 | 15,4% | 131,000 | 74,9% | 14,8% |
| agent_c | single_region | categorical | 27,000 | 21,000 | 12,0% | 130,000 | 74,3% | 3,7% |
| agent_b | single_region | categorical | 27,000 | 30,000 | 17,1% | 128,000 | 73,1% | 14,8% |
| agent_a | subfield | categorical | 175,000 | 175,000 | 100,0% | 145,000 | 82,9% | 82,9% |
| agent_b | subfield | categorical | 175,000 | 175,000 | 100,0% | 143,000 | 81,7% | 81,7% |
| agent_c | subfield | categorical | 175,000 | 175,000 | 100,0% | 132,000 | 75,4% | 75,4% |
| agent_c | uses_original_dataset | categorical | 82,000 | 61,000 | 34,9% | 105,000 | 60,0% | 39,0% |
| agent_a | uses_original_dataset | categorical | 82,000 | 95,000 | 54,3% | 90,000 | 51,4% | 41,5% |
| agent_b | uses_original_dataset | categorical | 82,000 | 117,000 | 66,9% | 82,000 | 46,9% | 52,4% |
| agent_a | brief_justification | text_or_structured_exact | 175,000 | 175,000 | 100,0% | 0,000 | 0,0% | 0,0% |
| agent_b | brief_justification | text_or_structured_exact | 175,000 | 175,000 | 100,0% | 0,000 | 0,0% | 0,0% |
| agent_c | brief_justification | text_or_structured_exact | 175,000 | 175,000 | 100,0% | 0,000 | 0,0% | 0,0% |
| agent_b | countries_of_focus | text_or_structured_exact | 128,000 | 107,000 | 61,1% | 139,000 | 79,4% | 75,0% |
| agent_a | countries_of_focus | text_or_structured_exact | 128,000 | 124,000 | 70,9% | 138,000 | 78,9% | 77,3% |
| agent_c | countries_of_focus | text_or_structured_exact | 128,000 | 74,000 | 42,3% | 113,000 | 64,6% | 53,9% |
| agent_a | dependent_variables | text_or_structured_exact | 10,000 | 14,000 | 8,0% | 156,000 | 89,1% | 0,0% |
| agent_b | dependent_variables | text_or_structured_exact | 10,000 | 38,000 | 21,7% | 135,000 | 77,1% | 0,0% |
| agent_c | dependent_variables | text_or_structured_exact | 10,000 | 48,000 | 27,4% | 125,000 | 71,4% | 0,0% |
| agent_a | independent_variables | text_or_structured_exact | 9,000 | 14,000 | 8,0% | 156,000 | 89,1% | 0,0% |
| agent_b | independent_variables | text_or_structured_exact | 9,000 | 38,000 | 21,7% | 135,000 | 77,1% | 0,0% |
| agent_c | independent_variables | text_or_structured_exact | 9,000 | 46,000 | 26,3% | 127,000 | 72,6% | 0,0% |
| agent_a | instrumental_variable_instrument | text_or_structured_exact | 0,000 | 0,000 | 0,0% | 175,000 | 100,0% | NA |
| agent_b | instrumental_variable_instrument | text_or_structured_exact | 0,000 | 0,000 | 0,0% | 175,000 | 100,0% | NA |
| agent_c | instrumental_variable_instrument | text_or_structured_exact | 0,000 | 0,000 | 0,0% | 175,000 | 100,0% | NA |
| agent_a | main_variable_relationship | text_or_structured_exact | 4,000 | 0,000 | 0,0% | 171,000 | 97,7% | 0,0% |
| agent_b | main_variable_relationship | text_or_structured_exact | 4,000 | 15,000 | 8,6% | 160,000 | 91,4% | 0,0% |
| agent_c | main_variable_relationship | text_or_structured_exact | 4,000 | 17,000 | 9,7% | 158,000 | 90,3% | 0,0% |
| agent_b | sample_size | text_or_structured_exact | 1,000 | 19,000 | 10,9% | 155,000 | 88,6% | 0,0% |
| agent_a | sample_size | text_or_structured_exact | 1,000 | 21,000 | 12,0% | 153,000 | 87,4% | 0,0% |
| agent_c | sample_size | text_or_structured_exact | 1,000 | 35,000 | 20,0% | 141,000 | 80,6% | 100,0% |
| agent_b | sample_size_quote | text_or_structured_exact | 1,000 | 19,000 | 10,9% | 155,000 | 88,6% | 0,0% |
| agent_a | sample_size_quote | text_or_structured_exact | 1,000 | 21,000 | 12,0% | 153,000 | 87,4% | 0,0% |
| agent_c | sample_size_quote | text_or_structured_exact | 1,000 | 35,000 | 20,0% | 140,000 | 80,0% | 0,0% |
| agent_a | statement_of_identification_assumptions_quote | text_or_structured_exact | 0,000 | 0,000 | 0,0% | 175,000 | 100,0% | NA |
| agent_b | statement_of_identification_assumptions_quote | text_or_structured_exact | 0,000 | 0,000 | 0,0% | 175,000 | 100,0% | NA |
| agent_c | statement_of_identification_assumptions_quote | text_or_structured_exact | 0,000 | 1,000 | 0,6% | 174,000 | 99,4% | NA |

## Arquivos gerados

- `data/processed/full_classification_pilot_v2/comparison/manual_gold_all_fields_performance_by_agent_field.csv`
- `data/processed/full_classification_pilot_v2/comparison/manual_gold_binary_fields_performance_by_agent_field.csv`
- `data/processed/full_classification_pilot_v2/comparison/manual_gold_all_fields_predictions_long.csv`
- `data/processed/full_classification_pilot_v2/comparison/manual_gold_all_fields_agent_overall_summary.csv`
- `data/processed/full_classification_pilot_v2/comparison/manual_gold_all_fields_field_overall_summary.csv`
