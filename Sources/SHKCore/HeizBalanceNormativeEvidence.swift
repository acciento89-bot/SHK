import Foundation

enum HeizBalanceNormativeSourceRole: String, Codable, Sendable {
    case normativeBasis
    case successorDraft
    case referenceCase
}

enum HeizBalanceNormativeSourceRights: String, Codable, Sendable {
    case notDocumented
    case implementationOnly
    case referenceValidationOnly
    case implementationAndReferenceValidation

    var allowsImplementation: Bool {
        switch self {
        case .implementationOnly, .implementationAndReferenceValidation: true
        case .notDocumented, .referenceValidationOnly: false
        }
    }

    var allowsReferenceValidation: Bool {
        switch self {
        case .referenceValidationOnly, .implementationAndReferenceValidation: true
        case .notDocumented, .implementationOnly: false
        }
    }
}

enum HeizBalanceNormativeSuccessorReviewState: String, Codable, Sendable {
    case notApplicable
    case pending
    case reviewedCurrentBasisRetained
    case requiresProfileUpdate
}

struct HeizBalanceNormativeSourceRecord: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var document: String
    var edition: String
    var role: HeizBalanceNormativeSourceRole
    var metadataReference: String
    var metadataURL: String?
    var doi: String?
    var metadataVerifiedOn: String
    var rights: HeizBalanceNormativeSourceRights
    var rightsReference: String?
    var successorReviewState: HeizBalanceNormativeSuccessorReviewState

    var editionKey: String {
        document.trimmingCharacters(in: .whitespacesAndNewlines)
            + "::"
            + edition.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct HeizBalanceNormativeSourceBasisReport: Equatable, Sendable {
    var requiredEditions: [HeizBalanceCalculationSourceEdition]
    var missingMetadataEditions: [HeizBalanceCalculationSourceEdition]
    var implementationRightsMissingEditions: [HeizBalanceCalculationSourceEdition]
    var pendingSuccessorDraftIDs: [String]
    var profileUpdateRequiredSourceIDs: [String]

    var metadataCoverageComplete: Bool {
        missingMetadataEditions.isEmpty
    }

    var readyForSpecificationValidation: Bool {
        metadataCoverageComplete && implementationRightsMissingEditions.isEmpty
    }

    var readyForNormativeRelease: Bool {
        readyForSpecificationValidation
            && pendingSuccessorDraftIDs.isEmpty
            && profileUpdateRequiredSourceIDs.isEmpty
    }
}

struct HeizBalanceNormativeSpecificationEvidence: Equatable, Sendable {
    var moduleID: HeizBalanceNormativeModuleID
    var sourceID: String
    var specificationVersion: String
    var verifiedBy: String
    var verifiedOn: String
    var independentlyReviewed: Bool
}

struct HeizBalanceNormativeReferenceCaseEvidence: Equatable, Sendable {
    var caseID: String
    var moduleIDs: [HeizBalanceNormativeModuleID]
    var sourceID: String
    var expectationCount: Int
    var independentFromImplementation: Bool
    var validationExecuted: Bool
    var validationPassed: Bool
}

enum HeizBalanceNormativeEvidenceLedger {
    static func sourceBasis(
        profile: HeizBalanceCalculationProfile,
        sources: [HeizBalanceNormativeSourceRecord]
    ) -> HeizBalanceNormativeSourceBasisReport {
        let required = profile.sourceEditions
        let basisSources = sources.filter { $0.role == .normativeBasis }

        let missingMetadata = required.filter { edition in
            !basisSources.contains { source in
                source.document == edition.document && source.edition == edition.edition
            }
        }

        let missingRights = required.filter { edition in
            guard let source = basisSources.first(where: {
                $0.document == edition.document && $0.edition == edition.edition
            }) else {
                return true
            }
            return !source.rights.allowsImplementation
                || source.rightsReference?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
        }

        let pendingDrafts = sources
            .filter { $0.role == .successorDraft && $0.successorReviewState == .pending }
            .map(\.id)
            .sorted()

        let updateRequired = sources
            .filter { $0.successorReviewState == .requiresProfileUpdate }
            .map(\.id)
            .sorted()

        return .init(
            requiredEditions: required,
            missingMetadataEditions: missingMetadata,
            implementationRightsMissingEditions: missingRights,
            pendingSuccessorDraftIDs: pendingDrafts,
            profileUpdateRequiredSourceIDs: updateRequired
        )
    }

    static func moduleEvidence(
        profile: HeizBalanceCalculationProfile,
        sources: [HeizBalanceNormativeSourceRecord],
        specifications: [HeizBalanceNormativeSpecificationEvidence],
        referenceCases: [HeizBalanceNormativeReferenceCaseEvidence]
    ) -> [HeizBalanceNormativeModuleEvidence] {
        let requiredModules = HeizBalanceNormativeReadiness.requiredModules(for: profile.engineID)
        let sourcesByID = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0) })

        return requiredModules.map { module in
            let specificationVerified = specifications.contains { evidence in
                guard evidence.moduleID == module,
                      let source = sourcesByID[evidence.sourceID],
                      source.role == .normativeBasis,
                      source.rights.allowsImplementation,
                      source.rightsReference?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                    return false
                }

                return !evidence.specificationVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !evidence.verifiedBy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !evidence.verifiedOn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && evidence.independentlyReviewed
            }

            let eligibleCases = referenceCases.filter { evidence in
                guard evidence.moduleIDs.contains(module),
                      let source = sourcesByID[evidence.sourceID],
                      source.rights.allowsReferenceValidation,
                      source.rightsReference?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                    return false
                }

                return !evidence.caseID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && evidence.expectationCount > 0
                    && evidence.independentFromImplementation
                    && evidence.validationExecuted
            }

            return HeizBalanceNormativeModuleEvidence(
                moduleID: module,
                specificationVerified: specificationVerified,
                referenceCaseCount: eligibleCases.count,
                passedReferenceCaseCount: eligibleCases.filter(\.validationPassed).count
            )
        }
    }
}

