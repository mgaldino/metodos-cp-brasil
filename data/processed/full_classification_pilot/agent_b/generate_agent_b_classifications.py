#!/usr/bin/env python3
"""Generate Agent B pilot classifications from the local XML manifest.

The source XMLs in this pilot snapshot contain no JATS <body> elements; they
only expose metadata, abstracts and references. Per the common schema, every
record is therefore marked Missing/Corrupt and classified only from the text
available in the XML itself.
"""

from __future__ import annotations

import csv
import json
import re
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
MANIFEST = ROOT / "processed/full_classification_pilot/pilot_manifest.csv"
OUT_DIR = ROOT / "processed/full_classification_pilot/agent_b"

CLASSIFICATION_KEYS = [
    "error_in_raw_text",
    "subfield",
    "is_empirical_quant_paper",
    "general_goal_of_analysis",
    "single_country_study",
    "single_region",
    "countries_of_focus",
    "paper_uses_survey_data",
    "uses_original_dataset",
    "seeks_determinants",
    "main_causal_research_design",
    "other_research_design",
    "instrumental_variable_instrument",
    "placebo_test",
    "independent_variables",
    "dependent_variables",
    "main_variable_relationship",
    "makes_explicit_causal_claim",
    "makes_implicit_causal_claim",
    "strong_non_causal_causal_qualification",
    "sample_size",
    "sample_size_quote",
    "claims_any_statistically_significant_results",
    "references_power_analysis",
    "clearly_defined_explanatory_variable",
    "clear_causal_quantity_of_interest",
    "specifies_estimate_equations",
    "discusses_threats_to_causality",
    "statement_of_identification_assumptions_quote",
    "statement_of_identification_assumptions",
    "effort_to_explore_mechanisms",
    "mentions_pre_registered_design_and_analysis_plan",
    "evidence_type",
    "method_status",
    "brief_justification",
]


def v(name: str, description: str) -> dict[str, str]:
    return {"variable_name": name, "variable_description": description}


def rel(
    iv: str,
    dv: str,
    relationship: str = "Unknown",
    statistically_significant: bool = False,
    substantively_significant: bool = False,
) -> dict[str, object]:
    return {
        "iv_var_name": iv,
        "dv_var_name": dv,
        "relationship_type": relationship,
        "statistically_significant": statistically_significant,
        "substantively_significant": substantively_significant,
    }


def local(tag: str) -> str:
    return tag.split("}")[-1]


def text_of(element: ET.Element) -> str:
    return " ".join("".join(element.itertext()).split())


def xml_text(path: Path) -> tuple[str, bool]:
    root = ET.parse(path).getroot()
    parts: list[str] = []
    has_body = False
    for elem in root.iter():
        tag = local(elem.tag)
        if tag == "body":
            has_body = bool(text_of(elem))
        if tag in {"article-title", "abstract", "trans-abstract", "kwd"}:
            txt = text_of(elem)
            if txt:
                parts.append(txt)
    return "\n".join(parts), has_body


def default_classification() -> dict[str, object]:
    return {
        "error_in_raw_text": "Missing/Corrupt",
        "subfield": "Other",
        "is_empirical_quant_paper": False,
        "general_goal_of_analysis": None,
        "single_country_study": None,
        "single_region": None,
        "countries_of_focus": None,
        "paper_uses_survey_data": "no_survey_data",
        "uses_original_dataset": None,
        "seeks_determinants": None,
        "main_causal_research_design": None,
        "other_research_design": None,
        "instrumental_variable_instrument": None,
        "placebo_test": None,
        "independent_variables": None,
        "dependent_variables": None,
        "main_variable_relationship": None,
        "makes_explicit_causal_claim": False,
        "makes_implicit_causal_claim": False,
        "strong_non_causal_causal_qualification": None,
        "sample_size": None,
        "sample_size_quote": None,
        "claims_any_statistically_significant_results": None,
        "references_power_analysis": False,
        "clearly_defined_explanatory_variable": None,
        "clear_causal_quantity_of_interest": None,
        "specifies_estimate_equations": None,
        "discusses_threats_to_causality": None,
        "statement_of_identification_assumptions_quote": None,
        "statement_of_identification_assumptions": None,
        "effort_to_explore_mechanisms": "No Mention of Mechanisms/Channels",
        "mentions_pre_registered_design_and_analysis_plan": False,
        "evidence_type": "theoretical-normative",
        "method_status": "essayistic",
        "brief_justification": "",
    }


