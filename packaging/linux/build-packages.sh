#!/usr/bin/env bash
# Builds the Linux packages of the app itself from the Flutter release bundle:
#   .deb      (Debian, Ubuntu, Mint)      with dpkg-deb
#   .rpm      (Fedora, openSUSE, RHEL)    with rpmbuild
#   AppImage  (any distribution)          with the pinned appimagetool
#
#   packaging/linux/build-packages.sh --version X.Y.Z[-pre][+build] \
#     --app build/linux/x64/release/bundle --out dist [--formats deb,rpm,appimage]
#
# Output names: linefm-radio-<version>-linux-x64.{deb,rpm,AppImage}.
# Layout of deb and rpm: bundle in /usr/lib/linefm-radio, command
# /usr/bin/linefm-radio, desktop entry with the linefm:// handler, hicolor icons
# and AppStream metainfo. /usr/lib is used on purpose: the graphical installer
# owns /opt/linefm-radio for its "all users" mode.
#
# Needs: dpkg-deb, rpmbuild, objdump, sha256sum and for the AppImage the
# appimagetool and runtime from installer/linux/fetch-appimagetool.sh.
set -euo pipefail

version=""; app=""; out=""; formats="deb,rpm,appimage"
while [ $# -gt 0 ]; do
  case "$1" in
    --version) version=$2; shift 2 ;;
    --app) app=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    --formats) formats=$2; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ "$version" =~ ^([0-9]+\.[0-9]+\.[0-9]+)(-([0-9A-Za-z.-]+))?(\+([0-9A-Za-z.-]+))?$ ]] || { echo "bad version: $version" >&2; exit 2; }
numeric=${BASH_REMATCH[1]}; pre=${BASH_REMATCH[3]}; build=${BASH_REMATCH[5]}
[ -x "$app/linefm_radio" ] || { echo "app bundle missing: $app" >&2; exit 2; }
[ -n "$out" ] || { echo "--out missing" >&2; exit 2; }

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
app=$(cd "$app" && pwd)
mkdir -p "$out"
out=$(cd "$out" && pwd)
tools=${APPIMAGE_TOOLS:-$repo/build/installer/tools}
work=$repo/build/packages
export SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(git -C "$repo" log -1 --format=%ct)}

name=linefm-radio
app_id=de.linefm.app
summary="Live radio of the LINEFM stations"
description="Desktop app for the LINEFM web radio stations: live streams, now playing, favorites and alarm."
homepage=https://app.linefm.de
maintainer="Tim Hauke (VectoDE) <VectoDE@users.noreply.github.com>"
vendor="LineFM Studios"
# All rights reserved (see LICENSE), so no SPDX list identifier applies.
license=LicenseRef-LINEFM-Proprietary

rm -rf "$work"
mkdir -p "$work"

# --- shared file tree (deb and rpm) ----------------------------------------------
root=$work/root
lib=$root/usr/lib/$name
mkdir -p "$lib" "$root/usr/bin" "$root/usr/share/applications" "$root/usr/share/metainfo" \
  "$root/usr/share/doc/$name"
cp -a "$app/." "$lib/"
# libdartjni.so comes with the jni plugin, used only by Android plugins
# (Sentry, path_provider, shared_preferences). Nothing loads it on Linux, and it links libjvm.so,
# which would pull a Java runtime into the package dependencies.
rm -f "$lib/lib/libdartjni.so"
ln -s "../lib/$name/linefm_radio" "$root/usr/bin/$name"
sed "s|^Exec=.*|Exec=$name %U|" "$repo/linux/$app_id.desktop" > "$root/usr/share/applications/$app_id.desktop"
install -m 644 "$repo/linux/$app_id.metainfo.xml" "$root/usr/share/metainfo/$app_id.metainfo.xml"
for icon in "$repo"/linux/assets/icons/hicolor/*/apps/"$app_id".png; do
  size=$(basename "$(dirname "$(dirname "$icon")")")
  install -Dm 644 "$icon" "$root/usr/share/icons/hicolor/$size/apps/$app_id.png"
done
install -m 644 "$repo/LICENSE" "$root/usr/share/doc/$name/copyright"
find "$root" -type d -exec chmod 755 {} +
find "$root" -type f -exec chmod u+rw,go+r,go-w {} +
find "$root" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +

# Shared libraries the bundle needs from the system: NEEDED entries of every
# ELF file that are not shipped in the bundle itself.
elfs=()
while IFS= read -r -d '' f; do
  if head -c 4 "$f" | grep -q $'\x7fELF'; then elfs+=("$f"); fi
done < <(find "$lib" -type f -print0)
bundled=$(find "$lib" -type f -name '*.so*' -printf '%f\n' | sort -u)
system_libs=$(for f in "${elfs[@]}"; do objdump -p "$f" | awk '$1 == "NEEDED" {print $2}'; done \
  | sort -u | grep -vxF -f <(printf '%s\n' "$bundled" ld-linux-x86-64.so.2) || true)
glibc=$(for f in "${elfs[@]}"; do objdump -T "$f" 2>/dev/null; done | grep -o 'GLIBC_[0-9.]*' | sed 's/GLIBC_//' | sort -uV | tail -n1)
[ -n "$glibc" ] || { echo "could not determine the glibc version" >&2; exit 1; }
installed_size=$(du -sk "$root" | cut -f1)
echo "system libraries: $(echo "$system_libs" | tr '\n' ' ')"
echo "minimum glibc: $glibc"

has() { [[ ",$formats," == *",$1,"* ]]; }

# --- .deb ------------------------------------------------------------------------
if has deb; then
  debver=$numeric${pre:+~${pre//-/.}}${build:++${build//-/.}}-1
  deb=$work/deb
  cp -a "$root" "$deb"
  mkdir -p "$deb/DEBIAN"
  # Package names as on Ubuntu 24.04 and Debian 13 (t64 names) with the older
  # names as alternatives. CI checks that every system library resolves.
  cat > "$deb/DEBIAN/control" <<EOF
Package: $name
Version: $debver
Architecture: amd64
Maintainer: $maintainer
Installed-Size: $installed_size
Depends: libc6 (>= $glibc), libstdc++6, libgtk-3-0t64 | libgtk-3-0, libmpv2, libayatana-appindicator3-1, libkeybinder-3.0-0, libcurl4t64 | libcurl4, libegl1, libgles2
Recommends: xdg-utils
Section: sound
Priority: optional
Homepage: $homepage
Description: $summary
 $description
 Publisher: $vendor. Manufacturer: Tim Hauke.
EOF
  cat > "$deb/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database -q /usr/share/applications || true; fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true; fi
exit 0
EOF
  cp "$deb/DEBIAN/postinst" "$deb/DEBIAN/postrm"
  chmod 755 "$deb/DEBIAN/postinst" "$deb/DEBIAN/postrm"
  touch -d "@$SOURCE_DATE_EPOCH" "$deb/DEBIAN" "$deb/DEBIAN"/*
  dpkg-deb --root-owner-group -Zxz --build "$deb" "$out/$name-$version-linux-x64.deb"
  dpkg-deb --info "$out/$name-$version-linux-x64.deb"
fi

# --- .rpm ------------------------------------------------------------------------
if has rpm; then
  rpmver=$numeric${pre:+~${pre//-/.}}${build:+^${build//-/.}}
  top=$work/rpm
  mkdir -p "$top"/{BUILD,RPMS,SOURCES,SPECS,SRPMS,BUILDROOT}
  # Requirements as sonames (libmpv.so.2()(64bit) etc.), so dnf and zypper
  # pick the right package on every distribution.
  # GTK opens EGL and GLES at run time (dlopen), so they are not NEEDED
  # entries; without them the app aborts on start.
  requires=$( (echo "$system_libs"; printf '%s
' libEGL.so.1 libGLESv2.so.2)     | sed '/^$/d' | sort -u | sed 's/.*/Requires: &()(64bit)/')
  cat > "$top/SPECS/$name.spec" <<EOF
