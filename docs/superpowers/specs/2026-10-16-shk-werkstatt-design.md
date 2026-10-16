# SHK Werkstatt — product and integration design

## User brief and authority

16October2026: user reprioritized all rejected apps ahead of Repair until14:00Europe/Berlin(12:00UTC), authorized implementation, fitting original icons, corrections and resubmission. ONLY six rejected products merge: RohrCalc, KälteCalc, LüftungsCalc, HeizkörperCalc, AnlagenCheck and VolumeCalc. Approved HydroCalc SHK, MAGCalc and BrennerCalc remain entirely untouched and on sale. Old rejected listings can be cleaned up only once the common replacement is actually available. No source repository deletion. Existing broad implementation/submission authority applies; work natively and sequentially in this chat.

## Product

SHK Werkstatt is an offline project notebook for heating/ventilation/refrigeration field work. It joins the six rejected calculators into one actual project workflow. Use the unpublished AnlagenCheck App Store entry6804749223/bundlede.kamilunavo.servicecheck as the common host. Existing legacy targets remain as source history, never batch-uploaded. New target/schemeSHKWerkstatt.

Navigation: Projekte / Rechner / Pro, with visible settings/help in the header. Project dashboard has named customer/system context and six clearly separated modules: Wärme, Rohrnetz, Wasserinhalt, Lüftung, Kälte, Service. Single calculators remain directly available outside a project. Modules share typed project data, not six embedded independent apps. Explicit transfers connect heat demand to pipe flow and route section volumes to inventory without double-counting. Existing source formulas remain unchanged and retain assumptions/units.

## Visual direction

Warm near-white canvas, deep ink text, restrained teal primary action and copper accents. Comfortable native typography, full labels at Dynamic Type, rectangular diagram cards and generous rhythm; no forced dark mode, huge all-caps panels or decorative dashboard walls. Relevant native diagrams accompany technical outputs. Responsive iPhone portrait/landscape and iPad split width;44ptminimum controls. All new UI and reports DE/EN. Original icon depicts one technical project plan and pipe/measurement mark, not unrelated imagery or third-party hardware branding. Use generated raster artwork only for the app icon; data graphics remain SwiftUI-native and readable.

## Architecture and data

Extend existing SHKCore and SwiftUI architecture. New SuiteProject Codable value type includes identity/customer/notes, shared heating temperatures, heat rooms, serial pipe sections, volume inventory, airflow terminals, refrigerant measurements and service inputs/checklist. Existing SHK calculators/FieldWork models supply math. Import original VolumeCalculator/VolumeModels/ReferenceData and its tests from the owned AnlagenVolumen repository with provenance and unchanged formulas. Validate finite inputs, genuine units and supported ranges before saving/calculating; missing measurement is distinct from measured zero. No new refrigerant tables, standards certification, pump network simulation or inferred physical defaults.

Project archive uses a versioned JSON envelope and atomic local writes. Missing file is empty; corrupt, unreadable or unsupported-schema file is preserved and blocks overwrite. Failure is shown. Editing uses explicit save and cancellation/discard behavior, never silently destroys the previous project. Sharing works from a real presented activity sheet on iPad and iPhone. Full report includes project identity, dates, entered values, calculated units, provenance and method limits.

Cross-module actions are explicit and idempotent: copy the calculated heating volume flow into the serial pipe route after confirmation; synchronize known pipe-section volumes by stable source IDs and retain manual inventory components. Reject missing/invalid inputs. No hidden clamping presented as a valid engineering answer.

## Commerce

Substantial free basis: all six single calculators, one saved project, text report. One non-consumable lifetimePro unlocks additional projects and structured PDF export. No subscription, ads, tracking or account in this tool. Productde.kamilunavo.servicecheck.pro, targetprice9.99EUR pending actual App Store price availability; never hardcode purchase price in UI. Direct Pro tab shows exact localized StoreKit product displayPrice, permanent entitlement, included features, restore, support/privacy/EULA. Only verified matching transactions grant access. Pending/cancelled/failed/unavailable purchases do not grant it. Finish verified processed transactions, handle updates/current entitlements, revoke refunded access. Existing projects remain readable after entitlement loss; do not delete data.

## Review and release

Latest AnlagenCheck letter: illegible type + non-responsive Servicebericht teilen on iPad Air11M3/iPadOS27. Other five rejected calculators:4.3(a). The consolidated app needs actual connected utility and a clean, distinct UI, not renamed copies. Capture authentic simulator iPhone/iPad screens, including real project detail, linked calculations, working report/share and Pro. Verify actual native AppIcon1024andvariants, opaque and same artwork. Run full core suite, new persistence/transfer/entitlement tests, Release compile, native UI workflow on phone and tablet, sign/archive and inspect product before upload. Complete metadata/privacy/screenshots/review notes and submit one consolidated host and firstIAP together. No claim of Apple approval from upload. Do not remove old rejected entries before the replacement is available. Other rejected apps follow sequentially only after this product is secured.
