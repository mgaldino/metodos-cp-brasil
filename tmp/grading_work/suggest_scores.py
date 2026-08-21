#!/usr/bin/env python3
"""Gera evidências e uma triagem de notas; não substitui a revisão docente."""

from __future__ import annotations

import csv
import json
import re
import unicodedata
from pathlib import Path


ROOT = Path(__file__).resolve().parent
OCR = ROOT / "moodle_ocr"
ROSTER = ROOT / "moodle_roster_and_submissions.json"


def norm(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    value = value.lower().replace("\u00a0", " ")
    return re.sub(r"\s+", " ", value)


def any_re(text: str, patterns: list[str]) -> bool:
    return any(re.search(pattern, text) for pattern in patterns)


def matched_lines(raw: str, patterns: list[str], limit: int = 18) -> list[str]:
    regexes = [re.compile(pattern, re.I) for pattern in patterns]
    lines = [re.sub(r"\s+", " ", line).strip() for line in raw.splitlines()]
    out: list[str] = []
    seen: set[str] = set()
    for i, line in enumerate(lines):
        if not line or line.startswith("====="):
            continue
        candidate = norm(line)
        if any(regex.search(candidate) for regex in regexes):
            context = " | ".join(item for item in lines[max(0, i - 1) : i + 2] if item)
            key = norm(context)
            if key not in seen:
                out.append(context[:700])
                seen.add(key)
        if len(out) >= limit:
            break
    return out


def score_student(raw: str, has_rmd: bool, page_count: int) -> dict:
    text = norm(raw)
    evidence_patterns = {
        "c1": [r"unidade de analise", r"cada linha", r"nomeac", r"mesma pessoa", r"agricultura", r"cultura"],
        "c2": [r"1038", r"1[.]?038", r"525", r"365", r"148", r"ausent", r"exp.?adm", r"exp.?car", r"indicacao", r"na[.]?rm", r"exclu", r"remov"],
        "c3": [r"91[,.]?[789]", r"88[,.]?[01]", r"0[,.]91", r"0[,.]88", r"intervalo", r"margem", r"524", r"354", r"482", r"312"],
        "c4": [r"0[,.]0(5[5-9]|6[0-9])", r"valor.?p", r"hipot", r"nao rejeit", r"rejeit", r"3[,.][789].?%", r"diferenca"],
        "c5": [r"alto.?nivel", r"nivel", r"35[,.][4-8]", r"42[,.][2-7]", r"0[,.]03[7-9]", r"6[,.][5-9].?%", r"magnitude"],
        "c6": [r"10.?%", r"1.?%", r"significancia", r"estatistic", r"substantiv"],
        "c7": [r"raiz", r"sqrt", r"70[,.]7", r"0[,.]707", r"29[,.]3", r"dobr", r"erro.?padrao", r"margem"],
        "c8": [r"tabela", r"fonte", r"figura", r"rmarkdown", r"referenc"],
    }

    c1_signals = sum(
        any_re(text, pats)
        for pats in (
            [r"unidade de analise.{0,180}nomeac", r"nomeac.{0,180}unidade de analise"],
            [r"cada linha.{0,160}(nomeac|funcionar|pessoa)"],
            [r"mesma pessoa.{0,220}(mais de uma|nomead)"],
            [r"ministerio da (agricultura|cultura).{0,240}ministerio da (agricultura|cultura)"],
        )
    )
    c1 = min(0.75, 0.20 * c1_signals + (0.15 if c1_signals >= 3 else 0))

    dims = any_re(text, [r"1038.{0,80}26", r"1[.]038.{0,80}26", r"26.{0,80}(1038|1[.]038)"])
    orgs = sum(value in text for value in ("365", "525", "148"))
    miss = sum(value in text for value in ("95", "76", "75", "11"))
    checks = sum(term in text for term in ("exp adm", "exp car", "nivel", "instr", "indicacao"))
    treatment = any_re(text, [r"(remov|exclu|filtr|casos completos|na[.]rm|complete[.]cases)"])
    c2 = (0.30 if dims else 0) + min(0.25, 0.09 * orgs) + min(0.35, 0.10 * miss) + (0.35 if checks >= 5 else 0.18 if checks >= 3 else 0) + (0.25 if treatment else 0)
    c2 = min(1.50, c2)

    props1 = sum(
        any_re(text, pats)
        for pats in ([r"0[,.]9(1[7-9]|2[0-1])", r"91[,.][7-9]"], [r"0[,.]88[0-3]", r"88[,.][0-3]"])
    )
    ci1 = any_re(text, [r"intervalo de confianca", r"ic.?95", r"95.?%"])
    counts1 = sum(value in text for value in ("524", "354", "482", "312"))
    interp1 = any_re(text, [r"mapa.{0,220}(maior|superior|mais)", r"(maior|superior|mais).{0,220}mapa"])
    c3 = min(1.75, 0.42 * props1 + (0.40 if ci1 else 0) + min(0.28, 0.07 * counts1) + (0.23 if interp1 else 0))

    p1 = any_re(text, [r"0[,.]0(5[5-9]|6[0-9])", r"5[,.][5-9].?%", r"6[,.][0-9].?%"])
    hyp1 = any_re(text, [r"h0", r"h 0", r"hipotese nula", r"hipotese alternativa"])
    decision1 = any_re(text, [r"nao (se )?rejeit", r"insuficient.{0,120}(evidencia|diferenca)"])
    mag1 = any_re(text, [r"3[,.][6-9].{0,15}(ponto|%)", r"0[,.]03[6-9]"])
    c4 = min(1.50, (0.45 if p1 else 0) + (0.30 if hyp1 else 0) + (0.45 if decision1 else 0) + (0.30 if mag1 else 0))

    definition2 = any_re(text, [r"alto.?nivel.{0,300}nivel", r"nivel.{0,300}(5 e 6|5, 6|5 ou 6)"])
    props2 = sum(
        any_re(text, pats)
        for pats in ([r"0[,.]35[4-8]", r"35[,.][4-8]"], [r"0[,.]42[2-7]", r"42[,.][2-7]"])
    )
    p2 = any_re(text, [r"0[,.]03[7-9]", r"3[,.][7-9].?%"])
    decision2 = any_re(text, [r"rejeit.{0,180}(hipotese nula|h0|h 0)", r"(diferenca|associacao).{0,160}signific"])
    mag2 = any_re(text, [r"6[,.][5-9].{0,18}(ponto|%)", r"0[,.]06[5-9]"])
    c5 = min(1.75, (0.35 if definition2 else 0) + 0.32 * props2 + (0.30 if p2 else 0) + (0.25 if decision2 else 0) + (0.21 if mag2 else 0))

    alpha10 = "10%" in text or "10 %" in text or any_re(text, [r"10 por cento"])
    alpha1 = bool(re.search(r"(^|[^0-9])1 ?%", text)) or "1 por cento" in text
    alpha_correct = any_re(text, [r"10.?%.{0,260}(rejeit|signific)", r"(rejeit|signific).{0,260}10.?%"])
    alpha1_correct = any_re(text, [r"1.?%.{0,260}(nao rejeit|nao.*signific)", r"(nao rejeit|nao.*signific).{0,260}1.?%"])
    substantive = "substantiv" in text or "pratic" in text
    c6 = min(0.75, (0.14 if alpha10 else 0) + (0.14 if alpha1 else 0) + (0.18 if alpha_correct else 0) + (0.18 if alpha1_correct else 0) + (0.11 if substantive else 0))

    root2 = any_re(text, [r"raiz.{0,40}2", r"sqrt.{0,30}2", r"70[,.]7", r"0[,.]707", r"29[,.]3"])
    double = "dobr" in text
    se = any_re(text, [r"erro.?padrao", r"margem de erro", r"intervalo.{0,50}(estreit|menor)"])
    correct_dir = any_re(text, [r"(reduz|diminui|menor|estreit).{0,100}(erro|margem|intervalo)", r"(erro|margem|intervalo).{0,100}(reduz|diminui|menor|estreit)"])
    c7 = min(0.50, (0.22 if root2 else 0) + (0.08 if double else 0) + (0.08 if se else 0) + (0.12 if correct_dir else 0))

    c8 = 0.25 + (0.45 if has_rmd else 0) + (0.28 if "tabela" in text else 0) + (0.12 if "fonte" in text else 0) + (0.18 if len(text) >= 5000 else 0.08 if len(text) >= 2500 else 0)
    if page_count >= 100:
        c8 -= 0.30
    c8 = max(0, min(1.50, c8))

    scores = [c1, c2, c3, c4, c5, c6, c7, c8]
    return {
        "criterion_scores": [round(value, 2) for value in scores],
        "suggested_total": round(sum(scores), 1),
        "evidence": {
            key: matched_lines(raw, patterns) for key, patterns in evidence_patterns.items()
        },
        "signals": {
            "dims": dims,
            "org_counts": orgs,
            "missing_counts": miss,
            "checks": checks,
            "treatment": treatment,
            "props1": props1,
            "p1": p1,
            "decision1": decision1,
            "definition2": definition2,
            "props2": props2,
            "p2": p2,
            "decision2": decision2,
            "alpha10": alpha10,
            "alpha1": alpha1,
            "root2": root2,
            "has_rmd": has_rmd,
            "page_count": page_count,
        },
    }


def main() -> None:
    roster = json.loads(ROSTER.read_text(encoding="utf-8"))["participants"]
    submitted = {item["nusp"]: item for item in roster if item["status"] == "Enviado"}
    rows: list[dict] = []
    for nusp, item in sorted(submitted.items(), key=lambda pair: pair[1]["name"].casefold()):
        raw = (OCR / f"{nusp}.txt").read_text(encoding="utf-8")
        meta = json.loads((ROOT / "moodle_captures" / nusp / "metadata.json").read_text(encoding="utf-8"))
        has_rmd = any(re.search(r"\.(rmd|qmd)$", file["fileName"], re.I) for file in item["files"])
        scored = score_student(raw, has_rmd, int(meta.get("pages", 0)))
        rows.append({"nusp": nusp, "name": item["name"], **scored})

    (ROOT / "heuristic_details.json").write_text(
        json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    with (ROOT / "heuristic_scores.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["NUSP", "Nome", "C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "Sugestão"])
        for row in rows:
            writer.writerow([row["nusp"], row["name"], *row["criterion_scores"], row["suggested_total"]])
    print(json.dumps({"students": len(rows), "min": min(row["suggested_total"] for row in rows), "max": max(row["suggested_total"] for row in rows)}))


if __name__ == "__main__":
    main()
