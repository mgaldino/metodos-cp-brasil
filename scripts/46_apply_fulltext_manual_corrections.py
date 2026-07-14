#!/usr/bin/env python3
"""Apply documented source corrections to the canonical processed corpus."""

from __future__ import annotations

import csv
import hashlib
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CORRECTIONS = ROOT / "data/processed/fulltext_corpus/manual_corrections.json"
CORPUS = ROOT / "data/processed/fulltext_corpus/article_texts_corpus.csv"
INVENTORY = ROOT / "quality_reports/fulltext_corpus_inventory.csv"


def word_count(text: str) -> int:
    return len(re.findall(r"[A-Za-zÀ-ÖØ-öø-ÿ0-9]+", text))


def rewrite_csv(path: Path, rows: list[dict[str, str]], fieldnames: list[str]) -> None:
    temp = path.with_suffix(path.suffix + ".tmp")
    with temp.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    temp.replace(path)


def main() -> int:
    corrections = json.loads(CORRECTIONS.read_text(encoding="utf-8"))
    by_pid = {item["pid"]: item for item in corrections}

    csv.field_size_limit(20_000_000)
    with CORPUS.open(newline="", encoding="utf-8") as handle:
        corpus_reader = csv.DictReader(handle)
        corpus_fields = corpus_reader.fieldnames or []
        corpus_rows = list(corpus_reader)

    corrected = 0
    corrected_body_by_pid: dict[str, str] = {}
    for row in corpus_rows:
        correction = by_pid.get(row["pid"])
        if correction is None:
            continue
        body = row["body_text"]
        match_text = correction["match_text"]
        replacement_text = correction["replacement_text"]
        if replacement_text in body:
            corrected_body_by_pid[row["pid"]] = body
            continue
        if body.count(match_text) != 1:
            raise ValueError(f"Expected exactly one correction anchor for {row['pid']}")
        body = body.replace(match_text, replacement_text, 1)
        row["body_text"] = body
        row["body_char_count"] = str(len(body))
        row["body_word_count"] = str(word_count(body))
        corrected_body_by_pid[row["pid"]] = body
        corrected += 1

    if set(by_pid) != set(corrected_body_by_pid):
        raise ValueError("Not all documented corrections matched the corpus")
    rewrite_csv(CORPUS, corpus_rows, corpus_fields)

    with INVENTORY.open(newline="", encoding="utf-8") as handle:
        inventory_reader = csv.DictReader(handle)
        inventory_fields = inventory_reader.fieldnames or []
        inventory_rows = list(inventory_reader)

    for row in inventory_rows:
        body = corrected_body_by_pid.get(row["pid"])
        if body is None:
            continue
        row["body_hash"] = hashlib.sha256(body.encode("utf-8")).hexdigest()
        row["body_char_count"] = str(len(body))
        row["body_word_count"] = str(word_count(body))
        row["validation_status"] = "PASS"
        row["suspect_flags"] = ""
        row["nonblocking_flags"] = "manual_source_correction"
    rewrite_csv(INVENTORY, inventory_rows, inventory_fields)

    report = ROOT / "quality_reports/fulltext_manual_correction_S0102-69092007000100010.md"
    correction = by_pid["S0102-69092007000100010"]
    report.write_text(
        "\n".join(
            [
                "# Correção manual de texto integral",
                "",
                f"- PID: `{correction['pid']}`",
                "- Motivo: o HTML local termina no meio da frase antes da seção Notas.",
                f"- Fonte de conferência: {correction['source_url']}",
                f"- Data de acesso: {correction['source_accessed']}",
                f"- Aplicações novas nesta execução: {corrected}",
                "- O arquivo bruto local foi preservado sem alteração.",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Applied corrections: {corrected}")
    print(f"Corpus: {CORPUS}")
    print(f"Inventory: {INVENTORY}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
