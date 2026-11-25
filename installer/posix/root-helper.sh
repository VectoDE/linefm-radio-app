#!/bin/sh
# Root part of the macOS/Linux installer (#88): "install for everyone".
#
# Started by engine.sh through pkexec (Linux), osascript "with administrator
# privileges" (macOS) or "sudo -n" (CI test mode). It takes no paths: the
# only inputs are a verb and 0/1 flags. Sources are the files next to this
# script (staged by the engine), targets are fixed system paths:
#   Linux: /opt/linefm-radio, /usr/share/applications, /usr/share/icons/hicolor,
#          /usr/local/bin/linefm-radio, /etc/xdg/autostart (optional),
#          record and uninstaller in /var/lib/linefm-radio-setup
#   macOS: /Applications/LINEFM Radio.app, record and uninstaller in
#          /Library/Application Support/LINEFM Radio Setup
# The payload is copied into a root-owned temporary folder first and its
# SHA-256 is checked there, so nothing can swap it between check and use.
# Symlinks at any target are refused.
#
#   root-helper.sh install --desktop-entry 0|1 --autostart 0|1 --desktop 0|1
#   root-helper.sh uninstall
# Prints the engine's line protocol (log/progress/result) and exits with the
# engine's exit codes.
set -u
umask 022
trap "" PIPE
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
LC_ALL=C
export LC_ALL

EX_OK=0; EX_BADARGS=1; EX_FAILED=3; EX_CORRUPT=4; EX_DOWNGRADE=6
EX_ELEVATION=7; EX_BADTARGET=8; EX_NOTINSTALLED=10

emit() { printf '%s\n' "$*"; }
log() { emit "log [root] $*"; }
TMP=""
finish() { [ -n "$TMP" ] && rm -rf "$TMP"; emit "result $1 $2"; exit "$1"; }

[ "$(id -u)" = 0 ] || finish "$EX_ELEVATION" "Helper needs administrator rights"
SRC=$(cd "$(dirname "$0")" && pwd -P) || finish "$EX_FAILED" "No source folder"

kv() { [ -f "$1" ] && sed -n "s/^$2=//p" "$1" | head -n 1; }
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'; fi
}

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux) OS=linux ;;
  *) finish "$EX_FAILED" "Unsupported OS" ;;
esac

# Fixed product identity (never taken from the staged files).
APP_ID=de.linefm.app
SCHEME=linefm
if [ "$OS" = macos ]; then
  DIR="/Applications/LINEFM Radio.app"
  STATE="/Library/Application Support/LINEFM Radio Setup"
else
  DIR=/opt/linefm-radio
  STATE=/var/lib/linefm-radio-setup
  APPS=/usr/share/applications
  ICONS=/usr/share/icons/hicolor
  BIN=/usr/local/bin/linefm-radio
  AUTOSTART=/etc/xdg/autostart/$APP_ID.desktop
fi
RECORD="$STATE/installed.env"

no_link() { # refuse symlinks on a target path and its parent
  for p in "$1" "$(dirname "$1")"; do
    [ -L "$p" ] && finish "$EX_BADTARGET" "Symlink refused: $p"
  done
  return 0
}

semver_lt() { # A < B ?
  awk -v a="$1" -v b="$2" 'function n(x){return x ~ /^[0-9]+$/}
    function c(x,y){ if(n(x)&&n(y)){x+=0;y+=0;return x<y?-1:(x>y?1:0)} if(n(x))return -1; if(n(y))return 1; return x<y?-1:(x>y?1:0)}
    BEGIN{sub(/\+.*/,"",a);sub(/\+.*/,"",b);pa="";pb=""
      if(index(a,"-")){pa=substr(a,index(a,"-")+1);a=substr(a,1,index(a,"-")-1)}
      if(index(b,"-")){pb=substr(b,index(b,"-")+1);b=substr(b,1,index(b,"-")-1)}
      split(a,x,".");split(b,y,".")
      for(i=1;i<=3;i++){r=c(x[i]==""?0:x[i],y[i]==""?0:y[i]);if(r){print (r<0);exit}}
      if(pa==""&&pb==""){print 0;exit} if(pa==""){print 0;exit} if(pb==""){print 1;exit}
      na=split(pa,p,".");nb=split(pb,q,".")
      for(i=1;i<=na&&i<=nb;i++){r=c(p[i],q[i]);if(r){print (r<0);exit}}
      print (na<nb)}'
}

