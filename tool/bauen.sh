#!/usr/bin/env bash
# Baut LINEFM Radio lokal auf Linux oder macOS.
#
# Aufruf:  tool/bauen.sh <ziel> [--oeffnen] [--port <zahl>]
# Ziele:   linux | macos | web | apk | aab   (windows baut tool/bauen.ps1)
# Ohne --oeffnen wird nur gebaut. Mit --oeffnen wird das Ergebnis danach gestartet.
# Exit-Code: 0 fertig, 1 Voraussetzung fehlt oder Bau fehlgeschlagen, 2 falsche Eingabe.
# Es werden keine Admin-Rechte gebraucht und nichts installiert.
# Anleitung: docs/BAUEN-UND-STARTEN.md
set -euo pipefail

hilfe() {
  cat <<'TEXT'

LINEFM Radio bauen (Linux und macOS)

Aufruf:
  tool/bauen.sh <ziel> [--oeffnen] [--port <zahl>]

Ziele:
  linux   App fuer Linux (Ordner mit linefm_radio), nur auf Linux
  macos   App fuer macOS (LINEFM Radio.app), nur auf einem Mac
  web     Web-Version (Ordner build/web)
  apk     Android-Installationsdatei
  aab     Android App Bundle (nur fuer den Play Store)

Ohne --oeffnen wird nur gebaut. Mit --oeffnen wird das Ergebnis danach gestartet.
Windows baut tool/bauen.ps1.
Anleitung: docs/BAUEN-UND-STARTEN.md

TEXT
}

fehler() {
  printf '\nFEHLER: %s\n' "$1" >&2
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
      [ "$#" -ge 2 ] || fehler "--port braucht eine Zahl." 2
      port="$2"
      shift
      ;;
    -*)
      hilfe
      fehler "Unbekannte Option: $1" 2
      ;;
    *)
      [ -z "$ziel" ] || fehler "Es ist nur ein Ziel erlaubt." 2
      ziel="$1"
      ;;
  esac
  shift
done

if [ -z "$ziel" ]; then
  hilfe
  fehler "Es fehlt das Ziel. Beispiel: tool/bauen.sh web" 2
fi
case "$port" in
  ''|*[!0-9]*) fehler "--port muss eine Zahl sein." 2 ;;
esac

ziel="$(printf '%s' "$ziel" | tr '[:upper:]' '[:lower:]')"
os="$(uname -s)"

case "$ziel" in
  windows) fehler "Das Ziel windows baut dieses Skript nicht. Nimm tool/bauen.ps1 unter Windows." 2 ;;
  linux|macos|web|apk|aab) ;;
  *) hilfe; fehler "Unbekanntes Ziel \"$ziel\". Erlaubt: linux, macos, web, apk, aab." 2 ;;
esac

if [ "$ziel" = "linux" ] && [ "$os" != "Linux" ]; then
  fehler "Linux-Programme lassen sich nur auf einem Linux-Rechner bauen. Hier laeuft: $os." 1
fi
if [ "$ziel" = "macos" ] && [ "$os" != "Darwin" ]; then
  fehler "macOS-Programme lassen sich nur auf einem Mac bauen. Hier laeuft: $os." 1
fi

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$repo/pubspec.yaml" ] || fehler "pubspec.yaml nicht gefunden unter $repo. Das Skript muss im Ordner tool des Projekts liegen." 1
cd "$repo"

schritt "Voraussetzungen pruefen"
hat flutter || fehler "Flutter wurde nicht gefunden. Installiere Flutter 3.50.0 (https://docs.flutter.dev/get-started/install), fuege flutter/bin zum PATH hinzu und oeffne ein neues Terminal." 1
hat git || printf 'Hinweis: Git wurde nicht gefunden. Flutter braucht Git.\n' >&2

case "$ziel" in
  linux)
    for werkzeug in clang cmake ninja pkg-config; do
      hat "$werkzeug" || fehler "\"$werkzeug\" fehlt. Auf Debian/Ubuntu: sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev libx11-dev libxi-dev libmpv-dev libayatana-appindicator3-dev libkeybinder-3.0-dev libcurl4-openssl-dev" 1
    done
    if hat pkg-config; then
      pkg-config --exists gtk+-3.0 || fehler "GTK 3 (Entwicklungspaket) fehlt. Auf Debian/Ubuntu: sudo apt-get install libgtk-3-dev libx11-dev libxi-dev libmpv-dev libayatana-appindicator3-dev libkeybinder-3.0-dev libcurl4-openssl-dev" 1
    fi
    ;;
  macos)
    hat xcodebuild || fehler "Xcode wurde nicht gefunden. Installiere Xcode aus dem App Store und starte es einmal, um die Lizenz zu bestaetigen." 1
    hat pod || fehler "CocoaPods fehlt. Installiere es mit: brew install cocoapods" 1
    ;;
  apk|aab)
    if [ -z "${JAVA_HOME:-}" ] && ! hat java; then
      printf 'Hinweis: Java (JDK 17) wurde nicht gefunden. Der Android-Build braucht es. Pruefe mit: flutter doctor\n' >&2
    fi
    ;;
  web)
    if [ "$oeffnen" -eq 1 ] && ! hat python3; then
      fehler "python3 wurde nicht gefunden. Es startet den lokalen Web-Server (--oeffnen). Installiere Python 3 oder baue ohne --oeffnen." 1
    fi
    ;;
esac

define_args=()
commit="$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || true)"
# config/app.yaml und config/features.yaml (YAML mit Kommentaren) werden
# geprueft und als Bauwerte nach config/app.json geschrieben (Issue #91).
if [ -f "$repo/config/app.yaml" ] || [ -f "$repo/config/features.yaml" ]; then
  echo "config/app.yaml bzw. features.yaml gefunden, Bauwerte werden erzeugt."
  (cd "$repo" && dart run tool/check_config.dart --defines config/app.json) ||
    fehler "Konfiguration in config/ fehlerhaft, siehe Meldungen oben." 1
