#!/usr/bin/env bash
# Fetches appimagetool and the AppImage type 2 runtime used by build.sh,
# pinned to fixed releases and verified by SHA-256 (digests from the GitHub
# release metadata).
set -euo pipefail
dest=${1:-build/installer/tools}
mkdir -p "$dest"

fetch() { # URL SHA256 FILE
  curl -fsSL --retry 3 -o "$dest/$3" "$1"
  echo "$2  $dest/$3" | sha256sum -c -
  chmod 755 "$dest/$3"
}

fetch https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage \
  ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0 appimagetool
fetch https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64 \
  2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d runtime-x86_64
