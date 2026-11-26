#!/usr/bin/env python3
"""Checks for the web hosting configs in deploy/ (standard library only).

  consistency   Static comparison of the four header sources (nginx snippet,
                Plesk nginx directives, Apache .htaccess, Cloudflare _headers):
                the security headers must be identical, the Cache-Control values
                must come from the same set, and the sample paths below must get
                the same Cache-Control from every source that can be evaluated
                without a server. Exit code 1 on any difference.
  smoke         Black-box test against a running server (nginx container, nginx
                behind Traefik, Apache with the .htaccess): security headers
                (exact values, no duplicates), caching per path, ETag and 304,
                gzip, MIME types, SPA fallback, honest 404 for files, hidden and
                hosting files blocked, optional HTTP to HTTPS redirect.

Usage:
  python3 tool/hosting_check.py consistency [--root .]
  python3 tool/hosting_check.py smoke --web build/web --port 8080 \
      [--headers build/hosting/nginx/snippets/linefm-headers.conf] [--tls --host app.linefm.de] \
      [--redirect-port 8000] [--no-healthz] [--allow-server-version]
"""

from __future__ import annotations

import argparse
import http.client
import re
import ssl
import sys
from pathlib import Path

NO_CACHE = "no-cache"
IMMUTABLE = "public, max-age=31536000, immutable"
SWR = "public, max-age=86400, stale-while-revalidate=604800"
HOUR = "public, max-age=3600"

# Sample path -> expected Cache-Control. One table for the static comparison and the smoke test.
PROBES: list[tuple[str, str]] = [
    ("/", NO_CACHE),
    ("/index.html", NO_CACHE),
    ("/flutter_bootstrap.js", NO_CACHE),
    ("/analytics.js", NO_CACHE),
    ("/cast.js", NO_CACHE),
    ("/sw.js", NO_CACHE),
    ("/manifest.webmanifest", NO_CACHE),
    ("/version.json", NO_CACHE),
    ("/asset-manifest.txt", NO_CACHE),
    ("/main.0123abcd.dart.wasm", IMMUTABLE),
    ("/main.0123abcd.dart.js", IMMUTABLE),
    ("/main.0123abcd.dart.mjs", IMMUTABLE),
    ("/canvaskit/abcdef/skwasm.wasm", IMMUTABLE),
    ("/assets/AssetManifest.bin", NO_CACHE),
    ("/assets/AssetManifest.bin.json", NO_CACHE),
    ("/assets/AssetManifest.json", NO_CACHE),
    ("/assets/FontManifest.json", NO_CACHE),
    ("/assets/NOTICES", NO_CACHE),
    ("/assets/assets/logo.png", SWR),
    ("/assets/fonts/MaterialIcons-Regular.otf", SWR),
    ("/assets/packages/pkg/a.png", SWR),
    ("/assets/shaders/ink.frag", SWR),
    ("/assets/fonts/fallback/notosans/v39/abcd.woff2", IMMUTABLE),
    ("/icons/Icon-192.png", SWR),
    ("/favicon.png", SWR),
    ("/robots.txt", HOUR),
    ("/sitemap.xml", HOUR),
    ("/llms.txt", HOUR),
    ("/impressum/", NO_CACHE),
    ("/impressum/index.html", NO_CACHE),
    ("/datenschutz/", NO_CACHE),
    ("/.well-known/assetlinks.json", HOUR),
    ("/.well-known/apple-app-site-association", HOUR),
]

_NGINX_ADD = re.compile(r'^\s*add_header\s+(\S+)\s+"((?:[^"\\]|\\.)*)"\s+always;', re.M)
_HTACCESS_SET = re.compile(r'^\s*Header always set (\S+) "(.*)"\s*$')


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


# ---------------------------------------------------------------- parsers


def nginx_headers(text: str) -> dict[str, str]:
    return {n.lower(): v for n, v in _NGINX_ADD.findall(text)}


