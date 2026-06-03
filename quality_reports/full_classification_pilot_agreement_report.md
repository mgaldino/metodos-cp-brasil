# Relatorio do piloto de classificacao tripla

Gerado em 2026-06-03 18:00:03 -03

## Recomendacao objetiva

`revisar_manualmente_campos_criticos`

Regra documentada: nao escalar enquanto houver JSON ausente/invalido, fila critica relevante, ou acordo contra gold abaixo do patamar operacional nos campos criticos.

## Snapshot geral

| metric | value | rate |
| --- | --- | --- |
| pid_artigos |  175 | NA |
| campos_classificacao |   35 | NA |
| decisoes_pid_campo | 6125 | NA |
| unanimidade | 3917 | 0.640 |
| maioria_2_contra_1_nao_critica | 1246 | 0.203 |
| adjudicacao_total |  962 | 0.157 |
| adjudicacao_campos_criticos |  642 | 0.459 |
| json_errors_validation |    0 | NA |

## Qualidade do insumo textual

| metric | value |
| --- | --- |
| xml_fonte_presentes | 175 |
| xml_fonte_com_body |   0 |
| raw_fulltext_presentes | 175 |
| raw_fulltext_identico_ao_xml_fonte | 175 |
| raw_fulltext_com_body |   0 |

Interpretacao: se `xml_fonte_com_body` e `raw_fulltext_com_body` forem zero, o piloto avaliou classificacoes feitas sobre o texto local disponivel nos XMLs, nao sobre o corpo integral dos artigos.

## Acordo por campo

| field | critical_field | n_articles | unanimity_n | unanimity_rate | majority_n | majority_rate | critical_disagreement_n | invalid_or_missing_n | adjudication_n | adjudication_rate |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| effort_to_explore_mechanisms | TRUE | 175 |   3 | 0.017 |   0 | 0.000 | 148 | 0 | 172 | 0.983 |
| makes_explicit_causal_claim | TRUE | 175 |  28 | 0.160 |   0 | 0.000 | 145 | 0 | 147 | 0.840 |
| makes_implicit_causal_claim | TRUE | 175 |  34 | 0.194 |   0 | 0.000 | 140 | 0 | 141 | 0.806 |
| statement_of_identification_assumptions | TRUE | 175 | 110 | 0.629 |   0 | 0.000 |  65 | 0 |  65 | 0.371 |
| evidence_type | TRUE | 175 | 132 | 0.754 |   0 | 0.000 |  43 | 0 |  43 | 0.246 |
| method_status | TRUE | 175 | 137 | 0.783 |   0 | 0.000 |  38 | 0 |  38 | 0.217 |
| main_causal_research_design | TRUE | 175 | 149 | 0.851 |   0 | 0.000 |  24 | 0 |  26 | 0.149 |
| is_empirical_quant_paper | TRUE | 175 | 165 | 0.943 |   0 | 0.000 |  10 | 0 |  10 | 0.057 |
| brief_justification | FALSE | 175 |   0 | 0.000 |   0 | 0.000 |   0 | 0 | 175 | 1.000 |
| uses_original_dataset | FALSE | 175 |  89 | 0.509 |  58 | 0.331 |   0 | 0 |  28 | 0.160 |
| independent_variables | FALSE | 175 | 149 | 0.851 |   2 | 0.011 |   0 | 0 |  24 | 0.137 |
| dependent_variables | FALSE | 175 | 149 | 0.851 |   3 | 0.017 |   0 | 0 |  23 | 0.131 |
| main_variable_relationship | FALSE | 175 | 151 | 0.863 |   9 | 0.051 |   0 | 0 |  15 | 0.086 |
| seeks_determinants | FALSE | 175 | 101 | 0.577 |  59 | 0.337 |   0 | 0 |  15 | 0.086 |
| sample_size_quote | FALSE | 175 | 156 | 0.891 |   5 | 0.029 |   0 | 0 |  14 | 0.080 |
| general_goal_of_analysis | FALSE | 175 |  74 | 0.423 |  95 | 0.543 |   0 | 0 |   6 | 0.034 |
| other_research_design | FALSE | 175 | 151 | 0.863 |  19 | 0.109 |   0 | 0 |   5 | 0.029 |
| subfield | FALSE | 175 | 124 | 0.709 |  46 | 0.263 |   0 | 0 |   5 | 0.029 |
| countries_of_focus | FALSE | 175 | 130 | 0.743 |  42 | 0.240 |   0 | 0 |   3 | 0.017 |
| clearly_defined_explanatory_variable | FALSE | 175 |  94 | 0.537 |  79 | 0.451 |   0 | 0 |   2 | 0.011 |
| single_country_study | FALSE | 175 | 118 | 0.674 |  55 | 0.314 |   0 | 0 |   2 | 0.011 |
| strong_non_causal_causal_qualification | FALSE | 175 |  99 | 0.566 |  74 | 0.423 |   0 | 0 |   2 | 0.011 |
| single_region | FALSE | 175 | 143 | 0.817 |  31 | 0.177 |   0 | 0 |   1 | 0.006 |
| claims_any_statistically_significant_results | FALSE | 175 | 152 | 0.869 |  23 | 0.131 |   0 | 0 |   0 | 0.000 |
| clear_causal_quantity_of_interest | FALSE | 175 | 108 | 0.617 |  67 | 0.383 |   0 | 0 |   0 | 0.000 |
| discusses_threats_to_causality | FALSE | 175 | 110 | 0.629 |  65 | 0.371 |   0 | 0 |   0 | 0.000 |
| error_in_raw_text | FALSE | 175 | 175 | 1.000 |   0 | 0.000 |   0 | 0 |   0 | 0.000 |
| instrumental_variable_instrument | FALSE | 175 | 175 | 1.000 |   0 | 0.000 |   0 | 0 |   0 | 0.000 |
| mentions_pre_registered_design_and_analysis_plan | FALSE | 175 |   0 | 0.000 | 175 | 1.000 |   0 | 0 |   0 | 0.000 |
| paper_uses_survey_data | FALSE | 175 | 171 | 0.977 |   4 | 0.023 |   0 | 0 |   0 | 0.000 |
| placebo_test | FALSE | 175 | 110 | 0.629 |  65 | 0.371 |   0 | 0 |   0 | 0.000 |
| references_power_analysis | FALSE | 175 |   0 | 0.000 | 175 | 1.000 |   0 | 0 |   0 | 0.000 |
| sample_size | FALSE | 175 | 167 | 0.954 |   8 | 0.046 |   0 | 0 |   0 | 0.000 |
| specifies_estimate_equations | FALSE | 175 |  88 | 0.503 |  87 | 0.497 |   0 | 0 |   0 | 0.000 |
| statement_of_identification_assumptions_quote | FALSE | 175 | 175 | 1.000 |   0 | 0.000 |   0 | 0 |   0 | 0.000 |

