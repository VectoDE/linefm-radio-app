#!/usr/bin/env python3
"""Tests for tool/hosting_check.py: the repository configs pass, and each kind of drift is caught."""

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hosting_check  # noqa: E402

REPO = Path(__file__).resolve().parent.parent


class ConsistencyTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        shutil.copytree(REPO / "deploy", self.tmp / "deploy")

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def edit(self, rel: str, old: str, new: str) -> None:
        path = self.tmp / "deploy" / rel
        text = path.read_text(encoding="utf-8")
        self.assertIn(old, text)
        path.write_text(text.replace(old, new, 1), encoding="utf-8")

    def test_repository_is_consistent(self):
        self.assertEqual(hosting_check.consistency(REPO), [])

    def test_csp_drift_in_cloudflare_is_found(self):
        self.edit("cloudflare/_headers", "frame-ancestors 'none'", "frame-ancestors 'self'")
        errors = hosting_check.consistency(self.tmp)
        self.assertTrue(any("content-security-policy" in e and "Cloudflare" in e for e in errors), errors)

    def test_missing_header_in_htaccess_is_found(self):
        self.edit("plesk/.htaccess", 'Header always set X-Frame-Options "DENY"', "")
        errors = hosting_check.consistency(self.tmp)
        self.assertTrue(any("x-frame-options" in e for e in errors), errors)

    def test_cache_drift_in_plesk_nginx_is_found(self):
        self.edit("plesk/nginx-additional.conf", "max-age=31536000, immutable", "max-age=3600")
        errors = hosting_check.consistency(self.tmp)
        self.assertTrue(any("Plesk nginx" in e for e in errors), errors)

    def test_cache_drift_in_htaccess_probe_is_found(self):
        self.edit("plesk/.htaccess", 'm#^/canvaskit/#">\n        Header always set Cache-Control "public, max-age=31536000, immutable"',
                  'm#^/canvaskit/#">\n        Header always set Cache-Control "no-cache"')
        errors = hosting_check.consistency(self.tmp)
        self.assertTrue(any("/canvaskit/" in e and ".htaccess" in e for e in errors), errors)


if __name__ == "__main__":
    unittest.main()
