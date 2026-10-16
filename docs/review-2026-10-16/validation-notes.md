# SHK Werkstatt — release validation, 16 October 2026

Only the six rejected calculators combine in unpublished AnlagenCheck host 6804749223 (`de.kamilunavo.servicecheck`, 1.0 build 5). Approved HydroCalc SHK, MAGCalc and BrennerCalc remain untouched and on sale. No sibling listing has been retired.

## Verified implementation

- Full core suite: 69 passing tests (22 XCTest + 47 Swift Testing), including optional actual readings, idempotent pipe/inventory transfer, archive boundaries, guarded radiator counts and six-discipline report content. Original calculator formulas remain unchanged.
- Eight original native iPad workflows passed in `IPadWorkflowR3.xcresult`: project creation, persistence/system sharing, six parent navigation paths, accessible large-text/landscape navigation, component/cold sheets, visible Pro restore, heating transfer and repeated pipe/inventory synchronization.
- Native iPhone transfer, repeated synchronization and save/relaunch passed in `FinalPhoneInputsR2.xcresult` (40.643 seconds). Six earlier phone workflows also passed.
- Actual native StoreKit tests passed on iOS18.5: permanent purchase, entitlement reload/restore, refund, pending approval and wrong-product handling. Three tests in `CommerceIOS185SpaceFixed.xcresult`. The iOS26.5 local StoreKit configuration error is retained as an infrastructure failure and is not counted as a pass.
- Native UIKit/CoreText/PDFKit probe passed 13 pages, technical Unicode, entry240 and the report tail sentinel. This is automated pagination/content evidence; no visual PDF inspection is claimed.

## Actual fill regression

`FillValueEvidence.xcresult` proved a stale sheet snapshot: the background inventory had 100 litres, while a newly opened fill sheet used zero litres despite valid explicit 0/100 meter readings and an activated native confirmation switch. The sheet item now carries a value snapshot captured when the user opens it, rather than reading a potentially stale parent presentation closure. The initial empty meter field remains missing; it is never silently converted to a measurement of zero.

`FillSnapshotFixed.xcresult` passed the native regression on iPhone16ProMax/iOS18.5 (37.245 seconds): add a 100-litre component, assert the frozen 100-litre baseline, reject untouched start reading, explicitly enter zero, accept the completed reading and dismiss the sheet. Focused independent read-only review approved this correction. Cancel/change/reopen is suggested additional coverage and is not claimed as executed.

## Final screenshots and distribution

Final source fingerprint: `4a67da4aeee9aeba73c3f283cf07a81277c09750bb1962fc04601b1fc1092609`. Native German/English captures passed on actual iPhone16ProMax and iPadPro13 simulators (`Store-Phone69R5.xcresult`, `Store-IPad13R2.xcresult`). Forty native images were captured, retaining the actual interface and clearly labeled example data. Public store selection is eight images per device/language; the Pro review image shows the actual local StoreKit price and restore control.

A fresh Release archive and manual App Store export both succeeded. Exported `SHKWerkstatt.ipa` SHA256: `817fde3a179a15987a10c5b020395267199838b48188c1f1304e296323de1881`. Inspection verified the exact host/version, App Store profile, valid distribution signature, `get-task-allow=false`, opaque compiled icons, production Pro SKU, no tracking/data-collection declaration, and absence of StoreKit test configuration, screenshot fixtures, UI-test launch namespace and unrelated approved-product identifiers. Archive and native captures have the same source fingerprint. The superseded earlier archive must not be uploaded.

Artifacts and complete result bundles are retained outside Git at `/Volumes/SSK SSD/Kamilunavo/Builds/SHKWerkstatt-20261016`.

## App Store Connect state

Host name, German/English metadata, free download price, review notes, privacy link, first permanent Pro product/localizations/9.99EUR price/availability and review image are configured. Existing 32 uploaded screenshots read back COMPLETE. Final recapture matches 27 uploaded images byte-for-byte; five visually corresponding recaptures await authenticated refresh. No screenshot was removed by the failed API-key-only refresh attempt.

The production build upload is in progress. The current rejected submission does not permit adding the first Pro purchase; it must be replaced with a joint app/IAP draft after the new build is processed. The Safari App Store Connect session expired; the user has been asked to sign in directly in Safari. The existing Developer API key cannot alter review submissions or store screenshots. No successful App Review submission or Apple approval is claimed.
