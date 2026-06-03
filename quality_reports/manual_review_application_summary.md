# Aplicação das Decisões Manuais

Gerado por `scripts/09_apply_manual_review_decisions.R`.

## Status

Dataset final validado: `scripts/05_validate_classifications.R` registrou zero `ERROR` no resultado final.

`data/processed/classifications_llm.csv` agora é o CSV canônico pós-revisão manual, gerado a partir de `data/processed/classifications_normalized/`, `quality_reports/manual_review_decisions_validated.csv` e `data/processed/manual_review_relationship_overrides.json`.

O snapshot pré-aplicação foi preservado em `data/processed/classifications_llm_pre_manual_review.csv` quando o CSV canônico foi sobrescrito.

## Regra Operacional de Exclusões

- `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` ficam fora da análise principal por regra documentada em `data/processed/excluded_journals.csv`.
- Os artigos listados em `data/processed/excluded_articles.csv` ficam fora da análise principal por regra documentada no próprio ledger.
- Registros excluídos são preservados no corpus e nos JSONs/CSV finais para rastreabilidade.
- `data/processed/classifications_llm_main_analysis.csv` contém apenas a amostra classificada elegível pós-exclusões; use esse arquivo para validação, auditoria e desenvolvimento do pipeline, não como base final de análise substantiva.
- Quando a decisão manual de um registro excluído era `<NULL>` em campo obrigatório do schema rígido, o script aplicou `schema_padding_for_excluded_record`; esses valores existem apenas para manter o registro preservado e schema-válido, não para inclusão analítica.

## Snapshot

| item | value |
| --- | --- |
| JSONs normalizados de entrada | 208 |
| JSONs finais | 208 |
| linhas no CSV final canônico | 208 |
| linhas no CSV elegível da amostra | 175 |
| decisões/pendências processadas | 174 |
| decisões manuais aplicadas | 150 |
| overrides estruturados aplicados | 2 |
| pendências excluídas convertidas em null | 18 |
| schema padding em registros excluídos | 4 |
| grupos pid+field duplicados idempotentes | 3 |
| erros na validação final | 0 |
| avisos na validação final | 9 |

## Ações Aplicadas

| action | queue_source | excluded_from_analysis | n |
| --- | --- | --- | --- |
| apply_manual_decision | main_queue | FALSE | 133 |
| excluded_pending_set_null | excluded_journal_queue | TRUE | 18 |
| apply_manual_decision | excluded_journal_queue | TRUE | 11 |
| apply_manual_decision | excluded_article_queue | TRUE | 6 |
| schema_padding_for_excluded_record | excluded_article_queue | TRUE | 4 |
| apply_structured_override | main_queue | FALSE | 2 |

## Campos Alterados

| field | action | n |
| --- | --- | --- |
| effort_to_explore_mechanisms | apply_manual_decision | 44 |
| effort_to_explore_mechanisms | excluded_pending_set_null | 6 |
| error_in_raw_text | apply_manual_decision | 6 |
| evidence_type | apply_manual_decision | 7 |
| evidence_type | schema_padding_for_excluded_record | 1 |
| general_goal_of_analysis | apply_manual_decision | 28 |
| general_goal_of_analysis | excluded_pending_set_null | 4 |
| is_empirical_quant_paper | apply_manual_decision | 1 |
| main_variable_relationship | apply_manual_decision | 3 |
| main_variable_relationship | apply_structured_override | 2 |
| main_variable_relationship | excluded_pending_set_null | 1 |
| method_status | apply_manual_decision | 23 |
| method_status | schema_padding_for_excluded_record | 3 |
| paper_uses_survey_data | apply_manual_decision | 5 |
| single_country_study | apply_manual_decision | 12 |
| single_country_study | excluded_pending_set_null | 2 |
| single_region | apply_manual_decision | 16 |
| single_region | excluded_pending_set_null | 5 |
| uses_original_dataset | apply_manual_decision | 5 |

## Exclusões na Amostra de Classificação

| excluded_by_journal | excluded_by_article | excluded_from_analysis | n |
| --- | --- | --- | --- |
| FALSE | FALSE | FALSE | 175 |
| FALSE | TRUE | TRUE | 5 |
| TRUE | FALSE | TRUE | 28 |

## Validação Final

| severity | n |
| --- | --- |
| WARN | 9 |

## Arquivos Gerados

- `data/processed/classifications_final`
- `data/processed/classifications_llm.csv`
- `data/processed/classifications_llm_main_analysis.csv`
- `data/processed/classifications_llm_pre_manual_review.csv`
- `quality_reports/manual_review_application_log.csv`
- `quality_reports/manual_review_application_summary.md`
- `quality_reports/classification_validation_issues_final.csv`
- `quality_reports/classification_validation_summary_final.md`
