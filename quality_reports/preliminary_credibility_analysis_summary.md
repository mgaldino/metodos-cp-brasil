# Síntese da análise preliminar de credibilidade

Gerado em: 2026-06-16 23:52:02 -0300

## Escopo

- Artigos no manifest completo: 5250.
- Linhas classificadas no CSV combinado bruto: 400.
- Artigos classificados e validados: 399.
- Linhas classificadas fora do manifest atual: 1.
- Cobertura preliminar: 7.6%.
- Blocos completos observados: 0, 100, 200, 300.

## Regra de contagem

- Numerador principal: métodos estritos de identificação causal.
- Fila de auditoria: `other_modern_causal_method`.
- Sensibilidade inclusiva: união de artigos únicos com método estrito ou `other_modern_causal_method`.

## Resultados preliminares

- Método estrito de credibilidade: 15 artigos.
- Fila `other_modern_causal_method`: 2 artigos; destes, 0 não têm método estrito também.
- Medida inclusiva de sensibilidade (união de artigos únicos): 15 artigos.
- Tough calls: 249 artigos.

## Aviso de interpretação

Os 399 artigos classificados e validados contra o manifest atual não formam uma amostra aleatória do corpus completo. As taxas deste relatório servem para validar o pipeline e antecipar a estrutura analítica; não devem ser usadas como estimativa substantiva final do paper.

## Artefatos principais

- Base analítica: `data/processed/credibility_prompt_v3_integral_reading/preliminary_analysis/analysis_dataset_preliminary.csv`.
- Tabelas: `output/tables/preliminary_credibility/`.
- Figuras: `output/figures/preliminary_credibility/`.
- Relatório: `quality_reports/preliminary_credibility_analysis.pdf`.
