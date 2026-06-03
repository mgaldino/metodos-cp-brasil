# Scripts

## Objetivo Atual do Pipeline

O pipeline deve avançar da amostra de validação para a classificação do corpus completo elegível. Os 208 artigos já classificados, reduzidos a 175 após exclusões, servem para validação/piloto do schema e dos scripts; não são a base final de análise substantiva do paper.

`Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` devem ficar fora da análise principal, embora seus registros possam permanecer preservados no corpus bruto e em artefatos rastreáveis.

## Coleta e corpus

- `01_discover_journals.py`: consulta a API ArticleMeta do SciELO, lista periódicos e aplica filtros de área.
- `02_collect_articles.py`: coleta metadados e XMLs dos artigos, preservando respostas brutas e logs.
- `03_sample_articles.R`: gera amostra estratificada para validação manual.

## Classificação

- `04_classify_articles.py`: classifica a amostra usando a API Claude e consolida JSONs individuais em CSV.
- `classify_batch.py`: classifica subconjuntos de PIDs definidos em arquivos `batch_*.txt`.
- `classify_writing_codex.py`: classifica características de escrita via Codex CLI.

## Validação e normalização

- `05_validate_classifications.R`: valida corpus, amostra, JSONs de classificação e CSV consolidado.
- `06_normalize_classifications.R`: gera uma versão candidata normalizada dos JSONs/CSV sem sobrescrever os originais, com log auditável e reconciliação das pendências manuais.
- `07_prepare_manual_review_queue.R`: prepara a fila de revisão manual e separa pendências dispensadas por regras de exclusão de periódico ou artigo.
- `08_validate_manual_review_decisions.R`: valida o snapshot da planilha Google Sheets com decisões manuais contra a fila local e checa overrides estruturados pendentes, produzindo relatório e CSVs auditáveis em `quality_reports/`.
- `09_apply_manual_review_decisions.R`: aplica `quality_reports/manual_review_decisions_validated.csv` e `data/processed/manual_review_relationship_overrides.json` aos JSONs normalizados da amostra, gera `data/processed/classifications_final/`, atualiza o CSV canônico da amostra em `data/processed/classifications_llm.csv`, preserva `data/processed/classifications_llm_pre_manual_review.csv`, cria `data/processed/classifications_llm_main_analysis.csv` com os 175 registros elegíveis da amostra e exige zero erros de schema via `05_validate_classifications.R`.

Estado em 2026-06-03: a etapa pós-revisão manual da amostra está fechada. A validação final registrou 208 JSONs, 208 linhas no CSV canônico da amostra, 175 linhas elegíveis pós-exclusões, 0 erros e 9 avisos não bloqueantes de `non_research_article_document_type`.

Regra operacional de exclusões: `Brazilian Journal of Political Economy`, `Civitas - Revista de Ciências Sociais` e os artigos em `data/processed/excluded_articles.csv` ficam fora da análise principal, mas permanecem preservados no corpus e nos artefatos rastreáveis.

Próximo passo documentado: adaptar/rodar a classificação em escala para o corpus completo elegível e gerar uma nova base analítica final, com exclusões aplicadas explicitamente.

## Benchmark e auditoria

- `build_benchmark.py`: processa PDFs internacionais e calcula benchmarks de readability/style.
- `readability_audit.py`: calcula métricas de readability e estilo para `.Rmd`, `.tex` ou `.pdf`.

## Testes

```bash
python3 -m pytest scripts
```

Estado em 2026-06-01: 59 testes passaram; houve apenas um aviso de compatibilidade entre `requests` e `urllib3`.
