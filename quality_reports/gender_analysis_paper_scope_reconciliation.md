# Reconciliação da análise de gênero com o escopo do paper

O relatório original de gênero partia do arquivo de autoria já classificado e removia os dois periódicos excluídos. O paper, porém, também aplica o ledger de artigos inelegíveis. Este script reproduz essa segunda etapa sem reclassificar prenomes.

- Base original de autoria: 4157 artigos.
- PIDs removidos pelo ledger: 13.
- Base reconciliada usada no paper: 4144 artigos em nove periódicos.
- Arquivo derivado: `data/processed/gender_analysis/current_canonical_article_gender_paper_scope.csv`.
- Tabelas derivadas: `output/tables/gender_analysis/table_3_methodological_indicators_by_first_author_gender_paper_scope.csv` e `output/tables/gender_analysis/table_7_standardized_comparison_journal_period_paper_scope.csv`.

A classificação dos prenomes continua sendo a produzida por `scripts/51_analyze_gender_current_canonical.R`; o denominador analítico é agora idêntico ao do paper.
