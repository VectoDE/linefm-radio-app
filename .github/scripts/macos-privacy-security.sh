#!/usr/bin/env bash
# Captures System Settings > Privacy & Security with the "Open Anyway" entry
# for LINEFM Radio in view, and nothing else on top of it.
#
# Usage: macos-privacy-security.sh <output.png> <log file>
# Runs on a GitHub macOS runner after a blocked launch of the app. Every GUI
# call is bounded; failures are logged, the caller checks the file.
set +e -uo pipefail

file="$1"
log="$2"
bounded() { local secs=$1; shift; perl -e 'alarm shift; exec @ARGV' "$secs" "$@"; }
osa() { bounded 40 osascript -e 'with timeout of 30 seconds' "$@" -e 'end timeout' 2>&1; }

# 1. Dismiss every Gatekeeper dialog with "Done", then end the agent.
for _ in 1 2 3; do
  osa -e 'tell application "System Events" to tell process "CoreServicesUIAgent"' \
  \
    -e 'repeat with w in windows' \
  \
    -e 'try' -e 'click (first button of w whose name is "Done")' -e 'end try' \
  \
    -e 'end repeat' -e 'end tell' >> "$log"
  sleep 1
done
pkill -x CoreServicesUIAgent || true
pkill -x "LINEFM Radio" || true

# 2. Close Finder windows (DMG window) and unmount the image.
osa -e 'tell application "Finder" to close every window' >> "$log"
if [ -d "/Volumes/LINEFM Radio" ]; then
  bounded 60 hdiutil detach -quiet "/Volumes/LINEFM Radio" || bounded 60 hdiutil detach -force -quiet "/Volumes/LINEFM Radio" || true
fi
pkill -x UserNotificationCenter || true

# 3. Open Privacy & Security in the foreground.
pkill -x "System Settings" || true
sleep 1
bounded 20 open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Security" \
  || bounded 20 open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension" \
  || echo "## open Privacy & Security: timed out or failed" >> "$log"
sleep 6
osa -e 'tell application "System Settings" to activate' \
    -e 'tell application "System Events" to set frontmost of process "System Settings" to true' >> "$log"
sleep 1

# 4. Bring the Security section with "Open Anyway" into view. The button sits
# in nested groups inside a scroll area near the bottom of the pane, so walk
# the whole tree, match name, description or title, and fall back to scrolling
# every scroll area to its end.
echo "## scroll to Open Anyway" >> "$log"
osa -e 'tell application "System Events" to tell process "System Settings"' \
    -e 'set found to "false"' \
    -e 'repeat 8 times' \
    -e 'try' \
    -e 'set els to entire contents of window 1' \
    -e 'repeat with e in els' \
    -e 'try' \
    -e 'if role of e is "AXButton" then' \
    -e 'set n to ""' \
    -e 'try' -e 'set n to n & (name of e as text)' -e 'end try' \
    -e 'try' -e 'set n to n & (description of e as text)' -e 'end try' \
    -e 'try' -e 'set n to n & (value of attribute "AXTitle" of e as text)' -e 'end try' \
    -e 'if n contains "Open Anyway" then' \
    -e 'try' -e 'perform action "AXScrollToVisible" of e' -e 'end try' \
    -e 'set found to "button"' \
    -e 'exit repeat' \
    -e 'end if' \
    -e 'end if' \
    -e 'end try' \
    -e 'end repeat' \
    -e 'end try' \
    -e 'if found is not "false" then exit repeat' \
    -e 'try' \
    -e 'repeat with s in (entire contents of window 1)' \
    -e 'try' \
    -e 'if role of s is "AXScrollArea" then set value of scroll bar 1 of s to 1' \
    -e 'end try' \
    -e 'end repeat' \
    -e 'end try' \
    -e 'key code 119' \
    -e 'repeat 4 times' -e 'key code 121' -e 'end repeat' \
    -e 'delay 1' \
    -e 'end repeat' \
    -e 'if found is "false" then set found to "scrolled to end, button not matched"' \
    -e 'return found' \
    -e 'end tell' >> "$log"
sleep 2

# 5. Capture only the System Settings window; full screen as fallback.
b=$(bounded 20 osascript -e 'with timeout of 15 seconds' -e 'tell application "System Events" to tell process "System Settings"' -e 'set {x, y} to position of window 1' -e 'set {w, h} to size of window 1' -e 'return (x as text) & "," & (y as text) & "," & (w as text) & "," & (h as text)' -e 'end tell' -e 'end timeout' 2>/dev/null)
if [[ "$b" =~ ^-?[0-9]+,-?[0-9]+,[0-9]+,[0-9]+$ ]]; then
  echo "## $file bounds of System Settings: $b" >> "$log"
  bounded 20 screencapture -x -R "$b" "$file"
else
  echo "## $file: no window bounds for System Settings, full screen" >> "$log"
  bounded 20 screencapture -x "$file"
fi
pkill -x "System Settings" || true
exit 0
