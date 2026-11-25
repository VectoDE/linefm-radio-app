#!/bin/sh
# LINEFM Radio installer engine for macOS and Linux.
#
# Counterpart of the Windows engine (installer/windows/engine). The shared
# setup UI (installer/ui) starts it as a child process and reads the same
# line protocol on stdout:
#   hello | phase <name> | progress <done> <total> | running <app>
#   log <text> | result <code> <message>
# Answers ("close", "keep", "cancel") arrive on stdin.
#
# Commands:
#   engine.sh context
#   engine.sh install --scope user|machine [--dir DIR] --desktop 0|1
#                     --startmenu 0|1 --autostart 0|1
#   engine.sh uninstall --target DIR [--delete-user-data]
#
# Security properties (same as on Windows):
# - The payload is only used after its SHA-256 matches payload.sha256.
# - No privilege escalation: everything runs as the signed-in user. Linux
#   installs per user only; macOS "everyone" needs a writable /Applications
#   (admin account), otherwise exit code 7.
# - Paths are validated (absolute, no "..", no control or shell characters,
#   inside the allowed roots), never passed through eval, and existing
#   symlinks are not followed when replacing or deleting.
# - product.env and the install record are parsed as KEY=VALUE text, never
#   sourced.
set -u
umask 022
# Keep going if the UI disappears mid-way: finishing (or rolling back) is
# safer than stopping half way.
trap "" PIPE
LC_ALL=C
export LC_ALL

# Exit codes (installer/windows/engine/src/common/base.h).
EX_OK=0; EX_BADARGS=1; EX_CANCELLED=2; EX_FAILED=3; EX_CORRUPT=4
EX_RUNNING=5; EX_DOWNGRADE=6; EX_ELEVATION=7; EX_BADTARGET=8
EX_NOTINSTALLED=10; EX_DISKFULL=11; EX_OTHERSCOPE=12

SELF_DIR=$(cd "$(dirname "$0")" && pwd -P) || exit "$EX_FAILED"
PAYLOAD="$SELF_DIR/payload.tar.gz"
PAYLOAD_SUM="$SELF_DIR/payload.sha256"

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux) OS=linux ;;
  *) echo "result $EX_FAILED unsupported OS"; exit "$EX_FAILED" ;;
esac

# --- small helpers ---------------------------------------------------------

emit() { printf '%s\n' "$*"; }
log() { emit "log $*"; }

# Value of KEY from a KEY=VALUE file (first match, no evaluation).
kv() {
  [ -f "$1" ] || return 0
  sed -n "s/^$2=//p" "$1" | head -n 1
}

json_str() {
  printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
}

json_bool() { if [ "$1" = 1 ]; then printf true; else printf false; fi; }

# SemVer precedence: prints -1, 0 or 1 (like CompareVersions on Windows).
semver_cmp() {
  awk -v a="$1" -v b="$2" '
    function isnum(x) { return x ~ /^[0-9]+$/ }
    function cmp(x, y) {
      if (isnum(x) && isnum(y)) { x += 0; y += 0; return x < y ? -1 : (x > y ? 1 : 0) }
      if (isnum(x)) return -1
      if (isnum(y)) return 1
      return x < y ? -1 : (x > y ? 1 : 0)
    }
    BEGIN {
      sub(/\+.*/, "", a); sub(/\+.*/, "", b)
      pa = ""; pb = ""
      if (index(a, "-")) { pa = substr(a, index(a, "-") + 1); a = substr(a, 1, index(a, "-") - 1) }
      if (index(b, "-")) { pb = substr(b, index(b, "-") + 1); b = substr(b, 1, index(b, "-") - 1) }
      na = split(a, ca, "."); nb = split(b, cb, ".")
      for (i = 1; i <= 3; i++) {
        x = (i <= na) ? ca[i] : "0"; y = (i <= nb) ? cb[i] : "0"
        c = cmp(x, y); if (c != 0) { print c; exit }
      }
      if (pa == "" && pb == "") { print 0; exit }
      if (pa == "") { print 1; exit }
      if (pb == "") { print -1; exit }
      na = split(pa, xa, "."); nb = split(pb, xb, ".")
      for (i = 1; i <= na && i <= nb; i++) { c = cmp(xa[i], xb[i]); if (c != 0) { print c; exit } }
      print (na < nb) ? -1 : (na > nb ? 1 : 0)
    }'
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# --- product data and locations --------------------------------------------

PRODUCT="$SELF_DIR/product.env"
P_NAME=$(kv "$PRODUCT" NAME); P_NAME=${P_NAME:-LINEFM Radio}
P_VERSION=$(kv "$PRODUCT" VERSION)
P_PUBLISHER=$(kv "$PRODUCT" PUBLISHER)
P_MANUFACTURER=$(kv "$PRODUCT" MANUFACTURER)
P_URL=$(kv "$PRODUCT" URL)
P_APP_ID=$(kv "$PRODUCT" APP_ID); P_APP_ID=${P_APP_ID:-de.linefm.app}
P_SCHEME=$(kv "$PRODUCT" SCHEME); P_SCHEME=${P_SCHEME:-linefm}
P_EXE=$(kv "$PRODUCT" EXE); P_EXE=${P_EXE:-linefm_radio}
P_DIR_NAME=$(kv "$PRODUCT" DIR_NAME)
P_SIZE=$(kv "$PRODUCT" SIZE)
case "$P_SIZE" in ''|*[!0-9]*) P_SIZE=0 ;; esac

