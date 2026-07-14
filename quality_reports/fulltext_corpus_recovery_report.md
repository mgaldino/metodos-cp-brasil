# Fulltext corpus recovery report

Generated at: 2026-07-14 15:22:27 -03

## Summary

- Expected eligible PIDs from plan: 6672
- Eligible PIDs rebuilt from ledgers: 5426
- Rows in processed corpus fulltext CSV: 6642
- Unique processed PIDs: 6642
- Validated bodies: 5403/5426
- Row-level failed or missing bodies: 23
- Global validation failures: 7

## Recovery methods

- articlemeta_fulltexts_html: 5357
- pdf_text_extraction: 42
- citation_xml_body: 4

## Blocking failures

- eligible_row_count_not_6672: 5426
- processed_row_count_not_5426: 6642
- processed_unique_pid_count_not_5426: 6642
- processed_extra_pids: S0034-76122006000100002, S0034-76122006000100003, S0034-76122006000100004, S0034-76122006000100005, S0034-76122006000100006, S0034-76122006000100007, S0034-76122006000100008, S0034-76122006000200002, S0034-76122006000200003, S0034-76122006000200004, S0034-76122006000200005, S0034-76122006000200006, S0034-76122006000200007, S0034-76122006000200008, S0034-76122006000300002, S0034-76122006000300003, S0034-76122006000300004, S0034-76122006000300005, S0034-76122006000300006, S0034-76122006000300007, S0034-76122006000300008, S0034-76122006000300009, S0034-76122006000400001, S0034-76122006000400002, S0034-76122006000400003, S0034-76122006000400004, S0034-76122006000400005, S0034-76122006000400006, S0034-76122006000400007, S0034-76122006000400008, S0034-76122006000400009, S0034-76122006000400010, S0034-76122006000400011, S0034-76122006000400012, S0034-76122006000500002, S0034-76122006000500003, S0034-76122006000500004, S0034-76122006000500005, S0034-76122006000500006, S0034-76122006000500007, S0034-76122006000500008, S0034-76122006000500009, S0034-76122006000600003, S0034-76122006000600004, S0034-76122006000600005, S0034-76122006000600006, S0034-76122006000600007, S0034-76122006000600008, S0034-76122006000600009, S0034-76122006000600010
- processed_missing_pids: S0011-52582008000200001, S0011-52582013000100001, S0034-73292011000100001, S0101-33002006000200018, S0101-33002007000300018, S0101-33002010000200014, S0101-33002011000100014, S0102-64452006000100001, S0102-64452006000300001, S0102-64452006000400001, S0102-64452008000200001, S0102-64452008000300001, S0102-64452009000100001, S0102-64452009000100008, S0102-64452009000300002, S0102-64452011000300001, S0102-69092007000100001, S0102-69092009000100010, S0102-69092009000100019
- duplicate_input_hash_across_pids: S0011-52582014000200007, S0011-52582014000200008, S0011-52582025000400225, S0011-52582025000400230
- duplicate_body_hash_across_pids: S0011-52582014000200007, S0011-52582014000200008, S0011-52582025000400225, S0011-52582025000400230
- `S0011-52582008000200001` (Dados, 2008): missing_pid
- `S0011-52582013000100001` (Dados, 2013): missing_pid
- `S0011-52582014000200007` (Dados, 2014): duplicate_input_hash_across_pids;duplicate_body_hash_across_pids
- `S0011-52582014000200008` (Dados, 2014): duplicate_input_hash_across_pids;duplicate_body_hash_across_pids
- `S0011-52582025000400225` (Dados, 2025): duplicate_input_hash_across_pids;duplicate_body_hash_across_pids
- `S0011-52582025000400230` (Dados, 2025): duplicate_input_hash_across_pids;duplicate_body_hash_across_pids
- `S0034-73292011000100001` (Revista Brasileira de Política Internacional, 2011): missing_pid
- `S0101-33002006000200018` (Novos estudos CEBRAP, 2006): missing_pid
- `S0101-33002007000300018` (Novos estudos CEBRAP, 2007): missing_pid
- `S0101-33002010000200014` (Novos estudos CEBRAP, 2010): missing_pid
- `S0101-33002011000100014` (Novos estudos CEBRAP, 2011): missing_pid
- `S0102-64452006000100001` (Lua Nova: Revista de Cultura e Política, 2006): missing_pid
- `S0102-64452006000300001` (Lua Nova: Revista de Cultura e Política, 2006): missing_pid
- `S0102-64452006000400001` (Lua Nova: Revista de Cultura e Política, 2006): missing_pid
- `S0102-64452008000200001` (Lua Nova: Revista de Cultura e Política, 2008): missing_pid
- `S0102-64452008000300001` (Lua Nova: Revista de Cultura e Política, 2008): missing_pid
- `S0102-64452009000100001` (Lua Nova: Revista de Cultura e Política, 2009): missing_pid
- `S0102-64452009000100008` (Lua Nova: Revista de Cultura e Política, 2009): missing_pid
- `S0102-64452009000300002` (Lua Nova: Revista de Cultura e Política, 2009): missing_pid
- `S0102-64452011000300001` (Lua Nova: Revista de Cultura e Política, 2011): missing_pid
- `S0102-69092007000100001` (Revista Brasileira de Ciências Sociais, 2007): missing_pid
- `S0102-69092009000100010` (Revista Brasileira de Ciências Sociais, 2009): missing_pid
- `S0102-69092009000100019` (Revista Brasileira de Ciências Sociais, 2009): missing_pid

