#!/usr/bin/env python3
"""Organiza e valida o download em massa do trabalho final no Moodle.

Fonte: https://edisciplinas.usp.br/mod/assign/view.php?id=6364861&action=grading
Acesso: download em massa autenticado, confirmado manualmente no navegador
Credenciais: não são lidas nem armazenadas por este script
Última execução esperada: 2026-08-21

O ZIP original é preservado sem modificações. Os anexos são extraídos para
pastas identificadas pelo número USP e pelo nome constante do inventário do
Moodle. Um manifesto CSV, checksums SHA-256 e um relatório de completude são
gerados junto dos arquivos.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import logging
import re
import shutil
import stat
import subprocess
import tempfile
import unicodedata
import zipfile
from collections import Counter, defaultdict, deque
from datetime import datetime
from difflib import SequenceMatcher
from pathlib import Path, PurePosixPath
from urllib.parse import unquote, urlparse


logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
LOGGER = logging.getLogger(__name__)

SOURCE_URL = "https://edisciplinas.usp.br/mod/assign/view.php?id=6364861&action=grading"
ACTIVITY_ID = 6364861
COURSE_ID = 139474


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--zip", required=True, type=Path, dest="zip_path")
    parser.add_argument("--inventory", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args()


def normalize_text(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    value = value.casefold()
    return re.sub(r"[^a-z0-9]+", " ", value).strip()


def safe_component(value: str) -> str:
    value = unicodedata.normalize("NFC", value).strip()
    value = re.sub(r"[\\/:\0]", "_", value)
    value = re.sub(r"\s+", " ", value)
    return value.rstrip(". ") or "sem_nome"


def sha256_path(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_inventory(path: Path) -> tuple[dict, list[dict]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("activityId") != ACTIVITY_ID or data.get("courseId") != COURSE_ID:
        raise RuntimeError("O inventário não corresponde à atividade/ao curso esperados.")
    participants = [p for p in data["participants"] if p.get("files")]
    if not participants:
        raise RuntimeError("O inventário não contém envios.")
    return data, participants


def archive_groups(zf: zipfile.ZipFile) -> dict[str, list[zipfile.ZipInfo]]:
    groups: dict[str, list[zipfile.ZipInfo]] = defaultdict(list)
    for info in zf.infolist():
        if info.is_dir():
            continue
        posix = PurePosixPath(info.filename)
        if posix.is_absolute() or ".." in posix.parts or len(posix.parts) < 2:
            raise RuntimeError(f"Caminho inseguro ou inesperado no ZIP: {info.filename!r}")
        mode = (info.external_attr >> 16) & 0xFFFF
        if stat.S_ISLNK(mode):
            raise RuntimeError(f"Link simbólico não permitido no ZIP: {info.filename!r}")
        groups[posix.parts[0]].append(info)
    return dict(groups)


def folder_student_name(folder: str) -> str:
    return re.sub(r"_\d+_assignsubmission_file$", "", folder)


def expected_names(participant: dict) -> Counter:
    return Counter(normalize_text(Path(item["fileName"]).name) for item in participant["files"])


def actual_names(infos: list[zipfile.ZipInfo]) -> Counter:
    return Counter(normalize_text(PurePosixPath(info.filename).name) for info in infos)


def similarity(folder: str, infos: list[zipfile.ZipInfo], participant: dict) -> float:
    archive_name = normalize_text(folder_student_name(folder))
    participant_name = normalize_text(participant["name"])
    name_score = SequenceMatcher(None, archive_name, participant_name).ratio()
    expected = expected_names(participant)
    actual = actual_names(infos)
    common = sum((expected & actual).values())
    file_score = common / max(sum(expected.values()), sum(actual.values()), 1)
    return 0.78 * name_score + 0.22 * file_score


def match_groups(groups: dict[str, list[zipfile.ZipInfo]], participants: list[dict]) -> dict[str, dict]:
    candidates: list[tuple[float, str, int]] = []
    for folder, infos in groups.items():
        for idx, participant in enumerate(participants):
            candidates.append((similarity(folder, infos, participant), folder, idx))
    candidates.sort(reverse=True)

    assigned_folders: set[str] = set()
    assigned_participants: set[int] = set()
    matches: dict[str, dict] = {}
    scores: dict[str, float] = {}
    for score, folder, idx in candidates:
        if folder in assigned_folders or idx in assigned_participants:
            continue
        assigned_folders.add(folder)
        assigned_participants.add(idx)
        matches[folder] = participants[idx]
        scores[folder] = score

    if len(matches) != len(groups) or len(assigned_participants) != len(participants):
        raise RuntimeError("Não foi possível obter uma correspondência um-a-um entre pastas e alunos.")

    low = [(folder, matches[folder]["name"], scores[folder]) for folder in matches if scores[folder] < 0.72]
    if low:
        raise RuntimeError(f"Correspondências de baixa confiança: {low}")

    for folder, participant in matches.items():
        if actual_names(groups[folder]) != expected_names(participant):
            raise RuntimeError(
                "Os nomes dos anexos divergem do inventário para "
                f"{participant['name']!r}: {folder!r}"
            )
    return matches


def file_url_queues(participant: dict) -> dict[str, deque[str]]:
    queues: dict[str, deque[str]] = defaultdict(deque)
    for item in participant["files"]:
        queues[normalize_text(Path(item["fileName"]).name)].append(item["url"])
    return queues


def submission_file_id(url: str) -> str:
    match = re.search(r"/submission_files/(\d+)/", url)
    return match.group(1) if match else ""


def validate_pdf(path: Path) -> tuple[str, str]:
    with path.open("rb") as handle:
        if handle.read(5) != b"%PDF-":
            return "FALHA", "assinatura PDF ausente"
    pdfinfo = shutil.which("pdfinfo")
    if not pdfinfo:
        return "PARCIAL", "assinatura válida; pdfinfo indisponível"
    result = subprocess.run([pdfinfo, str(path)], capture_output=True, text=True, check=False)
    if result.returncode != 0:
        return "FALHA", result.stderr.strip()[:300]
    pages = re.search(r"^Pages:\s*(\d+)", result.stdout, flags=re.MULTILINE)
    return "OK", f"{pages.group(1)} página(s)" if pages else "pdfinfo OK"


def validate_zip_container(path: Path) -> tuple[str, str]:
    try:
        with zipfile.ZipFile(path) as nested:
            bad = nested.testzip()
            if bad:
                return "FALHA", f"entrada corrompida: {bad}"
    except zipfile.BadZipFile as exc:
        return "FALHA", str(exc)
    return "OK", "estrutura ZIP íntegra"


def validate_file(path: Path) -> tuple[str, str]:
    if path.stat().st_size <= 0:
        return "FALHA", "arquivo vazio"
    suffix = path.suffix.casefold()
    if suffix == ".pdf":
        return validate_pdf(path)
    if suffix in {".zip", ".xlsx"}:
        return validate_zip_container(path)
    return "OK", "arquivo não vazio"


def write_csv(path: Path, rows: list[dict]) -> None:
    fields = [
        "nusp",
        "nome",
        "email",
        "status_moodle",
        "ultima_modificacao",
        "moodle_user_id",
        "moodle_submission_file_id",
        "pasta_original_zip",
        "caminho_relativo",
        "nome_arquivo",
        "extensao",
        "bytes",
        "sha256",
        "validacao",
        "detalhe_validacao",
        "url_moodle",
    ]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def yaml_quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def build_bundle(zip_path: Path, inventory_path: Path, stage: Path) -> dict:
    inventory, participants = load_inventory(inventory_path)
    raw_dir = stage / "_raw"
    script_dir = stage / "_scripts"
    raw_dir.mkdir(parents=True)
    script_dir.mkdir(parents=True)

    raw_copy = raw_dir / "FLP0406-2026-Trabalho_Final-6364861.zip"
    shutil.copy2(zip_path, raw_copy)
    shutil.copy2(Path(__file__).resolve(), script_dir / Path(__file__).name)

    manifest_rows: list[dict] = []
    validation_failures: list[str] = []
    extension_counts: Counter[str] = Counter()

    with zipfile.ZipFile(zip_path) as zf:
        corrupt = zf.testzip()
        if corrupt:
            raise RuntimeError(f"Entrada corrompida no ZIP bruto: {corrupt}")
        groups = archive_groups(zf)
        if len(groups) != len(participants):
            raise RuntimeError(
                f"Pastas de alunos no ZIP ({len(groups)}) != alunos com envio ({len(participants)})."
            )
        matches = match_groups(groups, participants)

        for folder in sorted(groups, key=normalize_text):
            participant = matches[folder]
            # O nome da pasta do ZIP é o rótulo efetivamente exportado pelo
            # Moodle. Ele evita artefatos ocasionais da leitura da tabela HTML
            # (por exemplo, texto de avatar colado ao início do nome).
            display_name = folder_student_name(folder)
            student_dir = stage / f"{participant['nusp']} - {safe_component(display_name)}"
            student_dir.mkdir()
            url_queues = file_url_queues(participant)

            for info in sorted(groups[folder], key=lambda item: normalize_text(item.filename)):
                original = PurePosixPath(info.filename)
                relative_parts = original.parts[1:]
                output = student_dir.joinpath(*(safe_component(part) for part in relative_parts))
                output.parent.mkdir(parents=True, exist_ok=True)
                with zf.open(info) as source, output.open("wb") as destination:
                    shutil.copyfileobj(source, destination)

                norm_base = normalize_text(original.name)
                if not url_queues[norm_base]:
                    raise RuntimeError(f"URL não encontrada para {participant['name']}: {original.name}")
                url = url_queues[norm_base].popleft()
                status, detail = validate_file(output)
                if status == "FALHA":
                    validation_failures.append(str(output.relative_to(stage)))
                suffix = output.suffix.casefold() or "[sem extensão]"
                extension_counts[suffix] += 1
                relative = output.relative_to(stage).as_posix()
                manifest_rows.append(
                    {
                        "nusp": participant["nusp"],
                        "nome": display_name,
                        "email": participant["email"],
                        "status_moodle": participant["status"],
                        "ultima_modificacao": participant["modified"],
                        "moodle_user_id": participant["moodleUserId"],
                        "moodle_submission_file_id": submission_file_id(url),
                        "pasta_original_zip": folder,
                        "caminho_relativo": relative,
                        "nome_arquivo": output.name,
                        "extensao": suffix,
                        "bytes": output.stat().st_size,
                        "sha256": sha256_path(output),
                        "validacao": status,
                        "detalhe_validacao": detail,
                        "url_moodle": url,
                    }
                )

            leftovers = [key for key, queue in url_queues.items() if queue]
            if leftovers:
                raise RuntimeError(f"Anexos esperados não extraídos para {participant['name']}: {leftovers}")

    expected_files = sum(len(p["files"]) for p in participants)
    if len(manifest_rows) != expected_files:
        raise RuntimeError(f"Arquivos extraídos ({len(manifest_rows)}) != esperados ({expected_files}).")
    if validation_failures:
        raise RuntimeError(f"Falhas de integridade: {validation_failures}")

    manifest_path = stage / "_manifesto_arquivos.csv"
    write_csv(manifest_path, manifest_rows)

    collected_at = datetime.now().astimezone().isoformat(timespec="seconds")
    raw_hash = sha256_path(raw_copy)
    sources = f"""sources:
  - id: moodle_trabalho_final_6364861
    name: {yaml_quote('Trabalho Final — FLP0406-2026')}
    provider: {yaml_quote('e-Disciplinas USP (Moodle)')}
    url: {yaml_quote(SOURCE_URL)}
    access_method: manual_bulk_download
    requires_credentials: true
    license: {yaml_quote('Material discente de acesso restrito; uso acadêmico interno')}
    download_script: {yaml_quote('Não aplicável: confirmação manual exigida pelo navegador')}
    organization_script: {yaml_quote('_scripts/organize_moodle_submissions.py')}
    date_accessed: {yaml_quote(collected_at)}
    course_id: {COURSE_ID}
    activity_id: {ACTIVITY_ID}
    raw_sha256: {yaml_quote(raw_hash)}
