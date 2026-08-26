import Foundation

struct HeizBalanceNormativeEvidenceReviewRecord: Codable, Equatable, Sendable, Identifiable {
    static let schemaVersion = "normative-evidence-review-v1"

    var schema: String
    var id: String
    var packageIdentity: HeizBalanceNormativeEvidenceCandidatePackage.Identity
    var reviewer: String
    var reviewedOn: String
    var sourceReviews: [SourceReview]
    var specificationReviews: [SpecificationReview]
    var referenceCaseReviews: [ReferenceCaseReview]
    var note: String?

    struct SourceReview: Codable, Equatable, Sendable, Identifiable {
        var sourceID: String
        var metadataChecked: Bool
        var rightsReferenceChecked: Bool
        var note: String?

        var id: String { sourceID }
    }

    struct SpecificationReview: Codable, Equatable, Sendable, Identifiable {
        var specificationID: String
        var sourceTraceabilityChecked: Bool
        var independentTechnicalReviewReference: String?
        var note: String?

        var id: String { specificationID }
    }

    struct ReferenceCaseReview: Codable, Equatable, Sendable, Identifiable {
        var referenceCaseID: String
        var sourceTraceabilityChecked: Bool
        var independentOriginChecked: Bool
        var expectationTranscriptionChecked: Bool
        var independentReviewReference: String?
        var note: String?

        var id: String { referenceCaseID }
    }
}

struct HeizBalanceNormativeEvidenceReviewAssessment: Equatable, Sendable {
    var structuralIssues: [String]
    var separationOfDutiesSatisfied: Bool
    var missingSourceReviewIDs: [String]
    var incompleteSourceReviewIDs: [String]
    var missingSpecificationReviewIDs: [String]
    var incompleteSpecificationReviewIDs: [String]
    var missingReferenceCaseReviewIDs: [String]
    var incompleteReferenceCaseReviewIDs: [String]

    var eligibleForQualificationReview: Bool {
        structuralIssues.isEmpty
            && separationOfDutiesSatisfied
            && missingSourceReviewIDs.isEmpty
            && incompleteSourceReviewIDs.isEmpty
            && missingSpecificationReviewIDs.isEmpty
            && incompleteSpecificationReviewIDs.isEmpty
            && missingReferenceCaseReviewIDs.isEmpty
            && incompleteReferenceCaseReviewIDs.isEmpty
    }

    /// A completed review is deliberately only a prerequisite for a later qualification step.
    /// It never feeds normative readiness directly.
    var canAffectNormativeReadiness: Bool { false }
}

