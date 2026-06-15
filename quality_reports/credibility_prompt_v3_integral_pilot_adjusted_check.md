# Checagem geral ajustada do piloto v3 integral

Gerado em: 2026-06-15 17:25:02 -0300

## Síntese

- Artigos no piloto: 175.
- Quantitativos Torreblanca: 78/175 = 44.6% do total; 78/133 = 58.6% dos empíricos.
- Screen de credibilidade aplicável: 34/175 = 19.4%.
- Positivos ajustados de desenho de revolução da credibilidade: 0/175 = 0.0%.

Ajuste aplicado: A017 (`S0104-62762018000100209`) foi removido do numerador de métodos de revolução da credibilidade. O artigo usa SEM/mediação causal citando Imai, Keele e Tingley, mas não discute nem justifica ignorabilidade sequencial ou hipótese equivalente de identificação.

Regra para a escala: métodos fora da lista usual de desenhos da revolução da credibilidade só contam como `other_modern_causal_method` positivo se houver discussão explícita da identificação causal e da plausibilidade das hipóteses de identificação.

## Tabela 1. Indicadores gerais ajustados

indicador | n | percent_total
--- | --- | ---
Artigos no piloto | 175 | 100.0%
Empíricos | 133 | 76.0%
Quantitativos Torreblanca |  78 | 44.6%
Qualitativos | 106 | 60.6%
Screen de credibilidade aplicável |  34 | 19.4%
method_present bruto do classificador |   2 | 1.1%
Método estrito de identificação causal |   0 | 0.0%
other_modern_causal_method bruto |   1 | 0.6%
Positivos ajustados após auditoria A017 |   0 | 0.0%

## Tabela 2. Distribuição de métodos detectados

method_class | method_type | adjusted_positive | n
--- | --- | --- | ---
broad_other_modern_causal_method | other_modern_causal_method | FALSE |  1
diagnostic_not_design | none_detected | FALSE | 20
diagnostic_not_design | observational_regression_with_causal_claim_no_design | FALSE | 14

## Tabela 3. Casos positivos ajustados

_Nenhum caso._

## Tabela 4. Ajustes manuais aplicados

pid | title | journal_title | method_type | method_class | adjusted_positive
--- | --- | --- | --- | --- | ---
S0104-62762018000100209 | Violência e satisfação com a democracia no Brasil | Opinião Pública | other_modern_causal_method | broad_other_modern_causal_method | FALSE
S0104-62762018000100209 | Violência e satisfação com a democracia no Brasil | Opinião Pública | observational_regression_with_causal_claim_no_design | diagnostic_not_design | FALSE

## Conclusão operacional

Com a regra ajustada, o piloto v3 tem 44,6% de artigos quantitativos e 0,0% de artigos com desenho validado de revolução da credibilidade. O próximo batch deve manter `method_present = false` para regressão observacional, SEM/mediação causal ou modelos estruturais sem justificativa explícita de identificação.
