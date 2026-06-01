# Revolução da Credibilidade na Ciência Política Brasileira

Este repositório replica e expande Torreblanca et al. (2026), "The Credibility Revolution in Political Science", para periódicos brasileiros de Ciência Política, Relações Internacionais e Administração Pública indexados no SciELO.

## Estado Atual

- Corpus coletado: `data/raw/articles_2005_2025.csv`, com 8.400 artigos, 15 periódicos e anos de publicação entre 2005 e 2025.
- Amostra de validação: `data/processed/sample_validation.csv`, com 208 artigos.
- Classificações LLM: `data/processed/classifications_llm.csv`, com 208 artigos classificados.
- Benchmarks internacionais de readability: `data/processed/benchmark_cp.csv` e `data/processed/benchmark_ir.csv`.
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

5. Construir benchmarks internacionais:

```bash
python3 scripts/build_benchmark.py --field both
```

6. Rodar testes:

```bash
python3 -m pytest scripts
```

## Convenções

- Use Python para coleta online, extração de texto, PDF, LLM e processamento textual.
- Use R para análise estatística, validação de dados, tabelas e figuras.
- Preserve arquivos brutos e extraídos em `data/raw/`.
- Salve outputs derivados em `data/processed/` ou `output/`.
- Antes de análises substantivas novas, registre um plano em `quality_reports/plans/`.
- Em R, use `dplyr::select()` explicitamente ao selecionar colunas.
- Figuras e tabelas do paper devem ser numeradas e ter caption.

## Pontos Pendentes

- Normalizar o schema de `data/processed/classifications/*.json`: há classificações antigas com valores fora do schema atual, especialmente em `error_in_raw_text`, `single_country_study`, `single_region`, `paper_uses_survey_data`, `uses_original_dataset` e `effort_to_explore_mechanisms`.
- Consolidar um script mestre em R para gerar tabelas e figuras finais a partir de `data/processed/classifications_llm.csv`.
- Escrever o manuscrito em `paper/paper.Rmd`.
- Documentar a versão final do corpus e os critérios de inclusão/exclusão no apêndice.
- Preparar um pacote de replicação em `replication/`.

