# Relatório final do piloto v2 de classificação tripla

Gerado em 2026-06-03 21:52:50 -03

## Recomendação objetiva

`nao_escalar_antes_de_adjudicar_falhas_graves_de_fidelidade`

Regra documentada: não escalar enquanto houver JSON ausente/inválido, auditoria de fidelidade incompleta, falha textual grave ou fila crítica relevante sem adjudicação. A classificação anterior entra apenas como diagnóstico, porque foi feita sem body integral.

## Snapshot geral

| metric | value | rate |
| --- | --- | --- |
| artigos |  175 | NA |
| campos_de_classificacao |   35 | NA |
| decisoes_pid_campo | 6125 | NA |
| unanimidade | 4264 | 0.696 |
| maioria_2_contra_1_nao_critica |  976 | 0.159 |
| adjudicacao_total |  885 | 0.144 |
| adjudicacao_campos_criticos |  570 | 0.407 |
| erros_schema_classificacao |    0 | NA |
| auditorias_fidelidade_esperadas |  525 | NA |
| auditorias_fidelidade_presentes |  525 | 1.000 |
| erros_schema_fidelidade |    0 | NA |

## Qualidade do insumo textual

| metric | value |
| --- | --- |
| fonte_canonica | data/processed/fulltext_gold/article_texts_gold.csv |
| coluna_canonica | body_text |
| fonte_canonica_presente | 175 |
| body_canonico_preenchido | 175 |
| hash_body_preenchido | 175 |
| pacotes_derivados | 175 |

Interpretação: a v2 usa o `body_text` integral canônico de `article_texts_gold.csv`. Os pacotes por PID são derivados desse CSV e servem apenas para leitura pelos subagentes.

## Acordo entre agentes A/B/C por campo

| field | critical_field | n_articles | unanimity_n | unanimity_rate | majority_n | majority_rate | critical_disagreement_n | invalid_or_missing_n | adjudication_n | adjudication_rate |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| makes_implicit_causal_claim | TRUE | 175 |   8 | 0.046 |   0 | 0.000 | 154 | 0 | 167 | 0.954 |
| makes_explicit_causal_claim | TRUE | 175 |  18 | 0.103 |   0 | 0.000 | 143 | 0 | 157 | 0.897 |
| effort_to_explore_mechanisms | TRUE | 175 | 113 | 0.646 |   0 | 0.000 |  54 | 0 |  62 | 0.354 |
| evidence_type | TRUE | 175 | 115 | 0.657 |   0 | 0.000 |  57 | 0 |  60 | 0.343 |
| method_status | TRUE | 175 | 130 | 0.743 |   0 | 0.000 |  45 | 0 |  45 | 0.257 |
| main_causal_research_design | TRUE | 175 | 148 | 0.846 |   0 | 0.000 |  27 | 0 |  27 | 0.154 |
| is_empirical_quant_paper | TRUE | 175 | 149 | 0.851 |   0 | 0.000 |  26 | 0 |  26 | 0.149 |
| statement_of_identification_assumptions | TRUE | 175 | 149 | 0.851 |   0 | 0.000 |  26 | 0 |  26 | 0.149 |
| brief_justification | FALSE | 175 |   0 | 0.000 |   0 | 0.000 |   0 | 0 | 175 | 1.000 |
| uses_original_dataset | FALSE | 175 |  93 | 0.531 |  57 | 0.326 |   0 | 0 |  25 | 0.143 |
| dependent_variables | FALSE | 175 | 111 | 0.634 |  42 | 0.240 |   0 | 0 |  22 | 0.126 |
| independent_variables | FALSE | 175 | 113 | 0.646 |  40 | 0.229 |   0 | 0 |  22 | 0.126 |
| main_variable_relationship | FALSE | 175 | 157 | 0.897 |   4 | 0.023 |   0 | 0 |  14 | 0.080 |
| sample_size_quote | FALSE | 175 | 139 | 0.794 |  26 | 0.149 |   0 | 0 |  10 | 0.057 |
| seeks_determinants | FALSE | 175 |  99 | 0.566 |  68 | 0.389 |   0 | 0 |   8 | 0.046 |
| subfield | FALSE | 175 | 122 | 0.697 |  45 | 0.257 |   0 | 0 |   8 | 0.046 |
| countries_of_focus | FALSE | 175 | 115 | 0.657 |  54 | 0.309 |   0 | 0 |   6 | 0.034 |
| strong_non_causal_causal_qualification | FALSE | 175 | 110 | 0.629 |  61 | 0.349 |   0 | 0 |   4 | 0.023 |
| clearly_defined_explanatory_variable | FALSE | 175 | 130 | 0.743 |  42 | 0.240 |   0 | 0 |   3 | 0.017 |
| general_goal_of_analysis | FALSE | 175 | 123 | 0.703 |  49 | 0.280 |   0 | 0 |   3 | 0.017 |
| other_research_design | FALSE | 175 | 149 | 0.851 |  23 | 0.131 |   0 | 0 |   3 | 0.017 |
| sample_size | FALSE | 175 | 146 | 0.834 |  26 | 0.149 |   0 | 0 |   3 | 0.017 |
| specifies_estimate_equations | FALSE | 175 | 141 | 0.806 |  31 | 0.177 |   0 | 0 |   3 | 0.017 |
| discusses_threats_to_causality | FALSE | 175 | 138 | 0.789 |  35 | 0.200 |   0 | 0 |   2 | 0.011 |
| single_country_study | FALSE | 175 | 115 | 0.657 |  58 | 0.331 |   0 | 0 |   2 | 0.011 |
| claims_any_statistically_significant_results | FALSE | 175 | 148 | 0.846 |  26 | 0.149 |   0 | 0 |   1 | 0.006 |
| single_region | FALSE | 175 | 154 | 0.880 |  20 | 0.114 |   0 | 0 |   1 | 0.006 |
| clear_causal_quantity_of_interest | FALSE | 175 | 149 | 0.851 |  26 | 0.149 |   0 | 0 |   0 | 0.000 |
| error_in_raw_text | FALSE | 175 | 175 | 1.000 |   0 | 0.000 |   0 | 0 |   0 | 0.000 |
| instrumental_variable_instrument | FALSE | 175 | 175 | 1.000 |   0 | 0.000 |   0 | 0 |   0 | 0.000 |
| mentions_pre_registered_design_and_analysis_plan | FALSE | 175 |   4 | 0.023 | 171 | 0.977 |   0 | 0 |   0 | 0.000 |
| paper_uses_survey_data | FALSE | 175 | 166 | 0.949 |   9 | 0.051 |   0 | 0 |   0 | 0.000 |
| placebo_test | FALSE | 175 | 139 | 0.794 |  36 | 0.206 |   0 | 0 |   0 | 0.000 |
| references_power_analysis | FALSE | 175 | 149 | 0.851 |  26 | 0.149 |   0 | 0 |   0 | 0.000 |
| statement_of_identification_assumptions_quote | FALSE | 175 | 174 | 0.994 |   1 | 0.006 |   0 | 0 |   0 | 0.000 |

