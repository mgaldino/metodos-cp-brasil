# Plano para batches paralelos do corpus integral

Gerado em: 2026-07-09 15:16:13 -0300

Este plano só prepara manifests e comandos; nenhum artigo foi classificado nesta etapa.

## Tabela 1. Configuração

campo | valor
--- | ---
slots paralelos | 2
limite por novo batch | 100
model_reasoning_effort | high
manifesto ativo | data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv
artigos no manifesto | 5250

## Tabela 2. Batches preparados

batch | origem | artigos | completos | faltantes | falhas | first_eligible_order | last_eligible_order
--- | --- | --- | --- | --- | --- | --- | ---
active_batch_011 | existente incompleto | 100 | 96 | 4 | 1 | 1000 | 1099
active_batch_012 | criado agora | 100 | 0 | 100 | 0 | 1100 | 1199

## Tabela 3. Periódicos por batch

batch | journal_title | n
--- | --- | ---
active_batch_011 | Dados | 100
active_batch_012 | Dados | 100

## Comando recomendado

```bash
python3 scripts/41_run_credibility_integral_parallel_batches.py --labels active_batch_011 active_batch_012 --model-reasoning-effort high --timeout 2400 --run
```

## Comandos manuais equivalentes

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py --manifest data/processed/credibility_prompt_v3_full_corpus/batch_manifests/active_batch_011.csv --out-dir data/processed/credibility_prompt_v3_integral_reading/full_corpus --timeout 2400 --codex-bin codex --model-reasoning-effort high --combined-stem active_batch_011
```

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py --manifest data/processed/credibility_prompt_v3_full_corpus/batch_manifests/active_batch_012.csv --out-dir data/processed/credibility_prompt_v3_integral_reading/full_corpus --timeout 2400 --codex-bin codex --model-reasoning-effort high --combined-stem active_batch_012
```

## Observação operacional

Não execute dois `scripts/36_run_credibility_integral_next_batch.py --run` em paralelo. Use o comando recomendado acima ou os comandos manuais com manifests distintos e `--combined-stem` distinto.
