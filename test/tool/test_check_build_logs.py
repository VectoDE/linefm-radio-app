"""Unit tests for tool/check_build_logs.py (standard library only).

Run from the repository root:
  python -m unittest discover -s test/tool -p "test_*.py"
"""

from __future__ import annotations

import importlib.util
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("check_build_logs", ROOT / "tool/check_build_logs.py")
cbl = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(cbl)

TS = "2026-11-25T22:00:22.1234567Z "


def hits(*lines: str, allow: list[dict] | None = None, job: str = "job") -> list[str]:
    return cbl.scan(job, "\n".join(TS + line for line in lines), allow or [])


class RuleTest(unittest.TestCase):
    def assert_caught(self, line: str, rule: str) -> None:
        found = hits(line)
        self.assertEqual(len(found), 1, f"not caught: {line!r}")
        self.assertIn(f"] {rule}:", found[0])

    def test_new_shapes_are_caught(self) -> None:
        cases = {
            "+ ERROR: Failed to check for updates: 400": "prefixed",
            "+ WARNING: something": "prefixed",
            "Use of uninitialized value $LW2::_SSL_LIBRARY in string eq at nikto.pl line 45.": "perl",
            "[WARN] Analyzing `x/package-lock.json` - however, node_modules is missing": "warn",
            "[ERROR] Failed to process CVE-2026-6785": "warn",
            "WARN: low disk": "warn",
            "E: Unable to locate package foo": "apt",
            "W: Some index files failed to download": "apt",
            "npm warn deprecated inflight@1.0.6": "npm",
            "npm error code ERESOLVE": "npm",
            "(node:3120) [DEP0005] DeprecationWarning: Buffer() is deprecated": "warning-mid-line",
            "tool says Warning: disk almost full": "warning-mid-line",
            "The option --foo is deprecated and will be removed": "deprecated",
        }
        for line, rule in cases.items():
            with self.subTest(line=line):
                self.assert_caught(line, rule)

    def test_existing_shapes_still_caught(self) -> None:
        self.assert_caught("##[warning]actions/x has been deprecated", "annotation")
        self.assert_caught("Warning: Missing web-define variables: A", "flutter/gradle")

    def test_clean_lines_pass(self) -> None:
        clean = [
            "Scanned 3 file(s): 0 warning/error line(s), 0 allow-list problem(s).",
            "+ Target IP:          127.0.0.1",
            "+ 45 requests: 0 errors and 1 item reported on the remote host",
            "Compiling lib/main.dart for the Web...",
            "added 120 packages in 3s",
            "error_reporting: enabled",
            '        "markdown": "Some features are deprecated in older runners"',
        ]
        self.assertEqual(hits(*clean), [])

    def test_runner_echo_of_script_source_is_ignored(self) -> None:
        lines = [
            "##[group]Run echo \"::error::no job logs downloaded\"",
            "\x1b[36;1mecho \"::error::no job logs downloaded\"\x1b[0m",
            '##[start-action display=Run echo "::warning::x has been deprecated";id=a]',
            "[command]/usr/bin/apt-get install -y foo",
        ]
        self.assertEqual(hits(*lines), [])

    def test_allow_list_with_job_filter(self) -> None:
        allow = [{"_re": re.compile(r"^WARN: low disk$"), "_job": re.compile("Android")}]
        self.assertEqual(hits("WARN: low disk", allow=allow, job="Android__APK_"), [])
        self.assertEqual(len(hits("WARN: low disk", allow=allow, job="Web")), 1)


class AnnotationTest(unittest.TestCase):
    def test_levels(self) -> None:
        text = "\n".join([
            "notice\tSigning skipped: secret missing",
            "warning\tNode.js 20 actions are deprecated",
            "failure\tProcess completed with exit code 1.",
        ])
        found = cbl.scan_annotations("job", text, [])
        self.assertEqual(len(found), 2)
        self.assertIn("annotation-warning", found[0])
        self.assertIn("annotation-failure", found[1])

    def test_allow_list_applies(self) -> None:
        allow = [{"_re": re.compile("Node.js 20"), "_job": None}]
        self.assertEqual(cbl.scan_annotations("job", "warning\tNode.js 20 actions are deprecated", allow), [])


class AllowListFileTest(unittest.TestCase):
    def test_repository_allow_list_is_valid(self) -> None:
        _, problems = cbl.load_allowlist(cbl.DEFAULT_ALLOWLIST)
        self.assertEqual(problems, [])


if __name__ == "__main__":
    unittest.main()
