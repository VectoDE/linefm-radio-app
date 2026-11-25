#!/usr/bin/env bash
# Prints one --web-define=NAME={{NAME}} argument per legal placeholder that is
# still unfilled in web/*/index.html.
#
# flutter build web treats every web/*/index.html as a template and warns for
# each {{NAME}} without a matching --web-define. Builds without operator data
# (pull request and smoke builds) keep the placeholders on purpose; mapping each
# one to itself keeps the output byte-identical and the build log clean.
# Release builds fill the pages first (write-config), so nothing is printed.
set -euo pipefail
cd "$(dirname "$0")/.."
{ grep -rhoE '\{\{[A-Z][A-Z0-9_]*\}\}' web --include=index.html || true; } \
  | sort -u \
  | sed -E 's/^\{\{(.*)\}\}$/--web-define=\1={{\1}}/'
