# Manual SHK native workflow acceptance

This is a new manual-only cloud lane. It compiles the selected real SHK debug flavor and an independent UiAutomator host from the checked-out source. A five-flavor matrix uses max-parallel1 and fail-fastfalse: exactly one API35 x86_64 Google APIs/Pixel7/2GiB KVM emulator at a time. No account, Play image, store/signing credential, purchase/restore/redemption or external recipient is configured. Do not enable this lane through push/PR triggers.

The original five business scenarios and their assertions remain byte-for-byte in the original business-method region. SDK guard36→35 and reviewed external active-window/actual-IME/scroll/trace helpers are explicitly hash-pinned in lineage.json. Unknown active apps, overlays, missing safe scroll bounds or unresolved keyboard state fail immediately; no app recovery, relaunch retry or ANR dismissal is attempted. Bounded window traces use only the existing encrypted events.jsonl artifact. Original source is pinned and included as a text fixture; the local report receiver is unchanged. No test record is injected into the product. Methods cover original calculator results, new project/visit/history/baseline/proposal/checklist behavior, rotated unsaved drafts, invalid draft input, exact cold archive reload and actual full UTF8 file share. The controlled local receiver checks authority, temporary read grant, ClipData, complete byte count/hash and expected neutral facts. Each job installs only its own flavor plus host/test APKs and invokes exactly its matching method.

## Before integration/dispatch

Root reviews the staged files and source manifest, then integrates only these additive `.github/shk-native-acceptance/**` and `.github/workflows/shk-native-acceptance.yml` files. No existing product/source/workflow/version/signing file changes are included. `verify_source.py` pins the actual product Gradle bytes, all five package mappings and current1.0.1(2) candidate identity. A future version/configuration change must be reviewed and deliberately reflected in the configuration/lineage fixture; a mismatch stops the lane before building.

Root chooses exact GitHub source/ref and manually dispatches `shk-native-acceptance.yml` with `flavor=all` (default, all five serial) or a single explicit flavor (first validation can be kaltecalc). The lane retains checkout SHA and separate product/host/test APK hashes. A source/mock pass is never actual host compilation or native workflow acceptance. Root must inspect actual job conclusions and decrypt evidence before claiming acceptance. No Duo/iOS or production release follows from this API35 phone lane.

## Source checks only

`python3 -m unittest discover -s .github/shk-native-acceptance/tests -v`

`bash -n .github/shk-native-acceptance/run-cloud.sh`

Tests use mocked adb only. Encryption tests execute actual local OpenSSL with the public certificate and synthetic temporary files; no private key or decryption is read/performed. These tests do not start an emulator, build or contact a backend.

## Failure/cleanup evidence and privacy

Each native invocation is bounded600seconds, with nonzero stdout/stderr and timeout partial output preserved, never printed into public job logs. Failure stays failure. The runner never dismisses dialogs. SystemUI ANR preflight fails before installation; later native failures retain actual PNG/XML/logcat rather than inventing an app defect. Exact original selectors/assertions remain unchanged.

The cloud wrapper owns only action-created `SHKNativeAcceptance-<flavor>-35` / emulator5554 in that single fresh hosted job. Its EXIT trap preserves failure, kills that emulator, deletes that exact AVD and verifies successful inventory commands plus exact absence. Cleanup failure fails the process. Action post cleanup remains. A boot failure/cancellation before the wrapper has no locally verified cleanup claim; GitHub eventually destroys the hosted machine.

All raw synthetic evidence (including build logs, archive, report, UI, cleanup inventories and result) lives only under `$RUNNER_TEMP/shk-native-acceptance/<flavor>`. An always-step encrypts a bounded exact filename allowlist with the pinned public certificate, using OpenSSL CMS AES256-CBC. It validates nonempty DER CMS and atomically publishes a fresh output before removing raw files. Missing/unsafe paths, unexpected names, links, changed certificate or encryption failure cannot publish raw evidence or replace ciphertext. The only artifact path is `$RUNNER_TEMP/shk-native-encrypted/<flavor>/acceptance.cms`, retention7days. Public ciphertext is not a private artifact; only root holds the private key outside source. Encryption failure leaves raw evidence local and fails the job; no raw upload fallback exists. Raw files must never contain customer data or a seeded personal account/device.

Native extraction allows only the original selected method's finite capture/report filenames, bounded sizes and matching PASS event after actual `OK(1test)`. Missing/invalid native evidence prevents a passing receipt. Root decrypts locally with its dedicated existing key, reads result/cleanup and actual screenshots/AX/report before approving a result. No success/native/cloud claim is made by preparing this lane.
