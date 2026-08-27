import Foundation
import Testing
@testable import SHKCore

@Test func incompleteReviewPreventsQualificationRunnerExecution() {
    let package = makeQualificationPackage()
    var review = makeQualificationReview(for: package)
    review.referenceCaseReviews[0].independentOriginChecked = false
    let runner = QualificationTestRunner(
        descriptor: makeQualificationRunnerDescriptor(),
        valuesByReference: ["CASE-REF-1": ["room.transmissionExteriorW": 1000]]
    )

    let report = HeizBalanceNormativeQualificationHarness.run(
        package: package,
        review: review,
        runner: runner
    )

    #expect(report.reviewEligible == false)
    #expect(report.caseResults.isEmpty)
    #expect(runner.executionCount == 0)
    #expect(report.technicalQualificationPassed == false)
    #expect(report.canAffectNormativeReadiness == false)
}

@Test func runnerEngineMustMatchExactTargetEngine() {
    let package = makeQualificationPackage()
    let review = makeQualificationReview(for: package)
    var descriptor = makeQualificationRunnerDescriptor()
    descriptor.engineID = .technicalPreviewV1
    let runner = QualificationTestRunner(
        descriptor: descriptor,
        valuesByReference: ["CASE-REF-1": ["room.transmissionExteriorW": 1000]]
    )

    let report = HeizBalanceNormativeQualificationHarness.run(
        package: package,
        review: review,
        runner: runner
    )

    #expect(report.structuralIssues.contains("Runner-Engine stimmt nicht mit dem Evidenzpaket überein"))
    #expect(report.caseResults.isEmpty)
    #expect(runner.executionCount == 0)
    #expect(report.technicalQualificationPassed == false)
}

@Test func runnerIdentityVersionAndImplementationFingerprintAreRequired() {
    let package = makeQualificationPackage()
    let review = makeQualificationReview(for: package)
    var descriptor = makeQualificationRunnerDescriptor()
    descriptor.implementationFingerprint = "   "
    let runner = QualificationTestRunner(
        descriptor: descriptor,
        valuesByReference: ["CASE-REF-1": ["room.transmissionExteriorW": 1000]]
    )

    let report = HeizBalanceNormativeQualificationHarness.run(
        package: package,
        review: review,
        runner: runner
    )

    #expect(report.structuralIssues.contains("Runner-Identität, Version oder Implementierungs-Fingerprint fehlt"))
    #expect(runner.executionCount == 0)
    #expect(report.technicalQualificationPassed == false)
}

@Test func controlledRunnerWithinToleranceProducesTechnicalQualificationOnly() throws {
    let package = makeQualificationPackage()
    let review = makeQualificationReview(for: package)
    let runner = QualificationTestRunner(
        descriptor: makeQualificationRunnerDescriptor(),
        valuesByReference: ["CASE-REF-1": ["room.transmissionExteriorW": 1000.4]]
    )

    let report = HeizBalanceNormativeQualificationHarness.run(
        package: package,
        review: review,
        runner: runner
    )

    #expect(report.structuralIssues.isEmpty)
    #expect(report.reviewEligible)
    #expect(report.allReferenceCasesExecuted)
    #expect(report.caseResults.count == 1)
    #expect(report.caseResults[0].passed)
    #expect(report.technicalQualificationPassed)
    #expect(report.canAffectNormativeReadiness == false)
    #expect(runner.executionCount == 1)

    let artifact = try #require(report.caseResults[0].artifact)
    #expect(artifact.packageIdentity == package.identity)
    #expect(artifact.reviewID == review.id)
    #expect(artifact.runner.implementationFingerprint == "test-engine-build-abc123")
    #expect(artifact.caseReference == "CASE-REF-1")
}

@Test func expectedValuesAreComparedByCoreAndOutsideToleranceFails() {
    let package = makeQualificationPackage()
    let review = makeQualificationReview(for: package)
    let runner = QualificationTestRunner(
        descriptor: makeQualificationRunnerDescriptor(),
        valuesByReference: ["CASE-REF-1": ["room.transmissionExteriorW": 1001]]
    )

    let report = HeizBalanceNormativeQualificationHarness.run(
        package: package,
        review: review,
        runner: runner
    )

    #expect(report.caseResults[0].validation?.passed == false)
    #expect(report.caseResults[0].passed == false)
    #expect(report.technicalQualificationPassed == false)
}

