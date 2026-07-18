# Diagnóstico das exceções do CSV canônico relevantes para o paper

- Data de execução: 2026-07-18 18:10:52 -0300
- CSV canônico: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/classifications_integral_reading.csv`
- Dimensão do CSV: 3.565 linhas x 27 colunas
- PIDs elegíveis classificados: 3565
- PIDs distintos com ao menos uma exceção: 6

## Contagem por verificação

- `statistical_inference_missing_within_quantitative` [warning]: 5
- `statistical_inference_outside_quantitative_definition` [warning]: 1

Os avisos são compatíveis com o schema: valores nulos de inferência são excluídos do denominador observado, e inferência fora da definição de artigo quantitativo não entra no numerador quantitativo. Apenas níveis fora da taxonomia seriam erros bloqueantes.

## Níveis de `quantitative_analysis_type`

- `none`: 1931 (previsto)
- `descriptive_statistics_only`: 899 (previsto)
- `statistical_modeling`: 617 (previsto)
- `bivariate_tests_or_correlations_only`: 116 (previsto)
- `unclear`: 2 (previsto)

## Artefatos

- `quality_reports/paper_variable_audit/current_canonical_failure_diagnostics.csv`
- `quality_reports/paper_variable_audit/current_canonical_quantitative_level_counts.csv`
