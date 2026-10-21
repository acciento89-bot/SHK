#!/usr/bin/env bash
set -euo pipefail
[[ "${GITHUB_ACTIONS:-}" == true ]] || { echo 'Disposable hosted runner required'; exit 2; }
case "${SHK_FLAVOR:-}" in kaltecalc|lueftungscalc|heizkoerpercalc|rohrcalc|anlagencheck) ;; *) echo 'Unknown SHK flavor'; exit 2;; esac
cd "$GITHUB_WORKSPACE"
proof="$RUNNER_TEMP/shk-native-acceptance/$SHK_FLAVOR"
mkdir -p "$proof"
serial=emulator-5554
avd="SHKNativeAcceptance-${SHK_FLAVOR}-35"
cleanup() {
  rc=$?; trap - EXIT; set +e
  timeout 10s adb -s "$serial" emu kill > "$proof/emulator-stop.txt" 2>&1
  for attempt in {1..15}; do
    if ! timeout 3s adb devices | grep -Fq "$serial"; then break; fi
    sleep 1
  done
  timeout 15s "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" delete avd -n "$avd" > "$proof/avd-delete.txt" 2>&1
  timeout 10s emulator -list-avds > "$proof/remaining-avds.txt" 2>&1
  avd_rc=$?
  timeout 5s adb devices > "$proof/remaining-devices.txt" 2>&1
  device_rc=$?
  python3 .github/shk-native-acceptance/verify_cleanup.py --proof "$proof" --avd "$avd" --serial "$serial" --avd-rc "$avd_rc" --device-rc "$device_rc"
  if [[ $? != 0 ]]; then echo 'Exact owned cloud device cleanup not verified' > "$proof/cleanup-failed.txt"; rc=1; fi
  exit "$rc"
}
trap cleanup EXIT
sleep 20
python3 .github/shk-native-acceptance/run_acceptance.py --serial "$serial" --flavor "$SHK_FLAVOR" \
  --product "android/app/build/outputs/apk/$SHK_FLAVOR/debug/app-$SHK_FLAVOR-debug.apk" \
  --host .github/shk-native-acceptance/host/app/build/outputs/apk/debug/app-debug.apk \
  --test .github/shk-native-acceptance/host/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --proof "$proof"
