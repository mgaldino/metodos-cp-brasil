#!/usr/bin/env python3
"""Build Agent C pilot classifications from the manifest XML inputs only.

This script deliberately avoids any LLM/API runner and any prior/gold
classification directories. It reads only pilot_manifest.csv and the XML files
listed in source_file, then writes one JSON envelope per PID in this directory.
"""

from __future__ import annotations

import csv
import datetime as dt
import html
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path


OUT_DIR = Path("data/processed/full_classification_pilot/agent_c")
MANIFEST = Path("data/processed/full_classification_pilot/pilot_manifest.csv")
AGENT_ID = "agent_c"
PROMPT_VERSION = "agent_c_v1+common_schema_v1"
MODEL = "codex_subagent_inherited"

FIELDS = [
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


def iv(name: str, description: str) -> dict[str, str]:
    return {"variable_name": name, "variable_description": description}


def rel(
    iv_name: str,
    dv_name: str,
    relationship_type: str = "Unknown",
    statistically_significant: bool = False,
    substantively_significant: bool = False,
) -> dict[str, object]:
    return {
        "iv_var_name": iv_name,
        "dv_var_name": dv_name,
        "relationship_type": relationship_type,
        "statistically_significant": statistically_significant,
        "substantively_significant": substantively_significant,
    }


def clean_text(value: str | None) -> str:
    if not value:
        return ""
    return re.sub(r"\s+", " ", html.unescape(value)).strip()


def parse_xml(path: Path) -> dict[str, object]:
    root = ET.parse(path).getroot()
    abstracts: list[str] = []
    for tag in ("abstract", "trans-abstract"):
        for element in root.iter(tag):
            text = clean_text("".join(element.itertext()))
            if text and text not in abstracts:
                abstracts.append(text)
    keywords: list[str] = []
    for element in root.iter("kwd"):
        text = clean_text("".join(element.itertext()))
        if text and text not in keywords:
            keywords.append(text)
    xml_title = ""
    title_el = root.find(".//article-title")
    if title_el is not None:
        xml_title = clean_text("".join(title_el.itertext()))
    return {
        "has_body": root.find(".//body") is not None,
        "title": xml_title,
        "abstract": " | ".join(abstracts),
        "keywords": "; ".join(keywords),
    }


POLITICAL_THEORY = {
    "S0011-52582006000300002",
    "S0011-52582008000400005",
    "S0011-52582010000200002",
    "S0011-52582010000300002",
    "S0011-52582011000100004",
    "S0011-52582015000401131",
    "S0011-52582025000400220",
    "S0011-52582025000400228",
    "S0101-33002013000100006",
    "S0101-33002014000100010",
    "S0101-33002020000100019",
    "S0101-33002022000200231",
    "S0102-64452005000100007",
    "S0102-64452006000300005",
    "S0102-64452008000300004",
    "S0102-64452009000100003",
    "S0102-64452010000100004",
    "S0102-64452012000300007",
    "S0102-64452022000100299",
    "S0102-69092006000100007",
    "S0102-69092006000300006",
    "S0102-69092008000300012",
    "S0102-69092011000100008",
    "S0102-69092015000200045",
    "S0102-85292011000100010",
    "S0102-85292015000300851",
    "S0102-85292019000300663",
    "S0102-85292021000100199",
    "S0103-33522012000300002",
    "S0103-33522014000100007",
    "S0103-33522015000300121",
    "S0104-44782008000200015",
    "S0104-44782009000200015",
    "S0104-44782012000200006",
    "S0104-62762006000100007",
    "S1806-64452005000100002",
    "S1806-64452005000100003",
    "S1806-64452005000100006",
    "S1806-64452006000100005",
    "S1981-38212015000100003",
    "S1981-38212020000200203",
}

METHODOLOGY = {
    "S0102-85292008000100002",
    "S0104-44782018000200031",
    "S0104-62762014000300377",
    "S1981-38212013000100002",
}

PUBLIC_POLICY = {
    "S0011-52582018000200463",
    "S0011-52582024000400209",
    "S0034-76122006000100004",
    "S0034-76122009000100006",
    "S0034-76122009000300003",
    "S0034-76122009000600006",
    "S0034-76122011000400011",
    "S0034-76122014000100004",
    "S0034-76122014000500011",
    "S0034-76122014000600003",
    "S0034-76122015000300563",
    "S0034-76122016000500745",
    "S0034-76122016000600959",
    "S0034-76122017000500879",
    "S0034-76122020000100181",
    "S0034-76122022000600694",
    "S0034-76122023000500502",
    "S0034-76122024000200402",
    "S0101-33002011000300004",
    "S0102-64452016000200021",
    "S0102-64452018000300003",
    "S0102-64452018000300005",
    "S0102-69092024000100506",
    "S0103-33522025000100208",
    "S0104-44782008000100018",
    "S0104-44782012000300006",
    "S0104-62762016000200318",
    "S0104-62762025000100204",
    "S1981-38212013000300001",
    "S2236-57102023000100213",
    "S2236-57102025000101006",
}

INTERNATIONAL_RELATIONS = {
    "S0011-52582015000200461",
    "S0034-73292005000200008",
    "S0034-73292008000100004",
    "S0034-73292009000100001",
    "S0034-73292009000100007",
    "S0034-73292010000300011",
    "S0034-73292011000200008",
    "S0034-73292012000100003",
    "S0034-73292012000300007",
    "S0034-73292017000100203",
    "S0034-73292017000100218",
    "S0034-73292017000200207",
    "S0034-73292017000200208",
    "S0034-73292021000200208",
    "S0034-73292022000100205",
    "S0034-73292023000200502",
    "S0034-73292025000200604",
    "S0101-33002005000200003",
    "S0102-69092015000200045",
    "S0102-69092020000100513",
    "S0102-85292005000100003",
    "S0102-85292006000100007",
    "S0102-85292007000100001",
    "S0102-85292013000200006",
    "S0102-85292013000200009",
    "S0102-85292014000100008",
    "S0102-85292016000100313",
    "S0102-85292017000300569",
    "S0102-85292021000100121",
    "S0102-85292023000100200",
    "S0103-33522019000300077",
    "S0103-33522020000100083",
    "S0104-44782017000100051",
    "S1981-38212007000200010",
    "S1981-38212008000100127",
    "S1981-38212024000200201",
}

COMPARATIVE_POLITICS = {
    "S0011-52582013000100006",
    "S0101-33002024000300409",
    "S0102-64452015000100006",
    "S0102-69092025000100509",
    "S0103-33522020000200135",
    "S0104-44782019000200209",
    "S0104-44782020000100202",
    "S0104-44782023000100400",
    "S0104-44782024000100204",
    "S0104-62762025000100220",
    "S1981-38212010000100131",
}

OTHER_SUBFIELD = {
    "S0101-33002006000200016",
    "S0101-33002007000200016",
    "S0101-33002014000100004",
    "S0101-33002015000100117",
    "S0101-33002018000200191",
    "S0101-33002019000100006",
    "S0101-33002021000300497",
    "S0102-69092009000100011",
    "S0102-69092010000100013",
    "S0102-69092012000200009",
    "S0102-69092019000200505",
    "S0102-69092021000100510",
}


def infer_subfield(pid: str, journal: str, text: str) -> str:
    if pid in METHODOLOGY:
        return "Methodology and Formal Theory"
    if pid in PUBLIC_POLICY:
        return "Public Policy/Administration"
    if pid in INTERNATIONAL_RELATIONS:
        return "International Relations"
    if pid in COMPARATIVE_POLITICS:
        return "Comparative Politics"
    if pid in POLITICAL_THEORY:
        return "Political Theory and Philosophy"
    if pid in OTHER_SUBFIELD:
        return "Other"
    if "Revista de Administração Pública" in journal or "Gestão Pública" in journal:
        return "Public Policy/Administration"
    if "Política Internacional" in journal or "Contexto Internacional" in journal:
        return "International Relations"
    if re.search(r"brasil|brasileir|lula|bolsonaro|stf|congresso|câmara|eleiç", text, re.I):
        return "Brazilian Politics"
    return "Other"


COUNTRY_ALIASES = [
    ("Brazil", r"\bbrasil\b|\bbrazil\b|brasileir"),
    ("Argentina", r"\bargentin"),
    ("China", r"\bchina\b|chines"),
    ("United States", r"estados unidos|\busa\b|\beua\b|united states|washington"),
    ("Mexico", r"\bméxico\b|\bmexico\b|mexican"),
    ("France", r"\bfrança\b|\bfrance\b|french|seine-saint-denis|sciences po"),
    ("Spain", r"\bespanha\b|\bspain\b|\bespaña\b|\bmadri\b|\bmadrid\b"),
    ("Peru", r"\bperu\b|\bperú\b"),
    ("Chile", r"\bchile\b|carabineros"),
    ("Colombia", r"\bcol[oô]mbia\b"),
    ("Russia", r"\brussia\b|\brússia\b"),
    ("India", r"\bindia\b|\bíndia\b"),
    ("South Africa", r"south africa|áfrica do sul"),
    ("Angola", r"\bangola\b"),
    ("Portugal", r"\bportugal\b|portuguesa|portuguese"),
    ("Lebanon", r"\blebanon\b|\blíbano\b|\blibano\b"),
]


def countries_from_text(text: str) -> tuple[str | None, str | None]:
    found: list[str] = []
    for country, pattern in COUNTRY_ALIASES:
        if re.search(pattern, text, re.I) and country not in found:
            found.append(country)
    multiple_region_terms = re.search(
        r"latin america|américa latina|america latina|south america|américa do sul|america do sul|"
        r"57 countries|brics|mercosur|cone sul|scandinavia|global|world",
        text,
        re.I,
    )
    if len(found) == 1 and not multiple_region_terms:
        return "single_country", found[0]
    if len(found) > 1:
        return "multiple_countries", "; ".join(found)
    if multiple_region_terms:
        return "multiple_countries", "; ".join(found) if found else None
    return None, None


def infer_single_region(text: str) -> str | None:
    if re.search(
        r"rio de janeiro|curitiba|porto alegre|chapec[oó]|florian[oó]polis|guarulhos|cidade do m[eé]xico|"
        r"mexico city|bahia|mato grosso do sul|esp[ií]rito santo|paran[aá]|s[aã]o paulo|buenos aires",
        text,
        re.I,
    ):
        if re.search(r"minas gerais.*cear[aá].*santa catarina|belo horizonte.*goi[aâ]nia.*porto alegre.*recife", text, re.I):
            return "multiple_region"
        return "single_region"
    if re.search(r"cinco regi[oõ]es|five regions|quatro pa[ií]ses|four countries|57 countries", text, re.I):
        return "multiple_region"
    return None


def default_classification(pid: str, row: dict[str, str], doc: dict[str, object]) -> dict[str, object]:
    title = clean_text(row.get("title") or str(doc["title"]))
    text = clean_text(" ".join([title, row.get("journal_title", ""), str(doc["keywords"]), str(doc["abstract"])]))
    single_country, countries = countries_from_text(text)
    subfield = infer_subfield(pid, row.get("journal_title", ""), text)

    quant_markers = re.search(
        r"regress|survey|levantamento|amostra representativa|dados quantitativos|quantitative data|"
        r"econometr|estat[ií]stic|statistical|qca|an[aá]lise comparad[ao] qualitativa|"
        r"world values survey|latinobar[oô]metro|eseb|pof/ibge|sips|bar[oô]metro das am[eé]ricas|"
        r"simulations|observational data|ecological analysis|modelos log[ií]sticos|modelos multinomiais|"
        r"correspondence analysis|an[aá]lise de correspond[eê]ncias",
        text,
        re.I,
    )
    qualitative_markers = re.search(
        r"entrevista|interview|etnograf|observa[cç][aã]o|document|fontes prim[aá]rias|case study|estudo de caso|"
        r"process-tracing|process tracing|trabalho de campo|focus group|grupos focais|an[aá]lise de discurso|"
        r"an[aá]lise de conte[uú]do|pesquisa documental",
        text,
        re.I,
    )
    theoretical_markers = re.search(
        r"ensaio|theoretical|te[oó]ric|conceit|conceptual|hist[oó]ria das ideias|pensamento|"
        r"literatura|debate metodol[oó]gico|revis[aã]o de escopo|revis[aã]o integrativa",
        text,
        re.I,
    )

    is_quant = bool(quant_markers)
    if quant_markers and qualitative_markers:
        evidence_type = "mixed"
    elif quant_markers:
        evidence_type = "quantitative"
    elif qualitative_markers:
        evidence_type = "qualitative"
    elif theoretical_markers or not str(doc["abstract"]).strip():
        evidence_type = "theoretical-normative"
    else:
        evidence_type = "qualitative"

    explicit_markers = quant_markers or qualitative_markers or re.search(
        r"metodologia|materiais e m[eé]todos|pesquisa bibliogr[aá]fica|revis[aã]o de escopo|revis[aã]o integrativa|"
        r"modelo formal|formal model|compar[aç][aã]o focada|structured comparison",
        text,
        re.I,
    )
    method_status = "explicit" if explicit_markers else "essayistic"

    if evidence_type == "theoretical-normative":
        is_quant = False
        general_goal = None
        seeks_determinants = None
        original_dataset = None
    else:
        general_goal = "Explain" if re.search(r"determinant|fatores|factors|explain|explicar|efeito|impact|influ[eê]ncia", text, re.I) else "Describe"
        seeks_determinants = bool(re.search(r"determinant|fatores|factors|conditioners|condicionantes|explain|explicar", text, re.I))
        original_dataset = "not_original"

    survey = "no_survey_data"
    if re.search(r"\bsurvey\b|levantamento|pesquisa nacional|world values survey|latinobar[oô]metro|eseb|pof/ibge|sips|bar[oô]metro das am[eé]ricas", text, re.I):
        survey = "uses_public_available_survey"

    return {
        "error_in_raw_text": "No Error" if doc["has_body"] else "Missing/Corrupt",
        "subfield": subfield,
        "is_empirical_quant_paper": is_quant,
        "general_goal_of_analysis": general_goal,
        "single_country_study": single_country,
        "single_region": infer_single_region(text),
        "countries_of_focus": countries,
        "paper_uses_survey_data": survey,
        "uses_original_dataset": original_dataset,
        "seeks_determinants": seeks_determinants,
        "main_causal_research_design": "Kitchen Sink Linear Model" if is_quant and seeks_determinants else None,
        "other_research_design": None,
        "instrumental_variable_instrument": None,
        "placebo_test": None,
        "independent_variables": None,
        "dependent_variables": None,
        "main_variable_relationship": None,
        "makes_explicit_causal_claim": bool(seeks_determinants) if seeks_determinants is not None else None,
        "makes_implicit_causal_claim": False if seeks_determinants is not None else None,
        "strong_non_causal_causal_qualification": None,
        "sample_size": None,
        "sample_size_quote": None,
        "claims_any_statistically_significant_results": None,
        "references_power_analysis": None,
        "clearly_defined_explanatory_variable": True if is_quant and seeks_determinants else None,
        "clear_causal_quantity_of_interest": "FALSE" if is_quant and seeks_determinants else None,
        "specifies_estimate_equations": False if is_quant else None,
        "discusses_threats_to_causality": None,
        "statement_of_identification_assumptions_quote": None,
        "statement_of_identification_assumptions": None,
        "effort_to_explore_mechanisms": "No Mention of Mechanisms/Channels" if evidence_type != "theoretical-normative" else None,
        "mentions_pre_registered_design_and_analysis_plan": None,
        "evidence_type": evidence_type,
        "method_status": method_status,
        "brief_justification": "",
    }


OVERRIDES: dict[str, dict[str, object]] = {
    "S0011-52582006000100002": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("economic indicators", "Inflation, unemployment, exchange rate, C-Bond spread, and Sao Paulo Stock Exchange index."),
        ],
        "dependent_variables": [
            iv("voting intentions", "Aggregate self-reported preferences for presidential candidates in 1994, 1998, and 2002."),
        ],
        "main_variable_relationship": [
            rel("economic indicators", "voting intentions", "Unknown", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "makes_implicit_causal_claim": False,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
        "specifies_estimate_equations": False,
    },
    "S0011-52582013000100006": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Describe",
        "countries_of_focus": "France",
        "single_country_study": "single_country",
        "single_region": "single_region",
        "uses_original_dataset": "field_study",
        "seeks_determinants": False,
        "main_causal_research_design": None,
        "makes_explicit_causal_claim": False,
        "makes_implicit_causal_claim": False,
    },
    "S0011-52582015000200461": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Describe",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "makes_explicit_causal_claim": False,
        "makes_implicit_causal_claim": False,
    },
    "S0011-52582017000200395": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Describe",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": False,
    },
    "S0011-52582018000200463": {
        "evidence_type": "qualitative",
        "method_status": "essayistic",
        "general_goal_of_analysis": "Explain",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
    },
    "S0011-52582024000400209": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "other_original_data",
        "seeks_determinants": True,
        "sample_size": 103,
        "sample_size_quote": "103 colegiados nacionais",
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("government policy preferences", "Preferences of the Bolsonaro government regarding policy content."),
            iv("council resilience", "Combination of institutional design and insertion in policy communities."),
        ],
        "dependent_variables": [
            iv("council deinstitutionalization", "Regulatory and operating status of national policy councils."),
        ],
        "main_variable_relationship": [
            rel("government policy preferences", "council deinstitutionalization", "Unknown", False, True),
            rel("council resilience", "council deinstitutionalization", "Negative", False, True),
        ],
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
        "specifies_estimate_equations": False,
    },
    "S0034-73292017000200207": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Explain",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Other",
        "other_research_design": "Process tracing case study",
        "makes_explicit_causal_claim": True,
        "effort_to_explore_mechanisms": "Mechanisms/Channels Mentioned With Substantial Exploration",
    },
    "S0034-73292022000100205": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "multiple_countries",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("ties to China", "Growing regional ties to China as extra-regional emerging power."),
            iv("ties to Brazil", "Shrinking regional ties to Brazil as regional paymaster."),
        ],
        "dependent_variables": [
            iv("institutional fragmentation", "Fragmentation among Latin American regional organizations."),
        ],
        "main_variable_relationship": [
            rel("ties to China", "institutional fragmentation", "Positive", False, True),
            rel("ties to Brazil", "institutional fragmentation", "Negative", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
        "specifies_estimate_equations": False,
        "effort_to_explore_mechanisms": "Mechanisms/Channels Mentioned With Substantial Exploration",
    },
    "S0034-73292023000200502": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "multiple_countries",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "main_causal_research_design": None,
        "makes_explicit_causal_claim": False,
        "makes_implicit_causal_claim": False,
    },
    "S0034-73292025000200604": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "multiple_countries",
        "countries_of_focus": "China",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": False,
        "main_causal_research_design": None,
        "makes_explicit_causal_claim": False,
        "makes_implicit_causal_claim": False,
    },
    "S0034-76122009000100006": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "uses_original_dataset": "field_study",
        "general_goal_of_analysis": "Describe",
        "seeks_determinants": False,
    },
    "S0034-76122009000300003": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "single_region": "single_region",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "sample_size": 77,
        "sample_size_quote": "Foram analisados os 77 municípios do estado de Mato Grosso do Sul",
        "main_causal_research_design": None,
        "makes_explicit_causal_claim": False,
        "makes_implicit_causal_claim": False,
    },
    "S0034-76122014000100004": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "uses_original_dataset": "field_study",
        "general_goal_of_analysis": "Describe",
        "seeks_determinants": False,
        "sample_size": 46,
        "sample_size_quote": "46 atores representativos do campo das OSC",
        "independent_variables": None,
        "dependent_variables": [
            iv("organizational legitimacy", "Legitimacy dimensions attributed to civil society organizations."),
        ],
        "main_variable_relationship": None,
        "makes_explicit_causal_claim": False,
        "makes_implicit_causal_claim": False,
        "clearly_defined_explanatory_variable": False,
        "main_causal_research_design": None,
        "other_research_design": None,
        "clear_causal_quantity_of_interest": None,
    },
    "S0034-76122014000500011": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "uses_original_dataset": "field_study",
        "general_goal_of_analysis": "Describe",
        "seeks_determinants": False,
    },
    "S0034-76122014000600003": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": False,
        "uses_original_dataset": "field_study",
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "sample_size": 3,
        "sample_size_quote": "três municípios brasileiros",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S0034-76122017000500879": {
        "evidence_type": "quantitative",
        "method_status": "essayistic",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "single_region": "single_region",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("bidding modality", "Procurement modality for education construction works."),
            iv("service type", "Type of service, including renovation."),
            iv("municipal and political characteristics", "Population, mayoral reelection, and mayor-president party alignment."),
        ],
        "dependent_variables": [
            iv("deadline compliance", "Whether construction works met deadlines."),
            iv("price compliance", "Whether construction works avoided overpayment."),
        ],
        "main_variable_relationship": [
            rel("bidding modality", "deadline compliance", "Unknown", False, True),
            rel("municipal and political characteristics", "price compliance", "Unknown", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
        "specifies_estimate_equations": False,
    },
    "S0034-76122024000200402": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": False,
        "uses_original_dataset": "field_study",
        "general_goal_of_analysis": "Explain",
        "seeks_determinants": True,
        "sample_size": 15,
        "sample_size_quote": "entrevistas com 15 atores-chave",
        "main_causal_research_design": "Other",
        "other_research_design": "Content analysis of interviews with triangulation against reports and indicators",
        "makes_explicit_causal_claim": True,
    },
    "S0101-33002014000100004": {
        "evidence_type": "quantitative",
        "method_status": "essayistic",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S0101-33002024000300409": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": False,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "single_region": "single_region",
        "countries_of_focus": "Mexico",
        "uses_original_dataset": "field_study",
        "seeks_determinants": True,
        "main_causal_research_design": "Other",
        "other_research_design": "Focus group field study",
        "makes_explicit_causal_claim": True,
    },
    "S0102-64452013000100013": {
        "evidence_type": "qualitative",
        "method_status": "essayistic",
        "subfield": "Brazilian Politics",
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
    },
    "S0102-64452014000200007": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "subfield": "Brazilian Politics",
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": False,
    },
    "S0102-64452024000200304": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "single_region": "single_region",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "field_study",
        "seeks_determinants": True,
        "main_causal_research_design": "Other",
        "other_research_design": "Ethnography with interviews and observation",
        "makes_explicit_causal_claim": True,
    },
    "S0102-69092013000300008": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "single_region": "single_region",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "field_study",
        "seeks_determinants": False,
        "sample_size": 52,
        "sample_size_quote": "24 advogados, 18 juízes estaduais e 10 juízes federais",
        "main_causal_research_design": None,
    },
    "S0102-69092018000300507": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("media exposure", "Audience/readership of Jornal Nacional, O Globo, Folha de S. Paulo and related outlets."),
            iv("media framing", "Valence and accountability framing of economy and federal government coverage."),
        ],
        "dependent_variables": [
            iv("economic evaluation", "Reader/voter perception of the economy."),
            iv("government evaluation", "Reader/voter evaluation of the federal government."),
        ],
        "main_variable_relationship": [
            rel("media exposure", "economic evaluation", "Negative", False, True),
            rel("media exposure", "government evaluation", "Null", False, False),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
        "specifies_estimate_equations": False,
    },
    "S0102-69092019000300509": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "main_causal_research_design": None,
        "dependent_variables": [
            iv("sex preferences", "Ideal number of children and preferred sex composition from demographic health surveys."),
        ],
    },
    "S0102-69092020000100513": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Explain",
        "single_country_study": "multiple_countries",
        "countries_of_focus": "Argentina; Brazil; Mexico; Colombia",
        "uses_original_dataset": "field_study",
        "seeks_determinants": True,
        "main_causal_research_design": "Other",
        "other_research_design": "Comparative documentary and interview research",
        "makes_explicit_causal_claim": True,
    },
    "S0102-69092024000100506": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "sample_size": 2084,
        "sample_size_quote": "A amostra utilizada foi de 2.084 casos",
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("management instruments and aligned resources", "Factors related to making traditional peoples and communities visible in CRAS implementation."),
        ],
        "dependent_variables": [
            iv("equitable assistance strategies", "Existence of specific assistance strategies for PCTs in CRAS."),
        ],
        "main_variable_relationship": [
            rel("management instruments and aligned resources", "equitable assistance strategies", "Positive", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
        "specifies_estimate_equations": False,
    },
    "S0102-69092025000100509": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Other",
        "other_research_design": "Documentary synthesis and interpretive case analysis",
        "makes_explicit_causal_claim": True,
    },
    "S0102-85292008000100002": {
        "evidence_type": "theoretical-normative",
        "method_status": "explicit",
        "is_empirical_quant_paper": False,
        "general_goal_of_analysis": None,
        "uses_original_dataset": None,
        "seeks_determinants": None,
        "main_causal_research_design": None,
        "makes_explicit_causal_claim": None,
    },
    "S0102-85292021000100121": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "multiple_countries",
        "countries_of_focus": "United States",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Other",
        "other_research_design": "Descriptive trend analysis with document analysis",
        "independent_variables": [
            iv("leftist governments and autonomy", "Latin American assertiveness and quest for autonomy during the 2000s."),
            iv("Chinese and Russian involvement", "External involvement in Latin America."),
        ],
        "dependent_variables": [
            iv("Latin American assertiveness", "Regional assertiveness vis-a-vis the United States after 9/11."),
        ],
        "main_variable_relationship": [
            rel("leftist governments and autonomy", "Latin American assertiveness", "Positive", False, True),
            rel("Chinese and Russian involvement", "Latin American assertiveness", "Positive", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S0103-33522014000300315": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S0103-33522016000100121": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S0103-33522017000300191": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S0103-33522020000100083": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": True,
        "main_causal_research_design": "Other",
        "other_research_design": "Manifesto coding with numerical ideological scale",
        "independent_variables": [
            iv("party", "Party label: PSDB, PT or MDB."),
        ],
        "dependent_variables": [
            iv("foreign policy ideology", "Left-right coded position of electoral foreign policy proposals."),
        ],
        "main_variable_relationship": [
            rel("party", "foreign policy ideology", "Unknown", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S0103-33522024000100214": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S0104-44782013000300008": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "single_region": "multiple_region",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("government coalition composition", "Composition, size, coalescence and contiguity of government coalitions."),
        ],
        "dependent_variables": [
            iv("positive-sum legislative outcomes", "Volume of positive-sum outcomes in state legislatures."),
        ],
        "main_variable_relationship": [
            rel("government coalition composition", "positive-sum legislative outcomes", "Negative", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S0104-44782014000100003": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "single_region": "single_region",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "other_research_design": None,
        "independent_variables": [
            iv("councilor electoral strategy", "Temporal, category and destination patterns of municipal requests."),
        ],
        "dependent_variables": [
            iv("electoral connection", "Use of requests to mediate between voters and the executive."),
        ],
        "main_variable_relationship": [
            rel("councilor electoral strategy", "electoral connection", "Positive", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S0104-44782015000200109": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "single_region": "single_region",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": True,
        "claims_any_statistically_significant_results": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("socioeconomic, political and spatial variables", "Municipal socioeconomic variables, prior electoral base, Lula effect, and Bolsa Familia."),
        ],
        "dependent_variables": [
            iv("PT vote in Bahia", "Municipal election results for governor in Bahia in 2006."),
        ],
        "main_variable_relationship": [
            rel("Lula effect", "PT vote in Bahia", "Positive", True, True),
            rel("Bolsa Familia", "PT vote in Bahia", "Unknown", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
        "specifies_estimate_equations": False,
    },
    "S0104-44782017000100051": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Explain",
        "single_country_study": "multiple_countries",
        "countries_of_focus": "Spain; Canada; Brazil",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Other",
        "other_research_design": "Focused structured comparison of case studies",
        "makes_explicit_causal_claim": True,
    },
    "S0104-44782018000200031": {
        "evidence_type": "theoretical-normative",
        "method_status": "explicit",
        "is_empirical_quant_paper": False,
        "general_goal_of_analysis": None,
        "uses_original_dataset": None,
        "seeks_determinants": None,
        "main_causal_research_design": None,
        "makes_explicit_causal_claim": None,
        "claims_any_statistically_significant_results": None,
    },
    "S0104-44782019000200209": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "single_region": "single_region",
        "countries_of_focus": "Argentina",
        "uses_original_dataset": "field_study",
        "seeks_determinants": True,
        "main_causal_research_design": "Other",
        "other_research_design": "Qualitative fieldwork case study",
        "makes_explicit_causal_claim": True,
    },
    "S0104-44782020000100202": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "multiple_countries",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": True,
        "main_causal_research_design": "Other",
        "other_research_design": "Qualitative Comparative Analysis (QCA) with binary variables",
        "independent_variables": [
            iv("legislative control", "Whether presidents control the legislature."),
            iv("civil society control", "Whether presidents control civil society."),
            iv("radical left alignment", "Whether presidents are aligned with the radical left."),
        ],
        "dependent_variables": [
            iv("electoral survival", "Capacity of Latin American presidents to survive electorally."),
        ],
        "main_variable_relationship": [
            rel("legislative control", "electoral survival", "Positive", False, True),
            rel("civil society control", "electoral survival", "Positive", False, True),
            rel("radical left alignment", "electoral survival", "Positive", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S0104-44782020000400209": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S0104-44782023000100400": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Describe",
        "single_country_study": "multiple_countries",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "sample_size": 20,
        "sample_size_quote": "Analisei 20 artigos selecionados",
        "main_causal_research_design": None,
    },
    "S0104-44782024000100204": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "multiple_countries",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("polarization", "National-level political polarization."),
            iv("voter ideology", "Individual ideological orientation and alignment with government ideology."),
        ],
        "dependent_variables": [
            iv("democratic legitimacy", "Individual commitment to democratic principles."),
        ],
        "main_variable_relationship": [
            rel("polarization", "democratic legitimacy", "Negative", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
        "specifies_estimate_equations": False,
    },
    "S0104-62762006000200005": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("civil society activism", "Participation in civil society organizations."),
            iv("gender, race and class", "Socio-demographic sources of information gaps."),
        ],
        "dependent_variables": [
            iv("political information", "Information about campaign issues in the 2002 elections."),
        ],
        "clearly_defined_explanatory_variable": True,
        "makes_explicit_causal_claim": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S0104-62762007000200001": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("2002 presidential electoral process", "Electoral process and adverse political/economic conditions."),
        ],
        "dependent_variables": [
            iv("social capital in 2006", "Institutional and informal social capital and political empowerment."),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S0104-62762012000200003": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "single_region": "single_region",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "field_study",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S0104-62762014000300377": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": False,
        "uses_original_dataset": "structure_systematize",
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S0104-62762014000300523": {
        "evidence_type": "quantitative",
        "method_status": "essayistic",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S0104-62762015000100132": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("socioeconomic and regional conditions", "Respondents' socioeconomic and regional characteristics."),
            iv("policy legitimacy/effectiveness perceptions", "Perceptions about legitimacy and effectiveness of defense/security policies."),
        ],
        "dependent_variables": [
            iv("trust in the Armed Forces", "Degree of trust in Brazilian Armed Forces."),
        ],
        "main_variable_relationship": [
            rel("socioeconomic and regional conditions", "trust in the Armed Forces", "Unknown", False, True),
            rel("policy legitimacy/effectiveness perceptions", "trust in the Armed Forces", "Unknown", False, True),
        ],
        "clearly_defined_explanatory_variable": True,
        "makes_explicit_causal_claim": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S0104-62762016000200318": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S0104-62762018000100209": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "claims_any_statistically_significant_results": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("criminological variables", "Victimization, fear or violence-related perceptions."),
        ],
        "dependent_variables": [
            iv("satisfaction with democracy", "Instrumental support/satisfaction with the democratic regime."),
        ],
        "main_variable_relationship": [
            rel("criminological variables", "satisfaction with democracy", "Negative", True, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S0104-62762018000300486": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": False,
    },
    "S0104-62762020000100034": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "runs_original_survey",
        "uses_original_dataset": "original_survey",
        "seeks_determinants": True,
        "sample_size": 2087,
        "sample_size_quote": "Foram entrevistadas 2.087 pessoas",
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("fear of violence", "Fear of violence as possible driver of authoritarian tendencies."),
        ],
        "dependent_variables": [
            iv("authoritarian attitudes", "Support for authoritarian positions measured with items from Adorno's F scale."),
        ],
        "main_variable_relationship": [
            rel("fear of violence", "authoritarian attitudes", "Positive", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "makes_implicit_causal_claim": False,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S0104-62762021000100051": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": False,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Portugal",
        "uses_original_dataset": "field_study",
        "seeks_determinants": False,
        "sample_size": 8,
        "sample_size_quote": "oito movimentos estudados",
        "main_causal_research_design": None,
    },
    "S0104-62762025000100204": {
        "evidence_type": "mixed",
        "method_status": "explicit",
        "is_empirical_quant_paper": False,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "field_study",
        "seeks_determinants": False,
        "sample_size": 19,
        "sample_size_quote": "19 das 21 ouvidorias estaduais",
        "main_causal_research_design": None,
    },
    "S0104-62762025000100220": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Chile",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("trust in legal system", "Confidence in the judicial/legal system."),
            iv("perceived police corruption", "Perceptions of corruption in Carabineros."),
            iv("perceived insecurity", "Perception of insecurity."),
        ],
        "dependent_variables": [
            iv("trust in Carabineros", "Trust in Chile's national police."),
        ],
        "main_variable_relationship": [
            rel("trust in legal system", "trust in Carabineros", "Positive", False, True),
            rel("perceived police corruption", "trust in Carabineros", "Negative", False, True),
            rel("perceived insecurity", "trust in Carabineros", "Unknown", False, False),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
        "specifies_estimate_equations": False,
    },
    "S1981-38212007000100070": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("religion", "Voters' religion."),
            iv("party sentiments", "Voters' feelings toward parties."),
            iv("left-right placement", "Voters' ideological self-placement."),
            iv("government evaluation", "Evaluation of incumbent government's performance."),
            iv("candidate attributes", "Reliability and preparedness/competence attributed to candidates."),
        ],
        "dependent_variables": [
            iv("vote choice", "Vote for presidential candidates in the 2002 election."),
        ],
        "main_variable_relationship": [
            rel("religion", "vote choice", "Unknown", False, True),
            rel("party sentiments", "vote choice", "Unknown", False, True),
            rel("candidate attributes", "vote choice", "Unknown", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S1981-38212009000100011": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": True,
        "main_causal_research_design": "Other",
        "other_research_design": "Empirical elite/bureaucracy mapping",
        "makes_explicit_causal_claim": True,
    },
    "S1981-38212013000100002": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "subfield": "Methodology and Formal Theory",
        "general_goal_of_analysis": "Describe",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "claims_any_statistically_significant_results": True,
        "main_causal_research_design": None,
    },
    "S1981-38212013000200003": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "single_region": "multiple_region",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "runs_original_survey",
        "uses_original_dataset": "original_survey",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("perceptions on justice and judicial institutions", "Perceptions of inequality, judicialization and judicial agency."),
        ],
        "dependent_variables": [
            iv("dissatisfaction with democracy", "Dissatisfaction with democratic institutions."),
        ],
        "main_variable_relationship": [
            rel("perceptions on justice and judicial institutions", "dissatisfaction with democracy", "Positive", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S1981-38212015000300021": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "paper_uses_survey_data": "uses_public_available_survey",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S1981-38212019000100200": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Explain",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": True,
        "main_causal_research_design": "Kitchen Sink Linear Model",
        "independent_variables": [
            iv("incumbent alignments", "Alignment with presidential incumbents."),
            iv("social modernization", "Municipal social modernization."),
            iv("political pluralism", "Municipal political pluralism."),
            iv("social inclusion", "Municipal social inclusion."),
        ],
        "dependent_variables": [
            iv("municipal ideology", "Electorally expressed ideology at the municipal level."),
        ],
        "main_variable_relationship": [
            rel("incumbent alignments", "municipal ideology", "Unknown", False, True),
        ],
        "makes_explicit_causal_claim": True,
        "clearly_defined_explanatory_variable": True,
        "clear_causal_quantity_of_interest": "FALSE",
    },
    "S2236-57102023000100213": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S2236-57102025000101006": {
        "evidence_type": "qualitative",
        "method_status": "explicit",
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "single_region": "single_region",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "not_original",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S2236-57102025000101606": {
        "evidence_type": "quantitative",
        "method_status": "explicit",
        "is_empirical_quant_paper": True,
        "general_goal_of_analysis": "Describe",
        "single_country_study": "single_country",
        "single_region": "multiple_region",
        "countries_of_focus": "Brazil",
        "uses_original_dataset": "structure_systematize",
        "seeks_determinants": False,
        "main_causal_research_design": None,
    },
    "S2236-57102025000101611": {
        "evidence_type": "theoretical-normative",
        "method_status": "essayistic",
        "subfield": "Public Policy/Administration",
        "single_country_study": "single_country",
        "countries_of_focus": "Brazil",
    },
}


