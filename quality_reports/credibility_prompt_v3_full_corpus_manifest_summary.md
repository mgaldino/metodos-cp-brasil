# Manifest do corpus completo restante para credibility_prompt_v3

Gerado em: 2026-06-16 20:26:15 -0300

## Síntese

- Artigos PASS no inventário de fulltext: 6638.
- PIDs do piloto excluídos por padrão: 175.
- Artigos excluídos por periódico no ledger: 1213.
- Artigos excluídos individualmente no ledger: 1.
- Artigos no manifest gerado: 5250.
- Manifest: `data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv`.
- Task packets: `data/processed/credibility_prompt_v3_full_corpus/task_packets/`.

Regra de ordenação: `Lua Nova: Revista de Cultura e Política` fica no fim do manifest; os demais periódicos são ordenados por `journal_title`, `year` e `pid`.

Este script não altera dados brutos nem o corpus processado. Ele apenas cria task packets derivados do `body_text` canônico para execução do classificador por leitura integral.

## Tabela 1. Artigos por periódico no manifest

journal_title | n
--- | ---
Revista Brasileira de Ciências Sociais | 708
Revista de Sociologia e Política | 638
Dados | 622
Novos estudos CEBRAP | 582
Lua Nova: Revista de Cultura e Política | 511
Revista Brasileira de Política Internacional | 490
Opinião Pública | 464
Contexto Internacional | 456
Revista Brasileira de Ciência Política | 391
Brazilian Political Science Review | 268
Cadernos Gestão Pública e Cidadania | 120
