"""
classify_writing_codex.py

Classifica papers (PDFs) segundo critérios de redação acadêmica do cap. 5,
chamando o Codex CLI (gpt-5.4, xhigh reasoning effort) em paralelo.

Uso:
    python scripts/classify_writing_codex.py

Requer: codex CLI instalado e configurado com modelo gpt-5.4
"""

import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path

# --- Config ---
PAPERS_DIR = Path(__file__).parent.parent / "data" / "raw" / "papers_internacionais" / "APSR"
OUTPUT_DIR = Path(__file__).parent.parent / "data" / "processed" / "classifications_writing"
BATCH_SIZE = 4  # papers em paralelo
CODEX_TIMEOUT = 600  # 10 min per paper

PROMPT = """You are an expert in academic writing in political science. Read the PDF file at the path below and classify its WRITING AND STRUCTURE choices.

IMPORTANT: Read the file using your tools. The file is a PDF at this path:
{pdf_path}

After reading the full paper, return a JSON object with exactly these fields:

1. has_introduction_section: true/false
2. little_template: "1_fact_puzzle", "2_gap_filling", "3_debate_resolution", "hybrid_1_2", "hybrid_1_3", "hybrid_2_3", "other", or null
3. little_template_justification: 1-2 sentences explaining your classification
4. intro_presents_main_result: true/false/null — Does the introduction explicitly state the paper's main empirical finding (not just the question)?
5. intro_presents_main_result_quote: Exact quote of the main result from the introduction, or null
6. inverted_pyramid: true/false/null — Does the introduction follow an inverted pyramid structure (most important information first)?
7. lit_review_location: "integrated_intro", "separate_section", "background_section", "distributed", "absent", or null
8. lit_review_has_title_literature_review: true/false
9. intro_communicates_prior_update: Does the introduction clearly communicate WHAT the reader should believe differently after reading, and HOW MUCH their belief should change?
   - "clear_what_and_magnitude": States both WHAT changes AND magnitude
   - "clear_what_only": States WHAT changes but not how much
   - "vague": Claims contribution but unclear what belief changes
   - "absent": Does not communicate prior update
   - null: No identifiable introduction
10. intro_prior_update_quote: Best 1-2 sentences from the intro communicating what the reader should believe differently. Null if absent.
11. uses_numbered_hypotheses: true/false
12. has_roadmap_paragraph: true/false
13. n_sections: integer — Number of top-level sections
14. section_titles: array of strings — All top-level section titles

Return ONLY valid JSON. No markdown, no commentary outside the JSON."""


