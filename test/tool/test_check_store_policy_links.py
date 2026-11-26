"""Unit tests for tool/check_store_policy_links.py (standard library only, no network).

Run from the repository root:
  python -m unittest discover -s test/tool -p "test_*.py"
"""

from __future__ import annotations

import importlib.util
import io
import urllib.error
import unittest
from email.message import Message
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("policy_links", ROOT / "tool/check_store_policy_links.py")
assert _spec is not None and _spec.loader is not None
pl = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(pl)


class _Response(io.BytesIO):
    def __init__(self, body: bytes) -> None:
        super().__init__(body)
        self.headers = Message()
        self.headers["Content-Type"] = "text/html; charset=utf-8"

    def __enter__(self):
        return self

    def __exit__(self, *_exc) -> None:
        self.close()


def _http_error(code: int, retry_after: str | None = None) -> urllib.error.HTTPError:
    headers = Message()
    if retry_after:
        headers["Retry-After"] = retry_after
    return urllib.error.HTTPError("https://x.test/", code, "err", headers, None)


class ExtractTest(unittest.TestCase):
    def test_links_are_unique_and_trimmed(self) -> None:
        text = "See <https://a.test/x>, [b](https://b.test/y). Again https://a.test/x."
        self.assertEqual(pl.extract_urls(text), ["https://a.test/x", "https://b.test/y"])

    def test_document_has_links_and_all_are_in_baseline(self) -> None:
        urls = pl.extract_urls(pl.DOC.read_text(encoding="utf-8"))
        self.assertGreater(len(urls), 30)
        import json
        baseline = json.loads(pl.BASELINE.read_text(encoding="utf-8"))
        self.assertEqual(sorted(set(urls) - set(baseline)), [])


class NormalizeTest(unittest.TestCase):
    def test_scripts_tags_and_tokens_removed(self) -> None:
        page = "<html><script>var t=1</script><style>p{}</style><p>Policy&nbsp;text</p>" \
               "<span>build 0123456789abcdef0123</span></html>"
        self.assertEqual(pl.normalize(page), "Policy text build")

    def test_whitespace_does_not_change_hash(self) -> None:
        self.assertEqual(pl.digest(pl.normalize("<p>a  b</p>")), pl.digest(pl.normalize("<p>a\n b</p>")))


class FetchTest(unittest.TestCase):
    def test_ok(self) -> None:
        state, body = pl.fetch("https://x.test/", opener=lambda _r, **_k: _Response(b"<p>hi</p>"), sleep=lambda s: None)
        self.assertEqual((state, body), ("ok", "<p>hi</p>"))

    def test_not_found_is_broken_without_retry(self) -> None:
        calls = []

        def opener(_request, **_kwargs):
            calls.append(1)
            raise _http_error(404)

        self.assertEqual(pl.fetch("https://x.test/", opener=opener, sleep=lambda s: None), ("broken", "HTTP 404"))
        self.assertEqual(len(calls), 1)

    def test_rate_limit_retries_then_recovers(self) -> None:
        answers = [_http_error(429, "7"), _http_error(503)]
        waits = []

        def opener(_request, **_kwargs):
            if answers:
                raise answers.pop(0)
            return _Response(b"ok")

        self.assertEqual(pl.fetch("https://x.test/", opener=opener, sleep=waits.append)[0], "ok")
        self.assertEqual(waits, [7, 20])

    def test_persistent_rate_limit_is_transient(self) -> None:
        def opener(_request, **_kwargs):
            raise _http_error(429)

        state, reason = pl.fetch("https://x.test/", opener=opener, sleep=lambda s: None)
        self.assertEqual((state, reason), ("transient", "HTTP 429"))

    def test_network_error_is_transient(self) -> None:
        def opener(_request, **_kwargs):
            raise urllib.error.URLError("timed out")

        self.assertEqual(pl.fetch("https://x.test/", opener=opener, sleep=lambda s: None)[0], "transient")


class CompareTest(unittest.TestCase):
    def test_groups_and_attention(self) -> None:
        results = {
            "https://a": ("ok", "h1"),
            "https://b": ("ok", "h2"),
            "https://c": ("ok", "h3"),
            "https://d": ("broken", "HTTP 404"),
            "https://e": ("transient", "HTTP 429"),
        }
        groups = pl.compare(results, {"https://a": "h1", "https://b": "old"})
        self.assertEqual(groups["ok"], ["https://a"])
        self.assertEqual(groups["changed"], ["https://b"])
        self.assertEqual(groups["new"], ["https://c"])
        self.assertEqual(groups["broken"], ["https://d (HTTP 404)"])
        self.assertTrue(pl.needs_attention(groups))
        self.assertIn("Text changed", pl.report(groups))

    def test_transient_alone_needs_no_attention(self) -> None:
        groups = pl.compare({"https://a": ("transient", "HTTP 503")}, {"https://a": "h"})
        self.assertFalse(pl.needs_attention(groups))


if __name__ == "__main__":
    unittest.main()
