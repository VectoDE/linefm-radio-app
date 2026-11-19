#!/usr/bin/env bash
# Erstellt das unsignierte DMG fuer LINEFM Radio.
#
# Aufruf (Vertrag mit build.yml, P25):
#   bash packaging/macos/create_dmg.sh "<Pfad zur .app>" "<Ziel.dmg>"
#
# Inhalt: die App, Verknuepfung "Applications", die Oeffnen-Anleitung.
# Nutzt "create-dmg" (https://github.com/create-dmg/create-dmg, brew install
# create-dmg) fuer Fensterlayout und Hintergrund, wenn vorhanden; sonst
# faellt das Skript auf hdiutil zurueck (gleicher Inhalt, ohne Layout).
# Signieren und Notarisieren macht build.yml danach, nicht dieses Skript.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Aufruf: $0 <App.app> <Ziel.dmg>" >&2
  exit 2
fi

APP_PATH="$1"
DMG_PATH="$2"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VOLNAME="LINEFM Radio"
APP_NAME="$(basename "$APP_PATH")"
README_SRC="$HERE/LIES-MICH-ZUERST.txt"
BACKGROUND="$HERE/dmg-background.png"

if [ ! -d "$APP_PATH" ]; then
  echo "App nicht gefunden: $APP_PATH" >&2
  exit 1
fi

mkdir -p "$(dirname "$DMG_PATH")"
rm -f "$DMG_PATH"

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP_PATH" "$STAGING/"
cp "$README_SRC" "$STAGING/LIES-MICH-ZUERST.txt"

if command -v create-dmg >/dev/null 2>&1; then
  args=(
    --volname "$VOLNAME"
    --window-pos 200 120
    --window-size 660 420
    --icon-size 110
    --icon "$APP_NAME" 170 190
    --hide-extension "$APP_NAME"
    --app-drop-link 490 190
    --icon "LIES-MICH-ZUERST.txt" 330 340
    --no-internet-enable
  )
  if [ -f "$BACKGROUND" ]; then
    args+=(--background "$BACKGROUND")
  fi
  # create-dmg legt die Applications-Verknuepfung selbst an (--app-drop-link).
  create-dmg "${args[@]}" "$DMG_PATH" "$STAGING"
else
  echo "create-dmg nicht gefunden, nutze hdiutil (ohne Fensterlayout)." >&2
  ln -s /Applications "$STAGING/Applications"
  hdiutil create -volname "$VOLNAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG_PATH"
fi

hdiutil verify "$DMG_PATH"
echo "DMG erstellt: $DMG_PATH"