## Campos instáveis

| field | critical_field | unanimity_rate | majority_rate | adjudication_rate | invalid_or_missing_n |
| --- | --- | --- | --- | --- | --- |
| makes_implicit_causal_claim | TRUE | 0.046 | 0.000 | 0.954 | 0 |
| makes_explicit_causal_claim | TRUE | 0.103 | 0.000 | 0.897 | 0 |
| effort_to_explore_mechanisms | TRUE | 0.646 | 0.000 | 0.354 | 0 |
| evidence_type | TRUE | 0.657 | 0.000 | 0.343 | 0 |
| method_status | TRUE | 0.743 | 0.000 | 0.257 | 0 |
| main_causal_research_design | TRUE | 0.846 | 0.000 | 0.154 | 0 |
| is_empirical_quant_paper | TRUE | 0.851 | 0.000 | 0.149 | 0 |
| statement_of_identification_assumptions | TRUE | 0.851 | 0.000 | 0.149 | 0 |
| brief_justification | FALSE | 0.000 | 0.000 | 1.000 | 0 |
| uses_original_dataset | FALSE | 0.531 | 0.326 | 0.143 | 0 |
| dependent_variables | FALSE | 0.634 | 0.240 | 0.126 | 0 |
| independent_variables | FALSE | 0.646 | 0.229 | 0.126 | 0 |
| main_variable_relationship | FALSE | 0.897 | 0.023 | 0.080 | 0 |
| sample_size_quote | FALSE | 0.794 | 0.149 | 0.057 | 0 |
| seeks_determinants | FALSE | 0.566 | 0.389 | 0.046 | 0 |
| subfield | FALSE | 0.697 | 0.257 | 0.046 | 0 |
| countries_of_focus | FALSE | 0.657 | 0.309 | 0.034 | 0 |
| strong_non_causal_causal_qualification | FALSE | 0.629 | 0.349 | 0.023 | 0 |
| general_goal_of_analysis | FALSE | 0.703 | 0.280 | 0.017 | 0 |
| clearly_defined_explanatory_variable | FALSE | 0.743 | 0.240 | 0.017 | 0 |
| specifies_estimate_equations | FALSE | 0.806 | 0.177 | 0.017 | 0 |
| sample_size | FALSE | 0.834 | 0.149 | 0.017 | 0 |
| other_research_design | FALSE | 0.851 | 0.131 | 0.017 | 0 |
| single_country_study | FALSE | 0.657 | 0.331 | 0.011 | 0 |
| discusses_threats_to_causality | FALSE | 0.789 | 0.200 | 0.011 | 0 |
| claims_any_statistically_significant_results | FALSE | 0.846 | 0.149 | 0.006 | 0 |
| single_region | FALSE | 0.880 | 0.114 | 0.006 | 0 |
| mentions_pre_registered_design_and_analysis_plan | FALSE | 0.023 | 0.977 | 0.000 | 0 |
| placebo_test | FALSE | 0.794 | 0.206 | 0.000 | 0 |

## Fidelidade textual do Agente D

