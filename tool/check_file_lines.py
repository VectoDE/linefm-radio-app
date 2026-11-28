#!/usr/bin/env python3
"""Fail if a Dart file under lib/ or test/ has more than 400 lines.

Generated files are skipped: *.g.dart, *.freezed.dart, *.mocks.dart and the
localization output under lib/l10n/gen/.

Usage: python3 tool/check_file_lines.py   (exit 1 on any finding)
"""
import subprocess
import sys

LIMIT = 400
ROOTS = ("lib/", "test/")
GENERATED_SUFFIXES = (".g.dart", ".freezed.dart", ".mocks.dart")
GENERATED_PREFIXES = ("lib/l10n/gen/",)


def is_checked(path):
    return (
        path.endswith(".dart")
        and path.startswith(ROOTS)
        and not path.endswith(GENERATED_SUFFIXES)
        and not path.startswith(GENERATED_PREFIXES)
    )


def count_lines(text):
    return len(text.splitlines())


def tracked_files():
    out = subprocess.check_output(["git", "ls-files", "-z", "--", *ROOTS])
    return [p for p in out.decode("utf-8").split("\0") if p]


def findings(files, read):
    result = []
    for path in sorted(files):
        if not is_checked(path):
            continue
        lines = count_lines(read(path))
        if lines > LIMIT:
            result.append((path, lines))
    return result


def _read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def main():
    found = findings(tracked_files(), _read)
    for path, lines in found:
        print(f"{path}: {lines} lines (limit {LIMIT})")
    if found:
        print(f"{len(found)} file(s) above {LIMIT} lines; split them into focused files.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
