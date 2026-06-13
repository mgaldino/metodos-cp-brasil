# Triagem da validação do fulltext corpus

Gerado em: 2026-06-13 15:44:55 -0300

## Síntese

- Casos bloqueantes triados: 34.
- PIDs sem body válido na fila de falhas: 30.
- PIDs em pares com hash duplicado: 4.
- Candidatos prováveis a ledger de exclusão após revisão humana: 25.
- Casos que exigem checagem manual de fonte/metadado ou duplicidade: 9.

Esta triagem não altera `excluded_articles.csv` nem o corpus processado. Ela apenas organiza os bloqueios para decisão manual rastreável.

## Tabela 1. Casos por tipo de bloqueio e ação recomendada

blocking_type | recommended_action | triage_class | n
--- | --- | --- | ---
duplicate_hash | manual_compare_duplicate_body_and_source | duplicate_hash_manual_check |  4
missing_or_invalid_body | review_for_excluded_articles_ledger | exclude_candidate_editorial_front_matter | 17
missing_or_invalid_body | review_for_excluded_articles_ledger | exclude_candidate_errata |  4
missing_or_invalid_body | review_for_excluded_articles_ledger | exclude_candidate_obituary_or_homage |  3
missing_or_invalid_body | manual_check_source_or_metadata | manual_check_short_text |  3
missing_or_invalid_body | manual_check_source_or_metadata | manual_check_blank_title_short_text |  2
missing_or_invalid_body | review_for_excluded_articles_ledger | exclude_candidate_review_or_critical_note |  1

## Tabela 2. Casos por periódico

blocking_type | journal_title | n
--- | --- | ---
duplicate_hash | Dados |  4
missing_or_invalid_body | Revista de Administração Pública | 11
missing_or_invalid_body | Lua Nova: Revista de Cultura e Política |  9
missing_or_invalid_body | Novos estudos CEBRAP |  4
missing_or_invalid_body | Revista Brasileira de Ciências Sociais |  3
missing_or_invalid_body | Dados |  2
missing_or_invalid_body | Revista Brasileira de Política Internacional |  1

## Próximas decisões

1. Revisar os candidatos a exclusão e, se confirmado que são erratas, apresentações, notas editoriais, homenagens ou críticas curtas fora do escopo, registrar a decisão em um ledger rastreável antes de rerodar a validação.
2. Checar manualmente os casos com título vazio ou curto sem marcador explícito de tipo documental.
3. Comparar os pares duplicados por `source_url`, `input_hash` e conteúdo bruto para decidir se são duplicatas reais do SciELO, alias de PID ou erro de extração.
4. Só declarar o fulltext corpus pronto para escala quando `scripts/17_validate_fulltext_corpus.R` não tiver bloqueios ou quando os bloqueios remanescentes estiverem documentados como exclusões metodológicas.
