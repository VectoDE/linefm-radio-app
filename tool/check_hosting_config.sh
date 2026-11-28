#!/usr/bin/env bash
# Syntax checks for the hosting configs in deploy/ with pinned images. Needs docker and openssl,
# no accounts and no network apart from pulling the two images.
#   - docker compose config for both compose files and the telemetry stack (with and without
#     the Traefik override, using .env.example); the override must expose only ingest routes
#   - nginx -t: native site config, container config, Plesk directives (wrapped in a server block)
#   - httpd -t: deploy/plesk/.htaccess inside a Directory block
# Placeholders such as __CSP_CONNECT_EXTRA__ stay as they are; they are plain text for the parsers.
#
# `check_hosting_config.sh --static` runs only the header consistency check (python3 3.11+, no
# docker, no network; also checks build/hosting and build/web for unrendered CSP placeholders when
# they exist): the security header set, the Cache-Control table must
# agree across Cloudflare _headers, netlify.toml, vercel.json, nginx, Plesk nginx and Plesk .htaccess.
set -euo pipefail

NGINX_IMAGE='nginxinc/nginx-unprivileged:1.31-alpine@sha256:b5047b9b76845eac124358373c6852377c52e4b05834a47647e955dd91cb8f1e'
HTTPD_IMAGE='httpd:2.4.66-alpine@sha256:968c8b4098fcecb473762b45f6c541a3b2b2cfab2caccb1edbd2cece071ef160'

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