| audited_agent_id | audited_fields | factual_fields | supported_factual_fields | factual_support_rate | contradicted_n | not_found_n | high_severity_n | medium_severity_n |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| agent_b | 2975 | 2975 | 2714 | 0.912 | 150 | 111 | 52 | 195 |
| agent_a | 2975 | 2975 | 2746 | 0.923 | 105 | 124 | 39 | 162 |
| agent_c | 2975 | 2975 | 2819 | 0.948 |  26 | 130 | 77 |  70 |

## Campos com maior risco de invenção

| field | audited_fields | factual_fields | supported_factual_fields | factual_support_rate | contradicted_n | not_found_n | high_severity_n | medium_severity_n |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| makes_explicit_causal_claim | 525 | 525 | 303 | 0.577 | 212 | 10 |  0 | 222 |
| uses_original_dataset | 525 | 525 | 408 | 0.777 |  36 | 81 |  0 | 117 |
| paper_uses_survey_data | 525 | 525 | 464 | 0.884 |   4 | 57 | 58 |   3 |
| sample_size_quote | 525 | 525 | 481 | 0.916 |   0 | 44 | 44 |   0 |
| sample_size | 525 | 525 | 486 | 0.926 |   0 | 39 | 39 |   0 |
| effort_to_explore_mechanisms | 525 | 525 | 489 | 0.931 |  27 |  9 |  0 |   9 |
| main_variable_relationship | 525 | 525 | 499 | 0.950 |   0 | 26 | 25 |   1 |
| makes_implicit_causal_claim | 525 | 525 | 501 | 0.954 |   0 | 24 |  0 |   0 |
| dependent_variables | 525 | 525 | 508 | 0.968 |   0 | 17 |  0 |  17 |
| main_causal_research_design | 525 | 525 | 508 | 0.968 |   0 | 17 |  0 |  17 |
| independent_variables | 525 | 525 | 510 | 0.971 |   0 | 15 |  0 |  15 |
| claims_any_statistically_significant_results | 525 | 525 | 511 | 0.973 |   0 | 14 |  0 |  14 |
| specifies_estimate_equations | 525 | 525 | 513 | 0.977 |   0 | 12 |  0 |  12 |
| references_power_analysis | 525 | 525 | 523 | 0.996 |   2 |  0 |  2 |   0 |
| mentions_pre_registered_design_and_analysis_plan | 525 | 525 | 525 | 1.000 |   0 |  0 |  0 |   0 |
| statement_of_identification_assumptions | 525 | 525 | 525 | 1.000 |   0 |  0 |  0 |   0 |
| statement_of_identification_assumptions_quote | 525 | 525 | 525 | 1.000 |   0 |  0 |  0 |   0 |

## PIDs com falhas graves de fidelidade