[ -n "${HOME:-}" ] && [ -d "$HOME" ] || { emit "result $EX_FAILED HOME not set"; exit "$EX_FAILED"; }
HOME_DIR=$(cd "$HOME" && pwd -P)

if [ "$OS" = macos ]; then
  P_DIR_NAME=${P_DIR_NAME:-$P_NAME.app}
  P_UNINSTALLER="Uninstall $P_NAME.app"
  STATE_DIR="$HOME_DIR/Library/Application Support/$P_NAME Setup"
  USER_DIR="$HOME_DIR/Applications/$P_DIR_NAME"
  MACHINE_DIR="/Applications/$P_DIR_NAME"
  MACHINE_STATE="/Library/Application Support/$P_NAME Setup"
else
  P_DIR_NAME=${P_DIR_NAME:-linefm-radio}
  DATA_HOME=${XDG_DATA_HOME:-$HOME_DIR/.local/share}
  CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME_DIR/.config}
  STATE_DIR="$DATA_HOME/$P_DIR_NAME-setup"
  USER_DIR="$DATA_HOME/$P_DIR_NAME"
  MACHINE_DIR="/opt/$P_DIR_NAME"
  MACHINE_STATE="/var/lib/$P_DIR_NAME-setup"
fi
RECORD="$STATE_DIR/installed.env"
# "Everyone" installs are written by root-helper.sh to fixed paths; the
# record there is root-owned and only read here.
MACHINE_RECORD="$MACHINE_STATE/installed.env"
MARKER=".linefm-install"

# Directory is inside an allowed root and safe to hand to rm/mv. Prints the
# reason on failure.
check_dir() {
  d=$1; scope=$2
  case "$d" in /*) ;; *) echo "not absolute"; return 1 ;; esac
  case "$d" in */../*|*/..|*/./*|*/.|*//*) echo "not normalized"; return 1 ;; esac
  # No control or shell-special characters (desktop entries, plists).
  if printf '%s' "$d" | LC_ALL=C grep -q '[[:cntrl:]"`$\\]'; then
    echo "bad characters"; return 1
  fi
  [ ${#d} -le 400 ] || { echo "too long"; return 1; }
  parent=$(dirname "$d")
  if [ "$OS" = macos ]; then
    case "$d" in *.app) ;; *) echo "must end in .app"; return 1 ;; esac
    if [ "$scope" = machine ]; then
      [ "$parent" = /Applications ] || { echo "everyone: only /Applications"; return 1; }
    else
      case "$d" in "$HOME_DIR"/?*/?*) ;; *) echo "just me: only inside the home folder"; return 1 ;; esac
    fi
  else
    [ "$scope" = user ] || { echo "only per-user installs"; return 1; }
    case "$d" in "$HOME_DIR"/?*/?*|"$HOME_DIR"/?*) ;; *) echo "only inside the home folder"; return 1 ;; esac
    case "$d" in "$HOME_DIR"/.config|"$HOME_DIR"/.local|"$HOME_DIR"/.local/share|"$DATA_HOME"|"$HOME_DIR"/Desktop) echo "system folder"; return 1 ;; esac
  fi
  [ -L "$d" ] && { echo "is a symlink"; return 1; }
  return 0
}

# Existing folder belongs to this product (safe to replace or delete).
is_ours() {
  d=$1
  [ -d "$d" ] && [ ! -L "$d" ] || return 1
  if [ "$OS" = macos ]; then
    id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$d/Contents/Info.plist" 2>/dev/null)
    [ "$id" = "$P_APP_ID" ]
  else
    [ -f "$d/$MARKER" ]
  fi
}

# --- install record ----------------------------------------------------------

# Per-user record first (like the Windows engine), then the system-wide one.
READ_RECORD=$RECORD
[ -f "$READ_RECORD" ] || READ_RECORD=$MACHINE_RECORD
R_VERSION=$(kv "$READ_RECORD" VERSION)
R_SCOPE=$(kv "$READ_RECORD" SCOPE)
R_DIR=$(kv "$READ_RECORD" DIR)
R_DESKTOP=$(kv "$READ_RECORD" DESKTOP)
R_STARTMENU=$(kv "$READ_RECORD" STARTMENU)
R_AUTOSTART=$(kv "$READ_RECORD" AUTOSTART)

installed_json() {
  if [ -n "$R_VERSION" ] && [ "$R_SCOPE" = "$1" ]; then
    printf '{"version":%s,"scope":%s,"dir":%s,"desktop":%s,"startMenu":%s,"autostart":%s}' \
      "$(json_str "$R_VERSION")" "$(json_str "$R_SCOPE")" "$(json_str "$R_DIR")" \
      "$(json_bool "$R_DESKTOP")" "$(json_bool "$R_STARTMENU")" "$(json_bool "$R_AUTOSTART")"
  else
    printf null
  fi
}