def classify_paper(pdf_path: Path) -> dict:
    """Classify a single paper by calling codex exec."""
    fname = pdf_path.name
    out_file = OUTPUT_DIR / f"{pdf_path.stem}.json"

    # Skip if already classified
    if out_file.exists():
        print(f"  SKIP (exists): {fname}")
        with open(out_file) as f:
            return json.load(f)

    prompt = PROMPT.format(pdf_path=str(pdf_path))

    print(f"  START: {fname}")
    t0 = time.time()

    try:
        result = subprocess.run(
            [
                "codex", "exec",
                "--skip-git-repo-check",
                "-C", str(pdf_path.parent),
                "-s", "read-only",
                "-o", str(out_file),
                prompt,
            ],
            capture_output=True,
            text=True,
            timeout=CODEX_TIMEOUT,
        )
        elapsed = time.time() - t0

        # Read output file
        if out_file.exists():
            raw = out_file.read_text().strip()
            # Try to extract JSON from the output
            try:
                # Find the JSON object in the output
                start = raw.find("{")
                end = raw.rfind("}") + 1
                if start >= 0 and end > start:
                    parsed = json.loads(raw[start:end])
                    # Re-save clean JSON
                    parsed["_file"] = fname
                    parsed["_elapsed_s"] = round(elapsed, 1)
                    with open(out_file, "w") as f:
                        json.dump(parsed, f, indent=2, ensure_ascii=False)
                    print(f"  OK ({elapsed:.0f}s): {fname}")
                    return parsed
                else:
                    print(f"  WARN (no JSON found): {fname}")
                    return {"_file": fname, "_error": "no JSON in output", "_raw": raw[:500]}
            except json.JSONDecodeError as e:
                print(f"  WARN (bad JSON): {fname} -> {e}")
                return {"_file": fname, "_error": str(e), "_raw": raw[:500]}
        else:
            print(f"  FAIL (no output file): {fname}")
            stderr = result.stderr[-500:] if result.stderr else ""
            return {"_file": fname, "_error": "no output file", "_stderr": stderr}

    except subprocess.TimeoutExpired:
        elapsed = time.time() - t0
        print(f"  TIMEOUT ({elapsed:.0f}s): {fname}")
        return {"_file": fname, "_error": "timeout"}
    except Exception as e:
        print(f"  ERROR: {fname} -> {e}")
        return {"_file": fname, "_error": str(e)}


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    pdfs = sorted(PAPERS_DIR.glob("*.pdf"))
    if not pdfs:
        print(f"No PDFs found in {PAPERS_DIR}")
        sys.exit(1)

    print(f"Found {len(pdfs)} PDFs in {PAPERS_DIR}")
    print(f"Output: {OUTPUT_DIR}")
    print(f"Batch size: {BATCH_SIZE}")
    print(f"Model: gpt-5.4 (from codex config)")
    print(f"Started: {datetime.now().isoformat()}")
    print()

    results = []
    t_total = time.time()

    # Process in batches
    for batch_start in range(0, len(pdfs), BATCH_SIZE):
        batch = pdfs[batch_start : batch_start + BATCH_SIZE]
        batch_num = batch_start // BATCH_SIZE + 1
        total_batches = (len(pdfs) + BATCH_SIZE - 1) // BATCH_SIZE
        print(f"--- Batch {batch_num}/{total_batches} ({len(batch)} papers) ---")

        with ThreadPoolExecutor(max_workers=BATCH_SIZE) as executor:
            futures = {executor.submit(classify_paper, pdf): pdf for pdf in batch}
            for future in as_completed(futures):
                try:
                    result = future.result()
                    results.append(result)
                except Exception as e:
                    pdf = futures[future]
                    print(f"  EXCEPTION: {pdf.name} -> {e}")
                    results.append({"_file": pdf.name, "_error": str(e)})

        print()

    # Save summary CSV
    summary_path = OUTPUT_DIR / "summary.csv"
    import csv
    if results:
        # Collect all keys
        all_keys = set()
        for r in results:
            all_keys.update(r.keys())
        # Order keys
        key_order = [
            "_file", "has_introduction_section", "little_template",
            "little_template_justification", "intro_presents_main_result",
            "intro_presents_main_result_quote", "inverted_pyramid",
            "lit_review_location", "lit_review_has_title_literature_review",
            "intro_communicates_prior_update", "intro_prior_update_quote",
            "uses_numbered_hypotheses", "has_roadmap_paragraph",
            "n_sections", "section_titles", "_elapsed_s", "_error"
        ]
        keys = [k for k in key_order if k in all_keys]
        keys += sorted(all_keys - set(keys))

        with open(summary_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=keys, extrasaction="ignore")
            writer.writeheader()
            for r in sorted(results, key=lambda x: x.get("_file", "")):
                writer.writerow(r)
        print(f"Summary saved: {summary_path}")

    elapsed_total = time.time() - t_total
    ok = sum(1 for r in results if "_error" not in r)
    fail = sum(1 for r in results if "_error" in r)
    print(f"\nDone: {ok} OK, {fail} failed, {elapsed_total:.0f}s total")
    print(f"Finished: {datetime.now().isoformat()}")


if __name__ == "__main__":
    main()
