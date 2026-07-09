#!/usr/bin/env python3
"""
Prepare disjoint active batches for parallel integral-reading execution.

This script only freezes manifests and writes an execution plan. It does not
call Codex and does not combine outputs.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
from collections import Counter
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable


PROJECT_DIR = Path(__file__).resolve().parents[1]

DEFAULT_MANIFEST = PROJECT_DIR / "data/processed/credibility_prompt_v3_full_corpus/full_corpus_manifest.csv"
DEFAULT_OUT_DIR = PROJECT_DIR / "data/processed/credibility_prompt_v3_integral_reading/full_corpus"
DEFAULT_BATCH_DIR = PROJECT_DIR / "data/processed/credibility_prompt_v3_full_corpus/batch_manifests"
DEFAULT_QUALITY_DIR = PROJECT_DIR / "quality_reports"
DEFAULT_PLAN_MD = DEFAULT_QUALITY_DIR / "credibility_prompt_v3_parallel_batches_plan.md"
DEFAULT_PLAN_JSON = DEFAULT_QUALITY_DIR / "credibility_prompt_v3_parallel_batches_plan.json"

ACTIVE_BATCH_RE = re.compile(r"^active_batch_(\d{3})\.csv$")


@dataclass
class BatchStatus:
    label: str
    manifest_path: Path
    rows: list[dict[str, str]]
    complete_pids: set[str]
    failed_pids: set[str]
    created_now: bool = False

    @property
    def pids(self) -> list[str]:
        return [row["pid"] for row in self.rows]

    @property
    def missing_pids(self) -> list[str]:
        return [pid for pid in self.pids if pid not in self.complete_pids]

    @property
    def is_complete(self) -> bool:
        return not self.missing_pids


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--batch-dir", type=Path, default=DEFAULT_BATCH_DIR)
    parser.add_argument("--quality-dir", type=Path, default=DEFAULT_QUALITY_DIR)
    parser.add_argument("--workers", type=int, default=2, help="Parallel batch slots to prepare.")
    parser.add_argument("--limit", type=int, default=100, help="Rows per newly created batch.")
    parser.add_argument("--timeout", type=int, default=2400)
    parser.add_argument("--codex-bin", default="codex")
    parser.add_argument("--model", default=None)
    parser.add_argument("--model-reasoning-effort", choices=["low", "medium", "high", "xhigh"], default="high")
    parser.add_argument("--ephemeral", action="store_true")
    parser.add_argument("--force", action="store_true", help="Include --force in the later run plan.")
    parser.add_argument("--plan-md", type=Path, default=DEFAULT_PLAN_MD)
    parser.add_argument("--plan-json", type=Path, default=DEFAULT_PLAN_JSON)
    return parser.parse_args()


def as_project_path(path: Path) -> Path:
    return path if path.is_absolute() else PROJECT_DIR / path


def project_relative(path: Path) -> str:
    return str(path.relative_to(PROJECT_DIR))


def read_csv_rows(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def write_csv_rows(path: Path, rows: list[dict[str, str]], fieldnames: Iterable[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(fieldnames))
        writer.writeheader()
        writer.writerows(rows)


def active_batch_number(path: Path) -> int | None:
    match = ACTIVE_BATCH_RE.match(path.name)
    return int(match.group(1)) if match else None


def active_batch_paths(batch_dir: Path) -> list[Path]:
    numbered = [
        (number, path)
        for path in batch_dir.glob("active_batch_*.csv")
        if (number := active_batch_number(path)) is not None
    ]
    return [path for _, path in sorted(numbered)]


def next_active_label(batch_dir: Path, planned_labels: set[str]) -> str:
    numbers = [
        number
        for path in batch_dir.glob("active_batch_*.csv")
        if (number := active_batch_number(path)) is not None
    ]
    next_number = (max(numbers) + 1) if numbers else 1
    while f"active_batch_{next_number:03d}" in planned_labels:
        next_number += 1
    return f"active_batch_{next_number:03d}"


def complete_manifest_pids(manifest_rows: list[dict[str, str]], out_dir: Path) -> set[str]:
    complete: set[str] = set()
    for row in manifest_rows:
        pid = row["pid"]
        if (
            (out_dir / "reading_logs" / f"{pid}.json").exists()
            and (out_dir / "classifications" / f"{pid}.json").exists()
        ):
            complete.add(pid)
    return complete


def batch_status(path: Path, complete_pids: set[str], out_dir: Path, *, created_now: bool = False) -> BatchStatus:
    rows = read_csv_rows(path)
    pids = [row["pid"] for row in rows]
    failed_pids = {pid for pid in pids if (out_dir / "failed" / f"{pid}.txt").exists()}
    return BatchStatus(
        label=path.stem,
        manifest_path=path,
        rows=rows,
        complete_pids=set(pids) & complete_pids,
        failed_pids=failed_pids,
        created_now=created_now,
    )


def select_pending_rows(
    manifest_rows: list[dict[str, str]],
    complete_pids: set[str],
    reserved_pids: set[str],
    limit: int,
) -> list[dict[str, str]]:
    selected: list[dict[str, str]] = []
    for row in manifest_rows:
        pid = row["pid"]
        if pid in complete_pids or pid in reserved_pids:
            continue
        selected.append(row)
        if len(selected) >= limit:
            break
    return selected


def md_escape(value: object) -> str:
    return str(value).replace("|", "\\|")


def md_table(rows: list[dict[str, object]], columns: list[str]) -> str:
    if not rows:
        return "_Nenhum caso._"
    header = " | ".join(columns)
    separator = " | ".join(["---"] * len(columns))
    body = [" | ".join(md_escape(row.get(column, "")) for column in columns) for row in rows]
    return "\n".join([header, separator, *body])


def journal_count_rows(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    counts = Counter(row.get("journal_title", "") for row in rows)
    return [
        {"journal_title": journal, "n": n}
        for journal, n in sorted(counts.items(), key=lambda item: (-item[1], item[0]))
    ]


def bounds_row(batch: BatchStatus) -> dict[str, object]:
    if not batch.rows:
        return {
            "first_eligible_order": "",
            "last_eligible_order": "",
            "first_pid": "",
            "last_pid": "",
        }
    orders = [int(row["eligible_order"]) for row in batch.rows if row.get("eligible_order")]
    return {
        "first_eligible_order": min(orders) if orders else "",
        "last_eligible_order": max(orders) if orders else "",
        "first_pid": batch.pids[0],
        "last_pid": batch.pids[-1],
    }


def build_batch_command(args: argparse.Namespace, batch: BatchStatus) -> list[str]:
    cmd = [
        "python3",
        "scripts/25_run_credibility_prompt_v3_integral_codex_batch.py",
        "--manifest",
        project_relative(batch.manifest_path),
        "--out-dir",
        project_relative(args.out_dir),
        "--timeout",
        str(args.timeout),
        "--codex-bin",
        args.codex_bin,
        "--model-reasoning-effort",
        args.model_reasoning_effort,
        "--combined-stem",
        batch.label,
    ]
    if args.model:
        cmd.extend(["--model", args.model])
    if args.ephemeral:
        cmd.append("--ephemeral")
    if args.force:
        cmd.append("--force")
    return cmd


def command_line(cmd: list[str]) -> str:
    return " ".join(cmd)


def write_selection_report(
    args: argparse.Namespace,
    batch: BatchStatus,
    manifest_rows: list[dict[str, str]],
    complete_count: int,
    reserved_before_count: int,
) -> Path:
    report_path = args.quality_dir / f"credibility_prompt_v3_{batch.label}_selection.md"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    summary_rows = [
        {"indicador": "artigos no manifesto ativo", "valor": len(manifest_rows)},
        {"indicador": "artigos já completos no manifesto ativo", "valor": complete_count},
        {"indicador": "PIDs pendentes já reservados por outros batches", "valor": reserved_before_count},
        {"indicador": "artigos selecionados neste bloco", "valor": len(batch.rows)},
    ]
    lines = [
        f"# Seleção de batch: {batch.label}",
        "",
        f"Gerado em: {datetime.now().astimezone().strftime('%Y-%m-%d %H:%M:%S %z')}",
        "",
        "## Tabela 1. Síntese",
        "",
        md_table(summary_rows, ["indicador", "valor"]),
        "",
        "## Tabela 2. Limites do bloco",
        "",
        md_table([bounds_row(batch)], ["first_eligible_order", "last_eligible_order", "first_pid", "last_pid"]),
        "",
        "## Tabela 3. Periódicos no bloco",
        "",
        md_table(journal_count_rows(batch.rows), ["journal_title", "n"]),
        "",
        "## Arquivos",
        "",
        f"- Manifesto ativo: `{project_relative(args.manifest)}`.",
        f"- Manifesto congelado do bloco: `{project_relative(batch.manifest_path)}`.",
    ]
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return report_path


def write_plan_reports(args: argparse.Namespace, batches: list[BatchStatus], manifest_rows: list[dict[str, str]]) -> None:
    args.plan_md.parent.mkdir(parents=True, exist_ok=True)
    args.plan_json.parent.mkdir(parents=True, exist_ok=True)

    slot_rows = []
    journal_rows = []
    for batch in batches:
        bounds = bounds_row(batch)
        slot_rows.append(
            {
                "batch": batch.label,
                "origem": "criado agora" if batch.created_now else "existente incompleto",
                "artigos": len(batch.rows),
                "completos": len(batch.complete_pids),
                "faltantes": len(batch.missing_pids),
                "falhas": len(batch.failed_pids),
                "first_eligible_order": bounds["first_eligible_order"],
                "last_eligible_order": bounds["last_eligible_order"],
            }
        )
        for item in journal_count_rows(batch.rows):
            journal_rows.append({"batch": batch.label, **item})

    labels = [batch.label for batch in batches]
    runner_cmd = [
        "python3",
        "scripts/41_run_credibility_integral_parallel_batches.py",
        "--labels",
        *labels,
        "--model-reasoning-effort",
        args.model_reasoning_effort,
        "--timeout",
        str(args.timeout),
        "--run",
    ]
    if args.model:
        runner_cmd.extend(["--model", args.model])
    if args.ephemeral:
        runner_cmd.append("--ephemeral")
    if args.force:
        runner_cmd.append("--force")

    manual_commands = [build_batch_command(args, batch) for batch in batches]

    lines = [
        "# Plano para batches paralelos do corpus integral",
        "",
        f"Gerado em: {datetime.now().astimezone().strftime('%Y-%m-%d %H:%M:%S %z')}",
        "",
        "Este plano só prepara manifests e comandos; nenhum artigo foi classificado nesta etapa.",
        "",
        "## Tabela 1. Configuração",
        "",
        md_table(
            [
                {"campo": "slots paralelos", "valor": len(batches)},
                {"campo": "limite por novo batch", "valor": args.limit},
                {"campo": "model_reasoning_effort", "valor": args.model_reasoning_effort},
                {"campo": "manifesto ativo", "valor": project_relative(args.manifest)},
                {"campo": "artigos no manifesto", "valor": len(manifest_rows)},
            ],
            ["campo", "valor"],
        ),
        "",
        "## Tabela 2. Batches preparados",
        "",
        md_table(
            slot_rows,
            [
                "batch",
                "origem",
                "artigos",
                "completos",
                "faltantes",
                "falhas",
                "first_eligible_order",
                "last_eligible_order",
            ],
        ),
        "",
        "## Tabela 3. Periódicos por batch",
        "",
        md_table(journal_rows, ["batch", "journal_title", "n"]),
        "",
        "## Comando recomendado",
        "",
        "```bash",
        command_line(runner_cmd),
        "```",
        "",
        "## Comandos manuais equivalentes",
        "",
    ]
    for cmd in manual_commands:
        lines.extend(["```bash", command_line(cmd), "```", ""])
    lines.extend(
        [
            "## Observação operacional",
            "",
            "Não execute dois `scripts/36_run_credibility_integral_next_batch.py --run` em paralelo. "
            "Use o comando recomendado acima ou os comandos manuais com manifests distintos e `--combined-stem` distinto.",
        ]
    )
    args.plan_md.write_text("\n".join(lines) + "\n", encoding="utf-8")

    plan_data = {
        "generated_at": datetime.now().astimezone().isoformat(),
        "labels": labels,
        "model": args.model,
        "model_reasoning_effort": args.model_reasoning_effort,
        "timeout": args.timeout,
        "manifest": project_relative(args.manifest),
        "out_dir": project_relative(args.out_dir),
        "batches": [
            {
                "label": batch.label,
                "manifest": project_relative(batch.manifest_path),
                "created_now": batch.created_now,
                "n_manifest": len(batch.rows),
                "n_complete": len(batch.complete_pids),
                "n_missing": len(batch.missing_pids),
                "n_failed_files": len(batch.failed_pids),
                "missing_pids": batch.missing_pids,
                "command": build_batch_command(args, batch),
            }
            for batch in batches
        ],
        "runner_command": runner_cmd,
    }
    args.plan_json.write_text(json.dumps(plan_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    args.manifest = as_project_path(args.manifest)
    args.out_dir = as_project_path(args.out_dir)
    args.batch_dir = as_project_path(args.batch_dir)
    args.quality_dir = as_project_path(args.quality_dir)
    args.plan_md = as_project_path(args.plan_md)
    args.plan_json = as_project_path(args.plan_json)

    if args.workers <= 0:
        raise SystemExit("--workers deve ser positivo.")
    if args.limit <= 0:
        raise SystemExit("--limit deve ser positivo.")
    if not args.manifest.exists():
        raise SystemExit(f"Manifesto ausente: {args.manifest}")
    if not args.out_dir.exists():
        raise SystemExit(f"Diretório de outputs ausente: {args.out_dir}")

    manifest_rows = read_csv_rows(args.manifest)
    manifest_fieldnames = list(manifest_rows[0].keys()) if manifest_rows else []
    complete_pids = complete_manifest_pids(manifest_rows, args.out_dir)

    incomplete_existing = [
        status
        for path in active_batch_paths(args.batch_dir)
        if not (status := batch_status(path, complete_pids, args.out_dir)).is_complete
    ]
    planned_batches = incomplete_existing[: args.workers]
    planned_labels = {batch.label for batch in planned_batches}
    reserved_pids = {pid for batch in incomplete_existing for pid in batch.pids}

    while len(planned_batches) < args.workers:
        label = next_active_label(args.batch_dir, planned_labels)
        batch_path = args.batch_dir / f"{label}.csv"
        selected = select_pending_rows(manifest_rows, complete_pids, reserved_pids, args.limit)
        if not selected:
            break
        write_csv_rows(batch_path, selected, manifest_fieldnames)
        batch = batch_status(batch_path, complete_pids, args.out_dir, created_now=True)
        write_selection_report(
            args,
            batch,
            manifest_rows,
            complete_count=len(complete_pids),
            reserved_before_count=len(reserved_pids - complete_pids),
        )
        planned_batches.append(batch)
        planned_labels.add(label)
        reserved_pids.update(batch.pids)

    if len(planned_batches) < args.workers:
        raise SystemExit(
            f"Apenas {len(planned_batches)} batch(es) puderam ser preparados para {args.workers} worker(s)."
        )

    write_plan_reports(args, planned_batches, manifest_rows)

    print(f"Prepared {len(planned_batches)} parallel batch slots:")
    for batch in planned_batches:
        source = "created" if batch.created_now else "existing"
        print(
            f"- {batch.label}: {source}, manifest={project_relative(batch.manifest_path)}, "
            f"complete={len(batch.complete_pids)}/{len(batch.rows)}, missing={len(batch.missing_pids)}, "
            f"failed_files={len(batch.failed_pids)}"
        )
    print(f"Plan: {project_relative(args.plan_md)}")
    print(f"Plan JSON: {project_relative(args.plan_json)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
