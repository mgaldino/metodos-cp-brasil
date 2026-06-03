# Revolução da Credibilidade na Ciência Política Brasileira

Este repositório replica e expande Torreblanca et al. (2026), "The Credibility Revolution in Political Science", para periódicos brasileiros de Ciência Política, Relações Internacionais e Administração Pública indexados no SciELO.

## Estado Atual

- Corpus coletado: `data/raw/articles_2005_2025.csv`, com 8.400 artigos, 15 periódicos e anos de publicação entre 2005 e 2025.
- Amostra de validação: `data/processed/sample_validation.csv`, com 208 artigos.
- Classificações LLM finais pós-revisão manual: `data/processed/classifications_llm.csv`, com 208 artigos classificados e schema validado; os JSONs finais estão em `data/processed/classifications_final/`.
- Base operacional da análise principal: `data/processed/classifications_llm_main_analysis.csv`, com 175 artigos após aplicar os ledgers de exclusão.
- Benchmarks internacionais de readability: `data/processed/benchmark_cp.csv` e `data/processed/benchmark_ir.csv`.
- Validação final das classificações: `Rscript --vanilla scripts/09_apply_manual_review_decisions.R` gerou zero erros de schema em 2026-06-03; o relatório está em `quality_reports/classification_validation_summary_final.md`.
- Testes locais: `python3 -m pytest scripts` passou com 59 testes em 2026-06-01.

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

4. Classificar artigos via LLM:

```bash
ANTHROPIC_API_KEY=... python3 scripts/04_classify_articles.py
```

5. Validar, normalizar e fechar classificações:

```bash
Rscript --vanilla scripts/05_validate_classifications.R
Rscript --vanilla scripts/06_normalize_classifications.R
Rscript --vanilla scripts/07_prepare_manual_review_queue.R
Rscript --vanilla scripts/08_validate_manual_review_decisions.R
Rscript --vanilla scripts/09_apply_manual_review_decisions.R
```

6. Construir benchmarks internacionais:

```bash
python3 scripts/build_benchmark.py --field both
```

7. Rodar testes:

```bash
python3 -m pytest scripts
```

## Inclusão e Exclusão

- `Brazilian Journal of Political Economy` e `Civitas - Revista de Ciências Sociais` ficam fora da análise principal por decisão de escopo documentada em `data/processed/excluded_journals.csv`.
- Os artigos listados em `data/processed/excluded_articles.csv` ficam fora da análise principal, mas permanecem preservados no corpus.
- `data/processed/classifications_llm.csv` mantém os 208 registros da amostra para rastreabilidade. Para análises substantivas, use `data/processed/classifications_llm_main_analysis.csv` ou aplique explicitamente os ledgers de exclusão.
- `data/processed/classifications_llm_pre_manual_review.csv` preserva o CSV consolidado antes da aplicação das decisões manuais.

## Convenções

- Use Python para coleta online, extração de texto, PDF, LLM e processamento textual.
- Use R para análise estatística, validação de dados, tabelas e figuras.
- Preserve arquivos brutos e extraídos em `data/raw/`.
- Salve outputs derivados em `data/processed/` ou `output/`.
- Antes de análises substantivas novas, registre um plano em `quality_reports/plans/`.
- Em R, use `dplyr::select()` explicitamente ao selecionar colunas.
- Figuras e tabelas do paper devem ser numeradas e ter caption.

## Pontos Pendentes

- Consolidar um script mestre em R para gerar tabelas e figuras finais a partir de `data/processed/classifications_llm_main_analysis.csv` ou de `data/processed/classifications_llm.csv` com os ledgers de exclusão aplicados explicitamente.
- Escrever o manuscrito em `paper/paper.Rmd`.
- Documentar a versão final do corpus e os critérios de inclusão/exclusão no apêndice.
- Preparar um pacote de replicação em `replication/`.
