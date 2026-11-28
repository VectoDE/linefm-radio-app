#!/usr/bin/env python3
"""Checks the Android accessibility tree of the running app on a device.

Takes `uiautomator dump` XML (from a file or via adb), the same tree that
TalkBack reads, and fails when
  * a clickable or checkable node has neither text nor content description
    (TalkBack would say "unlabelled" or nothing),
  * a clickable node is smaller than 48 x 48 dp,
  * the app package is not in the dump at all (wrong screen, crash).

Usage:
  android_tree_check.py --xml dump.xml [--package de.linefm.app] [--density 2.625]
  android_tree_check.py --adb PATH_TO_ADB [--serial emulator-5554] ...

What it cannot decide: spoken output, reading order under swipe gestures and
verbosity. Those stay manual checks (docs/GERAETETESTS.md).
"""
import argparse
import re
import subprocess
import sys
from html.parser import HTMLParser

BOUNDS = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")


def dump_via_adb(adb, serial):
    base = [adb] + (["-s", serial] if serial else [])
    subprocess.run(base + ["shell", "uiautomator", "dump", "/sdcard/a11y.xml"],
                   check=True, capture_output=True)
    return subprocess.run(base + ["exec-out", "cat", "/sdcard/a11y.xml"],
                          check=True, capture_output=True).stdout.decode("utf-8")


def density_via_adb(adb, serial):
    base = [adb] + (["-s", serial] if serial else [])
    out = subprocess.run(base + ["shell", "wm", "density"], check=True,
                         capture_output=True).stdout.decode()
    match = re.search(r"(\d+)\s*$", out.strip().splitlines()[-1])
    return int(match.group(1)) / 160.0 if match else 2.625


class Node:
    """Element of a uiautomator dump: tag, attributes and child elements."""

    def __init__(self, tag, attrs):
        self.tag = tag
        self.attrs = attrs
        self.children = []

    def get(self, name, default=None):
        return self.attrs.get(name, default)

    def iter(self, tag=None):
        """This element and all descendants in document order."""
        if tag is None or self.tag == tag:
            yield self
        for child in self.children:
            yield from child.iter(tag)


class _DumpParser(HTMLParser):
    """Builds the element tree. The input is a local uiautomator dump, never
    network data; this parser only splits tags and attributes and never
    resolves entities from a DTD, so no external entity or entity expansion
    can occur."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Node("#document", {})
        self._stack = [self.root]

    def handle_starttag(self, tag, attrs):
        element = Node(tag, {k: (v if v is not None else "") for k, v in attrs})
        self._stack[-1].children.append(element)
        self._stack.append(element)

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        self._stack.pop()

    def handle_endtag(self, tag):
        for i in range(len(self._stack) - 1, 0, -1):
            if self._stack[i].tag == tag:
                del self._stack[i:]
                return

    def handle_decl(self, decl):
        raise ValueError("dump contains a DTD, refusing to parse it")

    def unknown_decl(self, data):
        raise ValueError("dump contains a declaration, refusing to parse it")


def parse_dump(xml_text):
    """Parses a uiautomator dump; refuses DTDs and entity declarations."""
    if "<!DOCTYPE" in xml_text or "<!ENTITY" in xml_text:
        raise ValueError("dump contains a DTD, refusing to parse it")
    parser = _DumpParser()
    parser.feed(xml_text)
    parser.close()
    roots = parser.root.children
    if not roots:
        raise ValueError("dump contains no element")
    return roots[0]


def check(xml_text, package, density, min_dp=48.0):
    root = parse_dump(xml_text)
    nodes = [n for n in root.iter("node") if n.get("package") == package]
    problems = []
    if not nodes:
        return ["no node of package %s in the dump" % package], 0, 0
    interactive = 0
    for node in nodes:
        clickable = node.get("clickable") == "true" or node.get("checkable") == "true"
        if not clickable or node.get("enabled") == "false":
            continue
        interactive += 1
        name = (node.get("text") or node.get("content-desc") or "").strip()
        match = BOUNDS.match(node.get("bounds") or "")
        where = node.get("bounds")
        if not name:
            # A clickable container often has labelled children; TalkBack reads
            # those when the container itself is not focusable.
            if not any((c.get("text") or c.get("content-desc") or "").strip()
                       for c in node.iter("node") if c is not node):
                problems.append("unlabelled interactive node %s class=%s"
                                % (where, node.get("class")))
        if match:
            x1, y1, x2, y2 = (int(v) for v in match.groups())
            w, h = (x2 - x1) / density, (y2 - y1) / density
            if w < min_dp - 0.5 or h < min_dp - 0.5:
                problems.append("touch target %.0fx%.0f dp at %s (%s)"
                                % (w, h, where, name or "no name"))
    return problems, len(nodes), interactive


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--xml")
    p.add_argument("--adb")
    p.add_argument("--serial")
    p.add_argument("--package", default="de.linefm.app")
    p.add_argument("--density", type=float)
    a = p.parse_args()
    if a.xml:
        text = open(a.xml, encoding="utf-8").read()
        density = a.density or 2.625
    elif a.adb:
        text = dump_via_adb(a.adb, a.serial)
        density = a.density or density_via_adb(a.adb, a.serial)
    else:
        p.error("give --xml or --adb")
    problems, total, interactive = check(text, a.package, density)
    print("nodes of %s: %d, interactive: %d, density: %.3f"
          % (a.package, total, interactive, density))
    for line in problems:
        print("FAIL", line)
    if problems:
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
