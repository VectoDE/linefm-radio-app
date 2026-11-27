"""Fail when a start-time budget in start_budget.json is exceeded.

  python3 -I tool/perf/start_budget.py <folder with the measurement artifacts>

Reads whatever is present (at any depth): windows-perf.json, web-perf.json,
android-start-baseline.json and android-start-current.json. A missing file
skips its checks and says so; a present file without usable values fails.

Checks (medians, see docs/PERFORMANCE.md for the baseline behind each limit):
  - Windows: process start to first frame <= windows_first_frame_ms (half of
    the baseline).
  - Web: LCP of the static shell on a throttled phone and on a desktop does not
    exceed the limits (no regression; the LCP is bounded by one network round
    trip, so halving it is not possible, see the document).
  - Android: cold start (launch to first Flutter frame) of the current build is
    at most baseline * android_first_frame_regression_factor, and at most
    android_first_frame_ms when that is set. Whether it is at most
    baseline * android_first_frame_goal_factor (halved) is reported as a goal,
    it does not fail the run.

Standard library only. With GITHUB_STEP_SUMMARY set the table is also written
there. Exit code 1 on any overrun.
"""

from __future__ import annotations

import argparse
import json
import os
import statistics
import sys
from dataclasses import dataclass
from pathlib import Path

DEFAULT_BUDGET = Path(__file__).with_name("start_budget.json")


@dataclass
class Check:
    name: str
    actual: float | None
    limit: float | None
    note: str = ""
    gate: bool = True  # False: reported only

    @property
    def ok(self) -> bool:
        if not self.gate or self.limit is None:
            return True
        return self.actual is not None and self.actual <= self.limit


def find(root: Path, name: str) -> Path | None:
    for path in sorted(root.rglob(name)):
        if path.is_file():
            return path
    return None


def load(root: Path, name: str):
    path = find(root, name)
    return json.loads(path.read_text(encoding="utf-8")) if path else None


def median(values) -> float | None:
    numbers = [v for v in values if isinstance(v, (int, float))]
    return statistics.median(numbers) if numbers else None


def android_first_frame(data) -> float | None:
    runs = [r for r in data.get("results", []) if not r.get("warmup")]
    return median(r.get("marksMs", {}).get("first-frame") for r in runs)


def evaluate(root: Path, budget: dict) -> tuple[list[Check], list[str]]:
    checks: list[Check] = []
    skipped: list[str] = []

    windows = load(root, "windows-perf.json")
    if windows is None:
        skipped.append("windows-perf.json")
    else:
        runs = [r for r in windows.get("results", []) if not r.get("warmup")]
        checks.append(Check(
            "Windows: process start to first frame (ms)",
            median(r.get("windowVisibleMs") for r in runs),
            budget.get("windows_first_frame_ms"),
        ))

    web = load(root, "web-perf.json")
    if web is None:
        skipped.append("web-perf.json")
    else:
        stats = web.get("stats", {})
        for profile, key in (("mobile", "web_mobile_lcp_ms"), ("desktop", "web_desktop_lcp_ms")):
            lcp = stats.get(f"{profile}.cold", {}).get("lcp", {})
            checks.append(Check(f"Web {profile}: LCP, first visit (ms)", lcp.get("median"), budget.get(key)))

    current = load(root, "android-start-current.json")
    baseline = load(root, "android-start-baseline.json")
    if current is None:
        skipped.append("android-start-current.json")
    else:
        now = android_first_frame(current)
        if now is None:
            checks.append(Check("Android: current build reached the first frame", None, 0))
        absolute = budget.get("android_first_frame_ms")
        if absolute is not None:
            checks.append(Check("Android: launch to first frame (ms), absolute", now, absolute))
        if baseline is None:
            skipped.append("android-start-baseline.json")
        else:
            before = android_first_frame(baseline)
            if before is None:
                checks.append(Check("Android: baseline has no first-frame value", None, 0))
            else:
                regression = budget.get("android_first_frame_regression_factor", 1.1)
                checks.append(Check(
                    "Android: launch to first frame (ms), against baseline",
                    now,
                    before * regression,
                    f"baseline {before:.0f} ms x {regression}",
                ))
                goal = budget.get("android_first_frame_goal_factor", 0.5)
                checks.append(Check(
                    "Android: halved against baseline (goal, not a gate)",
                    now,
                    before * goal,
                    f"baseline {before:.0f} ms x {goal}",
                    gate=False,
                ))
    return checks, skipped


def render(checks: list[Check], skipped: list[str]) -> str:
    lines = ["| Check | Median | Limit | Result |", "|---|---|---|---|"]
    for c in checks:
        actual = "n/a" if c.actual is None else f"{c.actual:.0f}"
        limit = "-" if c.limit is None else f"{c.limit:.0f}"
        if c.note:
            limit += f" ({c.note})"
        if not c.gate:
            reached = c.actual is not None and c.limit is not None and c.actual <= c.limit
            result = "goal reached" if reached else "goal not reached"
        else:
            result = "ok" if c.ok else "OVER"
        lines.append(f"| {c.name} | {actual} | {limit} | {result} |")
    if skipped:
        lines.append("")
        lines.append("Not present, checks skipped: " + ", ".join(skipped))
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--budget", type=Path, default=DEFAULT_BUDGET)
    args = parser.parse_args(argv)
    budget = json.loads(args.budget.read_text(encoding="utf-8"))
    checks, skipped = evaluate(args.folder, budget)
    table = render(checks, skipped)
    print(table)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write("## Start-time budget\n\n" + table + "\n")
    if not checks:
        print("No measurement files found: nothing to check.", file=sys.stderr)
        return 1
    return 0 if all(c.ok for c in checks) else 1


if __name__ == "__main__":
    sys.exit(main())