def htaccess_rules(text: str) -> tuple[dict[str, str], list[tuple[str, object, str]]]:
    """Returns (all headers set, cache rules as (kind, condition, value) in file order)."""
    headers: dict[str, str] = {}
    rules: list[tuple[str, object, str]] = []
    ctx: tuple[str, object] | None = None
    for line in text.splitlines():
        s = line.strip()
        m = re.match(r'<FilesMatch "(.*)">$', s)
        if m:
            ctx = ("file", re.compile(m.group(1)))
            continue
        m = re.match(r'<If "(.*)">$', s)
        if m:
            ctx = ("if", [re.compile(p) for p in re.findall(r"m#([^#]*)#", m.group(1))])
            continue
        if s in ("</FilesMatch>", "</If>"):
            ctx = None
            continue
        m = _HTACCESS_SET.match(line)
        if not m:
            continue
        name, value = m.group(1).lower(), m.group(2)
        if name == "cache-control":
            kind, cond = ctx if ctx else ("top", None)
            rules.append((kind, cond, value))
        else:
            headers[name] = value
    return headers, rules


def htaccess_cache(rules, path: str) -> str | None:
    # Apache merges <FilesMatch> after the directory level and <If> last, each in file order.
    result = None
    base = path.rsplit("/", 1)[-1]
    for order in ("top", "file", "if"):
        for kind, cond, value in rules:
            if kind != order:
                continue
            if kind == "top" or (kind == "file" and cond.search(base)) or (
                kind == "if" and any(p.search(path) for p in cond)
            ):
                result = value
    return result


def plesk_cache(text: str, path: str) -> str | None:
    result = None
    m = re.search(r'set \$linefm_cache "([^"]*)";', text)
    if m:
        result = m.group(1)
    for cond, value in re.findall(
        r'if \(\$uri ~ "([^"]*)"\) \{\s*set \$linefm_cache "([^"]*)";', text
    ):
        if re.search(cond, path):
            result = value
    return result


def cloudflare_headers(text: str) -> tuple[dict[str, str], list[tuple[str, str]]]:
    """Returns (headers of the /* block, [(pattern, cache-control)] of the path rules)."""
    blocks: dict[str, list[str]] = {}
    current = None
    for line in text.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if not line[0].isspace():
            current = line.strip()
            blocks.setdefault(current, [])
        elif current is not None:
            blocks[current].append(line.strip())
    star: dict[str, str] = {}
    for entry in blocks.get("/*", []):
        if entry.startswith("!"):
            continue
        name, _, value = entry.partition(":")
        star[name.strip().lower()] = value.strip()
    caches: list[tuple[str, str]] = []
    for pattern, entries in blocks.items():
        for entry in entries:
            name, _, value = entry.partition(":")
            if name.strip().lower() == "cache-control":
                caches.append((pattern, value.strip()))
    return star, caches


def cloudflare_cache(caches, path: str) -> list[str]:
    out = []
    for pattern, value in caches:
        regex = "^" + re.escape(pattern).replace(r"\*", ".*") + "$"
        if re.match(regex, path):
            out.append(value)
    return out


# ------------------------------------------------------------ consistency


