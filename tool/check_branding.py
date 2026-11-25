#!/usr/bin/env python3
"""Fail if a tracked file uses a retired brand name or shows a developer URL.

Rules (no exceptions, the retired name is assembled below so that this file
does not contain it either):
  retired   the retired brand name, in any capitalisation, in any tracked text
            file (code, ARB, installer, packaging, docs, store texts, web)
  url       the developer's GitHub address inside a UI string (lib/l10n/*.arb):
            the developer is shown by name and linked, the address itself is
            never visible

Usage: python3 tool/check_branding.py   (exit 1 on any finding)
"""
import re
import subprocess
import sys

RETIRED = re.compile("jay" + "belife", re.IGNORECASE)
DEVELOPER_URL = re.compile(r"github\.com/VectoDE", re.IGNORECASE)
UI_STRING_FILES = re.compile(r"^lib/l10n/[^/]+\.arb$")
SKIP_PREFIXES = ("lib/l10n/gen/",)
SKIP_FILES = {"tool/font_fallback.lock.json"}


def tracked_files():
    out = subprocess.check_output(["git", "ls-files", "-z"])
    return [p for p in out.decode("utf-8").split("\0") if p]


def check_text(path, text):
    """Return a list of 'path:line: [rule] text' findings for one file."""
    found = []
    for number, line in enumerate(text.splitlines(), 1):
        if RETIRED.search(line):
            found.append(f"{path}:{number}: [retired] {line.strip()[:120]}")
        elif UI_STRING_FILES.match(path) and DEVELOPER_URL.search(line):
            found.append(f"{path}:{number}: [url] {line.strip()[:120]}")
    return found


def main():
    findings = []
    for path in tracked_files():
        if path in SKIP_FILES or path.startswith(SKIP_PREFIXES):
            continue
        try:
            with open(path, "rb") as fh:
                data = fh.read()
            if b"\0" in data:
                continue
            text = data.decode("utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        findings.extend(check_text(path, text))
    if findings:
        print("\n".join(findings))
        print(f"\n{len(findings)} branding finding(s).", file=sys.stderr)
        return 1
    print("No retired brand names and no visible developer URLs.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