@Test func missingActualMetricFailsQualification() throws {
    let package = makeQualificationPackage()
    let review = makeQualificationReview(for: package)
    let runner = QualificationTestRunner(
        descriptor: makeQualificationRunnerDescriptor(),
        valuesByReference: ["CASE-REF-1": [:]]
    )

    let report = HeizBalanceNormativeQualificationHarness.run(
        package: package,
        review: review,
        runner: runner
    )

    let validation = try #require(report.caseResults[0].validation)
    #expect(validation.failures.contains { failure in
        failure.key == "room.transmissionExteriorW" && failure.reason == .missingActualValue
    })
    #expect(report.technicalQualificationPassed == false)
}

@Test func unexpectedActualMetricFailsQualificationEvenWhenExpectedMetricPasses() {
    let package = makeQualificationPackage()
    let review = makeQualificationReview(for: package)
    let runner = QualificationTestRunner(
        descriptor: makeQualificationRunnerDescriptor(),
        metricsByReference: [
            "CASE-REF-1": [
                .init(key: "room.transmissionExteriorW", value: 1000),
                .init(key: "unreviewed.extraMetric", value: 42)
            ]
        ]
    )

    let report = HeizBalanceNormativeQualificationHarness.run(
        package: package,
        review: review,
        runner: runner
    )

    #expect(report.caseResults[0].validation?.passed == true)
    #expect(report.caseResults[0].unexpectedActualMetricKeys == ["unreviewed.extraMetric"])
    #expect(report.caseResults[0].passed == false)
    #expect(report.technicalQualificationPassed == false)
}

@Test func duplicateActualMetricKeyFailsQualification() {
    let package = makeQualificationPackage()
    let review = makeQualificationReview(for: package)
    let runner = QualificationTestRunner(
        descriptor: makeQualificationRunnerDescriptor(),
        metricsByReference: [
            "CASE-REF-1": [
                .init(key: "room.transmissionExteriorW", value: 1000),
                .init(key: "room.transmissionExteriorW", value: 1000)
            ]
        ]
    )

    let report = HeizBalanceNormativeQualificationHarness.run(
        package: package,
        review: review,
        runner: runner
    )

    #expect(report.caseResults[0].duplicateActualMetricKeys == ["room.transmissionExteriorW"])
    #expect(report.caseResults[0].passed == false)
    #expect(report.technicalQualificationPassed == false)
}

@Test func runnerFailureIsRecordedAndCannotBecomePass() {
    let package = makeQualificationPackage()
    let review = makeQualificationReview(for: package)
    let runner = QualificationTestRunner(
        descriptor: makeQualificationRunnerDescriptor(),
        valuesByReference: [:],
        failingReferences: ["CASE-REF-1"]
    )

    let report = HeizBalanceNormativeQualificationHarness.run(
        package: package,
        review: review,
        runner: runner
    )

    #expect(report.caseResults[0].artifact == nil)
    #expect(report.caseResults[0].executionError != nil)
    #expect(report.allReferenceCasesExecuted == false)
    #expect(report.technicalQualificationPassed == false)
}

@Test func productionNormativeQualificationRunnerRemainsUnavailable() {
    let availability = HeizBalanceNormativeQualificationProductionRegistry.availability(
        for: .deRoomHeatLoad2017_2020
    )

    #expect(availability.isRunnerRegistered == false)
    #expect(availability.reason.contains("Kein produktiver Norm-Qualifikationsrunner registriert"))
}

@Test func technicallyPassingQualificationStillCannotUnlockNormativeReadiness() {
    let package = makeQualificationPackage()
    let review = makeQualificationReview(for: package)
    let runner = QualificationTestRunner(
        descriptor: makeQualificationRunnerDescriptor(),
        valuesByReference: ["CASE-REF-1": ["room.transmissionExteriorW": 1000]]
    )
    let report = HeizBalanceNormativeQualificationHarness.run(
        package: package,
        review: review,
        runner: runner
    )
    #expect(report.technicalQualificationPassed)
    #expect(report.canAffectNormativeReadiness == false)

    var profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    profile.validationState = .released
    profile.normativeOutputAllowed = true
    let readiness = HeizBalanceNormativeReadiness.evaluate(profile: profile, evidence: [])

    #expect(readiness.canProduceNormativeOutput == false)
}

private final class QualificationTestRunner: HeizBalanceNormativeQualificationRunner {
    let descriptor: HeizBalanceNormativeQualificationRunnerDescriptor
    private let metricsByReference: [String: [HeizBalanceNormativeQualificationMetric]]
    private let failingReferences: Set<String>
    private(set) var executionCount = 0

    convenience init(
        descriptor: HeizBalanceNormativeQualificationRunnerDescriptor,
        valuesByReference: [String: [String: Double]],
        failingReferences: Set<String> = []
    ) {
        let metrics = valuesByReference.mapValues { values in
            values.map { .init(key: $0.key, value: $0.value) }
        }
        self.init(
            descriptor: descriptor,
            metricsByReference: metrics,
            failingReferences: failingReferences
        )
    }

