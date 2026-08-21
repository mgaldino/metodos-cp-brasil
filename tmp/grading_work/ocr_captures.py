#!/usr/bin/env python3
"""Extrai texto das capturas autenticadas do Moodle de forma reproduzível.

Cada captura contém a janela do corretor. O recorte usado pelo OCR corresponde
somente ao painel esquerdo do PDF (x=0..895, y=190..650). Os segmentos topo,
meio e fim são mantidos com marcadores para preservar a proveniência visual.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image


CROP_BOX = (0, 190, 895, 650)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def ocr_one(path: Path) -> dict[str, str | int]:
    with Image.open(path) as image:
        crop = image.crop(CROP_BOX)
        buffer = io.BytesIO()
        crop.save(buffer, format="PNG")
    proc = subprocess.run(
        ["tesseract", "stdin", "stdout", "-l", "por", "--psm", "6"],
        input=buffer.getvalue(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    return {
        "path": str(path),
        "sha256": sha256(path),
        "returncode": proc.returncode,
        "text": proc.stdout.decode("utf-8", errors="replace").strip(),
        "stderr": proc.stderr.decode("utf-8", errors="replace").strip(),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--captures", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--jobs", type=int, default=6)
    args = parser.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    images = sorted(
        path
        for path in args.captures.glob("*/page_*_*.png")
        if path.name.endswith(("_top.png", "_mid.png", "_bot.png"))
    )
    results: dict[Path, dict[str, str | int]] = {}
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = {pool.submit(ocr_one, path): path for path in images}
        for future in as_completed(futures):
            path = futures[future]
            results[path] = future.result()

    manifest: list[dict[str, str | int]] = []
    by_student: dict[str, list[Path]] = {}
    for path in images:
        by_student.setdefault(path.parent.name, []).append(path)

    for nusp, paths in sorted(by_student.items()):
        chunks: list[str] = []
        for path in paths:
            record = results[path]
            manifest.append({key: value for key, value in record.items() if key != "text"})
            chunks.append(f"\n===== {path.name} =====\n{record['text']}\n")
        (args.output / f"{nusp}.txt").write_text("".join(chunks), encoding="utf-8")

    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "captures_root": str(args.captures),
        "crop_box": CROP_BOX,
        "language": "por",
        "psm": 6,
        "images": len(images),
        "students": len(by_student),
        "failures": sum(int(item["returncode"] != 0) for item in manifest),
        "files": manifest,
    }
    (args.output / "manifest.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps({key: payload[key] for key in ("images", "students", "failures")}))


if __name__ == "__main__":
    main()
