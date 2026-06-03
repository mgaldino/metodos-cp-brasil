# Fulltext gold recovery report

Generated at: 2026-06-03 19:51:00 -03

## Summary

- Expected gold PIDs: 175
- Gold PIDs found in `classifications_llm_main_analysis.csv`: 175
- Rows in processed fulltext CSV: 175
- Unique processed PIDs: 175
- Validated bodies: 175/175
- Failed or missing bodies: 0

## Recovery methods

- articlemeta_fulltexts_html: 171
- pdf_text_extraction: 3
- citation_xml_body: 1

## Blocking failures

None. All 175 gold/pilot PIDs have validated body text.

## Nonblocking suspicious cases

- `S0104-62762011000200010`: 859 words via articlemeta_fulltexts_html (low_word_count_but_valid)

## Validation rules

- All 175 PIDs from the gold/pilot CSV must be present.
- PIDs must be unique in the processed fulltext CSV.
- `body_text` must be non-empty and at least 3,000 characters / 600 words.
- `body_text` must be substantially larger than the longest available abstract.
- Text starting with references or composed mostly of a reference tail fails.
- Abstract, metadata, keywords and references are not accepted as body substitutes.

## Outputs

- Processed body text: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/data/processed/fulltext_gold/article_texts_gold.csv`
- Inventory: `/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/quality_reports/fulltext_gold_inventory.csv`
