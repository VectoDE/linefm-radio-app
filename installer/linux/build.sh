#!/usr/bin/env bash
# Builds the Linux installer: an AppImage of the shared setup UI
# (installer/ui) with the POSIX engine and the app bundle as payload.
#
#   installer/linux/build.sh --version X.Y.Z --app build/linux/x64/release/bundle \
#     --out dist/linefm-radio-X.Y.Z-linux-x64-setup.AppImage [--skip-ui-build]
#
# Needs: flutter, tar, sha256sum and the pinned appimagetool and AppImage
# runtime (fetched by fetch-appimagetool.sh, verified by SHA-256).
set -euo pipefail

version=""; app=""; out=""; skip_ui=0
while [ $# -gt 0 ]; do
  case "$1" in
    --version) version=$2; shift 2 ;;
    --app) app=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    --skip-ui-build) skip_ui=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]] || { echo "bad version: $version" >&2; exit 2; }
[ -x "$app/linefm_radio" ] || { echo "app bundle missing: $app" >&2; exit 2; }
[ -n "$out" ] || { echo "--out missing" >&2; exit 2; }

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
app=$(cd "$app" && pwd)
numeric=${version%%[-+]*}
tools=${APPIMAGE_TOOLS:-$repo/build/installer/tools}
work=$repo/build/installer/linux
mkdir -p "$(dirname "$out")"
out=$(cd "$(dirname "$out")" && pwd)/$(basename "$out")
export SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(git -C "$repo" log -1 --format=%ct)}

if [ "$skip_ui" = 0 ]; then
  (cd "$repo/installer/ui" && flutter pub get && flutter build linux --release --build-name "$numeric")
fi
ui_bundle=$repo/installer/ui/build/linux/x64/release/bundle
[ -x "$ui_bundle/linefm_setup" ] || { echo "setup UI not built: $ui_bundle" >&2; exit 2; }

rm -rf "$work"
appdir=$work/AppDir
lib=$appdir/usr/lib/linefm-setup
setup=$lib/setup
mkdir -p "$lib" "$work/payload/app"
cp -a "$ui_bundle/." "$lib/"
mkdir -p "$setup/licenses"
install -m 755 "$repo/installer/posix/engine.sh" "$setup/engine.sh"
install -m 755 "$repo/installer/posix/root-helper.sh" "$setup/root-helper.sh"
install -m 644 "$repo/LICENSE" "$setup/LICENSE.txt"
install -m 644 "$repo/assets/fonts/OFL.txt" "$setup/licenses/OFL-Poppins.txt"
install -m 644 "$repo/assets/fonts/LICENSE-Syncopate-Apache2.txt" "$setup/licenses/Apache-2.0-Syncopate.txt"

# Payload: the app bundle under app/, deterministic tar (sorted, fixed owner
# and mtime), then its SHA-256 for the engine's check.
cp -a "$app/." "$work/payload/app/"
tar --sort=name --mtime="@$SOURCE_DATE_EPOCH" --owner=0 --group=0 --numeric-owner \
  -C "$work/payload" -cf - app | gzip -n -9 > "$setup/payload.tar.gz"
(cd "$setup" && sha256sum payload.tar.gz > payload.sha256)
size=$(du -sb "$work/payload/app" | cut -f1)
{
  grep -v '^#' "$repo/installer/posix/product.env"
  echo "DIR_NAME=linefm-radio"
  echo "VERSION=$version"
  echo "SIZE=$size"
} > "$setup/product.env"

cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
HERE=$(dirname "$(readlink -f "$0")")
exec "$HERE/usr/lib/linefm-setup/linefm_setup" "$@"
EOF
chmod 755 "$appdir/AppRun"
cat > "$appdir/de.linefm.setup.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=LINEFM Radio Setup
Comment=Installs LINEFM Radio
Exec=linefm_setup
Icon=de.linefm.setup
Terminal=false
Categories=Utility;
EOF
cp "$repo/linux/assets/icons/hicolor/256x256/apps/de.linefm.app.png" "$appdir/de.linefm.setup.png"

rm -f "$out"
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$tools/appimagetool" \
  --runtime-file "$tools/runtime-x86_64" --no-appstream "$appdir" "$out"
chmod 755 "$out"
ls -la "$out"