cmd_context() {
  mode=install
  [ -f "$PAYLOAD" ] || mode=uninstall
  default_scope=user
  if [ "$OS" = macos ] && [ -w /Applications ]; then default_scope=machine; fi
  exe=$P_EXE
  [ "$OS" = macos ] && exe=""
  printf '{"os":%s,"mode":%s,"engine":%s,' "$(json_str "$OS")" "$(json_str "$mode")" "$(json_str "$SELF_DIR/engine.sh")"
  printf '"product":{"name":%s,"version":%s,"publisher":%s,"manufacturer":%s,"exe":%s,"url":%s,"dirName":%s},' \
    "$(json_str "$P_NAME")" "$(json_str "$P_VERSION")" "$(json_str "$P_PUBLISHER")" \
    "$(json_str "$P_MANUFACTURER")" "$(json_str "$exe")" "$(json_str "$P_URL")" "$(json_str "$P_DIR_NAME")"
  printf '"installed":{"user":%s,"machine":%s},' "$(installed_json user)" "$(installed_json machine)"
  printf '"defaults":{"scope":%s,"userDir":%s,"machineDir":%s,"desktop":true,"startMenu":true,"autostart":false},' \
    "$(json_str "$default_scope")" "$(json_str "$USER_DIR")" "$(json_str "$MACHINE_DIR")"
  printf '"elevated":true,"sizeBytes":%s,"target":%s}\n' "$P_SIZE" "$(json_str "$R_DIR")"
}

# --- control channel (answers from the UI) -----------------------------------

CTL=""
WORK=""
start_control() {
  WORK=$(mktemp -d "${TMPDIR:-/tmp}/linefm-setup.XXXXXX") || exit "$EX_FAILED"
  chmod 700 "$WORK"
  CTL="$WORK/control"
  : > "$CTL"
  # Background jobs get /dev/null as stdin unless it is redirected
  # explicitly, so the UI's stdin is handed over via fd 3.
  exec 3<&0
  cat <&3 >> "$CTL" &
  CTL_PID=$!
}

stop_control() {
  [ -n "${CTL_PID:-}" ] && kill "$CTL_PID" 2>/dev/null
  [ -n "$WORK" ] && rm -rf "$WORK"
}

cancel_requested() { grep -qx cancel "$CTL" 2>/dev/null; }

# Waits for "close", "keep" or "cancel" after a "running" question.
wait_answer() {
  # There is only one question per run, so the first answer counts (the UI
  # may even have answered before the question arrived).
  while :; do
    line=$(grep -E -x 'close|keep|cancel' "$CTL" | head -n 1)
    [ -n "$line" ] && { echo "$line"; return; }
    # stdin closed without an answer (UI gone): keep the app running.
    # (An exited reader may linger as a zombie, so look at its state.)
    case "$(ps -o stat= -p "$CTL_PID" 2>/dev/null)" in ''|Z*) echo keep; return ;; esac
    sleep 0.2
  done
}

finish() {
  code=$1; shift
  emit "result $code $*"
  stop_control
  exit "$code"
}

# --- running app --------------------------------------------------------------

app_pids() {
  if [ "$OS" = macos ]; then
    pgrep -u "$(id -u)" -x "$P_NAME" 2>/dev/null
  else
    pgrep -u "$(id -u)" -x "$P_EXE" 2>/dev/null
  fi
}

ensure_not_running() {
  pids=$(app_pids)
  [ -z "$pids" ] && return 0
  emit "running $P_NAME"
  answer=$(wait_answer)
  case "$answer" in
    close) ;;
    cancel) finish "$EX_CANCELLED" "Cancelled" ;;
    *) finish "$EX_RUNNING" "App is running" ;;
  esac
  emit "phase closing"
  echo "$pids" | xargs kill -TERM 2>/dev/null
  i=0
  while [ -n "$(app_pids)" ] && [ $i -lt 50 ]; do sleep 0.2; i=$((i + 1)); done
  pids=$(app_pids)
  if [ -n "$pids" ]; then
    log "App does not respond, forcing it to quit"
    echo "$pids" | xargs kill -KILL 2>/dev/null
    sleep 1
  fi
  [ -z "$(app_pids)" ] || finish "$EX_RUNNING" "App cannot be closed"
  log "Running app closed"
}

# --- desktop integration ------------------------------------------------------

desktop_dir() {
  d=""
  if [ "$OS" = linux ] && command -v xdg-user-dir >/dev/null 2>&1; then d=$(xdg-user-dir DESKTOP 2>/dev/null); fi
  [ -n "$d" ] && [ "$d" != "$HOME_DIR" ] || d="$HOME_DIR/Desktop"
  printf '%s' "$d"
}

xml_escape() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