"""
    (stage / "_SOURCES.yaml").write_text(sources, encoding="utf-8")

    dictionary = """# Dicionário do manifesto de arquivos

O arquivo `_manifesto_arquivos.csv` tem uma linha por anexo entregue no Moodle.

**Tabela 1. Campos do manifesto**

| Campo | Tipo | Descrição |
|---|---|---|
| `nusp` | texto | Número USP do estudante. |
| `nome` | texto | Nome no diretório exportado pelo Moodle. |
| `email` | texto | E-mail cadastrado no Moodle. |
| `status_moodle` | texto | Situação do envio no momento do inventário. |
| `ultima_modificacao` | texto | Data exibida pelo Moodle. |
| `moodle_user_id` | texto | Identificador interno do usuário no Moodle. |
| `moodle_submission_file_id` | texto | Identificador interno do conjunto de anexos. |
| `pasta_original_zip` | texto | Pasta de origem dentro do ZIP bruto. |
| `caminho_relativo` | texto | Local do arquivo nesta coleção. |
| `nome_arquivo` | texto | Nome original do anexo. |
| `extensao` | texto | Extensão em letras minúsculas. |
| `bytes` | inteiro | Tamanho do arquivo. |
| `sha256` | texto | Hash SHA-256 do anexo extraído. |
| `validacao` | texto | Resultado da verificação de integridade. |
| `detalhe_validacao` | texto | Detalhe do teste aplicado. |
| `url_moodle` | texto | URL autenticada de origem do anexo. |
"""
    (stage / "_DATA_DICTIONARY.md").write_text(dictionary, encoding="utf-8")

    count_lines = "\n".join(
        f"| `{ext}` | {count} |" for ext, count in sorted(extension_counts.items())
    )
    validation_counts = Counter(row["validacao"] for row in manifest_rows)
    log = f"""# Relatório de coleta

