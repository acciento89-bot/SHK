import Testing
@testable import SHKCore

@Test func normativeProfileRemainsLockedWithoutEvidence() {
    let profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    let report = HeizBalanceNormativeReadiness.evaluate(profile: profile, evidence: [])

    #expect(report.requiredModules.count == 10)
    #expect(report.missingSpecificationModules.count == report.requiredModules.count)
    #expect(report.missingReferenceValidationModules.count == report.requiredModules.count)
    #expect(report.sourceBasisReady == false)
    #expect(report.profileLifecycleReady == false)
    #expect(report.explicitReleaseFlagEnabled == false)
    #expect(report.canProduceNormativeOutput == false)
}

@Test func normativeReadinessRequiresEveryModuleSourceBasisAndExplicitRelease() {
    var profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    profile.validationState = .referenceValidated
    profile.normativeOutputAllowed = true

    let evidence = HeizBalanceNormativeReadiness.requiredModules(for: profile.engineID).map {
        HeizBalanceNormativeModuleEvidence(
            moduleID: $0,
            specificationVerified: true,
            referenceCaseCount: 2,
            passedReferenceCaseCount: 2
        )
    }
    let sourceBasis = readySourceBasis(for: profile)

    let report = HeizBalanceNormativeReadiness.evaluate(
        profile: profile,
        evidence: evidence,
        sourceBasis: sourceBasis
    )
    #expect(report.missingSpecificationModules.isEmpty)
    #expect(report.missingReferenceValidationModules.isEmpty)
    #expect(report.sourceBasisReady)
    #expect(report.profileLifecycleReady)
    #expect(report.explicitReleaseFlagEnabled)
    #expect(report.canProduceNormativeOutput)
}

@Test func completeModulesCannotBypassMissingSourceBasis() {
    var profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    profile.validationState = .released
    profile.normativeOutputAllowed = true

    let evidence = HeizBalanceNormativeReadiness.requiredModules(for: profile.engineID).map {
        HeizBalanceNormativeModuleEvidence(
            moduleID: $0,
            specificationVerified: true,
            referenceCaseCount: 3,
            passedReferenceCaseCount: 3
        )
    }

    let report = HeizBalanceNormativeReadiness.evaluate(profile: profile, evidence: evidence)
    #expect(report.missingSpecificationModules.isEmpty)
    #expect(report.missingReferenceValidationModules.isEmpty)
    #expect(report.sourceBasisReady == false)
    #expect(report.canProduceNormativeOutput == false)
}

@Test func oneFailedModuleKeepsNormativeOutputLocked() {
    var profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    profile.validationState = .released
    profile.normativeOutputAllowed = true

    var evidence = HeizBalanceNormativeReadiness.requiredModules(for: profile.engineID).map {
        HeizBalanceNormativeModuleEvidence(
            moduleID: $0,
            specificationVerified: true,
            referenceCaseCount: 3,
            passedReferenceCaseCount: 3
        )
    }

    evidence[0].passedReferenceCaseCount = 2
    let report = HeizBalanceNormativeReadiness.evaluate(
        profile: profile,
        evidence: evidence,
        sourceBasis: readySourceBasis(for: profile)
    )

    #expect(report.sourceBasisReady)
    #expect(report.missingSpecificationModules.isEmpty)
    #expect(report.missingReferenceValidationModules == [evidence[0].moduleID])
    #expect(report.canProduceNormativeOutput == false)
}

@Test func referenceCaseValidatorChecksToleranceAndMissingMetrics() {
    let expectations = [
        HeizBalanceReferenceMetricExpectation(key: "room.totalW", expectedValue: 1000, absoluteTolerance: 1),
        HeizBalanceReferenceMetricExpectation(key: "room.ventilationW", expectedValue: 250, absoluteTolerance: 0.5)
    ]

    let passing = HeizBalanceReferenceCaseValidator.validate(
        caseID: "synthetic-pass",
        expectations: expectations,
        actualValues: [
            "room.totalW": 1000.5,
            "room.ventilationW": 249.7
        ]
    )
    #expect(passing.passed)

    let failing = HeizBalanceReferenceCaseValidator.validate(
        caseID: "synthetic-fail",
        expectations: expectations,
        actualValues: ["room.totalW": 1004]
    )
    #expect(failing.passed == false)
    #expect(failing.failures.count == 2)
}

private func readySourceBasis(
    for profile: HeizBalanceCalculationProfile
) -> HeizBalanceNormativeSourceBasisReport {
    let sources = profile.sourceEditions.enumerated().map { index, edition in
        HeizBalanceNormativeSourceRecord(
            id: "qualified-source-\(index)",
            document: edition.document,
            edition: edition.edition,
            role: .normativeBasis,
            metadataReference: "Qualified test source",
            metadataURL: nil,
            doi: nil,
            metadataVerifiedOn: "2026-08-26",
            rights: .implementationAndReferenceValidation,
            rightsReference: "TEST-RIGHTS-\(index)",
            successorReviewState: .notApplicable
        )
    }

    return HeizBalanceNormativeEvidenceLedger.sourceBasis(profile: profile, sources: sources)
}