dock_edit() { # add|remove DIR
  [ "$OS" = macos ] || return 0
  tmp="$WORK/dock.plist"
  defaults export com.apple.dock "$tmp" 2>/dev/null || { log "Dock settings not readable"; return 0; }
  url="file://$(printf '%s' "$2" | sed -e 's/%/%25/g' -e 's/ /%20/g')/"
  # The Dock may rewrite the URL of an entry (for example the resolved
  # path), so entries are matched by the bundle name as well.
  tail="/$(basename "$2" | sed -e 's/%/%25/g' -e 's/ /%20/g')/"
  pb=/usr/libexec/PlistBuddy
  i=0; found=""
  while label=$("$pb" -c "Print :persistent-apps:$i:tile-data:file-data:_CFURLString" "$tmp" 2>/dev/null) ||         "$pb" -c "Print :persistent-apps:$i" "$tmp" >/dev/null 2>&1; do
    case "$label" in
      "$url"|*"$tail") found="$i $found" ;;
    esac
    i=$((i + 1)); label=""
  done
  if [ "$1" = add ] && [ -z "$found" ]; then
    "$pb" -c "Add :persistent-apps:$i dict"         -c "Add :persistent-apps:$i:tile-type string file-tile"         -c "Add :persistent-apps:$i:tile-data dict"         -c "Add :persistent-apps:$i:tile-data:file-data dict"         -c "Add :persistent-apps:$i:tile-data:file-data:_CFURLString string $url"         -c "Add :persistent-apps:$i:tile-data:file-data:_CFURLStringType integer 15" "$tmp" >/dev/null 2>&1 || return 0
  elif [ "$1" = remove ] && [ -n "$found" ]; then
    # Highest index first, so the remaining indexes stay valid.
    log "Dock entries removed: $found"
    for n in $found; do
      "$pb" -c "Delete :persistent-apps:$n" "$tmp" >/dev/null 2>&1 || return 0
    done
  else
    return 0
  fi
  defaults import com.apple.dock "$tmp" 2>/dev/null && killall Dock 2>/dev/null
  return 0
}

launch_agent() { printf '%s' "$HOME_DIR/Library/LaunchAgents/$P_APP_ID.autostart.plist"; }

linux_entry() { # FILE NODISPLAY(0|1)
  {
    echo '[Desktop Entry]'
    echo 'Type=Application'
    echo "Name=$P_NAME"
    echo 'GenericName=Web Radio'
    echo 'GenericName[de]=Webradio'
    echo 'Comment=Live radio of the LINEFM stations'
    echo 'Comment[de]=Live-Radio der LINEFM-Sender'
    echo "Exec=\"$DIR/$P_EXE\" %U"
    echo "Icon=$P_APP_ID"
    echo 'Terminal=false'
    echo 'Categories=AudioVideo;Audio;Player;Music;'
    echo "MimeType=x-scheme-handler/$P_SCHEME;"
    echo 'StartupNotify=true'
    echo "StartupWMClass=$P_APP_ID"
    [ "$2" = 1 ] && echo 'NoDisplay=true'
    echo 'Actions=uninstall;'
    echo ''
    echo '[Desktop Action uninstall]'
    echo "Name=Uninstall $P_NAME"
    echo "Name[de]=$P_NAME deinstallieren"
    echo "Exec=\"$STATE_DIR/uninstaller/linefm_setup\""
  } > "$1"
}

remove_integration() { # DIR
  if [ "$OS" = macos ]; then
    alias_path="$(desktop_dir)/$P_NAME"
    if [ -L "$alias_path" ] && [ "$(readlink "$alias_path")" = "$1" ]; then rm -f "$alias_path"; fi
    dock_edit remove "$1"
    agent=$(launch_agent)
    if [ -f "$agent" ]; then
      launchctl bootout "gui/$(id -u)" "$agent" >/dev/null 2>&1
      rm -f "$agent"
    fi
  else
    rm -f "$DATA_HOME/applications/$P_APP_ID.desktop" \
          "$CONFIG_HOME/autostart/$P_APP_ID.desktop" \
          "$(desktop_dir)/$P_APP_ID.desktop"
    for icon in "$DATA_HOME"/icons/hicolor/*/apps/"$P_APP_ID".png; do
      [ -f "$icon" ] && rm -f "$icon"
    done
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DATA_HOME/applications" >/dev/null 2>&1
  fi
  return 0
}

add_integration() {
  if [ "$OS" = macos ]; then
    lsreg=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
    [ -x "$lsreg" ] && "$lsreg" -f "$DIR" >/dev/null 2>&1
    if [ "$DESKTOP" = 1 ]; then
      dd=$(desktop_dir)
      if [ -d "$dd" ] && [ ! -e "$dd/$P_NAME" ]; then ln -s "$DIR" "$dd/$P_NAME" && log "Desktop alias: $dd/$P_NAME"; fi
    fi
    [ "$STARTMENU" = 1 ] && dock_edit add "$DIR" && log "Dock entry added"
    if [ "$AUTOSTART" = 1 ]; then
      agent=$(launch_agent)
      mkdir -p "$(dirname "$agent")"
      {
        echo '<?xml version="1.0" encoding="UTF-8"?>'
        echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
        echo '<plist version="1.0"><dict>'
        echo "<key>Label</key><string>$P_APP_ID.autostart</string>"
        echo '<key>ProgramArguments</key><array><string>/usr/bin/open</string><string>-g</string>'
        echo "<string>$(xml_escape "$DIR")</string></array>"
        echo '<key>RunAtLoad</key><true/>'
        echo '</dict></plist>'
      } > "$agent"
      log "Login item: $agent"
    fi
  else
    apps="$DATA_HOME/applications"
    mkdir -p "$apps"
    nodisplay=1; [ "$STARTMENU" = 1 ] && nodisplay=0
    linux_entry "$apps/$P_APP_ID.desktop" "$nodisplay"
    for src in "$DIR"/share/icons/hicolor/*/apps/"$P_APP_ID".png; do
      [ -f "$src" ] || continue
      size=$(basename "$(dirname "$(dirname "$src")")")
      mkdir -p "$DATA_HOME/icons/hicolor/$size/apps"
      cp -f "$src" "$DATA_HOME/icons/hicolor/$size/apps/"
    done
    if [ "$DESKTOP" = 1 ]; then
      dd=$(desktop_dir)
      if [ -d "$dd" ]; then
        linux_entry "$dd/$P_APP_ID.desktop" 0
        chmod 755 "$dd/$P_APP_ID.desktop"
        command -v gio >/dev/null 2>&1 && gio set "$dd/$P_APP_ID.desktop" metadata::trusted true >/dev/null 2>&1
        log "Desktop shortcut: $dd/$P_APP_ID.desktop"
      fi
    fi
    if [ "$AUTOSTART" = 1 ]; then
      mkdir -p "$CONFIG_HOME/autostart"
      linux_entry "$CONFIG_HOME/autostart/$P_APP_ID.desktop" 1
      echo 'X-GNOME-Autostart-enabled=true' >> "$CONFIG_HOME/autostart/$P_APP_ID.desktop"
      log "Autostart: $CONFIG_HOME/autostart/$P_APP_ID.desktop"
    fi
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$apps" >/dev/null 2>&1
    command -v xdg-mime >/dev/null 2>&1 && xdg-mime default "$P_APP_ID.desktop" "x-scheme-handler/$P_SCHEME" >/dev/null 2>&1
  fi
  return 0
}