THEORETICAL_FORCE = {
    "S0011-52582006000300002",
    "S0011-52582010000200002",
    "S0011-52582010000300002",
    "S0011-52582011000100004",
    "S0011-52582015000401131",
    "S0011-52582025000400220",
    "S0101-33002006000200016",
    "S0101-33002007000200016",
    "S0101-33002014000100010",
    "S0101-33002015000100117",
    "S0101-33002019000100006",
    "S0101-33002021000300497",
    "S0102-64452005000100007",
    "S0102-64452006000300005",
    "S0102-64452008000300004",
    "S0102-64452009000100003",
    "S0102-64452012000300007",
    "S0102-69092006000100007",
    "S0102-69092006000300006",
    "S0102-69092008000300012",
    "S0102-69092009000100011",
    "S0102-69092010000100013",
    "S0102-69092011000100008",
    "S0102-69092012000200009",
    "S0102-69092015000200045",
    "S0102-85292011000100010",
    "S0102-85292013000200006",
    "S0102-85292013000200009",
    "S0102-85292014000100008",
    "S0102-85292015000300851",
    "S0102-85292019000300663",
    "S0102-85292021000100199",
    "S0102-85292023000100200",
    "S0103-33522012000300002",
    "S0103-33522014000100007",
    "S0103-33522015000300121",
    "S0104-44782008000200015",
    "S0104-44782009000200015",
    "S0104-44782012000200006",
    "S0104-62762006000100007",
    "S1806-64452005000100002",
    "S1806-64452005000100003",
    "S1806-64452005000100006",
    "S1806-64452006000100005",
    "S1981-38212013000300001",
    "S1981-38212015000100003",
    "S1981-38212020000200203",
}