enum HeizBalanceNormativeEvidenceCatalog {
    static let metadataCheckedOn = "2026-08-26"

    static let germanRoomHeatLoad2017_2020PublicMetadata: [HeizBalanceNormativeSourceRecord] = [
        .init(
            id: "din-en-12831-1-2017-09-metadata",
            document: "DIN EN 12831-1",
            edition: "2017-09",
            role: .normativeBasis,
            metadataReference: "DIN Media product metadata",
            metadataURL: "https://www.dinmedia.de/de/norm/din-en-12831-1/261292587",
            doi: "10.31030/2571775",
            metadataVerifiedOn: metadataCheckedOn,
            rights: .notDocumented,
            rightsReference: nil,
            successorReviewState: .notApplicable
        ),
        .init(
            id: "din-ts-12831-1-2020-04-metadata",
            document: "DIN/TS 12831-1",
            edition: "2020-04",
            role: .normativeBasis,
            metadataReference: "DIN Media product metadata",
            metadataURL: "https://www.dinmedia.de/de/vornorm/din-ts-12831-1/316645651",
            doi: "10.31030/3124717",
            metadataVerifiedOn: metadataCheckedOn,
            rights: .notDocumented,
            rightsReference: nil,
            successorReviewState: .notApplicable
        ),
        .init(
            id: "din-en-12831-1-2025-06-draft-metadata",
            document: "DIN EN 12831-1",
            edition: "2025-06 Entwurf",
            role: .successorDraft,
            metadataReference: "DIN Media draft metadata",
            metadataURL: "https://www.dinmedia.de/de/norm-entwurf/din-en-12831-1/390800689",
            doi: "10.31030/3613477",
            metadataVerifiedOn: metadataCheckedOn,
            rights: .notDocumented,
            rightsReference: nil,
            successorReviewState: .pending
        )
    ]
}
