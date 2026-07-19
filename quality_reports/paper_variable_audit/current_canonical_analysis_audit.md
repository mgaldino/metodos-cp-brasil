# Atualização analítica do paper com o CSV canônico

Gerado em: 2026-07-19 00:18:16 -0300

## Universo reconciliado

- Linhas no CSV canônico bruto: 4389.
- Linhas duplicadas exatas removidas apenas na camada analítica: 0.
- Artigos elegíveis no manifest após ledger: 4144.
- Artigos elegíveis classificados: 4144 (100,0%).
- Artigos elegíveis ainda não classificados: 0.
- Classificações preservadas fora do manifest: 0.
- Classificações excluídas pelo ledger: 13.
- Periódicos excluídos pelo ledger: Brazilian Journal of Political Economy; Civitas - Revista de Ciências Sociais; Revista de Administração Pública; Sur. Revista Internacional de Direitos Humanos; Lua Nova: Revista de Cultura e Política; Novos estudos CEBRAP.
- Intervalo de recuperação dos textos no manifest: 2026-06-04 00:04:16 a 2026-07-18 11:01:42.
- MD5 do manifest: `0d62ffa4738fb496e3f9a05b049185a8`.
- MD5 do CSV canônico: `b10712af7af5223ff9217f9645813ddb`.
- MD5 do ledger de artigos: `6ff2d2e1709eda1f551a0ce50bec8b03`.
- MD5 do ledger de periódicos: `2a3e3042d3638d733753f40137f27384`.

## Estratos analíticos

- Periódicos completos: Brazilian Political Science Review; Cadernos Gestão Pública e Cidadania; Contexto Internacional; Dados; Opinião Pública; Revista Brasileira de Ciência Política; Revista Brasileira de Ciências Sociais; Revista Brasileira de Política Internacional; Revista de Sociologia e Política.
- Artigos nos periódicos completos: 4144.
- Periódicos completos com artigos nos três períodos: Brazilian Political Science Review; Contexto Internacional; Dados; Opinião Pública; Revista Brasileira de Ciência Política; Revista Brasileira de Ciências Sociais; Revista Brasileira de Política Internacional; Revista de Sociologia e Política.

## Regra de interpretação

Os agregados desta versão cobrem o universo de periódicos elegíveis após as exclusões documentadas. Os resultados dos periódicos completos cobrem todos os artigos desses periódicos, mas os rótulos automatizados ainda não foram integralmente adjudicados por humanos. A comparação temporal usa somente periódicos completos com artigos nos três períodos e reporta tanto a média com peso igual por periódico quanto a proporção agrupada por artigo.

## Validações lógicas

- Checks PASS: 23 de 28.
- Checks WARN: statistical_inference_without_quantitative_flag (n=1); statistical_inference_without_quantitative_analysis (n=1); statistical_inference_missing_within_quantitative (n=5); classified_excluded_by_ledger (n=13); excluded_journal_in_classifications (n=232).
- Checks FAIL: nenhum.

## Lacunas que permanecem

- `method_explicitness` não está disponível no CSV canônico.
- `empirical_article_format` não está disponível no CSV canônico.
- A categoria de afirmação combina pretensões causais e explicativas; não deve ser interpretada como afirmação causal estrita.
- A classificação em escala ainda carece de validação humana estratificada e adjudicação dos casos difíceis e dos métodos raros.
- A proveniência de modelo e esforço de classificação ainda não está consolidada por PID; por isso, variação temporal pode refletir mudança do classificador.
- Os desenhos estritos registram presença nominal de famílias de método, não qualidade de implementação nem validade da identificação.
- Qualis e gênero de autoria não entram nesta atualização.

## Artefatos principais

- `data/processed/paper_analysis/paper_analysis_dataset_current.csv`
- `output/tables/paper/table_4_complete_journal_profile.csv`
- `output/tables/paper/table_5_claim_method_alignment.csv`
- `output/tables/paper/table_8_qualitative_complete_summary.csv`
- `output/tables/paper/period_equal_weight_profile.csv`
- `output/tables/paper/period_article_weight_profile.csv`
- `output/tables/paper/year_article_weight_profile.csv`
- `output/figures/paper/figure_2_journal_dimension_matrix.pdf`
- `output/figures/paper/figure_3_period_variation.pdf`
- `output/figures/paper/figure_7_year_variation.pdf`
- `output/figures/paper/figure_5_claim_method_alignment.pdf`