# Keeps a copy of the setup UI (without payload) as the uninstaller.
install_uninstaller() { # STAGING
  if [ "$OS" = macos ]; then
    src="$1/uninstaller/$P_UNINSTALLER"
    [ -d "$src" ] || { log "No uninstaller in the payload"; return 0; }
    rm -rf "${STATE_DIR:?}/${P_UNINSTALLER:?}"
    mv "$src" "$STATE_DIR/$P_UNINSTALLER"
  else
    bundle=$(dirname "$SELF_DIR")
    tmp="$STATE_DIR/.uninstaller.new"
    rm -rf "$tmp"
    cp -R "$bundle" "$tmp" || return 1
    rm -f "$tmp/setup/payload.tar.gz" "$tmp/setup/payload.sha256"
    rm -rf "$STATE_DIR/uninstaller"
    mv "$tmp" "$STATE_DIR/uninstaller"
  fi
}

write_record() {
  tmp="$STATE_DIR/.installed.env.new"
  {
    echo "VERSION=$P_VERSION"
    echo "SCOPE=$SCOPE"
    echo "DIR=$DIR"
    echo "DESKTOP=$DESKTOP"
    echo "STARTMENU=$STARTMENU"
    echo "AUTOSTART=$AUTOSTART"
  } > "$tmp" && mv -f "$tmp" "$RECORD"
}

# --- install -----------------------------------------------------------------

# --- progress -----------------------------------------------------------
# Units are bytes of the app: a fixed share for the hash check, the bytes of
# every extracted file, a fixed share for shortcuts and clean-up. 100 % is
# only reported right before the result.
plan_progress() {
  sizes="$WORK/sizes"
  if [ "$OS" = macos ]; then field=5; else field=3; fi
  tar -tzvf "$PAYLOAD" 2>/dev/null | awk -v f="$field" '{ s = $f; if (s !~ /^[0-9]+$/) s = 0; print s }' > "$sizes"
  BYTES=$(awk '{ t += $1 } END { printf "%d", t }' "$sizes")
  [ "${BYTES:-0}" -gt 0 ] 2>/dev/null || BYTES=1
  HASH_W=$((BYTES / 50 + 1))
  FIN_W=$((BYTES / 50 + 1))
  GRAND=$((HASH_W + BYTES + FIN_W))
}

