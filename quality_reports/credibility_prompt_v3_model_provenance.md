# Proveniência de modelos da classificação integral

Atualizado em: 2026-07-10

## Tabela 1. Histórico documentado

escopo | modelo | esforço | velocidade | situação da evidência
--- | --- | --- | --- | ---
baseline histórico e batches de produção anteriores ao GPT-5.6 | GPT-5.5 | xhigh | configuração padrão | reconstruído a partir da configuração e dos relatórios históricos; os runners antigos não gravavam sidecar por batch
teste A/B histórico, 50 artigos | GPT-5.5 | high | configuração padrão | comprovado pelo manifesto e relatório A/B
benchmark dirigido, 10 artigos difíceis | GPT-5.6 Sol | medium | default | comprovado pelos outputs e timings do benchmark
benchmark dirigido, 10 artigos difíceis | GPT-5.6 Terra | medium | default | comprovado pelos outputs e timings do benchmark
benchmark dirigido, 10 artigos difíceis | GPT-5.6 Terra | xhigh | default | comprovado pelos outputs e timings do benchmark
active_batch_014 e active_batch_015 | GPT-5.6 Sol | medium | default | reconstruído a partir dos comandos preparados e dos outputs completos; não havia sidecar automático no runner
active_batch_016 | GPT-5.6 Terra | medium | default | configuração escolhida para a execução atual; será comprovada pelo sidecar automático

## Decisão atual

O `active_batch_016` usa explicitamente `gpt-5.6-terra`, esforço `medium` e `service_tier=default`. A escolha é deliberada pelo pesquisador após o benchmark comparativo. No benchmark, Terra medium empatou com Sol medium em quatro PIDs com divergência crítica de screen/método, mas apresentou concordância média menor com o baseline GPT-5.5 xhigh (81,7% contra 87,5%). A concordância com o baseline mede continuidade, não verdade substantiva.

Na execução iniciada em 2026-07-10, 99 dos 100 PIDs foram concluídos após um retry idêntico. O PID `S0101-33002006000200005` permaneceu bloqueado porque o texto publicado termina editorialmente com “(continua)”; embora a fonte canônica tenha 8.917 palavras e status `PASS`, Terra medium recusou duas vezes declarar leitura integral. O resultado não foi forçado.

## Registro automático a partir do active_batch_016

O script `scripts/25_run_credibility_prompt_v3_integral_codex_batch.py` grava `combined/<combined_stem>_run_metadata.json` antes de chamar o Codex e `provenance/<pid>.json` após cada classificação válida. Os sidecars registram modelo e esforço efetivos, tier, manifesto e PIDs, hashes do manifesto, prompts, schema e runner, além da versão do Codex. Uma retomada só ignora um PID já completo quando sua proveniência coincide com o contrato atual; caso contrário, o artigo é reprocessado.

Os batches anteriores não devem ser tratados como tendo proveniência por PID: a documentação disponível permite reconstruir a configuração operacional, mas não substitui o sidecar introduzido nesta rodada.
