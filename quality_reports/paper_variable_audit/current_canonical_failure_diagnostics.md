# Diagnóstico das falhas do CSV canônico na análise do paper

- Data de execução: 2026-07-18 17:51:02 -0300
- CSV canônico: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv`
- Dimensão do CSV: 3.565 linhas x 27 colunas
- PIDs elegíveis classificados: 3565
- PIDs distintos com ao menos uma falha: 8

## Contagem por validação

- `statistical_inference_missing_within_quantitative`: 5
- `statistical_inference_without_quantitative_analysis`: 1
- `statistical_inference_without_quantitative_flag`: 1
- `unknown_quantitative_level`: 2

## Níveis de `quantitative_analysis_type`

- `unclear`: 2 (fora da taxonomia)
- `none`: 1931 (previsto)
- `descriptive_statistics_only`: 899 (previsto)
- `statistical_modeling`: 617 (previsto)
- `bivariate_tests_or_correlations_only`: 116 (previsto)

## Artefatos

- `quality_reports/paper_variable_audit/current_canonical_failure_diagnostics.csv`
- `quality_reports/paper_variable_audit/current_canonical_quantitative_level_counts.csv`
