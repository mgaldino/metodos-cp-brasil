# Plano do Repositório — 2026-06-01

## Diagnóstico

O repositório já tem coleta substantiva, amostra de validação, classificações LLM, benchmarks internacionais e testes unitários para os scripts de readability/benchmark. A estrutura, porém, ainda estava mais próxima de um projeto de coleta do que de um repositório de paper: faltavam `README.md`, `paper/`, `references.bib`, projeto RStudio e diretórios padronizados para outputs finais.

## Próximos Passos

1. Escrever scripts R de análise em arquivos separados e criar um script mestre para tabelas e figuras finais usando `data/processed/classifications_llm_main_analysis.csv` ou aplicando explicitamente os ledgers de exclusão.
2. Produzir estatísticas descritivas do corpus: artigos por ano, periódico, subfield, tipo de evidência, status do método e desenho causal.
3. Confrontar resultados brasileiros com benchmarks internacionais, mantendo separada a camada comparável a Torreblanca et al. e a camada expandida para o Brasil.
4. Escrever `paper/paper.Rmd` e `paper/appendix.Rmd`, com tabelas e figuras numeradas e captions.
5. Preparar `replication/` com dados processados, scripts necessários, metadados e instruções de execução.

## Risco Imediato

O CSV consolidado de classificações mistura saídas antigas e novas. Antes de qualquer inferência substantiva, é necessário validar categorias e tipos de campos. Em checagem rápida, `error_in_raw_text` tem valores fora do schema atual (`False` e vazio), o que indica necessidade de migração ou reclassificação parcial.

## Atualização — 2026-06-03

- A normalização candidata foi concluída em `data/processed/classifications_llm_normalized.csv`, com log auditável em `quality_reports/classification_normalization_log.csv`.
- A fila `manual_review=TRUE` foi preparada em `quality_reports/manual_review_queue.csv`; pendências de `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` foram dispensadas por regra de exclusão de periódico, documentada em `data/processed/excluded_journals.csv`.
- Obituário, editorial, comentário crítico, errata e nota fora de escopo foram documentados em `data/processed/excluded_articles.csv` e ficam fora da análise principal, preservados no corpus.
- As decisões manuais da planilha Google Sheets foram preservadas em `data/processed/manual_review_decisions_google_sheet.csv` e validadas por `scripts/08_validate_manual_review_decisions.R`.
- Resultado da validação: 135/135 itens da fila principal estão `done`; 18 itens `pending` pertencem apenas a periódicos excluídos; 10 itens estão dispensados por exclusão de artigo.
- Os 2 placeholders `structured_json_required` em `main_variable_relationship` foram resolvidos por overrides estruturados em `data/processed/manual_review_relationship_overrides.json`.
- `scripts/09_apply_manual_review_decisions.R` aplicou as decisões manuais aos JSONs normalizados, gerou `data/processed/classifications_final/`, atualizou `data/processed/classifications_llm.csv` e preservou `data/processed/classifications_llm_pre_manual_review.csv`.
- A validação final em `quality_reports/classification_validation_summary_final.md` registrou 208 JSONs finais, 208 linhas no CSV canônico, 0 erros de schema e 9 avisos não bloqueantes de `non_research_article_document_type`.
- A base de análise principal pós-exclusões está em `data/processed/classifications_llm_main_analysis.csv`, com 175 artigos.

## Regra Operacional Atual de Exclusões

- `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` ficam fora da análise principal por regra documentada em `data/processed/excluded_journals.csv`.
- Os artigos listados em `data/processed/excluded_articles.csv` ficam fora da análise principal.
- Todos esses registros permanecem preservados no corpus e nos artefatos rastreáveis; análises substantivas devem usar `data/processed/classifications_llm_main_analysis.csv` ou aplicar explicitamente os ledgers de exclusão.
