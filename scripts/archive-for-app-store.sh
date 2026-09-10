#!/usr/bin/env bash
# Run on a Mac with Xcode and the existing developer account/signing access.
set -euo pipefail
: "${SHK_DEVELOPMENT_TEAM:?Set SHK_DEVELOPMENT_TEAM to your Apple Developer team ID}"
command -v xcodebuild >/dev/null
command -v xcodegen >/dev/null
for scheme in KalteCalc LueftungsCalc HeizkoerperCalc RohrCalc; do
  app_key=$(echo "$scheme" | tr '[:upper:]' '[:lower:]')
  python3 scripts/generate_app_icon.py --app "$app_key" --source-dir "Apps/$scheme"
done
xcodegen generate
mkdir -p release
python3 - <<'PY'
import os, plistlib
with open('release/ExportOptions.plist', 'wb') as stream:
    plistlib.dump({'method':'app-store-connect', 'destination':'upload', 'signingStyle':'automatic',
                  'teamID':os.environ['SHK_DEVELOPMENT_TEAM'], 'manageAppVersionAndBuildNumber':False,
                  'uploadSymbols':True}, stream)
PY
for scheme in KalteCalc LueftungsCalc HeizkoerperCalc RohrCalc; do
  xcodebuild -project KamilunavoSHK.xcodeproj -scheme "$scheme" -configuration Release \
    -destination 'generic/platform=iOS' -archivePath "release/$scheme.xcarchive" \
    DEVELOPMENT_TEAM="$SHK_DEVELOPMENT_TEAM" ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon -allowProvisioningUpdates archive
  xcodebuild -exportArchive -archivePath "release/$scheme.xcarchive" \
    -exportOptionsPlist release/ExportOptions.plist -exportPath "release/$scheme" -allowProvisioningUpdates
 done
