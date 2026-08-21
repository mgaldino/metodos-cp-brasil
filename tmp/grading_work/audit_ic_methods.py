"""Classify confidence-interval methods used in Métodos III submissions.

The classification is intentionally conservative. It combines OCR text from the
submitted PDF with any submitted RMarkdown source and records the textual/code
signals supporting the label.
"""

from __future__ import annotations

import re
import unicodedata
from pathlib import Path

import pandas as pd


ROOT = Path("/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP")
COURSE = Path(
    "/Users/manoelgaldino/Documents/DCP/Cursos/stat_basica/"
    "trabalhos_graduacao_metodos_III_2026/entregas_moodle"
)
OCR_DIR = ROOT / "tmp/grading_work/moodle_ocr"
ROSTER = ROOT / "tmp/grading_work/final_grade_records.csv"
OUTPUT = ROOT / "tmp/grading_work/ic_methods_audit.csv"


def normalize(text: str) -> str:
    """Return lower-case ASCII text with normalized whitespace."""
    decomposed = unicodedata.normalize("NFKD", text)
    ascii_text = "".join(char for char in decomposed if not unicodedata.combining(char))
    return re.sub(r"\s+", " ", ascii_text.lower())


def find_sources(nusp: str) -> list[Path]:
    """Find submitted RMarkdown sources whose top-level folder starts with NUSP."""
    return sorted(
        path
        for path in COURSE.rglob("*")
        if path.is_file()
        and path.suffix.lower() in {".rmd", ".qmd", ".r"}
        and path.relative_to(COURSE).parts[0].startswith(f"{nusp} -")
    )


def classify(text: str) -> tuple[str, str]:
    """Classify the interval method from explicit code/text evidence."""
    clean = normalize(text)

    if "wilson" in clean:
        if "binom.confint" in clean:
            return "Wilson declarado", "wilson; binom.confint"
        if "prop.test" in clean:
            return "Wilson declarado", "wilson; prop.test/conf.int"
        return "Wilson declarado", "wilson"

    if any(token in clean for token in ("clopper", "binom.test", "exato de fisher")):
        return "Binomial exato/Clopper-Pearson", "binomial/exato"

    formula_z = bool(re.search(r"(?:1[\.,]96|qnorm\s*\(\s*0[\.,]975)", clean))
    formula_se = bool(
        re.search(
            r"(?:sqrt|sgrt|sqre|raiz).*?(?:propor|p\s*\*?\s*\(\s*1\s*-)",
            clean,
        )
        or re.search(r"erro.?padrao.*?(?:sqrt|raiz)", clean)
    )
    interval_bounds = bool(
        re.search(r"(?:ic|intervalo|limite).{0,30}(?:inferior|superior|inf|sup)", clean)
        or "margem de erro" in clean
    )
    if formula_z and formula_se and interval_bounds:
        return "Normal/Wald manual", "1,96 ou qnorm; erro-padrão binomial; limites"

    if "prop.test" in clean and "conf.int" in clean:
        return "IC extraído de prop.test", "prop.test; conf.int"

    if "binom.confint" in clean:
        return "binom.confint sem método legível", "binom.confint"

    if formula_z and interval_bounds:
        return "Provável normal/Wald", "1,96 ou qnorm; limites/margem"

    if "prop.test" in clean and "95 percent confidence interval" in clean:
        return "IC exibido por prop.test", "prop.test; saída com IC"

    return "Não identificável com segurança", "sem sinal inequívoco"


def main() -> None:
    """Build the audit table."""
    roster = pd.read_csv(ROSTER, dtype={"NUSP": "string"})
    roster = roster[["Nome", "NUSP", "Trabalho_final", "Situacao"]].copy()

    rows: list[dict[str, object]] = []
    for ocr_path in sorted(OCR_DIR.glob("*.txt")):
        nusp = ocr_path.stem
        source_paths = find_sources(nusp)
        pieces = [ocr_path.read_text(encoding="utf-8", errors="replace")]
        for source_path in source_paths:
            pieces.append(source_path.read_text(encoding="utf-8", errors="replace"))
        method, evidence = classify("\n".join(pieces))
        rows.append(
            {
                "NUSP": nusp,
                "metodo_ic": method,
                "evidencia": evidence,
                "tem_fonte_codigo": bool(source_paths),
                "fontes_codigo": " | ".join(str(path) for path in source_paths),
                "ocr_path": str(ocr_path),
            }
        )

    audit = pd.DataFrame(rows)
    audit["NUSP"] = audit["NUSP"].astype("string")
    result = audit.merge(roster, on="NUSP", how="left", validate="one_to_one")
    result = result[
        [
            "Nome",
            "NUSP",
            "Trabalho_final",
            "metodo_ic",
            "evidencia",
            "tem_fonte_codigo",
            "fontes_codigo",
            "ocr_path",
        ]
    ].sort_values(["metodo_ic", "Nome"], na_position="last")
    result.to_csv(OUTPUT, index=False)

    print(f"submissoes_classificadas={len(result)}")
    print(result["metodo_ic"].value_counts(dropna=False).to_string())
    print("\nWilson declarado:")
    print(
        result.loc[
            result["metodo_ic"].eq("Wilson declarado"),
            ["Nome", "NUSP", "Trabalho_final", "evidencia"],
        ].to_string(index=False)
    )
    print("\nNotas >= 8,8 sem Wilson:")
    print(
        result.loc[
            result["Trabalho_final"].ge(8.8)
            & ~result["metodo_ic"].eq("Wilson declarado"),
            ["Nome", "NUSP", "Trabalho_final", "metodo_ic"],
        ].sort_values("Trabalho_final", ascending=False).to_string(index=False)
    )


if __name__ == "__main__":
    main()
