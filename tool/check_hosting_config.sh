#!/usr/bin/env bash
# Syntax checks for the hosting configs in deploy/ with pinned images. Needs docker and openssl,
# no accounts and no network apart from pulling the two images.
#   - docker compose config for both compose files and the telemetry stack (with and without
#     the Traefik override, using .env.example); the override must expose only ingest routes
#   - nginx -t: native site config, container config, Plesk directives (wrapped in a server block)
#   - httpd -t: deploy/plesk/.htaccess inside a Directory block
# Placeholders such as __CSP_CONNECT_EXTRA__ stay as they are; they are plain text for the parsers.
set -euo pipefail

NGINX_IMAGE='nginxinc/nginx-unprivileged:1.31-alpine@sha256:b5047b9b76845eac124358373c6852377c52e4b05834a47647e955dd91cb8f1e'
HTTPD_IMAGE='httpd:2.4.66-alpine@sha256:968c8b4098fcecb473762b45f6c541a3b2b2cfab2caccb1edbd2cece071ef160'

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
