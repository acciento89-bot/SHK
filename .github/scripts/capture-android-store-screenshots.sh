#!/usr/bin/env bash
set -euo pipefail

: "${PACKAGE_NAME:?PACKAGE_NAME is required}"
: "${APK_PATH:?APK_PATH is required}"
: "${OUTPUT_DIR:?OUTPUT_DIR is required}"
: "${SECOND_ACTION:?SECOND_ACTION is required}"
: "${WAIT_TEXT:?WAIT_TEXT is required}"

readonly apk_path="$GITHUB_WORKSPACE/$APK_PATH"
readonly output_dir="$GITHUB_WORKSPACE/$OUTPUT_DIR"

current_focus() {
  adb shell dumpsys window | grep -m1 'mCurrentFocus=' || true
}

ui_dump() {
  adb shell uiautomator dump /sdcard/window.xml >/dev/null 2>&1 || true
  adb shell cat /sdcard/window.xml 2>/dev/null || true
}

reject_system_dialog() {
  local dump="$1"
  if grep -Eqi "System UI|isn't responding|Close app|Viewing full screen|Got it" <<<"$dump"; then
    echo "System dialog detected; refusing to capture app screenshots." >&2
    return 1
  fi
}

wait_for_ready_ui() {
  local attempt focus dump
  for attempt in $(seq 1 90); do
    focus="$(current_focus)"
    if [[ "$focus" == *"$PACKAGE_NAME"* ]]; then
      dump="$(ui_dump)"
      reject_system_dialog "$dump"
      if grep -Fq "$WAIT_TEXT" <<<"$dump"; then return 0; fi
    fi
    sleep 2
  done
  echo "Timed out waiting for real $PACKAGE_NAME UI text: $WAIT_TEXT" >&2
  current_focus >&2
  ui_dump >&2
  return 1
}

launch_app() {
  local component
  adb shell am force-stop "$PACKAGE_NAME"
  component="$(adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER "$PACKAGE_NAME" | tr -d '\r' | tail -n 1)"
  if [[ "$component" != "$PACKAGE_NAME/"* ]]; then
    echo "Could not resolve launcher activity for $PACKAGE_NAME: $component" >&2
    return 1
  fi
  adb shell am start -W -n "$component"
  wait_for_ready_ui
}

assert_clean_foreground() {
  local focus dump
  focus="$(current_focus)"
  if [[ "$focus" != *"$PACKAGE_NAME"* ]]; then
    echo "Expected $PACKAGE_NAME in mCurrentFocus; refusing to capture." >&2
    printf '%s\n' "$focus" >&2
    return 1
  fi
  dump="$(ui_dump)"
  reject_system_dialog "$dump"
  grep -Fq "$WAIT_TEXT" <<<"$dump"
}

mkdir -p "$output_dir"
rm -f "$output_dir"/*.png
test -s "$apk_path"
adb install -r "$apk_path"
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
adb shell settings put global hide_error_dialogs 1
adb shell cmd locale set-app-locales "$PACKAGE_NAME" --user 0 de-DE || true

launch_app
assert_clean_foreground
adb exec-out screencap -p > "$output_dir/01-current-ui.png"

case "$SECOND_ACTION" in
  tap)
    adb shell input tap "${TAP_X:-540}" "${TAP_Y:-1900}"
    ;;
  swipe)
    adb shell input swipe 540 1900 540 650 600
    ;;
  dark)
    adb shell cmd uimode night yes
    launch_app
    ;;
  *)
    echo "Unsupported SECOND_ACTION: $SECOND_ACTION" >&2
    exit 1
    ;;
esac

WAIT_TEXT="${SECOND_WAIT_TEXT:-$WAIT_TEXT}"
wait_for_ready_ui
assert_clean_foreground
adb exec-out screencap -p > "$output_dir/02-current-ui-detail.png"

python3 - "$output_dir" <<'PY'
import hashlib
import struct
import sys
from pathlib import Path

paths = sorted(Path(sys.argv[1]).glob('*.png'))
assert len(paths) == 2, paths
digests = set()
for path in paths:
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    width, height = struct.unpack('>II', data[16:24])
    assert (width, height) == (1080, 2400), (path, width, height)
    digests.add(hashlib.sha256(data).hexdigest())
assert len(digests) == 2, 'Screenshots must show two distinct real app states'
PY
