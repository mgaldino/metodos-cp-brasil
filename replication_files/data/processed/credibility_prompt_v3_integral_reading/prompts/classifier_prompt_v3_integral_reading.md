# Credibility Prompt v3 - Integral Reading Batch Prompt

You are classifying exactly one article in this run.

## Absolute Rule: Integral Reading Before Classification

You must read the full article body from beginning to end before classifying it.

It is prohibited to classify by:

- regexes, scripts, keyword matching, heuristics, or automated rules;
- previous consensus labels, gold labels, auxiliary classifications, or journal priors;
- title, abstract, metadata, isolated tables, or selected excerpts alone;
- guessing from the journal, year, topic, or style.

The purpose of this task is interpretive article-by-article classification, not scale automation. If the article is long, keep reading until the end. Do not substitute a shortcut for full reading.

If you cannot read the full body text, return `status: "incomplete"`, set `full_body_read: false`, explain why in `incomplete_reason`, and set `classification: null`. Do not produce a final classification for an article you did not read fully.

## Mandatory Reading Log Before Classification

Before producing the classification, build a `section_reading_log`. This log is part of the required JSON output.

For each section explicitly present in the paper, include:

- `section_title`: the section heading as it appears in the article;
- `section_position`: 1-based section order;
- `section_summary`: one or two substantive paragraphs summarizing what the section argues or does;
- `methods_or_data_mentions`: one paragraph identifying data, methods, tables, figures, interviews, documents, models, tests, or stating that none appear in the section;
- `classification_relevance`: one paragraph explaining how this section matters, or does not matter, for empirical/quantitative/qualitative/causal/statistical classification.

If the article has no clear section headings, divide the body into sequential chunks and use `chunk_1`, `chunk_2`, etc. as section titles. Still summarize every chunk.

After the section log, write:

- `general_summary`: one or two paragraphs summarizing the paper as a whole;
- `decision_audit`: answers to the final audit questions listed below.

Only after completing these steps may you fill the `classification` object.

## Final Audit Questions

Answer these in `decision_audit` before classification:

1. Where does the article present its own empirical evidence, if anywhere?
2. Where does the article present original or reanalyzed quantitative analysis, if anywhere?
3. Where does the article present substantive qualitative evidence, if anywhere?
4. Where does the article report statistical inference, if anywhere?
5. Where does the article present a causal or credibility-revolution design, if anywhere?
6. Is there any section that contradicts the likely classification?

## Output Shape

Return exactly one valid JSON object and no text outside the JSON.

Top-level required fields:

- `pid`
- `title`
- `journal_title`
- `input_text_hash`
- `status`: `"complete"` or `"incomplete"`
- `full_body_read`: boolean
- `incomplete_reason`: string or null
- `section_reading_log`: array
- `general_summary`: string
- `decision_audit`: object
- `classification`: object if `status == "complete"`, otherwise null

The nested `classification` object must follow the original credibility prompt v3 schema exactly.

## Original Classifier Prompt v3

The following classifier instructions define the classification schema and field meanings. They are binding, but they do not override the integral-reading rule above.

{{CLASSIFIER_PROMPT_V3}}

## Output Reconciliation

The original prompt v3 above describes the fields of the nested `classification` object.
When it says to return one JSON object, that object must be placed inside the top-level
object required by this integral-reading prompt. Your final response must always have
the top-level fields `section_reading_log`, `general_summary`, `decision_audit`, and
`classification`.

## Article Task Packet

The task packet below contains the article metadata and full body text. Use only this packet for substantive classification.

{{TASK_PACKET}}
