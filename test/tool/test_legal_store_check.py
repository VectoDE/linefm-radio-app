"""Einheitstests fuer tool/legal_store_check.py (nur Standardbibliothek).

Aufruf im Repo-Wurzelverzeichnis:
  python -m unittest discover -s test/tool -p "test_*.py"

Den Ablauf als Prozess (Exit-Codes) prueft test/tool/legal_store_check_test.dart.
"""

from __future__ import annotations

import importlib.util
import json
import shutil
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("legal_store_check", ROOT / "tool/legal_store_check.py")
lsc = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(lsc)


class PlaceholderPatternTest(unittest.TestCase):
    """R4-S02: lockere Erkennung."""

    def test_varianten(self) -> None:
        cases = {
            "{{BETREIBER_NAME}}": "BETREIBER_NAME",
            "{{ BETREIBER_NAME }}": "BETREIBER_NAME",
            "{{X-Y}}": "X-Y",
            "{{STRASSE_ÄÖÜ}}": "STRASSE_ÄÖÜ",
            "｛｛VOLLBREIT｝｝": "VOLLBREIT",
            "{　{ X }}": "X",
        }
        for text, name in cases.items():
            with self.subTest(text=text):
                self.assertEqual(lsc.names(f"vor {text} nach"), {name})

    def test_keine_falschen_treffer(self) -> None:
        for text in ("{einfach}", "{ {x}", "plural {count, plural, =1{1} other{{count} x}}", "{{\n}}"):
            with self.subTest(text=text):
                self.assertNotIn("", lsc.names(text))

    def test_escape_im_json(self) -> None:
        raw = '{"blocks": [{"type": "p", "text": "\\u007b\\u007bVERSTECKT\\u007d\\u007d"}]}'
        self.assertEqual(lsc.names(raw), set())  # roh nicht sichtbar ...
        self.assertEqual(lsc.placeholders_in_json(raw), {"VERSTECKT"})  # ... dekodiert schon

    def test_fill_mit_lockerer_schreibweise(self) -> None:
        self.assertEqual(lsc.fill('"{{ A }} {{B}}"', {"A": 'x"y'}), '"x\\"y {{B}}"')


class ValuesTest(unittest.TestCase):
    """R4-S01: nur nicht-leere JSON-Strings zaehlen."""

    def test_nur_strings(self) -> None:
        values = {"A": "x", "B": None, "C": 0, "D": False, "E": ["x"], "F": {"x": 1}}
        self.assertEqual(lsc.non_blank(values), {"A": "x"})

    def test_unsichtbare_zeichen(self) -> None:
        for blank in ("", "   ", "​", "﻿", "  ", "　", "‎\t\n"):
            with self.subTest(value=repr(blank)):
                self.assertEqual(lsc.non_blank({"A": blank}), {})
        self.assertEqual(lsc.non_blank({"A": "​x"}), {"A": "​x"})


class RequirementTest(unittest.TestCase):
    """Review PR #77: Listen in requires gelten als UND (ga4-Varianten)."""

    def test_listen_und_ga4(self) -> None:
        self.assertTrue(lsc.requirement_met(["!telemetry", "ga4"], {"ga4"}))
        self.assertFalse(lsc.requirement_met(["!telemetry", "!ga4"], {"ga4"}))
        self.assertTrue(lsc.requirement_met(["!telemetry", "!ga4"], set()))
        self.assertTrue(lsc.requirement_met(["telemetry", "ga4"], {"umami", "ga4"}))
        self.assertFalse(lsc.requirement_met("telemetry", {"ga4"}))


class MainTest(unittest.TestCase):
    """Ganzer Lauf auf einer Kopie der Rechtstexte."""

    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp(prefix="lsc"))
        shutil.copytree(ROOT / "assets/legal", self.tmp / "assets/legal")
        self.registry = lsc.load_registry(self.tmp / "assets/legal/placeholders.json")

    def tearDown(self) -> None:
        shutil.rmtree(self.tmp)

    def run_fill(self, values: dict[str, object]) -> int:
        import os

        old = os.environ.get("LEGAL_VALUES_JSON")
        os.environ["LEGAL_VALUES_JSON"] = json.dumps(values)
        try:
            return lsc.main(["--root", str(self.tmp), "--fill"])
        finally:
            if old is None:
                del os.environ["LEGAL_VALUES_JSON"]
            else:
                os.environ["LEGAL_VALUES_JSON"] = old

    def test_alle_werte_ok(self) -> None:
        self.assertEqual(self.run_fill({k: "X" for k in self.registry}), 0)

    def test_null_und_zahl_bleiben_offen(self) -> None:
        values: dict[str, object] = {k: "X" for k in self.registry}
        values["BETREIBER_NAME"] = None
        self.assertEqual(self.run_fill(values), 1)
        values["BETREIBER_NAME"] = 0
        self.assertEqual(self.run_fill(values), 1)

    def test_nur_zero_width_bleibt_offen(self) -> None:
        values: dict[str, object] = {k: "X" for k in self.registry}
        values["BETREIBER_NAME"] = "​ "
        self.assertEqual(self.run_fill(values), 1)

    def test_escaped_platzhalter_faellt_auf(self) -> None:
        path = self.tmp / "assets/legal/de/impressum.json"
        doc = json.loads(path.read_text(encoding="utf-8"))
        doc["blocks"].append({"type": "p", "text": "{{GANZ_NEU}}"})
        path.write_text(json.dumps(doc, ensure_ascii=True).replace("{{", "\\u007b\\u007b"), encoding="utf-8")
        self.assertIn("\\u007b\\u007bGANZ_NEU", path.read_text(encoding="utf-8"))
        self.assertEqual(self.run_fill({k: "X" for k in self.registry}), 1)


if __name__ == "__main__":
    unittest.main()
