# HeizBalance – Normative Evidence Qualification Contract

## Scope

Batch 45 adds a controlled technical qualification harness after the Batch-44 independent review stage.

The qualification harness is deliberately **not** an evidence-acceptance or normative-release stage.

A technically passing qualification report still has:

`canAffectNormativeReadiness == false`

## Why a separate execution stage exists

Candidate packages contain independently sourced expected values. Those expected values must never become executable truth merely because they were imported or reviewed.

A trustworthy comparison needs two separated sides:

1. independently reviewed expected values from the candidate package
2. actual values produced by a controlled implementation runner

The runner must not receive the expected values it is being tested against.

## Runner request

`HeizBalanceNormativeQualificationExecutionRequest` contains only:

- exact package ID + version
- exact review ID
- target engine ID
- reference-case ID
- reference-case lookup/reference
- covered normative module IDs

It deliberately does **not** contain:

- expected numeric values
- tolerances
- an expected PASS/FAIL state
- an imported qualification decision

The runner must resolve the executable fixture independently from `caseReference`.

## Runner identity

Every runner is identified by:

- runner ID
- runner version
- engine ID
- implementation fingerprint

All fields are mandatory for qualification execution.

The implementation fingerprint binds the execution artifact to the exact tested implementation/build identity rather than to a generic app name.

A runner whose engine does not exactly match the candidate target engine is rejected before any reference case executes.

## Review prerequisite

The harness first evaluates the Batch-44 review again.

If the review is not `eligibleForQualificationReview`:

- the runner is not executed
- no execution artifacts are produced
- technical qualification cannot pass

The review must still match the exact package ID + version.

## Execution artifacts

For each reference case, the controlled runner produces actual metrics only.

The harness creates an execution artifact bound to:

- package identity
- review ID
- runner identity/version
- implementation fingerprint
- reference-case ID/reference
- module IDs
- actual metrics

There is no user/imported PASS field in the artifact.

## Comparison

Expected values and tolerances remain on the independent candidate side.

The harness converts those expectations into the existing `HeizBalanceReferenceCaseValidator` and compares the runner-produced actual values in Core.

Qualification fails when any expected metric is:

- missing
- non-finite
- outside its absolute tolerance

Batch 45 additionally fails a case when actual output contains:

- duplicate metric keys
- unexpected metric keys that were not part of the independently reviewed expectations

This prevents unreviewed output fields from silently entering a successful qualification artifact.

## Runner failures

If a runner cannot resolve or execute a reference fixture:

- the case records an execution error
- no execution artifact exists for that case
- `allReferenceCasesExecuted` becomes false
- technical qualification fails

No exception is converted into a guessed or manual PASS.

## Technical qualification result

`technicalQualificationPassed` is calculated only when:

- runner identity is structurally complete
- runner engine matches the package engine
- review is independently complete
- reference cases exist
- every case executes
- every expected metric passes the Core tolerance comparison
- no duplicate actual metric key exists
- no unexpected actual metric key exists

The result is computed. It is not imported and there is no setter for a trusted PASS decision.

## Production availability

Batch 45 deliberately registers **no production normative qualification runner** for `de-room-heat-load-2017-2020`.

Reason:

- the reserved normative engine is still not released
- executable independently reviewed reference fixtures are not yet registered
- protected normative formulas/tables are still not copied or invented

The app exposes this state as `Produktiver Norm-Runner: nicht registriert`.

There is therefore no production UI button that can execute a normative qualification run in Batch 45.

## No readiness promotion

Even a passing controlled test harness report has:

`canAffectNormativeReadiness == false`

Batch 45 does not create `HeizBalanceNormativeSpecificationEvidence` or `HeizBalanceNormativeReferenceCaseEvidence` entries accepted by the normative evidence ledger.

A future, separately designed evidence-acceptance/promotion stage must decide whether a technically qualified artifact may be promoted into ledger evidence. That later stage must preserve exact provenance, review, runner, implementation-fingerprint and case-result bindings.

Until that later acceptance stage is explicitly implemented, validated and released, the reserved normative profile remains locked.
