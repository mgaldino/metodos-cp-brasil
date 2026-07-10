# Plano para batches paralelos do corpus integral

Gerado em: 2026-07-09 21:43:06 -0300

Este plano só prepara manifests e comandos; nenhum artigo foi classificado nesta etapa.

## Tabela 1. Configuração

campo | valor
--- | ---
slots paralelos | 2
limite por novo batch | 100
model_reasoning_effort | medium
batches assumidos completos no plano | _nenhum_
manifesto ativo | data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv
artigos no manifesto | 5250

## Tabela 2. Batches preparados

batch | origem | artigos | completos | faltantes | falhas | first_eligible_order | last_eligible_order
--- | --- | --- | --- | --- | --- | --- | ---
active_batch_014 | existente incompleto | 100 | 1 | 99 | 24 | 1300 | 1399
active_batch_015 | existente incompleto | 100 | 0 | 100 | 25 | 1400 | 1499

## Tabela 3. Periódicos por batch

batch | journal_title | n
--- | --- | ---
active_batch_014 | Dados | 100
active_batch_015 | Dados | 67
active_batch_015 | Novos estudos CEBRAP | 33

## Comando recomendado

```bash
python3 scripts/41_run_credibility_integral_parallel_batches.py --labels active_batch_014 active_batch_015 --model-reasoning-effort medium --timeout 2400 --run --model gpt-5.6-sol
```

## Comandos manuais equivalentes

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py --manifest data/processed/credibility_prompt_v3_full_corpus/batch_manifests/active_batch_014.csv --out-dir data/processed/credibility_prompt_v3_integral_reading/full_corpus --timeout 2400 --codex-bin /Applications/Codex.app/Contents/Resources/codex --model-reasoning-effort medium --combined-stem active_batch_014 --model gpt-5.6-sol
```

```bash
python3 scripts/25_run_credibility_prompt_v3_integral_codex_batch.py --manifest data/processed/credibility_prompt_v3_full_corpus/batch_manifests/active_batch_015.csv --out-dir data/processed/credibility_prompt_v3_integral_reading/full_corpus --timeout 2400 --codex-bin /Applications/Codex.app/Contents/Resources/codex --model-reasoning-effort medium --combined-stem active_batch_015 --model gpt-5.6-sol
```

## Observação operacional

Não execute dois `scripts/36_run_credibility_integral_next_batch.py --run` em paralelo. Use o comando recomendado acima ou os comandos manuais com manifests distintos e `--combined-stem` distinto.
