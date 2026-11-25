#!/usr/bin/env python3
"""Fails when a CI job log contains a warning or an error line.

Every warning in a build log is a defect: compiler and CMake warnings,
PowerShell errors, Gradle/Xcode/Flutter warnings, workflow annotations and pub
notices about outdated or overridden packages. This script scans job logs and
exits non-zero on the first run that contains any such line that is not covered
by an active entry in tool/build_log_allowlist.json.

Usage:
  # all completed jobs of a workflow run (needs GH_TOKEN with actions:read)
  check_build_logs.py --repo OWNER/NAME --run-id ID [--attempt N] [--skip-job NAME]
  # local files, e.g. a saved build output
  check_build_logs.py FILE [FILE ...]

Allow-list entries (JSON list): {"pattern": regex, "job": optional regex,
"expires": "YYYY-MM-DD", "reason": text}. An expired entry fails the check so
that it gets reviewed instead of lingering.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ALLOWLIST = ROOT / "tool" / "build_log_allowlist.json"

# Each rule: (name, compiled regex). Matching is per log line after the
# timestamp prefix and ANSI colour codes were removed.
RULES: list[tuple[str, re.Pattern[str]]] = [
    ("cmake", re.compile(r"CMake (Deprecation )?(Warning|Error)\b")),
    ("msvc", re.compile(r"\b(warning|error) [A-Z]{1,4}\d{3,5}\s*:")),
    ("compiler", re.compile(r":\d+(:\d+)?: (fatal )?(warning|error): ")),
    ("tool", re.compile(r"^(ld: )?(warning|error): ")),
    ("flutter/gradle", re.compile(r"^(Warning|WARNING|Error|ERROR|FAILURE):? ")),
    ("kotlin", re.compile(r"^[we]: (file:|/|[A-Z]:\\)")),
    ("gradle-deprecation", re.compile(r"Deprecated Gradle features were used")),
    ("powershell", re.compile(r"FullyQualifiedErrorId|^\s*\+ CategoryInfo\s*:")),
    ("annotation", re.compile(r"^##\[(warning|error)\]")),
    ("dart-analyzer", re.compile(r"^\s*(info|warning|error) [-•] ")),
    ("pub-outdated", re.compile(r"^!?\s*[a-z0-9_]+ \S+ (\(overridden\) )?\(\S+ available\)$")),
    ("pub-summary", re.compile(r"packages? ha(s|ve) newer versions incompatible")),
    ("pub-discontinued", re.compile(r"\(discontinued")),
    ("npm", re.compile(r"^npm (WARN|warn|ERR!)")),
]

TIMESTAMP = re.compile(r"^﻿?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z ?")
ANSI = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
# Lines the runner prints for the script it is about to execute are shown in
# cyan; they contain our own `echo "::error::..."` source, not output.
SCRIPT_ECHO = "\x1b[36;1m"


def load_allowlist(path: Path) -> tuple[list[dict], list[str]]:
    if not path.exists():
        return [], []
    entries = json.loads(path.read_text(encoding="utf-8"))
    today = dt.date.today()
    problems: list[str] = []
    active: list[dict] = []
    for entry in entries:
        for key in ("pattern", "expires", "reason"):
            if not entry.get(key):
                problems.append(f"allow-list entry without {key}: {entry}")
        expires = dt.date.fromisoformat(entry["expires"])
        if expires < today:
            problems.append(
                f"allow-list entry expired on {expires}: {entry['pattern']!r} "
                f"({entry['reason']})"
            )
            continue
        entry["_re"] = re.compile(entry["pattern"])
        entry["_job"] = re.compile(entry["job"]) if entry.get("job") else None
        active.append(entry)
    return active, problems


def scan(job: str, text: str, allow: list[dict]) -> list[str]:
    hits: list[str] = []
    for raw in text.splitlines():
        if SCRIPT_ECHO in raw:
            continue
        line = ANSI.sub("", TIMESTAMP.sub("", raw)).rstrip()
        if line.startswith(("##[group]", "##[endgroup]", "[command]")):
            continue
        rule = next((name for name, rx in RULES if rx.search(line)), None)
        if rule is None:
            continue
        if any(
            e["_re"].search(line) and (e["_job"] is None or e["_job"].search(job))
            for e in allow
        ):
            continue
        hits.append(f"[{job}] {rule}: {line[:300]}")
    return hits


def fetch(url: str, token: str) -> bytes:
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    data = b""
    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:  # noqa: S310 (fixed host)
                data = resp.read()
            break
        except urllib.error.HTTPError as err:
            # A finished job's log can take a moment to become available.
            if err.code != 404 or attempt == 5:
                raise
            time.sleep(10)
    return data


def api_json(url: str, token: str) -> dict:
    return json.loads(fetch(url, token))


def api_text(url: str, token: str) -> str:
    return fetch(url, token).decode("utf-8", errors="replace")


def run_logs(repo: str, run_id: str, attempt: str, skip: list[str]):
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if not token:
        sys.exit("GH_TOKEN or GITHUB_TOKEN is required to read job logs")
    base = f"https://api.github.com/repos/{repo}/actions/runs/{run_id}"
    page = 1
    while True:
        data = api_json(f"{base}/attempts/{attempt}/jobs?per_page=100&page={page}", token)
        for job in data["jobs"]:
            name = job["name"]
            if any(name == s or name.endswith(f" / {s}") for s in skip):
                continue
            if job["status"] != "completed" or job["conclusion"] == "skipped":
                continue
            yield name, api_text(
                f"https://api.github.com/repos/{repo}/actions/jobs/{job['id']}/logs",
                token,
            )
        if len(data["jobs"]) < 100:
            return
        page += 1


def main() -> int:
    ap = argparse.ArgumentParser(description="Fail on warning or error lines in CI job logs.")
    ap.add_argument("files", nargs="*", type=Path)
    ap.add_argument("--repo")
    ap.add_argument("--run-id")
    ap.add_argument("--attempt", default="1")
    ap.add_argument("--skip-job", action="append", default=[])
    ap.add_argument("--allowlist", type=Path, default=DEFAULT_ALLOWLIST)
    args = ap.parse_args()

    allow, problems = load_allowlist(args.allowlist)
    if args.run_id:
        if not args.repo:
            ap.error("--run-id needs --repo")
        sources = run_logs(args.repo, args.run_id, args.attempt, args.skip_job)
    elif args.files:
        sources = ((str(f), f.read_text(encoding="utf-8", errors="replace")) for f in args.files)
    else:
        ap.error("give log files or --repo/--run-id")

    hits: list[str] = []
    scanned = 0
    for job, text in sources:
        scanned += 1
        hits.extend(scan(job, text, allow))

    for p in problems:
        print(f"::error::{p}")
    for h in hits:
        print(h)
    print(f"Scanned {scanned} log(s): {len(hits)} warning/error line(s), "
          f"{len(problems)} allow-list problem(s).")
    return 1 if hits or problems else 0


if __name__ == "__main__":
    sys.exit(main())
