# Piloto v3 por leitura integral: síntese pós-consolidação

Gerado em: 2026-06-13 15:46:00 -0300

## Integridade

- Classificações no CSV consolidado: 175.
- Reading logs: 175.
- Arquivos de falha: 0.
- Tough calls: 85.

## Tabela 1. Indicadores agregados do piloto v3 integral

total | empirical | torreblanca_quant | qualitative | credibility_screen_applicable | credibility_method_present | tough_calls
--- | --- | --- | --- | --- | --- | ---
175 | 133 | 78 | 106 | 34 | 2 | 85

## Tabela 2. Distribuição por tipo de evidência e análise quantitativa

empirical_evidence_type | quantitative_analysis_type | n | percent
--- | --- | --- | ---
qualitative_only | none | 55 | 31.4
mixed_empirical | descriptive_statistics_only | 44 | 25.1
none | none | 42 | 24.0
quantitative_only | statistical_modeling | 20 | 11.4
quantitative_only | descriptive_statistics_only |  6 |  3.4
mixed_empirical | statistical_modeling |  4 |  2.3
mixed_empirical | bivariate_tests_or_correlations_only |  3 |  1.7
quantitative_only | bivariate_tests_or_correlations_only |  1 |  0.6

## Tabela 3. Distribuição do screen de revolução da credibilidade

credibility_revolution_screen_applicable | credibility_revolution_screen_reason | n | percent
--- | --- | --- | ---
FALSE | qualitative_only | 55 | 31.4
FALSE | descriptive_quantitative_only | 44 | 25.1
FALSE | not_empirical | 42 | 24.0
TRUE | statistical_modeling_screen | 24 | 13.7
TRUE | causal_claim_with_quantitative_analysis_screen |  6 |  3.4
TRUE | bivariate_or_correlation_screen |  4 |  2.3

## Tabela 4. Rótulos de método nos casos com `method_present == TRUE`

method_type | n
--- | ---
observational_regression_with_causal_claim_no_design | 2
other_modern_causal_method | 1

`observational_regression_with_causal_claim_no_design` é um rótulo diagnóstico conservador, não um método de credibilidade em sentido estrito.

## Tabela 5. Rótulos compatíveis com método de credibilidade em sentido estrito

method_type | n
--- | ---
other_modern_causal_method | 1

## Tabela 6. Tough calls por tipo de evidência

empirical_evidence_type | quantitative_analysis_type | n
--- | --- | ---
mixed_empirical | descriptive_statistics_only | 28
none | none | 18
qualitative_only | none | 17
quantitative_only | statistical_modeling | 12
mixed_empirical | statistical_modeling |  4
quantitative_only | descriptive_statistics_only |  3
mixed_empirical | bivariate_tests_or_correlations_only |  2
quantitative_only | bivariate_tests_or_correlations_only |  1

## Arquivos derivados

- Tough calls: `quality_reports/credibility_prompt_v3_integral_tough_calls.csv`.
- Artigos com método detectado: `quality_reports/credibility_prompt_v3_integral_methods_detected.csv`.

## Nota metodológica

Esta síntese apenas resume o piloto integral consolidado. Ela não declara o conjunto como gold; antes disso, ainda é necessário auditar manualmente uma amostra dos reading logs e das tough calls.
