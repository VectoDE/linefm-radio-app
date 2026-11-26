#!/usr/bin/env bash
# Builds LINEFM Radio locally on Linux or macOS.
#
# Usage:   tool/bauen.sh <target> [--oeffnen] [--port <number>]
# Targets: linux | macos | web | apk | aab   (windows is built by tool/bauen.ps1)
# Without --oeffnen it only builds. With --oeffnen the result is started afterwards.
# Exit code: 0 done, 1 prerequisite missing or build failed, 2 invalid input.
# No admin rights are needed and nothing is installed.
# Guide: docs/BAUEN-UND-STARTEN.md
set -euo pipefail

hilfe() {
  cat <<'TEXT'

Build LINEFM Radio (Linux and macOS)

Usage:
  tool/bauen.sh <target> [--oeffnen] [--port <number>]

Targets:
  linux   App for Linux (folder with linefm_radio), Linux only
  macos   App for macOS (LINEFM Radio.app), on a Mac only
  web     Web version (folder build/web)
  apk     Android installation file
  aab     Android App Bundle (for the Play Store only)

Without --oeffnen it only builds. With --oeffnen the result is started afterwards.
Windows is built by tool/bauen.ps1.
Guide: docs/BAUEN-UND-STARTEN.md

TEXT
}

fehler() {
  printf '\nERROR: %s\n' "$1" >&2
  exit "${2:-1}"
}

schritt() {
  printf '\n==> %s\n' "$1"
}

hat() {
  command -v "$1" >/dev/null 2>&1
}

ziel=""
oeffnen=0
port=8090

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--hilfe|--help)
      hilfe
      exit 0
      ;;
    --oeffnen)
      oeffnen=1
      ;;
    --port)
      [ "$#" -ge 2 ] || fehler "--port needs a number." 2
      port="$2"
      shift
      ;;
    -*)
      hilfe
      fehler "Unknown option: $1" 2
      ;;
    *)
      [ -z "$ziel" ] || fehler "Only one target is allowed." 2
      ziel="$1"
      ;;
  esac
  shift
done

if [ -z "$ziel" ]; then
  hilfe
  fehler "The target is missing. Example: tool/bauen.sh web" 2
fi
case "$port" in
  ''|*[!0-9]*) fehler "--port must be a number." 2 ;;
esac

ziel="$(printf '%s' "$ziel" | tr '[:upper:]' '[:lower:]')"
os="$(uname -s)"

case "$ziel" in
  windows) fehler "This script does not build the windows target. Use tool/bauen.ps1 on Windows." 2 ;;
  linux|macos|web|apk|aab) ;;
  *) hilfe; fehler "Unknown target \"$ziel\". Allowed: linux, macos, web, apk, aab." 2 ;;
esac

if [ "$ziel" = "linux" ] && [ "$os" != "Linux" ]; then
  fehler "Linux programs can only be built on a Linux machine. This is: $os." 1
fi
if [ "$ziel" = "macos" ] && [ "$os" != "Darwin" ]; then
  fehler "macOS programs can only be built on a Mac. This is: $os." 1
fi

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$repo/pubspec.yaml" ] || fehler "pubspec.yaml not found under $repo. The script must be in the project's tool folder." 1
cd "$repo"

schritt "Checking prerequisites"
hat flutter || fehler "Flutter was not found. Install Flutter 3.50.0 (https://docs.flutter.dev/get-started/install), add flutter/bin to the PATH and open a new terminal." 1
hat git || printf 'Note: Git was not found. Flutter needs Git.\n' >&2

case "$ziel" in
  linux)
    for werkzeug in clang cmake ninja pkg-config; do
      hat "$werkzeug" || fehler "\"$werkzeug\" is missing. On Debian/Ubuntu: sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev libx11-dev libxi-dev libmpv-dev libayatana-appindicator3-dev libkeybinder-3.0-dev libcurl4-openssl-dev" 1
    done
    if hat pkg-config; then
      pkg-config --exists gtk+-3.0 || fehler "GTK 3 (development package) is missing. On Debian/Ubuntu: sudo apt-get install libgtk-3-dev libx11-dev libxi-dev libmpv-dev libayatana-appindicator3-dev libkeybinder-3.0-dev libcurl4-openssl-dev" 1
    fi
    ;;
  macos)
    hat xcodebuild || fehler "Xcode was not found. Install Xcode from the App Store and start it once to accept the license." 1
    hat pod || fehler "CocoaPods is missing. Install it with: brew install cocoapods" 1
    ;;
  apk|aab)
    if [ -z "${JAVA_HOME:-}" ] && ! hat java; then
      printf 'Note: Java (JDK 17) was not found. The Android build needs it. Check with: flutter doctor\n' >&2
    fi
    ;;
  web)
    if [ "$oeffnen" -eq 1 ] && ! hat python3; then
      fehler "python3 was not found. It starts the local web server (--oeffnen). Install Python 3 or build without --oeffnen." 1
    fi
    ;;
esac

define_args=()
commit="$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || true)"
# config/app.yaml and config/features.yaml (YAML with comments) are
# validated and written as build values to config/app.json.
if [ -f "$repo/config/app.yaml" ] || [ -f "$repo/config/features.yaml" ]; then
  echo "config/app.yaml or features.yaml found, build values are being generated."
  (cd "$repo" && dart run tool/check_config.dart --defines config/app.json) ||
    fehler "Configuration in config/ is invalid, see the messages above." 1
