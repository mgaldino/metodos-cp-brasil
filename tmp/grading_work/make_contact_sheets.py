"""Cria folhas de contato para a revisão visual dos PDFs entregues."""

from pathlib import Path

from PIL import Image, ImageDraw


def build_contact(source_dir: Path, output_path: Path, columns: int = 3) -> None:
    pages = sorted(source_dir.glob("page-*.png"))
    if not pages:
        raise FileNotFoundError(f"Nenhuma página renderizada em {source_dir}")

    thumb_width = 306
    gap = 12
    label_height = 24
    thumbs: list[Image.Image] = []
    for page_path in pages:
        with Image.open(page_path) as image:
            thumb = image.convert("RGB")
            ratio = thumb_width / thumb.width
            thumb = thumb.resize(
                (thumb_width, round(thumb.height * ratio)),
                Image.Resampling.LANCZOS,
            )
            thumbs.append(thumb)

    row_height = max(image.height for image in thumbs) + label_height
    rows = (len(thumbs) + columns - 1) // columns
    canvas = Image.new(
        "RGB",
        (
            columns * thumb_width + (columns + 1) * gap,
            rows * row_height + (rows + 1) * gap,
        ),
        "white",
    )
    draw = ImageDraw.Draw(canvas)

    for index, thumb in enumerate(thumbs):
        row, column = divmod(index, columns)
        x = gap + column * (thumb_width + gap)
        y = gap + row * (row_height + gap)
        canvas.paste(thumb, (x, y + label_height))
        draw.text((x, y + 3), f"Página {index + 1}", fill="black")

    canvas.save(output_path, optimize=True)


if __name__ == "__main__":
    root = Path("/Users/manoelgaldino/Documents/DCP/Papers/metodos_CP/tmp/pdfs")
    for student in ("carmen", "mariana"):
        build_contact(root / student, root / student / "contact.png")