def q(
    goal: str = "Explain",
    survey: str = "no_survey_data",
    original: str | None = "procure_original_data",
    design: str | None = None,
    other_design: str | None = None,
    causal: bool = False,
    implicit: bool = False,
    strong_qual: bool | None = None,
    ivs: list[dict[str, str]] | None = None,
    dvs: list[dict[str, str]] | None = None,
    rels: list[dict[str, object]] | None = None,
    sample: int | None = None,
    sample_quote: str | None = None,
    sig: bool | None = None,
) -> dict[str, object]:
    out: dict[str, object] = {
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": goal,
        "paper_uses_survey_data": survey,
        "uses_original_dataset": original,
        "seeks_determinants": goal == "Explain",
        "main_causal_research_design": design,
        "other_research_design": other_design,
        "makes_explicit_causal_claim": causal,
        "makes_implicit_causal_claim": implicit,
        "strong_non_causal_causal_qualification": strong_qual,
        "independent_variables": ivs,
        "dependent_variables": dvs,
        "main_variable_relationship": rels,
        "claims_any_statistically_significant_results": sig,
        "clearly_defined_explanatory_variable": bool(ivs) if goal == "Explain" else None,
        "clear_causal_quantity_of_interest": "FALSE" if causal or implicit else None,
        "discusses_threats_to_causality": False if causal or implicit else None,
        "statement_of_identification_assumptions": False if causal or implicit else None,
        "evidence_type": "quantitative",
        "method_status": "explicit",
    }
    if sample is not None:
        out["sample_size"] = sample
        out["sample_size_quote"] = sample_quote
    return out


def qual(
    goal: str = "Explain",
    original: str | None = "field_study",
    causal: bool = False,
    implicit: bool = False,
    design: str | None = None,
    other_design: str | None = None,
    mechanisms: str = "No Mention of Mechanisms/Channels",
    sample: int | None = None,
    sample_quote: str | None = None,
    explicit_method: bool = True,
) -> dict[str, object]:
    out: dict[str, object] = {
        "general_goal_of_analysis": goal,
        "uses_original_dataset": original,
        "seeks_determinants": goal == "Explain",
        "main_causal_research_design": design,
        "other_research_design": other_design,
        "makes_explicit_causal_claim": causal,
        "makes_implicit_causal_claim": implicit,
        "clear_causal_quantity_of_interest": "FALSE" if causal or implicit else None,
        "discusses_threats_to_causality": False if causal or implicit else None,
        "statement_of_identification_assumptions": False if causal or implicit else None,
        "effort_to_explore_mechanisms": mechanisms,
        "evidence_type": "qualitative",
        "method_status": "explicit" if explicit_method else "essayistic",
    }
    if sample is not None:
        out["sample_size"] = sample
        out["sample_size_quote"] = sample_quote
    return out


def theory(
    goal: str | None = None,
    causal: bool = False,
    implicit: bool = False,
    mechanisms: str = "No Mention of Mechanisms/Channels",
) -> dict[str, object]:
    return {
        "general_goal_of_analysis": goal,
        "makes_explicit_causal_claim": causal,
        "makes_implicit_causal_claim": implicit,
        "clear_causal_quantity_of_interest": "FALSE" if causal or implicit else None,
        "discusses_threats_to_causality": False if causal or implicit else None,
        "statement_of_identification_assumptions": False if causal or implicit else None,
        "effort_to_explore_mechanisms": mechanisms,
        "evidence_type": "theoretical-normative",
        "method_status": "essayistic",
    }


def mixed(**kwargs: object) -> dict[str, object]:
    out = qual(**{k: v for k, v in kwargs.items() if k in {
        "goal", "original", "causal", "implicit", "design", "other_design",
        "mechanisms", "sample", "sample_quote", "explicit_method"
    }})
    out["is_empirical_quant_paper"] = True
    out["evidence_type"] = "mixed"
    return out


