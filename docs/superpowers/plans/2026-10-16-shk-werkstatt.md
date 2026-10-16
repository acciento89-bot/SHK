# SHK Werkstatt Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Native sequential execution explicitly follows the user's one-app-at-a-time request and broad implementation/submission authority.

**Goal:** Ship one useful, polished six-module SHK project app with lifetimePro, replacing only the rejected calculators.

**Architecture:** Add SHKWerkstatt target on unpublished AnlagenCheck bundle. Reuse tested SHKCore math, import owned Volume core, add typed shared projects and safe local archive. New SwiftUI shell/editors/report and verified StoreKit2.

**Tech Stack:** Swift6, SwiftUI iOS17+, Foundation, Charts, StoreKit2, UIKitPDF/activities, XcodeGen; no external runtime packages.

**Spec:** docs/superpowers/specs/2026-10-16-shk-werkstatt-design.md

## Global Constraints

- Only six rejected products merge. Approved calculator apps and all approved games remain unchanged.
- Host6804749223 / de.kamilunavo.servicecheck, targetSHKWerkstatt; no legacy batch uploads.
- iOS17+, iPhone/iPad, DE/EN,44pttargets and Dynamic Type.
- No invented engineering formulas or missing-as-zero outputs.
- One free project/all basic calculators/text report; lifetimePro for additional projects/PDF; no subscriptions/ads/tracking.
- Native heavy builds/simulators serial on8GBMac. Stop new implementation at14:00Berlin16Oct2026.

## Review Focus

- Malformed/future archive must survive failed loads and subsequent save attempts unchanged.
- Repeated pipe synchronization cannot duplicate imported liters or remove manual components.
- Empty/NaN/negative/out-of-domain fields cannot become plausible valid reports.
- iPad share sheet must actually appear; rotation, keyboard and large text cannot cover Save/Back.
- Wrong/unverified/pending/refunded purchase cannot unlockPro; previously saved projects survive entitlement loss.

### Task1: Shared project and archive

Files: Sources/SHKCore/VolumeModels.swift,VolumeCalculator.swift,ReferenceData.swift (owned import); SuiteProject.swift,SuiteArchive.swift,SuiteAccess.swift; Tests/SHKCoreTests/SuiteProjectTests.swift,SuiteArchiveTests.swift,SuiteAccessTests.swift plus importedVolume tests.

Interfaces: SuiteProject.init(name:customer:), heating/pipe/volume/air/cold/service typed values, transferHeatingFlow(), synchronizePipeVolumes(), reportText(language:); SuiteArchive(url:).load()/save(_:); SuiteAccess.canCreateProject(count:hasPro:).

- [ ] Run existing swift test --jobs2 baseline and retain exact result.
- [ ] Write failing tests: six modules persist with UUIDs; source sync repeated twice same volume and manual component; invalid source leaves destination unchanged; missing!=zero; future/corrupt archive does not overwrite; free count0allows/1blocks,Proallows; report contains all actual sections/units.
- [ ] Run new tests RED, implement minimum typed model/archive/access policy and imported tested math, then run full swift test GREEN.
- [ ] Commit coherent core integration with exact imported source provenance.

### Task2: Unified native product and commerce

Files: Apps/SHKWerkstatt/SHKWerkstattApp.swift,SuiteTheme.swift,SuiteHome.swift,SuiteProjectViews.swift,SuiteModuleEditors.swift,SuiteCalculators.swift,SuiteStore.swift,SuiteProView.swift,SuiteReport.swift,Assets.xcassets,PrivacyInfo.xcprivacy,DE/EN resources; project.yml; UI tests; scripts/archive-suite.sh; suite StoreKit config.

Interfaces: projectStore.save()returnsBool/error preserves last file; module editors use SuiteProject bindings; StoreKit verified current/updated entitlement drives hasPro; ReportShare presents activity for text or generated PDF.

- [ ] Add UI tests before product: create named project, edit across modules, save/relaunch, synchronize twice, navigate parentBack, actually open/cancel share on iPhone/iPad; missing inputs and largestDynamicType.
- [ ] Implement one consistent light shell, six connected editors and accessible native diagrams; no nested legacy app shells.
- [ ] Implement matching-product StoreKit verification/restore/pending/refund/error states and visible permanentPro shop. UI-only test overrides must be debug-only and absent in Release.
- [ ] Generate original icon using built-in imagegen, inspect it, add opaque1024andnativevariants with provenance; do not modify approved sibling apps.
- [ ] Generate Xcode project, build/UITest phone then tablet serially, fix actual regressions; inspect screenshots and actual native icon variants.
- [ ] Independent read-only review, full core tests, Release compilation/archive and exact artifact/source binding; commit/push verified slices.

### Task3: Single host metadata and review

Files: docs/review-2026-10-16/ (metadata/review notes/proof), scripts for scoped archive only, current task handoff.

- [ ] Read existing hostIAPs/builds/current version in authenticatedSafari before modifying anything.
- [ ] Complete DE/EN distinct metadata and current privacy, actual iPhone/iPad screenshots, permanentPro product/price/review screenshot and restore instructions.
- [ ] Upload signed common host only, select processed build, submit host and firstIAP together as authorized. Record actual submission state/errors, not assumed success.
- [ ] Leave the five superseded rejected entries until replacement is actually available, then clean up only those rejected listings. Keep approved calculators untouched.
- [ ] Continue NavoOps, Family LifeOS,99.9,NavoPass sequentially, using their actual letters; maintain deadline14:00 handoff.
