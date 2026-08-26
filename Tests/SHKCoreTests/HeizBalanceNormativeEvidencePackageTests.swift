import Foundation
import Testing
@testable import SHKCore

@Test func validEvidencePackageImportIsAlwaysQuarantined() throws {
    let package = makeValidCandidatePackage()
    let data = try JSONEncoder().encode(package)

    let receipt = try HeizBalanceNormativeEvidenceCandidateImportDecoder.decode(data: data)

    #expect(receipt.package.id == package.id)
    #expect(receipt.trustState == .quarantined)
    #expect(receipt.canAffectNormativeReadiness == false)
}

@Test func importedCandidateCannotBypassNormativeReadiness() throws {
    var profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    profile.validationState = .released
    profile.normativeOutputAllowed = true

    let package = makeValidCandidatePackage()
    let receipt = try HeizBalanceNormativeEvidenceCandidateImportDecoder.decode(
        data: JSONEncoder().encode(package)
    )
    #expect(receipt.canAffectNormativeReadiness == false)

    let report = HeizBalanceNormativeReadiness.evaluate(profile: profile, evidence: [])
    #expect(report.sourceBasisReady == false)
    #expect(report.canProduceNormativeOutput == false)
}

@Test func candidatePackageRejectsUnknownSpecificationSource() {
    var package = makeValidCandidatePackage()
    package.specifications[0].sourceID = "unknown-source"

    #expect(package.validationIssues.contains {
        if case .unknownSpecificationSource = $0 { return true }
        return false
    })
}

@Test func candidatePackageRejectsDuplicateExpectationKeys() {
    var package = makeValidCandidatePackage()
    let original = package.referenceCases[0].expectations[0]
    package.referenceCases[0].expectations.append(
        .init(
            id: "expectation-2",
            key: original.key,
            expectedValue: original.expectedValue + 1,
            absoluteTolerance: original.absoluteTolerance
        )
    )

    #expect(package.validationIssues.contains {
        if case .duplicateExpectationKey = $0 { return true }
        return false
    })
}

@Test func candidatePackageRejectsTechnicalPreviewAsNormativeTarget() {
    var package = makeValidCandidatePackage()
    package.targetEngineID = .technicalPreviewV1

    #expect(package.validationIssues.contains(.unsupportedTargetEngine))
}

@Test func candidatePackageRequiresRightsReferenceWhenRightsAreClaimed() {
    var package = makeValidCandidatePackage()
    package.sources[0].rights = .implementationAndReferenceValidation
    package.sources[0].rightsReference = nil

    #expect(package.validationIssues.contains {
        if case .invalidSource(let id) = $0 { return id == package.sources[0].id }
        return false
    })
}

@Test func candidatePackageRejectsReferenceCaseWithoutIndependentExpectedMetrics() {
    var package = makeValidCandidatePackage()
    package.referenceCases[0].expectations = []

    #expect(package.validationIssues.contains {
        if case .invalidReferenceCase(let id) = $0 { return id == package.referenceCases[0].id }
        return false
    })
}

private func makeValidCandidatePackage() -> HeizBalanceNormativeEvidenceCandidatePackage {
    let basisSource = HeizBalanceNormativeSourceRecord(
        id: "basis-source",
        document: "DIN EN 12831-1",
        edition: "2017-09",
        role: .normativeBasis,
        metadataReference: "Documented source metadata",
        metadataURL: nil,
        doi: nil,
        metadataVerifiedOn: "2026-08-26",
        rights: .implementationOnly,
        rightsReference: "CANDIDATE-RIGHTS-REF",
        successorReviewState: .notApplicable
    )
    let caseSource = HeizBalanceNormativeSourceRecord(
        id: "reference-source",
        document: "Independent reference case source",
        edition: "1",
        role: .referenceCase,
        metadataReference: "Reference-case metadata",
        metadataURL: nil,
        doi: nil,
        metadataVerifiedOn: "2026-08-26",
        rights: .referenceValidationOnly,
        rightsReference: "CANDIDATE-CASE-RIGHTS-REF",
        successorReviewState: .notApplicable
    )

    return .init(
        schema: HeizBalanceNormativeEvidenceCandidatePackage.schemaVersion,
        id: "candidate-package-1",
        packageVersion: "1",
        targetEngineID: .deRoomHeatLoad2017_2020,
        createdOn: "2026-08-26",
        submitter: "Test fixture",
        note: "Structurally valid but intentionally untrusted.",
        sources: [basisSource, caseSource],
        specifications: [
            .init(
                id: "spec-transmission-exterior",
                moduleID: .transmissionExterior,
                sourceID: basisSource.id,
                specificationVersion: "candidate-v1",
                specificationReference: "SPEC-REF-1",
                note: nil
            )
        ],
        referenceCases: [
            .init(
                id: "reference-case-1",
                moduleIDs: [.transmissionExterior],
                sourceID: caseSource.id,
                caseReference: "CASE-REF-1",
                expectations: [
                    .init(
                        id: "expectation-1",
                        key: "room.transmissionExteriorW",
                        expectedValue: 1234,
                        absoluteTolerance: 0.5
                    )
                ],
                note: nil
            )
        ]
    )
}
