#!/usr/bin/env bash
# Builds the macOS installer: "LINEFM Radio Setup.app" (shared setup UI
# from installer/ui with the POSIX engine and the app as payload) inside a
# designed DMG.
#
#   installer/macos/build.sh --version X.Y.Z --app "build/macos/Build/Products/Release/LINEFM Radio.app" \
#     --out dist/linefm-radio-X.Y.Z-macos-setup.dmg [--identity "Developer ID Application"] [--skip-ui-build]
#
# Without --identity everything is signed ad hoc (runs on Apple silicon, but
# Gatekeeper asks on first open). Notarization is done by build.yml when the
# Apple secrets exist.
set -euo pipefail

version=""; app=""; out=""; identity="-"; skip_ui=0
while [ $# -gt 0 ]; do
  case "$1" in
    --version) version=$2; shift 2 ;;
    --app) app=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    --identity) identity=$2; shift 2 ;;
    --skip-ui-build) skip_ui=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]] || { echo "bad version: $version" >&2; exit 2; }
[ -d "$app/Contents/MacOS" ] || { echo "app missing: $app" >&2; exit 2; }
[ -n "$out" ] || { echo "--out missing" >&2; exit 2; }

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
here=$repo/installer/macos
app=$(cd "$(dirname "$app")" && pwd)/$(basename "$app")
numeric=${version%%[-+]*}
work=$repo/build/installer/macos
mkdir -p "$(dirname "$out")"
out=$(cd "$(dirname "$out")" && pwd)/$(basename "$out")
entitlements=$repo/installer/ui/macos/Runner/Release.entitlements

if [ "$skip_ui" = 0 ]; then
  (cd "$repo/installer/ui" && flutter pub get && flutter build macos --release --build-name "$numeric")
fi
ui_app="$repo/installer/ui/build/macos/Build/Products/Release/LINEFM Radio Setup.app"
[ -d "$ui_app" ] || { echo "setup UI not built: $ui_app" >&2; exit 2; }

sign() { # BUNDLE
  local opts=(--force --deep --entitlements "$entitlements" --sign "$identity")
  [ "$identity" != "-" ] && opts+=(--options runtime --timestamp)
  codesign "${opts[@]}" "$1"
  codesign --verify --deep --strict "$1"
}

setup_files() { # RESOURCES_SETUP_DIR
  mkdir -p "$1/licenses"
  install -m 755 "$repo/installer/posix/root-helper.sh" "$1/root-helper.sh"
  install -m 755 "$repo/installer/posix/engine.sh" "$1/engine.sh"
  install -m 644 "$repo/LICENSE" "$1/LICENSE.txt"
  install -m 644 "$repo/assets/fonts/OFL.txt" "$1/licenses/OFL-Poppins.txt"
  install -m 644 "$repo/assets/fonts/LICENSE-Syncopate-Apache2.txt" "$1/licenses/Apache-2.0-Syncopate.txt"
  {
    grep -v '^#' "$repo/installer/posix/product.env"
    echo "DIR_NAME=LINEFM Radio.app"
    echo "VERSION=$version"
    echo "SIZE=$size"
  } > "$1/product.env"
}

rm -rf "$work"
mkdir -p "$work/payload/app" "$work/payload/uninstaller" "$work/dmg"
size=$(( $(du -sk "$app" | cut -f1) * 1024 ))

# Uninstaller: the same UI without payload, kept by the engine after install.
uninstaller="$work/payload/uninstaller/Uninstall LINEFM Radio.app"
ditto "$ui_app" "$uninstaller"
setup_files "$uninstaller/Contents/Resources/setup"
plist="$uninstaller/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier de.linefm.setup.uninstall" "$plist"
/usr/libexec/PlistBuddy -c "Delete :CFBundleDisplayName" "$plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Uninstall LINEFM Radio" "$plist"
sign "$uninstaller"

ditto "$app" "$work/payload/app/LINEFM Radio.app"
installer="$work/dmg/LINEFM Radio Setup.app"
ditto "$ui_app" "$installer"
setup="$installer/Contents/Resources/setup"
setup_files "$setup"
(cd "$work/payload" && COPYFILE_DISABLE=1 tar -czf "$setup/payload.tar.gz" app uninstaller)
(cd "$setup" && shasum -a 256 payload.tar.gz > payload.sha256)
sign "$installer"

# Retina background: 1x and 2x combined into one TIFF.
tiffutil -cathidpicheck "$here/dmg-background.png" "$here/dmg-background@2x.png" -out "$work/background.tiff"
rm -f "$out"
dmgbuild -s "$here/dmg-settings.py" -D app="$installer" -D background="$work/background.tiff" \
  "LINEFM Radio Setup" "$out"
[ "$identity" != "-" ] && codesign --force --timestamp --sign "$identity" "$out"
hdiutil verify "$out"
ls -la "$out"
