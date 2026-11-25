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

  word      the concepts themselves ("issue", "pull request", "PR") are not
            used in files either; write "ticket", "proposed change" or
            describe the behaviour. Case-insensitive except "PR", whole words
            only, so "PRNG" or "express" do not match.

Allow-list (false positives, each with its reason):
  - repeated-digit shorthand colors such as #111, #333, #999 (CSS/SVG/YAML)
  - HTML/XML character references such as &#10; or &#39; (the "&" precedes)
  - references to other projects written as owner/repo#<n> or as a URL of
    another repository: they point to upstream trackers for workarounds, not
    to this repository's tracker (the "bare" pattern needs a non-word
    character before "#", so "repo#16" never matches)
  - tool/font_fallback.lock.json: generated data, not prose
  - lib/l10n/gen/: output of the localizations tool, text comes from Flutter
  - LICENSE files of third parties (verbatim legal text)
  - machine-required GitHub identifiers, matched per line (see WORD_ALLOW):
    the "issues:" and "pull-requests:" permission keys and "issues:" trigger,
    "gh issue ..." and "gh api ..." calls, "github.event.issue", API paths
    "repos/.../issues", the web path "/issues/new" of the new-report form, and
    Dependabot's "open-pull-requests-limit". They cannot be renamed. The
    identifiers pull_request, pull_request_target and ISSUE_TEMPLATE contain
    an underscore and are not words, so they need no entry.

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
WORD_CASE = re.compile(r"\bPRs?\b")  # "PR" is matched case-sensitively
WORD_NOCASE = re.compile(r"\b(?:issues?|pull[ -]requests?)\b", re.IGNORECASE)
WORD_ALLOW = [
    re.compile(p)
    for p in (
        r"^\s*issues:\s*(?:read|write)?\s*$",
        r"^\s*pull-requests:",
        r"github\.event\.issue",
        r"\bgh (?:issue|api)\b",
        r"repos/\S*/issues",
        r"/issues/new",
        r"open-pull-requests-limit",
    )
]
# This file documents the words it forbids.
WORD_SKIP_PREFIXES = ("lib/l10n/gen/", "tool/check_no_issue_refs.py")
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
            if (
                not path.startswith(WORD_SKIP_PREFIXES)
                and "LICENSE" not in path
                and not any(a.search(line) for a in WORD_ALLOW)
                and (WORD_NOCASE.search(line) or WORD_CASE.search(line))
            ):
                print(f"{path}:{number}: [word] {line.strip()[:120]}")
                findings += 1
                continue
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