check_header_consistency() {
  python3 -I - "$root" <<'PY'
import json, re, sys, tomllib
from pathlib import Path

root = Path(sys.argv[1])
SECURITY = ['Content-Security-Policy', 'Strict-Transport-Security', 'X-Content-Type-Options',
            'Referrer-Policy', 'Permissions-Policy', 'Cross-Origin-Opener-Policy',
            'Cross-Origin-Resource-Policy', 'X-Frame-Options']
errors = []


def fail(msg):
    errors.append(msg)
    print(f'::error::{msg}')


def read(rel):
    return (root / rel).read_text(encoding='utf-8')


def norm_path(p):
    """Same path, different wildcard dialects: Cloudflare/Netlify `*`, Vercel `(.*)`."""
    return p[:-4] + '*' if p.endswith('(.*)') else p


# Cloudflare Pages _headers: path line, indented headers, `! Name` detaches a default header.
cf, cf_detached, cur = {}, {}, None
for raw in read('deploy/cloudflare/_headers').splitlines():
    if not raw.strip() or raw.lstrip().startswith('#'):
        continue
    if not raw.startswith((' ', '\t')):
        cur = raw.strip()
        cf.setdefault(cur, {})
        cf_detached.setdefault(cur, set())
    elif raw.strip().startswith('!'):
        cf_detached[cur].add(raw.strip()[1:].strip().lower())
    else:
        k, v = raw.strip().split(':', 1)
        cf[cur][k.strip()] = v.strip()

nl = {}
for block in tomllib.loads(read('netlify.toml')).get('headers', []):
    nl.setdefault(block['for'], {}).update(block['values'])

vc = {}
for block in json.loads(read('vercel.json')).get('headers', []):
    vc.setdefault(norm_path(block['source']), {}).update({h['key']: h['value'] for h in block['headers']})

add_header = re.compile(r'^\s*add_header\s+(\S+)\s+"(.*)"\s+always;', re.M)
set_header = re.compile(r'^\s*Header always set\s+(\S+)\s+"(.*)"\s*$', re.M)
nginx = dict(add_header.findall(read('deploy/nginx/snippets/linefm-headers.conf')))
plesk_nginx = dict(add_header.findall(read('deploy/plesk/nginx-additional.conf')))
htaccess = dict(set_header.findall(read('deploy/plesk/.htaccess')))

sets = {
    'deploy/cloudflare/_headers': cf.get('/*', {}),
    'netlify.toml': nl.get('/*', {}),
    'vercel.json': vc.get('/*', {}),
    'deploy/nginx/snippets/linefm-headers.conf': nginx,
    'deploy/plesk/nginx-additional.conf': plesk_nginx,
    'deploy/plesk/.htaccess': htaccess,
}
for name in SECURITY:
    ref = sets['deploy/cloudflare/_headers'].get(name)
    if ref is None:
        fail(f'deploy/cloudflare/_headers has no {name}')
        continue
    for target, headers in sets.items():
        if headers.get(name) != ref:
            fail(f'{name} in {target} differs from deploy/cloudflare/_headers')


# Cache-Control and Content-Type per path: Cloudflare, Netlify and Vercel carry the same table.
def table(rules):
    keep = ('Cache-Control', 'Content-Type')
    return {p: {k: v for k, v in h.items() if k in keep}
            for p, h in rules.items() if p != '/*' and any(k in h for k in keep)}


ref_table = table(cf)
for target, rules in (('netlify.toml', nl), ('vercel.json', vc)):
    other = table(rules)
    for p in sorted(set(ref_table) | set(other)):
        if ref_table.get(p) != other.get(p):
            fail(f'{target}: rule for {p} is {other.get(p)} but deploy/cloudflare/_headers has {ref_table.get(p)}')

# Every Cache-Control value nginx and Apache send must exist in the Cloudflare table.
allowed = {h['Cache-Control'] for h in ref_table.values() if 'Cache-Control' in h}
for rel, pattern in (('deploy/nginx/snippets/linefm-locations.conf', r'add_header Cache-Control "([^"]+)"'),
                     ('deploy/plesk/.htaccess', r'Header always set Cache-Control "([^"]+)"')):
    for value in set(re.findall(pattern, read(rel))):
        if value not in allowed:
            fail(f'{rel}: Cache-Control "{value}" is not in deploy/cloudflare/_headers')

# Rendered output (tool/web_postbuild.dart writes build/hosting, build/web): no placeholder may
# survive there. Skipped when the directories do not exist (the repo files keep placeholders).
placeholder = re.compile(r'__CSP_[A-Z_]+__')
checked = 0
for rel in ('build/hosting', 'build/web'):
    base = root / rel
    if not base.is_dir():
        continue
    for f in base.rglob('*'):
        rendered = f.name in ('_headers', '.htaccess', 'netlify.toml', 'vercel.json') or (
            f.suffix == '.conf' and rel == 'build/hosting')
        if f.is_file() and rendered:
            checked += 1
            if placeholder.search(f.read_text(encoding='utf-8', errors='replace')):
                fail(f'{f.relative_to(root).as_posix()}: unrendered CSP placeholder')
if checked and not errors:
    print(f'Rendered output: {checked} files without CSP placeholders.')

if errors:
    sys.exit(1)
print(f'Header sets agree across {len(sets)} targets; Cache-Control table matches '
      f'({len(ref_table)} rules).')
PY
}

if [ "${1:-}" = '--static' ]; then
  echo "== static header consistency"
  check_header_consistency
  exit 0
fi
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
chmod 755 "$work"

for f in deploy/traefik/docker-compose.yml deploy/nginx/docker-compose.yml; do
  echo "== docker compose config: $f"
  (cd "$root/$(dirname "$f")" && docker compose -f "$(basename "$f")" config --quiet)
done

echo "== docker compose config: deploy/telemetry (plain and with Traefik override)"
# .env.example leaves the secrets empty on purpose; compose refuses empty required values,
# so the check fills every empty entry with a throwaway value in a temporary copy.
sed -E 's/^([A-Z0-9_]+)=$/\1=ci-placeholder/' "$root/deploy/telemetry/.env.example" > "$work/telemetry.env"
(
  cd "$root/deploy/telemetry"
  docker compose --env-file "$work/telemetry.env" -f compose.yml config --quiet
  merged="$(docker compose --env-file "$work/telemetry.env" -f compose.yml -f compose.traefik.yml config)"
  for needle in \
    'traefik.http.routers.umami-ingest.rule: Host(`statistik.example.org`) && Path(`/api/send`)' \
    'traefik.http.routers.umami.middlewares: umami-admin-only' \
    'traefik.http.routers.glitchtip.middlewares: glitchtip-admin-only' \
    'ipallowlist.sourcerange: 203.0.113.10/32'; do
    if ! grep -qF -- "$needle" <<<"$merged"; then
      echo "::error::Telemetry Traefik override is missing: $needle"
      exit 1
    fi
  done
  if grep -qE '^\s+- (mode: ingress|published:)' <<<"$merged"; then
    echo "::error::Telemetry Traefik override still publishes host ports"
    exit 1
  fi
)