%global debug_package %{nil}
%global __os_install_post %{nil}
%define _build_id_links none
%define _source_date_epoch_from_changelog 0
%define use_source_date_epoch_as_buildtime 1
%define build_mtime_policy clamp_to_source_date_epoch
Name: $name
Version: $rpmver
Release: 1
Summary: $summary
License: $license
URL: $homepage
Vendor: $vendor
Packager: $maintainer
AutoReqProv: no
Requires: libc.so.6(GLIBC_$glibc)(64bit)
$requires
Recommends: xdg-utils

%description
$description
Publisher: $vendor. Manufacturer: Tim Hauke.

%install
mkdir -p %{buildroot}
cp -a $root/. %{buildroot}/

%post
update-desktop-database -q /usr/share/applications >/dev/null 2>&1 || :
gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor >/dev/null 2>&1 || :

%postun
update-desktop-database -q /usr/share/applications >/dev/null 2>&1 || :
gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor >/dev/null 2>&1 || :

%files
%license /usr/share/doc/$name/copyright
/usr/lib/$name
/usr/bin/$name
/usr/share/applications/$app_id.desktop
/usr/share/metainfo/$app_id.metainfo.xml
/usr/share/icons/hicolor/*/apps/$app_id.png
EOF
  rpmbuild --quiet --define "_topdir $top" --target x86_64 -bb "$top/SPECS/$name.spec"
  cp "$top"/RPMS/x86_64/*.rpm "$out/$name-$version-linux-x64.rpm"
  rpm -qpiR "$out/$name-$version-linux-x64.rpm"
fi

# --- AppImage --------------------------------------------------------------------
if has appimage; then
  appdir=$work/AppDir
  mkdir -p "$appdir/usr/lib" "$appdir/usr/share/applications" "$appdir/usr/share/metainfo"
  cp -a "$lib" "$appdir/usr/lib/$name"
  cp -a "$root/usr/share/icons" "$appdir/usr/share/icons"
  sed "s|^Exec=.*|Exec=linefm_radio %U|" "$repo/linux/$app_id.desktop" > "$appdir/$app_id.desktop"
  cp "$appdir/$app_id.desktop" "$appdir/usr/share/applications/$app_id.desktop"
  install -m 644 "$repo/linux/$app_id.metainfo.xml" "$appdir/usr/share/metainfo/$app_id.appdata.xml"
  cp "$repo/linux/assets/icons/hicolor/256x256/apps/$app_id.png" "$appdir/$app_id.png"
  ln -s "$app_id.png" "$appdir/.DirIcon"
  cat > "$appdir/AppRun" <<EOF
#!/bin/sh
HERE=\$(dirname "\$(readlink -f "\$0")")
exec "\$HERE/usr/lib/$name/linefm_radio" "\$@"
EOF
  chmod 755 "$appdir/AppRun"
  target="$out/$name-$version-linux-x64.AppImage"
  rm -f "$target"
  ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$tools/appimagetool" \
    --runtime-file "$tools/runtime-x86_64" --no-appstream "$appdir" "$target"
  chmod 755 "$target"
fi

ls -la "$out"
