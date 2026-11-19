# Web-Container fuer app.linefm.de. Build-Kontext: Repository-Wurzel, nach
#   flutter build web ... && dart run tool/web_postbuild.dart build/web
# docker build -f deploy/traefik/Dockerfile -t linefm-app-web .
# Basisimage per Digest gepinnt (nginx 1.30 stable, alpine). Aktualisierung: docs/hosting-traefik.md
FROM nginxinc/nginx-unprivileged:1.31-alpine@sha256:b5047b9b76845eac124358373c6852377c52e4b05834a47647e955dd91cb8f1e

COPY build/hosting/nginx/snippets/ /etc/nginx/snippets/
COPY build/hosting/traefik/nginx.conf /etc/nginx/nginx.conf
COPY build/web/ /usr/share/nginx/html/

# Hosting-Dateien der anderen Ziele gehoeren nicht ins Image.
USER root
RUN rm -f /usr/share/nginx/html/_headers /usr/share/nginx/html/_redirects /usr/share/nginx/html/.htaccess
USER 101

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz >/dev/null || exit 1