fi
if [ -f "$repo/config/app.json" ]; then
  echo "config/app.json gefunden, wird beim Bauen verwendet."
  define_args=(--dart-define-from-file=config/app.json)
else
  echo "Keine config/app.json, die App baut mit Standardwerten."
fi
# Lokale Builds zeigen "Entwicklungsversion" mit Commit-Kurz-ID (#104).
if [ -n "$commit" ]; then define_args+=(--dart-define=APP_COMMIT="$commit"); fi

port_frei() {
  # Frei, wenn sich nichts mit dem Port verbinden laesst.
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
    [ "$versuche" -lt 50 ] || fehler "Kein freier Port ab $port gefunden. Mit --port eine andere Startzahl waehlen." 1
  done
fi

schritt "Pakete holen (flutter pub get)"
flutter pub get || fehler "flutter pub get ist fehlgeschlagen. Die Meldung steht oben. Hilfe: docs/BAUEN-UND-STARTEN.md, Abschnitt \"Wenn etwas schiefgeht\"." 1

start_zeit=$SECONDS
ergebnis=""

case "$ziel" in
  linux)
    schritt "Linux bauen"
    flutter build linux --release ${define_args[@]+"${define_args[@]}"} || fehler "flutter build linux ist fehlgeschlagen. Die Meldung steht oben." 1
    ergebnis="$repo/build/linux/x64/release/bundle/linefm_radio"
    ;;
  macos)
    schritt "macOS bauen"
    flutter build macos --release ${define_args[@]+"${define_args[@]}"} || fehler "flutter build macos ist fehlgeschlagen. Die Meldung steht oben." 1
    ergebnis="$repo/build/macos/Build/Products/Release/LINEFM Radio.app"
    ;;
  apk)
    schritt "Android-APK bauen"
    flutter build apk --release ${define_args[@]+"${define_args[@]}"} || fehler "flutter build apk ist fehlgeschlagen. Die Meldung steht oben." 1
    ergebnis="$repo/build/app/outputs/flutter-apk/app-release.apk"
    ;;
  aab)
    schritt "Android App Bundle bauen"
    flutter build appbundle --release ${define_args[@]+"${define_args[@]}"} || fehler "flutter build appbundle ist fehlgeschlagen. Die Meldung steht oben." 1
    ergebnis="$repo/build/app/outputs/bundle/release/app-release.aab"
    ;;
  web)
    schritt "Web bauen"
    flutter build web --release --wasm --no-web-resources-cdn ${define_args[@]+"${define_args[@]}"} || fehler "flutter build web ist fehlgeschlagen. Die Meldung steht oben." 1
    # Wie in der CI: die Werkzeuge ausserhalb des Pakets starten, sonst baut "dart run"
    # zusaetzlich die Native-Asset-Hooks des Projekts (unter Linux braucht das GTK).
    tmp="$(mktemp -d)"
    cp tool/fetch_font_fallback.dart tool/web_postbuild.dart "$tmp/"
    schritt "Ersatzschriften holen (braucht Internet)"
    dart run "$tmp/fetch_font_fallback.dart" build/web || fehler "Ersatzschriften holen ist fehlgeschlagen. Ist das Internet erreichbar?" 1
    schritt "Nachbearbeitung der Web-Dateien"
    dart run "$tmp/web_postbuild.dart" build/web --targets none --base-url "http://localhost:$web_port" || fehler "Nachbearbeitung (web_postbuild) ist fehlgeschlagen. Die Meldung steht oben." 1
    rm -rf "$tmp"
    ergebnis="$repo/build/web/index.html"
    ;;
esac

[ -e "$ergebnis" ] || fehler "Der Bau meldete Erfolg, aber die erwartete Datei fehlt: $ergebnis" 1

printf '\nFERTIG nach %s Sekunden.\n' "$((SECONDS - start_zeit))"
printf 'Ergebnis: %s\n' "$ergebnis"

oeffne_ordner() {
  if [ "$os" = "Darwin" ]; then
    open "$1"
  elif hat xdg-open; then
    xdg-open "$1" >/dev/null 2>&1 || true
  else
    printf 'Ordner: %s\n' "$1"
  fi
}

if [ "$oeffnen" -eq 0 ]; then
  case "$ziel" in
    linux) echo "Starten: ./build/linux/x64/release/bundle/linefm_radio (der ganze Ordner bundle gehoert zusammen)." ;;
    macos) echo "Starten: open \"build/macos/Build/Products/Release/LINEFM Radio.app\"" ;;
    web)   echo "Ansehen: erneut mit --oeffnen starten oder: python3 -m http.server $web_port --directory build/web" ;;
    apk)   echo "Die APK aufs Handy kopieren und dort oeffnen." ;;
    aab)   echo "Das App Bundle ist nur fuer den Play Store gedacht, nicht zum Installieren." ;;
  esac
  exit 0
fi

schritt "Ergebnis oeffnen"
case "$ziel" in
  linux)
    (cd "$(dirname "$ergebnis")" && ./linefm_radio >/dev/null 2>&1 &)
    echo "Die App wurde gestartet."
    ;;
  macos)
    open "$ergebnis"
    ;;
  apk|aab)
    oeffne_ordner "$(dirname "$ergebnis")"
    ;;
  web)
    adresse="http://localhost:$web_port"
    echo "Server laeuft auf $adresse . Zum Beenden Strg+C druecken."
    oeffne_ordner "$adresse"
    exec python3 -m http.server "$web_port" --bind 127.0.0.1 --directory build/web
    ;;
esac
exit 0
