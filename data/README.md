# Dados

## Objetivo Analítico dos Dados

O objetivo do repo é classificar o corpus completo elegível de artigos SciELO 2005-2025. As classificações existentes de 208 artigos, reduzidas a 175 registros elegíveis após exclusões, são uma amostra de validação/piloto para calibrar e auditar o schema. Elas não são a base final de análise substantiva do paper.

`Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` não entram na análise principal. Os registros desses periódicos podem permanecer preservados nos dados brutos e artefatos rastreáveis, mas devem ser excluídos de qualquer base analítica substantiva.

## `data/raw/`

Arquivos brutos, metadados de execução e materiais coletados de fontes externas.

Arquivos centrais:

- `journals_list.csv`: periódicos SciELO incluídos no corpus.
- `journals_rejected.csv`: periódicos avaliados e rejeitados.
- `articles_2005_2025.csv`: metadados consolidados dos artigos coletados.
- `run_metadata*.json`: parâmetros e timestamps das coletas.
- `papers_internacionais/`: PDFs usados para benchmarks externos.

## `data/processed/`

Arquivos derivados usados para validação, classificação e análise.

Arquivos centrais:

- `sample_validation.csv`: amostra de validação gerada por `scripts/03_sample_articles.R`.
- `sample_validation_sheet.csv`: planilha ampliada para classificação.
- `classifications/`: um JSON por artigo classificado.
- `classifications_llm.csv`: CSV consolidado das classificações da amostra de validação.
- `classifications_llm_main_analysis.csv`: 175 registros elegíveis da amostra classificada, após excluir periódicos e artigos fora do escopo. Use para validação, auditoria e desenvolvimento do pipeline; não use como base final de inferência substantiva.
- `excluded_journals.csv`: regras de exclusão da análise principal por periódico/ISSN. Em 2026-06-02, `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` foram marcados como fora do escopo principal, preservando os registros no corpus.
- `excluded_articles.csv`: regras de exclusão da análise principal por artigo. Obituário, editorial, comentário crítico, errata e nota fora de escopo ficam preservados no corpus, mas não entram nas análises do paper.
- `manual_review_decisions_google_sheet.csv`: snapshot CSV da planilha Google Sheets com as decisões manuais da fila `manual_review=TRUE`, acessado em 2026-06-02 -03.
- `manual_review_relationship_overrides.json`: decisões estruturadas para pendências `main_variable_relationship` que exigiam JSON manual.
- `benchmark_cp.csv` e `benchmark_ir.csv`: métricas por paper para benchmarks internacionais.
- `benchmark_cp_stats.json` e `benchmark_ir_stats.json`: estatísticas agregadas dos benchmarks.

## Regras

- Não sobrescrever dados brutos sem preservar versão anterior ou metadados de execução.
- Toda coleta nova deve registrar fonte, data de acesso e parâmetros.
- Validações de dados devem checar datas, valores incompatíveis e categorias fora do schema esperado.