enum HeizBalanceNormativeEvidenceReviewEvaluator {
    static func evaluate(
        package: HeizBalanceNormativeEvidenceCandidatePackage,
        review: HeizBalanceNormativeEvidenceReviewRecord
    ) -> HeizBalanceNormativeEvidenceReviewAssessment {
        var structuralIssues: [String] = []

        if review.schema != HeizBalanceNormativeEvidenceReviewRecord.schemaVersion {
            structuralIssues.append("Unbekanntes Review-Schema")
        }
        if review.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            structuralIssues.append("Review-ID fehlt")
        }
        if review.packageIdentity != package.identity {
            structuralIssues.append("Review gehört nicht exakt zu dieser Paket-ID und Version")
        }
        if review.reviewer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            structuralIssues.append("Prüfer fehlt")
        }
        if review.reviewedOn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            structuralIssues.append("Prüfdatum fehlt")
        }

        let reviewerKey = normalizedActor(review.reviewer)
        let submitterKey = normalizedActor(package.submitter)
        let separationOfDutiesSatisfied = !reviewerKey.isEmpty
            && !submitterKey.isEmpty
            && reviewerKey != submitterKey

        let sourceIDs = Set(package.sources.map(\.id))
        let specificationIDs = Set(package.specifications.map(\.id))
        let referenceCaseIDs = Set(package.referenceCases.map(\.id))

        let sourceReviewIDs = review.sourceReviews.map(\.sourceID)
        let specificationReviewIDs = review.specificationReviews.map(\.specificationID)
        let referenceCaseReviewIDs = review.referenceCaseReviews.map(\.referenceCaseID)

        if Set(sourceReviewIDs).count != sourceReviewIDs.count {
            structuralIssues.append("Doppelte Quellenprüfung")
        }
        if Set(specificationReviewIDs).count != specificationReviewIDs.count {
            structuralIssues.append("Doppelte Spezifikationsprüfung")
        }
        if Set(referenceCaseReviewIDs).count != referenceCaseReviewIDs.count {
            structuralIssues.append("Doppelte Referenzfallprüfung")
        }

        let unknownSourceReviews = Set(sourceReviewIDs).subtracting(sourceIDs).sorted()
        if !unknownSourceReviews.isEmpty {
            structuralIssues.append("Unbekannte Quellenprüfungen: " + unknownSourceReviews.joined(separator: ", "))
        }
        let unknownSpecificationReviews = Set(specificationReviewIDs).subtracting(specificationIDs).sorted()
        if !unknownSpecificationReviews.isEmpty {
            structuralIssues.append("Unbekannte Spezifikationsprüfungen: " + unknownSpecificationReviews.joined(separator: ", "))
        }
        let unknownReferenceCaseReviews = Set(referenceCaseReviewIDs).subtracting(referenceCaseIDs).sorted()
        if !unknownReferenceCaseReviews.isEmpty {
            structuralIssues.append("Unbekannte Referenzfallprüfungen: " + unknownReferenceCaseReviews.joined(separator: ", "))
        }

        let sourceReviewsByID = Dictionary(
            uniqueKeysWithValues: review.sourceReviews.enumerated().compactMap { index, item in
                sourceReviewIDs.firstIndex(of: item.sourceID) == index ? (item.sourceID, item) : nil
            }
        )
        let specificationReviewsByID = Dictionary(
            uniqueKeysWithValues: review.specificationReviews.enumerated().compactMap { index, item in
                specificationReviewIDs.firstIndex(of: item.specificationID) == index ? (item.specificationID, item) : nil
            }
        )
        let referenceCaseReviewsByID = Dictionary(
            uniqueKeysWithValues: review.referenceCaseReviews.enumerated().compactMap { index, item in
                referenceCaseReviewIDs.firstIndex(of: item.referenceCaseID) == index ? (item.referenceCaseID, item) : nil
            }
        )

        let missingSourceReviews = package.sources
            .map(\.id)
            .filter { sourceReviewsByID[$0] == nil }
            .sorted()

        let incompleteSourceReviews = package.sources.compactMap { source -> String? in
            guard let item = sourceReviewsByID[source.id] else { return nil }
            guard item.metadataChecked else { return source.id }

            switch source.role {
            case .normativeBasis:
                guard source.rights.allowsImplementation,
                      source.rightsReference?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                      item.rightsReferenceChecked else {
                    return source.id
                }
            case .referenceCase:
                guard source.rights.allowsReferenceValidation,
                      source.rightsReference?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                      item.rightsReferenceChecked else {
                    return source.id
                }
            case .successorDraft:
                guard source.successorReviewState != .pending,
                      source.successorReviewState != .requiresProfileUpdate else {
                    return source.id
                }
            }
            return nil
        }.sorted()

        let missingSpecificationReviews = package.specifications
            .map(\.id)
            .filter { specificationReviewsByID[$0] == nil }
            .sorted()

        let incompleteSpecificationReviews = package.specifications.compactMap { specification -> String? in
            guard let item = specificationReviewsByID[specification.id] else { return nil }
            let reviewReference = item.independentTechnicalReviewReference?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return item.sourceTraceabilityChecked && !reviewReference.isEmpty ? nil : specification.id
        }.sorted()

        let missingReferenceCaseReviews = package.referenceCases
            .map(\.id)
            .filter { referenceCaseReviewsByID[$0] == nil }
            .sorted()

        let incompleteReferenceCaseReviews = package.referenceCases.compactMap { referenceCase -> String? in
            guard let item = referenceCaseReviewsByID[referenceCase.id] else { return nil }
            let reviewReference = item.independentReviewReference?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return item.sourceTraceabilityChecked
                && item.independentOriginChecked
                && item.expectationTranscriptionChecked
                && !reviewReference.isEmpty
                ? nil
                : referenceCase.id
        }.sorted()

        return .init(
            structuralIssues: structuralIssues,
            separationOfDutiesSatisfied: separationOfDutiesSatisfied,
            missingSourceReviewIDs: missingSourceReviews,
            incompleteSourceReviewIDs: incompleteSourceReviews,
            missingSpecificationReviewIDs: missingSpecificationReviews,
            incompleteSpecificationReviewIDs: incompleteSpecificationReviews,
            missingReferenceCaseReviewIDs: missingReferenceCaseReviews,
            incompleteReferenceCaseReviewIDs: incompleteReferenceCaseReviews
        )
    }

    private static func normalizedActor(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }
}
