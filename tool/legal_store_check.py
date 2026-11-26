#!/usr/bin/env python3
"""Checks before a store upload that the legal texts no longer contain open
required placeholders ({{NAME}}).

For store workflows that do not build via .github/actions/write-config and
therefore do not run tool/gen_legal_html.dart --strict:

  store-google.yml  reads the texts from the finished AAB (--aab dist/x.aab)
  store-snap.yml    fills the texts in the checkout from LEGAL_VALUES_JSON (--fill)
                    and checks them before snapcraft builds

Rules as in gen_legal_html.dart --strict:
  - Required is whatever does not carry "required": false in
    assets/legal/placeholders.json. Unregistered placeholders are also required.
  - "required_if" (e.g. "telemetry", "umami") makes an optional entry
    required as soon as the provider is active (--providers=umami,sentry,firebase).
  - Only non-empty JSON strings count as a value. Numbers, null, lists etc.
    and values that are empty after removing blank and invisible format
    characters (Unicode Cf, Zs, e.g. U+200B, U+FEFF, U+00A0) count as open.
  - Placeholders are recognized loosely (PLACEHOLDER_PATTERN, identical in
    gen_legal_html.dart): {{ X }}, {{X-Y}}, umlauts, full-width (U+FF5B/U+FF5D).
    The legal texts are checked decoded as JSON, so that escapes such as
    \\u007b\\u007bNAME\\u007d\\u007d are caught as well.
  - The files in STRICT_FILES (security contact, code of conduct,
    accessibility) must not contain any placeholders at all.

Standard library only.
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

# Same pattern as placeholderPattern in tool/gen_legal_html.dart (a test
# compares both). Deliberately recognizes more than the valid spelling {{NAME}}:
# inner spaces, hyphens, umlauts and full-width braces.
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

# Same list as strictFiles in tool/gen_legal_html.dart.
STRICT_FILES = (
    "SECURITY.md",
    "CODE_OF_CONDUCT.md",
    "docs/BARRIEREFREIHEIT.md",
    "web/.well-known/security.txt",
)


def requirement_met(requires: object, providers: set[str]) -> bool:
    """Like requirementMet in gen_legal_html.dart ("!x" = negation, list = AND)."""
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
        return True  # not registered: required
    if info.get("required") is not False:
        return True
    cond = info.get("required_if")
    return cond is not None and requirement_met(cond, providers)


def visible(value: str) -> str:
    """Value without blank and format characters (Unicode Cf, Zs) and whitespace."""
    return "".join(
        ch for ch in value if not ch.isspace() and unicodedata.category(ch) not in ("Cf", "Zs")
    )


def non_blank(values: dict[str, object]) -> dict[str, str]:
    """Only non-empty JSON strings count as set."""
    return {k: v for k, v in values.items() if isinstance(v, str) and visible(v)}


def names(text: str) -> set[str]:
    """Names of all placeholders (including loosely written ones) in text."""
    return {m.group(1).strip() for m in PLACEHOLDER.finditer(text)}


def json_strings(node: object) -> list[str]:
    """All strings (values and keys) of a decoded JSON document."""
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
    """Placeholders in the decoded JSON (also finds \\u007b escapes)."""
    found = set()
    for s in json_strings(json.loads(text)):
        found |= names(s)
    return found


def fill(text: str, values: dict[str, str]) -> str:
    """Replaces known placeholders JSON-safely (like substituteJsonText).
    Empty values are not inserted, the placeholder stays open."""
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
                    raise SystemExit(f"legal_store_check: ERROR: {name} is missing in the AAB {aab}")
    return out


def parse_providers(raw: str) -> set[str]:
    return {p.strip() for p in raw.split(",") if p.strip()}


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=".", help="Repo root (default: .)")
    ap.add_argument("--aab", help="Read the texts from this AAB instead of from the repo")
    ap.add_argument(
        "--fill",
        action="store_true",
        help="Insert values from the environment variable LEGAL_VALUES_JSON into assets/legal",
    )
    ap.add_argument(
        "--providers",
        default="",
        help="active telemetry providers, comma-separated (umami,sentry,firebase)",
    )
    args = ap.parse_args(argv)
    root = Path(args.root)
    providers = parse_providers(args.providers)
    unknown = providers - TELEMETRY_PROVIDERS
    if unknown:
        raise SystemExit(f"legal_store_check: ERROR: unknown providers: {', '.join(sorted(unknown))}")
    registry = load_registry(root / "assets/legal/placeholders.json")

    if args.aab:
        texts = texts_from_aab(Path(args.aab))
    else:
        texts = texts_from_repo(root)
        if args.fill:
            raw = os.environ.get("LEGAL_VALUES_JSON", "").strip()
            values = json.loads(raw) if raw else {}
            if not isinstance(values, dict):
                raise SystemExit("legal_store_check: ERROR: LEGAL_VALUES_JSON is not a JSON object")
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
            problems.append(f"{rel}: not valid JSON ({e})")
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
        print("legal_store_check: ERROR: open required placeholders:", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        print(
            "Set the values in the variable LEGAL_VALUES_JSON or fill in the files in "
            "the repo (see docs/EINRICHTUNG.md).",
            file=sys.stderr,
        )
        return 1
    prov = ", ".join(sorted(providers)) or "none"
    print(f"Legal texts: no open required placeholders (telemetry: {prov}).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
