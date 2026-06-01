# Validação das Classificacoes_Normalizadas_Candidatas

Gerado em 2026-06-01 15:03:54 -03

## Snapshot

| item | value |
| --- | --- |
| rótulo da validação | Classificacoes_Normalizadas_Candidatas |
| diretório de classificações | /Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/classifications_normalized |
| CSV de classificações | /Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/classifications_llm_normalized.csv |
| artigos no corpus | 8400 |
| periódicos no corpus | 15 |
| anos no corpus | 2005-2025 |
| artigos na amostra | 208 |
| linhas na planilha de validação | 208 |
| JSONs de classificação | 208 |
| linhas no CSV consolidado | 208 |
| issues totais | 142 |
| errors | 133 |
| warnings | 9 |

## Issues por Severidade

| severity | n |
| --- | --- |
| ERROR | 133 |
| WARN |   9 |

## Principais Regras com Issues

| severity | scope | rule | n |
| --- | --- | --- | --- |
| ERROR | classification_json | effort_to_explore_mechanisms_invalid | 50 |
| ERROR | classification_json | method_status_invalid | 23 |
| ERROR | classification_json | single_region_invalid | 21 |
| ERROR | classification_json | single_country_study_invalid | 14 |
| WARN | corpus | non_research_article_document_type |  9 |
| ERROR | classification_json | main_variable_relationship_not_array_or_null |  6 |
| ERROR | classification_json | evidence_type_invalid |  5 |
| ERROR | classification_json | uses_original_dataset_invalid |  5 |
| ERROR | classification_json | paper_uses_survey_data_invalid |  3 |
| ERROR | classification_json | evidence_type_null |  2 |
| ERROR | classification_json | method_status_null |  2 |
| ERROR | classification_json | is_empirical_quant_paper_null |  1 |
| ERROR | classification_json | paper_uses_survey_data_null |  1 |

## Próximos Passos

1. Corrigir primeiro os erros de schema em `error_in_raw_text`, `paper_uses_survey_data`, `uses_original_dataset`, `single_country_study`, `single_region`, `clear_causal_quantity_of_interest` e `effort_to_explore_mechanisms`.
2. Decidir se campos extras (`classified_by`, `qualitative_method`) serão incorporados ao schema oficial ou removidos antes da consolidação.
3. Regerar `data/processed/classifications_llm.csv` a partir dos JSONs corrigidos.
4. Só depois usar `classifications_llm.csv` para tabelas, figuras e inferências substantivas.

## Arquivos Gerados

- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/classification_validation_issues_normalized.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/classification_validation_summary_normalized.md`
