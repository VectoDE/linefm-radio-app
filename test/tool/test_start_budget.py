"""Unit tests for tool/perf/start_budget.py (standard library only).

Run from the repository root:
  python -m unittest discover -s test/tool -p "test_*.py"
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("start_budget", ROOT / "tool/perf/start_budget.py")
assert _spec is not None and _spec.loader is not None
sb = importlib.util.module_from_spec(_spec)
sys.modules["start_budget"] = sb  # dataclasses look the module up
_spec.loader.exec_module(sb)

BUDGET = {
    "windows_first_frame_ms": 535,
    "web_mobile_lcp_ms": 750,
    "web_desktop_lcp_ms": 150,
    "android_first_frame_regression_factor": 1.1,
    "android_first_frame_goal_factor": 0.5,
    "android_first_frame_ms": None,
}


def android(first_frames: list[int | None]) -> dict:
    results = [{"run": 0, "warmup": True, "marksMs": {"first-frame": 9999}}]
    results += [{"run": i + 1, "warmup": False, "marksMs": {"first-frame": v}} for i, v in enumerate(first_frames)]
    return {"results": results}


def write(folder: Path, name: str, data: dict) -> None:
    (folder / name).write_text(json.dumps(data), encoding="utf-8")


def run(folder: Path) -> tuple[int, str]:
    budget = folder / "budget.json"
    budget.write_text(json.dumps(BUDGET), encoding="utf-8")
    out = io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(io.StringIO()):
        code = sb.main([str(folder), "--budget", str(budget)])
    return code, out.getvalue()


class StartBudgetTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.dir = Path(self._tmp.name)

    def test_empty_folder_fails(self) -> None:
        self.assertEqual(run(self.dir)[0], 1)

    def test_windows_within_and_over_budget(self) -> None:
        write(self.dir, "windows-perf.json", {"results": [
            {"warmup": True, "windowVisibleMs": 9000},
            {"warmup": False, "windowVisibleMs": 420},
            {"warmup": False, "windowVisibleMs": 460},
            {"warmup": False, "windowVisibleMs": 400},
        ]})
        self.assertEqual(run(self.dir)[0], 0)
        write(self.dir, "windows-perf.json", {"results": [
            {"warmup": False, "windowVisibleMs": 700},
            {"warmup": False, "windowVisibleMs": 640},
        ]})
        self.assertEqual(run(self.dir)[0], 1)

    def test_web_lcp(self) -> None:
        stats = {"mobile.cold": {"lcp": {"median": 664}}, "desktop.cold": {"lcp": {"median": 92}}}
        write(self.dir, "web-perf.json", {"stats": stats})
        self.assertEqual(run(self.dir)[0], 0)
        stats["mobile.cold"]["lcp"]["median"] = 1170
        write(self.dir, "web-perf.json", {"stats": stats})
        self.assertEqual(run(self.dir)[0], 1)

    def test_android_goal_is_reported_not_gated(self) -> None:
        write(self.dir, "android-start-baseline.json", android([2000, 2100, 1900]))
        write(self.dir, "android-start-current.json", android([1500, 1600, 1400]))
        code, out = run(self.dir)
        self.assertEqual(code, 0)
        self.assertIn("goal not reached", out)

    def test_android_halved_reaches_goal(self) -> None:
        write(self.dir, "android-start-baseline.json", android([2000, 2100, 1900]))
        write(self.dir, "android-start-current.json", android([900, 950, 1000]))
        code, out = run(self.dir)
        self.assertEqual(code, 0)
        self.assertIn("| goal reached", out)

    def test_android_regression_fails(self) -> None:
        write(self.dir, "android-start-baseline.json", android([1000, 1000, 1000]))
        write(self.dir, "android-start-current.json", android([1300, 1300, 1300]))
        self.assertEqual(run(self.dir)[0], 1)

    def test_android_without_first_frame_fails(self) -> None:
        write(self.dir, "android-start-baseline.json", android([1000, 1000]))
        write(self.dir, "android-start-current.json", android([None, None]))
        self.assertEqual(run(self.dir)[0], 1)


if __name__ == "__main__":
    unittest.main()
