# Manifest do piloto de classificacao tripla

Gerado em 2026-06-03 17:59:36 -03

## Decisao operacional

Este manifest usa os 175 PIDs de `data/processed/classifications_llm_main_analysis.csv` apenas como gold/piloto elegivel. A classificacao substantiva do corpus completo continua pendente e nao deve usar essa base como base final do paper.

Nao ha chamada de API neste piloto. As classificacoes substantivas devem ser feitas por tres subagentes locais independentes, usando os XMLs e os prompts versionados.

## Snapshot

| item | value |
| --- | --- |
| artigos no manifest | 175 |
| XMLs presentes | 175 |
| hash SHA-256 preenchido | 175 |
| XML fonte com body |   0 |
| raw fulltext presente | 175 |
| raw fulltext identico ao XML fonte | 175 |
| raw fulltext com body |   0 |
| periodicos |  13 |

## Artigos por periodico

| journal_title | n |
| --- | --- |
| Brazilian Political Science Review | 16 |
| Lua Nova: Revista de Cultura e Política | 16 |
| Opinião Pública | 16 |
| Revista Brasileira de Ciências Sociais | 16 |
| Revista Brasileira de Política Internacional | 16 |
| Revista de Administração Pública | 16 |
| Revista de Sociologia e Política | 16 |
| Contexto Internacional | 15 |
| Dados | 14 |
| Novos estudos CEBRAP | 14 |
| Revista Brasileira de Ciência Política | 12 |
| Cadernos Gestão Pública e Cidadania |  4 |
| Sur. Revista Internacional de Direitos Humanos |  4 |

## Arquivos gerados

- `data/processed/full_classification_pilot/pilot_manifest.csv`
- `data/processed/full_classification_pilot/pilot_manifest_metadata.json`
