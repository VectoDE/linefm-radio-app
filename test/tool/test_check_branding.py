"""Unit tests for tool/check_branding.py (standard library only).

Run from the repository root:
  python -m unittest discover -s test/tool -p "test_*.py"
"""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("check_branding", ROOT / "tool/check_branding.py")
cb = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(cb)

RETIRED = "jay" + "belife"


class CheckTextTest(unittest.TestCase):
    def test_retired_name_any_capitalisation(self) -> None:
        for word in (RETIRED, RETIRED.upper(), "." + RETIRED, RETIRED.capitalize()):
            self.assertEqual(len(cb.check_text("docs/a.md", f"Made by {word}")), 1, word)

    def test_clean_text(self) -> None:
        self.assertEqual(cb.check_text("docs/a.md", "Made by Tim Hauke"), [])

    def test_developer_url_only_in_ui_strings(self) -> None:
        line = '"x": "https://github.com/VectoDE"'
        self.assertEqual(len(cb.check_text("lib/l10n/app_de.arb", line)), 1)
        self.assertEqual(cb.check_text("README.md", line), [])

    def test_repository_is_clean(self) -> None:
        self.assertEqual(cb.main(), 0)


if __name__ == "__main__":
    unittest.main()
