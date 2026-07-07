# Loop operacional para classificar o corpus completo

Este loop continua a classificação por leitura integral do `credibility_prompt_v3` em blocos de 100 artigos, preservando checkpoint por PID e evitando offsets manuais.

## Estado de referência

- Manifesto ativo: `data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv`.
- Output canônico: `data/processed/credibility_prompt_v3_integral_reading/full_corpus/`.
- O runner conta como completo apenas PID com `reading_logs/<pid>.json` e `classifications/<pid>.json` válidos.
- O combinado canônico é regenerado com `--combine-only` depois de cada bloco real.
- O esforço de raciocínio padrão do loop é `xhigh`, conforme o A/B `gpt-5.5 high` vs `xhigh`.

## Comandos

Preparar ou reutilizar o próximo batch ativo incompleto:

```bash
python3 scripts/36_run_credibility_integral_next_batch.py
```

Renderizar prompts sem chamar `codex exec`:

```bash
python3 scripts/36_run_credibility_integral_next_batch.py --dry-run
```

Rodar o bloco real:

```bash
python3 scripts/36_run_credibility_integral_next_batch.py --run
```

Se a execução parar no meio, repetir exatamente o mesmo comando. O wrapper reutiliza o batch ativo incompleto mais recente e o runner pula PIDs que já têm log e classificação válidos.

## Artefatos por bloco

- Manifesto congelado: `data/processed/credibility_prompt_v3_full_corpus/batch_manifests/active_batch_NNN.csv`.
- Relatório de seleção: `quality_reports/credibility_prompt_v3_active_batch_NNN_selection.md`.
- CSV/JSONL do bloco: `data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/active_batch_NNN.csv` e `.jsonl`.
- Resumo do bloco: `data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/batch_summary_active_batch_NNN.md`.
- Resumo corrente do corpus classificado: `data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/batch_summary_current.md`.

## Regras

- Não rodar análise substantiva final antes de completar ou documentar todos os PIDs do manifesto.
- Não usar `--force` salvo para reprocessamento deliberado.
- Não commitar outputs grandes em `full_corpus/` ou `task_packets/`.
- Depois de cada bloco real, reportar: selecionados, completos, falhas, empíricos, quantitativos Torreblanca, screen de credibilidade, candidatos positivos e caminhos dos resumos.