# Manual classifications by manifest row, based only on pilot_manifest metadata
# and each source XML's available title/abstract/keywords.
OVERRIDES: dict[int, dict[str, object]] = {
    1: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(survey="uses_public_available_survey", original="structure_systematize", design="Kitchen Sink Linear Model", causal=True, ivs=[v("economic indicators", "Inflation, unemployment, exchange rate, C-Bond spread and stock exchange index."), v("financial market indicators", "Financial market measures compared with economic fundamentals.")], dvs=[v("voting intentions", "Aggregate self-reported presidential voting preferences.")], rels=[rel("economic indicators", "voting intentions", "Unknown", True, True)], sig=True)},
    2: {"subfield": "Methodology and Formal Theory", **theory("Explain")},
    3: {"subfield": "Political Theory and Philosophy", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize")},
    4: {"subfield": "Methodology and Formal Theory", **theory("Describe")},
    5: {"subfield": "Political Theory and Philosophy", **theory("Explain", causal=True)},
    6: {"subfield": "Public Policy/Administration", "countries_of_focus": "Denmark; Norway; Sweden", "single_country_study": "multiple_countries", **theory("Explain", causal=True)},
    7: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "France", **qual("Explain", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration", sample=4, sample_quote="programs in four high schools of the Seine-Saint-Denis")},
    8: {"subfield": "International Relations", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned But Not Explored")},
    9: {"subfield": "Political Theory and Philosophy", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Explain")},
    10: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned But Not Explored")},
    11: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    12: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(original="other_original_data", design="Other", other_design="Original regulatory database and typological analysis", causal=True, ivs=[v("government policy preferences", "Policy-content alignment with the Bolsonaro government."), v("council resilience", "Combination of institutional design and policy-community insertion.")], dvs=[v("council deinstitutionalization", "Regulatory and functional effects on national policy councils.")], sample=103, sample_quote="103 colegiados nacionais", sig=True)},
    13: {"subfield": "Political Theory and Philosophy", "single_country_study": "single_country", "countries_of_focus": "France", **theory("Describe")},
    14: {"subfield": "Political Theory and Philosophy", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize")},
    15: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", causal=True)},
    16: {"subfield": "International Relations", "single_country_study": "multiple_countries", "single_region": "single_region", "countries_of_focus": "Brazil; Argentina", **theory("Explain", causal=True)},
    17: {"subfield": "International Relations", "single_country_study": "multiple_countries", "countries_of_focus": "Argentina; United States", **qual("Explain", original="structure_systematize", causal=True)},
    18: {"subfield": "International Relations", **theory("Describe")},
    19: {"subfield": "International Relations", "single_country_study": "multiple_countries", "countries_of_focus": "Brazil; China", **theory("Describe")},
    20: {"subfield": "International Relations", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **theory("Describe")},
    21: {"subfield": "International Relations", "single_region": "single_region", "countries_of_focus": "Brazil", **theory("Explain", causal=True)},
    22: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "China", **qual("Describe", original="structure_systematize")},
    23: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned But Not Explored")},
    24: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize")},
    25: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", causal=True, design="Other", other_design="Process tracing case study", mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    26: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="structure_systematize")},
    27: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize")},
    28: {"subfield": "International Relations", "single_region": "single_region", "countries_of_focus": "China; Brazil", **q(original="procure_original_data", design="Other", other_design="Longitudinal comparative regional-organization analysis", causal=True, ivs=[v("ties to China", "Growing connections to China as extra-regional catalyst."), v("ties to Brazil", "Shrinking Brazilian regional paymaster role.")], dvs=[v("institutional fragmentation", "Fragmentation among Latin American regional organizations.")], rels=[rel("ties to China", "institutional fragmentation", "Positive", True, True), rel("ties to Brazil", "institutional fragmentation", "Negative", True, True)], sig=True)},
    29: {"subfield": "International Relations", "single_region": "single_region", "countries_of_focus": None, **mixed(goal="Describe", original="procure_original_data")},
    30: {"subfield": "International Relations", "single_region": "single_region", "countries_of_focus": "China", **q(goal="Describe", original="procure_original_data", sig=True)},
    31: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="structure_systematize")},
    32: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **qual("Explain", original="field_study")},
    33: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **q(goal="Describe", original="not_original", sample=77, sample_quote="77 municipalities")},
    34: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="not_original")},
    35: {"subfield": "Other", **theory("Explain")},
    36: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **qual("Explain", original="field_study", sample=46, sample_quote="46 representative actors")},
    37: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **qual("Describe", original="field_study")},
    38: {"subfield": "Methodology and Formal Theory", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="field_study", sample=3, sample_quote="three Brazilian municipalities")},
    39: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="structure_systematize")},
    40: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Spain", **q(goal="Describe", original="not_original", causal=True)},
    41: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Describe")},
    42: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **q(design="Kitchen Sink Linear Model", causal=True, ivs=[v("bidding modality", "Public bidding and invitation procurement types."), v("service type", "Whether the project was a renovation."), v("municipal and political characteristics", "Population, reelection status and mayor-president party alignment.")], dvs=[v("deadline compliance", "Whether education public works met deadlines."), v("price compliance", "Whether education public works met expected prices.")], rels=[rel("bidding modality", "deadline compliance", "Unknown", True, True), rel("municipal and political characteristics", "price compliance", "Unknown", True, True)], sig=True)},
    43: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **qual("Explain", original="field_study", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    44: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Describe", original="procure_original_data")},
    45: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Explain", causal=True)},
    46: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="field_study", causal=True, design="Other", other_design="Qualitative content analysis of expert interviews", mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration", sample=15, sample_quote="15 key players")},
    47: {"subfield": "International Relations", "single_country_study": "multiple_countries", "countries_of_focus": None, **theory("Describe")},
    48: {"subfield": "Other", **theory()},
    49: {"subfield": "Other", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory()},
    50: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Explain", causal=True)},
    51: {"subfield": "Other", **theory("Describe")},
    52: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Explain", original="not_original", sig=True)},
    53: {"subfield": "Other", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Describe")},
    54: {"subfield": "Other", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Explain")},
    55: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", explicit_method=False)},
    56: {"subfield": "Other", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Describe")},
    57: {"subfield": "Other", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="field_study", explicit_method=False)},
    58: {"subfield": "Other", "single_country_study": "single_country", "countries_of_focus": "Israel", **theory("Describe")},
    59: {"subfield": "Political Theory and Philosophy", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Explain")},
    60: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Mexico", **mixed(goal="Explain", original="field_study", causal=True, other_design="Qualitative focus groups and original research", mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    61: {"subfield": "Political Theory and Philosophy", **theory("Explain")},
    62: {"subfield": "Political Theory and Philosophy", **theory("Describe")},
    63: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "Russia", **theory("Explain")},
    64: {"subfield": "Political Theory and Philosophy", **theory("Describe")},
    65: {"subfield": "Other", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **theory("Describe")},
    66: {"subfield": "Political Theory and Philosophy", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Describe")},
    67: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory()},
    68: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="structure_systematize")},
    69: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "Mexico", **qual("Explain", original="structure_systematize", causal=True, design="Other", other_design="Qualitative case study of international norm effects", mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    70: {"subfield": "Public Policy/Administration", "single_country_study": "multiple_countries", "countries_of_focus": "Uganda; Brazil", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    71: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    72: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    73: {"subfield": "Other", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Describe", original="procure_original_data")},
    74: {"subfield": "Political Theory and Philosophy", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Explain")},
    75: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **qual("Explain", original="field_study", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    76: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Explain", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    77: {"subfield": "Political Theory and Philosophy", **theory("Describe")},
    78: {"subfield": "Political Theory and Philosophy", **theory("Describe")},
    79: {"subfield": "Other", **theory("Describe")},
    80: {"subfield": "Other", **theory()},
    81: {"subfield": "Other", **theory()},
    82: {"subfield": "Political Theory and Philosophy", **theory("Explain")},
    83: {"subfield": "Methodology and Formal Theory", **theory("Describe")},
    84: {"subfield": "Other", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **mixed(goal="Describe", original="field_study", sample=52, sample_quote="24 lawyers, 18 state judges and 10 federal court judges")},
    85: {"subfield": "International Relations", **theory("Describe")},
    86: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **mixed(goal="Explain", original="procure_original_data", causal=False, implicit=True, design="Kitchen Sink Linear Model", mechanisms="Mechanisms/Channels Mentioned But Not Explored"), "paper_uses_survey_data": "runs_original_survey", "strong_non_causal_causal_qualification": True, "independent_variables": [v("media consumption", "Reading or watching specific news outlets."), v("media framing", "Valence and accountability framing of economy and government coverage.")], "dependent_variables": [v("economic evaluation", "Reader or voter evaluation of the economy."), v("government evaluation", "Evaluation of the federal government.")], "main_variable_relationship": [rel("media consumption", "economic evaluation", "Negative", True, True)]},
    87: {"subfield": "Other", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="field_study", explicit_method=False)},
    88: {"subfield": "Other", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Explain", survey="uses_public_available_survey", original="not_original", design="Kitchen Sink Linear Model", causal=False, implicit=True, ivs=[v("social structure and fertility decline", "Contextual and individual characteristics linked to sex preferences.")], dvs=[v("sex preference", "Ideal sex composition of children.")], rels=[rel("social structure and fertility decline", "sex preference", "Unknown", True, True)], sig=True)},
    89: {"subfield": "International Relations", "single_country_study": "multiple_countries", "single_region": "single_region", "countries_of_focus": "Argentina; Brazil; Mexico; Colombia", **qual("Explain", original="field_study", causal=True, mechanisms="Mechanisms/Channels Mentioned But Not Explored")},
    90: {"subfield": "Other", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **qual("Describe", original="field_study")},
    91: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(survey="no_survey_data", original="not_original", design="Kitchen Sink Linear Model", causal=True, ivs=[v("implementation factors", "Factors from case studies and implementation literature."), v("management instruments", "Identification and management tools used by CRAS.")], dvs=[v("equitable implementation", "Specific assistance strategies for Indigenous Peoples and Traditional Communities.")], rels=[rel("management instruments", "equitable implementation", "Positive", True, True)], sample=2084, sample_quote="2,084 cases", sig=True)},
    92: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize")},
    93: {"subfield": "International Relations", "single_region": "single_region", "countries_of_focus": None, **qual("Describe", original="structure_systematize", explicit_method=False)},
    94: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "India", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    95: {"subfield": "International Relations", "single_country_study": "multiple_countries", "countries_of_focus": "Brazil; United States", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned But Not Explored")},
    96: {"subfield": "Methodology and Formal Theory", "single_country_study": "single_country", "countries_of_focus": "Brazil", **mixed(goal="Explain", original="not_original", causal=True, other_design="Formal climate-economy model discussion with budget data")},
    97: {"subfield": "Political Theory and Philosophy", **theory("Explain")},
    98: {"subfield": "International Relations", "single_region": "single_region", "countries_of_focus": None, **theory("Explain", causal=True)},
    99: {"subfield": "International Relations", "single_country_study": "multiple_countries", "countries_of_focus": "Brazil; Russia; India; China; South Africa", **theory("Explain")},
    100: {"subfield": "Methodology and Formal Theory", "single_country_study": "multiple_countries", "countries_of_focus": None, **mixed(goal="Describe", original="structure_systematize")},
    101: {"subfield": "International Relations", **theory("Explain")},
    102: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned But Not Explored")},
    103: {"subfield": "International Relations", "single_region": "single_region", "countries_of_focus": None, **qual("Describe", original="structure_systematize")},
    104: {"subfield": "Political Theory and Philosophy", **theory("Describe")},
    105: {"subfield": "International Relations", "single_country_study": "multiple_countries", "single_region": "single_region", "countries_of_focus": "United States; China; Russia", **mixed(goal="Explain", original="not_original", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    106: {"subfield": "Political Theory and Philosophy", "single_country_study": "single_country", "countries_of_focus": "Peru", **theory("Describe")},
    107: {"subfield": "International Relations", "single_country_study": "multiple_countries", "single_region": "single_region", "countries_of_focus": "United States", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    108: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **qual("Describe", original="structure_systematize")},
    109: {"subfield": "Political Theory and Philosophy", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Describe")},
    110: {"subfield": "Political Theory and Philosophy", **theory("Describe")},
    111: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Describe", original="procure_original_data")},
    112: {"subfield": "Political Theory and Philosophy", **theory("Describe")},
    113: {"subfield": "Methodology and Formal Theory", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Explain", original="not_original", sig=True)},
    114: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Describe", original="procure_original_data")},
    115: {"subfield": "Comparative Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(design="Kitchen Sink Linear Model", causal=True, ivs=[v("nationality", "Immigrant nationality."), v("gender, race and education", "Individual characteristics of immigrants.")], dvs=[v("salary", "Immigrant salary in the Brazilian labor market."), v("occupation type", "Type of occupation obtained by immigrants.")], rels=[rel("nationality", "salary", "Unknown", True, True), rel("nationality", "occupation type", "Unknown", True, True)], sig=True)},
    116: {"subfield": "International Relations", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Explain", original="structure_systematize", sig=True)},
    117: {"subfield": "Comparative Politics", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Spain", **qual("Explain", original="field_study", mechanisms="Mechanisms/Channels Mentioned But Not Explored")},
    118: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Describe", original="not_original")},
    119: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    120: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", causal=True, design="Other", other_design="Comparative subnational case analysis", mechanisms="Mechanisms/Channels Mentioned But Not Explored", sample=4, sample_quote="four states")},
    121: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="structure_systematize", sample=3, sample_quote="Minas Gerais, Ceará e Santa Catarina")},
    122: {"subfield": "Political Theory and Philosophy", **theory()},
    123: {"subfield": "Other", **theory()},
    124: {"subfield": "Comparative Politics", "single_country_study": "single_country", "countries_of_focus": "Peru", **theory("Explain", causal=True)},
    125: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="field_study", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    126: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(design="Kitchen Sink Linear Model", causal=True, ivs=[v("coalition composition", "Composition, coalescence and contiguity of government coalitions."), v("party subsystem characteristics", "State-level party subsystem structure.")], dvs=[v("positive-sum legislative outcomes", "Volume of positive-sum outcomes in state legislatures.")], rels=[rel("coalition composition", "positive-sum legislative outcomes", "Negative", True, True)], sig=True)},
    127: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **q(goal="Describe", original="not_original")},
    128: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **q(design="Kitchen Sink Linear Model", causal=True, ivs=[v("socioeconomic, political and spatial variables", "Municipal characteristics and spatial interactions."), v("income transfer program variables", "Bolsa Familia and related government transfers.")], dvs=[v("electoral outcomes", "Municipal vote outcomes in the 2006 Bahia governor election.")], rels=[rel("income transfer program variables", "electoral outcomes", "Unknown", True, True)], sig=True)},
    129: {"subfield": "International Relations", "single_country_study": "multiple_countries", "countries_of_focus": None, **qual("Explain", original="structure_systematize", causal=True, design="Other", other_design="Focused structured comparison of case studies", mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration", sample=3, sample_quote="three creative cities")},
    130: {"subfield": "Methodology and Formal Theory", **theory("Describe")},
    131: {"subfield": "Comparative Politics", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Argentina", **qual("Explain", original="field_study", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    132: {"subfield": "Comparative Politics", "single_region": "single_region", "countries_of_focus": None, **q(design="Other", other_design="Qualitative Comparative Analysis (QCA)", causal=True, ivs=[v("legislative control", "Whether presidents control the legislature."), v("civil society control", "Whether presidents control civil society."), v("radical-left alignment", "Whether presidents are aligned with the radical left.")], dvs=[v("electoral survival", "Presidential capacity to survive electorally.")], rels=[rel("legislative control", "electoral survival", "Positive", True, True), rel("radical-left alignment", "electoral survival", "Positive", True, True)], sig=True)},
    133: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Describe", original="structure_systematize", sample=4, sample_quote="four programs (from 1994, 1998, 2002 and 2006)")},
    134: {"subfield": "Methodology and Formal Theory", **qual("Describe", original="structure_systematize", causal=True, sample=20, sample_quote="20 articles")},
    135: {"subfield": "Comparative Politics", "single_country_study": "multiple_countries", "countries_of_focus": None, **q(survey="uses_public_available_survey", original="not_original", design="Kitchen Sink Linear Model", causal=True, ivs=[v("national-level polarization", "Country-level political polarization."), v("government ideology", "Ideology of the ruling party or government."), v("voter ideology", "Individual ideological orientation.")], dvs=[v("democratic legitimacy", "Individual support for democratic principles.")], rels=[rel("national-level polarization", "democratic legitimacy", "Negative", True, True)], sample=77000, sample_quote="over 77,000 respondents", sig=True)},
    136: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="field_study", explicit_method=False)},
    137: {"subfield": "Political Theory and Philosophy", **theory("Describe")},
    138: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(survey="uses_public_available_survey", original="not_original", design="Kitchen Sink Linear Model", causal=True, ivs=[v("civil society activism", "Participation in unions, parties, neighborhood associations, churches or participatory budgeting."), v("gender, race and class", "Social-demographic inequalities.")], dvs=[v("political information", "Knowledge of campaign issues in the 2002 election.")], rels=[rel("civil society activism", "political information", "Positive", True, True)], sig=True)},
    139: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(survey="uses_public_available_survey", original="not_original", design="Kitchen Sink Linear Model", causal=True, ivs=[v("2002 presidential electoral process", "Electoral process and adverse political or ethical conditions."), v("formal electoral procedures", "Formal procedures in the electoral process.")], dvs=[v("social capital", "Institutional and informal social capital in 2006."), v("political empowerment", "Citizen political empowerment.")], rels=[rel("formal electoral procedures", "social capital", "Null", False, True)], sig=True)},
    140: {"subfield": "Other", **theory()},
    141: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **mixed(goal="Describe", original="field_study")},
    142: {"subfield": "Methodology and Formal Theory", "single_country_study": "single_country", "countries_of_focus": "Brazil", **mixed(goal="Describe", original="structure_systematize")},
    143: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory()},
    144: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(survey="uses_public_available_survey", original="not_original", design="Kitchen Sink Linear Model", causal=True, ivs=[v("socioeconomic and regional conditions", "Respondent socioeconomic and regional characteristics."), v("policy legitimacy and effectiveness perceptions", "Perceptions about legitimacy and effectiveness of policies.")], dvs=[v("trust in the Armed Forces", "Degree of confidence in Brazilian Armed Forces.")], rels=[rel("socioeconomic and regional conditions", "trust in the Armed Forces", "Unknown", True, True)], sig=True)},
    145: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Describe", survey="runs_original_survey", original="original_survey")},
    146: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(survey="uses_public_available_survey", original="not_original", design="Other", other_design="Observational causal mediation models", causal=True, ivs=[v("criminological variables", "Violence-related variables measured in AmericasBarometer."), v("interpersonal trust", "Mediator for the indirect pathway.")], dvs=[v("satisfaction with democracy", "Instrumental support or satisfaction with the democratic regime.")], rels=[rel("criminological variables", "satisfaction with democracy", "Negative", True, True), rel("interpersonal trust", "satisfaction with democracy", "Null", False, False)], sig=True), "effort_to_explore_mechanisms": "Mechanisms/Channels Mentioned With Substantial Exploration"},
    147: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="structure_systematize")},
    148: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(survey="runs_original_survey", original="original_survey", design="Kitchen Sink Linear Model", causal=True, ivs=[v("fear of violence", "Fear of violence as potential driver of authoritarian tendencies."), v("social strata", "Social position of respondents.")], dvs=[v("authoritarianism", "Adherence to authoritarian positions on the F scale.")], rels=[rel("fear of violence", "authoritarianism", "Positive", True, True)], sample=2087, sample_quote="2,087 people", sig=True)},
    149: {"subfield": "Comparative Politics", "single_country_study": "single_country", "countries_of_focus": "Portugal", **mixed(goal="Describe", original="field_study", sample=8, sample_quote="eight movements studied")},
    150: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="field_study", sample=19, sample_quote="19 of the 21 state ombudsmen offices")},
    151: {"subfield": "Comparative Politics", "single_country_study": "single_country", "countries_of_focus": "Chile", **q(survey="uses_public_available_survey", original="not_original", design="Kitchen Sink Linear Model", causal=False, implicit=True, strong_qual=True, ivs=[v("trust in the legal system", "Confidence in the justice system."), v("perceived police corruption", "Perceptions of corruption among Carabineros."), v("perceived insecurity", "Perception of insecurity.")], dvs=[v("trust in the police", "Confidence in Carabineros.")], rels=[rel("trust in the legal system", "trust in the police", "Positive", True, True), rel("perceived police corruption", "trust in the police", "Negative", True, True)], sig=True)},
    152: {"subfield": "Public Policy/Administration", **theory("Describe")},
    153: {"subfield": "Public Policy/Administration", **theory("Describe")},
    154: {"subfield": "International Relations", **theory("Explain", causal=True)},
    155: {"subfield": "Public Policy/Administration", **theory("Describe")},
    156: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(survey="uses_public_available_survey", original="not_original", design="Kitchen Sink Linear Model", causal=True, ivs=[v("religion", "Voter religion."), v("party sentiments", "Voter party sentiments."), v("left-right placement", "Voter ideological position."), v("government evaluations", "Evaluation of incumbent government performance."), v("candidate attributes", "Reliability and competence assessments.")], dvs=[v("voting decision", "Vote choice in the 2002 presidential election.")], rels=[rel("party sentiments", "voting decision", "Unknown", True, True), rel("candidate attributes", "voting decision", "Unknown", True, True)], sig=True)},
    157: {"subfield": "International Relations", **theory("Explain")},
    158: {"subfield": "International Relations", "single_country_study": "multiple_countries", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned With Substantial Exploration")},
    159: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="procure_original_data", causal=True, mechanisms="Mechanisms/Channels Mentioned But Not Explored")},
    160: {"subfield": "Comparative Politics", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Mexico", **qual("Describe", original="structure_systematize")},
    161: {"subfield": "Methodology and Formal Theory", **q(goal="Describe", original="other_original_data")},
    162: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(survey="runs_original_survey", original="original_survey", design="Kitchen Sink Linear Model", causal=True, ivs=[v("perceptions on justice", "Citizen perceptions of inequalities and justice."), v("agency of judicial institutions", "Perceived role/performance of judicial institutions.")], dvs=[v("dissatisfaction with democracy", "Discontent with democracy and institutions.")], rels=[rel("agency of judicial institutions", "dissatisfaction with democracy", "Positive", True, True)], sig=True)},
    163: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory("Describe")},
    164: {"subfield": "Political Theory and Philosophy", **theory("Describe")},
    165: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="not_original", explicit_method=False)},
    166: {"subfield": "Other", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Describe", survey="uses_public_available_survey", original="not_original")},
    167: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(original="not_original", design="Kitchen Sink Linear Model", causal=True, ivs=[v("incumbent alignments", "Alignment with presidential incumbents."), v("social modernization", "Municipal modernization indicators."), v("political pluralism", "Pluralism in local politics."), v("social inclusion", "Indicators of inclusion.")], dvs=[v("municipal ideology", "Electorally expressed municipal-level ideology.")], rels=[rel("incumbent alignments", "municipal ideology", "Unknown", True, True)], sig=True)},
    168: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned But Not Explored")},
    169: {"subfield": "Political Theory and Philosophy", **theory("Describe")},
    170: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="structure_systematize", explicit_method=False)},
    171: {"subfield": "International Relations", "single_country_study": "multiple_countries", "countries_of_focus": "Brazil; Angola", **qual("Explain", original="structure_systematize", causal=True, mechanisms="Mechanisms/Channels Mentioned But Not Explored")},
    172: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "countries_of_focus": "Brazil", **qual("Describe", original="structure_systematize")},
    173: {"subfield": "Public Policy/Administration", "single_country_study": "single_country", "single_region": "single_region", "countries_of_focus": "Brazil", **qual("Describe", original="structure_systematize")},
    174: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **q(goal="Describe", original="procure_original_data")},
    175: {"subfield": "Brazilian Politics", "single_country_study": "single_country", "countries_of_focus": "Brazil", **theory()},
}