cmd_install() {
  SCOPE=user; DIR=""; DESKTOP=1; STARTMENU=1; AUTOSTART=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --scope) SCOPE=${2:-}; shift 2 ;;
      --dir) DIR=${2:-}; shift 2 ;;
      --desktop) DESKTOP=${2:-}; shift 2 ;;
      --startmenu) STARTMENU=${2:-}; shift 2 ;;
      --autostart) AUTOSTART=${2:-}; shift 2 ;;
      *) finish "$EX_BADARGS" "Unknown argument" ;;
    esac
  done
  case "$SCOPE" in user|machine) ;; *) finish "$EX_BADARGS" "Bad scope" ;; esac
  for v in "$DESKTOP" "$STARTMENU" "$AUTOSTART"; do
    case "$v" in 0|1) ;; *) finish "$EX_BADARGS" "Bad option value" ;; esac
  done

  emit hello
  emit "phase prepare"
  log "Installation $P_NAME $P_VERSION ($OS)"
  [ -f "$PAYLOAD" ] && [ -f "$PAYLOAD_SUM" ] || finish "$EX_CORRUPT" "Payload missing"

  if [ -n "$R_VERSION" ]; then
    log "Existing: $R_VERSION in $R_DIR"
    [ "$R_SCOPE" = "$SCOPE" ] || finish "$EX_OTHERSCOPE" "Installed in the other scope"
    if [ "$(semver_cmp "$P_VERSION" "$R_VERSION")" = -1 ]; then
      finish "$EX_DOWNGRADE" "Newer version installed"
    fi
    DIR=$R_DIR
    log "Update: the existing folder is kept ($DIR)"
  fi
  [ -n "$DIR" ] || { if [ "$SCOPE" = machine ]; then DIR=$MACHINE_DIR; else DIR=$USER_DIR; fi; }

  if [ "$SCOPE" = machine ]; then
    install_machine
  fi
  if ! why=$(check_dir "$DIR" "$SCOPE"); then
    log "Destination rejected: $why"
    finish "$EX_BADTARGET" "$why"
  fi
  PARENT=$(dirname "$DIR")
  if [ "$SCOPE" = machine ] && [ ! -w "$PARENT" ]; then
    finish "$EX_ELEVATION" "No write access to $PARENT"
  fi
  if [ -e "$DIR" ] && ! is_ours "$DIR"; then
    log "Destination exists and does not belong to $P_NAME"
    finish "$EX_BADTARGET" "Destination folder is not empty"
  fi
  log "Destination: $DIR ($SCOPE)"

  expected=$(awk '{print $1; exit}' "$PAYLOAD_SUM")
  actual=$(sha256_of "$PAYLOAD")
  if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
    log "Payload hash mismatch"
    finish "$EX_CORRUPT" "Payload damaged"
  fi
  log "Payload SHA-256 verified"
  plan_progress
  emit "progress $HASH_W $GRAND"

  mkdir -p "$PARENT" "$STATE_DIR" || finish "$EX_BADTARGET" "Cannot create $PARENT"
  chmod 700 "$STATE_DIR"
  if [ "$P_SIZE" -gt 0 ]; then
    avail=$(df -Pk "$PARENT" | awk 'NR==2 {print $4}')
    need=$(( (P_SIZE / 1024) * 2 + 10240 ))
    case "$avail" in ''|*[!0-9]*) avail=$need ;; esac
    [ "$avail" -ge "$need" ] || finish "$EX_DISKFULL" "Not enough space"
  fi

  ensure_not_running
  cancel_requested && finish "$EX_CANCELLED" "Cancelled"

  emit "phase copying"
  base=$(basename "$DIR")
  STAGING="$PARENT/.$base.lfnew.$$"
  BACKUP="$PARENT/.$base.lfold.$$"
  rm -rf "$STAGING"
  mkdir -m 700 "$STAGING" || finish "$EX_FAILED" "Cannot create staging folder"
  # One verbose line per extracted entry, in archive order: add its size.
  tar -xzvf "$PAYLOAD" -C "$STAGING" 2>&1 | awk -v base="$HASH_W" -v grand="$GRAND" \
      -v sizes="$WORK/sizes" -v ctl="$CTL" '
    BEGIN { while ((getline l < sizes) > 0) sz[++n] = l }
    {
      i++; done += sz[i]
      if (i % 20 == 0) {
        printf "progress %d %d\n", base + done, grand; fflush()
        if (system("grep -qx cancel \"" ctl "\"") == 0) exit
      }
    }' 
  if cancel_requested; then
    emit "phase rollback"
    rm -rf "$STAGING"
    finish "$EX_CANCELLED" "Cancelled"
  fi
  if [ "$OS" = macos ]; then NEW="$STAGING/app/$P_DIR_NAME"; else NEW="$STAGING/app"; fi
  if [ ! -d "$NEW" ] || { [ "$OS" = linux ] && [ ! -x "$NEW/$P_EXE" ]; }; then
    rm -rf "$STAGING"
    finish "$EX_CORRUPT" "Payload incomplete"
  fi
  emit "progress $((HASH_W + BYTES)) $GRAND"
  [ "$OS" = linux ] && : > "$NEW/$MARKER"
  # The app itself stays user-writable only for its owner.
  chmod 755 "$NEW"

  if [ -e "$DIR" ]; then
    mv "$DIR" "$BACKUP" || { rm -rf "$STAGING"; finish "$EX_FAILED" "Cannot move the old version"; }
  fi
  if ! mv "$NEW" "$DIR"; then
    emit "phase rollback"
    [ -e "$BACKUP" ] && mv "$BACKUP" "$DIR"
    rm -rf "$STAGING"
    finish "$EX_FAILED" "Cannot move the new version into place"
  fi

  emit "phase registry"
  if [ -n "$R_VERSION" ]; then remove_integration "$DIR"; fi
  add_integration
  install_uninstaller "$STAGING" || log "Uninstaller could not be kept"
  if ! write_record; then
    emit "phase rollback"
    remove_integration "$DIR"
    rm -rf "$DIR"
    [ -e "$BACKUP" ] && mv "$BACKUP" "$DIR"
    rm -rf "$STAGING"
    finish "$EX_FAILED" "Cannot write the install record"
  fi

  emit "phase finalizing"
  rm -rf "$BACKUP" "$STAGING"
  emit "progress $GRAND $GRAND"
  log "Installation finished"
  finish "$EX_OK" "$DIR"
}

