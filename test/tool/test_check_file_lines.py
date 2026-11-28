"""Unit tests for tool/check_file_lines.py (standard library only).

Run from the repository root:
  python -m unittest discover -s test/tool -p "test_*.py"
"""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("check_file_lines", ROOT / "tool/check_file_lines.py")
cfl = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(cfl)


def _text(lines: int) -> str:
    return "x\n" * lines


class IsCheckedTest(unittest.TestCase):
    def test_lib_and_test_dart_files(self) -> None:
        self.assertTrue(cfl.is_checked("lib/app/app.dart"))
        self.assertTrue(cfl.is_checked("test/app/app_test.dart"))

    def test_generated_and_other_files_skipped(self) -> None:
        for path in (
            "lib/a.g.dart",
            "lib/a.freezed.dart",
            "test/a.mocks.dart",
            "lib/l10n/gen/app_localizations.dart",
            "tool/web_postbuild.dart",
            "lib/l10n/app_de.arb",
        ):
            self.assertFalse(cfl.is_checked(path), path)


class FindingsTest(unittest.TestCase):
    def test_limit_is_inclusive(self) -> None:
        files = {"lib/ok.dart": _text(400), "lib/big.dart": _text(401)}
        self.assertEqual(cfl.findings(files, files.__getitem__), [("lib/big.dart", 401)])

    def test_generated_file_above_limit_ignored(self) -> None:
        files = {"lib/a.g.dart": _text(900)}
        self.assertEqual(cfl.findings(files, files.__getitem__), [])

    def test_repository_is_clean(self) -> None:
        self.assertEqual(cfl.main(), 0)


if __name__ == "__main__":
    unittest.main()
