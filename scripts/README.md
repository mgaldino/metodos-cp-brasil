# Scripts

## Objetivo Atual do Pipeline

O pipeline deve avançar da amostra de validação para a classificação do corpus completo elegível. Os 208 artigos já classificados, reduzidos a 175 após exclusões, servem para validação/piloto do schema e dos scripts; não são a base final de análise substantiva do paper.

`Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` devem ficar fora da análise principal, embora seus registros possam permanecer preservados no corpus bruto e em artefatos rastreáveis.

## Coleta e corpus

- `01_discover_journals.py`: consulta a API ArticleMeta do SciELO, lista periódicos e aplica filtros de área.
- `02_collect_articles.py`: coleta metadados e XMLs dos artigos, preservando respostas brutas e logs.
- `03_sample_articles.R`: gera amostra estratificada para validação manual.
- `13_recover_fulltext_gold.py`: recupera body integral dos 175 artigos gold/piloto, por PID, usando ArticleMeta HTML, seletores SciELO `Text`/`Texto`, XML real com `<body>` e PDF como fallback. Preserva brutos em `data/raw/fulltext_gold/` e só escreve `data/processed/fulltext_gold/article_texts_gold.csv` quando fecha 175/175.

## Classificação

- `04_classify_articles.py`: classifica a amostra usando a API Claude e consolida JSONs individuais em CSV.
- `classify_batch.py`: classifica subconjuntos de PIDs definidos em arquivos `batch_*.txt`.
- `classify_writing_codex.py`: classifica características de escrita via Codex CLI.
- `10_prepare_full_classification_pilot.R`: cria o manifest rastreável dos 175 artigos gold/piloto elegíveis, com XML fonte, hashes SHA-256 e versões dos prompts dos três subagentes.
- `11_validate_full_classification_pilot_outputs.R`: valida os JSONs produzidos pelos três subagentes Codex locais e consolida uma base CSV por agente.
- `12_compare_full_classification_pilot.R`: compara os três agentes campo a campo, gera consenso provisório, conflitos, fila de adjudicação e comparação contra o gold/piloto.

O piloto triplo em `data/processed/full_classification_pilot/` não usa `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` nem chamadas de API. As classificações substantivas são produzidas por três subagentes Codex locais independentes.

## Validação e normalização

- `05_validate_classifications.R`: valida corpus, amostra, JSONs de classificação e CSV consolidado.
- `06_normalize_classifications.R`: gera uma versão candidata normalizada dos JSONs/CSV sem sobrescrever os originais, com log auditável e reconciliação das pendências manuais.
- `07_prepare_manual_review_queue.R`: prepara a fila de revisão manual e separa pendências dispensadas por regras de exclusão de periódico ou artigo.
- `08_validate_manual_review_decisions.R`: valida o snapshot da planilha Google Sheets com decisões manuais contra a fila local e checa overrides estruturados pendentes, produzindo relatório e CSVs auditáveis em `quality_reports/`.
- `09_apply_manual_review_decisions.R`: aplica `quality_reports/manual_review_decisions_validated.csv` e `data/processed/manual_review_relationship_overrides.json` aos JSONs normalizados da amostra, gera `data/processed/classifications_final/`, atualiza o CSV canônico da amostra em `data/processed/classifications_llm.csv`, preserva `data/processed/classifications_llm_pre_manual_review.csv`, cria `data/processed/classifications_llm_main_analysis.csv` com os 175 registros elegíveis da amostra e exige zero erros de schema via `05_validate_classifications.R`.

Estado em 2026-06-03: a etapa pós-revisão manual da amostra está fechada. A validação final registrou 208 JSONs, 208 linhas no CSV canônico da amostra, 175 linhas elegíveis pós-exclusões, 0 erros e 9 avisos não bloqueantes de `non_research_article_document_type`.

Fonte canônica de body para os 175 gold/piloto: `data/processed/fulltext_gold/article_texts_gold.csv`, gerado por `scripts/13_recover_fulltext_gold.py` e validado por `scripts/14_validate_fulltext_gold.R`. Os XMLs antigos em `data/raw/articles_fulltext/` e `data/processed/sample_xmls/` não continham `<body>` real e não devem ser usados como substituto de texto integral.

Regra operacional de exclusões: `Brazilian Journal of Political Economy`, `Civitas - Revista de Ciências Sociais` e os artigos em `data/processed/excluded_articles.csv` ficam fora da análise principal, mas permanecem preservados no corpus e nos artefatos rastreáveis.

Próximo passo documentado: adaptar/rodar a classificação em escala para o corpus completo elegível e gerar uma nova base analítica final, com exclusões aplicadas explicitamente.

- `14_validate_fulltext_gold.R`: valida que os 175 PIDs gold/piloto têm body integral recuperado, PIDs únicos, proveniência obrigatória, texto maior que abstract, corpo não vazio e não composto por referências. Gera `quality_reports/fulltext_gold_recovery_report.md` e `quality_reports/fulltext_gold_inventory.csv`.
- `15_write_fulltext_scaling_plan.R`: escreve `quality_reports/fulltext_scaling_plan.md` para escalar a extração ao corpus elegível completo. Exige antes inventário gold validado 175/175 `PASS`.

## Benchmark e auditoria

- `build_benchmark.py`: processa PDFs internacionais e calcula benchmarks de readability/style.
- `readability_audit.py`: calcula métricas de readability e estilo para `.Rmd`, `.tex` ou `.pdf`.

## Testes

```bash
python3 -m pytest scripts
```

Estado em 2026-06-01: 59 testes passaram; houve apenas um aviso de compatibilidade entre `requests` e `urllib3`.