Data: {collected_at}

Fonte: e-Disciplinas USP, atividade {ACTIVITY_ID} do curso {COURSE_ID}.

## Cobertura esperada e obtida

- Participantes no inventário: {len(inventory['participants'])}
- Estudantes com envio: {len(participants)}
- Pastas de estudantes no ZIP: {len(participants)}
- Anexos esperados: {expected_files}
- Anexos extraídos: {len(manifest_rows)}
- Divergências entre o ZIP e o inventário: 0
- Falhas de integridade: 0
- Validações OK: {validation_counts.get('OK', 0)}
- Validações parciais: {validation_counts.get('PARCIAL', 0)}

## Formatos coletados

**Tabela 1. Número de anexos por extensão**

| Extensão | Arquivos |
|---|---:|
{count_lines}

## Integridade e proveniência

- SHA-256 do ZIP bruto: `{raw_hash}`
- Teste interno do ZIP: aprovado.
- PDFs: assinatura `%PDF-` e leitura por `pdfinfo` quando disponível.
- Arquivos `.zip` e `.xlsx`: estrutura ZIP testada.
- Demais formatos: presença e tamanho maior que zero.
- O ZIP original foi copiado sem modificação para `_raw/`.

## Gaps

Nenhum gap identificado entre o inventário autenticado do Moodle e o pacote em massa.
"""
    (stage / "_COLLECTION_LOG.md").write_text(log, encoding="utf-8")

    readme = f"""# Entregas do Moodle — Trabalho Final FLP0406-2026

