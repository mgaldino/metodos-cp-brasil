"""
classify_batch.py

Classifica um lote de artigos via API Claude.
Uso: python scripts/classify_batch.py <batch_file.txt>
"""

import csv
import json
import os
import sys
import time
from pathlib import Path

import anthropic

MODEL = "claude-sonnet-4-20250514"
BATCH_PAUSE = 1.0

PROJECT_DIR = Path(__file__).parent.parent
SAMPLE_CSV = PROJECT_DIR / "data" / "processed" / "sample_validation_sheet.csv"
XML_DIR = PROJECT_DIR / "data" / "processed" / "sample_xmls"
OUTPUT_DIR = PROJECT_DIR / "data" / "processed" / "classifications"

SYSTEM_PROMPT = """You are a research methodology classifier for political science articles published in Brazilian journals. You read full article texts (in Portuguese, English, or Spanish) and classify them along standardized research design dimensions.

For each article, return a JSON object with exactly these fields:

1. error_in_raw_text: "No Error", "Missing/Corrupt", or "Title/Text Mismatch"
2. subfield: "Brazilian Politics", "Comparative Politics", "International Relations", "Methodology and Formal Theory", "Political Theory and Philosophy", "Public Policy/Administration", "Other" — Use "Brazilian Politics" for articles focused on Brazil's domestic politics (elections, parties, legislature, federalism, public opinion, etc.). Use "Comparative Politics" for cross-country studies or single-country studies of countries other than Brazil.
3. is_empirical_quant_paper: true if it conducts its own analysis of observational or experimental data; false otherwise
4. general_goal_of_analysis: "Describe", "Predict", "Explain", or null (null if not empirical)
5. single_country_study: "single_country", "multiple_countries", or null
6. single_region: "single_region", "multiple_region", or null
7. countries_of_focus: semicolon-separated country names, or null
8. paper_uses_survey_data: "no_survey_data", "runs_original_survey", "uses_public_available_survey"
9. uses_original_dataset: "original_survey", "field_experiment", "field_study", "structure_systematize", "procure_original_data", "other_original_data", "not_original", or null
10. seeks_determinants: true/false/null — true if the paper investigates which factors explain variation in an outcome
11. main_causal_research_design: "Field Experiment", "Survey Experiment", "Lab Experiment", "Diff-in-Diff", "Instrumental Variable", "Regression Discontinuity Design", "Regression Kink Design", "Synthetic Control", "Matching/Weighting/Balancing", "Kitchen Sink Linear Model", "Multiple Designs", "Other", or null
12. other_research_design: string description if main_causal_research_design is "Other" or "Multiple Designs"; null otherwise
13. instrumental_variable_instrument: concise name of instrument if IV design; null otherwise
14. placebo_test: true/false/null
15. independent_variables: array of {"variable_name": str, "variable_description": str} or null
16. dependent_variables: array of {"variable_name": str, "variable_description": str} or null
17. main_variable_relationship: array of {"iv_var_name": str, "dv_var_name": str, "relationship_type": "Positive"/"Negative"/"Non-Monotonic"/"Null"/"Unknown", "statistically_significant": bool, "substantively_significant": bool} or null
18. makes_explicit_causal_claim: true/false/null — uses terms like "causes", "effect", "impact"
19. makes_implicit_causal_claim: true/false/null — frames contribution causally without explicit terms
20. strong_non_causal_causal_qualification: true/false/null — explicitly states relationship is NOT causal
21. sample_size: integer or null (do NOT guess; null if unclear)
22. sample_size_quote: exact quote from text used to determine sample size, or null
23. claims_any_statistically_significant_results: true/false/null
24. references_power_analysis: true/false/null
25. clearly_defined_explanatory_variable: true/false/null
26. clear_causal_quantity_of_interest: one of "ATE", "ATT", "ATC", "LATE", "CATE", "ITT", "FALSE", or null
27. specifies_estimate_equations: true/false/null
28. discusses_threats_to_causality: true/false/null
29. statement_of_identification_assumptions_quote: exact quote(s) mentioning identification assumptions, or null
30. statement_of_identification_assumptions: true/false/null
31. effort_to_explore_mechanisms: "No Mention of Mechanisms/Channels", "Mechanisms/Channels Mentioned But Not Explored", "Mechanisms/Channels Mentioned With Substantial Exploration", or null
32. mentions_pre_registered_design_and_analysis_plan: true/false/null
33. evidence_type: "quantitative", "qualitative", "mixed", "theoretical-normative"
34. method_status: "explicit" (clearly states and justifies method) or "essayistic" (no explicit method section)
35. brief_justification: 2-3 sentences explaining your classification

Return ONLY valid JSON. No markdown, no commentary outside the JSON."""

USER_PROMPT_TEMPLATE = """<!--begin excerpt-->
Paper Title:
{title}
==============================
Paper Full TEXT:
{fulltext}
<!--end excerpt-->

You are given the full text of a political science paper above. Read it carefully. Then extract the requisite fields following the system guidelines, returning them in valid JSON."""


def main():
    if len(sys.argv) < 2:
        print("Usage: python classify_batch.py <batch_file.txt>")
        sys.exit(1)

    batch_file = Path(sys.argv[1])
    pids = [line.strip() for line in batch_file.read_text().splitlines() if line.strip()]

    # Load sample CSV for titles
    titles = {}
    with open(SAMPLE_CSV, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            titles[row["pid"]] = row.get("title", "")

    # Skip already classified
    done = {p.stem for p in OUTPUT_DIR.glob("*.json")}
    remaining = [pid for pid in pids if pid not in done]
    print(f"Batch: {len(pids)} total, {len(done & set(pids))} already done, {len(remaining)} to classify")

    if not remaining:
        print("All articles already classified.")
        return

    client = anthropic.Anthropic()
    classified = 0
    errors = 0

    for i, pid in enumerate(remaining):
        xml_path = XML_DIR / f"{pid}.xml"
        if not xml_path.exists():
            print(f"  [{i+1}/{len(remaining)}] SKIP {pid} — XML not found")
            errors += 1
            continue

        print(f"  [{i+1}/{len(remaining)}] Classifying {pid}...", end=" ", flush=True)

        fulltext = xml_path.read_text(encoding="utf-8")
        if len(fulltext) > 100_000:
            fulltext = fulltext[:100_000]

        title = titles.get(pid, "")
        user_msg = USER_PROMPT_TEMPLATE.format(title=title, fulltext=fulltext)

        try:
            response = client.messages.create(
                model=MODEL,
                max_tokens=4096,
                system=SYSTEM_PROMPT,
                messages=[{"role": "user", "content": user_msg}],
            )
            text = response.content[0].text.strip()
            if text.startswith("```"):
                text = text.split("\n", 1)[1].rsplit("```", 1)[0].strip()

            result = json.loads(text)
            result["pid"] = pid

            out_file = OUTPUT_DIR / f"{pid}.json"
            with open(out_file, "w", encoding="utf-8") as f:
                json.dump(result, f, ensure_ascii=False, indent=2)

            classified += 1
            print(f"OK — {result.get('subfield', '?')} | empirical={result.get('is_empirical_quant_paper', '?')}")

        except json.JSONDecodeError as e:
            errors += 1
            print(f"JSON ERROR: {e}")
        except anthropic.APIError as e:
            errors += 1
            print(f"API ERROR: {e}")

        time.sleep(BATCH_PAUSE)

    print(f"\nDone: {classified} classified, {errors} errors")


if __name__ == "__main__":
    main()
