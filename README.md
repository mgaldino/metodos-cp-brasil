# Revolução da Credibilidade na Ciência Política Brasileira

Este repositório replica e expande Torreblanca et al. (2026), "The Credibility Revolution in Political Science", para periódicos brasileiros de Ciência Política, Relações Internacionais e Administração Pública indexados no SciELO.

## Estado Atual

- Corpus coletado: `data/raw/articles_2005_2025.csv`, com 8.400 artigos, 15 periódicos e anos de publicação entre 2005 e 2025.
- Amostra de validação: `data/processed/sample_validation.csv`, com 208 artigos.
- Classificações LLM finais pós-revisão manual: `data/processed/classifications_llm.csv`, com 208 artigos classificados e schema validado; os JSONs finais estão em `data/processed/classifications_final/`.
- Base operacional atual da amostra classificada: `data/processed/classifications_llm_main_analysis.csv`, com 175 artigos após aplicar os ledgers de exclusão. Este arquivo é a amostra validada pós-exclusões, não a base final do paper.
- Texto integral dos 175 artigos gold/piloto: `data/processed/fulltext_gold/article_texts_gold.csv`, validado em 2026-06-03 com 175/175 bodies recuperados. Esta é a fonte canônica de body para o piloto/gold; não use abstract, metadados, keywords, referências ou os XMLs antigos como substituto de body.
- Piloto de classificação tripla independente: `data/processed/full_classification_pilot/`, usando subagentes Codex locais e os 175 artigos elegíveis apenas como gold/piloto.
- Benchmarks internacionais de readability: `data/processed/benchmark_cp.csv` e `data/processed/benchmark_ir.csv`.
- Validação final das classificações: `Rscript --vanilla scripts/09_apply_manual_review_decisions.R` gerou zero erros de schema em 2026-06-03; o relatório está em `quality_reports/classification_validation_summary_final.md`.
- Testes locais: `python3 -m pytest scripts` passou com 59 testes em 2026-06-01.

## Direção Analítica Atual

- O objetivo do paper é expandir a classificação para o corpus completo elegível, não analisar apenas a amostra de 175 artigos.
- `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` não entrarão na análise principal.
- Os registros desses periódicos podem permanecer preservados nos dados brutos e artefatos rastreáveis, mas devem ser excluídos de qualquer base analítica substantiva.
- A amostra de 208 artigos, reduzida a 175 após exclusões, deve ser tratada como etapa de validação/piloto para calibrar e auditar a classificação do corpus completo elegível.
- A base final de análise substantiva ainda precisa ser gerada depois da classificação do corpus completo elegível.

## Estrutura

```text
metodos_CP/
├── CLAUDE.md                         # Memória substantiva do projeto
├── README.md                         # Documentação principal
├── references.bib                    # Bibliografia do paper
├── metodos_CP.Rproj                  # Projeto RStudio
├── paper/                            # Manuscrito e apêndice
├── scripts/                          # Coleta, amostragem, classificação e auditoria
├── data/
│   ├── raw/                          # Dados brutos e metadados de execução
│   └── processed/                    # Dados processados e classificações
├── output/
│   ├── figures/
│   ├── tables/
│   └── models/
├── quality_reports/plans/            # Planos antes de novas análises
├── replication/                      # Materiais finais de replicação
├── references_pdfs/                  # PDFs de referências
├── explorations/                     # Explorações não canônicas
└── notes/                            # Notas de pesquisa
```

## Pipeline

1. Descobrir periódicos SciELO:

```bash
python3 scripts/01_discover_journals.py
```

2. Coletar artigos:

```bash
PUB_YEAR_FROM=2005 PUB_YEAR_UNTIL=2025 python3 scripts/02_collect_articles.py
```

3. Gerar amostra de validação:

```bash
Rscript --vanilla scripts/03_sample_articles.R
```

4. Testar classificação tripla independente nos 175 artigos gold/piloto:

```bash
Rscript --vanilla scripts/10_prepare_full_classification_pilot.R
# Em seguida, três subagentes Codex locais classificam os mesmos PIDs em:
# data/processed/full_classification_pilot/agent_a/
# data/processed/full_classification_pilot/agent_b/
# data/processed/full_classification_pilot/agent_c/
Rscript --vanilla scripts/11_validate_full_classification_pilot_outputs.R
Rscript --vanilla scripts/12_compare_full_classification_pilot.R
```

