"""Unit tests for the audit-ID rule in tool/check_no_issue_refs.py.

Run from the repository root:
  python -m unittest discover -s test/tool -p "test_*.py"
"""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location(
    "check_no_issue_refs", ROOT / "tool/check_no_issue_refs.py"
)
assert _spec is not None and _spec.loader is not None
cr = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cr)


def _j(text: str) -> str:
    """Drop the "~" that keeps sample IDs out of the repository check itself."""
    return text.replace("~", "")


class AuditIdTest(unittest.TestCase):
    def test_hyphenated_ids(self) -> None:
        for line in (
            "// Grossbuchstaben (D~80-10).",
            "/// Speicherfehler nicht verschlucken (Q~-14): loggen",
            "# L~3-08: Zeitstempel im Build",
            "group('Pflicht-Regeln (R~3-P01)', () {",
            "| S~133-04 | Ort |",
            "(WCAG 2.1.4, A~11Y-08)",
        ):
            self.assertTrue(cr.audit_ids(_j(line)), line)

    def test_short_ids_in_parentheses_and_lists(self) -> None:
        for line in (
            "/// Oeffnet die Sleeptimer-Auswahl (U~2).",
            "// Reichweitenmessung (P~31, Consent Mode v2).",
            "// Fenster (Desktop, P~18).",
            "/// abgelehnt (S~6/Q~-08).",
            "/// Ziel (C~04; Rest).",
        ):
            self.assertTrue(cr.audit_ids(_j(line)), line)

    def test_false_positives_stay_out(self) -> None:
        for line in (
            "color: #FF0F12; background: #1B1D2B;",
            "version: 1.2.3-beta.4+5",
            "SHA-256, UTF-8, ISO-8601, GPL-3, CC0-1.0, LGPL-2.1",
            "RegExp(r'^GTM-[A-Z0-9]{4,12}$')",
            "expect(escapeCsv('=SUM(A1)'), \"'=SUM(A1)\");",
            "laut.fm-Streams (MP3/AAC/Ogg)",
            "'data:image/png;base64,AAAA/WW7/k+AB12/CD3=='",
            '"integrity": "sha512-1pTbQ/W4/kHT3"',
            "Paper size A4 and USB-C",
            "0.0.0-dev+1a2b3c4",
            "Spec 9, Seite 4.1",
        ):
            self.assertEqual(cr.audit_ids(line), [], line)

    def test_markdown_section_numbers_of_the_same_file(self) -> None:
        text = _j("### A~4 Der Weg ueber ein Release\n\nNur ueber Releases (A~4).\n")
        local = frozenset(cr.HEADING_ID.findall(text))
        self.assertEqual(cr.audit_ids(_j("Nur ueber Releases (A~4)."), local), [])
        self.assertTrue(cr.audit_ids(_j("Siehe (A~6)."), local))

    def test_repository_is_clean(self) -> None:
        self.assertEqual(cr.main(), 0)


if __name__ == "__main__":
    unittest.main()


class CatalogIdTest(unittest.TestCase):
    def test_anchor_ids_of_a_catalog_are_allowed(self) -> None:
        line = _j("Items: [A~-01](#a-01), [D~-09](#d-09)")
        self.assertTrue(cr.audit_ids(line))
        local = frozenset({_j("A~-01"), _j("D~-09")})
        self.assertFalse(cr.audit_ids(line, local))

    def test_anchor_pattern_reads_catalog_definitions(self) -> None:
        text = '- [x] <a id="g-08"></a>**G-08 Malware**'
        self.assertEqual(cr.ANCHOR_ID.findall(text), ["g-08"])
