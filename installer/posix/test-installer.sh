#!/usr/bin/env bash
# Tests the macOS or Linux installer on a throwaway CI runner (#88):
# graphical install through the real setup UI (autopilot, screenshots of
# every step), installed files and desktop integration, app start, update,
# running-app protection, downgrade protection, damaged payload, unsafe
# destination, graphical uninstall with user data.
#
#   installer/posix/test-installer.sh --os linux|macos --setup <ui executable> \
#     --setup-dir <folder with engine.sh> --artifacts <folder>
#
# Changes the signed-in user's home (apps, desktop entries, Dock). Only run it
# on disposable machines such as GitHub runners.
set -uo pipefail

os=""; setup=""; setup_dir=""; art="build/installer-test"
while [ $# -gt 0 ]; do
  case "$1" in
    --os) os=$2; shift 2 ;;
    --setup) setup=$2; shift 2 ;;
    --setup-dir) setup_dir=$2; shift 2 ;;
    --artifacts) art=$2; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
mkdir -p "$art/screenshots" "$art/logs"
art=$(cd "$art" && pwd)
setup_dir=$(cd "$setup_dir" && pwd)
engine="$setup_dir/engine.sh"
failures=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }
check() { local what=$1; shift; if "$@"; then pass "$what"; else fail "$what"; fi; }

home=$(cd "$HOME" && pwd -P)
mkdir -p "$home/Desktop"
if [ "$os" = macos ]; then
  state="$home/Library/Application Support/LINEFM Radio Setup"
  data_dir="$home/Library/Containers/de.linefm.app"
else
  data_home=${XDG_DATA_HOME:-$home/.local/share}
  state="$data_home/linefm-radio-setup"
  data_dir="$data_home/de.linefm.app"
fi
record="$state/installed.env"
rec() { sed -n "s/^$1=//p" "$record" 2>/dev/null | head -n 1; }

run_ui() { # NAME EXECUTABLE [extra env...]
  local name=$1 exe=$2; shift 2
  echo "== UI: $name"
  env LF_SETUP_AUTOPILOT="$art/screenshots/$name" "$@" "$exe" > "$art/logs/$name-ui.log" 2>&1 &
  local pid=$!
  local waited=0
  while kill -0 "$pid" 2>/dev/null && [ $waited -lt 600 ]; do sleep 1; waited=$((waited + 1)); done
  if kill -0 "$pid" 2>/dev/null; then kill "$pid"; echo "timeout"; return 124; fi
  wait "$pid"
}

run_engine() { # LOGNAME DIR STDIN ARGS...
  local name=$1 dir=$2 input=$3; shift 3
  printf '%s' "$input" | /bin/sh "$dir/engine.sh" "$@" > "$art/logs/$name.log" 2>&1
}

app_running() {
  if [ "$os" = macos ]; then pgrep -x "LINEFM Radio" >/dev/null; else pgrep -x linefm_radio >/dev/null; fi
}

start_app() {
  if [ "$os" = macos ]; then open "$1"; else ("$1/linefm_radio" > "$art/logs/app.log" 2>&1 &); fi
  sleep 8
}

# --- context ------------------------------------------------------------------
/bin/sh "$engine" context > "$art/logs/context.json"
check "context is valid JSON" python3 -m json.tool "$art/logs/context.json" >/dev/null

# --- graphical install ----------------------------------------------------------
run_ui install "$setup"; code=$?
check "install through the UI exits 0 (got $code)" test "$code" = 0
dir=$(rec DIR)
echo "installed into: $dir"
check "install record written" test -n "$dir"
if [ "$os" = macos ]; then
  check "app bundle in place" test -x "$dir/Contents/MacOS/LINEFM Radio"
  check "bundle id" test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$dir/Contents/Info.plist")" = de.linefm.app
  check "desktop alias" test -L "$home/Desktop/LINEFM Radio"
  check "Dock entry" sh -c "defaults read com.apple.dock persistent-apps | grep -q 'LINEFM%20Radio.app'"
  check "uninstaller kept" test -d "$state/Uninstall LINEFM Radio.app"
  uninstaller="$state/Uninstall LINEFM Radio.app/Contents/MacOS/LINEFM Radio Setup"
else
  check "app binary in place" test -x "$dir/linefm_radio"
  check "menu entry" test -f "$data_home/applications/de.linefm.app.desktop"
  check "menu entry valid" sh -c "! command -v desktop-file-validate >/dev/null || desktop-file-validate '$data_home/applications/de.linefm.app.desktop'"
  check "icon installed" test -f "$data_home/icons/hicolor/256x256/apps/de.linefm.app.png"
  check "desktop shortcut" test -x "$home/Desktop/de.linefm.app.desktop"
  check "uninstaller kept" test -x "$state/uninstaller/linefm_setup"
  check "uninstaller has no payload" test ! -e "$state/uninstaller/setup/payload.tar.gz"
  uninstaller="$state/uninstaller/linefm_setup"
