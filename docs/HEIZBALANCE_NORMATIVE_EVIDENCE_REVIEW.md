# HeizBalance – Normative Evidence Review Contract

## Scope

Batch 44 extends the normative-evidence quarantine introduced in Batches 42–43 with immutable package revisions and a separated human review stage.

This stage is deliberately **not** a normative qualification stage and is deliberately **not** connected to the normative readiness gate.

## Immutable candidate identity

A candidate package revision is identified by:

- package ID
- package version

Together they form `HeizBalanceNormativeEvidenceCandidatePackage.Identity`.

Rules:

1. Same ID + same version + identical content → recognized as the existing revision.
2. Same ID + same version + changed content → hard conflict.
3. Changed content requires a new package version.
4. Different versions of the same package ID may coexist in quarantine.
5. Local persistence is checked defensively for conflicting duplicate identities.
6. A persisted conflicting duplicate causes the quarantine to load fail-closed rather than guessing which revision is authoritative.
7. The trust state is always reset to `quarantined` when persisted candidates are loaded.

This prevents silent replacement of reference expectations, source metadata, specifications or rights assertions under an already known package revision.

## Separation of duties

A review record uses schema:

`normative-evidence-review-v1`

Every review is bound to the exact candidate package identity.

The evaluator requires:

- non-empty review ID
- exact package ID + version match
- non-empty reviewer
- non-empty review date
- reviewer different from package submitter after normalized comparison
- no duplicate or unknown source/specification/reference-case review records

The package submitter cannot satisfy the separated-review gate by reviewing their own package.

## Source review

Every package source must have a review record.

The review checks source metadata explicitly.

For normative basis sources, a complete source review additionally requires:

- source rights allowing implementation
- documented rights reference
- reviewer confirmation that the rights reference was checked

For reference-case sources, a complete source review additionally requires:

- source rights allowing reference validation
- documented rights reference
- reviewer confirmation that the rights reference was checked

Successor drafts remain blocked while their successor review state is pending or requires a profile update.

## Specification review

Every specification candidate must have a review record containing:

- confirmed source traceability
- a non-empty independent technical review reference

A package-provided specification reference is not treated as an independent project review by itself.

## Reference-case review

Every reference-case candidate must have a review record containing:

- confirmed source traceability
- confirmed independent origin
- confirmed expectation-value transcription/check
- a non-empty independent review reference

The package may carry expected numeric values, but it cannot carry its own trusted PASS decision.

## Review result

`HeizBalanceNormativeEvidenceReviewAssessment.eligibleForQualificationReview` becomes true only when all structural, separation-of-duties, source, specification and reference-case review requirements are complete.

Even then:

`canAffectNormativeReadiness == false`

A completed Batch-44 review means only:

> eligible for a later, separate qualification review

It does **not** mean:

- specification verified for normative release
- reference case passed against the implementation
- source rights finally qualified by the product
- normative heat-load calculation released
- GEG/BEG/Procedure-B conformity

## Review snapshots

The iOS app stores review snapshots separately from candidate packages.

Rules:

- review history is keyed by review ID
- the same review ID with identical content is recognized
- the same review ID with changed content is rejected
- edited follow-up reviews receive a new review ID
- old review snapshots are not silently overwritten
- review persistence has no API that feeds normative readiness

The review workspace may save an incomplete snapshot for audit/work-in-progress purposes. The evaluator still marks it as incomplete.

## UI contract

The evidence quarantine UI shows:

- exact package ID + version identity
- quarantine state
- number of review snapshots
- latest review status
- separated review workspace
- explicit `no direct gate influence` status

The review workspace captures:

- reviewer identity
- review date
- source metadata/rights checks
- specification traceability and independent technical-review references
- reference-case source/origin/transcription checks and independent review references
- review history

The calculation-status screen shows candidate and review counts while continuing to state that neither import nor preliminary review has direct normative gate influence.

## Still required after Batch 44

A future qualification stage must remain separate from this review stage and must independently establish the evidence objects accepted by `HeizBalanceNormativeEvidenceLedger`.

Until that later stage is explicitly implemented, validated and released, the reserved normative profile remains locked.
