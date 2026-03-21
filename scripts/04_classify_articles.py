"""
04_classify_articles.py

Classifica artigos da amostra de validação usando a API Claude.
Lê XMLs, envia para a API com prompt de classificação, salva resultados.

Uso:
    python scripts/04_classify_articles.py

Configuração via variáveis de ambiente:
    ANTHROPIC_API_KEY: chave da API (obrigatória)
    CLASSIFY_MODEL: modelo a usar (default: claude-sonnet-4-20250514)
    CLASSIFY_BATCH_PAUSE: segundos entre requests (default: 1)

Requer: pip install anthropic
"""

import csv
import json
import logging
import os
import time
from datetime import datetime, timezone
from pathlib import Path

import anthropic

# --- Configuração ---

MODEL = os.environ.get("CLASSIFY_MODEL", "claude-sonnet-4-20250514")
BATCH_PAUSE = float(os.environ.get("CLASSIFY_BATCH_PAUSE", "1"))

PROJECT_DIR = Path(__file__).parent.parent
SAMPLE_CSV = PROJECT_DIR / "data" / "processed" / "sample_validation_sheet.csv"
XML_DIR = PROJECT_DIR / "data" / "processed" / "sample_xmls"
OUTPUT_DIR = PROJECT_DIR / "data" / "processed" / "classifications"
LOG_DIR = PROJECT_DIR / "data" / "raw" / "logs"

SYSTEM_PROMPT = """You are a research methodology classifier for political science articles published in Brazilian journals. You read full article texts (in Portuguese, English, or Spanish) and classify them along standardized research design dimensions.

For each article, return a JSON object with exactly these fields:

1. error_in_raw_text: "No Error", "Missing/Corrupt", or "Title/Text Mismatch"
2. subfield: "Comparative Politics", "International Relations", "Methodology and Formal Theory", "Political Theory and Philosophy", "Public Policy/Administration", "Other"
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


def setup_logging(run_timestamp: str) -> logging.Logger:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = LOG_DIR / f"04_classify_{run_timestamp}.log"
    logger = logging.getLogger("classify")
    logger.setLevel(logging.DEBUG)
    if logger.handlers:
        logger.handlers.clear()
    fmt = logging.Formatter("%(asctime)s | %(levelname)-7s | %(message)s",
                            datefmt="%Y-%m-%d %H:%M:%S")
    fh = logging.FileHandler(log_file, encoding="utf-8")
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(fmt)
    logger.addHandler(fh)
    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    ch.setFormatter(fmt)
    logger.addHandler(ch)
    return logger


def load_sample(path: Path) -> list[dict]:
    with open(path, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def read_xml_text(xml_path: Path) -> str:
    """Read XML and extract plain text content."""
    with open(xml_path, encoding="utf-8") as f:
        content = f.read()
    # Truncate to ~100k chars (~25k tokens) to stay within context limits
    if len(content) > 100_000:
        content = content[:100_000]
    return content


def classify_article(
    client: anthropic.Anthropic,
    title: str,
    fulltext: str,
    log: logging.Logger,
) -> dict | None:
    """Send article to Claude API for classification."""
    user_msg = USER_PROMPT_TEMPLATE.format(title=title, fulltext=fulltext)

    try:
        response = client.messages.create(
            model=MODEL,
            max_tokens=4096,
            system=SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_msg}],
        )
        text = response.content[0].text.strip()

        # Parse JSON from response (handle potential markdown wrapping)
        if text.startswith("```"):
            text = text.split("\n", 1)[1].rsplit("```", 1)[0].strip()

        return json.loads(text)

    except json.JSONDecodeError as e:
        log.warning("JSON parse error: %s\nRaw response: %s", e, text[:500])
        return None
    except anthropic.APIError as e:
        log.warning("API error: %s", e)
        return None


def main() -> None:
    run_timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    log = setup_logging(run_timestamp)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    log.info("=" * 60)
    log.info("Classificação de artigos via API Claude")
    log.info("Modelo: %s", MODEL)
    log.info("=" * 60)

    # Load sample
    sample = load_sample(SAMPLE_CSV)
    log.info("Artigos na amostra: %d", len(sample))

    # Check which are already classified (checkpoint)
    done_pids = set()
    for jf in OUTPUT_DIR.glob("*.json"):
        done_pids.add(jf.stem)
    log.info("Já classificados: %d", len(done_pids))

    remaining = [s for s in sample if s["pid"] not in done_pids]
    log.info("Restantes: %d", len(remaining))

    if not remaining:
        log.info("Todos os artigos já foram classificados.")
        return

    # Initialize API client
    client = anthropic.Anthropic()

    classified = 0
    errors = 0

    for i, article in enumerate(remaining):
        pid = article["pid"]
        title = article.get("title", "")
        xml_path = XML_DIR / f"{pid}.xml"

        if not xml_path.exists():
            log.warning("XML não encontrado: %s", pid)
            errors += 1
            continue

        log.info("[%d/%d] Classificando %s...", i + 1, len(remaining), pid)

        fulltext = read_xml_text(xml_path)
        result = classify_article(client, title, fulltext, log)

        if result:
            result["pid"] = pid
            # Save individual result
            out_file = OUTPUT_DIR / f"{pid}.json"
            with open(out_file, "w", encoding="utf-8") as f:
                json.dump(result, f, ensure_ascii=False, indent=2)
            classified += 1
            log.info("  -> %s | empirical=%s | design=%s",
                     result.get("subfield", "?"),
                     result.get("is_empirical_quant_paper", "?"),
                     result.get("main_causal_research_design", "?"))
        else:
            errors += 1
            log.warning("  -> FALHA na classificação de %s", pid)

        time.sleep(BATCH_PAUSE)

    # Consolidate all results into single CSV
    log.info("Consolidando resultados...")
    all_results = []
    for jf in sorted(OUTPUT_DIR.glob("*.json")):
        with open(jf, encoding="utf-8") as f:
            all_results.append(json.load(f))

    if all_results:
        # Write consolidated CSV
        csv_out = PROJECT_DIR / "data" / "processed" / "classifications_llm.csv"
        fieldnames = list(all_results[0].keys())
        # Ensure pid is first
        if "pid" in fieldnames:
            fieldnames.remove("pid")
            fieldnames.insert(0, "pid")

        with open(csv_out, "w", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames,
                                    restval="", extrasaction="ignore")
            writer.writeheader()
            for r in all_results:
                # Flatten complex fields for CSV
                row = {}
                for k, v in r.items():
                    if isinstance(v, (list, dict)):
                        row[k] = json.dumps(v, ensure_ascii=False)
                    else:
                        row[k] = v
                writer.writerow(row)

        log.info("CSV consolidado: %s (%d artigos)", csv_out, len(all_results))

    # Summary
    log.info("=" * 60)
    log.info("RESUMO")
    log.info("=" * 60)
    log.info("Classificados nesta execução: %d", classified)
    log.info("Erros: %d", errors)
    log.info("Total classificados: %d/%d", len(all_results), len(sample))


if __name__ == "__main__":
    main()
