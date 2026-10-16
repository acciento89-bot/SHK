# iPhone Duo readiness — SHK Werkstatt

Status: source audit passes; actual device-pose validation remains open. No optimized-for-Duo claim or badge is authorized by the evidence so far.

## Current implementation

- Xcode27.1 / iOS27.1SDK, minimumiOS17. SwiftUIApp/WindowGroup and native navigation/tabbars/sheets.
- Generated launch screen; all four iPad orientations; no UIRequiresFullScreen override.
- No main-screen size/scale, orientation, device-idiom layout branch, symmetric safearea, cached inset or geometry-dependent view identity found across the app and imported SHKCore source.
- Adaptive tools grid; hero preserves its full artwork using fit; text wraps with DynamicType. State is owned by stable SwiftUI containers.
- Independent read-only audit completed16October2026 without source findings.

## Evidence already complete for build6

69core regressions pass (22XCTest+47SwiftTesting). Nine native phone workflows pass, including persistence/relaunch, actual share sheet, all six tools, actual measurement entry, transfer/sync and largest accessibility text in landscape.48actual DE/EN phone+iPad captures pass, including four real UI purchase taps against local StoreKit test configuration. These checks do not substitute for Duo pose changes.

## Duo validation attempted

Existing simulatorC29D1BDB-6FCC-4C2F-BDB1-B2324BF43CA3 failed data migration before app launch. Its data were preserved. A new isolated Duo27.1 simulator7CF19FC3-EA2A-4A6D-A028-B3690A1F6E4B completed first migration, but a later clean boot again reported Data Migration Failed. App installation succeeded, while app launch and SpringBoard stalled. Actual outer-screen image showed the Apple boot logo and inner image was black. These are simulator diagnostics, not screenshots of the app. DeviceHub Open was pressed using its real accessibility control. No product fix was inferred from a boot failure.

Runtime diagnostics and retained interrupted launch result: external Build directory WorkshopR6. Device shut down after the investigation. Host was under substantial memory pressure (8GBRAM, about9.6GBswap); cause not conclusively established. SSD had293GB free and internal disk3.5GB free. Do not describe SSD storage as the blocker.

## Required next native checks

1. Closed outer display: navigation, every calculator, Pro and restore, input keyboard and sheets.
2. Open inner display: asymmetric safe areas and vertical native bars; no hidden controls or stretched artwork.
3. Fold/unfold while editing an unsaved project and an actual measurement; retain entered values and presented state.
4. Rotate both displays, partially open pose, and resize in split view. Retain project/draft state and reachable actions.
5. Open the actual system share sheet in narrow and wide configurations, with native anchors.
6. Largest DynamicType: readable cards, form labels, values and purchase/restore actions.
7. Capture actual supported Duo store assets only after these checks pass; verify current AppStoreConnect display slots and image specifications.

## Portfolio sequence

Finish SHK Werkstatt first. Then inspect the actual review issue and Duo layout for NavoOps, FamilyLifeOS,99.9% and NavoPass individually. Approved HydroCalcSHK,MAGCalc,BrennerCalc and approved games remain available; future updates require their own audit, testing and suitable improvements. No approved app is to be deleted or merged as part of this work.

## Official sources

- https://developer.apple.com/iphone-duo/prepare/
- https://developer.apple.com/videos/play/tech-talks/111461/
- Apple app-resizability skill exported via xcrun agent skills export to Artifacts/AppPortfolio-20261016/AppleSkills-20261016 (read locally).
