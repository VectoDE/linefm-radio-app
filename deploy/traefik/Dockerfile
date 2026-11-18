# Web-Container fuer app.linefm.de. Build-Kontext: Repository-Wurzel, nach
#   flutter build web ... && dart run tool/web_postbuild.dart build/web
# docker build -f deploy/traefik/Dockerfile -t linefm-app-web .
# Basisimage per Digest gepinnt (nginx 1.30 stable, alpine). Aktualisierung: docs/hosting-traefik.md
FROM nginxinc/nginx-unprivileged:1.30-alpine@sha256:f5116ed4606f3eb015dd4a8e28cb9b351476dc0ad4bc6e9f93b19cec130cdf03

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
