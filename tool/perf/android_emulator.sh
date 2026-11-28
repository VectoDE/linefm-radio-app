#!/usr/bin/env bash
# Boots an x86_64 Android emulator on a GitHub-hosted Linux runner (KVM) and
# waits until the system is ready. The emulator output goes to a file so it
# cannot end up in the job log.
#
#   bash tool/perf/android_emulator.sh [LOG_DIR]
#
# Needs the preinstalled Android SDK (ANDROID_HOME) with cmdline-tools and a
# KVM device. Prints nothing but progress lines.

set -euo pipefail

log_dir="${1:-tool/perf/out}"
api="${EMULATOR_API:-34}"
# google_apis (default) has no TalkBack; the accessibility job uses
# google_apis_playstore and checks at runtime whether TalkBack is installed.
tag="${EMULATOR_TAG:-google_apis}"
image="system-images;android-${api};${tag};x86_64"
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$sdk" ]; then
  echo "ANDROID_HOME is not set" >&2
  exit 1
fi
mkdir -p "$log_dir"
export PATH="$sdk/cmdline-tools/latest/bin:$sdk/emulator:$sdk/platform-tools:$PATH"

# KVM for the runner user (documented by GitHub for hardware acceleration).
echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' |
  sudo tee /etc/udev/rules.d/99-kvm4all.rules >/dev/null
sudo udevadm control --reload-rules
sudo udevadm trigger --name-match=kvm

echo "Installing emulator and $image"
yes 2>/dev/null | sdkmanager --licenses >"$log_dir/sdkmanager-licenses.log" 2>&1 || true
sdkmanager --install "emulator" "$image" >"$log_dir/sdkmanager-install.log" 2>&1

# One AVD directory for avdmanager and the emulator. The preinstalled
# cmdline-tools and the current emulator resolve the default location
# differently, so without this the emulator does not find the new AVD.
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$HOME/.android/avd}"
mkdir -p "$ANDROID_AVD_HOME"

echo "Creating the virtual device"
echo no | avdmanager create avd --force --name perf --package "$image" --device pixel_6 \
  >"$log_dir/avdmanager.log" 2>&1
if ! emulator -list-avds 2>/dev/null | grep -qx perf; then
  echo "The virtual device was not created in $ANDROID_AVD_HOME, see avdmanager.log" >&2
  exit 1
fi

booted() {
  [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '')" = "1" ]
}

# Starts the emulator and waits a bounded time for the boot to complete.
# An emulator that exits early fails the attempt instead of leaving
# "adb wait-for-device" hanging until the job timeout. The Play Store image
# boots slower than google_apis; callers can allow more polls (2 s each)
# with EMULATOR_BOOT_POLLS.
start_and_wait() {
  nohup emulator -avd perf -no-window -no-audio -no-boot-anim -no-snapshot -no-metrics     -gpu swiftshader_indirect -memory 4096 -cores 3 -accel on "$@"     >>"$log_dir/emulator.log" 2>&1 &
  emulator_pid=$!
  for _ in $(seq 1 "${EMULATOR_BOOT_POLLS:-240}"); do
    if ! kill -0 "$emulator_pid" 2>/dev/null; then
      echo "The emulator exited during boot, see emulator.log" >&2
      return 1
    fi
    if booted; then
      return 0
    fi
    sleep 2
  done
  return 1
}

# A cold boot of the system image occasionally stalls before
# sys.boot_completed (seen with the Play Store image on hosted runners).
# One more attempt on wiped data recovers it; a second stall fails.
echo "Starting the emulator"
if ! start_and_wait; then
  echo "The emulator did not finish booting, retrying once on wiped data"
  kill "$emulator_pid" 2>/dev/null || true
  wait "$emulator_pid" 2>/dev/null || true
  adb kill-server >/dev/null 2>&1 || true
  if ! start_and_wait -wipe-data || ! booted; then
    echo "The emulator did not finish booting" >&2
    exit 1
  fi
fi

# Fewer moving parts while measuring: no animations, no first-boot noise.
adb shell settings put global window_animation_scale 0 >/dev/null
adb shell settings put global transition_animation_scale 0 >/dev/null
adb shell settings put global animator_duration_scale 0 >/dev/null
sleep 30
echo "Emulator ready: $(adb shell getprop ro.product.model | tr -d '\r'), API $(adb shell getprop ro.build.version.sdk | tr -d '\r')"