def consistency(root: Path) -> list[str]:
    errors: list[str] = []
    dep = root / "deploy"
    nginx_snippet = nginx_headers(read(dep / "nginx/snippets/linefm-headers.conf"))
    locations = read(dep / "nginx/snippets/linefm-locations.conf")
    plesk_text = read(dep / "plesk/nginx-additional.conf")
    plesk = nginx_headers(plesk_text)
    htaccess_text = read(dep / "plesk/.htaccess")
    htaccess, ht_rules = htaccess_rules(htaccess_text)
    cf_star, cf_caches = cloudflare_headers(read(dep / "cloudflare/_headers"))

    sources = {
        "nginx snippet": nginx_snippet,
        "Plesk nginx": {k: v for k, v in plesk.items() if k != "cache-control"},
        ".htaccess": htaccess,
        "Cloudflare _headers": cf_star,
    }
    reference = nginx_snippet
    if not reference:
        errors.append("nginx snippet: no add_header found")
    for label, headers in sources.items():
        if label == "nginx snippet":
            continue
        for name in sorted(set(reference) | set(headers)):
            if reference.get(name) != headers.get(name):
                errors.append(
                    f"security header '{name}' differs in {label}:\n"
                    f"    nginx snippet: {reference.get(name)}\n    {label}: {headers.get(name)}"
                )
    csp = reference.get("content-security-policy", "")
    for needle in ("default-src 'self'", "frame-ancestors 'none'", "object-src 'none'"):
        if needle not in csp:
            errors.append(f"CSP lacks '{needle}'")

    # Same set of Cache-Control values everywhere.
    value_sets = {
        "nginx locations": set(re.findall(r'add_header Cache-Control "([^"]*)" always;', locations)),
        "Plesk nginx": set(re.findall(r'set \$linefm_cache "([^"]*)";', plesk_text)),
        ".htaccess": {v for _, _, v in ht_rules},
        "Cloudflare _headers": {v for _, v in cf_caches},
    }
    ref_set = value_sets["nginx locations"]
    for label, values in value_sets.items():
        if values != ref_set:
            errors.append(
                f"Cache-Control values in {label} differ from nginx locations: "
                f"only there {sorted(values - ref_set)}, missing {sorted(ref_set - values)}"
            )

    # Probe paths: every source that can be evaluated statically must agree with the table.
    for path, expected in PROBES:
        got = {
            "Plesk nginx": plesk_cache(plesk_text, path),
            ".htaccess": htaccess_cache(ht_rules, path),
        }
        cf = cloudflare_cache(cf_caches, path)
        if len(cf) != 1:
            errors.append(f"Cloudflare _headers: {path} matches {len(cf)} Cache-Control rules (expected 1): {cf}")
        else:
            got["Cloudflare _headers"] = cf[0]
        for label, value in got.items():
            if value != expected:
                errors.append(f"Cache-Control for {path} in {label}: '{value}', expected '{expected}'")
    return errors


# ------------------------------------------------------------------ smoke


class Client:
    def __init__(self, host: str, port: int, tls: bool, vhost: str):
        self.host, self.port, self.tls, self.vhost = host, port, tls, vhost

    def get(self, path: str, headers: dict[str, str] | None = None, method: str = "GET"):
        hdrs = {"Host": self.vhost, "Accept-Encoding": "identity", **(headers or {})}
        if self.tls:
            ctx = ssl._create_unverified_context()  # self-signed test certificate
            conn = http.client.HTTPSConnection(self.host, self.port, timeout=20, context=ctx)
        else:
            conn = http.client.HTTPConnection(self.host, self.port, timeout=20)
        try:
            conn.request(method, path, headers=hdrs)
            resp = conn.getresponse()
            body = resp.read()
            return resp.status, resp.getheaders(), body
        finally:
            conn.close()


def hget(headers, name: str) -> str | None:
    vals = [v for k, v in headers if k.lower() == name.lower()]
    return vals[0] if vals else None


def hcount(headers, name: str) -> int:
    return len([1 for k, _ in headers if k.lower() == name.lower()])