## Campos instaveis

| field | critical_field | unanimity_rate | majority_rate | adjudication_rate | invalid_or_missing_n |
| --- | --- | --- | --- | --- | --- |
| effort_to_explore_mechanisms | TRUE | 0.017 | 0.000 | 0.983 | 0 |
| makes_explicit_causal_claim | TRUE | 0.160 | 0.000 | 0.840 | 0 |
| makes_implicit_causal_claim | TRUE | 0.194 | 0.000 | 0.806 | 0 |
| statement_of_identification_assumptions | TRUE | 0.629 | 0.000 | 0.371 | 0 |
| evidence_type | TRUE | 0.754 | 0.000 | 0.246 | 0 |
| method_status | TRUE | 0.783 | 0.000 | 0.217 | 0 |
| main_causal_research_design | TRUE | 0.851 | 0.000 | 0.149 | 0 |
| is_empirical_quant_paper | TRUE | 0.943 | 0.000 | 0.057 | 0 |
| brief_justification | FALSE | 0.000 | 0.000 | 1.000 | 0 |
| uses_original_dataset | FALSE | 0.509 | 0.331 | 0.160 | 0 |
| independent_variables | FALSE | 0.851 | 0.011 | 0.137 | 0 |
| dependent_variables | FALSE | 0.851 | 0.017 | 0.131 | 0 |
| seeks_determinants | FALSE | 0.577 | 0.337 | 0.086 | 0 |
| main_variable_relationship | FALSE | 0.863 | 0.051 | 0.086 | 0 |
| sample_size_quote | FALSE | 0.891 | 0.029 | 0.080 | 0 |
| general_goal_of_analysis | FALSE | 0.423 | 0.543 | 0.034 | 0 |
| subfield | FALSE | 0.709 | 0.263 | 0.029 | 0 |
| other_research_design | FALSE | 0.863 | 0.109 | 0.029 | 0 |
| countries_of_focus | FALSE | 0.743 | 0.240 | 0.017 | 0 |
| clearly_defined_explanatory_variable | FALSE | 0.537 | 0.451 | 0.011 | 0 |
| strong_non_causal_causal_qualification | FALSE | 0.566 | 0.423 | 0.011 | 0 |
| single_country_study | FALSE | 0.674 | 0.314 | 0.011 | 0 |
| single_region | FALSE | 0.817 | 0.177 | 0.006 | 0 |
| mentions_pre_registered_design_and_analysis_plan | FALSE | 0.000 | 1.000 | 0.000 | 0 |
| references_power_analysis | FALSE | 0.000 | 1.000 | 0.000 | 0 |
| specifies_estimate_equations | FALSE | 0.503 | 0.497 | 0.000 | 0 |
| clear_causal_quantity_of_interest | FALSE | 0.617 | 0.383 | 0.000 | 0 |
| discusses_threats_to_causality | FALSE | 0.629 | 0.371 | 0.000 | 0 |
| placebo_test | FALSE | 0.629 | 0.371 | 0.000 | 0 |

