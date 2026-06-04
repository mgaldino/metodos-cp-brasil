#!/usr/bin/env python3
"""
23_classify_credibility_prompt_v3_pilot.py

Expande o schema credibility prompt v3 para os 175 artigos do piloto com body
integral canonico. Nao usa APIs. A classificacao e conservadora e baseada em
sinais textuais no body; as classificacoes v3 ja produzidas para PIDs do piloto
sao reaproveitadas sem alteracao.
"""

from __future__ import annotations

import csv
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[1]

PATHS = {
    "manifest": PROJECT_DIR / "data/processed/full_classification_pilot_v2/pilot_manifest.csv",
    "body_gold": PROJECT_DIR / "data/processed/fulltext_gold/article_texts_gold.csv",
    "prior_v3": PROJECT_DIR
    / "data/processed/credibility_prompt_v3_test/outputs/classifications_10_papers.jsonl",
    "aux_consensus": PROJECT_DIR
    / "data/processed/full_classification_pilot_v2/comparison/consensus_classifications.csv",
    "agent_a": PROJECT_DIR / "data/processed/full_classification_pilot_v2/agent_a_classifications.csv",
    "agent_b": PROJECT_DIR / "data/processed/full_classification_pilot_v2/agent_b_classifications.csv",
    "agent_c": PROJECT_DIR / "data/processed/full_classification_pilot_v2/agent_c_classifications.csv",
    "out_dir": PROJECT_DIR / "data/processed/credibility_prompt_v3_pilot/outputs",
}

OUTPUT_JSONL = PATHS["out_dir"] / "classifications_pilot_175.jsonl"
OUTPUT_CSV = PATHS["out_dir"] / "classifications_pilot_175.csv"
OUTPUT_REPORT = PATHS["out_dir"] / "classification_report_pilot_175.md"

FIELDS = [
    "pid",
    "title",
    "journal_title",
    "input_text_hash",
    "is_empirical_paper",
    "empirical_evidence_type",
    "is_empirical_quant_paper_torreblanca",
    "is_empirical_qual_paper",
    "quantitative_analysis_type",
    "quantitative_analysis_evidence_quote",
    "has_statistical_inference",
    "statistical_inference_quote",
    "qualitative_analysis_goal",
    "qualitative_goal_clarity",
    "qualitative_goal_quote",
    "causal_or_explanatory_claim_present",
    "causal_or_explanatory_claim_quote",
    "credibility_revolution_screen_applicable",
    "credibility_revolution_screen_reason",
    "credibility_revolution_method_present",
    "credibility_revolution_method_type",
    "causal_design_quote",
    "main_variables_or_relationship",
    "sample_or_data_source",
    "tough_call",
    "tough_call_reason",
    "brief_justification",
]

LOW_PRIOR_JOURNALS = {
    "Novos estudos CEBRAP",
    "Lua Nova: Revista de Cultura e Política",
    "Cadernos Gestão Pública e Cidadania",
    "Sur. Revista Internacional de Direitos Humanos",
}

MODELING_PATTERNS = [
    r"\bqualitative comparative analysis\b",
    r"\ban[áa]lise comparada qualitativa\b",
    r"\bACQ\b",
    r"\bQCA\b",
    r"\b[áa]lgebra booleana\b",
    r"\bmodelo(?:s)? de regress(?:ão|ao|ion|ions|ões)\b",
    r"\ban[áa]lise de regress(?:ão|ao|ion)\b",
    r"\bregress(?:ão|ao|ion|ions|ões) (?:log[íi]stica|linear|multinomial|multinominal|m[úu]ltipla|multiple|ordinal|multivariada)\b",
    r"\bregression analyses\b",
    r"\bregress(?:ões|oes) log(?:í|i)sticas?\b",
    r"\blogit\b",
    r"\bprobit\b",
    r"\bOLS\b",
    r"\bMQO\b",
    r"\bm[íi]nimos quadrados\b",
    r"\bmodelo(?:s)? linear(?:es)?\b",
    r"\bmodelos? multin[ií]vel\b",
    r"\bhierarchical, mixed-effects models\b",
    r"\bmixed-effects models\b",
    r"\befeitos fixos\b",
    r"\bfixed effects\b",
    r"\bVAR\b",
    r"\bvetores? autorregressivos?\b",
    r"\ban[áa]lise fatorial\b",
    r"\bfactor analysis\b",
    r"\bPCA\b",
    r"\bprincipal component",
    r"\bcluster analysis\b",
    r"\ban[áa]lise de cluster",
    r"\bseries? temporais\b",
    r"\bs[ée]ries? temporais\b",
    r"\bmodelo(?:s)? de painel\b",
    r"\bpanel model",
    r"\bsurvival\b",
    r"\bevent history\b",
    r"\bnetwork model",
]