def smoke(args) -> list[str]:
    errors: list[str] = []
    web = Path(args.web)
    client = Client("127.0.0.1", args.port, args.tls, args.host)

    def check(cond: bool, msg: str) -> None:
        if not cond:
            errors.append(msg)

    expected_sec = nginx_headers(read(Path(args.headers)))
    check(bool(expected_sec), f"no expected headers in {args.headers}")

    def newest(pattern: str) -> str:
        found = sorted(p.relative_to(web).as_posix() for p in web.glob(pattern))
        check(bool(found), f"no file {pattern} in {web}")
        return "/" + found[0] if found else "/missing"

    wasm = newest("main.*.dart.wasm")
    mjs = newest("main.*.dart.mjs")
    djs = newest("main.*.dart.js")
    canvas = newest("canvaskit/*/skwasm.wasm")
    fallback_font = newest("assets/fonts/fallback/**/*.woff2")

    # 1. Security headers on every kind of response, exact and exactly once.
    for path in ("/", wasm, "/radio/favoriten", "/gibtsnicht.js", "/robots.txt"):
        status, hdrs, _ = client.get(path)
        for name, value in expected_sec.items():
            check(hget(hdrs, name) == value, f"{path} ({status}): header {name} wrong or missing: {hget(hdrs, name)}")
            check(hcount(hdrs, name) == 1, f"{path}: header {name} appears {hcount(hdrs, name)} times")
        check(hget(hdrs, "Access-Control-Allow-Origin") is None, f"{path}: unexpected Access-Control-Allow-Origin")
        if not args.allow_server_version:
            check(not re.search(r"\d", hget(hdrs, "Server") or ""),
                  f"{path}: Server header leaks a version: {hget(hdrs, 'Server')}")

    # 2. Caching per path, taken from the files that exist in the build.
    concrete = {
        "/main.0123abcd.dart.wasm": wasm,
        "/main.0123abcd.dart.js": djs,
        "/main.0123abcd.dart.mjs": mjs,
        "/canvaskit/abcdef/skwasm.wasm": canvas,
        "/assets/fonts/fallback/notosans/v39/abcd.woff2": fallback_font,
    }
    for sample, expected in PROBES:
        path = concrete.get(sample, sample)
        if not path.endswith("/") and path not in concrete.values() and not (web / path.lstrip("/")).exists():
            continue  # optional files (for example app links) are only checked when built
        if path.endswith("/") and path != "/" and not (web / path.strip("/")).is_dir():
            continue
        status, hdrs, _ = client.get(path)
        check(status == 200, f"{path}: status {status}, expected 200")
        check(hget(hdrs, "Cache-Control") == expected, f"{path}: Cache-Control '{hget(hdrs, 'Cache-Control')}', expected '{expected}'")
        check(hget(hdrs, "ETag") is not None, f"{path}: no ETag")

    # 3. ETag and conditional request.
    for path in ("/", wasm, "/assets/FontManifest.json"):
        _, hdrs, _ = client.get(path)
        etag = hget(hdrs, "ETag")
        if etag:
            status, h2, body = client.get(path, {"If-None-Match": etag})
            check(status == 304, f"{path}: If-None-Match gave {status}, expected 304")
            check(not body, f"{path}: 304 with a body")
            check(hget(h2, "Cache-Control") is not None, f"{path}: 304 without Cache-Control")

    # 4. Compression and MIME types.
    status, hdrs, _ = client.get(wasm, {"Accept-Encoding": "gzip"})
    check(hget(hdrs, "Content-Encoding") == "gzip", f"{wasm}: no gzip (Content-Encoding {hget(hdrs, 'Content-Encoding')})")
    check("Accept-Encoding" in (hget(hdrs, "Vary") or ""), f"{wasm}: no Vary: Accept-Encoding")
    for path, ctype in ((wasm, "application/wasm"), (mjs, "text/javascript"), (djs, ("application/javascript", "text/javascript")),
                        ("/manifest.webmanifest", "application/manifest+json"), ("/", "text/html")):
        if not (web / path.lstrip("/")).exists() and path != "/":
            continue
        _, hdrs, _ = client.get(path)
        check((hget(hdrs, "Content-Type") or "").startswith(ctype), f"{path}: Content-Type '{hget(hdrs, 'Content-Type')}', expected {ctype}")  # ctype may be a tuple
    if (web / "assets/NOTICES").exists():
        _, hdrs, _ = client.get("/assets/NOTICES", {"Accept-Encoding": "gzip"})
        check(hget(hdrs, "Content-Encoding") == "gzip", "assets/NOTICES is not compressed")
    for path in ("/.well-known/assetlinks.json", "/.well-known/apple-app-site-association"):
        if (web / path.lstrip("/")).exists():
            _, hdrs, _ = client.get(path)
            check((hget(hdrs, "Content-Type") or "").startswith("application/json"), f"{path}: Content-Type {hget(hdrs, 'Content-Type')}")

    # 5. SPA fallback and honest 404s.
    _, _, index_body = client.get("/")
    for path in ("/radio/favoriten", "/einstellungen/sprache", "/some/deep/link"):
        status, hdrs, body = client.get(path)
        check(status == 200, f"{path}: status {status}, expected 200 (SPA fallback)")
        check(body == index_body, f"{path}: body is not index.html")
        check(hget(hdrs, "Cache-Control") == NO_CACHE, f"{path}: Cache-Control {hget(hdrs, 'Cache-Control')}")
    for path in ("/gibtsnicht.js", "/assets/gibtsnicht.png", "/main.00000000.dart.wasm"):
        status, _, _ = client.get(path)
        check(status == 404, f"{path}: status {status}, expected 404")
    if (web / "impressum").is_dir():
        for path in ("/impressum/", "/impressum/index.html", "/datenschutz/"):
            status, _, _ = client.get(path)
            check(status == 200, f"{path}: status {status}, expected 200")
        status, _, _ = client.get("/impressum/gibtsnicht")
        check(status == 404, f"/impressum/gibtsnicht: status {status}, expected 404 (no SPA fallback for legal pages)")

    # 6. Hosting and hidden files are never served (nginx answers 404, Apache denies with 403).
    for path in ("/_headers", "/_redirects", "/.htaccess", "/.git/config", "/.env"):
        status, _, body = client.get(path)
        check(status in (403, 404), f"{path}: status {status}, expected 403 or 404")
        check(b"Content-Security-Policy" not in body and b"RewriteEngine" not in body, f"{path}: content leaked")

    # 7. Health check (container variants only).
    if not args.no_healthz:
        status, _, body = client.get("/healthz")
        check(status == 200 and body.strip() == b"ok", f"/healthz: {status} {body[:20]!r}")

    # 8. HTTP to HTTPS (behind Traefik).
    if args.redirect_port:
        plain = Client("127.0.0.1", args.redirect_port, False, args.host)
        status, hdrs, _ = plain.get("/radio/favoriten")
        check(status in (301, 308), f"HTTP redirect: status {status}, expected 301/308")
        check((hget(hdrs, "Location") or "").startswith(f"https://{args.host}/radio/favoriten"),
              f"HTTP redirect: Location {hget(hdrs, 'Location')}")
    return errors


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("consistency")
    c.add_argument("--root", default=".")
    s = sub.add_parser("smoke")
    s.add_argument("--web", default="build/web")
    s.add_argument("--port", type=int, required=True)
    s.add_argument("--headers", default="build/hosting/nginx/snippets/linefm-headers.conf")
    s.add_argument("--tls", action="store_true")
    s.add_argument("--host", default="app.linefm.de")
    s.add_argument("--redirect-port", type=int, default=0)
    s.add_argument("--no-healthz", action="store_true")
    s.add_argument("--allow-server-version", action="store_true",
                   help="Apache sets the Server header at server level, not in .htaccess")
    args = ap.parse_args(argv)

    errors = consistency(Path(args.root)) if args.cmd == "consistency" else smoke(args)
    if errors:
        print(f"hosting_check {args.cmd}: {len(errors)} problem(s)", file=sys.stderr)
        for e in errors:
            print(f"::error::{e}" if args.cmd == "smoke" else f"- {e}", file=sys.stderr)
        return 1
    print(f"hosting_check {args.cmd}: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
