# Fila de Revisão Manual

Gerado por `scripts/07_prepare_manual_review_queue.R`.

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
| effort_to_explore_mechanisms | 38 |
| general_goal_of_analysis | 24 |
| method_status | 23 |
| single_region | 16 |
| single_country_study | 11 |
| evidence_type | 7 |
| main_variable_relationship | 5 |
| paper_uses_survey_data | 5 |
| uses_original_dataset | 4 |
| error_in_raw_text | 1 |
| is_empirical_quant_paper | 1 |

## Pendências dispensadas por exclusão de periódico

| journal_title | issn | exclusion_reason | n |
| --- | --- | --- | --- |
| Brazilian Journal of Political Economy | 0101-3157 | out_of_scope_economics | 15 |
| Brazilian Journal of Political Economy | 1809-4538 | out_of_scope_economics | 6 |
| Civitas - Revista de Ciências Sociais | 1519-6089 | out_of_scope_social_sciences | 6 |
| Civitas - Revista de Ciências Sociais | 1984-7289 | out_of_scope_social_sciences | 2 |

## Pendências dispensadas por exclusão de artigo

Nota: esta seção e `quality_reports/manual_review_queue_excluded_articles.csv` mostram apenas pendências de revisão dispensadas por exclusão de artigo. O ledger completo de artigos excluídos é `data/processed/excluded_articles.csv`.

| pid | title | journal_title | exclusion_reason | n |
| --- | --- | --- | --- | --- |
| S0102-85292023000200904 | 'Novas direções para a Análise de Política Externa': reconfigurando o campo | Contexto Internacional | non_research_editorial | 4 |
| S0011-52582022000100401 | Por uma Abordagem Interdisciplinar, Estrutural e Interseccional de Usuárias(os) do Estado: Comentário Crítico ao Artigo &#8220;Categorizando Usuários &#8216;Fáceis&#8217; e &#8216;Difíceis&#8217;...&#8221; de Gabriela Spanghero Lotta e Roberto Rocha Coelho Pires | Dados | non_independent_article_commentary | 3 |
| S0011-52582008000200002 | Ruth Corrêa Leite Cardoso | Dados | non_research_obituary | 3 |

## Artigos por Número de Pendências

| n_pending | n_articles |
| --- | --- |
| 8 | 1 |
| 6 | 1 |
| 5 | 6 |
| 4 | 14 |
| 3 | 7 |
| 2 | 4 |
| 1 | 6 |

## Arquivos Gerados

- `quality_reports/manual_review_queue.csv`
- `quality_reports/manual_review_queue_excluded_journals.csv`
- `quality_reports/manual_review_queue_excluded_articles.csv`
- `quality_reports/manual_review_queue_by_article.csv`
- `quality_reports/manual_review_codebook.md`
- `quality_reports/manual_review_queue_summary.md`
