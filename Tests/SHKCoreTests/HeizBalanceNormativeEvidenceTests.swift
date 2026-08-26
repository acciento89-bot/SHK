import Testing
@testable import SHKCore

@Test func publicMetadataCatalogDocumentsBasisButCannotUnlockNormativeRelease() {
    let profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    let sources = HeizBalanceNormativeEvidenceCatalog.germanRoomHeatLoad2017_2020PublicMetadata
    let report = HeizBalanceNormativeEvidenceLedger.sourceBasis(profile: profile, sources: sources)

    #expect(report.metadataCoverageComplete)
    #expect(report.missingMetadataEditions.isEmpty)
    #expect(report.implementationRightsMissingEditions.count == 2)
    #expect(report.pendingSuccessorDraftIDs == ["din-en-12831-1-2025-06-draft-metadata"])
    #expect(report.readyForSpecificationValidation == false)
    #expect(report.readyForNormativeRelease == false)
}

@Test func metadataOnlyRightsCannotQualifySpecificationOrReferenceEvidence() {
    let profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    let sources = HeizBalanceNormativeEvidenceCatalog.germanRoomHeatLoad2017_2020PublicMetadata

    let evidence = HeizBalanceNormativeEvidenceLedger.moduleEvidence(
        profile: profile,
        sources: sources,
        specifications: [
            .init(
                moduleID: .transmissionExterior,
                sourceID: "din-en-12831-1-2017-09-metadata",
                specificationVersion: "candidate-v1",
                verifiedBy: "Reviewer",
                verifiedOn: "2026-08-26",
                independentlyReviewed: true
            )
        ],
        referenceCases: [
            .init(
                caseID: "candidate-case",
                moduleIDs: [.transmissionExterior],
                sourceID: "din-en-12831-1-2017-09-metadata",
                expectationCount: 3,
                independentFromImplementation: true,
                validationExecuted: true,
                validationPassed: true
            )
        ]
    )

    let transmission = evidence.first { $0.moduleID == .transmissionExterior }
    #expect(transmission?.specificationVerified == false)
    #expect(transmission?.referenceCaseCount == 0)
    #expect(transmission?.passedReferenceCaseCount == 0)
}

@Test func qualifiedIndependentEvidenceFeedsOnlyItsDeclaredModules() {
    let profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    let source = HeizBalanceNormativeSourceRecord(
        id: "licensed-basis",
        document: "DIN EN 12831-1",
        edition: "2017-09",
        role: .normativeBasis,
        metadataReference: "Licensed implementation source",
        metadataURL: nil,
        doi: nil,
        metadataVerifiedOn: "2026-08-26",
        rights: .implementationAndReferenceValidation,
        rightsReference: "LICENSE-REF-1",
        successorReviewState: .notApplicable
    )

    let evidence = HeizBalanceNormativeEvidenceLedger.moduleEvidence(
        profile: profile,
        sources: [source],
        specifications: [
            .init(
                moduleID: .transmissionExterior,
                sourceID: source.id,
                specificationVersion: "spec-v1",
                verifiedBy: "Independent reviewer",
                verifiedOn: "2026-08-26",
                independentlyReviewed: true
            )
        ],
        referenceCases: [
            .init(
                caseID: "reference-pass",
                moduleIDs: [.transmissionExterior],
                sourceID: source.id,
                expectationCount: 4,
                independentFromImplementation: true,
                validationExecuted: true,
                validationPassed: true
            )
        ]
    )

    let transmission = evidence.first { $0.moduleID == .transmissionExterior }
    let adjacent = evidence.first { $0.moduleID == .transmissionAdjacent }

    #expect(transmission?.specificationVerified == true)
    #expect(transmission?.referenceCaseCount == 1)
    #expect(transmission?.passedReferenceCaseCount == 1)
    #expect(adjacent?.specificationVerified == false)
    #expect(adjacent?.referenceCaseCount == 0)
}

@Test func failedIndependentReferenceCaseRemainsVisibleAndBlocksCoverage() {
    let profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    let source = HeizBalanceNormativeSourceRecord(
        id: "licensed-reference",
        document: "Reference source",
        edition: "1",
        role: .referenceCase,
        metadataReference: "Documented expected results",
        metadataURL: nil,
        doi: nil,
        metadataVerifiedOn: "2026-08-26",
        rights: .referenceValidationOnly,
        rightsReference: "REFERENCE-RIGHTS-1",
        successorReviewState: .notApplicable
    )

    let evidence = HeizBalanceNormativeEvidenceLedger.moduleEvidence(
        profile: profile,
        sources: [source],
        specifications: [],
        referenceCases: [
            .init(
                caseID: "reference-fail",
                moduleIDs: [.ventilationMinimum],
                sourceID: source.id,
                expectationCount: 2,
                independentFromImplementation: true,
                validationExecuted: true,
                validationPassed: false
            )
        ]
    )

    let ventilation = evidence.first { $0.moduleID == .ventilationMinimum }
    #expect(ventilation?.referenceCaseCount == 1)
    #expect(ventilation?.passedReferenceCaseCount == 0)
    #expect(ventilation?.referenceCoverageComplete == false)
}

@Test func pendingSuccessorDraftBlocksReleaseEvenWhenCurrentBasisRightsAreDocumented() {
    let profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    var sources = profile.sourceEditions.enumerated().map { index, edition in
        HeizBalanceNormativeSourceRecord(
            id: "basis-\(index)",
            document: edition.document,
            edition: edition.edition,
            role: .normativeBasis,
            metadataReference: "Qualified basis",
            metadataURL: nil,
            doi: nil,
            metadataVerifiedOn: "2026-08-26",
            rights: .implementationAndReferenceValidation,
            rightsReference: "RIGHTS-\(index)",
            successorReviewState: .notApplicable
        )
    }
    sources.append(
        .init(
            id: "successor-draft",
            document: "DIN EN 12831-1",
            edition: "2025-06 Entwurf",
            role: .successorDraft,
            metadataReference: "Draft metadata",
            metadataURL: nil,
            doi: nil,
            metadataVerifiedOn: "2026-08-26",
            rights: .notDocumented,
            rightsReference: nil,
            successorReviewState: .pending
        )
    )

    let report = HeizBalanceNormativeEvidenceLedger.sourceBasis(profile: profile, sources: sources)
    #expect(report.readyForSpecificationValidation)
    #expect(report.readyForNormativeRelease == false)
    #expect(report.pendingSuccessorDraftIDs == ["successor-draft"])
}
