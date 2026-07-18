# Retry do active_batch_036

Data: 2026-07-18

## Escopo

Foram repetidos os quatro PIDs que falharam na execução original do
`active_batch_036`:

- `S0103-33522022000300204`
- `S0103-33522022000300205`
- `S0103-33522022000300206`
- `S0103-33522023000300200`

Modelo: `gpt-5.6-luna`  
Esforço: `xhigh`  
Service tier: `default`  
Timeout: 2400 segundos  
Execução: `--ephemeral`

## Resultado

Os três primeiros PIDs passaram no primeiro retry. O quarto repetiu uma
inconsistência de schema: a resposta marcava
`credibility_revolution_screen_applicable` como `false`, mas preenchia os
campos de método que o schema exige como `null` nesse caso.

O runner foi ajustado para normalizar somente esses campos redundantes antes
da validação, sem alterar a evidência textual nem a decisão substantiva. O
quarto PID foi então repetido isoladamente e passou.

Após a reconciliação da proveniência com o contrato canônico do batch, a
recombinação confirmou:

- artigos no manifesto: 91;
- classificações completas: 91;
- PIDs faltantes: 0;
- falhas específicas do `active_batch_036`: 0.

O contador global de arquivos de falha ainda inclui um caso antigo de Lua
Nova cujo texto termina em `(continua)`. Esse caso foi explicitamente deixado
fora dos batches atuais e não foi reprocessado.

## Verificações

- `python3 -m py_compile scripts/25_run_credibility_prompt_v3_integral_codex_batch.py`
- `git diff --check -- scripts/25_run_credibility_prompt_v3_integral_codex_batch.py`
- recombinação canônica com `--combine-only` para `active_batch_036`;
- proveniências dos quatro retries alinhadas ao contrato canônico.