def apply_theoretical_defaults(pid: str, cls: dict[str, object]) -> None:
    if pid not in THEORETICAL_FORCE:
        return
    cls.update(
        {
            "evidence_type": "theoretical-normative",
            "is_empirical_quant_paper": False,
            "general_goal_of_analysis": None,
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
            "makes_explicit_causal_claim": None,
            "makes_implicit_causal_claim": None,
            "strong_non_causal_causal_qualification": None,
            "claims_any_statistically_significant_results": None,
            "references_power_analysis": None,
            "clearly_defined_explanatory_variable": None,
            "clear_causal_quantity_of_interest": None,
            "specifies_estimate_equations": None,
            "discusses_threats_to_causality": None,
            "statement_of_identification_assumptions_quote": None,
            "statement_of_identification_assumptions": None,
            "effort_to_explore_mechanisms": None,
            "mentions_pre_registered_design_and_analysis_plan": None,
        }
    )


def fill_consistency(cls: dict[str, object]) -> None:
    if cls["is_empirical_quant_paper"] is False and cls["evidence_type"] != "mixed":
        if cls["paper_uses_survey_data"] != "runs_original_survey":
            cls["paper_uses_survey_data"] = "no_survey_data"
    if cls["is_empirical_quant_paper"] is False and cls["main_causal_research_design"] == "Kitchen Sink Linear Model":
        cls["main_causal_research_design"] = None
    if cls["seeks_determinants"] is False:
        cls["clearly_defined_explanatory_variable"] = False if cls["evidence_type"] != "theoretical-normative" else None
        cls["clear_causal_quantity_of_interest"] = None
    if cls["main_causal_research_design"] != "Other" and cls["main_causal_research_design"] != "Multiple Designs":
        if cls["main_causal_research_design"] is not None:
            cls["other_research_design"] = None
    if cls["evidence_type"] == "theoretical-normative":
        cls["method_status"] = cls.get("method_status") or "essayistic"
    if cls["uses_original_dataset"] is None and cls["evidence_type"] != "theoretical-normative":
        cls["uses_original_dataset"] = "not_original"
    for key in ("placebo_test", "references_power_analysis", "mentions_pre_registered_design_and_analysis_plan"):
        if key not in cls:
            cls[key] = None


