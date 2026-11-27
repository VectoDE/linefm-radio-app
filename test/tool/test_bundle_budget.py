"""Unit tests for tool/perf/bundle_budget.py (standard library only).

Run from the repository root:
  python -m unittest discover -s test/tool -p "test_*.py"
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("bundle_budget", ROOT / "tool/perf/bundle_budget.py")
assert _spec is not None and _spec.loader is not None
bb = importlib.util.module_from_spec(_spec)
sys.modules["bundle_budget"] = bb  # dataclasses look the module up
_spec.loader.exec_module(bb)

WASM = r"main\.([0-9a-f]+\.)?dart\.wasm"
SKWASM = r"canvaskit/([^/]+/)?skwasm\.wasm"


class BundleBudgetTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.web = Path(self._tmp.name) / "web"
        (self.web / "canvaskit/abc").mkdir(parents=True)
        (self.web / "assets").mkdir()
        (self.web / "main.1f2c.dart.wasm").write_bytes(os.urandom(2000))
        (self.web / "canvaskit/abc/skwasm.wasm").write_bytes(b"a" * 5000)
        (self.web / "assets/logo.png").write_bytes(b"x" * 300)
        self._env = os.environ.pop("GITHUB_STEP_SUMMARY", None)

    def tearDown(self) -> None:
        if self._env is not None:
            os.environ["GITHUB_STEP_SUMMARY"] = self._env
        self._tmp.cleanup()

    @staticmethod
    def budget(wasm: int, total: int, images: int) -> dict:
        return {
            "files_gzip": {WASM: wasm},
            "startup_gzip": {"patterns": [WASM, SKWASM], "max": total},
            "groups_raw": {"images": {"pattern": r"\.png$", "max": images}},
        }

    def run_main(self, budget: dict) -> int:
        path = Path(self._tmp.name) / "budget.json"
        path.write_text(json.dumps(budget), encoding="utf-8")
        with contextlib.redirect_stdout(io.StringIO()):
            return bb.main([str(self.web), "--budget", str(path)])

    def test_within_budget(self) -> None:
        self.assertEqual(self.run_main(self.budget(10_000, 10_000, 300)), 0)

    def test_file_over_budget(self) -> None:
        # Random bytes do not compress, so gzip stays above 2000 bytes.
        self.assertEqual(self.run_main(self.budget(1_000, 10_000, 300)), 1)

    def test_group_over_budget(self) -> None:
        self.assertEqual(self.run_main(self.budget(10_000, 10_000, 299)), 1)

    def test_missing_file_fails(self) -> None:
        (self.web / "main.1f2c.dart.wasm").unlink()
        self.assertEqual(self.run_main(self.budget(10_000, 10_000, 300)), 1)

    def test_startup_total_sums_files(self) -> None:
        results, missing = bb.check(self.web, self.budget(10_000, 10_000, 300))
        self.assertEqual(missing, [])
        total = next(r for r in results if r.name.startswith("startup"))
        expected = bb.gzip_size(self.web / "main.1f2c.dart.wasm") + bb.gzip_size(
            self.web / "canvaskit/abc/skwasm.wasm"
        )
        self.assertEqual(total.actual, expected)

    def test_shipped_budget_is_valid(self) -> None:
        data = json.loads((ROOT / "tool/perf/bundle_budget.json").read_text(encoding="utf-8"))
        for limit in data["files_gzip"].values():
            self.assertGreater(limit, 0)
        self.assertGreater(data["startup_gzip"]["max"], 0)
        for spec in data["groups_raw"].values():
            self.assertGreater(spec["max"], 0)

    def test_apk_over_budget_fails_and_unset_budget_reports(self) -> None:
        apk = self.web / "app.apk"
        apk.write_bytes(b"x" * 1000)
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(bb.check_apk(apk, {"apk_bytes": None}), 0)
            self.assertEqual(bb.check_apk(apk, {"apk_bytes": 1000}), 0)
            self.assertEqual(bb.check_apk(apk, {"apk_bytes": 999}), 1)
            self.assertEqual(bb.check_apk(self.web / "none.apk", {}), 1)


if __name__ == "__main__":
    unittest.main()
