# Gate 0: auditoria de completude e escopo do paper

Gerado em: 2026-07-08 21:21:05 -0300

## Resultado do gate

- A classificação ainda não cobre o manifest completo; qualquer manuscrito precisa rotular os resultados como preliminares.
- Manifest completo elegível: 5250 PIDs.
- PIDs classificados com leitura integral e no manifest: 799 (15.2% do manifest).
- PIDs ainda sem classificação combinada: 4451.
- PIDs do manifest com texto integral no corpus: 5250 de 5250.
- PIDs totais no arquivo de texto integral do corpus: 6642.

## Denominadores atuais

- Corpus completo elegível: 5250.
- Artigos classificados: 799.
- Artigos empíricos entre classificados: 647 de 799 (81%).
- Artigos empíricos quantitativos entre classificados: 349 de 799 (43.7%).
- Artigos com claim causal ou explicativo entre classificados: 682 de 799 (85.4%).
- Artigos no screen de credibilidade entre classificados: 150 de 799 (18.8%).

## Checagens

- Checks PASS: 10 de 11.
- Checks FAIL: classification_covers_full_manifest

## Implicação para a redação

O paper não pode apresentar resultados finais do corpus completo. A versão compilável deve declarar no resumo, em Dados, Resultados e Conclusão que os resultados são preliminares e cobrem apenas os PIDs já classificados por leitura integral.

## Artefatos

- `data/processed/paper_analysis/gate0_validation_checks.csv`
- `data/processed/paper_analysis/gate0_denominator_summary.csv`
- `data/processed/paper_analysis/gate0_coverage_by_journal_period.csv`
- `data/processed/paper_analysis/gate0_manifest_not_classified.csv`
