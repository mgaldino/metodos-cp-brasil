# Atualização analítica do paper com o CSV canônico

Gerado em: 2026-07-13 10:45:46 -0300

## Universo reconciliado

- Linhas no CSV canônico bruto: 1798.
- Linhas duplicadas exatas removidas apenas na camada analítica: 0.
- Artigos elegíveis no manifest após ledger: 5249.
- Artigos elegíveis classificados: 1798 (34,3%).
- Artigos elegíveis ainda não classificados: 3451.
- Classificações preservadas fora do manifest: 0.
- Classificações excluídas pelo ledger: 0.

## Estratos analíticos

- Periódicos completos: Brazilian Political Science Review; Cadernos Gestão Pública e Cidadania; Contexto Internacional; Dados.
- Artigos nos periódicos completos: 1466.
- Periódicos completos com artigos nos três períodos: Brazilian Political Science Review; Contexto Internacional; Dados.

## Regra de interpretação

Os agregados dos artigos classificados continuam preliminares para o universo de onze periódicos, porque a seleção segue a ordem operacional da classificação e não um desenho amostral representativo. Os resultados dos periódicos completos são censitários apenas para esses periódicos. A comparação temporal padronizada usa somente periódicos completos com artigos nos três períodos e dá o mesmo peso a cada periódico.

## Validações lógicas

- Checks PASS: 12 de 12.
- Checks FAIL: 

## Lacunas que permanecem

- `method_explicitness` não está disponível no CSV canônico.
- `empirical_article_format` não está disponível no CSV canônico.
- O campo de claim combina pretensões causais e explicativas; não deve ser interpretado como claim causal estrito.
- Qualis e gênero de autoria não entram nesta atualização.

## Artefatos principais

- `data/processed/paper_analysis/paper_analysis_dataset_current.csv`
- `output/tables/paper/table_4_complete_journal_profile.csv`
- `output/tables/paper/table_5_claim_method_alignment.csv`
- `output/tables/paper/table_8_qualitative_complete_summary.csv`
- `output/tables/paper/period_equal_weight_profile.csv`
- `output/figures/paper/figure_2_journal_dimension_matrix.pdf`
- `output/figures/paper/figure_3_period_variation.pdf`
- `output/figures/paper/figure_5_claim_method_alignment.pdf`