| pid | title | audited_agent_id | field | status | severity | reason |
| --- | --- | --- | --- | --- | --- | --- |
| S0011-52582006000100002 | Fundamentos da economia, mercado financeiro e intenção de voto: as eleições presidenciais brasileiras de 1994, 1998 e 2002 | agent_c | paper_uses_survey_data | contradicted_by_text | high | The classification says no survey data, but the body shows survey/questionnaire/opinion-poll data used as evidence in the article's own analysis. |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | agent_b | paper_uses_survey_data | contradicted_by_text | high | The classification says no survey data, but the body shows survey/questionnaire/opinion-poll data used as evidence in the article's own analysis. |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | agent_c | paper_uses_survey_data | contradicted_by_text | high | The classification says no survey data, but the body shows survey/questionnaire/opinion-poll data used as evidence in the article's own analysis. |
| S0034-76122014000500011 | Dificuldades e perspectivas no acesso de micro e pequenas empresas a linhas de crédito públicas: o caso de Chapecó | agent_b | paper_uses_survey_data | contradicted_by_text | high | The classification says no survey data, but the body shows survey/questionnaire/opinion-poll data used as evidence in the article's own analysis. |
| S1981-38212013000100002 | When is statistical significance not significant? | agent_a | references_power_analysis | contradicted_by_text | high | The classification is false, but the body contains direct evidence for the field. |
| S1981-38212013000100002 | When is statistical significance not significant? | agent_c | references_power_analysis | contradicted_by_text | high | The classification is false, but the body contains direct evidence for the field. |
| S0011-52582013000100006 | Os alunos do ensino médio e Sciences Po: entre a meritocracia e a percepção das desigualdades | agent_a | paper_uses_survey_data | not_found_in_text | high | The classification claims an original survey, but no own-analysis survey/questionnaire/opinion-poll evidence was found. |
| S0011-52582013000100006 | Os alunos do ensino médio e Sciences Po: entre a meritocracia e a percepção das desigualdades | agent_b | paper_uses_survey_data | not_found_in_text | high | The classification claims an original survey, but no own-analysis survey/questionnaire/opinion-poll evidence was found. |
| S0011-52582013000100006 | Os alunos do ensino médio e Sciences Po: entre a meritocracia e a percepção das desigualdades | agent_c | paper_uses_survey_data | not_found_in_text | high | The classification claims an original survey, but no own-analysis survey/questionnaire/opinion-poll evidence was found. |
| S0011-52582024000400209 | Entre a Desinstitucionalização e a Resiliência: Participação Institucional no Governo Bolsonaro | agent_c | sample_size | not_found_in_text | high | The accompanying quote is in the body text but does not clearly contain the classified sample size with sample-unit language. |
| S0011-52582024000400209 | Entre a Desinstitucionalização e a Resiliência: Participação Institucional no Governo Bolsonaro | agent_c | sample_size_quote | not_found_in_text | high | The quote appears in the body text but does not clearly support the paired sample-size value. |
| S0034-73292025000200604 | Impact of China&#8211;Latin America Transportation Infrastructure Cooperation on Latin American Economies: A Project Data Study (2009&#8211;2023) | agent_b | main_variable_relationship | not_found_in_text | high | The specific IV-DV relationship claims were not found with result-language support in the body. |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | agent_a | sample_size | not_found_in_text | high | The accompanying quote is in the body text but does not clearly contain the classified sample size with sample-unit language. |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | agent_a | sample_size_quote | not_found_in_text | high | The quote appears in the body text but does not clearly support the paired sample-size value. |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | agent_b | sample_size | not_found_in_text | high | The accompanying quote is in the body text but does not clearly contain the classified sample size with sample-unit language. |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | agent_b | sample_size_quote | not_found_in_text | high | The quote appears in the body text but does not clearly support the paired sample-size value. |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | agent_c | sample_size | not_found_in_text | high | The accompanying quote is in the body text but does not clearly contain the classified sample size with sample-unit language. |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | agent_c | sample_size_quote | not_found_in_text | high | The quote appears in the body text but does not clearly support the paired sample-size value. |
| S0034-76122014000500011 | Dificuldades e perspectivas no acesso de micro e pequenas empresas a linhas de crédito públicas: o caso de Chapecó | agent_a | sample_size | not_found_in_text | high | The accompanying quote is in the body text but does not clearly contain the classified sample size with sample-unit language. |
| S0034-76122014000500011 | Dificuldades e perspectivas no acesso de micro e pequenas empresas a linhas de crédito públicas: o caso de Chapecó | agent_a | sample_size_quote | not_found_in_text | high | The quote appears in the body text but does not clearly support the paired sample-size value. |
| S0034-76122014000500011 | Dificuldades e perspectivas no acesso de micro e pequenas empresas a linhas de crédito públicas: o caso de Chapecó | agent_c | sample_size | not_found_in_text | high | The accompanying quote is in the body text but does not clearly contain the classified sample size with sample-unit language. |
| S0034-76122014000500011 | Dificuldades e perspectivas no acesso de micro e pequenas empresas a linhas de crédito públicas: o caso de Chapecó | agent_c | sample_size_quote | not_found_in_text | high | The quote appears in the body text but does not clearly support the paired sample-size value. |
| S0034-76122017000500879 | Determinantes para o cumprimento de prazo e preço em obras da educação: uma análise nos municípios capixabas | agent_b | main_variable_relationship | not_found_in_text | high | The specific IV-DV relationship claims were not found with result-language support in the body. |
| S0034-76122017000500879 | Determinantes para o cumprimento de prazo e preço em obras da educação: uma análise nos municípios capixabas | agent_c | main_variable_relationship | not_found_in_text | high | The specific IV-DV relationship claims were not found with result-language support in the body. |
| S0034-76122020000100181 | Ecossistema de inovação social, sustentabilidade e experimentação democrática: um estudo em Florianópolis | agent_a | paper_uses_survey_data | not_found_in_text | high | The classification claims an original survey, but no own-analysis survey/questionnaire/opinion-poll evidence was found. |
| S0034-76122020000100181 | Ecossistema de inovação social, sustentabilidade e experimentação democrática: um estudo em Florianópolis | agent_a | sample_size | not_found_in_text | high | The accompanying quote is in the body text but does not clearly contain the classified sample size with sample-unit language. |
| S0034-76122020000100181 | Ecossistema de inovação social, sustentabilidade e experimentação democrática: um estudo em Florianópolis | agent_a | sample_size_quote | not_found_in_text | high | The quote appears in the body text but does not clearly support the paired sample-size value. |
| S0034-76122024000200402 | Fatores que aumentam o tempo do processo judicial no Brasil | agent_a | sample_size | not_found_in_text | high | The accompanying quote is in the body text but does not clearly contain the classified sample size with sample-unit language. |
| S0034-76122024000200402 | Fatores que aumentam o tempo do processo judicial no Brasil | agent_a | sample_size_quote | not_found_in_text | high | The quote appears in the body text but does not clearly support the paired sample-size value. |
| S0034-76122024000200402 | Fatores que aumentam o tempo do processo judicial no Brasil | agent_b | sample_size | not_found_in_text | high | The accompanying quote is in the body text but does not clearly contain the classified sample size with sample-unit language. |
| S0034-76122024000200402 | Fatores que aumentam o tempo do processo judicial no Brasil | agent_b | sample_size_quote | not_found_in_text | high | The quote appears in the body text but does not clearly support the paired sample-size value. |
| S0034-76122024000200402 | Fatores que aumentam o tempo do processo judicial no Brasil | agent_c | sample_size | not_found_in_text | high | The accompanying quote is in the body text but does not clearly contain the classified sample size with sample-unit language. |
| S0034-76122024000200402 | Fatores que aumentam o tempo do processo judicial no Brasil | agent_c | sample_size_quote | not_found_in_text | high | The quote appears in the body text but does not clearly support the paired sample-size value. |
| S0101-33002011000300004 | Trabalhar para estudar: sobre a pertinência da noção de transição escola-trabalho no Brasil | agent_a | paper_uses_survey_data | not_found_in_text | high | The classification claims survey data, but no own-analysis survey/questionnaire/opinion-poll evidence was found. |
| S0101-33002011000300004 | Trabalhar para estudar: sobre a pertinência da noção de transição escola-trabalho no Brasil | agent_b | paper_uses_survey_data | not_found_in_text | high | The classification claims survey data, but no own-analysis survey/questionnaire/opinion-poll evidence was found. |
| S0101-33002014000100004 | Escassez de engenheiros no Brasil? uma proposta de sistematização do debate | agent_b | paper_uses_survey_data | not_found_in_text | high | The classification claims survey data, but no own-analysis survey/questionnaire/opinion-poll evidence was found. |
| S0101-33002019000100006 | REVOLUÇÕES NO CAMPO RELIGIOSO | agent_b | paper_uses_survey_data | not_found_in_text | high | The classification claims survey data, but no own-analysis survey/questionnaire/opinion-poll evidence was found. |
| S0101-33002024000300409 | Trabalho remunerado e de cuidados na Cidade do México: os efeitos da pandemia da Covid-19 sobre as desigualdades sociais e a convivialidade | agent_a | paper_uses_survey_data | not_found_in_text | high | The classification claims an original survey, but no own-analysis survey/questionnaire/opinion-poll evidence was found. |
| S0101-33002024000300409 | Trabalho remunerado e de cuidados na Cidade do México: os efeitos da pandemia da Covid-19 sobre as desigualdades sociais e a convivialidade | agent_a | sample_size | not_found_in_text | high | The accompanying quote is in the body text but does not clearly contain the classified sample size with sample-unit language. |
| S0101-33002024000300409 | Trabalho remunerado e de cuidados na Cidade do México: os efeitos da pandemia da Covid-19 sobre as desigualdades sociais e a convivialidade | agent_a | sample_size_quote | not_found_in_text | high | The quote appears in the body text but does not clearly support the paired sample-size value. |