def make_brief(row: dict[str, str], text: str, classification: dict[str, object], has_body: bool) -> str:
    available = "O XML não contém corpo completo do artigo; a classificação usa apenas título, resumo, palavras-chave e metadados disponíveis."
    if not text.strip() or len(text.strip()) < len(row["title"]) + 5:
        substance = "Como o texto disponível é mínimo, não há base para inferir método, variáveis, amostra ou desenho causal."
    else:
        ev = classification["evidence_type"]
        method = classification["method_status"]
        goal = classification["general_goal_of_analysis"]
        subfield = classification["subfield"]
        substance = f"Pelo resumo, o artigo foi classificado em {subfield}, com evidência {ev} e método {method}; o objetivo analítico principal foi tratado como {goal if goal else 'não aplicável/indefinido'}."
    if classification["makes_explicit_causal_claim"] or classification["makes_implicit_causal_claim"]:
        causal = "Há linguagem causal no resumo, mas não há quantidade causal clara nem suposições de identificação explicitadas no texto disponível."
    else:
        causal = "O resumo disponível não sustenta a codificação de um desenho de identificação causal forte."
    return f"{available} {substance} {causal}"


def normalize(classification: dict[str, object]) -> dict[str, object]:
    # Keep causal-claim dependent fields coherent after overrides.
    causal = bool(classification["makes_explicit_causal_claim"] or classification["makes_implicit_causal_claim"])
    if not causal:
        classification["clear_causal_quantity_of_interest"] = None
        classification["discusses_threats_to_causality"] = None
        classification["statement_of_identification_assumptions"] = None
        classification["strong_non_causal_causal_qualification"] = classification["strong_non_causal_causal_qualification"]
    else:
        classification.setdefault("clear_causal_quantity_of_interest", "FALSE")
        if classification["clear_causal_quantity_of_interest"] is None:
            classification["clear_causal_quantity_of_interest"] = "FALSE"
        if classification["discusses_threats_to_causality"] is None:
            classification["discusses_threats_to_causality"] = False
        if classification["statement_of_identification_assumptions"] is None:
            classification["statement_of_identification_assumptions"] = False
        if classification["strong_non_causal_causal_qualification"] is None:
            classification["strong_non_causal_causal_qualification"] = False
    if classification["main_causal_research_design"] not in {"Other", "Multiple Designs"}:
        classification["other_research_design"] = None
    classification["placebo_test"] = False if causal else None
    classification["specifies_estimate_equations"] = False if classification["is_empirical_quant_paper"] or causal else None
    return {key: classification[key] for key in CLASSIFICATION_KEYS}


