# Calculator listing cleanup — 16 October 2026

The user explicitly authorized removing the rejected single-purpose calculator listings now. This supersedes the older instruction to wait until the consolidated replacement is publicly available. Completed normal removal in App Store Connect after canceling each stale unresolved review submission. RohrCalc (6804748249), KälteCalc (6804747292), LüftungsCalc (6804747588), HeizkörperCalc (6804748049) and VolumeCalc (6804672773) all read back `removed: true`. Each actual App Information page offers App wiederherstellen. VolumeCalc required removing its existing 175-territory sale availability first; its only app version was REJECTED, with no live DE/US lookup result. Local projects, source and historical builds were retained. Removed listings remain under Apple's Removed Apps and their names are released.

Protected app records were independently read back: SHK Werkstatt (6804749223) `removed:false`, READY_FOR_REVIEW; MAGCalc (6801678865), BrennerCalc (6801656652) and HydroCalc SHK (6801788464) `removed:false`, READY_FOR_DISTRIBUTION. No approved listing was modified. Evidence: QA/rejected-calculators-removed-20261016.json.

SHK Werkstatt build 6 and the joint App+Pro draft remain prepared, not submitted or approved. Actual Duo validation remains open. The Mac rebooted twice: after the first reboot, actual built-in Settings rendered on the Duo, but SHK launch still stalled and the host later required the owner's second restart. Do not repeat the old claim that every post-restart Duo capture stayed at the Apple logo; do not count Settings as SHK validation. No new native Duo pass or badge exists. Production source and signed build 6 are unchanged by this documentation cleanup.

One More Floor received a renewed 4.3(a) rejection on 16 October at 20:04 Berlin. After explicit owner approval, the clarification was sent at 20:30 Berlin and exact published text read back. No new Floor resubmission. Its dedicated repository has the receipt/current status.

---

# Authorized Mac restart — 2026-10-16T19:24:53.153415+02:00

User replied "versuch es jetzt mal" to the explicit Mac restart question, authorizing the restart now. A bounded Duo retry launched the app process (PID45846), but native UI remained at launcher/blank white and the native two-case entry/share test harness did not begin cases after approximately3minutes. Interrupted this test deliberately; never count it as a native pass. Diagnostics retained. No product source was changed. Preparing normal macOS restart after committing/pushing this checkpoint; do not force-close unrelated unsaved documents. No new confirmation required. On resumption, verify actual new boot time, mount SSD and continue actual Duo testing. Build6 and joint review draft remain prepared, not submitted. Proof guard remains in place. Restart marker outside Git: Artifacts/AppPortfolio-20261016/MAC-RESTART-CHECKPOINT-20261016.json.

---

# Latest prepared release — 16 October 2026, 17:40 Berlin

Design sourcef098cd5 pushed.69core tests pass, final9nativephone workflows pass,48native DE/EN phone+iPad captures and4localStoreKitUI purchases pass. Archive/export build6 succeeded; signed distribution verified, SHA25683b99cad5490d484ce3dc326c22ff2640bc0c5a06efc7276da9a40d79371280d. Build6 b9338387-7e8b-422d-95af-2dc2fd1ce07e uploaded and VALID. All36actual public store screenshots COMPLETE with local checksum verification. Current Pro review imagecd26dbf2-6612-4453-888e-af3a1e155628 COMPLETE. Selected build6. Removed ONLY old rejected review item, preserved listing. New joint AppVersion+ProVersion draft5ae9147d-4dfd-47c6-8c0a-3894c4a1a94d has exactly2items, READY_FOR_REVIEW, NOT submitted. No approved app touched.

Duo source audit passes. Actual Duo validation remains open: after targeted restart of idle CoreSimulator service, bootstatus reported Finished at17:27:10, but after more than10minutes native outer display still showed Apple boot logo, inner black, no app process. This is stronger evidence of an environment blocker; root cause not established. Isolated device7CF19FC3 is now shut down, old user's device preserved. Native diagnostic images retained under WorkshopR6/DuoDiagnostics. Do not represent these as app images. User question pending: self-restart Mac / authorize now / prepare only. DO NOT restart Mac without explicit answer; this interrupts their other active apps. Current source and release are saved/pushed.

Exact safe resume helper Artifacts/AppPortfolio-20261016/prepare_suite_workshop_review6.py successfully ran --prepare. --submit requires actual native Duo evidence file suite-native-duo-validation.json, which does NOT exist and must not be fabricated. Old finish_suite_submission.py remains hardcoded build5 and blocked by SHK-DESIGN-HOLD.json. Resume with native Duo test after environment recovery, then submit already prepared joint draft with user authorization already present. No App Review approval needed again. Submission has not yet been sent. NavoOps/FamilyOS/other apps remain sequential, Repair deferred. Existing heartbeat remains PAUSED.

---

