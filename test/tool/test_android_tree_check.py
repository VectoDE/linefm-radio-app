"""Unit tests for tool/a11y/android_tree_check.py (standard library only).

Run from the repository root:
  python -m unittest discover -s test/tool -p "test_*.py"
"""

import importlib.util
import unittest
from pathlib import Path

_SPEC = importlib.util.spec_from_file_location(
    "android_tree_check",
    Path(__file__).resolve().parents[2] / "tool" / "a11y" / "android_tree_check.py",
)
c = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(c)

PKG = "de.linefm.app"


def tree(*nodes):
    return "<hierarchy>" + "".join(nodes) + "</hierarchy>"


def node(text="", desc="", clickable="true", bounds="[0,0][168,168]", inner=""):
    return ('<node package="%s" class="android.view.View" text="%s" content-desc="%s" '
            'clickable="%s" checkable="false" enabled="true" bounds="%s">%s</node>'
            % (PKG, text, desc, clickable, bounds, inner))


class CheckTest(unittest.TestCase):
    def test_labelled_and_large_enough(self):
        problems, _, n = c.check(tree(node(desc="Play")), PKG, 3.5)
        self.assertEqual(problems, [])
        self.assertEqual(n, 1)

    def test_unlabelled(self):
        problems, _, _ = c.check(tree(node()), PKG, 3.5)
        self.assertEqual(len(problems), 1)
        self.assertIn("unlabelled", problems[0])

    def test_label_on_child_counts(self):
        problems, _, _ = c.check(tree(node(inner=node(desc="Play", clickable="false"))), PKG, 3.5)
        self.assertEqual(problems, [])

    def test_small_target(self):
        problems, _, _ = c.check(tree(node(desc="x", bounds="[0,0][100,100]")), PKG, 3.5)
        self.assertEqual(len(problems), 1)
        self.assertIn("touch target", problems[0])

    def test_wrong_package(self):
        problems, _, _ = c.check(tree(node(desc="x")), "other.app", 3.5)
        self.assertEqual(len(problems), 1)

    def test_refuses_dtd(self):
        bomb = '<!DOCTYPE h [<!ENTITY a "aaaa">]>' + tree(node(desc="&a;"))
        with self.assertRaises(ValueError):
            c.check(bomb, PKG, 3.5)


if __name__ == "__main__":
    unittest.main()
