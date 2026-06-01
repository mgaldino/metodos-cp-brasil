# Fila de Revisão Manual

Gerado em 2026-06-01 16:29:06 -03

## Como usar

1. Abra `quality_reports/manual_review_queue.csv`.
2. Para cada linha, preencha `decision_value` com um valor permitido em `allowed_values`.
3. Marque `decision_status` como `done` quando decidir.
4. Use `decision_note` para registrar a justificativa quando houver ambiguidade.
5. Depois, rode um script de aplicação das decisões para atualizar os JSONs candidatos finais.

## Pendências por Campo

| field | n |
| --- | --- |
| effort_to_explore_mechanisms | 50 |
| general_goal_of_analysis | 32 |
| method_status | 26 |
| single_region | 21 |
| single_country_study | 14 |
| evidence_type |  8 |
| error_in_raw_text |  6 |
| main_variable_relationship |  6 |
| paper_uses_survey_data |  5 |
| uses_original_dataset |  5 |
| is_empirical_quant_paper |  1 |

## Artigos por Número de Pendências

| n_pending | n_articles |
| --- | --- |
| 8 | 1 |
| 6 | 1 |
| 5 | 6 |
| 4 | 17 |
| 3 | 11 |
| 2 | 8 |
| 1 | 13 |

## Arquivos Gerados

- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_queue.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_queue_by_article.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_codebook.md`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_queue_summary.md`