## Comparacao do consenso contra gold

| field | critical_field | n_articles | n_consensus_accepted | n_matches_gold | agreement_rate |
| --- | --- | --- | --- | --- | --- |
| effort_to_explore_mechanisms | TRUE | 175 |   3 |   0 | 0.000 |
| makes_implicit_causal_claim | TRUE | 175 |  34 |  12 | 0.353 |
| makes_explicit_causal_claim | TRUE | 175 |  28 |  10 | 0.357 |
| statement_of_identification_assumptions | TRUE | 175 | 110 |  83 | 0.755 |
| evidence_type | TRUE | 175 | 132 | 116 | 0.879 |
| method_status | TRUE | 175 | 137 | 121 | 0.883 |
| is_empirical_quant_paper | TRUE | 175 | 165 | 152 | 0.921 |
| main_causal_research_design | TRUE | 175 | 149 | 146 | 0.980 |
| mentions_pre_registered_design_and_analysis_plan | FALSE | 175 | 175 |  14 | 0.080 |
| uses_original_dataset | FALSE | 175 | 147 |  85 | 0.578 |
| general_goal_of_analysis | FALSE | 175 | 169 | 100 | 0.592 |
| seeks_determinants | FALSE | 175 | 160 |  95 | 0.594 |
| discusses_threats_to_causality | FALSE | 175 | 175 | 113 | 0.646 |
| claims_any_statistically_significant_results | FALSE | 175 | 175 | 117 | 0.669 |
| specifies_estimate_equations | FALSE | 175 | 175 | 120 | 0.686 |
| strong_non_causal_causal_qualification | FALSE | 175 | 173 | 122 | 0.705 |
| clear_causal_quantity_of_interest | FALSE | 175 | 175 | 125 | 0.714 |
| error_in_raw_text | FALSE | 175 | 175 | 130 | 0.743 |
| clearly_defined_explanatory_variable | FALSE | 175 | 173 | 130 | 0.751 |
| references_power_analysis | FALSE | 175 | 175 | 133 | 0.760 |
| single_region | FALSE | 175 | 174 | 135 | 0.776 |
| subfield | FALSE | 175 | 170 | 147 | 0.865 |
| countries_of_focus | FALSE | 175 | 172 | 151 | 0.878 |
| placebo_test | FALSE | 175 | 175 | 158 | 0.903 |
| single_country_study | FALSE | 175 | 173 | 159 | 0.919 |
| sample_size | FALSE | 175 | 175 | 161 | 0.920 |
| paper_uses_survey_data | FALSE | 175 | 175 | 165 | 0.943 |
| other_research_design | FALSE | 175 | 170 | 162 | 0.953 |
| dependent_variables | FALSE | 175 | 152 | 147 | 0.967 |
| independent_variables | FALSE | 175 | 151 | 148 | 0.980 |
| main_variable_relationship | FALSE | 175 | 160 | 159 | 0.994 |
| sample_size_quote | FALSE | 175 | 161 | 160 | 0.994 |
| instrumental_variable_instrument | FALSE | 175 | 175 | 175 | 1.000 |
| statement_of_identification_assumptions_quote | FALSE | 175 | 175 | 175 | 1.000 |
| brief_justification | FALSE | 175 |   0 |   0 | NA |

## Campos com acordo fraco contra gold

