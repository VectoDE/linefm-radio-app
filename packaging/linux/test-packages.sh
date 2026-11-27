#!/usr/bin/env bash
# Tests the Linux packages built by build-packages.sh on a throwaway CI runner:
#   .deb in a clean Ubuntu 24.04 container, .rpm in a clean Fedora 42 container
#   (install with dependencies, files, desktop entry, linefm:// handler, shared
#   libraries, app start, update, downgrade protection, uninstall),
#   AppImage on the runner (contents, desktop entry, app start).
#
#   packaging/linux/test-packages.sh --version X.Y.Z --app build/linux/x64/release/bundle \
#     --dist dist --artifacts build/packages-test
#
# --app is the bundle the packages were built from; a second deb and rpm with
# a higher version label are built from it for the update test.
#
# Needs docker, desktop-file-utils and xvfb on the runner.
set -uo pipefail

version=""; app=""; dist=""; art=build/packages-test
while [ $# -gt 0 ]; do
  case "$1" in
    --version) version=$2; shift 2 ;;
    --app) app=$2; shift 2 ;;
    --dist) dist=$2; shift 2 ;;
    --artifacts) art=$2; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
dist=$(cd "$dist" && pwd)
mkdir -p "$art"
art=$(cd "$art" && pwd)
base=linefm-radio-$version-linux-x64
failures=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }

# Base images pinned by digest (multi-arch index of the tag in the comment).
ubuntu=docker.io/library/ubuntu@sha256:562111b88caa79c71391c0c4d3c2114a7d5c35915c20561fd893cb1e07929e6b # 24.04
fedora=docker.io/library/fedora@sha256:99e203b80b1c3d8f7e161ec10a68fd02b081ef83a3963553e513c82846b97814 # 42

# Newer packages for the update test: same bundle, major version one above
# the tested one. Kept outside the artifacts folder (no upload).
major=${version%%.*}
newer_version=$((major + 1)).0.0
newer_dir="$(cd "$here/../.." && pwd)/build/packages-newer"
mkdir -p "$newer_dir"
if ! bash "$here/build-packages.sh" --version "$newer_version" --app "$app" --out "$newer_dir" \
    --formats deb,rpm > "$art/build-newer.log" 2>&1; then
  echo "FAIL: building the newer packages"; cat "$art/build-newer.log"; exit 1
fi
newer_base=linefm-radio-$newer_version-linux-x64

in_container() { # KIND IMAGE
  if docker run --rm -v "$dist:/pkgs:ro" -v "$newer_dir:/newer:ro" -v "$here:/t:ro" -v "$art:/out" "$2" \
      sh /t/test-in-container.sh "$1" "/pkgs/$base.$1" "/newer/$newer_base.$1" /out > "$art/$1.log" 2>&1; then
    pass "$1 in a clean container"
  else
    fail "$1 in a clean container"
  fi
  grep -E '^(PASS|FAIL):' "$art/$1.log"
}
in_container deb "$ubuntu"
in_container rpm "$fedora"

# AppImage: extract, check the desktop integration, start the app.
image="$dist/$base.AppImage"
ext="$art/appimage"
rm -rf "$ext"; mkdir -p "$ext"
if (cd "$ext" && "$image" --appimage-extract >/dev/null); then pass "AppImage extracts"; else fail "AppImage extracts"; fi
root="$ext/squashfs-root"
entry="$root/de.linefm.app.desktop"
if [ -x "$root/AppRun" ] && [ -x "$root/usr/lib/linefm-radio/linefm_radio" ]; then pass "AppImage contains the app"; else fail "AppImage contains the app"; fi
if [ -f "$entry" ] && ! desktop-file-validate "$entry" 2>&1 | grep -E 'error|warning' ; then pass "AppImage desktop entry valid"; else fail "AppImage desktop entry valid"; fi
if grep -qx 'MimeType=x-scheme-handler/linefm;' "$entry"; then pass "AppImage declares the linefm:// handler"; else fail "AppImage declares the linefm:// handler"; fi
if [ -f "$root/de.linefm.app.png" ] && [ -f "$root/usr/share/icons/hicolor/256x256/apps/de.linefm.app.png" ]; then pass "AppImage icons"; else fail "AppImage icons"; fi
# shellcheck disable=SC2016 # expanded by the inner bash
if APPIMAGE_EXTRACT_AND_RUN=1 xvfb-run -a -s '-screen 0 1280x900x24' bash -c '
  "$1" > "$2" 2>&1 & app=$!
  sleep 10
  if kill -0 "$app" 2>/dev/null; then kill "$app"; wait "$app" 2>/dev/null; exit 0; fi
  exit 1' _ "$image" "$art/app-appimage.log"; then
  pass "AppImage starts and keeps running"
else
  fail "AppImage starts and keeps running"; cat "$art/app-appimage.log"
fi
rm -rf "$ext"

echo "failures: $failures"
[ "$failures" -eq 0 ]
