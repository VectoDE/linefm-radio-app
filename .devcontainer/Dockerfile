# Entwicklungsumgebung fuer LINEFM Radio (Web, Linux-Desktop, Tests, Analyse).
# Android-, Windows-, macOS- und iOS-Builds laufen nicht in diesem Container
# (siehe docs/ENTWICKLUNG.md).
#
# Das Basisimage ist per Digest gepinnt (Ubuntu 24.04, Dev-Container-Basis von
# Microsoft). Dependabot aktualisiert Tag und Digest (.github/dependabot.yml).
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04@sha256:d94c97dd9cacf183d0a6fd12a8e87b526e9e928307674ae9c94139139c0c6eae

# Flutter-Version und Pruefsumme des offiziellen Linux-Archivs. Quelle der
# Wahrheit fuer die Version ist .fvmrc, ein Test (test/tool/flutter_version_test.dart)
# vergleicht beide mit der CI. Die Pruefsumme steht in
# https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
ARG FLUTTER_VERSION=3.50.0
ARG FLUTTER_SHA256=6ea2d806fd57269ae783e6788e2a81fc26eaad782f1e0d0ff38623bb765ff9f5

# Systempakete wie in .github/actions/linux-deps (Linux-Desktop-Build und
# Native-Asset-Hooks), dazu die Werkzeuge, die Flutter selbst verlangt.
RUN apt-get update -q \
    && apt-get install -y -q --no-install-recommends \
        ca-certificates curl git unzip xz-utils zip \
        clang cmake ninja-build pkg-config libgtk-3-dev libx11-dev libxi-dev \
        libmpv-dev libayatana-appindicator3-dev libkeybinder-3.0-dev \
        libcurl4-openssl-dev libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/flutter.tar.xz \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && chown -R vscode:vscode /opt/flutter \
    && git config --system --add safe.directory /opt/flutter

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Kein Dienst im Container (reine Entwicklungsumgebung, VS Code startet die
# Prozesse selbst). Ein Gesundheitstest haette nichts zu pruefen; HEALTHCHECK NONE
# legt das ausdruecklich fest (Trivy DS-0026).
HEALTHCHECK NONE

USER vscode
