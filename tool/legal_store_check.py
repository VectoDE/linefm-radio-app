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
  - Als Wert zaehlen nur nicht-leere JSON-Strings. Zahlen, null, Listen usw.
    und Werte, die nach Entfernen von Leer- und unsichtbaren Formatzeichen
    (Unicode Cf, Zs, z. B. U+200B, U+FEFF, U+00A0) leer sind, gelten als offen.
  - Platzhalter werden locker erkannt (PLACEHOLDER_PATTERN, identisch in
    gen_legal_html.dart): {{ X }}, {{X-Y}}, Umlaute, Vollbreite (U+FF5B/U+FF5D).
    Die Rechtstexte werden als JSON dekodiert geprueft, damit auch
    Escapes wie \\u007b\\u007bNAME\\u007d\\u007d auffallen.
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
import unicodedata
import zipfile
from pathlib import Path

# Gleiches Muster wie placeholderPattern in tool/gen_legal_html.dart (ein Test
# vergleicht beide). Erkennt bewusst mehr als die gueltige Schreibweise {{NAME}}:
# Leerzeichen innen, Bindestriche, Umlaute und vollbreite Klammern.
PLACEHOLDER_PATTERN = (
    r"[{\uFF5B][ \t\u00A0\u3000]*[{\uFF5B][ \t\u00A0\u3000]*"
    r"([^{}\uFF5B\uFF5D\r\n]{1,80}?)"
    r"[ \t\u00A0\u3000]*[}\uFF5D][ \t\u00A0\u3000]*[}\uFF5D]"
)
PLACEHOLDER = re.compile(PLACEHOLDER_PATTERN)
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


def visible(value: str) -> str:
    """Wert ohne Leer- und Formatzeichen (Unicode Cf, Zs) und Whitespace."""
    return "".join(
        ch for ch in value if not ch.isspace() and unicodedata.category(ch) not in ("Cf", "Zs")
    )


def non_blank(values: dict[str, object]) -> dict[str, str]:
    """Nur nicht-leere JSON-Strings zaehlen als gesetzt."""
    return {k: v for k, v in values.items() if isinstance(v, str) and visible(v)}


def names(text: str) -> set[str]:
    """Namen aller (auch locker geschriebenen) Platzhalter in text."""
    return {m.group(1).strip() for m in PLACEHOLDER.finditer(text)}


def json_strings(node: object) -> list[str]:
    """Alle Strings (Werte und Schluessel) eines dekodierten JSON-Dokuments."""
    if isinstance(node, str):
        return [node]
    if isinstance(node, dict):
        out: list[str] = []
        for k, v in node.items():
            out.append(str(k))
            out.extend(json_strings(v))
        return out
    if isinstance(node, list):
        out = []
        for v in node:
            out.extend(json_strings(v))
        return out
    return []


def placeholders_in_json(text: str) -> set[str]:
    """Platzhalter im dekodierten JSON (findet auch \\u007b-Escapes)."""
    found = set()
    for s in json_strings(json.loads(text)):
        found |= names(s)
    return found


def fill(text: str, values: dict[str, str]) -> str:
    """Ersetzt bekannte Platzhalter JSON-sicher (wie substituteJsonText).
    Leere Werte werden nicht eingesetzt, der Platzhalter bleibt offen."""
    values = non_blank(values)

    def repl(m: re.Match[str]) -> str:
        name = m.group(1).strip()
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
            values = non_blank({str(k): v for k, v in values.items()})
            for rel, text in texts.items():
                filled = fill(text, values)
                texts[rel] = filled
                (root / "assets/legal" / rel).write_text(filled, encoding="utf-8")

    problems = []
    for rel, text in sorted(texts.items()):
        try:
            found = placeholders_in_json(text)
        except json.JSONDecodeError as e:
            problems.append(f"{rel}: kein gueltiges JSON ({e})")
            continue
        open_required = sorted(n for n in found if is_required(n, registry, providers))
        if open_required:
            problems.append(f"{rel}: {', '.join(open_required)}")
    for rel in STRICT_FILES:
        path = root / rel
        if not path.is_file():
            continue
        found = sorted(names(path.read_text(encoding="utf-8")))
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