## Agentes mais permissivos

| agent_id | audited_signal_slots | permissive_signal_n | permissive_signal_rate |
| --- | --- | --- | --- |
| agent_a | 2975 | 378 | 0.127 |
| agent_b | 2975 | 371 | 0.125 |
| agent_c | 2975 | 311 | 0.105 |

## Fila de adjudicação priorizada

| pid | title | field | critical_field | consensus_level | priority_score | adjudication_reason | fidelity_agents_with_issue |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S0104-62762012000200003 | Solidariedade e expressão jurídica: valores políticos de vereadores sobre direitos sociais | sample_size_quote | FALSE | no_majority | 20 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_a; agent_b; agent_c |
| S1981-38212009000100011 | Social Scientists and Public Administration in the Lula da Silva Government | sample_size_quote | FALSE | no_majority | 20 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_a; agent_b; agent_c |
| S1981-38212010000100131 | Private Security and the State in Latin America: the Case of Mexico City | sample_size_quote | FALSE | no_majority | 20 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_a; agent_b; agent_c |
| S0011-52582013000100006 | Os alunos do ensino médio e Sciences Po: entre a meritocracia e a percepção das desigualdades | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | sample_size | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | sample_size_quote | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122024000200402 | Fatores que aumentam o tempo do processo judicial no Brasil | sample_size | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122024000200402 | Fatores que aumentam o tempo do processo judicial no Brasil | sample_size_quote | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0101-33002024000300409 | Trabalho remunerado e de cuidados na Cidade do México: os efeitos da pandemia da Covid-19 sobre as desigualdades sociais e a convivialidade | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0101-33002024000300409 | Trabalho remunerado e de cuidados na Cidade do México: os efeitos da pandemia da Covid-19 sobre as desigualdades sociais e a convivialidade | sample_size | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0101-33002024000300409 | Trabalho remunerado e de cuidados na Cidade do México: os efeitos da pandemia da Covid-19 sobre as desigualdades sociais e a convivialidade | sample_size_quote | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0102-69092018000300507 | O OVO E A GALINHA. Estudo do enquadramento e da recepção da cobertura jornalística no pleito de 2014 | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0102-69092019000200505 | CLASSE SOCIAL E ALIMENTAÇÃO: PADRÕES DE CONSUMO ALIMENTAR NO BRASIL CONTEMPORÂNEO | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0102-69092019000300509 | EXISTEM PREFERÊNCIAS DE SEXO NO BRASIL? | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762006000200005 | Os militantes são mais informados? Desigualdade e informação política nas eleições de 2002 | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762007000200001 | Eleições e capital social: uma análise das eleições presidenciais no Brasil (2002-2006) | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762012000200003 | Solidariedade e expressão jurídica: valores políticos de vereadores sobre direitos sociais | sample_size | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762014000300523 | Encarte de dados: Opinião sobre questões de segurança pública e comportamento social | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762015000100132 | Confiança nas Forças Armadas brasileiras: uma análise empírica a partir dos dados da pesquisa SIPS - Defesa Nacional | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762016000200318 | Medindo o acesso à Justiça Cível no Brasil | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762020000100034 | Medo da violência e adesão ao autoritarismo no Brasil: proposta metodológica e resultados em 2017 | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212007000100070 | Relevant Factors for the Voting Decision in the 2002 Presidential Election: An Analysis of the ESEB (Brazilian Electoral Study) Data | sample_size | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212007000100070 | Relevant Factors for the Voting Decision in the 2002 Presidential Election: An Analysis of the ESEB (Brazilian Electoral Study) Data | sample_size_quote | FALSE | majority | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212009000100011 | Social Scientists and Public Administration in the Lula da Silva Government | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212010000100131 | Private Security and the State in Latin America: the Case of Mexico City | sample_size | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212013000200003 | Perceptions on justice, the judiciary and democracy | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212015000300021 | The Elusive New Middle Class in Brazil | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212019000100200 | Mapping Ideological Preferences in Brazilian Elections, 1994-2018: A Municipal-Level Study | paper_uses_survey_data | FALSE | unanimity | 18 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | paper_uses_survey_data | FALSE | majority | 16 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0011-52582024000400209 | Entre a Desinstitucionalização e a Resiliência: Participação Institucional no Governo Bolsonaro | makes_explicit_causal_claim | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122009000300003 | Exames de mamografia em Mato Grosso do Sul: análise da cobertura como componente de equidade | makes_explicit_causal_claim | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122014000100004 | Legitimidade das organizações da sociedade civil: análise de conteúdo à luz da teoria da capacidade crítica | makes_explicit_causal_claim | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122014000500011 | Dificuldades e perspectivas no acesso de micro e pequenas empresas a linhas de crédito públicas: o caso de Chapecó | makes_explicit_causal_claim | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0101-33002014000100004 | Escassez de engenheiros no Brasil? uma proposta de sistematização do debate | makes_explicit_causal_claim | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0102-64452013000100013 | O STF e a agenda pública nacional: de outro desconhecido a supremo protagonista? | makes_explicit_causal_claim | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0102-69092018000300507 | O OVO E A GALINHA. Estudo do enquadramento e da recepção da cobertura jornalística no pleito de 2014 | makes_explicit_causal_claim | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-44782024000100204 | Polarização e ideologia: explorando a natureza contextual do compromisso democrático | main_causal_research_design | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762015000100132 | Confiança nas Forças Armadas brasileiras: uma análise empírica a partir dos dados da pesquisa SIPS - Defesa Nacional | makes_explicit_causal_claim | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0104-62762025000100220 | Determinantes da confiança na Polícia Nacional: o caso dos Carabineros chilenos, 2015-2020 | main_causal_research_design | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212007000100070 | Relevant Factors for the Voting Decision in the 2002 Presidential Election: An Analysis of the ESEB (Brazilian Electoral Study) Data | main_causal_research_design | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212013000200003 | Perceptions on justice, the judiciary and democracy | main_causal_research_design | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S1981-38212019000100200 | Mapping Ideological Preferences in Brazilian Elections, 1994-2018: A Municipal-Level Study | main_causal_research_design | TRUE | unanimity | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122014000500011 | Dificuldades e perspectivas no acesso de micro e pequenas empresas a linhas de crédito públicas: o caso de Chapecó | paper_uses_survey_data | FALSE | majority | 14 | falha_de_fidelidade_textual | agent_a; agent_b; agent_c |
| S0034-76122017000500879 | Determinantes para o cumprimento de prazo e preço em obras da educação: uma análise nos municípios capixabas | main_variable_relationship | FALSE | no_majority | 14 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_b; agent_c |
| S0103-33522019000300077 | Fronteiras de Estados emergentes: migração, cidadania pós-nacional e trabalhadores latino-americanos no Brasil, | main_variable_relationship | FALSE | no_majority | 14 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_b; agent_c |
| S0104-44782024000100204 | Polarização e ideologia: explorando a natureza contextual do compromisso democrático | main_variable_relationship | FALSE | no_majority | 14 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_b; agent_c |
| S0104-44782024000100204 | Polarização e ideologia: explorando a natureza contextual do compromisso democrático | sample_size_quote | FALSE | no_majority | 14 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_b; agent_c |
| S0104-62762006000200005 | Os militantes são mais informados? Desigualdade e informação política nas eleições de 2002 | main_variable_relationship | FALSE | no_majority | 14 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_b; agent_c |
| S0104-62762014000300377 | A identificação de enquadramentos através da análise de correspondências: um modelo analítico aplicado à controvérsia das ações afirmativas raciais na imprensa | sample_size_quote | FALSE | no_majority | 14 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_a; agent_c |
| S0104-62762015000100132 | Confiança nas Forças Armadas brasileiras: uma análise empírica a partir dos dados da pesquisa SIPS - Defesa Nacional | main_variable_relationship | FALSE | no_majority | 14 | desacordo_entre_agentes_e_falha_de_fidelidade | agent_b; agent_c |

