# Amostra para auditoria manual do piloto v3 integral

Gerado em: 2026-06-13 16:05:03 -0300

## Síntese

- Arquivo CSV para Google Sheets: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/credibility_prompt_v3_integral_manual_audit_sample.csv`.
- Tamanho da amostra: 64 artigos.
- Seed reprodutível: 20260613.
- Alvo de tough calls fora do screen: 20.
- Alvo de controles não tough-call: 10.

A amostra inclui todos os casos em que o screen de revolução da credibilidade é aplicável ou em que o classificador detectou método. Em seguida, adiciona uma amostra estratificada de tough calls fora do screen e uma amostra estratificada de controles não tough-call.

Esta amostra foi desenhada para auditoria manual focalizada do classificador, não para estimar de forma representativa a taxa de erro do corpus. Os estratos do sorteio complementar são `empirical_evidence_type` e `quantitative_analysis_type`.

Nos campos Codex booleanos, `NA_IN_SOURCE` indica valor ausente no CSV consolidado e `NOT_APPLICABLE_SCREEN_FALSE` indica que `method_present` estava em branco porque o screen de revolução da credibilidade não era aplicável.

## Tabela 1. Artigos selecionados por grupo de amostragem

audit_sample_group | n
--- | ---
1_screen_or_method_core | 34
2_tough_outside_screen_sample | 20
3_non_tough_control_sample | 10

## Tabela 2. Artigos selecionados por razão de inclusão

selection_reason | n
--- | ---
screen_applicable | 32
tough_call_outside_screen_sample | 20
non_tough_control_sample | 10
screen_applicable; method_present |  2

## Tabela 3. Artigos selecionados por tipo de evidência, análise quantitativa e grupo

codex_empirical_evidence_type | codex_quantitative_analysis_type | audit_sample_group | n
--- | --- | --- | ---
mixed_empirical | bivariate_tests_or_correlations_only | 1_screen_or_method_core |  3
mixed_empirical | descriptive_statistics_only | 1_screen_or_method_core |  5
mixed_empirical | statistical_modeling | 1_screen_or_method_core |  4
quantitative_only | bivariate_tests_or_correlations_only | 1_screen_or_method_core |  1
quantitative_only | descriptive_statistics_only | 1_screen_or_method_core |  1
quantitative_only | statistical_modeling | 1_screen_or_method_core | 20
mixed_empirical | descriptive_statistics_only | 2_tough_outside_screen_sample |  6
none | none | 2_tough_outside_screen_sample |  8
qualitative_only | none | 2_tough_outside_screen_sample |  5
quantitative_only | descriptive_statistics_only | 2_tough_outside_screen_sample |  1
mixed_empirical | descriptive_statistics_only | 3_non_tough_control_sample |  2
none | none | 3_non_tough_control_sample |  2
qualitative_only | none | 3_non_tough_control_sample |  5
quantitative_only | descriptive_statistics_only | 3_non_tough_control_sample |  1

## Colunas manuais sugeridas

- `manual_is_empirical_paper`: TRUE/FALSE.
- `manual_empirical_evidence_type`: `none`, `qualitative_only`, `quantitative_only` ou `mixed_empirical`.
- `manual_is_empirical_quant_paper_torreblanca`: TRUE/FALSE.
- `manual_is_empirical_qual_paper`: TRUE/FALSE.
- `manual_quantitative_analysis_type`: `none`, `descriptive_statistics_only`, `bivariate_tests_or_correlations_only` ou `statistical_modeling`.
- `manual_has_statistical_inference`: TRUE/FALSE.
- `manual_causal_or_explanatory_claim_present`: TRUE/FALSE.
- `manual_screen_applicable`: TRUE/FALSE.
- `manual_method_present`: TRUE/FALSE.
- `manual_decision`: `accept_codex`, `minor_edit`, `major_disagreement` ou `needs_second_review`.

## Como usar

1. Importe o CSV no Google Sheets como nova planilha.
2. Congele a primeira linha e ative filtros.
3. Leia o paper pelo `paper_url` e, quando necessário, compare com o `reading_log_relative_path` no repositório.
4. Preencha apenas as colunas `manual_*`, `reviewer` e `audit_date`.
5. Exporte a planilha auditada como CSV e salve de volta no repositório para reconciliação posterior.