    init(
        descriptor: HeizBalanceNormativeQualificationRunnerDescriptor,
        metricsByReference: [String: [HeizBalanceNormativeQualificationMetric]],
        failingReferences: Set<String> = []
    ) {
        self.descriptor = descriptor
        self.metricsByReference = metricsByReference
        self.failingReferences = failingReferences
    }

    func execute(
        request: HeizBalanceNormativeQualificationExecutionRequest
    ) throws -> [HeizBalanceNormativeQualificationMetric] {
        executionCount += 1
        if failingReferences.contains(request.caseReference) {
            throw QualificationTestError.fixtureUnavailable(request.caseReference)
        }
        return metricsByReference[request.caseReference] ?? []
    }
}

private enum QualificationTestError: LocalizedError {
    case fixtureUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .fixtureUnavailable(let reference):
            "Test-Fixture nicht verfügbar: \(reference)"
        }
    }
}

private func makeQualificationRunnerDescriptor() -> HeizBalanceNormativeQualificationRunnerDescriptor {
    .init(
        runnerID: "controlled-test-runner",
        runnerVersion: "1",
        engineID: .deRoomHeatLoad2017_2020,
        implementationFingerprint: "test-engine-build-abc123"
    )
}

private func makeQualificationPackage() -> HeizBalanceNormativeEvidenceCandidatePackage {
    let basisSource = HeizBalanceNormativeSourceRecord(
        id: "basis-source",
        document: "DIN EN 12831-1",
        edition: "2017-09",
        role: .normativeBasis,
        metadataReference: "Documented source metadata",
        metadataURL: nil,
        doi: nil,
        metadataVerifiedOn: "2026-08-27",
        rights: .implementationOnly,
        rightsReference: "RIGHTS-BASIS-1",
        successorReviewState: .notApplicable
    )
    let referenceSource = HeizBalanceNormativeSourceRecord(
        id: "reference-source",
        document: "Independent reference source",
        edition: "1",
        role: .referenceCase,
        metadataReference: "Reference metadata",
        metadataURL: nil,
        doi: nil,
        metadataVerifiedOn: "2026-08-27",
        rights: .referenceValidationOnly,
        rightsReference: "RIGHTS-CASE-1",
        successorReviewState: .notApplicable
    )

    return .init(
        schema: HeizBalanceNormativeEvidenceCandidatePackage.schemaVersion,
        id: "qualification-package",
        packageVersion: "1",
        targetEngineID: .deRoomHeatLoad2017_2020,
        createdOn: "2026-08-27",
        submitter: "Fixture Author",
        note: nil,
        sources: [basisSource, referenceSource],
        specifications: [
            .init(
                id: "spec-1",
                moduleID: .transmissionExterior,
                sourceID: basisSource.id,
                specificationVersion: "candidate-v1",
                specificationReference: "SPEC-REF-1",
                note: nil
            )
        ],
        referenceCases: [
            .init(
                id: "case-1",
                moduleIDs: [.transmissionExterior],
                sourceID: referenceSource.id,
                caseReference: "CASE-REF-1",
                expectations: [
                    .init(
                        id: "expected-1",
                        key: "room.transmissionExteriorW",
                        expectedValue: 1000,
                        absoluteTolerance: 0.5
                    )
                ],
                note: nil
            )
        ]
    )
}

private func makeQualificationReview(
    for package: HeizBalanceNormativeEvidenceCandidatePackage
) -> HeizBalanceNormativeEvidenceReviewRecord {
    .init(
        schema: HeizBalanceNormativeEvidenceReviewRecord.schemaVersion,
        id: "review-qualified-1",
        packageIdentity: package.identity,
        reviewer: "Independent Reviewer",
        reviewedOn: "2026-08-27",
        sourceReviews: package.sources.map {
            .init(
                sourceID: $0.id,
                metadataChecked: true,
                rightsReferenceChecked: true,
                note: nil
            )
        },
        specificationReviews: package.specifications.map {
            .init(
                specificationID: $0.id,
                sourceTraceabilityChecked: true,
                independentTechnicalReviewReference: "TECH-REVIEW-\($0.id)",
                note: nil
            )
        },
        referenceCaseReviews: package.referenceCases.map {
            .init(
                referenceCaseID: $0.id,
                sourceTraceabilityChecked: true,
                independentOriginChecked: true,
                expectationTranscriptionChecked: true,
                independentReviewReference: "CASE-REVIEW-\($0.id)",
                note: nil
            )
        },
        note: nil
    )
}
