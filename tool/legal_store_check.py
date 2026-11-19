#!/usr/bin/env python3
"""Prueft vor einem Store-Upload, dass die Rechtstexte keine offenen
Pflicht-Platzhalter ({{NAME}}) mehr haben (N7).

Fuer Store-Workflows, die nicht ueber .github/actions/write-config bauen und
deshalb tool/gen_legal_html.dart --strict nicht laufen lassen:

  store-google.yml  liest die Texte aus dem fertigen AAB (--aab dist/x.aab)
  store-snap.yml    fuellt die Texte im Checkout aus LEGAL_VALUES_JSON (--fill)
                    und prueft sie, bevor snapcraft baut

Pflicht ist, was in assets/legal/placeholders.json nicht "required": false
traegt (dieselbe Regel wie gen_legal_html.dart). Nur Standardbibliothek.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import zipfile
from pathlib import Path

PLACEHOLDER = re.compile(r"\{\{(\w+)\}\}")
KINDS = ("impressum", "datenschutz")
LANGS = ("de", "en")
AAB_PREFIX = "base/assets/flutter_assets/assets/legal"


def required_names(meta_path: Path) -> set[str]:
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    return {
        name
        for name, info in meta["placeholders"].items()
        if not (isinstance(info, dict) and info.get("required") is False)
    }


def fill(text: str, values: dict[str, str]) -> str:
    """Ersetzt bekannte Platzhalter JSON-sicher (wie substituteJsonText)."""

    def repl(m: re.Match[str]) -> str:
        name = m.group(1)
        if name not in values:
            return m.group(0)
        return json.dumps(values[name], ensure_ascii=False)[1:-1]

    return PLACEHOLDER.sub(repl, text)


def texts_from_repo(root: Path) -> dict[str, str]:
    return {
        f"{lang}/{kind}.json": (root / "assets/legal" / lang / f"{kind}.json").read_text(
            encoding="utf-8"
        )
        for lang in LANGS
        for kind in KINDS
    }


def texts_from_aab(aab: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    with zipfile.ZipFile(aab) as z:
        for lang in LANGS:
            for kind in KINDS:
                name = f"{AAB_PREFIX}/{lang}/{kind}.json"
                try:
                    out[f"{lang}/{kind}.json"] = z.read(name).decode("utf-8")
                except KeyError:
                    raise SystemExit(f"FEHLER: {name} fehlt im AAB {aab}")
    return out


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", default=".", help="Repo-Wurzel (Standard: .)")
    ap.add_argument("--aab", help="Texte aus diesem AAB lesen statt aus dem Repo")
    ap.add_argument(
        "--fill",
        action="store_true",
        help="Werte aus der Umgebungsvariable LEGAL_VALUES_JSON in assets/legal einsetzen",
    )
    args = ap.parse_args(argv)
    root = Path(args.root)
    required = required_names(root / "assets/legal/placeholders.json")

    if args.aab:
        texts = texts_from_aab(Path(args.aab))
    else:
        texts = texts_from_repo(root)
        if args.fill:
            raw = os.environ.get("LEGAL_VALUES_JSON", "").strip()
            values = json.loads(raw) if raw else {}
            if not isinstance(values, dict):
                raise SystemExit("FEHLER: LEGAL_VALUES_JSON ist kein JSON-Objekt")
            values = {str(k): str(v) for k, v in values.items()}
            for rel, text in texts.items():
                filled = fill(text, values)
                texts[rel] = filled
                (root / "assets/legal" / rel).write_text(filled, encoding="utf-8")

    problems = []
    for rel, text in sorted(texts.items()):
        open_required = sorted(set(PLACEHOLDER.findall(text)) & required)
        if open_required:
            problems.append(f"{rel}: {', '.join(open_required)}")
    if problems:
        print("FEHLER: offene Pflicht-Platzhalter in den Rechtstexten:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        print("Werte in der Variable LEGAL_VALUES_JSON setzen (siehe docs/EINRICHTUNG.md).", file=sys.stderr)
        return 1
    print("Rechtstexte: keine offenen Pflicht-Platzhalter.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