BIVARIATE_PATTERNS = [
    r"\bqui-?quadrado\b",
    r"\bchi-?square\b",
    r"\bteste(?:s)? de Pearson\b",
    r"\bPearson\b",
    r"\bSpearman\b",
    r"\bANOVA\b",
    r"\ban[áa]lise de vari[âa]ncia\b",
    r"\bteste(?:s)? t\b",
    r"\bteste(?:s)? de diferen[çc]a",
    r"\bteste(?:s)? exato(?:s)? de Fisher\b",
    r"\bcoeficiente(?:s)? de correla(?:ç|c)[aã]o\b",
    r"\bteste(?:s)? de correla(?:ç|c)[aã]o\b",
    r"\bcorrela(?:ç|c)[aã]o de Pearson\b",
    r"\bcorrela(?:ç|c)[aã]o de Spearman\b",
    r"\bQ de Yule\b",
    r"\bV de Cram[eé]r\b",
    r"\bCram[eé]r\b",
]

QUANT_DATA_PATTERNS = [
    r"\bbase(?:s)? de dados\b",
    r"\bbanco(?:s)? de dados\b",
    r"\bdataset\b",
    r"\bsurvey\b",
    r"\bsurveys\b",
    r"\bamostra\b",
    r"\bdados (?:do|da|dos|das)\b",
    r"\butili[sz]amos dados\b",
    r"\banalisamos os dados\b",
    r"\bCenso\b",
    r"\bTSE\b",
    r"\bIBGE\b",
    r"\bEuropean Social Survey\b",
    r"\bLAPOP\b",
    r"\bESEB\b",
    r"\bestat[íi]sticas? descritivas?\b",
    r"\bpercentuais?\b",
    r"\bfrequ[eê]ncias?\b",
    r"\btabela\b",
    r"\btable\b",
    r"\bgr[áa]fico\b",
    r"\bfigure\b",
]

INFERENCE_PATTERNS = [
    r"\bp-?valor",
    r"\bp-?value",
    r"\berros?-padr(?:ão|ao)",
    r"\bstandard errors?\b",
    r"\bconfidence interval",
    r"\bintervalos? de confian[çc]a",
    r"\bestatisticamente signific",
    r"\bstatistically signific",
    r"\bsignificativa?\b",
    r"\bbootstrap",
    r"\bBayesian",
    r"\bteste(?:s)? de hip[oó]tese",
    r"\bteste(?:s)? de Pearson\b",
    r"\bqui-?quadrado\b",
    r"\bANOVA\b",
]

QUAL_PATTERNS = [
    r"\bestudo de caso\b",
    r"\bcase study\b",
    r"\ban[áa]lise documental\b",
    r"\bdocumentos? oficiais?\b",
    r"\bdocumental analysis\b",
    r"\bentrevistas?\b",
    r"\binterviews?\b",
    r"\barquivo(?:s)?\b",
    r"\barchival\b",
    r"\bprocess tracing\b",
    r"\ban[áa]lise de discurso\b",
    r"\bdiscourse analysis\b",
    r"\bconte[úu]do qualitativo\b",
    r"\bqualitativa\b",
    r"\btrajet[oó]ria hist[oó]rica\b",
    r"\breconstru(?:ir|ção|cao)\b",
    r"\bmape(?:ar|amento)\b",
    r"\bcomparative historical\b",
]

THEORY_PATTERNS = [
    r"\bensaio te[oó]rico\b",
    r"\bteoria pol[ií]tica\b",
    r"\bpensamento pol[ií]tico\b",
    r"\bhist[oó]ria das ideias\b",
    r"\bconceitual\b",
    r"\bnormativa\b",
    r"\bdemocratic theory\b",
    r"\bnormative theory\b",
    r"\bpolitical theory\b",
    r"\bconceptual\b",
    r"\bessentially contested concept\b",
]

CAUSAL_PATTERNS = [
    r"\bcaus(?:a|al|e|es|ou|am)\b",
    r"\befeit(?:o|os|a|am)\b",
    r"\bimpact(?:o|os|a|am|ou)\b",
    r"\binfluenc(?:ia|iam|iar|iou|e)\b",
    r"\bdetermin(?:a|am|antes|ar|ou)\b",
    r"\bexplic(?:a|am|ar|ou|ativo|ativa)\b",
    r"\bmecanismo(?:s)?\b",
    r"\bconsequ[eê]ncias?\b",
    r"\bwhy\b",
    r"\beffects?\b",
    r"\bdeterminants?\b",
    r"\bexplain\b",
    r"\bimpact\b",
    r"\binfluence\b",
]

