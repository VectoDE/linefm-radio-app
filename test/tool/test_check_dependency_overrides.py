"""Unit tests for tool/check_dependency_overrides.sh (standard library only).

Run from the repository root:
  python -m unittest discover -s test/tool -p "test_*.py"
"""

from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tool/check_dependency_overrides.sh"
BASH = shutil.which("bash")


@unittest.skipIf(BASH is None, "bash not available")
class CheckDependencyOverridesTest(unittest.TestCase):
    def _run(self, text: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "pubspec.yaml"
            path.write_text(text, encoding="utf-8")
            return subprocess.run(
                [BASH, str(SCRIPT), path.as_posix()],
                capture_output=True,
                text=True,
                check=False,
            )

    def test_documented_override_passes(self) -> None:
        result = self._run(
            "name: x\n"
            "# override-reason(foo): upstream pins foo\n"
            "dependency_overrides:\n"
            "  foo: 1.0.0\n"
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_undocumented_override_fails(self) -> None:
        result = self._run(
            "name: x\n"
            "# override-reason(foo): upstream pins foo\n"
            "dependency_overrides:\n"
            "  foo: 1.0.0\n"
            "  bar: 2.0.0\n"
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("'bar'", result.stdout)

    def test_no_overrides_passes(self) -> None:
        result = self._run("name: x\ndependencies:\n  foo: ^1.0.0\n")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_repository_pubspec_passes(self) -> None:
        result = subprocess.run(
            [BASH, str(SCRIPT), (ROOT / "pubspec.yaml").as_posix()],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
