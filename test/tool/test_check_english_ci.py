"""Unit tests for tool/check_english_ci.py (standard library only).

Run from the repository root:
  python -m unittest discover -s test/tool -p "test_*.py"
"""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("check_english_ci", ROOT / "tool/check_english_ci.py")
assert _spec is not None and _spec.loader is not None
ce = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ce)

WF = ".github/workflows/x.yml"


class CheckTextTest(unittest.TestCase):
    def test_umlaut_is_found(self) -> None:
        for ch in ("ä", "ö", "ü", "Ä", "ß"):
            self.assertEqual(len(ce.check_text(WF, f"- name: Gr{ch}n")), 1, ch)

    def test_ascii_german_words_are_found(self) -> None:
        for line in ("- name: Runner haerten", "# Nur fuer den Release", "echo 'Fehler und Abbruch'"):
            self.assertEqual(len(ce.check_text(WF, line)), 1, line)

    def test_english_text_is_clean(self) -> None:
        text = "- name: Harden runner\n  run: echo '::error::Build failed, see the log'\n"
        self.assertEqual(ce.check_text(WF, text), [])

    def test_words_inside_longer_words_are_ignored(self) -> None:
        self.assertEqual(ce.check_text(WF, "run: ls dist/ && undo && dieselengine"), [])

    def test_proper_names_are_allowed(self) -> None:
        self.assertEqual(ce.check_text(WF, "- name: Build LineFM Studios app with tool/bauen.sh"), [])

    def test_allow_marker(self) -> None:
        self.assertEqual(ce.check_text(WF, "TEXT='und nicht'  # english-ci: allow"), [])

    def test_scope(self) -> None:
        self.assertTrue(ce.in_scope(".github/workflows/ci.yml"))
        self.assertTrue(ce.in_scope(".github/actions/a/action.yml"))
        self.assertTrue(ce.in_scope(".github/dependabot.yml"))
        self.assertFalse(ce.in_scope(".github/ISSUE_TEMPLATE/bug.yml"))
        self.assertFalse(ce.in_scope("lib/l10n/app_de.arb"))

    def test_repository_is_clean(self) -> None:
        self.assertEqual(ce.main(), 0)


if __name__ == "__main__":
    unittest.main()