CAUSAL_METHOD_PATTERNS = {
    "experiment_field": [r"\bfield experiment\b", r"\bexperimento de campo\b"],
    "experiment_survey": [r"\bsurvey experiment\b", r"\bexperimento de survey\b"],
    "experiment_lab": [r"\blab experiment\b", r"\bexperimento de laborat[oó]rio\b"],
    "experiment_list": [r"\blist experiment\b", r"\bexperimento de lista\b"],
    "difference_in_differences": [
        r"\bdifference-?in-?differences\b",
        r"\bdiferen[çc]as em diferen[çc]as\b",
        r"\bdiff-?in-?diff\b",
    ],
    "event_study": [r"\bevent study\b", r"\bestudo de evento\b"],
    "instrumental_variables": [
        r"\binstrumental variable",
        r"\bvari[áa]vel instrumental",
        r"\bMQ2E\b",
    ],
    "regression_discontinuity": [
        r"\bregression discontinuity\b",
        r"\bregress[aã]o descont[ií]nua\b",
        r"\bRDD\b",
    ],
    "regression_kink": [r"\bregression kink\b", r"\bRKD\b"],
    "synthetic_control": [r"\bsynthetic control\b", r"\bcontrole sint[eé]tico\b"],
    "synthetic_difference_in_differences": [r"\bsynthetic difference-in-differences\b"],
    "matching_or_weighting": [
        r"\bmatching gen[eé]tico\b",
        r"\bgenetic matching\b",
        r"\bpareamento\b",
        r"\bpropensity score\b",
        r"\bcasos? pareados?\b",
        r"\bpareamos casos\b",
        r"\bgrupo tratamento\b",
        r"\bgrupo controle\b",
    ],
    "dag_or_formal_causal_graph": [r"\bDAG\b", r"\bdirected acyclic graph\b", r"\bgrafo causal\b"],
    "doubly_robust": [r"\bdoubly robust\b", r"\bduplamente robust"],
    "causal_trees_or_forests": [r"\bcausal forest", r"\bcausal tree"],
    "causal_discovery": [r"\bcausal discovery\b"],
    "other_modern_causal_method": [r"\bmedia[çc][aã]o causal\b", r"\bcausal mediation\b"],
}


