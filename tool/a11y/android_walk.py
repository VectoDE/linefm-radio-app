#!/usr/bin/env python3
"""Walks the main areas of the installed app on a running Android device or
emulator (tap per navigation label) and runs android_tree_check.py on each.

Usage: android_walk.py ADB [LABEL ...]
Default labels are the English navigation labels; the device language has to
match. The app must be installed and started (adb shell am start ...).
"""
import importlib.util
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
_SPEC = importlib.util.spec_from_file_location(
    "android_tree_check", os.path.join(HERE, "android_tree_check.py"))
tree_check = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(tree_check)
BOUNDS = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")


def main():
    adb = sys.argv[1]
    labels = sys.argv[2:] or ["Stations", "Player", "History", "Favorites", "Settings"]

    def sh(*args):
        return subprocess.run([adb, *args], capture_output=True).stdout.decode("utf-8", "replace")

    def tap(label):
        sh("shell", "uiautomator", "dump", "/sdcard/a11y.xml")
        root = tree_check.parse_dump(sh("exec-out", "cat", "/sdcard/a11y.xml"))
        for node in root.iter("node"):
            if label in (node.get("content-desc"), node.get("text")) and node.get("clickable") == "true":
                x1, y1, x2, y2 = map(int, BOUNDS.match(node.get("bounds")).groups())
                sh("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))
                time.sleep(2)
                return True
        return False

    failed = False
    for index, label in enumerate(labels):
        if index and not tap(label):
            print("==", label, "FAIL: navigation target not found")
            failed = True
            continue
        text = tree_check.dump_via_adb(adb, None)
        density = tree_check.density_via_adb(adb, None)
        problems, total, interactive = tree_check.check(text, "de.linefm.app", density)
        print("==", label)
        print("nodes: %d, interactive: %d, density: %.3f" % (total, interactive, density))
        for line in problems:
            print("FAIL", line)
        failed = failed or bool(problems)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