fi
scope=$(rec SCOPE)

# --- the app starts -------------------------------------------------------------
start_app "$dir"
check "installed app starts" app_running

# --- running app: keep -> 5, close -> update goes through ----------------------
run_engine running-keep "$setup_dir" $'keep\n' install --scope "$scope" --desktop 1 --startmenu 1 --autostart 0; code=$?
check "running app, keep: exit 5 (got $code)" test "$code" = 5
check "app still running after keep" app_running
run_engine running-close "$setup_dir" $'close\n' install --scope "$scope" --desktop 1 --startmenu 1 --autostart 1; code=$?
check "running app, close: update exits 0 (got $code)" test "$code" = 0
check "app closed for the update" sh -c '! pgrep -x linefm_radio >/dev/null && ! pgrep -x "LINEFM Radio" >/dev/null'
check "update keeps the folder" test "$(rec DIR)" = "$dir"
if [ "$os" = macos ]; then
  check "login item" test -f "$home/Library/LaunchAgents/de.linefm.app.autostart.plist"
else
  check "autostart entry" test -f "${XDG_CONFIG_HOME:-$home/.config}/autostart/de.linefm.app.desktop"
fi

# --- downgrade protection --------------------------------------------------------
tmp=$(mktemp -d)
cp -R "$setup_dir" "$tmp/old"
sed -i.bak 's/^VERSION=.*/VERSION=0.0.0-0/' "$tmp/old/product.env"
run_engine downgrade "$tmp/old" "" install --scope "$scope" --desktop 1 --startmenu 1 --autostart 0; code=$?
check "downgrade blocked: exit 6 (got $code)" test "$code" = 6

# --- damaged payload -------------------------------------------------------------
cp -R "$setup_dir" "$tmp/bad"
printf 'x' >> "$tmp/bad/payload.tar.gz"
run_engine corrupt "$tmp/bad" "" install --scope "$scope" --desktop 1 --startmenu 1 --autostart 0; code=$?
check "damaged payload rejected: exit 4 (got $code)" test "$code" = 4

# --- unsafe destinations (fresh home, nothing installed) -------------------------
mkdir -p "$tmp/home2"
for target in /etc/linefm-radio "$tmp/home2/../x/LINEFM Radio.app" "$tmp/home2"; do
  HOME="$tmp/home2" XDG_DATA_HOME="" XDG_CONFIG_HOME="" run_engine badtarget "$setup_dir" "" \
    install --scope user --dir "$target" --desktop 0 --startmenu 0 --autostart 0; code=$?
  check "unsafe destination $target: exit 8 (got $code)" test "$code" = 8
done
if [ "$os" = linux ]; then
  HOME="$tmp/home2" run_engine machine "$setup_dir" "" install --scope machine --desktop 0 --startmenu 0 --autostart 0; code=$?
  check "Linux 'everyone' needs no root, refused: exit 7 (got $code)" test "$code" = 7
fi
rm -rf "$tmp"

# --- graphical uninstall with user data ------------------------------------------
mkdir -p "$data_dir" && echo test > "$data_dir/marker"
run_ui uninstall "$uninstaller" LF_SETUP_AUTOPILOT_DELETE_DATA=1; code=$?
check "uninstall through the UI exits 0 (got $code)" test "$code" = 0
check "app removed" test ! -e "$dir"
check "install record removed" test ! -e "$state"
check "user data removed" test ! -e "$data_dir"
if [ "$os" = macos ]; then
  check "desktop alias removed" test ! -L "$home/Desktop/LINEFM Radio"
  check "Dock entry removed" sh -c "! defaults read com.apple.dock persistent-apps | grep -q 'LINEFM%20Radio.app'"
  check "login item removed" test ! -e "$home/Library/LaunchAgents/de.linefm.app.autostart.plist"
else
  check "menu entry removed" test ! -e "$data_home/applications/de.linefm.app.desktop"
  check "desktop shortcut removed" test ! -e "$home/Desktop/de.linefm.app.desktop"
  check "autostart removed" test ! -e "${XDG_CONFIG_HOME:-$home/.config}/autostart/de.linefm.app.desktop"
fi

ls -R "$art/screenshots" | head -60
echo "failures: $failures"
[ "$failures" = 0 ]
