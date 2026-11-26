#!/usr/bin/env python3
"""Fail if GitHub Actions files contain German text.

Everything that runs in or shows up in GitHub Actions is English: workflow,
job and step names, comments, log messages, job summaries and composite
action metadata. This check scans those files for

  umlaut   any of the characters a/o/u with umlaut or sharp s
  word     a curated list of common German words, including the ASCII
           spellings with ae/oe/ue/ss that avoid umlauts

Proper names are allowed (see ALLOWED). A single line can opt out with the
marker "english-ci: allow" when it must carry German data verbatim.

Usage: python3 tool/check_english_ci.py   (exit 1 on any finding)
"""
import re
import subprocess
import sys

# Files that run in or are shown by GitHub Actions.
SCAN_PREFIXES = (".github/workflows/", ".github/actions/")
SCAN_FILES = {".github/dependabot.yml", ".github/zizmor.yml", ".github/CODEOWNERS"}

UMLAUT = re.compile("[äöüÄÖÜß]")
ALLOW_MARKER = "english-ci: allow"

# Proper names that may contain words from the list below.
ALLOWED = re.compile(r"LineFM Studios|LINEFM|LineFM|bauen\.(?:sh|ps1)", re.IGNORECASE)

# Common German words that are not also everyday English words.
GERMAN_WORDS = {
    "aber", "abhaengigkeit", "abhaengigkeiten", "alle", "allen", "aller",
    "alles", "als", "anlegen", "auch", "auf", "aufraeumen", "aus", "ausfuehren",
    "bauen", "bei", "beim", "bereits", "bericht", "berichte", "bitte", "bleibt",
    "dann", "darf", "dass", "dabei", "damit", "danach", "dazu", "deine",
    "dem", "den", "denn", "der", "des", "dies", "diese", "diesem", "diesen",
    "dieser", "dieses", "doch", "dort", "durch", "eigene", "ein", "eine",
    "einem", "einen", "einer", "eines", "einrichten", "erst", "erstellen",
    "erzeugen", "fehler", "fehlt", "fehlen", "fuer", "ganz", "gegen",
    "geprueft", "gibt", "haerten", "hier", "hochladen", "ihre", "immer",
    "installieren", "ist", "jede", "jeder", "jedes", "kein", "keine", "keinen",
    "koennen", "kommt", "laeuft", "laufen", "mehr", "muss", "nach", "nicht",
    "noch", "nur", "oder", "ohne", "pruefen", "pruefung", "schon", "sein",
    "sich", "sind", "sonst", "ueber", "und", "unter", "veroeffentlichen",
    "vom", "von", "vor", "waere", "wenn", "werden", "wird", "wie", "weil",
    "zum", "zur", "zwischen",
}
WORD = re.compile(r"[A-Za-z]+")


def tracked_files():
    out = subprocess.check_output(["git", "ls-files", "-z"])
    return [p for p in out.decode("utf-8").split("\0") if p]


def in_scope(path):
    return path in SCAN_FILES or path.startswith(SCAN_PREFIXES)


def check_text(path, text):
    """Return a list of 'path:line: [rule] text' findings for one file."""
    found = []
    for number, line in enumerate(text.splitlines(), 1):
        if ALLOW_MARKER in line:
            continue
        clean = ALLOWED.sub(" ", line)
        if UMLAUT.search(clean):
            found.append(f"{path}:{number}: [umlaut] {line.strip()[:120]}")
            continue
        words = sorted({w.lower() for w in WORD.findall(clean)} & GERMAN_WORDS)
        if words:
            found.append(f"{path}:{number}: [word {','.join(words)}] {line.strip()[:120]}")
    return found


def main():
    findings = []
    for path in tracked_files():
        if not in_scope(path):
            continue
        try:
            with open(path, encoding="utf-8") as fh:
                text = fh.read()
        except (OSError, UnicodeDecodeError):
            continue
        findings.extend(check_text(path, text))
    if findings:
        print("\n".join(findings))
        print(f"\n{len(findings)} German text finding(s) in GitHub Actions files.", file=sys.stderr)
        return 1
    print("GitHub Actions files are English.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