# --- uninstall ---------------------------------------------------------------

delete_user_data() {
  if [ "$OS" = macos ]; then
    set -- "$HOME_DIR/Library/Containers/$P_APP_ID" \
           "$HOME_DIR/Library/Application Support/$P_APP_ID" \
           "$HOME_DIR/Library/Preferences/$P_APP_ID.plist" \
           "$HOME_DIR/Library/Caches/$P_APP_ID"
  else
    set -- "$DATA_HOME/$P_APP_ID" "${XDG_CACHE_HOME:-$HOME_DIR/.cache}/$P_APP_ID"
  fi
  for p in "$@"; do
    if [ -e "$p" ] && [ ! -L "$p" ]; then
      log "Deleting user data: $p"
      rm -rf "$p"
    fi
  done
}

# --- everyone (system-wide) -------------------------------------------------

# Runs root-helper.sh with administrator rights. Only a verb and 0/1 flags
# are passed; the helper copies the staged files into a root-owned folder,
# checks the payload hash there and writes only to fixed system paths.
# Runs HELPER [ARGS...] with administrator rights; output to $out, exit code
# to $rc (written last, so $rc marks completion).
root_exec() {
  if [ "$(id -u)" = 0 ]; then
    /bin/sh "$@" > "$out" 2>&1; c=$?
  elif [ "${LF_SETUP_ELEVATE:-}" = sudo ]; then
    # CI test mode (passwordless sudo on the runner).
    # shellcheck disable=SC2024 # output files stay user-owned on purpose
    sudo -n /bin/sh "$@" > "$out" 2>&1; c=$?
  elif [ "$OS" = linux ]; then
    pkexec /bin/sh "$@" > "$out" 2>&1; c=$?
  else
    # Standard macOS administrator prompt. Script text is fixed; the helper
    # path and the flags are passed as arguments and quoted by AppleScript.
    # Output arrives only at the end here, so progress jumps on macOS.
    /usr/bin/osascript -e 'on run argv' \
      -e 'set cmd to "/bin/sh"' \
      -e 'repeat with a in argv' -e 'set cmd to cmd & " " & quoted form of (a as text)' -e 'end repeat' \
      -e 'do shell script cmd with administrator privileges' -e 'end run' \
      "$@" > "$out.r" 2>&1; c=$?
    tr '\r' '\n' < "$out.r" > "$out"
  fi
  echo "$c" > "$rc"
}


run_root() { # VERB [FLAGS...]
  elev="$WORK/elev"
  rm -rf "$elev"; mkdir -m 755 "$elev" || finish "$EX_FAILED" "Cannot stage"
  chmod 755 "$WORK"
  cp "$SELF_DIR/root-helper.sh" "$SELF_DIR/product.env" "$elev/" || finish "$EX_CORRUPT" "Helper missing"
  if [ "$1" = install ]; then
    cp "$PAYLOAD" "$PAYLOAD_SUM" "$elev/" || finish "$EX_CORRUPT" "Payload missing"
    if [ "$OS" = linux ]; then
      cp -R "$(dirname "$SELF_DIR")" "$elev/uninstaller" || finish "$EX_FAILED" "Cannot stage uninstaller"
      rm -f "$elev/uninstaller/setup/payload.tar.gz" "$elev/uninstaller/setup/payload.sha256"
    fi
  fi
  chmod -R a+rX "$elev"
  helper="$elev/root-helper.sh"
  rc="$WORK/root.rc"; out="$WORK/root.out"
  emit "phase elevating"
  if [ "$(id -u)" != 0 ] && [ "${LF_SETUP_ELEVATE:-}" != sudo ] && [ "$OS" = linux ]; then
    command -v pkexec >/dev/null 2>&1 || finish "$EX_ELEVATION" "pkexec (polkit) is not installed"
  fi
  : > "$out"; rm -f "$rc"
  # The helper runs in the background; its byte progress is mapped live onto
  # our scale (the extraction share between HASH_W and HASH_W + BYTES).
  root_exec "$helper" "$@" &
  hp=$!
  last=""
  while :; do
    line=$(grep -E '^progress [0-9]+ [0-9]+$' "$out" 2>/dev/null | tail -n 1 \
      | awk -v base="${HASH_W:-0}" -v bytes="${BYTES:-0}" -v grand="${GRAND:-0}" \
          '$3 > 0 && grand > 0 { printf "progress %d %d", base + int(bytes * ($2 / $3)), grand }')
    if [ -n "$line" ] && [ "$line" != "$last" ]; then emit "$line"; last=$line; fi
    [ -f "$rc" ] && break
    kill -0 "$hp" 2>/dev/null || { sleep 0.2; [ -f "$rc" ] || echo 1 > "$rc"; break; }
    sleep 0.3
  done
  wait "$hp" 2>/dev/null
  code=$(cat "$rc")
  # Forward the helper's log (progress units are the engine's), keep its
  # result for us.
  grep -E '^log ' "$out" | while IFS= read -r line; do emit "$line"; done
  result=$(grep -E '^result [0-9]+' "$out" | tail -n 1 | awk '{print $2}')
  if [ -z "$result" ]; then
    # No result line: the prompt was dismissed or polkit has no agent.
    log "Elevation failed ($code): $(grep -v -E '^(log|progress|result) ' "$out" | head -n 3 | tr '\n' ' ')"
    finish "$EX_ELEVATION" "Administrator rights were not granted"
  fi
  [ "$result" = 0 ] || finish "$result" "$(grep -E '^result ' "$out" | tail -n 1 | cut -d' ' -f3-)"
}