fi
if [ -f "$repo/config/app.json" ]; then
  echo "config/app.json found, it is used for the build."
  define_args=(--dart-define-from-file=config/app.json)
else
  echo "No config/app.json, the app builds with default values."
fi
# Local builds show "development version" with the short commit ID.
if [ -n "$commit" ]; then define_args+=(--dart-define=APP_COMMIT="$commit"); fi

port_frei() {
  # Free if nothing can connect to the port.
  if hat python3; then
    python3 - "$1" <<'PY'
import socket, sys
s = socket.socket()
s.settimeout(0.3)
try:
    s.connect(("127.0.0.1", int(sys.argv[1])))
except OSError:
    sys.exit(0)
sys.exit(1)
PY
  else
    return 0
  fi
}

web_port="$port"
if [ "$ziel" = "web" ]; then
  versuche=0
  while ! port_frei "$web_port"; do
    web_port=$((web_port + 1))
    versuche=$((versuche + 1))
    [ "$versuche" -lt 50 ] || fehler "No free port found from $port. Choose a different starting number with --port." 1
  done
fi

schritt "Fetching packages (flutter pub get)"
flutter pub get || fehler "flutter pub get failed. The message is above. Help: docs/BAUEN-UND-STARTEN.md, section \"Wenn etwas schiefgeht\"." 1

start_zeit=$SECONDS
ergebnis=""

case "$ziel" in
  linux)
    schritt "Building Linux"
    flutter build linux --release ${define_args[@]+"${define_args[@]}"} || fehler "flutter build linux failed. The message is above." 1
    ergebnis="$repo/build/linux/x64/release/bundle/linefm_radio"
    ;;
  macos)
    schritt "Building macOS"
    flutter build macos --release ${define_args[@]+"${define_args[@]}"} || fehler "flutter build macos failed. The message is above." 1
    ergebnis="$repo/build/macos/Build/Products/Release/LINEFM Radio.app"
    ;;
  apk)
    schritt "Building Android APK"
    flutter build apk --release ${define_args[@]+"${define_args[@]}"} || fehler "flutter build apk failed. The message is above." 1
    ergebnis="$repo/build/app/outputs/flutter-apk/app-release.apk"
    ;;
  aab)
    schritt "Building Android App Bundle"
    flutter build appbundle --release ${define_args[@]+"${define_args[@]}"} || fehler "flutter build appbundle failed. The message is above." 1
    ergebnis="$repo/build/app/outputs/bundle/release/app-release.aab"
    ;;
  web)
    schritt "Building web"
    # Map unfilled legal-text placeholders to themselves, otherwise flutter build web warns
    # (loop instead of mapfile, because macOS only ships Bash 3.2).
    web_defines=()
    while IFS= read -r arg; do web_defines+=("$arg"); done < <(bash "$repo/tool/web_define_passthrough.sh")
    flutter build web --release --wasm --no-web-resources-cdn ${define_args[@]+"${define_args[@]}"} ${web_defines[@]+"${web_defines[@]}"} || fehler "flutter build web failed. The message is above." 1
    # As in CI: start the tools outside the package, otherwise "dart run"
    # additionally builds the project's native asset hooks (on Linux that needs GTK).
    tmp="$(mktemp -d)"
    cp tool/fetch_font_fallback.dart tool/web_postbuild.dart "$tmp/"
    schritt "Fetching fallback fonts (needs internet)"
    dart run "$tmp/fetch_font_fallback.dart" build/web || fehler "Fetching fallback fonts failed. Is the internet reachable?" 1
    schritt "Post-processing the web files"
    dart run "$tmp/web_postbuild.dart" build/web --targets none --base-url "http://localhost:$web_port" || fehler "Post-processing (web_postbuild) failed. The message is above." 1
    rm -rf "$tmp"
    ergebnis="$repo/build/web/index.html"
    ;;
esac

[ -e "$ergebnis" ] || fehler "The build reported success, but the expected file is missing: $ergebnis" 1

printf '\nDONE after %s seconds.\n' "$((SECONDS - start_zeit))"
printf 'Result: %s\n' "$ergebnis"

oeffne_ordner() {
  if [ "$os" = "Darwin" ]; then
    open "$1"
  elif hat xdg-open; then
    xdg-open "$1" >/dev/null 2>&1 || true
  else
    printf 'Folder: %s\n' "$1"
  fi
}

if [ "$oeffnen" -eq 0 ]; then
  case "$ziel" in
    linux) echo "Start: ./build/linux/x64/release/bundle/linefm_radio (the whole bundle folder belongs together)." ;;
    macos) echo "Start: open \"build/macos/Build/Products/Release/LINEFM Radio.app\"" ;;
    web)   echo "View: run again with --oeffnen or: python3 -m http.server $web_port --directory build/web" ;;
    apk)   echo "Copy the APK to the phone and open it there." ;;
    aab)   echo "The App Bundle is meant for the Play Store only, not for installing." ;;
  esac
  exit 0
fi

schritt "Opening the result"
case "$ziel" in
  linux)
    (cd "$(dirname "$ergebnis")" && ./linefm_radio >/dev/null 2>&1 &)
    echo "The app was started."
    ;;
  macos)
    open "$ergebnis"
    ;;
  apk|aab)
    oeffne_ordner "$(dirname "$ergebnis")"
    ;;
  web)
    adresse="http://localhost:$web_port"
    echo "Server running at $adresse . Press Ctrl+C to stop."
    oeffne_ordner "$adresse"
    exec python3 -m http.server "$web_port" --bind 127.0.0.1 --directory build/web
    ;;
esac
exit 0
