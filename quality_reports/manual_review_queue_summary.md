# Fila de Revisão Manual

Gerado em 2026-06-02 22:10:14 -03

## Como usar

1. Abra `quality_reports/manual_review_queue.csv`.
2. Leia `title`, `abstract_pt`, `abstract_en` e `brief_justification` para decidir.
3. Para cada linha, preencha `decision_value` com um valor permitido em `allowed_values`.
4. Marque `decision_status` como `done` quando decidir.
5. Use `decision_note` para registrar a justificativa quando houver ambiguidade.
6. Depois, rode um script de aplicação das decisões para atualizar os JSONs candidatos finais.

## Pendências por Campo

| field | n |
| --- | --- |
| effort_to_explore_mechanisms | 44 |
| general_goal_of_analysis | 28 |
| method_status | 26 |
| single_region | 17 |
| single_country_study | 13 |
| evidence_type |  8 |
| main_variable_relationship |  5 |
| paper_uses_survey_data |  5 |
| uses_original_dataset |  5 |
| error_in_raw_text |  1 |
| is_empirical_quant_paper |  1 |

## Pendências dispensadas por exclusão de periódico

| journal_title | issn | exclusion_reason | n |
| --- | --- | --- | --- |
| Brazilian Journal of Political Economy | 0101-3157 | out_of_scope_economics | 15 |
| Brazilian Journal of Political Economy | 1809-4538 | out_of_scope_economics |  6 |

## Artigos por Número de Pendências

| n_pending | n_articles |
| --- | --- |
| 8 | 1 |
| 6 | 1 |
| 5 | 6 |
| 4 | 15 |
| 3 | 10 |
| 2 | 6 |
| 1 | 7 |

## Arquivos Gerados

- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_queue.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_queue_excluded_journals.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_queue_by_article.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_codebook.md`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_queue_summary.md`
