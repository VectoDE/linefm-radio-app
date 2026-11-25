#!/usr/bin/env python3
"""Fails when a CI job log contains a warning or an error line.

Every warning in a build log is a defect: compiler and CMake warnings,
PowerShell errors, Gradle/Xcode/Flutter warnings, workflow annotations and pub
notices about outdated or overridden packages. This script scans job logs and
exits non-zero when any log that contains any such line that is not covered
by an active entry in tool/build_log_allowlist.json.

It also fails on check-run annotations of level warning or failure (the
notices GitHub shows on the run page, such as "Node.js 20 actions are
deprecated"), which never appear in the job log itself.

Usage:
  check_build_logs.py FILE [FILE ...]
The script never touches the network; tool/fetch_job_logs.sh downloads the
logs of a workflow run first (one file per job, named after the job, suffix
.log) and tool/fetch_run_annotations.sh the annotations (suffix .annotations,
one "LEVEL<TAB>TITLE: MESSAGE" per line). Both kinds can be passed together.

Allow-list entries (JSON list): {"pattern": regex, "job": optional regex,
"expires": "YYYY-MM-DD", "reason": text}. An expired entry fails the check so
that it gets reviewed instead of lingering.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
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


# Annotation levels that fail the check; "notice" is informational.
FAILING_ANNOTATION_LEVELS = {"warning", "failure"}


def scan_annotations(job: str, text: str, allow: list[dict]) -> list[str]:
    hits: list[str] = []
    for raw in text.splitlines():
        level, sep, message = raw.partition("	")
        if not sep or level not in FAILING_ANNOTATION_LEVELS:
            continue
        message = message.strip()
        if any(
            e["_re"].search(message) and (e["_job"] is None or e["_job"].search(job))
            for e in allow
        ):
            continue
        hits.append(f"[{job}] annotation-{level}: {message[:300]}")
    return hits


def main() -> int:
    ap = argparse.ArgumentParser(description="Fail on warning or error lines in CI job logs.")
    ap.add_argument("files", nargs="*", type=Path)
    ap.add_argument("--allowlist", type=Path, default=DEFAULT_ALLOWLIST)
    args = ap.parse_args()

    allow, problems = load_allowlist(args.allowlist)
    if not args.files:
        ap.error("give one or more log files")
    hits: list[str] = []
    scanned = 0
    for f in args.files:
        # The job name is the file name without its suffix (see the fetch scripts).
        text = f.read_text(encoding="utf-8", errors="replace")
        scanned += 1
        if f.suffix == ".annotations":
            hits.extend(scan_annotations(f.stem, text, allow))
        else:
            hits.extend(scan(f.stem, text, allow))

    for p in problems:
        print(f"::error::{p}")
    for h in hits:
        print(h)
    print(f"Scanned {scanned} file(s): {len(hits)} warning/error line(s), "
          f"{len(problems)} allow-list problem(s).")
    return 1 if hits or problems else 0


if __name__ == "__main__":
    sys.exit(main())
