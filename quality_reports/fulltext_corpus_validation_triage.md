# Triagem da valida<c3><a7><c3><a3>o do fulltext corpus

Gerado em: 2026-06-13 14:09:26 -0300

## S<c3><ad>ntese

- Casos bloqueantes triados: 34.
- PIDs sem body v<c3><a1>lido na fila de falhas: 30.
- PIDs em pares com hash duplicado: 4.
- Candidatos prov<c3><a1>veis a ledger de exclus<c3><a3>o ap<c3><b3>s revis<c3><a3>o humana: 25.
- Casos que exigem checagem manual de fonte/metadado ou duplicidade: 9.

Esta triagem n<c3><a3>o altera `excluded_articles.csv` nem o corpus processado. Ela apenas organiza os bloqueios para decis<c3><a3>o manual rastre<c3><a1>vel.

## Tabela 1. Casos por tipo de bloqueio e a<c3><a7><c3><a3>o recomendada

blocking_type | recommended_action | triage_class | n
--- | --- | --- | ---
duplicate_hash | manual_compare_duplicate_body_and_source | duplicate_hash_manual_check |  4
missing_or_invalid_body | review_for_excluded_articles_ledger | exclude_candidate_editorial_front_matter | 17
missing_or_invalid_body | review_for_excluded_articles_ledger | exclude_candidate_errata |  4
missing_or_invalid_body | review_for_excluded_articles_ledger | exclude_candidate_obituary_or_homage |  3
missing_or_invalid_body | manual_check_source_or_metadata | manual_check_short_text |  3
missing_or_invalid_body | manual_check_source_or_metadata | manual_check_blank_title_short_text |  2
missing_or_invalid_body | review_for_excluded_articles_ledger | exclude_candidate_review_or_critical_note |  1

## Tabela 2. Casos por peri<c3><b3>dico

blocking_type | journal_title | n
--- | --- | ---
duplicate_hash | Dados |  4
missing_or_invalid_body | Revista de Administração Pública | 11
missing_or_invalid_body | Lua Nova: Revista de Cultura e Política |  9
missing_or_invalid_body | Novos estudos CEBRAP |  4
missing_or_invalid_body | Revista Brasileira de Ciências Sociais |  3
missing_or_invalid_body | Dados |  2
missing_or_invalid_body | Revista Brasileira de Política Internacional |  1

## Pr<c3><b3>ximas decis<c3><b5>es

1. Revisar os candidatos a exclus<c3><a3>o e, se confirmado que s<c3><a3>o erratas, apresenta<c3><a7><c3><b5>es, notas editoriais, homenagens ou cr<c3><ad>ticas curtas fora do escopo, registrar a decis<c3><a3>o em um ledger rastre<c3><a1>vel antes de rerodar a valida<c3><a7><c3><a3>o.
2. Checar manualmente os casos com t<c3><ad>tulo vazio ou curto sem marcador expl<c3><ad>cito de tipo documental.
3. Comparar os pares duplicados por `source_url`, `input_hash` e conte<c3><ba>do bruto para decidir se s<c3><a3>o duplicatas reais do SciELO, alias de PID ou erro de extra<c3><a7><c3><a3>o.
4. S<c3><b3> declarar o fulltext corpus pronto para escala quando `scripts/17_validate_fulltext_corpus.R` n<c3><a3>o tiver bloqueios ou quando os bloqueios remanescentes estiverem documentados como exclus<c3><b5>es metodol<c3><b3>gicas.