## Nonblocking suspicious cases

- `S0011-52582012000200009`: 826 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0011-52582014000200001`: 636 words via articlemeta_fulltexts_html (short_but_valid;low_word_count_but_valid)
- `S0034-73292005000100008`: 858 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0034-73292005000100009`: 1019 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0034-73292005000100010`: 972 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0034-73292007000200013`: 1173 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0034-73292008000200001`: 1090 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0034-73292008000200012`: 603 words via pdf_text_extraction (short_but_valid;low_word_count_but_valid)
- `S0034-73292009000100010`: 684 words via articlemeta_fulltexts_html (short_but_valid;low_word_count_but_valid)
- `S0034-73292009000100011`: 740 words via pdf_text_extraction (low_word_count_but_valid)
- `S0034-73292009000100012`: 843 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0034-73292011000100012`: 849 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0101-33002006000100001`: 747 words via articlemeta_fulltexts_html (short_but_valid;low_word_count_but_valid)
- `S0101-33002006000200001`: 905 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0101-33002006000200017`: 957 words via articlemeta_fulltexts_html (short_but_valid;low_word_count_but_valid)
- `S0101-33002007000200020`: 696 words via articlemeta_fulltexts_html (short_but_valid;low_word_count_but_valid)
- `S0101-33002008000100015`: 696 words via articlemeta_fulltexts_html (short_but_valid;low_word_count_but_valid)
- `S0101-33002012000100001`: 620 words via citation_xml_body (short_but_valid;low_word_count_but_valid)
- `S0102-64452006000200002`: 955 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0102-64452006000400002`: 628 words via articlemeta_fulltexts_html (short_but_valid;low_word_count_but_valid)
- `S0102-64452009000300001`: 630 words via articlemeta_fulltexts_html (short_but_valid;low_word_count_but_valid)
- `S0102-64452012000200001`: 998 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0102-69092007000100015`: 1155 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0102-85292008000200007`: 1125 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0103-33522012000300010`: 922 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0104-44782005000100002`: 967 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0104-44782006000100008`: 924 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0104-44782007000200001`: 644 words via pdf_text_extraction (short_but_valid;low_word_count_but_valid)
- `S0104-44782008000200001`: 984 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0104-44782008000200002`: 1179 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0104-44782008000200020`: 985 words via pdf_text_extraction (low_word_count_but_valid)
- `S0104-62762010000100010`: 840 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0104-62762010000200011`: 1021 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0104-62762011000200010`: 859 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0104-62762012000100012`: 1041 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0104-62762012000200013`: 963 words via articlemeta_fulltexts_html (low_word_count_but_valid)
- `S0104-62762013000100010`: 782 words via articlemeta_fulltexts_html (short_but_valid;low_word_count_but_valid)

## Validation rules

- All 5426 eligible PIDs rebuilt from raw metadata and exclusion ledgers must be present.
- PIDs must be unique in the processed fulltext CSV.
- `document_type` must be exactly `research-article`; excluded journals and article PIDs must be absent.
- Publication year must be compatible with the 2005-2025 corpus window.
- `body_text` must be non-empty and at least 3,000 characters / 600 words.
- Provenance fields (`source_method`, `source_url`, `input_path`, `input_hash`, `retrieved_at`) are mandatory.
- `input_path` must point to `data/raw/fulltext_corpus/`, and `input_hash` must match the preserved raw file.
- `input_hash` and `body_hash` must not be reused by multiple PIDs.
- `body_text` must contain at least four text blocks and cannot start with abstract/keyword front matter.
- `body_text` must be substantially larger than the longest available abstract.
- Text starting with references or composed mostly of a reference tail fails.
- Abstract, metadata, keywords and references are not accepted as body substitutes.
- Corpus validation fails if any processed row points to `fulltext_gold`.

## Outputs

- Processed body text: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/fulltext_corpus/article_texts_corpus.csv`
- Inventory: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/fulltext_corpus_inventory.csv`
