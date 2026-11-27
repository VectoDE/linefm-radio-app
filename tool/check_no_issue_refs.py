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

  audit     IDs of review findings used as tracking markers, e.g. "D80-10",
            "A11Y-08", "Q-14", "L3-01", "R3-P01", or a short ID such as
            "(U2)", "(P31, Consent Mode)" or "S6/Q-08". Findings live in the
            tracker; the file states the reason in words. Hyphenated IDs are
            prefix plus number; short IDs (one to three capitals plus one to
            three digits) only count inside parentheses or a slash list.

Allow-list (false positives, each with its reason):
  - repeated-digit shorthand colors such as #111, #333, #999 (CSS/SVG/YAML)
  - HTML/XML character references such as &#10; or &#39; (the "&" precedes)
  - references to other projects written as owner/repo#<n> or as a URL of
    another repository: they point to upstream trackers for workarounds, not
    to this repository's tracker (the "bare" pattern needs a non-word
    character before "#", so "repo#16" never matches)
  - tool/font_fallback.lock.json: generated data, not prose
  - audit: standard and format names with a number (SHA-256, UTF-8, GPL-3,
    ISO-8601, GTM-..., MP3, H264, ...), cell references after a function
    name such as SUM(A1), tokens glued to other characters (base64, hashes),
    and section numbers a Markdown file defines itself as headings
    ("### A1 ...", then "(A1)" points to that section), and rule IDs a
    Markdown catalog defines as anchors (<a id="g-08"></a>): they are the
    catalog's own item names, usable in any Markdown file
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
AUDIT_HYPHEN = re.compile(
    r"(?<![\w./+-])([A-Z][A-Z0-9]{0,4})-([A-Z]?\d{1,3})(?![\w.+-])"
)
AUDIT_SHORT = re.compile(
    r"(?:(?<=[ \t]\()|(?<=^\()|(?<=, )|(?<=; )|(?<=/))"
    r"([A-Z]{1,3}\d{1,3})(?=[),;/]|, )"
)
AUDIT_ALLOW = {
    "AA", "AAA", "AAC", "AES", "AGPL", "BSD", "CC0", "CVE", "CWE", "DIN",
    "ECMA", "EN", "ES", "G", "GA4", "GHSA", "GPL", "GTM", "H", "H264",
    "H265", "HTTP", "IEC", "IPV", "ISO", "LGPL", "MA", "MD5", "MP3", "MP4", "MPL",
    "OFL", "OSV", "PEP", "RFC", "SHA", "SL", "TLS", "UA", "UTF", "VP8", "VP9",
    "W3C", "WCAG", "X",
}
PREV_ID = re.compile(
    r"(?:^|[\s(,])(?=[A-Z0-9-]*\d)[A-Z][A-Z0-9]{0,4}(?:-[A-Z]?\d{1,3})?/$"
)
ANCHOR_ID = re.compile(r'<a id="([a-z]{1,5}-\d{1,3})"></a>')
HEADING_ID = re.compile(r"^#{1,6}\s+([A-Z]{1,3}\d{1,3})\b", re.MULTILINE)


def audit_ids(line, local_ids=frozenset()):
    """Audit-finding IDs in [line]; [local_ids] are a file's own sections."""
    found = []
    for m in AUDIT_HYPHEN.finditer(line):
        if m.group(1) not in AUDIT_ALLOW and m.group(0) not in local_ids:
            found.append(m.group(0))
    for m in AUDIT_SHORT.finditer(line):
        token = m.group(1)
        if token not in AUDIT_ALLOW and token not in local_ids:
            # "/" only starts a list after another ID ("S6/Q-08", "A11Y-02/07").
            if line[m.start() - 1] == "/" and not PREV_ID.search(
                line[: m.start()]
            ):
                continue
            found.append(token)
    return found


SHORTHAND_COLOR = re.compile(r"#(\d)\1\1\b")
SKIP_FILES = {"tool/font_fallback.lock.json"}


def tracked_files():
    out = subprocess.check_output(["git", "ls-files", "-z"])
    return [p for p in out.decode("utf-8").split("\0") if p]


def catalog_ids(paths):
    """Rule IDs that Markdown catalogs define as anchors, upper-cased."""
    ids = set()
    for path in paths:
        if not path.endswith(".md"):
            continue
        try:
            with open(path, encoding="utf-8") as fh:
                ids.update(a.upper() for a in ANCHOR_ID.findall(fh.read()))
        except (OSError, UnicodeDecodeError):
            continue
    return frozenset(ids)


def main():
    findings = 0
    paths = tracked_files()
    catalog = catalog_ids(paths)
    for path in paths:
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
        local_ids = (
            frozenset(HEADING_ID.findall(text)) | catalog
            if path.endswith(".md")
            else frozenset()
        )
        audit_on = (
            not path.startswith(WORD_SKIP_PREFIXES)
            and "LICENSE" not in path
            and not path.endswith(".json")
        )
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
            if audit_on and audit_ids(line, local_ids):
                print(f"{path}:{number}: [audit] {line.strip()[:120]}")
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
