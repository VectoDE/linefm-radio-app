#!/bin/sh
# Install, start and uninstall test of the .deb or .rpm inside a clean
# distribution container (run by test-packages.sh, never on a real machine).
#
#   test-in-container.sh deb|rpm <package> <newer package> /out
#
# The newer package is the same bundle with a higher version label and
# drives the update and downgrade checks.
set -u
kind=$1; pkg=$2; newer=$3; out=$4
failures=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }
check() { what=$1; shift; if "$@"; then pass "$what"; else fail "$what"; fi; }
desktop=/usr/share/applications/de.linefm.app.desktop

case "$kind" in
  deb)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -q >/dev/null
    apt-get install -y -q --no-install-recommends xvfb xauth desktop-file-utils procps >/dev/null || exit 1
    check "deb installs with its dependencies" apt-get install -y -q --no-install-recommends "$pkg"
    check "package registered" dpkg -s linefm-radio
    ;;
  rpm)
    dnf install -y -q xorg-x11-server-Xvfb desktop-file-utils procps-ng >/dev/null || exit 1
    check "rpm installs with its dependencies" dnf install -y -q "$pkg"
    check "package files verify" rpm -V linefm-radio
    ;;
  *) echo "unknown kind: $kind" >&2; exit 2 ;;
esac

check "app binary" test -x /usr/lib/linefm-radio/linefm_radio
check "command linefm-radio" test -x /usr/bin/linefm-radio
check "desktop entry" test -f "$desktop"
check "icon 256x256" test -f /usr/share/icons/hicolor/256x256/apps/de.linefm.app.png
check "AppStream metainfo" test -f /usr/share/metainfo/de.linefm.app.metainfo.xml
check "desktop entry valid (no errors or warnings)" sh -c "! desktop-file-validate '$desktop' 2>&1 | grep -E 'error|warning'"
check "linefm:// handler declared" grep -qx 'MimeType=x-scheme-handler/linefm;' "$desktop"
check "linefm:// handler registered" grep -q '^x-scheme-handler/linefm=.*de.linefm.app.desktop' /usr/share/applications/mimeinfo.cache
missing=$(find /usr/lib/linefm-radio -type f \( -name linefm_radio -o -name '*.so*' \) -exec env LD_LIBRARY_PATH=/usr/lib/linefm-radio/lib ldd {} + 2>/dev/null | grep 'not found' | sort -u)
check "all shared libraries resolve" test -z "$missing"
[ -z "$missing" ] || echo "$missing"

# Start: the app must still run after 10 seconds on a virtual display.
Xvfb :99 -screen 0 1280x900x24 >/dev/null 2>&1 &
xvfb=$!
sleep 2
DISPLAY=:99 linefm-radio >"$out/app-$kind.log" 2>&1 &
app=$!
sleep 10
if kill -0 "$app" 2>/dev/null; then pass "app starts and keeps running"; kill "$app"; else fail "app starts and keeps running"; cat "$out/app-$kind.log"; fi
wait "$app" 2>/dev/null
kill "$xvfb" 2>/dev/null

# Update to the newer package, then a plain install of the older one must not
# downgrade.
version() {
  case "$kind" in
    deb) dpkg-query -W -f '${Version}' linefm-radio 2>/dev/null ;;
    rpm) rpm -q --qf '%{VERSION}-%{RELEASE}' linefm-radio 2>/dev/null ;;
  esac
}
before=$(version)
case "$kind" in
  deb) check "update installs" apt-get install -y -q --no-install-recommends "$newer"
       want=$(dpkg-deb -f "$newer" Version) ;;
  rpm) check "update installs" dnf install -y -q "$newer"
       want=$(rpm -qp --qf '%{VERSION}-%{RELEASE}' "$newer") ;;
esac
updated=$(version)
echo "version before: $before, after update: $updated, expected: $want"
check "update raised the version" sh -c "test \"$updated\" = \"$want\" && test \"$updated\" != \"$before\""
check "app binary after update" test -x /usr/lib/linefm-radio/linefm_radio
case "$kind" in
  deb) apt-get install -y -q --no-install-recommends "$pkg" >"$out/downgrade-$kind.log" 2>&1 ;;
  # dnf5 treats "install ./older.rpm" as an explicit downgrade request; the
  # update path users run is "upgrade", which must keep the newer version.
  rpm) dnf upgrade -y -q "$pkg" >"$out/downgrade-$kind.log" 2>&1 ;;
esac
check "no silent downgrade" test "$(version)" = "$updated"

case "$kind" in
  deb) check "deb uninstalls" apt-get remove -y -q linefm-radio ;;
  rpm) check "rpm uninstalls" dnf remove -y -q linefm-radio ;;
esac
check "files removed" sh -c '! test -e /usr/lib/linefm-radio && ! test -e /usr/bin/linefm-radio && ! test -e '"$desktop"' && ! test -e /usr/share/icons/hicolor/256x256/apps/de.linefm.app.png'
check "linefm:// handler unregistered" sh -c '! grep -q "de.linefm.app.desktop" /usr/share/applications/mimeinfo.cache 2>/dev/null'

echo "failures: $failures"
[ "$failures" -eq 0 ]
