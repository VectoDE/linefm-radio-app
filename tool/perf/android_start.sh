#!/usr/bin/env bash
# Android cold start in the emulator: launch command to first Flutter frame.
#
#   bash tool/perf/android_start.sh --apk app.apk --label current --runs 5 \
#     --out tool/perf/out/android-start-current.json
#
# The APK must be built with --dart-define=LINEFM_PERF_MARKS=true
# (lib/core/perf/perf_marks.dart). On Android the marks are printed to logcat
# as `LINEFM_PERF <name> <microseconds since 1970, UTC>`.
#
# Per run (after one warm-up launch that is not counted):
#   - force-stop and drop the page cache (adb root where the image allows it),
#     so the process and its files start cold;
#   - one adb call takes the device clock and runs `am start -W` right after,
#     so the clock reading and the launch share one command;
#   - total/wait time from `am start -W` (time until the activity window is
#     shown, which is the splash, not the first Flutter frame);
#   - marks main, run-app and first-frame relative to the clock reading.
#     "first-frame" is the cold-start figure; it includes the adb call latency,
#     which is the same for every build measured this way.
# Result: JSON with one entry per run. Needs adb, jq, a booted emulator/device.

set -euo pipefail

apk=""
label="current"
runs=5
out="tool/perf/out/android-start.json"
package="de.linefm.app"
activity=".MainActivity"
while [ $# -gt 0 ]; do
  case "$1" in
    --apk) apk="$2"; shift 2 ;;
    --label) label="$2"; shift 2 ;;
    --runs) runs="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    --package) package="$2"; shift 2 ;;
    --activity) activity="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
if [ -z "$apk" ] || [ ! -f "$apk" ]; then
  echo "--apk must point to an existing file" >&2
  exit 2
fi
mkdir -p "$(dirname "$out")"

# adb from the SDK when it is not on PATH (each CI step starts a new shell, so
# the PATH set by tool/perf/android_emulator.sh does not carry over).
if ! command -v adb >/dev/null 2>&1; then
  sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  if [ -z "$sdk" ] || [ ! -x "$sdk/platform-tools/adb" ]; then
    echo "adb not found: put it on PATH or set ANDROID_HOME" >&2
    exit 2
  fi
  export PATH="$sdk/platform-tools:$PATH"
fi

adb root >/dev/null 2>&1 || true
adb wait-for-device
adb uninstall "$package" >/dev/null 2>&1 || true
adb install -r "$apk" >/dev/null
adb shell pm grant "$package" android.permission.POST_NOTIFICATIONS >/dev/null 2>&1 || true

# Launches once and returns "<clock ns>|<am start -W output>" on stdout.
launch() {
  adb shell "date +%s%N; am start -W -n $package/$package$activity" | tr -d '\r'
}

# Reads the mark <name> (micros) from the current logcat, empty if missing.
mark_micros() {
  adb logcat -d -s flutter:I 2>/dev/null | tr -d '\r' |
    awk -v n="$1" '$0 ~ ("LINEFM_PERF " n " ") { v = $NF } END { if (v != "") print v }'
}

# Waits up to 40 s for the first-frame mark.
wait_first_frame() {
  for _ in $(seq 1 200); do
    if [ -n "$(mark_micros first-frame)" ]; then return 0; fi
    sleep 0.2
  done
  return 1
}

results='[]'
total=$((runs + 1))
for i in $(seq 0 $((total - 1))); do
  adb shell am force-stop "$package"
  adb shell "echo 3 > /proc/sys/vm/drop_caches" >/dev/null 2>&1 || true
  sleep 3
  adb logcat -c
  raw="$(launch)"
  t0_ns="$(printf '%s\n' "$raw" | head -n1)"
  total_ms="$(printf '%s\n' "$raw" | awk -F': ' '/^TotalTime/ { print $2 }')"
  wait_ms="$(printf '%s\n' "$raw" | awk -F': ' '/^WaitTime/ { print $2 }')"
  reached=true
  wait_first_frame || reached=false
  t0_us=$((t0_ns / 1000))
  rel() { # mark name -> ms since t0, "null" if missing
    local v
    v="$(mark_micros "$1")"
    if [ -z "$v" ]; then echo null; else echo $(((v - t0_us) / 1000)); fi
  }
  main_ms="$(rel main)"
  runapp_ms="$(rel run-app)"
  first_ms="$(rel first-frame)"
  warm=false
  [ "$i" -eq 0 ] && warm=true
  echo "Run $i$([ "$warm" = true ] && echo ' (warm-up)'): first frame ${first_ms} ms, TotalTime ${total_ms:-?} ms"
  results="$(jq -c --argjson run "$i" --argjson warm "$warm" --argjson reached "$reached" \
    --argjson total "${total_ms:-null}" --argjson wait "${wait_ms:-null}" \
    --argjson main "$main_ms" --argjson runapp "$runapp_ms" --argjson first "$first_ms" \
    '. + [{run: $run, warmup: $warm, reachedFirstFrame: $reached, totalTimeMs: $total, waitTimeMs: $wait,
           marksMs: {main: $main, "run-app": $runapp, "first-frame": $first}}]' <<<"$results")"
done

model="$(adb shell getprop ro.product.model | tr -d '\r')"
api="$(adb shell getprop ro.build.version.sdk | tr -d '\r')"
abi="$(adb shell getprop ro.product.cpu.abi | tr -d '\r')"
jq -n --arg label "$label" --arg apk "$(basename "$apk")" --argjson bytes "$(stat -c %s "$apk")" \
  --arg commit "${GITHUB_SHA:-unknown}" --arg ref "${BUILD_REF:-}" \
  --arg run "${GITHUB_SERVER_URL:-}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}" \
  --arg model "$model" --arg api "$api" --arg abi "$abi" --argjson runs "$runs" \
  --argjson results "$results" \
  '{tool: "tool/perf/android_start.sh", label: $label,
    environment: {commit: $commit, builtFrom: $ref, runUrl: $run, device: {model: $model, api: $api, abi: $abi, emulator: true}},
    apk: {file: $apk, bytes: $bytes}, runs: $runs, results: $results}' >"$out"
echo "android-start: $out"