install_machine() {
  [ "$DIR" = "$MACHINE_DIR" ] || finish "$EX_BADTARGET" "Everyone: fixed folder $MACHINE_DIR"
  expected=$(awk '{print $1; exit}' "$PAYLOAD_SUM")
  [ -n "$expected" ] && [ "$expected" = "$(sha256_of "$PAYLOAD")" ] || finish "$EX_CORRUPT" "Payload damaged"
  log "Destination: $DIR (everyone)"
  plan_progress
  emit "progress $HASH_W $GRAND"
  ensure_not_running
  cancel_requested && finish "$EX_CANCELLED" "Cancelled"
  emit "phase copying"
  run_root install --desktop-entry "$STARTMENU" --autostart "$AUTOSTART" --desktop "$DESKTOP"
  emit "progress $((HASH_W + BYTES)) $GRAND"
  emit "phase registry"
  # Per-user parts stay with the user: desktop shortcut on Linux; desktop
  # alias, Dock and login item on macOS.
  STATE_DIR=$MACHINE_STATE
  if [ "$OS" = macos ]; then
    add_integration
  elif [ "$DESKTOP" = 1 ]; then
    dd=$(desktop_dir)
    if [ -d "$dd" ]; then
      linux_entry "$dd/$P_APP_ID.desktop" 0
      chmod 755 "$dd/$P_APP_ID.desktop"
      command -v gio >/dev/null 2>&1 && gio set "$dd/$P_APP_ID.desktop" metadata::trusted true >/dev/null 2>&1
    fi
  fi
  emit "phase finalizing"
  emit "progress $GRAND $GRAND"
  finish "$EX_OK" "$DIR"
}

cmd_uninstall() {
  TARGET=""; DELETE_DATA=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --target) TARGET=${2:-}; shift 2 ;;
      --delete-user-data) DELETE_DATA=1; shift ;;
      *) finish "$EX_BADARGS" "Unknown argument" ;;
    esac
  done
  emit hello
  emit "phase prepare"
  if [ -z "$R_VERSION" ] || [ -z "$TARGET" ] || [ "$TARGET" != "$R_DIR" ]; then
    finish "$EX_NOTINSTALLED" "Not installed"
  fi
  DIR=$R_DIR
  if [ "$R_SCOPE" = machine ]; then
    [ "$DIR" = "$MACHINE_DIR" ] || finish "$EX_BADTARGET" "Unexpected folder"
    log "Uninstalling from $DIR (everyone)"
    ensure_not_running
    emit "phase removing"
    run_root uninstall
    if [ "$OS" = macos ]; then
      remove_integration "$DIR"
    else
      f="$(desktop_dir)/$P_APP_ID.desktop"
      [ -f "$f" ] && rm -f "$f"
    fi
    [ "$DELETE_DATA" = 1 ] && delete_user_data
    rm -rf "$STATE_DIR"
    log "Uninstall finished"
    finish "$EX_OK" ""
  fi
  if ! why=$(check_dir "$DIR" "$R_SCOPE"); then
    finish "$EX_BADTARGET" "$why"
  fi
  log "Uninstalling from $DIR"
  ensure_not_running
  emit "phase removing"
  # Units: one per file of the app, plus one each for the entries and the
  # user data.
  files=0
  is_ours "$DIR" && files=$(find "$DIR" | wc -l | tr -d ' ')
  total=$((files + 2))
  emit "progress 0 $total"
  remove_integration "$DIR"
  emit "progress 1 $total"
  if [ -e "$DIR" ]; then
    if is_ours "$DIR"; then
      # Delete file by file (depth first) so progress follows real work.
      find "$DIR" -depth -print | {
        n=0
        while IFS= read -r f; do
          if [ -d "$f" ] && [ ! -L "$f" ]; then rmdir "$f" 2>/dev/null; else rm -f "$f"; fi
          n=$((n + 1))
          [ $((n % 20)) -eq 0 ] && emit "progress $((1 + n)) $total"
        done
      }
      rm -rf "$DIR" || finish "$EX_FAILED" "Cannot remove $DIR"
    else
      log "Folder does not belong to $P_NAME, left in place: $DIR"
    fi
  fi
  emit "progress $((files + 1)) $total"
  [ "$DELETE_DATA" = 1 ] && delete_user_data
  # The record folder holds this uninstaller; deleting it while it runs is
  # fine on POSIX systems.
  rm -rf "$STATE_DIR"
  emit "progress $total $total"
  log "Uninstall finished"
  finish "$EX_OK" ""
}

cmd=${1:-}
[ $# -gt 0 ] && shift
case "$cmd" in
  context) cmd_context ;;
  install) start_control; cmd_install "$@" ;;
  uninstall) start_control; cmd_uninstall "$@" ;;
  *) echo "usage: engine.sh context|install|uninstall" >&2; exit "$EX_BADARGS" ;;
esac
