"""Fail when the web build grows past the budget in bundle_budget.json.

  python3 -I tool/perf/bundle_budget.py build/web [--budget tool/perf/bundle_budget.json]

Standard library only. Prints one line per check; with GITHUB_STEP_SUMMARY set
it also writes a Markdown table there. Exit code 1 on any overrun or when a
budgeted file is missing from the build.
"""

from __future__ import annotations

import argparse
import gzip
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path

DEFAULT_BUDGET = Path(__file__).with_name("bundle_budget.json")


@dataclass
class Result:
    name: str
    actual: int
    limit: int

    @property
    def ok(self) -> bool:
        return self.actual <= self.limit


def gzip_size(path: Path) -> int:
    return len(gzip.compress(path.read_bytes(), compresslevel=5, mtime=0))


def list_files(web: Path) -> list[str]:
    return sorted(p.relative_to(web).as_posix() for p in web.rglob("*") if p.is_file())


def match_one(files: list[str], pattern: str) -> str | None:
    rx = re.compile(f"^{pattern}$")
    return next((f for f in files if rx.match(f)), None)


def check(web: Path, budget: dict) -> tuple[list[Result], list[str]]:
    files = list_files(web)
    results: list[Result] = []
    missing: list[str] = []
    gz_cache: dict[str, int] = {}

    def gz(rel: str) -> int:
        if rel not in gz_cache:
            gz_cache[rel] = gzip_size(web / rel)
        return gz_cache[rel]

    for pattern, limit in budget.get("files_gzip", {}).items():
        rel = match_one(files, pattern)
        if rel is None:
            missing.append(pattern)
            continue
        results.append(Result(f"{rel} (gzip)", gz(rel), int(limit)))

    startup = budget.get("startup_gzip")
    if startup:
        total = 0
        for pattern in startup["patterns"]:
            rel = match_one(files, pattern)
            if rel is None:
                if pattern not in missing:
                    missing.append(pattern)
                continue
            total += gz(rel)
        results.append(Result("startup total (gzip)", total, int(startup["max"])))

    for name, spec in budget.get("groups_raw", {}).items():
        rx = re.compile(spec["pattern"])
        total = sum((web / f).stat().st_size for f in files if rx.search(f))
        results.append(Result(f"{name} (raw)", total, int(spec["max"])))

    return results, missing


def summary(results: list[Result], missing: list[str]) -> str:
    rows = ["| Check | Size | Budget | Result |", "|---|---:|---:|---|"]
    for r in results:
        rows.append(f"| {r.name} | {r.actual:,} | {r.limit:,} | {'ok' if r.ok else 'over'} |")
    for m in missing:
        rows.append(f"| `{m}` | missing | | fail |")
    return "### Bundle budget\n\n" + "\n".join(rows) + "\n"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Check the web build against its size budget.")
    ap.add_argument("web", type=Path)
    ap.add_argument("--budget", type=Path, default=DEFAULT_BUDGET)
    args = ap.parse_args(argv)

    if not args.web.is_dir():
        print(f"::error::{args.web} is not a directory")
        return 1
    budget = json.loads(args.budget.read_text(encoding="utf-8"))
    results, missing = check(args.web, budget)
    for r in results:
        pct = 100 * r.actual / r.limit if r.limit else 0
        line = f"{r.name}: {r.actual:,} of {r.limit:,} bytes ({pct:.0f} %)"
        print(line if r.ok else f"::error::bundle budget exceeded: {line}")
    for m in missing:
        print(f"::error::bundle budget: no file matches {m}")
    out = os.environ.get("GITHUB_STEP_SUMMARY")
    if out:
        with open(out, "a", encoding="utf-8") as fh:
            fh.write(summary(results, missing))
    return 0 if not missing and all(r.ok for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