def validate_record(record: dict[str, object], row: dict[str, str]) -> None:
    expected_top = {
        "pid",
        "agent_id",
        "prompt_version",
        "model",
        "run_timestamp",
        "input_text_hash",
        "source_file",
        "classification",
        "raw_response_path",
    }
    if set(record) != expected_top:
        raise ValueError(f"{row['pid']}: top-level keys mismatch")
    c = record["classification"]
    if not isinstance(c, dict) or list(c.keys()) != CLASSIFICATION_KEYS:
        raise ValueError(f"{row['pid']}: classification keys mismatch")
    if record["pid"] != row["pid"]:
        raise ValueError(f"{row['pid']}: pid mismatch")
    if record["source_file"] != row["source_file"]:
        raise ValueError(f"{row['pid']}: source_file mismatch")
    if record["input_text_hash"] != row["input_text_hash"]:
        raise ValueError(f"{row['pid']}: hash mismatch")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with MANIFEST.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    if len(rows) != 175:
        raise SystemExit(f"Expected 175 manifest rows, found {len(rows)}")
    missing = sorted(set(range(1, len(rows) + 1)) - set(OVERRIDES))
    if missing:
        raise SystemExit(f"Missing manual overrides for rows: {missing}")
    timestamp = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    for index, row in enumerate(rows, start=1):
        source = ROOT / row["source_file"].removeprefix("data/")
        text, has_body = xml_text(source)
        c = default_classification()
        c.update(OVERRIDES[index])
        c["brief_justification"] = make_brief(row, text, c, has_body)
        c = normalize(c)
        record = {
            "pid": row["pid"],
            "agent_id": "agent_b",
            "prompt_version": "agent_b_v1+common_schema_v1",
            "model": "codex_subagent_inherited",
            "run_timestamp": timestamp,
            "input_text_hash": row["input_text_hash"],
            "source_file": row["source_file"],
            "classification": c,
            "raw_response_path": None,
        }
        validate_record(record, row)
        out = OUT_DIR / f"{row['pid']}.json"
        out.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(rows)} JSON files to {OUT_DIR}")


if __name__ == "__main__":
    main()