Este piloto não usa `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` nem runner de API. As classificações são produzidas por subagentes Codex independentes, e `classifications_llm_main_analysis.csv` é usado apenas como gold/piloto para seleção e avaliação.

Limitação documentada em 2026-06-03: os 175 XMLs locais usados como entrada não continham `<body>` e eram idênticos entre `data/processed/sample_xmls/` e `data/raw/articles_fulltext/`. O body integral dos 175 gold/piloto foi recuperado posteriormente e a fonte canônica passou a ser `data/processed/fulltext_gold/article_texts_gold.csv`.

```bash
python3 scripts/13_recover_fulltext_gold.py --offline
Rscript --vanilla scripts/14_validate_fulltext_gold.R
Rscript --vanilla scripts/15_write_fulltext_scaling_plan.R
```

Os brutos usados estão preservados em `data/raw/fulltext_gold/`; a validação e o plano de escala estão em `quality_reports/fulltext_gold_recovery_report.md`, `quality_reports/fulltext_gold_inventory.csv` e `quality_reports/fulltext_scaling_plan.md`.

5. Classificar artigos via LLM/API, quando houver decisão posterior de escala:

```bash
ANTHROPIC_API_KEY=... python3 scripts/04_classify_articles.py
```

Estado atual: este script foi usado para a amostra de validação. A escala para o corpus completo elegível só deve ocorrer depois do relatório do piloto triplo, mantendo fora da análise os periódicos excluídos.

6. Validar, normalizar e fechar classificações:

```bash
Rscript --vanilla scripts/05_validate_classifications.R
Rscript --vanilla scripts/06_normalize_classifications.R
Rscript --vanilla scripts/07_prepare_manual_review_queue.R
Rscript --vanilla scripts/08_validate_manual_review_decisions.R
Rscript --vanilla scripts/09_apply_manual_review_decisions.R
```

7. Construir benchmarks internacionais:

```bash
python3 scripts/build_benchmark.py --field both
```

8. Rodar testes:

```bash
python3 -m pytest scripts
```

## Inclusão e Exclusão

- `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` ficam fora da análise principal por decisão de escopo documentada em `data/processed/excluded_journals.csv`.
- Os artigos listados em `data/processed/excluded_articles.csv` ficam fora da análise principal, mas permanecem preservados no corpus.
- `data/processed/classifications_llm.csv` mantém os 208 registros da amostra para rastreabilidade.
- `data/processed/classifications_llm_main_analysis.csv` contém os 175 registros elegíveis da amostra classificada. Use este arquivo para validação, auditoria, desenvolvimento de tabelas e testes do pipeline; não o trate como base final de inferência substantiva do paper.
- `data/processed/classifications_llm_pre_manual_review.csv` preserva o CSV consolidado antes da aplicação das decisões manuais.

## Convenções

- Use Python para coleta online, extração de texto, PDF, LLM e processamento textual.
- Use R para análise estatística, validação de dados, tabelas e figuras.
- Preserve arquivos brutos e extraídos em `data/raw/`.
- Salve outputs derivados em `data/processed/` ou `output/`.
- Para os 175 gold/piloto, use `data/processed/fulltext_gold/article_texts_gold.csv` como fonte canônica de body. `has_fulltext_xml=1` e arquivos em `data/raw/articles_fulltext/` não garantem texto integral utilizável.
- Antes de análises substantivas novas, registre um plano em `quality_reports/plans/`.
- Em R, use `dplyr::select()` explicitamente ao selecionar colunas.
- Figuras e tabelas do paper devem ser numeradas e ter caption.

## Pontos Pendentes

- Expandir a recuperação de body e a classificação para o corpus completo elegível, excluindo `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` da análise principal antes da extração. O plano operacional está em `quality_reports/fulltext_scaling_plan.md`.
- Consolidar um script mestre em R para gerar tabelas e figuras finais a partir da base completa classificada elegível, com os ledgers de exclusão aplicados explicitamente.
- Escrever o manuscrito em `paper/paper.Rmd`.
- Documentar a versão final do corpus e os critérios de inclusão/exclusão no apêndice.
- Preparar um pacote de replicação em `replication/`.