Esta pasta contém os anexos do trabalho final baixados em massa do e-Disciplinas USP em {collected_at}.

## Organização

- Uma pasta por estudante, nomeada como `NÚMERO USP - Nome`.
- `_raw/`: ZIP bruto preservado sem alterações.
- `_manifesto_arquivos.csv`: uma linha por anexo, com origem, validação e SHA-256.
- `_checksums.sha256`: hashes dos arquivos da coleção.
- `_COLLECTION_LOG.md`: completude, formatos e testes de integridade.
- `_SOURCES.yaml`: proveniência da coleta.
- `_DATA_DICTIONARY.md`: descrição dos campos do manifesto.
- `_scripts/`: script usado para organizar e validar o pacote.

## Verificação

Na raiz desta pasta, execute:

```bash
shasum -a 256 -c _checksums.sha256
```

O ZIP bruto e os anexos extraídos devem permanecer preservados. Novas transformações devem ser gravadas em outro diretório.
"""
    (stage / "README.md").write_text(readme, encoding="utf-8")

    checksum_targets = sorted(
        path for path in stage.rglob("*") if path.is_file() and path.name != "_checksums.sha256"
    )
    checksum_lines = [
        f"{sha256_path(path)}  {path.relative_to(stage).as_posix()}" for path in checksum_targets
    ]
    (stage / "_checksums.sha256").write_text("\n".join(checksum_lines) + "\n", encoding="utf-8")

    return {
        "participants_total": len(inventory["participants"]),
        "students_submitted": len(participants),
        "files": len(manifest_rows),
        "extension_counts": dict(sorted(extension_counts.items())),
        "raw_sha256": raw_hash,
        "validation_counts": dict(validation_counts),
    }


def copy_stage(stage: Path, output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        raise RuntimeError(f"A pasta de destino não está vazia: {output}")
    for child in stage.iterdir():
        destination = output / child.name
        if child.is_dir():
            shutil.copytree(child, destination)
        else:
            shutil.copy2(child, destination)


def main() -> int:
    args = parse_args()
    for path, label in [(args.zip_path, "ZIP"), (args.inventory, "inventário")]:
        if not path.is_file():
            raise FileNotFoundError(f"{label} não encontrado: {path}")
    LOGGER.info("Validando e organizando %s", args.zip_path)
    with tempfile.TemporaryDirectory(prefix="moodle_trabalho_final_") as temp_dir:
        stage = Path(temp_dir) / "bundle"
        stage.mkdir()
        summary = build_bundle(args.zip_path, args.inventory, stage)
        copy_stage(stage, args.output)
    LOGGER.info("Coleta concluída em %s", args.output)
    LOGGER.info("Resumo: %s", json.dumps(summary, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
