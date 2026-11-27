"""Unit tests for tool/check_native_lgpl.py (standard library only)."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("check_native_lgpl", ROOT / "tool/check_native_lgpl.py")
cnl = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(cnl)

MPV_LGPL = b"\x00Configuration: -Dgpl=false -Dlibmpv=true\x00"
MPV_GPL = b"\x00Configuration: -Dlibmpv=true -Dcdda=enabled\x00"
FF_LGPL = (
    b"\x00libavcodec license: LGPL version 3 or later\x00"
    b"--prefix=/usr --disable-gpl --enable-version3 --enable-shared\x00"
)
FF_GPL = (
    b"\x00libavcodec license: GPL version 3 or later\x00"
    b"--prefix=/usr --enable-gpl --enable-version3\x00"
)


class CheckBytesTest(unittest.TestCase):
    def test_lgpl_ok(self) -> None:
        probs, mpv, av = cnl.check_bytes("x", MPV_LGPL + FF_LGPL)
        self.assertEqual(probs, [])
        self.assertTrue(mpv and av)

    def test_gpl_mpv(self) -> None:
        probs, _, _ = cnl.check_bytes("x", MPV_GPL)
        self.assertTrue(any("-Dgpl=false" in p for p in probs))

    def test_gpl_ffmpeg(self) -> None:
        probs, _, av = cnl.check_bytes("x", FF_GPL)
        self.assertTrue(av)
        self.assertEqual(len(probs), 2)


class MainTest(unittest.TestCase):
    def _run(self, files: dict[str, bytes]) -> int:
        with tempfile.TemporaryDirectory() as d:
            for name, data in files.items():
                p = Path(d) / name
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_bytes(data)
            # The expected "error:" lines stay out of the CI log (log gate).
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                rc = cnl.main([d])
            self.output = out.getvalue()
            return rc

    def test_snap_layout_ok(self) -> None:
        rc = self._run({
            "usr/lib/x86_64-linux-gnu/libmpv.so.2.5.0": MPV_LGPL,
            "usr/lib/x86_64-linux-gnu/libavcodec.so.62.11.100": FF_LGPL,
        })
        self.assertEqual(rc, 0)

    def test_gpl_fails(self) -> None:
        rc = self._run({"libmpv.so.2": MPV_GPL, "libavcodec.so.60": FF_GPL})
        self.assertEqual(rc, 1)
        self.assertIn("GPL build", self.output)

    def test_missing_fails(self) -> None:
        self.assertEqual(self._run({"other.so": b"x"}), 1)


if __name__ == "__main__":
    unittest.main()
