#!/usr/bin/env python3
"""Watch the official store policy pages linked in docs/STORE-POLICIES.md.

For every https link in the document the script downloads the page, reduces
it to its visible text (scripts, styles and tags removed, whitespace
collapsed) and hashes that text with SHA-256. The hashes are compared with
tool/store_policy_baseline.json.

Result per page:
  ok         reachable, text unchanged
  changed    reachable, text differs from the baseline
  new        reachable, no baseline entry yet
  broken     permanent failure (HTTP 4xx except 408/429, or 3xx loop)
  transient  rate limit, server error or timeout after all retries

Changed, new and broken pages are written to the report (Markdown) and set
"attention=true" in $GITHUB_OUTPUT so the workflow can open a ticket.
Transient pages are only listed in the report: a rate limit is not a policy
change, and flagging it would make the monthly run noisy.

Usage:
  python3 tool/check_store_policy_links.py [--report FILE] [--update-baseline]

Standard library only. Exit code 0 unless the input is unusable.
"""
from __future__ import annotations

import argparse
import hashlib
import html
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "STORE-POLICIES.md"
BASELINE = ROOT / "tool" / "store_policy_baseline.json"

USER_AGENT = "Mozilla/5.0 (compatible; store-policy-watch; +https://github.com/VectoDE/linefm-radio-app)"
TIMEOUT = 30
RETRY_DELAYS = (5, 20, 60)
MAX_RETRY_AFTER = 120
TRANSIENT_CODES = {408, 425, 429, 500, 502, 503, 504}

URL_RE = re.compile(r"https://[^\s)<>\]\"'`]+")
DROP_BLOCKS = re.compile(r"(?is)<(script|style|noscript|svg|template)\b.*?</\1\s*>")
COMMENTS = re.compile(r"(?s)<!--.*?-->")
TAGS = re.compile(r"<[^>]+>")
# Long hex or digit runs are build ids, cache busters or session tokens.
VOLATILE = re.compile(r"\b(?:[0-9a-f]{16,}|\d{9,})\b", re.IGNORECASE)
SPACE = re.compile(r"\s+")


def extract_urls(markdown: str) -> list[str]:
    """Return the unique https links of the document, sorted."""
    urls = set()
    for match in URL_RE.findall(markdown):
        urls.add(match.rstrip(".,;:"))
    return sorted(urls)


def normalize(page: str) -> str:
    """Reduce an HTML page to stable visible text."""
    text = DROP_BLOCKS.sub(" ", page)
    text = COMMENTS.sub(" ", text)
    text = TAGS.sub(" ", text)
    text = html.unescape(text)
    text = VOLATILE.sub(" ", text)
    return SPACE.sub(" ", text).strip()


def digest(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def fetch(url: str, opener=urllib.request.urlopen, sleep=time.sleep) -> tuple[str, str]:
    """Download a page. Returns (state, text or reason)."""
    last = ""
    for attempt in range(len(RETRY_DELAYS) + 1):
        wait = RETRY_DELAYS[attempt] if attempt < len(RETRY_DELAYS) else 0
        try:
            request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept-Language": "en"})
            with opener(request, timeout=TIMEOUT) as response:
                body = response.read()
                charset = response.headers.get_content_charset() or "utf-8"
                return "ok", body.decode(charset, errors="replace")
        except urllib.error.HTTPError as error:
            if error.code not in TRANSIENT_CODES:
                return "broken", f"HTTP {error.code}"
            last = f"HTTP {error.code}"
            retry_after = error.headers.get("Retry-After") if error.headers else None
            if retry_after and retry_after.isdigit():
                wait = max(wait, min(int(retry_after), MAX_RETRY_AFTER))
        except (urllib.error.URLError, TimeoutError, ConnectionError, OSError) as error:
            last = type(error).__name__ + ": " + str(getattr(error, "reason", error))
        if attempt < len(RETRY_DELAYS):
            sleep(wait)
    return "transient", last


def compare(results: dict[str, tuple[str, str]], baseline: dict[str, str]) -> dict[str, list[str]]:
    """Sort URLs into ok, changed, new, broken and transient."""
    groups: dict[str, list[str]] = {k: [] for k in ("ok", "changed", "new", "broken", "transient")}
    for url, (state, value) in sorted(results.items()):
        if state == "ok":
            old = baseline.get(url)
            if old is None:
                groups["new"].append(url)
            elif old != value:
                groups["changed"].append(url)
            else:
                groups["ok"].append(url)
        else:
            groups[state].append(f"{url} ({value})")
    return groups


def report(groups: dict[str, list[str]]) -> str:
    titles = {
        "changed": "Text changed since the baseline",
        "new": "No baseline entry yet",
        "broken": "Not reachable (permanent error)",
        "transient": "Not checked this time (rate limit, server error or timeout)",
    }
    lines = ["## Store policy pages", ""]
    lines.append(f"Unchanged: {len(groups['ok'])}")
    for key, title in titles.items():
        if groups[key]:
            lines += ["", f"### {title}", ""] + [f"- {item}" for item in groups[key]]
    return "\n".join(lines) + "\n"


def needs_attention(groups: dict[str, list[str]]) -> bool:
    return bool(groups["changed"] or groups["new"] or groups["broken"])


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Watch the official store policy pages.")
    parser.add_argument("--report", type=Path, help="write the Markdown report to this file")
    parser.add_argument("--update-baseline", action="store_true", help="store the current hashes")
    args = parser.parse_args(argv)

    urls = extract_urls(DOC.read_text(encoding="utf-8"))
    if not urls:
        print(f"No links found in {DOC}", file=sys.stderr)
        return 2
    baseline = json.loads(BASELINE.read_text(encoding="utf-8")) if BASELINE.exists() else {}

    results: dict[str, tuple[str, str]] = {}
    for url in urls:
        state, value = fetch(url)
        results[url] = (state, digest(normalize(value)) if state == "ok" else value)
        print(f"{state:9} {url}")

    groups = compare(results, baseline)
    text = report(groups)
    print(text)
    if args.report:
        args.report.write_text(text, encoding="utf-8")
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a", encoding="utf-8") as handle:
            handle.write(f"attention={'true' if needs_attention(groups) else 'false'}\n")

    if args.update_baseline:
        fresh = {u: v for u, (s, v) in results.items() if s == "ok"}
        # Keep the old hash for pages that could not be checked this time.
        fresh.update({u: baseline[u] for u, (s, _) in results.items() if s == "transient" and u in baseline})
        BASELINE.write_text(json.dumps(dict(sorted(fresh.items())), indent=2) + "\n", encoding="utf-8", newline="\n")
        print(f"Baseline written: {len(fresh)} pages")
    return 0


if __name__ == "__main__":
    sys.exit(main())
