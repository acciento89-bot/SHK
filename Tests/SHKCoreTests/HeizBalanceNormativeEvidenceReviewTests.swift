import Testing
@testable import SHKCore

@Test func identicalCandidateRevisionIsRecognizedWithoutCreatingNewIdentity() {
    let package = makeReviewCandidatePackage()
    let decision = HeizBalanceNormativeEvidenceCandidateRevisionPolicy.decision(
        existing: [package],
        incoming: package
    )

    #expect(decision == .identicalRevision)
}

@Test func changedContentUnderSamePackageIDAndVersionIsAConflict() {
    let package = makeReviewCandidatePackage()
    var changed = package
    changed.referenceCases[0].expectations[0].expectedValue += 10

    let decision = HeizBalanceNormativeEvidenceCandidateRevisionPolicy.decision(
        existing: [package],
        incoming: changed
    )

    #expect(decision == .conflictingRevision)
}

@Test func changedContentUnderNewVersionCreatesNewIdentity() {
    let package = makeReviewCandidatePackage()
    var changed = package
    changed.packageVersion = "2"
    changed.referenceCases[0].expectations[0].expectedValue += 10

    let decision = HeizBalanceNormativeEvidenceCandidateRevisionPolicy.decision(
        existing: [package],
        incoming: changed
    )

    #expect(decision == .insertNewIdentity)
    #expect(changed.identity != package.identity)
}

@Test func submitterCannotReviewOwnCandidatePackage() {
    let package = makeReviewCandidatePackage()
    var review = makeCompleteReview(for: package)
    review.reviewer = "  TEST SUBMITTER "

    let assessment = HeizBalanceNormativeEvidenceReviewEvaluator.evaluate(
        package: package,
        review: review
    )

    #expect(assessment.separationOfDutiesSatisfied == false)
    #expect(assessment.eligibleForQualificationReview == false)
    #expect(assessment.canAffectNormativeReadiness == false)
}

@Test func reviewMustMatchExactPackageVersion() {
    let package = makeReviewCandidatePackage()
    var review = makeCompleteReview(for: package)
    review.packageIdentity.packageVersion = "999"

    let assessment = HeizBalanceNormativeEvidenceReviewEvaluator.evaluate(
        package: package,
        review: review
    )

    #expect(assessment.structuralIssues.contains("Review gehört nicht exakt zu dieser Paket-ID und Version"))
    #expect(assessment.eligibleForQualificationReview == false)
}

@Test func completeIndependentReviewOnlyQualifiesForLaterQualificationReview() {
    let package = makeReviewCandidatePackage()
    let review = makeCompleteReview(for: package)

    let assessment = HeizBalanceNormativeEvidenceReviewEvaluator.evaluate(
        package: package,
        review: review
    )

    #expect(assessment.structuralIssues.isEmpty)
    #expect(assessment.separationOfDutiesSatisfied)
    #expect(assessment.missingSourceReviewIDs.isEmpty)
    #expect(assessment.incompleteSourceReviewIDs.isEmpty)
    #expect(assessment.missingSpecificationReviewIDs.isEmpty)
    #expect(assessment.incompleteSpecificationReviewIDs.isEmpty)
    #expect(assessment.missingReferenceCaseReviewIDs.isEmpty)
    #expect(assessment.incompleteReferenceCaseReviewIDs.isEmpty)
    #expect(assessment.eligibleForQualificationReview)
    #expect(assessment.canAffectNormativeReadiness == false)
}

@Test func uncheckedRightsReferenceBlocksQualificationReview() {
    let package = makeReviewCandidatePackage()
    var review = makeCompleteReview(for: package)
    review.sourceReviews[0].rightsReferenceChecked = false

    let assessment = HeizBalanceNormativeEvidenceReviewEvaluator.evaluate(
        package: package,
        review: review
    )

    #expect(assessment.incompleteSourceReviewIDs.contains(package.sources[0].id))
    #expect(assessment.eligibleForQualificationReview == false)
}

@Test func missingIndependentReferenceCaseOriginBlocksQualificationReview() {
    let package = makeReviewCandidatePackage()
    var review = makeCompleteReview(for: package)
    review.referenceCaseReviews[0].independentOriginChecked = false

    let assessment = HeizBalanceNormativeEvidenceReviewEvaluator.evaluate(
        package: package,
        review: review
    )

    #expect(assessment.incompleteReferenceCaseReviewIDs == [package.referenceCases[0].id])
    #expect(assessment.eligibleForQualificationReview == false)
}

@Test func reviewNeverFeedsNormativeReadinessDirectly() {
    var profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020
    profile.validationState = .released
    profile.normativeOutputAllowed = true

    let package = makeReviewCandidatePackage()
    let review = makeCompleteReview(for: package)
    let assessment = HeizBalanceNormativeEvidenceReviewEvaluator.evaluate(package: package, review: review)
    #expect(assessment.eligibleForQualificationReview)
    #expect(assessment.canAffectNormativeReadiness == false)

    let readiness = HeizBalanceNormativeReadiness.evaluate(profile: profile, evidence: [])
    #expect(readiness.canProduceNormativeOutput == false)
}

private func makeReviewCandidatePackage() -> HeizBalanceNormativeEvidenceCandidatePackage {
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
        metadataVerifiedOn: "2026-08-26",
        rights: .referenceValidationOnly,
        rightsReference: "RIGHTS-CASE-1",
        successorReviewState: .notApplicable
    )

    return .init(
        schema: HeizBalanceNormativeEvidenceCandidatePackage.schemaVersion,
        id: "review-package",
        packageVersion: "1",
        targetEngineID: .deRoomHeatLoad2017_2020,
        createdOn: "2026-08-26",
        submitter: "Test Submitter",
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

private func makeCompleteReview(
    for package: HeizBalanceNormativeEvidenceCandidatePackage
) -> HeizBalanceNormativeEvidenceReviewRecord {
    .init(
        schema: HeizBalanceNormativeEvidenceReviewRecord.schemaVersion,
        id: "review-1",
        packageIdentity: package.identity,
        reviewer: "Independent Reviewer",
        reviewedOn: "2026-08-26",
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