# Latest user steering — iPhone Duo, 16 October 2026

SHK Werkstatt remains first; audit and improve other apps individually afterward for Duo updates. No approved calculator is to be merged, removed or silently changed. Adopted Apple app-resizability skill exported to Artifacts/AppPortfolio-20261016/AppleSkills-20261016. Source audit (including independent read-only review) passes all five categories: no fixed screen/orientation/idiom layout, SwiftUI scene lifecycle, native safe areas; launch screen and all four iPad orientations configured. SDK27.1. Actual Duo pose/state verification is NOT complete. Existing device C29D1BDB boot migration failed; separate fresh simulator7CF19FC3-EA2A-4A6D-A028-B3690A1F6E4B was created without erasing existing data. First boot migrated, subsequent clean boot again reported Data Migration Failed, app installation succeeded but launch and SpringBoard stalled. Native outer display showed the Apple boot logo; inner was black. DeviceHub Open control was exercised through actual accessibility. Retain diagnostics; do not call these screenshots app screenshots or claim native Duo readiness/badge. Device shut down after investigation to release host pressure (8GB RAM, approximately9.6GB swap,3.5GB internal free). SSD itself has293GB free.

The current source fingerprint07a37649e58972744a776eaae1d9ccdac8b8920b4e4505622d5765393cd78b63 remains unchanged. Final native phone9/9 workflows PASS (PhoneWorkflowsGreen.xcresult,238.860sec; wrapper's trailing shutdown returned149 because Xcode had already shut the device; TEST EXECUTE SUCCEEDED and zero failures). Final DE/EN phone+iPad capture tests all PASS,48 actual native screenshots plus four actual local StoreKit UI purchase assertions. Phone69 updated dark screenshots now uploaded9per locale, both COMPLETE; iPad upload in progress. Apple intermittent500 recovered. Build5 remains explicitly blocked from submission. Build6 is not yet archived/uploaded/submitted. Duo work must remain explicitly pending if simulator cannot launch.

---

## Latest verification during workshop revision

Production source final fingerprint07a37649e58972744a776eaae1d9ccdac8b8920b4e4505622d5765393cd78b63. Native build6 succeeds. First DE/EN phone+iPad captures passed (48 actual images) before minor Pro symbol correction. Native9-phone workflow run:8passed, original max-text landscape scroll failed from test flick oscillation. Evidence retained PhoneWorkflowsFinal.xcresult. Fixed test driver only (slow measured deltas inside usable viewport), scoped partial-card opt-in requiring title fully visible, actual destination/back checks for all6 max-text cards. Focused LargestTextTargetedScroll.xcresult PASSED54.019sec. Independent code review clears product visual changes and final test-driver delta. Production data/math/StoreKit unchanged. Old one-symbol typo iphone.and.ipad corrected to ipad.and.iphone; final captures and actual UI purchase tap assertions under local SKTest now running. Source stays frozen during native jobs.

Safari auth restored and current rejected SHK version read200. User is actively browsing other tabs; helpers now target the existing ASC tab by exact origin/window without changing the user's front tab. A prior relative GET hit a foreign front tab and returned404; no writes sent. Initial500 errors also occurred on official public API and subsequently recovered. Old build5 remains on design hold; do not execute old submission helper.

# ACTIVE VISUAL REVISION — user correction after the 14:00 checkpoint

User has resumed work and explicitly rejected the mostly white SHK Werkstatt design. The new brief is a cohesive SHK workshop look. Bounded visual revision under way: deep petrol/steel surfaces, copper actions with dark ink, original generated HVAC workbench banner and six native scalable equipment illustrations; root, quick tools, project/module forms, report preview and Pro aligned. Default native dark scheme, full Dynamic Type. Calculations/data/commerce behavior retained. Host source build is now 6; old VALID uploaded build5 is NOT to be submitted. Design hold marker /Artifacts/AppPortfolio-20261016/SHK-DESIGN-HOLD.json blocks the old finish helper.

On user relogin Safari left login, but actual normal App Store Connect page and authenticated/public API reads returned HTTP500 UNEXPECTED_ERROR / timeouts. No submission changes sent. Developer Portal session restored; exact NavoOps App Store profile 49ZRAU2VXH was generated with existing local W4WP547TR8 certificate, confirmed Download page, but not yet downloaded/installed/exported. Public profile read also500. NavoOps remains paused while SHK design is priority. No approved calculators touched. Heartbeat stays PAUSED; this work is directly resumed by current user feedback, not a new scheduled run.

Native design build/captures pending. Old validation below belongs to build5 and is not proof of build6.

---

# Current checkpoint — 16 October 2026, 14:00 Berlin deadline

## Binding scope
Repair Empire deferred. ONLY rejected RohrCalc, KälteCalc, LüftungsCalc, HeizkörperCalc, VolumeCalc and AnlagenCheck combine into SHK Werkstatt. Approved HydroCalc SHK, MAGCalc and BrennerCalc remain unchanged and on sale. Approved Perfect Drop/Rising Steps untouched. One More Floor 1.0(7) already waiting for review. No old listing or repository removed; retire rejected duplicates only after replacement is actually available.

## SHK Werkstatt
Host AnlagenCheck 6804749223 / de.kamilunavo.servicecheck, 1.0(5). Free basics, one project and text report; permanent Pro 9.99 EUR for extra projects and PDF; no subscription, ads, login or tracking. Source commit b0794e0 pushed on codex/shk-werkstatt. Preserve branch: GitHub Pages privacy uses it.

Release source fingerprint 4a67da4aeee9aeba73c3f283cf07a81277c09750bb1962fc04601b1fc1092609 matches final native captures. ReleaseR2 archive/export succeeded. Actual IPA signature, exact host/version/profile, non-debug entitlement, opaque compiled icons and correct Pro SKU verified. IPA SHA256 817fde3a179a15987a10c5b020395267199838b48188c1f1304e296323de1881. Upload succeeded; build 5 VALID, id 1866aa6f-35e8-4c5e-aab2-fe669ee04eb8.

Verified: 69 core tests; three native StoreKit tests on iOS 18.5 (purchase/restore/refund/pending/wrong SKU); eight iPad workflows; six phone workflows plus final transfer/sync/save/relaunch and actual 100 l fill snapshot regression; actual PDF 13-page/Unicode/tail validation. Final DE/EN phone and iPad capture tests passed, 40 actual images. 32 public store images already COMPLETE; five final render/date variants require authenticated refresh. See /Volumes/SSK SSD/Kamilunavo/Builds/SHKWerkstatt-20261016 for receipts, xcresults and StoreUploads. Do not claim all earlier test runs passed: retained failures were fixed or infrastructure-specific.

App metadata, privacy, free price, review notes and Pro 6823486460 / de.kamilunavo.servicecheck.pro configured. Pro review screenshot COMPLETE, draft version 7a38f677-f70e-49e6-aaf4-96e30652cbb7 prepared. Current remote rejected app version 3d763324-d055-426e-9554-0c441eabc82d still selects OLD build 4. Select VALID build 5 before review. Old submission 9b8822d1-1ecb-4403-8f54-b308643a298a is UNRESOLVED_ISSUES; cannot add first IAP there. Remove only rejected review item (not listing), create joint App + Pro submission and verify readback.

## Authentication blocker
Safari App Store Connect and Developer Portal sessions expired around 13:12. User login question pending. Main Safari tab remains login. Existing Developer API key can read/upload but returns 403 for metadata/review writes. No role/key escalation, no forbidden-write retries. No new App Review submission completed. Authorized work remains pending login, not approval.

Prepared helper /Volumes/SSK SSD/Kamilunavo/Artifacts/AppPortfolio-20261016/finish_suite_submission.py is compiled but NOT executed. Default preflight; --execute selects build 5, refreshes images, replaces rejected review item with new joint draft, submits and verifies WAITING_FOR_REVIEW/IN_REVIEW. Inspect actual responses; do not infer success.

## Other rejected apps
NavoOps: repo /Volumes/SSK SSD/Kamilunavo/Projects/NavoOps, codex/navoops-review-20261016, commit 552fa2a pushed. Apple actual objection 2.3.10 Google Play references: DE/EN metadata fixed locally, original relevant icon/header, build 1.3.1(7). 23 native tests pass; actual dashboard inspected; archive succeeds. Export blocked by missing App Store distribution profile and Xcode No Accounts; background portal profile wizard expired, NO profile created. No IPA upload, metadata update or resubmission. apply_navoops_review_metadata.py ready but not executed.

Family Life OS: /Volumes/SSK SSD/Kamilunavo/Projects/FamilyLifeOS sparse monorepo, codex/family-visual-review-20261016. Original information-flow icon, welcome/Today visual pass, real responsive DEBUG screenshot shell and fixed date injection. Final native build and four existing model regressions pass; actual light login, dark Today and largest text captures inspected. Version 0.1.0(10). Full functional/iPad/release verification and substantive 4.3(a) response remain open. No backend/auth/voice/StoreKit implementation change, no App Store update/submission. See its review-2026-10-16/validation.md.

99,9% (Godot repo 99-9) and NavoPass not yet changed. Read actual review messages/source first. Repair Empire remains deferred. Full inventory/review letters, auth-safe helpers and artifacts: /Volumes/SSK SSD/Kamilunavo/Artifacts/AppPortfolio-20261016.

At deadline: save/push work, pause existing apps-bis-14-uhr-fertigstellen heartbeat; no new implementation after 14:00. Continue after renewed user instruction/authentication. No goal object.