entry() { # FILE NODISPLAY
  {
    echo '[Desktop Entry]'
    echo 'Type=Application'
    echo 'Name=LINEFM Radio'
    echo 'GenericName=Web Radio'
    echo 'GenericName[de]=Webradio'
    echo 'Comment=Live radio of the LINEFM stations'
    echo 'Comment[de]=Live-Radio der LINEFM-Sender'
    echo "Exec=$DIR/linefm_radio %U"
    echo "Icon=$APP_ID"
    echo 'Terminal=false'
    echo 'Categories=AudioVideo;Audio;Player;Music;'
    echo "MimeType=x-scheme-handler/$SCHEME;"
    echo 'StartupNotify=true'
    echo "StartupWMClass=$APP_ID"
    [ "$2" = 1 ] && echo 'NoDisplay=true'
    echo 'Actions=uninstall;'
    echo ''
    echo '[Desktop Action uninstall]'
    echo 'Name=Uninstall LINEFM Radio'
    echo 'Name[de]=LINEFM Radio deinstallieren'
    echo "Exec=$STATE/uninstaller/linefm_setup"
  } > "$1"
}

remove_system() {
  if [ "$OS" = linux ]; then
    for f in "$APPS/$APP_ID.desktop" "$AUTOSTART" "$BIN"; do
      { [ -f "$f" ] || [ -L "$f" ]; } && rm -f "$f"
    done
    for f in "$ICONS"/*/apps/"$APP_ID".png; do [ -f "$f" ] && rm -f "$f"; done
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" >/dev/null 2>&1
  fi
  return 0
}

cmd_install() {
  ENTRY=1; AUTO=0; DESK=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --desktop-entry) ENTRY=${2:-}; shift 2 ;;
      --autostart) AUTO=${2:-}; shift 2 ;;
      --desktop) DESK=${2:-}; shift 2 ;;
      *) finish "$EX_BADARGS" "Unknown argument" ;;
    esac
  done
  for v in "$ENTRY" "$AUTO" "$DESK"; do case "$v" in 0|1) ;; *) finish "$EX_BADARGS" "Bad flag" ;; esac; done

  VERSION=$(kv "$SRC/product.env" VERSION)
  case "$VERSION" in ''|*[!0-9A-Za-z.+-]*) finish "$EX_BADARGS" "Bad version" ;; esac
  OLD=$(kv "$RECORD" VERSION)
  if [ -n "$OLD" ] && [ "$(semver_lt "$VERSION" "$OLD")" = 1 ]; then
    finish "$EX_DOWNGRADE" "Newer version installed"
  fi
  no_link "$DIR"; no_link "$STATE"
  if [ -e "$DIR" ] && [ -z "$OLD" ]; then
    if [ "$OS" = macos ]; then
      id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DIR/Contents/Info.plist" 2>/dev/null)
      [ "$id" = "$APP_ID" ] || finish "$EX_BADTARGET" "Destination belongs to another app"
    else
      [ -f "$DIR/.linefm-install" ] || finish "$EX_BADTARGET" "Destination folder is not empty"
    fi
  fi

  # Root-owned copy, then verify: no swap possible between check and use.
  TMP=$(mktemp -d /tmp/linefm-root.XXXXXX) || finish "$EX_FAILED" "No temp folder"
  chmod 700 "$TMP"
  cp "$SRC/payload.tar.gz" "$TMP/payload.tar.gz" && cp "$SRC/payload.sha256" "$TMP/payload.sha256" \
    || finish "$EX_CORRUPT" "Payload missing"
  # Uninstaller (setup UI without payload): copied, never extracted, so it
  # cannot write outside its folder; symlinks stay links (cp -R does not
  # follow them).
  [ "$OS" = linux ] && { cp -R "$SRC/uninstaller" "$TMP/uninstaller" || finish "$EX_CORRUPT" "Uninstaller missing"; }
  expected=$(awk '{print $1; exit}' "$TMP/payload.sha256")
  [ -n "$expected" ] && [ "$expected" = "$(sha256_of "$TMP/payload.tar.gz")" ] || finish "$EX_CORRUPT" "Payload damaged"
  log "Payload SHA-256 verified as root"
  mkdir "$TMP/x" && tar -xzf "$TMP/payload.tar.gz" -C "$TMP/x" --no-same-owner 2>/dev/null \
    || tar -xzf "$TMP/payload.tar.gz" -C "$TMP/x" || finish "$EX_CORRUPT" "Payload unreadable"
  if [ "$OS" = macos ]; then NEW="$TMP/x/app/LINEFM Radio.app"; else NEW="$TMP/x/app"; fi
  [ -d "$NEW" ] || finish "$EX_CORRUPT" "Payload incomplete"
  chown -R 0:0 "$NEW" 2>/dev/null || chown -R 0:wheel "$NEW"
  chmod -R go-w "$NEW"
  [ "$OS" = linux ] && : > "$NEW/.linefm-install"
  emit "progress 1 3"

  parent=$(dirname "$DIR"); base=$(basename "$DIR")
  STAGE="$parent/.$base.lfnew.$$"; BACKUP="$parent/.$base.lfold.$$"
  mkdir -p "$parent"
  mv "$NEW" "$STAGE" 2>/dev/null || cp -R "$NEW" "$STAGE" || finish "$EX_FAILED" "Cannot stage"
  if [ -e "$DIR" ]; then mv "$DIR" "$BACKUP" || { rm -rf "$STAGE"; finish "$EX_FAILED" "Cannot move old version"; }; fi
  if ! mv "$STAGE" "$DIR"; then
    [ -e "$BACKUP" ] && mv "$BACKUP" "$DIR"; rm -rf "$STAGE"
    finish "$EX_FAILED" "Cannot move new version into place"
  fi
  rm -rf "$BACKUP"
  emit "progress 2 3"

  mkdir -p "$STATE"; chmod 755 "$STATE"
  if [ "$OS" = linux ]; then
    remove_system
    mkdir -p "$APPS"
    nd=1; [ "$ENTRY" = 1 ] && nd=0
    entry "$APPS/$APP_ID.desktop" "$nd"
    for src in "$DIR"/share/icons/hicolor/*/apps/"$APP_ID".png; do
      [ -f "$src" ] || continue
      size=$(basename "$(dirname "$(dirname "$src")")")
      mkdir -p "$ICONS/$size/apps" && cp -f "$src" "$ICONS/$size/apps/"
    done
    no_link "$BIN"; mkdir -p /usr/local/bin; ln -sf "$DIR/linefm_radio" "$BIN"
    if [ "$AUTO" = 1 ]; then
      mkdir -p /etc/xdg/autostart; entry "$AUTOSTART" 1
      echo 'X-GNOME-Autostart-enabled=true' >> "$AUTOSTART"
    fi
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" >/dev/null 2>&1
    rm -rf "$STATE/uninstaller"
    chown -R -h 0:0 "$TMP/uninstaller" && chmod -R go-w "$TMP/uninstaller" \
      && mv "$TMP/uninstaller" "$STATE/uninstaller" || log "Uninstaller could not be kept"
  else
    un="$TMP/x/uninstaller/Uninstall LINEFM Radio.app"
    if [ -d "$un" ]; then
      rm -rf "$STATE/Uninstall LINEFM Radio.app"
      chown -R 0:wheel "$un"; mv "$un" "$STATE/"
    fi
    lsreg=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
    [ -x "$lsreg" ] && "$lsreg" -f "$DIR" >/dev/null 2>&1
  fi
  {
    echo "VERSION=$VERSION"; echo "SCOPE=machine"; echo "DIR=$DIR"
    echo "DESKTOP=$DESK"; echo "STARTMENU=$ENTRY"; echo "AUTOSTART=$AUTO"
  } > "$RECORD.new" && chmod 644 "$RECORD.new" && mv -f "$RECORD.new" "$RECORD" || finish "$EX_FAILED" "Cannot write record"
  emit "progress 3 3"
  log "System-wide installation finished"
  finish "$EX_OK" "$DIR"
}

cmd_uninstall() {
  [ -f "$RECORD" ] || finish "$EX_NOTINSTALLED" "Not installed for everyone"
  no_link "$DIR"; no_link "$STATE"
  remove_system
  if [ -e "$DIR" ]; then
    if [ "$OS" = macos ]; then
      id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DIR/Contents/Info.plist" 2>/dev/null)
      [ "$id" = "$APP_ID" ] && rm -rf "$DIR"
    else
      [ -f "$DIR/.linefm-install" ] && rm -rf "$DIR"
    fi
  fi
  rm -rf "$STATE"
  log "System-wide uninstall finished"
  finish "$EX_OK" ""
}

cmd=${1:-}; [ $# -gt 0 ] && shift
case "$cmd" in
  install) cmd_install "$@" ;;
  uninstall) cmd_uninstall ;;
  *) finish "$EX_BADARGS" "usage: root-helper.sh install|uninstall" ;;
esac
