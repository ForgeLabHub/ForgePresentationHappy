#!/usr/bin/env python3
"""Проверяет, что каждый артефакт действительно открывается своим парсером.

Расширение файла ничего не доказывает: обрезанный .pptx откроется с ошибкой уже
у получателя. Здесь используются те же библиотеки, что и у читателя.
"""
from __future__ import annotations

import sys
from pathlib import Path

OK, FAIL = "  \033[32mok\033[0m    ", "  \033[31mfail\033[0m  "


def check_pptx(path: Path) -> str:
    from pptx import Presentation

    deck = Presentation(path)
    return f"{len(deck.slides)} слайдов"


def check_docx(path: Path) -> str:
    from docx import Document

    document = Document(path)
    return f"{len(document.paragraphs)} абзацев"


def check_pdf(path: Path) -> str:
    data = path.read_bytes()
    if not data.startswith(b"%PDF"):
        raise ValueError("нет сигнатуры %PDF")
    if b"%%EOF" not in data[-1024:]:
        raise ValueError("нет маркера конца %%EOF — файл обрезан")
    return f"{len(data) // 1024} КБ"


def check_mp4(path: Path) -> str:
    data = path.read_bytes()
    if b"ftyp" not in data[:64]:
        raise ValueError("нет атома ftyp — это не MP4")
    if b"moov" not in data:
        raise ValueError("нет атома moov — файл не пригоден для воспроизведения")
    return f"{len(data) // 1024 // 1024} МБ"


def check_html(path: Path) -> str:
    text = path.read_text(encoding="utf-8", errors="replace")
    if "<html" not in text.lower():
        raise ValueError("нет корневого элемента html")
    if "</html>" not in text.lower():
        raise ValueError("документ не закрыт — файл обрезан")
    return f"{len(text) // 1024} КБ"


CHECKERS = {
    ".pptx": check_pptx,
    ".docx": check_docx,
    ".pdf": check_pdf,
    ".mp4": check_mp4,
    ".html": check_html,
}


def main() -> int:
    failures = 0
    files = sorted(p for p in Path(".").iterdir() if p.suffix.lower() in CHECKERS)
    if not files:
        print(FAIL + "не найдено ни одного артефакта")
        return 1
    for path in files:
        try:
            detail = CHECKERS[path.suffix.lower()](path)
        except Exception as error:  # noqa: BLE001 - печатаем причину как есть
            print(f"{FAIL}{path.name}: {error}")
            failures += 1
        else:
            print(f"{OK}{path.name}: {detail}")
    if failures:
        print(f"\n\033[31mпроблем: {failures}\033[0m")
        return 1
    print("\n\033[32mвсе артефакты открываются\033[0m")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