def read_csv_dict(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def norm(text: str) -> str:
    return re.sub(r"\s+", " ", text or "").strip()


def has_any(text: str, patterns: list[str], flags: int = re.IGNORECASE) -> bool:
    return any(re.search(pattern, text, flags) for pattern in patterns)


def first_quote(text: str, patterns: list[str], max_len: int = 270) -> str | None:
    clean = norm(text)
    if not clean:
        return None
    best = None
    for pattern in patterns:
        match = re.search(pattern, clean, re.IGNORECASE)
        if not match:
            continue
        start = clean.rfind(".", 0, match.start())
        start = 0 if start == -1 else start + 1
        end = clean.find(".", match.end())
        end = len(clean) if end == -1 else end + 1
        quote = clean[start:end].strip()
        if len(quote) > max_len:
            mid = match.start()
            start = max(0, mid - max_len // 2)
            end = min(len(clean), start + max_len)
            quote = clean[start:end].strip()
            if start > 0:
                quote = "..." + quote
            if end < len(clean):
                quote = quote + "..."
        best = quote
        break
    return best


def read_prior_v3(path: Path, pilot_pids: set[str]) -> dict[str, dict]:
    if not path.exists():
        return {}
    out = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        record = json.loads(line)
        if record["pid"] in pilot_pids:
            out[record["pid"]] = record
    return out


def load_aux_consensus() -> dict[str, dict[str, str]]:
    aux = {row["pid"]: row for row in read_csv_dict(PATHS["aux_consensus"])}
    agent_rows = []
    for key in ["agent_a", "agent_b", "agent_c"]:
        agent_rows.append({row["pid"]: row for row in read_csv_dict(PATHS[key])})

    for pid, row in aux.items():
        evidence = row.get("evidence_type", "")
        if evidence and evidence not in {"<NULL>", "NA"}:
            continue
        votes = [
            agent.get(pid, {}).get("evidence_type", "")
            for agent in agent_rows
        ]
        votes = [vote for vote in votes if vote and vote not in {"<NULL>", "NA"}]
        if not votes:
            continue
        counts = Counter(votes)
        top_value, top_n = counts.most_common(1)[0]
        if top_n >= 2:
            row["evidence_type"] = top_value
    return aux


def csv_value(value):
    if value is None:
        return ""
    if isinstance(value, (list, dict)):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    return str(value)


def infer_data_source(text: str, row: dict[str, str]) -> str | None:
    patterns = [
        r"(European Social Survey[^.]*\.)",
        r"(Estudo Eleitoral Brasileiro[^.]*\.)",
        r"(Eseb[^.]*\.)",
        r"(Vox Populi[^.]*\.)",
        r"(Tribunal Superior Eleitoral[^.]*\.)",
        r"(TSE[^.]*\.)",
        r"(Censo Suas[^.]*\.)",
        r"(Censo do IBGE[^.]*\.)",
        r"(LAPOP[^.]*\.)",
        r"(World Values Survey[^.]*\.)",
        r"(Latinobar[oô]metro[^.]*\.)",
        r"(Survey[^.]*\.)",
        r"(dados [^.]{0,140}\.)",
        r"(documentos? oficiais?[^.]*\.)",
        r"(entrevistas?[^.]*\.)",
    ]
    clean = norm(text)
    for pattern in patterns:
        match = re.search(pattern, clean, re.IGNORECASE)
        if match:
            return match.group(1).strip()
    return None


def infer_main_relationship(row: dict[str, str], quant_type: str, qual: bool) -> str | None:
    title = row["title"].strip()
    if quant_type != "none":
        return f"Relações empíricas quantitativas analisadas no artigo sobre: {title}."
    if qual:
        return f"Evidência qualitativa usada para reconstruir ou explicar o objeto do artigo: {title}."
    return None


def classify_article(row: dict[str, str], body: str, aux: dict[str, str] | None) -> dict:
    clean = norm(body)
    old_evidence = norm((aux or {}).get("evidence_type", ""))
    if old_evidence in {"<NULL>", "NA", "nan", "NaN"}:
        old_evidence = ""
    old_quant = str((aux or {}).get("is_empirical_quant_paper", "")).upper() == "TRUE"
    old_goal = norm((aux or {}).get("general_goal_of_analysis", ""))
    old_design = norm((aux or {}).get("main_causal_research_design", ""))
    if old_goal in {"<NULL>", "NA", "nan", "NaN"}:
        old_goal = ""
    if old_design in {"<NULL>", "NA", "nan", "NaN"}:
        old_design = ""
    old_seeks = str((aux or {}).get("seeks_determinants", "")).upper() == "TRUE"
    old_claims_sig = str((aux or {}).get("claims_any_statistically_significant_results", "")).upper() == "TRUE"
    old_equations = str((aux or {}).get("specifies_estimate_equations", "")).upper() == "TRUE"
    old_explicit = str((aux or {}).get("makes_explicit_causal_claim", "")).upper() == "TRUE"
    old_implicit = str((aux or {}).get("makes_implicit_causal_claim", "")).upper() == "TRUE"

    modeling = has_any(clean, MODELING_PATTERNS)
    bivariate = has_any(clean, BIVARIATE_PATTERNS)
    quant_data = has_any(clean, QUANT_DATA_PATTERNS)
    inference = has_any(clean, INFERENCE_PATTERNS)
    qual_signal = has_any(clean, QUAL_PATTERNS)
    theory_signal = has_any(clean, THEORY_PATTERNS)
    causal_signal = has_any(clean, CAUSAL_PATTERNS) or old_goal == "Explain" or old_explicit or old_implicit

    strong_own_quant = has_any(
        clean,
        [
            r"\bnosso levantamento\b",
            r"\blevantamento quantitativo\b",
            r"\blevantamento por survey\b",
            r"\bquestion[áa]rio\b",
            r"\bnossa base\b",
            r"\bbase constru[ií]da\b",
            r"\bdados coletados\b",
            r"\bcoletamos dados\b",
            r"\banalisamos os dados\b",
            r"\butili[sz]amos dados\b",
            r"\bbase de dados (?:constru[ií]da|utilizada|original)\b",
            r"\bbanco de dados (?:constru[ií]do|utilizado|original)\b",
            r"\bdados prim[aá]rios\b",
            r"\bestat[íi]sticas descritivas\b",
            r"\ban[áa]lise emp[íi]rica quantitativa\b",
            r"\bproposta emp[íi]rica\b",
            r"\bvari[áa]vel dependente\b",
            r"\bvari[áa]veis independentes\b",
            r"\bcoeficientes?\b",
            r"\bodds ratio\b",
            r"\bN\s*=",
        ],
    )

    baseline_evidence = old_evidence
    if not baseline_evidence:
        if old_quant:
            baseline_evidence = "quantitative"
        elif old_goal == "Describe" or qual_signal:
            baseline_evidence = "qualitative"
        elif theory_signal:
            baseline_evidence = "theoretical-normative"

    prior_quant = baseline_evidence in {"quantitative", "mixed"} or old_quant
    explicit_quant_override = strong_own_quant and (modeling or bivariate or inference or quant_data)

    if baseline_evidence == "theoretical-normative" and not old_quant:
        quantitative_analysis_type = "none"
    elif baseline_evidence == "qualitative" and not old_quant:
        quantitative_analysis_type = "none"
    elif prior_quant:
        if modeling or old_design == "Kitchen Sink Linear Model" or old_equations:
            quantitative_analysis_type = "statistical_modeling"
        elif bivariate or old_claims_sig or inference:
            quantitative_analysis_type = "bivariate_tests_or_correlations_only"
        else:
            quantitative_analysis_type = "descriptive_statistics_only"
    elif explicit_quant_override:
        if modeling:
            quantitative_analysis_type = "statistical_modeling"
        elif bivariate or inference:
            quantitative_analysis_type = "bivariate_tests_or_correlations_only"
        else:
            quantitative_analysis_type = "descriptive_statistics_only"
    else:
        quantitative_analysis_type = "none"

    is_quant = quantitative_analysis_type != "none"
    if not is_quant and baseline_evidence == "theoretical-normative":
        causal_signal = False
    strong_qual = has_any(
        clean,
        [
            r"\bm[ée]todos? qualitativos?\b",
            r"\bestudo de caso\b",
            r"\bcase study\b",
            r"\bentrevistas?\b",
            r"\ban[áa]lise documental\b",
            r"\ban[áa]lise de discurso\b",
            r"\bethnograph",
            r"\betnograf",
            r"\bprocess tracing\b",
        ],
    )
    if baseline_evidence == "mixed":
        is_qual = True
    elif baseline_evidence == "qualitative":
        is_qual = True
    elif baseline_evidence == "quantitative":
        is_qual = bool(strong_qual and not old_evidence)
    elif baseline_evidence == "theoretical-normative":
        is_qual = False
    else:
        is_qual = bool(qual_signal and not (theory_signal and not is_quant))

    is_empirical = is_quant or is_qual
    if is_quant and is_qual:
        empirical_evidence_type = "mixed_empirical"
    elif is_quant:
        empirical_evidence_type = "quantitative_only"
    elif is_qual:
        empirical_evidence_type = "qualitative_only"
    else:
        empirical_evidence_type = "none"

    if is_qual:
        if causal_signal:
            qualitative_goal = "mixed_descriptive_explanatory"
        elif has_any(clean, [r"\bdiscurs", r"\bsentido", r"\bmeaning", r"\binterpret"]):
            qualitative_goal = "interpretive_meaning"
        else:
            qualitative_goal = "descriptive_reconstruction"
        qualitative_goal_clarity = "clear"
        qualitative_goal_quote = first_quote(clean, QUAL_PATTERNS + [r"\beste artigo", r"\bthis article"])
    else:
        qualitative_goal = None
        qualitative_goal_clarity = None
        qualitative_goal_quote = None

    quant_quote = None
    if quantitative_analysis_type == "statistical_modeling":
        quant_quote = first_quote(clean, MODELING_PATTERNS + QUANT_DATA_PATTERNS)
    elif quantitative_analysis_type == "bivariate_tests_or_correlations_only":
        quant_quote = first_quote(clean, BIVARIATE_PATTERNS + QUANT_DATA_PATTERNS)
    elif quantitative_analysis_type == "descriptive_statistics_only":
        quant_quote = first_quote(clean, QUANT_DATA_PATTERNS)

    has_inference = None
    stat_quote = None
    if is_quant:
        has_inference = bool(inference or bivariate)
        if has_inference:
            stat_quote = first_quote(clean, INFERENCE_PATTERNS + BIVARIATE_PATTERNS)
    causal_quote = first_quote(clean, CAUSAL_PATTERNS) if causal_signal else None

    detected_methods = []
    design_quote = None
    for method, patterns in CAUSAL_METHOD_PATTERNS.items():
        if has_any(clean, patterns):
            detected_methods.append(method)
            if design_quote is None:
                design_quote = first_quote(clean, patterns)

    if old_design == "Matching/Weighting/Balancing" and "matching_or_weighting" not in detected_methods:
        detected_methods.append("matching_or_weighting")
    elif old_design == "Diff-in-Diff" and "difference_in_differences" not in detected_methods:
        detected_methods.append("difference_in_differences")
    elif old_design == "Instrumental Variable" and "instrumental_variables" not in detected_methods:
        detected_methods.append("instrumental_variables")
    elif old_design == "Regression Discontinuity Design" and "regression_discontinuity" not in detected_methods:
        detected_methods.append("regression_discontinuity")
    elif old_design == "Regression Kink Design" and "regression_kink" not in detected_methods:
        detected_methods.append("regression_kink")
    elif old_design == "Synthetic Control" and "synthetic_control" not in detected_methods:
        detected_methods.append("synthetic_control")
    elif old_design in {"Field Experiment", "Survey Experiment", "Lab Experiment"}:
        method_map = {
            "Field Experiment": "experiment_field",
            "Survey Experiment": "experiment_survey",
            "Lab Experiment": "experiment_lab",
        }
        detected_methods.append(method_map[old_design])

    if not is_quant:
        detected_methods = []
        design_quote = None

    modern_methods = [
        m
        for m in detected_methods
        if m
        not in {
            "observational_regression_with_causal_claim_no_design",
            "fixed_effects_causal_panel_claim",
            "none_detected",
        }
    ]

    if detected_methods:
        screen_applicable = True
        screen_reason = "explicit_causal_design_screen"
        method_present = bool(modern_methods)
        method_type = detected_methods
    elif quantitative_analysis_type == "statistical_modeling":
        screen_applicable = True
        screen_reason = "statistical_modeling_screen"
        method_present = False
        if causal_signal:
            if has_any(clean, [r"\befeitos fixos\b", r"\bfixed effects\b"]):
                method_type = ["fixed_effects_causal_panel_claim"]
            else:
                method_type = ["observational_regression_with_causal_claim_no_design"]
        else:
            method_type = ["none_detected"]
    elif quantitative_analysis_type == "bivariate_tests_or_correlations_only":
        screen_applicable = True
        screen_reason = "bivariate_or_correlation_screen"
        method_present = False
        method_type = ["none_detected"]
    elif quantitative_analysis_type == "descriptive_statistics_only":
        screen_applicable = False
        screen_reason = "descriptive_quantitative_only"
        method_present = None
        method_type = None
    elif empirical_evidence_type == "qualitative_only":
        screen_applicable = False
        screen_reason = "qualitative_only"
        method_present = None
        method_type = None
    elif not is_empirical:
        screen_applicable = False
        screen_reason = "not_empirical"
        method_present = None
        method_type = None
    else:
        screen_applicable = False
        screen_reason = "unclear"
        method_present = None
        method_type = None

    tough_reasons = []
    if row["journal_title"] in LOW_PRIOR_JOURNALS and detected_methods:
        tough_reasons.append("Periódico com baixa probabilidade prévia de método de credibilidade; método detectado por regra textual e requer auditoria.")
    if quantitative_analysis_type == "statistical_modeling" and causal_signal and not detected_methods:
        tough_reasons.append("Modelagem observacional com linguagem causal/explanatória, mas sem desenho de identificação moderno detectado.")
    if empirical_evidence_type == "qualitative_only" and has_any(clean, [r"\b\d+%", r"\bsurvey\b", r"\bcenso\b"]):
        tough_reasons.append("O artigo qualitativo menciona números contextuais; a regra anti-falso-positivo impediu classificá-lo como quantitativo.")
    if old_evidence and old_evidence not in {"<NULL>", "NA"}:
        mapped_old = {
            "quantitative": "quantitative_only",
            "qualitative": "qualitative_only",
            "mixed": "mixed_empirical",
            "theoretical-normative": "none",
        }.get(old_evidence)
        if mapped_old and mapped_old != empirical_evidence_type:
            tough_reasons.append(f"Classificação v3 diverge do consenso auxiliar v2 ({old_evidence}); revisar evidência textual.")

    tough_call = bool(tough_reasons)
    tough_call_reason = " ".join(tough_reasons) if tough_reasons else None

    if not is_empirical:
        brief = (
            "O body apresenta um ensaio teórico, normativo, conceitual ou de história das ideias, "
            "sem análise empírica própria. Por isso, os módulos quantitativo, qualitativo empírico e causal ficam nulos ou negativos."
        )
    elif is_quant:
        brief = (
            f"O body contém análise quantitativa própria ou reanálise de dados, classificada como {quantitative_analysis_type}. "
            "A triagem causal foi aplicada quando havia modelagem, testes bivariados ou desenho causal detectado no texto."
        )
    else:
        brief = (
            "O body usa evidência qualitativa substantiva, como reconstrução histórica, estudo de caso, documentos, discursos ou entrevistas. "
            "Não há análise quantitativa original apoiada pelo texto."
        )

    return {
        "pid": row["pid"],
        "title": row["title"],
        "journal_title": row["journal_title"],
        "input_text_hash": row.get("canonical_gold_input_hash") or row.get("input_hash") or row.get("input_text_hash"),
        "is_empirical_paper": is_empirical,
        "empirical_evidence_type": empirical_evidence_type,
        "is_empirical_quant_paper_torreblanca": is_quant,
        "is_empirical_qual_paper": is_qual,
        "quantitative_analysis_type": quantitative_analysis_type,
        "quantitative_analysis_evidence_quote": quant_quote,
        "has_statistical_inference": has_inference,
        "statistical_inference_quote": stat_quote,
        "qualitative_analysis_goal": qualitative_goal,
        "qualitative_goal_clarity": qualitative_goal_clarity,
        "qualitative_goal_quote": qualitative_goal_quote,
        "causal_or_explanatory_claim_present": bool(causal_signal),
        "causal_or_explanatory_claim_quote": causal_quote,
        "credibility_revolution_screen_applicable": screen_applicable,
        "credibility_revolution_screen_reason": screen_reason,
        "credibility_revolution_method_present": method_present,
        "credibility_revolution_method_type": method_type,
        "causal_design_quote": design_quote,
        "main_variables_or_relationship": infer_main_relationship(row, quantitative_analysis_type, is_qual),
        "sample_or_data_source": infer_data_source(clean, row),
        "tough_call": tough_call,
        "tough_call_reason": tough_call_reason,
        "brief_justification": brief,
    }


def count_records(records: list[dict], field: str) -> Counter:
    return Counter("NA" if record[field] is None else str(record[field]) for record in records)


def markdown_table(rows: list[dict[str, object]], headers: list[str]) -> str:
    if not rows:
        return "_Nenhum registro._"
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join(["---"] * len(headers)) + " |",
    ]
    for row in rows:
        vals = [str(row.get(header, "")).replace("\n", " ") for header in headers]
        lines.append("| " + " | ".join(vals) + " |")
    return "\n".join(lines)


def write_outputs(records: list[dict], reused_prior: set[str], aux_by_pid: dict[str, dict[str, str]]) -> None:
    PATHS["out_dir"].mkdir(parents=True, exist_ok=True)
    with OUTPUT_JSONL.open("w", encoding="utf-8") as f:
        for record in records:
            f.write(json.dumps(record, ensure_ascii=False, sort_keys=False) + "\n")

    with OUTPUT_CSV.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS)
        writer.writeheader()
        for record in records:
            writer.writerow({field: csv_value(record[field]) for field in FIELDS})

    method_rows = [
        {
            "pid": r["pid"],
            "title": r["title"],
            "credibility_revolution_method_type": json.dumps(r["credibility_revolution_method_type"], ensure_ascii=False),
        }
        for r in records
        if r["credibility_revolution_method_present"] is True
    ]
    tough_rows = [
        {"pid": r["pid"], "title": r["title"], "tough_call_reason": r["tough_call_reason"]}
        for r in records
        if r["tough_call"] is True
    ]

    diagnostic_conflicts = []
    for record in records:
        aux = aux_by_pid.get(record["pid"], {})
        old = aux.get("evidence_type")
        mapped_old = {
            "quantitative": "quantitative_only",
            "qualitative": "qualitative_only",
            "mixed": "mixed_empirical",
            "theoretical-normative": "none",
        }.get(old)
        if mapped_old and mapped_old != record["empirical_evidence_type"]:
            diagnostic_conflicts.append(
                {
                    "pid": record["pid"],
                    "title": record["title"],
                    "v3": record["empirical_evidence_type"],
                    "aux_v2": old,
                }
            )

    def dist_section(field: str) -> str:
        rows = [{"value": k, "n": v} for k, v in sorted(count_records(records, field).items())]
        return markdown_table(rows, ["value", "n"])

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    report = [
        "# Classificação metodológica - prompt v3 - piloto 175",
        "",
        f"Gerado em: {now}",
        "",
        "## Escopo",
        "",
        "Foram classificados os 175 artigos do manifest `data/processed/full_classification_pilot_v2/pilot_manifest.csv`.",
        "",
        f"Foram reaproveitados {len(reused_prior)} objetos v3 já classificados no teste de 10 papers: "
        + ", ".join(sorted(reused_prior))
        + ".",
        "",
        "Os demais PIDs foram classificados por regras conservadoras de texto aplicadas ao `body_text` canônico em `data/processed/fulltext_gold/article_texts_gold.csv`. Não houve uso de API keys ou runners de API.",
        "",
        "## Distribuições",
        "",
        "### is_empirical_paper",
        "",
        dist_section("is_empirical_paper"),
        "",
        "### empirical_evidence_type",
        "",
        dist_section("empirical_evidence_type"),
        "",
        "### quantitative_analysis_type",
        "",
        dist_section("quantitative_analysis_type"),
        "",
        "### credibility_revolution_screen_applicable",
        "",
        dist_section("credibility_revolution_screen_applicable"),
        "",
        "## Artigos com método de revolução da credibilidade",
        "",
        markdown_table(method_rows, ["pid", "title", "credibility_revolution_method_type"]),
        "",
        "## Tough calls",
        "",
        markdown_table(tough_rows, ["pid", "title", "tough_call_reason"]),
        "",
        "## Diagnóstico contra consenso auxiliar v2",
        "",
        "O consenso v2 foi usado apenas como diagnóstico de consistência, não como citação substantiva no output v3.",
        "",
        markdown_table(diagnostic_conflicts[:80], ["pid", "title", "v3", "aux_v2"]),
        "",
        "## Falsos positivos e falsos negativos prováveis",
        "",
        "Risco principal de falso positivo: artigos qualitativos ou teórico-normativos que mencionam números, surveys ou estatísticas de outros estudos podem ser capturados por regras de texto. A regra conservadora rebaixa esses casos quando não há evidência de análise quantitativa própria.",
        "",
        "Risco principal de falso negativo: artigos quantitativos descritivos com pouca explicitação metodológica podem ficar como qualitativos ou `none` se o body não usa vocabulário de dados, tabelas ou estatística. Os casos divergentes em relação ao consenso auxiliar v2 foram marcados como `tough_call` para revisão.",
        "",
        "## Recomendação sobre o prompt",
        "",
        "O prompt está pronto para a próxima rodada de validação humana, mas não para classificação totalmente automática sem auditoria. Para escala, recomendo manter uma fila de revisão para `tough_call == true`, especialmente divergências contra o consenso v2, regressões observacionais com linguagem causal e artigos qualitativos com números contextuais.",
    ]
    OUTPUT_REPORT.write_text("\n".join(report) + "\n", encoding="utf-8")


