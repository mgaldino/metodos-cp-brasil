# Validação das Decisões Manuais

Gerado em 2026-06-03 00:01:13 -03

## Fonte

- Planilha Google Sheets: https://docs.google.com/spreadsheets/d/1DZgnyu9StUDLE0szvkWFutqA1hI-_QqOlqvRO5dBH4k/edit?usp=sharing
- Endpoint CSV usado para o snapshot: https://docs.google.com/spreadsheets/d/1DZgnyu9StUDLE0szvkWFutqA1hI-_QqOlqvRO5dBH4k/gviz/tq?tqx=out:csv&sheet=manual_review_queue
- Snapshot salvo em `data/processed/manual_review_decisions_google_sheet.csv`.
- A validação compara chaves `pid + field + file + issue_rule + action`, não posição de linha.

## Status

Fila principal operacionalmente completa: todas as chaves foram pareadas e todos os itens não excluídos estão `done`.

Observação: a validação estrita ainda registra dois placeholders de `main_variable_relationship` e um mismatch não bloqueante em `allowed_values` editado na planilha.

## Snapshot

| item | value |
| --- | --- |
| linhas no snapshot da planilha | 174 |
| linhas manual_review=TRUE no log | 174 |
| linhas na fila principal local | 135 |
| linhas dispensadas por exclusão de periódico | 29 |
| linhas dispensadas por exclusão de artigo | 10 |
| chaves duplicadas no snapshot | 0 |
| linhas do snapshot sem par local | 0 |
| linhas locais sem par no snapshot | 0 |
| linhas do log manual sem par no snapshot | 0 |
| linhas principais marcadas done | 135 |
| linhas principais ainda pending | 0 |
| linhas pending dispensadas por exclusão | 18 |
| valores done fora do codebook local na análise principal | 0 |
| placeholders structured_json_required | 2 |
| mismatches de allowed_values na planilha | 1 |

## Status por Escopo

| queue_source | excluded_by_journal | excluded_by_article | excluded_from_analysis | decision_status | n |
| --- | --- | --- | --- | --- | --- |
| excluded_article_queue | FALSE | TRUE | TRUE | done | 10 |
| excluded_journal_queue | TRUE | FALSE | TRUE | done | 11 |
| excluded_journal_queue | TRUE | FALSE | TRUE | pending | 18 |
| main_queue | FALSE | FALSE | FALSE | done | 135 |

## Pendências Dispensadas por Exclusão

| queue_source | journal_title | issn | exclusion_reason | n |
| --- | --- | --- | --- | --- |
| excluded_journal_queue | Brazilian Journal of Political Economy | 0101-3157 | out_of_scope_economics | 9 |
| excluded_journal_queue | Civitas - Revista de Ciências Sociais | 1519-6089 | out_of_scope_social_sciences | 5 |
| excluded_journal_queue | Brazilian Journal of Political Economy | 1809-4538 | out_of_scope_economics | 4 |

## Itens Dispensados por Exclusão de Artigo

| pid | title | journal_title | exclusion_reason | n |
| --- | --- | --- | --- | --- |
| S0102-85292023000200904 | Novas direções para a Análise de Política Externa': reconfigurando o campo | Contexto Internacional | non_research_editorial | 4 |
| S0011-52582022000100401 | Por uma Abordagem Interdisciplinar, Estrutural e Interseccional de Usuárias(os) do Estado: Comentário Crítico ao Artigo &#8220;Categorizando Usuários &#8216;Fáceis&#8217; e &#8216;Difíceis&#8217;...&#8221; de Gabriela Spanghero Lotta e Roberto Rocha Coelho Pires | Dados | non_independent_article_commentary | 3 |
| S0011-52582008000200002 | Ruth Corrêa Leite Cardoso | Dados | non_research_obituary | 3 |

## Itens com Ressalva de Aplicação

| pid | field | journal_title | decision_value | local_allowed_values | decision_note | validation_issue |
| --- | --- | --- | --- | --- | --- | --- |
| S1981-38212007000100070 | main_variable_relationship | Brazilian Political Science Review | structured_json_required | <NULL> \| structured_json_required | Regreessão | structured_json_required_placeholder |
| S1981-38212013000200003 | main_variable_relationship | Brazilian Political Science Review | structured_json_required | <NULL> \| structured_json_required | Regressão logística com múltiplas relações IV/DV interpretadas substantivamente e com significância; requer codificação estruturada posterior. Importante, link leva para página e precisa clicar em pdf para abrir o paper. Caso diferente dos outros links. É um problema de textos mais antigos da Brazilian Political Sciencie Review especitifcamente | structured_json_required_placeholder |

## Interpretação

- `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` estão documentados em `data/processed/excluded_journals.csv` e suas pendências restantes aparecem apenas como dispensadas por periódico.
- Obituário, editorial, comentário crítico, errata e nota fora de escopo estão documentados em `data/processed/excluded_articles.csv` e ficam fora da análise principal.
- As decisões da fila principal estão completas, mas nem todas são diretamente aplicáveis ao schema atual sem regra adicional.
- Antes de regerar `classifications_llm.csv` final, substituir `structured_json_required` por JSON substantivo ou `<NULL>`.

## Arquivos Gerados

- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_decisions_validated.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_decisions_issues.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/manual_review_decisions_validation_summary.md`