## Comparação diagnóstica contra a classificação anterior

A rodada anterior foi feita sem body integral. As tabelas abaixo medem divergência operacional, não validam a v2 contra um gold substantivo.

### Acordo do consenso v2 contra a rodada anterior

| field | critical_field | n_articles | n_consensus_accepted | n_matches_previous | agreement_rate |
| --- | --- | --- | --- | --- | --- |
| makes_explicit_causal_claim | TRUE | 175 |  18 |  13 | 0.722 |
| statement_of_identification_assumptions | TRUE | 175 | 149 | 113 | 0.758 |
| evidence_type | TRUE | 175 | 115 |  97 | 0.843 |
| makes_implicit_causal_claim | TRUE | 175 |   8 |   7 | 0.875 |
| method_status | TRUE | 175 | 130 | 119 | 0.915 |
| effort_to_explore_mechanisms | TRUE | 175 | 113 | 104 | 0.920 |
| is_empirical_quant_paper | TRUE | 175 | 149 | 140 | 0.940 |
| main_causal_research_design | TRUE | 175 | 148 | 145 | 0.980 |
| error_in_raw_text | FALSE | 175 | 175 |  45 | 0.257 |
| mentions_pre_registered_design_and_analysis_plan | FALSE | 175 | 175 |  66 | 0.377 |
| seeks_determinants | FALSE | 175 | 167 |  94 | 0.563 |
| uses_original_dataset | FALSE | 175 | 150 |  88 | 0.587 |
| references_power_analysis | FALSE | 175 | 175 | 103 | 0.589 |
| specifies_estimate_equations | FALSE | 175 | 172 | 107 | 0.622 |
| clearly_defined_explanatory_variable | FALSE | 175 | 172 | 112 | 0.651 |
| general_goal_of_analysis | FALSE | 175 | 172 | 112 | 0.651 |
| clear_causal_quantity_of_interest | FALSE | 175 | 175 | 117 | 0.669 |
| claims_any_statistically_significant_results | FALSE | 175 | 174 | 120 | 0.690 |
| discusses_threats_to_causality | FALSE | 175 | 173 | 124 | 0.717 |
| single_region | FALSE | 175 | 174 | 131 | 0.753 |
| strong_non_causal_causal_qualification | FALSE | 175 | 171 | 132 | 0.772 |
| countries_of_focus | FALSE | 175 | 169 | 134 | 0.793 |
| single_country_study | FALSE | 175 | 173 | 143 | 0.827 |
| placebo_test | FALSE | 175 | 175 | 149 | 0.851 |
| subfield | FALSE | 175 | 167 | 145 | 0.868 |
| sample_size | FALSE | 175 | 172 | 151 | 0.878 |
| sample_size_quote | FALSE | 175 | 165 | 151 | 0.915 |
| paper_uses_survey_data | FALSE | 175 | 175 | 162 | 0.926 |
| other_research_design | FALSE | 175 | 172 | 165 | 0.959 |
| dependent_variables | FALSE | 175 | 153 | 149 | 0.974 |
| independent_variables | FALSE | 175 | 153 | 149 | 0.974 |
| instrumental_variable_instrument | FALSE | 175 | 175 | 175 | 1.000 |
| main_variable_relationship | FALSE | 175 | 161 | 161 | 1.000 |
| statement_of_identification_assumptions_quote | FALSE | 175 | 175 | 175 | 1.000 |
| brief_justification | FALSE | 175 |   0 |   0 | NA |