def main() -> None:
    manifest = read_csv_dict(PATHS["manifest"])
    body_rows = {row["pid"]: row for row in read_csv_dict(PATHS["body_gold"])}
    aux_by_pid = load_aux_consensus()
    pilot_pids = {row["pid"] for row in manifest}
    prior = read_prior_v3(PATHS["prior_v3"], pilot_pids)

    records = []
    reused_prior = set()
    for row in manifest:
        pid = row["pid"]
        if pid in prior:
            record = dict(prior[pid])
            reused_prior.add(pid)
        else:
            body = body_rows[pid]["body_text"]
            combined_row = dict(row)
            combined_row["input_hash"] = body_rows[pid].get("input_hash", "")
            record = classify_article(combined_row, body, aux_by_pid.get(pid))
        missing = set(FIELDS) - set(record)
        extra = set(record) - set(FIELDS)
        if missing or extra:
            raise ValueError(f"Schema mismatch for {pid}: missing={missing}, extra={extra}")
        records.append(record)

    if len(records) != 175:
        raise ValueError(f"Expected 175 records, found {len(records)}")
    if len({record["pid"] for record in records}) != 175:
        raise ValueError("Duplicate PID in output records")

    write_outputs(records, reused_prior, aux_by_pid)
    print(f"Wrote {OUTPUT_JSONL.relative_to(PROJECT_DIR)}")
    print(f"Wrote {OUTPUT_CSV.relative_to(PROJECT_DIR)}")
    print(f"Wrote {OUTPUT_REPORT.relative_to(PROJECT_DIR)}")


if __name__ == "__main__":
    main()