| field | critical_field | n_consensus_accepted | agreement_rate |
| --- | --- | --- | --- |
| effort_to_explore_mechanisms | TRUE |   3 | 0.000 |
| makes_implicit_causal_claim | TRUE |  34 | 0.353 |
| makes_explicit_causal_claim | TRUE |  28 | 0.357 |
| statement_of_identification_assumptions | TRUE | 110 | 0.755 |
| evidence_type | TRUE | 132 | 0.879 |
| method_status | TRUE | 137 | 0.883 |
| mentions_pre_registered_design_and_analysis_plan | FALSE | 175 | 0.080 |
| uses_original_dataset | FALSE | 147 | 0.578 |
| general_goal_of_analysis | FALSE | 169 | 0.592 |
| seeks_determinants | FALSE | 160 | 0.594 |
| discusses_threats_to_causality | FALSE | 175 | 0.646 |
| claims_any_statistically_significant_results | FALSE | 175 | 0.669 |
| specifies_estimate_equations | FALSE | 175 | 0.686 |
| strong_non_causal_causal_qualification | FALSE | 173 | 0.705 |
| clear_causal_quantity_of_interest | FALSE | 175 | 0.714 |
| error_in_raw_text | FALSE | 175 | 0.743 |
| clearly_defined_explanatory_variable | FALSE | 173 | 0.751 |
| references_power_analysis | FALSE | 175 | 0.760 |
| single_region | FALSE | 174 | 0.776 |
| subfield | FALSE | 170 | 0.865 |
| countries_of_focus | FALSE | 172 | 0.878 |
| brief_justification | FALSE |   0 | NA |

## Sinais de rigor/permissividade por agente

| agent_id | field | value | agent_share | gold_share | share_minus_gold |
| --- | --- | --- | --- | --- | --- |
| agent_a | makes_explicit_causal_claim | FALSE | 0.120 | 0.949 | -0.829 |
| agent_a | makes_explicit_causal_claim | <NULL> | 0.657 | 0.023 |  0.634 |
| agent_a | makes_implicit_causal_claim | <NULL> | 0.657 | 0.023 |  0.634 |
| agent_c | makes_explicit_causal_claim | FALSE | 0.360 | 0.949 | -0.589 |
| agent_a | makes_implicit_causal_claim | FALSE | 0.263 | 0.789 | -0.526 |
| agent_c | makes_implicit_causal_claim | <NULL> | 0.446 | 0.023 |  0.423 |
| agent_c | makes_explicit_causal_claim | <NULL> | 0.440 | 0.023 |  0.417 |
| agent_a | discusses_threats_to_causality | <NULL> | 1.000 | 0.646 |  0.354 |
| agent_c | discusses_threats_to_causality | <NULL> | 1.000 | 0.646 |  0.354 |
| agent_a | statement_of_identification_assumptions | <NULL> | 1.000 | 0.646 |  0.354 |
| agent_c | statement_of_identification_assumptions | <NULL> | 1.000 | 0.646 |  0.354 |
| agent_b | makes_explicit_causal_claim | TRUE | 0.354 | 0.029 |  0.326 |
| agent_b | makes_explicit_causal_claim | FALSE | 0.646 | 0.949 | -0.303 |
| agent_b | specifies_estimate_equations | FALSE | 0.497 | 0.234 |  0.263 |
| agent_b | specifies_estimate_equations | <NULL> | 0.503 | 0.760 | -0.257 |
| agent_a | specifies_estimate_equations | <NULL> | 1.000 | 0.760 |  0.240 |
| agent_c | makes_implicit_causal_claim | FALSE | 0.554 | 0.789 | -0.234 |
| agent_a | makes_explicit_causal_claim | TRUE | 0.223 | 0.029 |  0.194 |
| agent_b | makes_implicit_causal_claim | FALSE | 0.983 | 0.789 |  0.194 |
| agent_c | makes_explicit_causal_claim | TRUE | 0.200 | 0.029 |  0.171 |
| agent_b | makes_implicit_causal_claim | TRUE | 0.017 | 0.189 | -0.171 |
| agent_c | method_status | essayistic | 0.560 | 0.446 |  0.114 |
| agent_c | method_status | explicit | 0.440 | 0.554 | -0.114 |
| agent_a | makes_implicit_causal_claim | TRUE | 0.080 | 0.189 | -0.109 |

## Arquivos gerados

- `data/processed/full_classification_pilot/comparison/agent_field_agreement.csv`
- `data/processed/full_classification_pilot/comparison/consensus_field_decisions.csv`
- `data/processed/full_classification_pilot/comparison/consensus_classifications.csv`
- `data/processed/full_classification_pilot/comparison/conflicts.csv`
- `data/processed/full_classification_pilot/comparison/adjudication_queue.csv`
- `data/processed/full_classification_pilot/comparison/gold_agreement_by_agent_field.csv`
- `data/processed/full_classification_pilot/comparison/gold_agreement_consensus_by_field.csv`
- `data/processed/full_classification_pilot/comparison/gold_disagreements.csv`
- `data/processed/full_classification_pilot/comparison/agent_bias_summary.csv`