echo "== Traefik dynamic files parse as YAML"
for f in deploy/traefik/*.dynamic.yml; do
  python3 -I -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1], encoding="utf-8"))' "$root/$f"
done

# Throwaway certificate for the paths the site config names.
mkdir -p "$work/certs"
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj "/CN=app.linefm.de" \
  -keyout "$work/certs/privkey.pem" -out "$work/certs/fullchain.pem" 2>/dev/null
chmod 644 "$work/certs/"*.pem

cat > "$work/native.conf" <<'CONF'
pid /tmp/nginx.pid;
events {}
http {
    include /etc/nginx/mime.types;
    include /work/sites/linefm-app.conf;
}
CONF
mkdir -p "$work/sites"
cp "$root/deploy/nginx/linefm-app.conf" "$work/sites/"

cat > "$work/plesk.conf" <<'CONF'
pid /tmp/nginx.pid;
events {}
http {
    include /etc/nginx/mime.types;
    server {
        listen 8081;
        root /tmp;
        include /work/plesk-additional.conf;
    }
}
CONF
cp "$root/deploy/plesk/nginx-additional.conf" "$work/plesk-additional.conf"
cp "$root/deploy/traefik/nginx.conf" "$work/container.conf"
cp -r "$root/deploy/nginx/snippets" "$work/snippets"
docker run --rm --entrypoint cat "$NGINX_IMAGE" /etc/nginx/mime.types > "$work/mime.types"

run_nginx() { # $1 = main config
  docker run --rm --user 0 \
    -v "$root/deploy/nginx/snippets:/etc/nginx/snippets:ro" \
    -v "$root/deploy/traefik/nginx.conf:/work/container.conf:ro" \
    -v "$work:/work:ro" \
    -v "$work/certs:/etc/letsencrypt/live/app.linefm.de:ro" \
    --entrypoint nginx "$NGINX_IMAGE" -t -c "$1"
}
echo "== nginx -t: deploy/nginx/linefm-app.conf (+ snippets)"
run_nginx /work/native.conf
echo "== nginx -t: deploy/traefik/nginx.conf (+ snippets)"
run_nginx /work/container.conf
echo "== nginx -t: deploy/plesk/nginx-additional.conf"
run_nginx /work/plesk.conf

# Apache reads .htaccess only per request, so the file is included in a Directory block;
# that applies the same directive parser and the same context rules.
cat > "$work/httpd.conf" <<'CONF'
ServerRoot "/usr/local/apache2"
Listen 8082
ServerName localhost
LoadModule mpm_event_module modules/mod_mpm_event.so
LoadModule unixd_module modules/mod_unixd.so
LoadModule filter_module modules/mod_filter.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule mime_module modules/mod_mime.so
LoadModule dir_module modules/mod_dir.so
LoadModule headers_module modules/mod_headers.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule deflate_module modules/mod_deflate.so
LoadModule log_config_module modules/mod_log_config.so
DocumentRoot "/usr/local/apache2/htdocs"
ErrorLog /dev/stderr
<Directory "/usr/local/apache2/htdocs">
    AllowOverride All
    Include /work/plesk.htaccess
</Directory>
CONF
cp "$root/deploy/plesk/.htaccess" "$work/plesk.htaccess"
echo "== httpd -t: deploy/plesk/.htaccess"
docker run --rm -v "$work:/work:ro" "$HTTPD_IMAGE" httpd -t -f /work/httpd.conf
echo "Hosting configs: syntax OK"
