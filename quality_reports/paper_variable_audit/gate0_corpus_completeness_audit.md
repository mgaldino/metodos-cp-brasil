# Gate 0: auditoria de completude e escopo do paper

Gerado em: 2026-07-08 20:56:11 -0300

## Resultado do gate

- A classificação ainda não cobre o manifest completo; qualquer manuscrito precisa rotular os resultados como preliminares.
- Manifest completo elegível: 5250 PIDs.
- PIDs classificados com leitura integral e no manifest: 699 (13.3% do manifest).
- PIDs ainda sem classificação combinada: 4551.
- PIDs do manifest com texto integral no corpus: 5250 de 5250.
- PIDs totais no arquivo de texto integral do corpus: 6642.

## Denominadores atuais

- Corpus completo elegível: 5250.
- Artigos classificados: 699.
- Artigos empíricos entre classificados: 568 de 699 (81.3%).
- Artigos empíricos quantitativos entre classificados: 324 de 699 (46.4%).
- Artigos com claim causal ou explicativo entre classificados: 597 de 699 (85.4%).
- Artigos no screen de credibilidade entre classificados: 147 de 699 (21%).

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
