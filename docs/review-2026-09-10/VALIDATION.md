# Validation — SHK field workflows, 2026-09-10

Validated source commit: `f857962ff9455f5160c7e8ddb25d66abeb9e6c11`.

[CI run 387](https://github.com/acciento89-bot/SHK/actions/runs/34446330960) passed all ten jobs. The final documentation-only commit does not change the tested source or configuration.

## Build and calculation checks

- 34 core tests passed: 9 XCTest cases and 25 Swift Testing cases.
- Debug simulator builds passed for HeizkoerperCalc, RohrCalc, LueftungsCalc, KalteCalc and AnlagenCheck.
- Unsigned Release device compilation passed for all four revised Calc apps.
- Version and export-compliance checks passed: the four revised apps use 1.0 (5), with non-exempt encryption declared NO. AnlagenCheck remains at build 2.

## Persisted workflow validation

| App | iPhone 17 Pro | iPad Pro 13-inch (M5) |
| --- | --- | --- |
| HeizkörperCalc | Passed | Passed |
| RohrCalc | Passed | Passed |
| LüftungsCalc | Passed | Passed |
| KälteCalc | Passed | Passed |

The automated tests create a named project, add its first room/section/terminal/reading, enter the required measurements, save, terminate and relaunch the app, then open the persisted result. They repeat presentation checks at the largest accessibility text size. Screenshots are retained in the run's review artifacts.

Environment: GitHub-hosted macOS, Xcode 26.6, iOS 26.4 simulators. This is simulator validation, not physical-device testing or a complete manual accessibility audit. The screenshots verify text scaling; they do not establish a separate dark-mode accessibility audit.

Earlier failed runs exposed missing localization resources, inaccessible test selectors, off-screen form fields and intermittent simulator launch timeouts. The final run above passed without suppressing failed assertions or omitting either device family.

## Distribution state

No signed archive, TestFlight upload or App Review submission was produced from this workspace. Debug and unsigned Release builds do not establish distribution signing.

`scripts/archive-for-app-store.sh` is prepared for a Mac with Xcode and the existing Apple Developer signing setup. It requires the developer team ID through `SHK_DEVELOPMENT_TEAM`; no signing key has been created or replaced. The script has been syntax-checked, but its signing/upload steps have not been run here.

Use the app-specific text in [APP_REVIEW.md](APP_REVIEW.md) only for the new build 5. In App Store Connect, select the uploaded build, update screenshots and metadata, then submit. Existing rejected build 4 does not contain these workflows. Apple's review decision remains outstanding.
