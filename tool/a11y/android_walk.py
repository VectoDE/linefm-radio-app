#!/usr/bin/env python3
"""Walks the main areas of the installed app on a running Android device or
emulator and runs android_tree_check.py on each.

Usage: android_walk.py ADB [--out DIR] [LABEL ...]

A plain LABEL is a navigation target: the walk taps the clickable node whose
text or content description equals it. A LABEL of the form "Parent>Row"
opens Parent first, then taps the first clickable node whose name starts
with Row (scrolling down if needed), checks that screen and goes back.
Default labels are the English labels of the five areas plus Alarm and About
from Settings; the device language has to match. The app must be installed
and started (adb shell am start ...).

With --out the walk writes one uiautomator dump per screen and a JSON
report (walk.json) with the named interactive nodes, i.e. what TalkBack
offers as focus stops, and every finding.
"""
import importlib.util
import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
_SPEC = importlib.util.spec_from_file_location(
    "android_tree_check", os.path.join(HERE, "android_tree_check.py"))
if _SPEC is None or _SPEC.loader is None:
    raise ImportError("cannot load android_tree_check.py")
tree_check = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(tree_check)
BOUNDS = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")
PACKAGE = "de.linefm.app"
DEFAULT_LABELS = ["Stations", "Player", "History", "Favorites", "Settings",
                  "Settings>Alarm", "Settings>About LINEFM Radio"]


def node_name(node):
    return (node.get("content-desc") or node.get("text") or "").strip()


def focus_stops(xml_text):
    """Named interactive nodes of the app in document order."""
    root = tree_check.parse_dump(xml_text)
    stops = []
    for node in root.iter("node"):
        if node.get("package") != PACKAGE:
            continue
        if node.get("clickable") == "true" or node.get("checkable") == "true":
            stops.append({"name": node_name(node), "class": node.get("class"),
                          "bounds": node.get("bounds")})
    return stops


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    adb = args.pop(0)
    out = None
    if args[:1] == ["--out"]:
        out = args[1]
        args = args[2:]
        os.makedirs(out, exist_ok=True)
    labels = args or DEFAULT_LABELS

    def sh(*cmd):
        return subprocess.run([adb, *cmd], capture_output=True).stdout.decode("utf-8", "replace")

    def dump():
        sh("shell", "uiautomator", "dump", "/sdcard/a11y.xml")
        return sh("exec-out", "cat", "/sdcard/a11y.xml")

    def tap(label, prefix=False, scrolls=0):
        for attempt in range(scrolls + 1):
            root = tree_check.parse_dump(dump())
            for node in root.iter("node"):
                name = node_name(node)
                hit = name.startswith(label) if prefix else label in (
                    node.get("content-desc"), node.get("text"))
                if hit and node.get("clickable") == "true":
                    match = BOUNDS.match(node.get("bounds") or "")
                    if match is None:
                        continue
                    x1, y1, x2, y2 = map(int, match.groups())
                    sh("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))
                    time.sleep(2)
                    return True
            if attempt < scrolls:
                size = re.findall(r"(\d+)x(\d+)", sh("shell", "wm", "size"))
                w, h = map(int, size[-1]) if size else (1080, 2400)
                sh("shell", "input", "swipe", str(w // 2), str(h * 3 // 4),
                   str(w // 2), str(h // 4), "300")
                time.sleep(1)
        return False

    report = {"package": PACKAGE, "screens": []}
    failed = False
    for index, label in enumerate(labels):
        parent, _, row = label.partition(">")
        reached = True
        if row:
            reached = tap(parent) and tap(row, prefix=True, scrolls=4)
        elif index:
            reached = tap(label)
        if not reached:
            print("==", label, "FAIL: navigation target not found")
            report["screens"].append({"screen": label, "error": "navigation target not found"})
            failed = True
            continue
        text = dump()
        density = tree_check.density_via_adb(adb, None)
        problems, total, interactive = tree_check.check(text, PACKAGE, density)
        print("==", label)
        print("nodes: %d, interactive: %d, density: %.3f" % (total, interactive, density))
        for line in problems:
            print("FAIL", line)
        failed = failed or bool(problems)
        entry = {"screen": label, "nodes": total, "interactive": interactive,
                 "problems": problems}
        if out:
            slug = re.sub(r"[^a-z0-9]+", "-", label.lower()).strip("-")
            with open(os.path.join(out, "tree-%s.xml" % slug), "w", encoding="utf-8") as f:
                f.write(text)
            entry["focusStops"] = focus_stops(text)
        report["screens"].append(entry)
        if row:
            sh("shell", "input", "keyevent", "KEYCODE_BACK")
            time.sleep(2)
    if out:
        with open(os.path.join(out, "walk.json"), "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
