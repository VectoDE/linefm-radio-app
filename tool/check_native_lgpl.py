"""Fail if bundled libmpv/FFmpeg libraries were built with GPL parts.

The app is proprietary, so the desktop packages may only ship LGPL builds of
libmpv and FFmpeg (see docs/LIZENZEN-DRITTE.md). Both libraries embed their
build configuration as plain text:

- mpv:    "Configuration: -Dgpl=false ..." (meson options)
- FFmpeg: "libavcodec license: LGPL version 3 or later" and the configure
          line ("--disable-gpl ..." or no "--enable-gpl")

Usage:
  python3 -I tool/check_native_lgpl.py <dir> [<dir> ...]

Scans every libmpv*/libav*/libsw* shared library (.so*, .dll) below the given
directories. Exit 0 if at least one mpv and one libavcodec build configuration
were found and all are LGPL, otherwise exit 1. Standard library only.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

_NAME = re.compile(r"^(libmpv|libav[a-z]+|libsw[a-z]+)[^/]*\.(so(\.[0-9.]+)?|dll)$")
_MPV_CONFIG = re.compile(rb"Configuration: (-D[ -~]+)")
_FF_LICENSE = re.compile(rb"(lib[a-z]+) license: ([ -~]+)")
_FF_CONFIGURE = re.compile(rb"[ -~]*--prefix=[ -~]*")


def candidates(roots: list[Path]) -> list[Path]:
    out: list[Path] = []
    for root in roots:
        for p in sorted(root.rglob("*")):
            if p.is_file() and not p.is_symlink() and _NAME.match(p.name):
                out.append(p)
    return out


def check_bytes(name: str, data: bytes) -> tuple[list[str], bool, bool]:
    """Return (problems, saw_mpv_config, saw_avcodec_license) for one file."""
    problems: list[str] = []
    saw_mpv = False
    saw_avcodec = False
    for m in _MPV_CONFIG.finditer(data):
        saw_mpv = True
        opts = m.group(1).decode("ascii", "replace").split()
        if "-Dgpl=false" not in opts:
            problems.append(f"{name}: mpv built without -Dgpl=false (GPL build)")
    for m in _FF_LICENSE.finditer(data):
        lib = m.group(1).decode()
        lic = m.group(2).decode("ascii", "replace")
        if lib == "libavcodec":
            saw_avcodec = True
        if not lic.startswith("LGPL"):
            problems.append(f"{name}: {lib} license is '{lic}'")
    for m in _FF_CONFIGURE.finditer(data):
        line = m.group(0).decode("ascii", "replace").split()
        if "--enable-gpl" in line or "--enable-nonfree" in line:
            problems.append(f"{name}: FFmpeg configured with --enable-gpl/--enable-nonfree")
    return problems, saw_mpv, saw_avcodec


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__)
        return 2
    roots = [Path(a) for a in argv]
    for r in roots:
        if not r.is_dir():
            print(f"error: not a directory: {r}")
            return 2
    problems: list[str] = []
    saw_mpv = saw_avcodec = False
    files = candidates(roots)
    for p in files:
        probs, m, a = check_bytes(str(p), p.read_bytes())
        problems += probs
        saw_mpv |= m
        saw_avcodec |= a
    if not saw_mpv:
        problems.append("no mpv build configuration found (libmpv missing?)")
    if not saw_avcodec:
        problems.append("no libavcodec license string found (FFmpeg missing?)")
    for line in sorted(set(problems)):
        print(f"error: {line}")
    if problems:
        return 1
    print(f"OK: {len(files)} libraries checked, mpv and FFmpeg are LGPL builds.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
