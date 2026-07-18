# Atualização analítica do paper com o CSV canônico

Gerado em: 2026-07-18 18:28:03 -0300

## Universo reconciliado

- Linhas no CSV canônico bruto: 3565.
- Linhas duplicadas exatas removidas apenas na camada analítica: 0.
- Artigos elegíveis no manifest após ledger: 5249.
- Artigos elegíveis classificados: 3565 (67,9%).
- Artigos elegíveis ainda não classificados: 1684.
- Classificações preservadas fora do manifest: 0.
- Classificações excluídas pelo ledger: 0.
- Periódicos excluídos pelo ledger: Brazilian Journal of Political Economy; Civitas - Revista de Ciências Sociais; Revista de Administração Pública; Sur. Revista Internacional de Direitos Humanos.
- Intervalo de recuperação dos textos no manifest: 2026-06-04 00:04:16 a 2026-07-18 11:01:42.
- MD5 do manifest: `ca3988ebbd9f2cbf243f3f2abeab7a50`.
- MD5 do CSV canônico: `72616ef21a0aa3ca33482e3400fca176`.
- MD5 do ledger de artigos: `0f155ad948b2a419443e12daf96f2ec0`.
- MD5 do ledger de periódicos: `d0a3660f87b7c60efdd2efff05b68e6a`.

## Estratos analíticos

- Periódicos completos: Brazilian Political Science Review; Cadernos Gestão Pública e Cidadania; Contexto Internacional; Dados; Opinião Pública; Revista Brasileira de Ciência Política.
- Artigos nos periódicos completos: 2321.
- Periódicos completos com artigos nos três períodos: Brazilian Political Science Review; Contexto Internacional; Dados; Opinião Pública; Revista Brasileira de Ciência Política.

## Regra de interpretação

Os agregados dos artigos classificados continuam preliminares para o universo de onze periódicos, porque a seleção segue a ordem operacional da classificação e não um desenho amostral representativo. Os resultados dos periódicos completos cobrem todos os artigos desses periódicos, mas os rótulos automatizados ainda não foram integralmente adjudicados por humanos. A comparação temporal usa somente periódicos completos com artigos nos três períodos e reporta tanto a média com peso igual por periódico quanto a proporção agrupada por artigo.

## Validações lógicas

- Checks PASS: 25 de 28.
- Checks WARN: statistical_inference_without_quantitative_flag (n=1); statistical_inference_without_quantitative_analysis (n=1); statistical_inference_missing_within_quantitative (n=5).
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
