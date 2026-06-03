# Validação das Classificacoes_Finais_Pos_Revisao_Manual

Gerado em 2026-06-03 01:06:31 -03

## Snapshot

| item | value |
| --- | --- |
| rótulo da validação | Classificacoes_Finais_Pos_Revisao_Manual |
| diretório de classificações | /Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/classifications_final |
| CSV de classificações | /Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/classifications_llm.csv |
| artigos no corpus | 8400 |
| periódicos no corpus | 15 |
| anos no corpus | 2005-2025 |
| artigos na amostra | 208 |
| linhas na planilha de validação | 208 |
| JSONs de classificação | 208 |
| linhas no CSV consolidado | 208 |
| issues totais | 9 |
| errors | 0 |
| warnings | 9 |

## Issues por Severidade

| severity | n |
| --- | --- |
| WARN | 9 |

## Principais Regras com Issues

| severity | scope | rule | n |
| --- | --- | --- | --- |
| WARN | corpus | non_research_article_document_type | 9 |

## Próximos Passos

1. Não há erros de schema nesta validação.
2. Revisar eventuais `WARN` documentados antes de análises substantivas, sem bloquear o uso do CSV validado.
3. Usar o CSV validado correspondente a esta execução para a próxima etapa documentada do pipeline.

## Arquivos Gerados

- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/classification_validation_issues_final.csv`
- `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/classification_validation_summary_final.md`
