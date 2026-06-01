# Validação das Classificações

Gerado em 2026-06-01 14:47:20 -03

## Snapshot

| item | value |
| --- | --- |
| artigos no corpus | 8400 |
| periódicos no corpus | 15 |
| anos no corpus | 2005-2025 |
| artigos na amostra | 208 |
| linhas na planilha de validação | 208 |
| JSONs de classificação | 208 |
| linhas no CSV consolidado | 208 |
| issues totais | 595 |
| errors | 575 |
| warnings | 20 |

## Issues por Severidade

| severity | n |
| --- | --- |
| ERROR | 575 |
| WARN |  20 |

## Principais Regras com Issues

| severity | scope | rule | n |
| --- | --- | --- | --- |
| ERROR | classification_json | missing_field | 123 |
| ERROR | classification_json | uses_original_dataset_invalid |  52 |
| ERROR | classification_json | clear_causal_quantity_of_interest_invalid |  51 |
| ERROR | classification_json | paper_uses_survey_data_invalid |  51 |
| ERROR | classification_json | effort_to_explore_mechanisms_invalid |  50 |
| ERROR | classification_json | error_in_raw_text_invalid |  47 |
| ERROR | classification_json | general_goal_of_analysis_invalid |  38 |
| ERROR | classification_json | single_country_study_invalid |  37 |
| ERROR | classification_json | countries_of_focus_invalid_string |  32 |
| ERROR | classification_json | single_region_invalid |  27 |
| ERROR | classification_json | method_status_invalid |  23 |
| ERROR | classification_json | evidence_type_invalid |  16 |
| WARN | classification_json | extra_field |  11 |
| WARN | corpus | non_research_article_document_type |   9 |
| ERROR | classification_json | main_causal_research_design_invalid |   8 |
| ERROR | classification_json | main_variable_relationship_not_array_or_null |   8 |
| ERROR | classification_json | sample_size_not_nonnegative_integer |   4 |
| ERROR | classification_json | dependent_variables_not_array_or_null |   2 |
| ERROR | classification_json | error_in_raw_text_null |   2 |
| ERROR | classification_json | independent_variables_not_array_or_null |   2 |
| ERROR | classification_json | evidence_type_null |   1 |
| ERROR | classification_json | method_status_null |   1 |

## Próximos Passos

1. Corrigir primeiro os erros de schema em `error_in_raw_text`, `paper_uses_survey_data`, `uses_original_dataset`, `single_country_study`, `single_region`, `clear_causal_quantity_of_interest` e `effort_to_explore_mechanisms`.
2. Decidir se campos extras (`classified_by`, `qualitative_method`) serão incorporados ao schema oficial ou removidos antes da consolidação.
3. Regerar `data/processed/classifications_llm.csv` a partir dos JSONs corrigidos.
4. Só depois usar `classifications_llm.csv` para tabelas, figuras e inferências substantivas.

## Arquivos Gerados

- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/classification_validation_issues.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/classification_validation_summary.md`
