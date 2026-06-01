# Normalização das Classificações

Gerado em 2026-06-01 15:03:54 -03

## Status

Critério operacional atendido: `unexpected_unresolved_errors == 0`.

`data/processed/classifications_llm_normalized.csv` é um candidato normalizado. Casos com `manual_review=TRUE` no log ainda exigem decisão substantiva antes de análises finais.

## Snapshot

| item | value |
| --- | --- |
| JSONs originais | 208 |
| JSONs normalizados | 208 |
| linhas no CSV normalizado | 208 |
| erros originais de classificação | 575 |
| erros normalizados de classificação | 133 |
| unexpected_unresolved_errors |   0 |
| pendências manuais registradas no log | 174 |

## Ações de Normalização

| action | manual_review | confidence | n |
| --- | --- | --- | --- |
| no_change_manual | TRUE | none | 132 |
| add_missing_null | FALSE | high | 113 |
| normalize_false_to_false_category | FALSE | high |  51 |
| normalize_false_to_no_survey | FALSE | high |  48 |
| normalize_false_to_no_error | FALSE | high |  47 |
| normalize_false_to_not_original | FALSE | high |  47 |
| blank_to_null | FALSE | high |  32 |
| text_to_null_manual | TRUE | none |  32 |
| string_list_to_semicolon_string | FALSE | high |  30 |
| normalize_alias | FALSE | high |  18 |
| normalize_true_to_single_country | FALSE | high |  15 |
| drop_extra_field | FALSE | high |  11 |
| add_missing_null | TRUE | none |  10 |
| normalize_false_with_multiple_countries | FALSE | medium |   8 |
| normalize_null_to_no_error | FALSE | medium |   8 |
| normalize_true_to_single_region | FALSE | high |   6 |
| empty_list_to_null | FALSE | high |   2 |

## Reconciliação

| reconciliation_status | n |
| --- | --- |
| resolved_by_normalization | 404 |
| remaining_manual_review | 171 |

## Arquivos Gerados

- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/classifications_normalized`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/classifications_llm_normalized.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/classification_normalization_log.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/classification_normalization_reconciliation.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/classification_validation_issues_normalized.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/classification_validation_summary_normalized.md`