### Campos com divergência diagnóstica elevada

| field | critical_field | n_consensus_accepted | agreement_rate |
| --- | --- | --- | --- |
| makes_explicit_causal_claim | TRUE |  18 | 0.722 |
| statement_of_identification_assumptions | TRUE | 149 | 0.758 |
| evidence_type | TRUE | 115 | 0.843 |
| makes_implicit_causal_claim | TRUE |   8 | 0.875 |
| error_in_raw_text | FALSE | 175 | 0.257 |
| mentions_pre_registered_design_and_analysis_plan | FALSE | 175 | 0.377 |
| seeks_determinants | FALSE | 167 | 0.563 |
| uses_original_dataset | FALSE | 150 | 0.587 |
| references_power_analysis | FALSE | 175 | 0.589 |
| specifies_estimate_equations | FALSE | 172 | 0.622 |
| clearly_defined_explanatory_variable | FALSE | 172 | 0.651 |
| general_goal_of_analysis | FALSE | 172 | 0.651 |
| clear_causal_quantity_of_interest | FALSE | 175 | 0.669 |
| claims_any_statistically_significant_results | FALSE | 174 | 0.690 |
| discusses_threats_to_causality | FALSE | 173 | 0.717 |
| single_region | FALSE | 174 | 0.753 |
| strong_non_causal_causal_qualification | FALSE | 171 | 0.772 |
| countries_of_focus | FALSE | 169 | 0.793 |
| single_country_study | FALSE | 173 | 0.827 |
| placebo_test | FALSE | 175 | 0.851 |
| subfield | FALSE | 167 | 0.868 |
| sample_size | FALSE | 172 | 0.878 |
| brief_justification | FALSE |   0 | NA |

