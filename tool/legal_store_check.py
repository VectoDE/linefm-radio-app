#!/usr/bin/env python3
"""Prueft vor einem Store-Upload, dass die Rechtstexte keine offenen
Pflicht-Platzhalter ({{NAME}}) mehr haben (N7).

Fuer Store-Workflows, die nicht ueber .github/actions/write-config bauen und
deshalb tool/gen_legal_html.dart --strict nicht laufen lassen:

  store-google.yml  liest die Texte aus dem fertigen AAB (--aab dist/x.aab)
  store-snap.yml    fuellt die Texte im Checkout aus LEGAL_VALUES_JSON (--fill)
                    und prueft sie, bevor snapcraft baut

Regeln wie in gen_legal_html.dart --strict:
  - Pflicht ist, was in assets/legal/placeholders.json nicht "required": false
    traegt. Nicht registrierte Platzhalter sind ebenfalls Pflicht.
  - "required_if" (z. B. "telemetry", "umami") macht eine optionale Angabe zur
    Pflicht, sobald der Anbieter aktiv ist (--providers=umami,sentry,firebase).
  - Leere oder nur aus Leerzeichen bestehende Werte gelten als offen.
  - Die Dateien aus STRICT_FILES (Sicherheitskontakt, Verhaltenskodex,
    Barrierefreiheit) duerfen gar keine Platzhalter mehr enthalten.

Nur Standardbibliothek.
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
TELEMETRY_PROVIDERS = frozenset({"umami", "sentry", "firebase"})

# Gleiche Liste wie strictFiles in tool/gen_legal_html.dart.
STRICT_FILES = (
    "SECURITY.md",
    "CODE_OF_CONDUCT.md",
    "docs/BARRIEREFREIHEIT.md",
    "web/.well-known/security.txt",
)


def requirement_met(requires: object, providers: set[str]) -> bool:
    """Wie requirementMet in gen_legal_html.dart ("!x" = Negation, Liste = UND)."""
    if requires is None:
        return True
    tokens = [str(t) for t in requires] if isinstance(requires, list) else [str(requires)]
    for raw in tokens:
        negate = raw.startswith("!")
        token = raw[1:] if negate else raw
        if token == "telemetry":
            active = bool(providers & TELEMETRY_PROVIDERS)
        else:
            active = token in providers
        if active == negate:
            return False
    return True


def load_registry(meta_path: Path) -> dict[str, object]:
    return json.loads(meta_path.read_text(encoding="utf-8"))["placeholders"]


def is_required(name: str, registry: dict[str, object], providers: set[str]) -> bool:
    info = registry.get(name)
    if not isinstance(info, dict):
        return True  # nicht registriert: Pflicht
    if info.get("required") is not False:
        return True
    cond = info.get("required_if")
    return cond is not None and requirement_met(cond, providers)


def non_blank(values: dict[str, str]) -> dict[str, str]:
    return {k: v for k, v in values.items() if v.strip()}


def fill(text: str, values: dict[str, str]) -> str:
    """Ersetzt bekannte Platzhalter JSON-sicher (wie substituteJsonText).
    Leere Werte werden nicht eingesetzt, der Platzhalter bleibt offen."""
    values = non_blank(values)

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


def parse_providers(raw: str) -> set[str]:
    return {p.strip() for p in raw.split(",") if p.strip()}


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=".", help="Repo-Wurzel (Standard: .)")
    ap.add_argument("--aab", help="Texte aus diesem AAB lesen statt aus dem Repo")
    ap.add_argument(
        "--fill",
        action="store_true",
        help="Werte aus der Umgebungsvariable LEGAL_VALUES_JSON in assets/legal einsetzen",
    )
    ap.add_argument(
        "--providers",
        default="",
        help="aktive Telemetrie-Anbieter, kommagetrennt (umami,sentry,firebase)",
    )
    args = ap.parse_args(argv)
    root = Path(args.root)
    providers = parse_providers(args.providers)
    unknown = providers - TELEMETRY_PROVIDERS
    if unknown:
        raise SystemExit(f"FEHLER: unbekannte Anbieter: {', '.join(sorted(unknown))}")
    registry = load_registry(root / "assets/legal/placeholders.json")

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
        open_required = sorted(
            n for n in set(PLACEHOLDER.findall(text)) if is_required(n, registry, providers)
        )
        if open_required:
            problems.append(f"{rel}: {', '.join(open_required)}")
    for rel in STRICT_FILES:
        path = root / rel
        if not path.is_file():
            continue
        found = sorted(set(PLACEHOLDER.findall(path.read_text(encoding="utf-8"))))
        if found:
            problems.append(f"{rel}: {', '.join(found)}")
    if problems:
        print("FEHLER: offene Pflicht-Platzhalter:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        print(
            "Werte in der Variable LEGAL_VALUES_JSON setzen bzw. die Dateien im Repo "
            "ausfuellen (siehe docs/EINRICHTUNG.md).",
            file=sys.stderr,
        )
        return 1
    prov = ", ".join(sorted(providers)) or "keine"
    print(f"Rechtstexte: keine offenen Pflicht-Platzhalter (Telemetrie: {prov}).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
