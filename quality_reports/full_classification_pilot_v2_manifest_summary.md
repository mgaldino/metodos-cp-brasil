# Manifest do piloto v2 de classificacao tripla

Gerado em 2026-06-03 20:54:01 -03

## Decisao operacional

Este manifest usa os 175 PIDs presentes em `data/processed/fulltext_gold/article_texts_gold.csv`, com o `body_text` integral canonico como unica fonte textual substantiva.

A classificacao tripla anterior foi feita sem `<body>` integral e fica preservada. Artefatos antigos so devem entrar depois como comparacao diagnostica.

Nao ha chamada de API neste piloto. As classificacoes substantivas devem ser feitas por tres subagentes Codex locais independentes.

## Snapshot

| item | value |
| --- | --- |
| artigos no manifest | 175 |
| fonte canonica presente | 175 |
| body canonico preenchido | 175 |
| hash SHA-256 do body preenchido | 175 |
| hash SHA-256 igual ao input_hash do gold |   0 |
| pacotes derivados gerados | 175 |
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

- `data/processed/full_classification_pilot_v2/pilot_manifest.csv`
- `data/processed/full_classification_pilot_v2/pilot_manifest_metadata.json`
- `data/processed/full_classification_pilot_v2/task_packets/`
