#!/usr/bin/env python3
"""Fail if a tracked file refers to a tracker item (issue or pull request).

Repository rule: files describe behaviour and reasons in plain words. Numbers
of issues or pull requests belong into commit messages, branch names and the
tracker itself, never into code, comments, tests, strings, configs, scripts,
workflows or Markdown.

Flagged patterns (case-insensitive where noted):
  keyword   issue/issues/PR/pull request/Refs/Fixes/Closes/Resolves followed by #<number>
  bare      #<number> (1 to 4 digits) that is not part of a longer word or
            entity, e.g. a number in parentheses or after "see"
  url       a link to /issues/<n> or /pull/<n> of this repository

Allow-list (false positives, each with its reason):
  - repeated-digit shorthand colors such as #111, #333, #999 (CSS/SVG/YAML)
  - HTML/XML character references such as &#10; or &#39; (the "&" precedes)
  - references to other projects written as owner/repo#<n> or as a URL of
    another repository: they point to upstream trackers for workarounds, not
    to this repository's tracker (the "bare" pattern needs a non-word
    character before "#", so "repo#16" never matches)
  - tool/font_fallback.lock.json: generated data, not prose

Usage: python3 tool/check_no_issue_refs.py   (exit 1 on any finding)
"""
import re
import subprocess
import sys

OWN_REPO = r"github\.com/VectoDE/linefm-radio-app"

PATTERNS = {
    "keyword": re.compile(
        r"\b(?:issues?|prs?|pull[ -]?requests?|refs?|fix(?:es|ed)?|"
        r"close[sd]?|resolve[sd]?)[ -]?#\d+",
        re.IGNORECASE,
    ),
    "bare": re.compile(r"(?<![\w&/#])#\d{1,4}\b"),
    "url": re.compile(OWN_REPO + r"/(?:issues|pull)/\d+"),
}
SHORTHAND_COLOR = re.compile(r"#(\d)\1\1\b")
SKIP_FILES = {"tool/font_fallback.lock.json"}


def tracked_files():
    out = subprocess.check_output(["git", "ls-files", "-z"])
    return [p for p in out.decode("utf-8").split("\0") if p]


def main():
    findings = 0
    for path in tracked_files():
        if path in SKIP_FILES:
            continue
        try:
            with open(path, "rb") as fh:
                data = fh.read()
            if b"\0" in data:
                continue
            text = data.decode("utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        for number, line in enumerate(text.splitlines(), 1):
            scrubbed = SHORTHAND_COLOR.sub("", line)
            for name, pattern in PATTERNS.items():
                if pattern.search(scrubbed):
                    print(f"{path}:{number}: [{name}] {line.strip()[:120]}")
                    findings += 1
                    break
    if findings:
        print(f"\n{findings} reference(s) to issues or pull requests found. "
              "Describe the behaviour in words instead.", file=sys.stderr)
        return 1
    print("No references to issues or pull requests in tracked files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
