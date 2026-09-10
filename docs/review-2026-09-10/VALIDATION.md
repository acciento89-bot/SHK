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

## Distribution state — updated 2026-09-10

All four revised apps were distribution-signed and uploaded as version 1.0, build 5 using the existing App Store Connect credentials in `appideenchatgpt` and GitHub-hosted macOS. The successful upload jobs are in [the release run](https://github.com/acciento89-bot/appideenchatgpt/actions/runs/34503135017). The release packaging now generates the existing app icons and explicitly selects the AppIcon asset catalog; this resolved Apple's missing-icon validation errors.

Fresh native iPhone 17 Pro Max and iPad Pro 13-inch screenshots were captured from the same application source in [the screenshot run](https://github.com/acciento89-bot/appideenchatgpt/actions/runs/34502913598). App-specific German and English descriptions, screenshots and review notes were uploaded, and the exact VALID build 5 was selected before submission.

Apple confirmed `WAITING_FOR_REVIEW` for KälteCalc, RohrCalc and LüftungsCalc in [the submission run](https://github.com/acciento89-bot/appideenchatgpt/actions/runs/34507204308), and for HeizkörperCalc in [its successful finish job](https://github.com/acciento89-bot/appideenchatgpt/actions/runs/34508668954/job/102977038831). The other job in that finish run concerns VolumeCalc and does not change HeizkörperCalc's successful submission.

These are confirmed submissions, not Apple approvals or publication. The credentials were used inside the runner; no secret values were added to the repository or reports.