### Sinais diagnósticos de rigor/permissividade contra a rodada anterior

| agent_id | field | value | agent_share | previous_share | share_minus_previous |
| --- | --- | --- | --- | --- | --- |
| agent_c | makes_explicit_causal_claim | FALSE | 0.103 | 0.949 | -0.846 |
| agent_c | makes_implicit_causal_claim | <NULL> | 0.840 | 0.023 |  0.817 |
| agent_c | makes_explicit_causal_claim | <NULL> | 0.834 | 0.023 |  0.811 |
| agent_c | makes_implicit_causal_claim | FALSE | 0.023 | 0.789 | -0.766 |
| agent_a | makes_explicit_causal_claim | FALSE | 0.589 | 0.949 | -0.360 |
| agent_a | makes_explicit_causal_claim | <NULL> | 0.371 | 0.023 |  0.349 |
| agent_a | makes_implicit_causal_claim | <NULL> | 0.371 | 0.023 |  0.349 |
| agent_a | makes_implicit_causal_claim | FALSE | 0.474 | 0.789 | -0.314 |
| agent_c | discusses_threats_to_causality | FALSE | 0.046 | 0.343 | -0.297 |
| agent_c | statement_of_identification_assumptions | FALSE | 0.109 | 0.354 | -0.246 |
| agent_c | statement_of_identification_assumptions | <NULL> | 0.886 | 0.646 |  0.240 |
| agent_c | discusses_threats_to_causality | <NULL> | 0.880 | 0.646 |  0.234 |
| agent_c | evidence_type | qualitative | 0.194 | 0.411 | -0.217 |
| agent_c | evidence_type | theoretical-normative | 0.520 | 0.320 |  0.200 |
| agent_b | makes_implicit_causal_claim | FALSE | 0.977 | 0.789 |  0.189 |
| agent_c | method_status | explicit | 0.383 | 0.554 | -0.171 |
| agent_c | method_status | essayistic | 0.617 | 0.446 |  0.171 |
| agent_b | makes_implicit_causal_claim | TRUE | 0.023 | 0.189 | -0.166 |
| agent_a | discusses_threats_to_causality | <NULL> | 0.806 | 0.646 |  0.160 |
| agent_a | statement_of_identification_assumptions | <NULL> | 0.806 | 0.646 |  0.160 |
| agent_a | statement_of_identification_assumptions | FALSE | 0.194 | 0.354 | -0.160 |
| agent_b | discusses_threats_to_causality | FALSE | 0.189 | 0.343 | -0.154 |
| agent_b | makes_explicit_causal_claim | TRUE | 0.183 | 0.029 |  0.154 |
| agent_b | discusses_threats_to_causality | <NULL> | 0.794 | 0.646 |  0.149 |
| agent_a | discusses_threats_to_causality | FALSE | 0.194 | 0.343 | -0.149 |
| agent_b | statement_of_identification_assumptions | <NULL> | 0.794 | 0.646 |  0.149 |
| agent_b | statement_of_identification_assumptions | FALSE | 0.206 | 0.354 | -0.149 |
| agent_b | makes_explicit_causal_claim | FALSE | 0.817 | 0.949 | -0.131 |
| agent_a | specifies_estimate_equations | FALSE | 0.109 | 0.234 | -0.126 |
| agent_b | main_causal_research_design | Other | 0.126 | 0.006 |  0.120 |

## Arquivos gerados

- `data/processed/full_classification_pilot_v2/comparison/agent_field_agreement.csv`
- `data/processed/full_classification_pilot_v2/comparison/consensus_field_decisions.csv`
- `data/processed/full_classification_pilot_v2/comparison/consensus_classifications.csv`
- `data/processed/full_classification_pilot_v2/comparison/conflicts.csv`
- `data/processed/full_classification_pilot_v2/comparison/adjudication_queue.csv`
- `data/processed/full_classification_pilot_v2/comparison/adjudication_queue_prioritized.csv`
- `data/processed/full_classification_pilot_v2/comparison/previous_classification_agreement_by_agent_field.csv`
- `data/processed/full_classification_pilot_v2/comparison/previous_classification_agreement_consensus_by_field.csv`
- `data/processed/full_classification_pilot_v2/comparison/previous_classification_disagreements.csv`
- `data/processed/full_classification_pilot_v2/comparison/agent_bias_against_previous_diagnostic.csv`
- `data/processed/full_classification_pilot_v2/comparison/agent_permissiveness_summary.csv`
- `data/processed/full_classification_pilot_v2/comparison/fidelity_file_audits.csv`
- `data/processed/full_classification_pilot_v2/comparison/fidelity_field_audits.csv`
- `data/processed/full_classification_pilot_v2/comparison/fidelity_supported_rates_by_agent.csv`
- `data/processed/full_classification_pilot_v2/comparison/fidelity_supported_rates_by_agent_field.csv`
- `data/processed/full_classification_pilot_v2/comparison/fidelity_high_risk_fields.csv`
- `data/processed/full_classification_pilot_v2/comparison/fidelity_severe_failures.csv`
