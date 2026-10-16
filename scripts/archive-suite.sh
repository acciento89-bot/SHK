#!/usr/bin/env bash
# Only the unified, unpublished AnlagenCheck host. No sibling app uploads.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${SHK_RELEASE_DIR:?Set an absolute output directory outside the repository}"
[[ "$SHK_RELEASE_DIR" = /* ]] || { echo 'Output directory must be absolute.' >&2; exit 2; }
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-27.1-RC.app/Contents/Developer}"
# Existing App Store Connect API key; identifiers only, never private-key contents.
SHK_AUTH_FILE="/Volumes/SSK SSD/Kamilunavo/Artifacts/AppPortfolio-20261016/signing-auth-identifiers.json"
read -r SHK_KEY_ID SHK_ISSUER_ID < <(python3 - "$SHK_AUTH_FILE" <<'AUTH'
import json,sys
v=json.load(open(sys.argv[1]));assert v['keyID']=='6K454PQ466'
print(v['keyID'],v['issuerID'])
AUTH
)
SHK_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${SHK_KEY_ID}.p8"
[[ -f "$SHK_KEY_PATH" ]] || { echo 'Existing signing key unavailable.' >&2; exit 2; }
SHK_AUTH=(-authenticationKeyPath "$SHK_KEY_PATH" -authenticationKeyID "$SHK_KEY_ID" -authenticationKeyIssuerID "$SHK_ISSUER_ID")
[[ ! -e "$SHK_RELEASE_DIR/SHKWerkstatt-1.0-6.xcarchive" ]] || { echo 'Archive already exists; inspect it before a new run.' >&2; exit 2; }
xcodegen generate
mkdir -p "$SHK_RELEASE_DIR"
xcodebuild -project KamilunavoSHK.xcodeproj -scheme SHKWerkstatt -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath "$SHK_RELEASE_DIR/DerivedData" -archivePath "$SHK_RELEASE_DIR/SHKWerkstatt-1.0-6.xcarchive" \
  DEVELOPMENT_TEAM=TKG684N5GL -allowProvisioningUpdates "${SHK_AUTH[@]}" archive
python3 - "$SHK_RELEASE_DIR" <<'PY'
import pathlib,plistlib,sys
out=pathlib.Path(sys.argv[1]);archive=out/'SHKWerkstatt-1.0-6.xcarchive'
info=plistlib.load(open(archive/'Products/Applications/SHKWerkstatt.app/Info.plist','rb'))
assert info['CFBundleIdentifier']=='de.kamilunavo.servicecheck'
assert info['CFBundleVersion']=='6'
assert info['CFBundleShortVersionString']=='1.0'
app=archive/'Products/Applications/SHKWerkstatt.app'
assert not list(app.rglob('*.storekit')), 'Local StoreKit configuration must never ship'
assert not list(app.rglob('example-*.json')), 'Screenshot data must never ship'
assert not list(app.rglob('*.xctest')), 'Test bundles must never ship'
plistlib.dump({'method':'app-store-connect','destination':'export','teamID':'TKG684N5GL','signingStyle':'automatic','manageAppVersionAndBuildNumber':False,'testFlightInternalTestingOnly':False,'uploadSymbols':True},open(out/'ExportOptions.plist','wb'))
print('Verified single host de.kamilunavo.servicecheck 1.0(6).')
PY
if [[ -n "${SHK_MANUAL_EXPORT_OPTIONS:-}" ]]; then
  python3 - "$SHK_MANUAL_EXPORT_OPTIONS" "$SHK_RELEASE_DIR/ExportOptions.plist" <<'MANUAL'
import pathlib,plistlib,sys
options=plistlib.load(open(sys.argv[1],'rb'))
assert options['method']=='app-store-connect'
assert options['teamID']=='TKG684N5GL' and options['signingStyle']=='manual'
assert set(options['provisioningProfiles'])=={'de.kamilunavo.servicecheck'}
plistlib.dump(options,open(sys.argv[2],'wb'))
MANUAL
  xcodebuild -exportArchive -archivePath "$SHK_RELEASE_DIR/SHKWerkstatt-1.0-6.xcarchive" \
    -exportOptionsPlist "$SHK_RELEASE_DIR/ExportOptions.plist" -exportPath "$SHK_RELEASE_DIR/Distribution"
else
  xcodebuild -exportArchive -archivePath "$SHK_RELEASE_DIR/SHKWerkstatt-1.0-6.xcarchive" \
    -exportOptionsPlist "$SHK_RELEASE_DIR/ExportOptions.plist" -exportPath "$SHK_RELEASE_DIR/Distribution" -allowProvisioningUpdates "${SHK_AUTH[@]}"
fi
