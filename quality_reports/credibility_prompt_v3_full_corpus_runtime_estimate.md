# Estimativa de tempo: credibility_prompt_v3 full corpus

Gerado em: 2026-06-16 23:19:56 -0300

## Método

A duração por artigo é calculada como a diferença entre o `mtime` de `prompts/<pid>.prompt.md`, escrito imediatamente antes da chamada `codex exec`, e o `mtime` de `classifications/<pid>.json`, escrito após validação do JSON.

A estimativa exclui pausas manuais entre blocos, tempo de dry-run, tentativas que falharam antes do sucesso e tempo de espera por autorização após cada bloco de 100 artigos.

## Tabela 1. Status e tempos observados

indicador | valor
--- | ---
artigos no manifesto | 5250
artigos concluídos | 499
artigos restantes | 4751
artigos concluídos com tempo estimável | 499
tempo observado somado | 12h 48m 12s
média por artigo | 92.4 s
mediana por artigo | 83.7 s
p90 por artigo | 129.2 s
p95 por artigo | 147.8 s

## Tabela 2. Projeção serial para o corpus completo

cenário | segundos_por_artigo | tempo_total_manifesto | tempo_restante
--- | --- | --- | ---
mediana observada | 83.7 | 5d 02h 01m 08s | 4d 14h 25m 17s
média observada | 92.4 | 5d 14h 42m 19s | 5d 01h 54m 07s
p90 observado | 129.2 | 7d 20h 28m 20s | 7d 02h 33m 31s

## Tabela 3. Tempo por bloco concluído

block_offset | artigos | media_seg | mediana_seg | p90_seg | soma
--- | --- | --- | --- | --- | ---
0 | 100 | 81.1 | 74.1 | 111.2 | 02h 15m 13s
100 | 100 | 83.2 | 77.9 | 105 | 02h 18m 43s
200 | 100 | 103.4 | 91.8 | 133.3 | 02h 52m 18s
300 | 100 | 94.1 | 90.4 | 126.7 | 02h 36m 50s
400 | 99 | 100.1 | 83 | 143.6 | 02h 45m 09s

## Interpretação operacional

Usando a média observada, os 5250 artigos exigiriam cerca de 5d 14h 42m 19s de processamento serial efetivo. Como 499 já estão concluídos, o restante exigiria cerca de 5d 01h 54m 07s de processamento efetivo, antes de retries e pausas de governança.

CSV por artigo: `data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/runtime_estimate_completed_articles.csv`.
