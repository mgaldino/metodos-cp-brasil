# Estimativa de tempo: credibility_prompt_v3 full corpus

Gerado em: 2026-06-16 18:04:59 -0300

## Método

A duração por artigo é calculada como a diferença entre o `mtime` de `prompts/<pid>.prompt.md`, escrito imediatamente antes da chamada `codex exec`, e o `mtime` de `classifications/<pid>.json`, escrito após validação do JSON.

A estimativa exclui pausas manuais entre blocos, tempo de dry-run, tentativas que falharam antes do sucesso e tempo de espera por autorização após cada bloco de 100 artigos.

## Tabela 1. Status e tempos observados

indicador | valor
--- | ---
artigos no manifesto | 6464
artigos concluídos | 400
artigos restantes | 6064
artigos concluídos com tempo estimável | 400
tempo observado somado | 10h 02m 34s
média por artigo | 90.4 s
mediana por artigo | 83.7 s
p90 por artigo | 122.7 s
p95 por artigo | 139.4 s

## Tabela 2. Projeção serial para o corpus completo

cenário | segundos_por_artigo | tempo_total_6464 | tempo_restante
--- | --- | --- | ---
mediana observada | 83.7 | 6d 06h 17m 19s | 5d 20h 59m 19s
média observada | 90.4 | 6d 18h 17m 23s | 6d 08h 14m 50s
p90 observado | 122.7 | 9d 04h 19m 30s | 8d 14h 41m 28s

## Tabela 3. Tempo por bloco concluído

block_offset | artigos | media_seg | mediana_seg | p90_seg | soma
--- | --- | --- | --- | --- | ---
0 | 100 | 81.1 | 74.1 | 111.2 | 02h 15m 13s
100 | 100 | 83.2 | 77.9 | 105 | 02h 18m 43s
200 | 100 | 103.4 | 91.8 | 133.3 | 02h 52m 18s
300 | 100 | 93.8 | 90.4 | 126.7 | 02h 36m 20s

## Interpretação operacional

Usando a média observada, os 6464 artigos exigiriam cerca de 6d 18h 17m 23s de processamento serial efetivo. Como 400 já estão concluídos, o restante exigiria cerca de 6d 08h 14m 50s de processamento efetivo, antes de retries e pausas de governança.

CSV por artigo: `data/processed/credibility_prompt_v3_integral_reading/full_corpus/combined/runtime_estimate_completed_articles.csv`.