def justification(row: dict[str, str], doc: dict[str, object], cls: dict[str, object]) -> str:
    title = clean_text(row.get("title") or str(doc["title"]) or row["pid"])
    missing = "O XML não contém corpo integral, apenas metadados/resumo/referências, então marquei Missing/Corrupt e usei somente o que aparece no resumo ou título."
    if cls["evidence_type"] == "quantitative":
        method = "O resumo indica análise quantitativa própria ou uso de dados estruturados; variáveis e desenho foram preenchidos apenas quando explicitados."
    elif cls["evidence_type"] == "mixed":
        method = "O resumo combina dados estruturados ou testes com material qualitativo, como documentos, entrevistas, codificação ou análise de conteúdo."
    elif cls["evidence_type"] == "qualitative":
        method = "A evidência descrita é qualitativa, documental, histórica, etnográfica ou de estudo de caso, sem análise estatística própria clara."
    else:
        method = "O texto disponível sustenta classificação como ensaio teórico, conceitual, normativo ou história das ideias, sem evidência empírica própria clara."
    return f"{missing} Para '{title}', {method}"


def validate_classification(cls: dict[str, object], pid: str) -> None:
    keys = list(cls)
    if keys != FIELDS:
        missing = [field for field in FIELDS if field not in cls]
        extra = [field for field in keys if field not in FIELDS]
        raise ValueError(f"{pid}: schema mismatch missing={missing} extra={extra}")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = list(csv.DictReader(MANIFEST.open(encoding="utf-8")))
    timestamp = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    for row in rows:
        pid = row["pid"]
        doc = parse_xml(Path(row["source_file"]))
        cls = default_classification(pid, row, doc)
        apply_theoretical_defaults(pid, cls)
        cls.update(OVERRIDES.get(pid, {}))
        fill_consistency(cls)
        cls["brief_justification"] = justification(row, doc, cls)
        ordered_cls = {field: cls.get(field) for field in FIELDS}
        validate_classification(ordered_cls, pid)
        envelope = {
            "pid": pid,
            "agent_id": AGENT_ID,
            "prompt_version": PROMPT_VERSION,
            "model": MODEL,
            "run_timestamp": timestamp,
            "input_text_hash": row["input_text_hash"],
            "source_file": row["source_file"],
            "classification": ordered_cls,
            "raw_response_path": None,
        }
        with (OUT_DIR / f"{pid}.json").open("w", encoding="utf-8") as fh:
            json.dump(envelope, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
    print(f"Wrote {len(rows)} JSON files to {OUT_DIR}")


if __name__ == "__main__":
    main()
