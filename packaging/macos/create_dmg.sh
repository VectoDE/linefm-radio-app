#!/usr/bin/env bash
# Erstellt das unsignierte DMG fuer LINEFM Radio.
#
# Aufruf (Vertrag mit build.yml):
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
STAGING_BG="$(mktemp -d)"
trap 'rm -rf "$STAGING" "$STAGING_BG"' EXIT
cp -R "$APP_PATH" "$STAGING/"
cp "$README_SRC" "$STAGING/LIES-MICH-ZUERST.txt"

# CI runners have Homebrew but not create-dmg; without it the DMG has no
# styled window, so install it there. Locally nothing is installed silently.
if ! command -v create-dmg >/dev/null 2>&1 && [ "${CI:-}" = "true" ] && command -v brew >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --quiet create-dmg
fi

if command -v create-dmg >/dev/null 2>&1; then
  args=(
    --volname "$VOLNAME"
    --window-pos 200 120
    --window-size 660 448
    --icon-size 110
    --icon "$APP_NAME" 170 170
    --hide-extension "$APP_NAME"
    --app-drop-link 490 170
    --icon "LIES-MICH-ZUERST.txt" 95 60
    --no-internet-enable
  )
  if [ -f "$BACKGROUND" ]; then
    # Retina: tiffutil merges 1x and 2x into one HiDPI background (macOS only).
    BACKGROUND_2X="$HERE/dmg-background@2x.png"
    if [ -f "$BACKGROUND_2X" ] && command -v tiffutil >/dev/null 2>&1; then
      tiffutil -cathidpicheck "$BACKGROUND" "$BACKGROUND_2X" -out "$STAGING_BG/background.tiff"
      args+=(--background "$STAGING_BG/background.tiff")
    else
      args+=(--background "$BACKGROUND")
    fi
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
