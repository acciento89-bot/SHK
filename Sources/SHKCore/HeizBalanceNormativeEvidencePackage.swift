import Foundation

struct HeizBalanceNormativeEvidenceCandidatePackage: Codable, Equatable, Sendable, Identifiable {
    static let schemaVersion = "normative-evidence-candidate-package-v1"

    var schema: String
    var id: String
    var packageVersion: String
    var targetEngineID: HeizBalanceCalculationEngineID
    var createdOn: String
    var submitter: String
    var note: String?
    var sources: [HeizBalanceNormativeSourceRecord]
    var specifications: [SpecificationCandidate]
    var referenceCases: [ReferenceCaseCandidate]

    struct SpecificationCandidate: Codable, Equatable, Sendable, Identifiable {
        var id: String
        var moduleID: HeizBalanceNormativeModuleID
        var sourceID: String
        var specificationVersion: String
        var specificationReference: String
        var note: String?
    }

    struct ReferenceCaseCandidate: Codable, Equatable, Sendable, Identifiable {
        var id: String
        var moduleIDs: [HeizBalanceNormativeModuleID]
        var sourceID: String
        var caseReference: String
        var expectations: [Expectation]
        var note: String?
    }

    struct Expectation: Codable, Equatable, Sendable, Identifiable {
        var id: String
        var key: String
        var expectedValue: Double
        var absoluteTolerance: Double
    }

    enum ValidationIssue: Equatable, Sendable, CustomStringConvertible {
        case wrongSchema
        case missingPackageID
        case missingPackageVersion
        case unsupportedTargetEngine
        case missingCreatedOn
        case missingSubmitter
        case noEvidence
        case duplicateSourceID(String)
        case invalidSource(String)
        case duplicateSpecificationID(String)
        case invalidSpecification(String)
        case unknownSpecificationSource(specificationID: String, sourceID: String)
        case invalidSpecificationSourceRole(specificationID: String, sourceID: String)
        case duplicateReferenceCaseID(String)
        case invalidReferenceCase(String)
        case unknownReferenceCaseSource(caseID: String, sourceID: String)
        case duplicateExpectationID(caseID: String, expectationID: String)
        case duplicateExpectationKey(caseID: String, key: String)
        case invalidExpectation(caseID: String, expectationID: String)

        var description: String {
            switch self {
            case .wrongSchema:
                "Unbekanntes Evidenzpaket-Schema"
            case .missingPackageID:
                "Paket-ID fehlt"
            case .missingPackageVersion:
                "Paketversion fehlt"
            case .unsupportedTargetEngine:
                "Zielprofil ist kein reserviertes Normprofil"
            case .missingCreatedOn:
                "Erstellungsdatum fehlt"
            case .missingSubmitter:
                "Einreicher/Quelle des Pakets fehlt"
            case .noEvidence:
                "Paket enthält weder Spezifikationen noch Referenzfälle"
            case .duplicateSourceID(let id):
                "Doppelte Quellen-ID: \(id)"
            case .invalidSource(let id):
                "Unvollständige Quellenmetadaten: \(id)"
            case .duplicateSpecificationID(let id):
                "Doppelte Spezifikations-ID: \(id)"
            case .invalidSpecification(let id):
                "Ungültiger Spezifikationskandidat: \(id)"
            case .unknownSpecificationSource(let specificationID, let sourceID):
                "Spezifikation \(specificationID) referenziert unbekannte Quelle \(sourceID)"
            case .invalidSpecificationSourceRole(let specificationID, let sourceID):
                "Spezifikation \(specificationID) nutzt keine normative Basisquelle: \(sourceID)"
            case .duplicateReferenceCaseID(let id):
                "Doppelte Referenzfall-ID: \(id)"
            case .invalidReferenceCase(let id):
                "Ungültiger Referenzfallkandidat: \(id)"
            case .unknownReferenceCaseSource(let caseID, let sourceID):
                "Referenzfall \(caseID) referenziert unbekannte Quelle \(sourceID)"
            case .duplicateExpectationID(let caseID, let expectationID):
                "Doppelte Erwartungs-ID in \(caseID): \(expectationID)"
            case .duplicateExpectationKey(let caseID, let key):
                "Doppelter Erwartungsschlüssel in \(caseID): \(key)"
            case .invalidExpectation(let caseID, let expectationID):
                "Ungültiger Erwartungswert in \(caseID): \(expectationID)"
            }
        }
    }

    var validationIssues: [ValidationIssue] {
        var issues: [ValidationIssue] = []

        if schema != Self.schemaVersion { issues.append(.wrongSchema) }
        if id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingPackageID) }
        if packageVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingPackageVersion) }
        if HeizBalanceNormativeReadiness.requiredModules(for: targetEngineID).isEmpty {
            issues.append(.unsupportedTargetEngine)
        }
        if createdOn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingCreatedOn) }
        if submitter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingSubmitter) }
        if specifications.isEmpty && referenceCases.isEmpty { issues.append(.noEvidence) }

        var sourcesByID: [String: HeizBalanceNormativeSourceRecord] = [:]
        var sourceIDs = Set<String>()
        for source in sources {
            let sourceID = source.id.trimmingCharacters(in: .whitespacesAndNewlines)
            if !sourceIDs.insert(sourceID).inserted { issues.append(.duplicateSourceID(source.id)) }

            let rightsReferenceRequired = source.rights != .notDocumented
            let rightsReferencePresent = source.rightsReference?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            if sourceID.isEmpty
                || source.document.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || source.edition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || source.metadataReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || source.metadataVerifiedOn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || (rightsReferenceRequired && !rightsReferencePresent) {
                issues.append(.invalidSource(source.id.isEmpty ? "<ohne ID>" : source.id))
            }
            sourcesByID[source.id] = source
        }

        var specificationIDs = Set<String>()
        for specification in specifications {
            let specificationID = specification.id.trimmingCharacters(in: .whitespacesAndNewlines)
            if !specificationIDs.insert(specificationID).inserted {
                issues.append(.duplicateSpecificationID(specification.id))
            }
            if specificationID.isEmpty
                || specification.specificationVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || specification.specificationReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.invalidSpecification(specification.id.isEmpty ? "<ohne ID>" : specification.id))
            }
            guard let source = sourcesByID[specification.sourceID] else {
                issues.append(.unknownSpecificationSource(specificationID: specification.id, sourceID: specification.sourceID))
                continue
            }
            if source.role != .normativeBasis {
                issues.append(.invalidSpecificationSourceRole(specificationID: specification.id, sourceID: specification.sourceID))
            }
        }

        var caseIDs = Set<String>()
        for referenceCase in referenceCases {
            let caseID = referenceCase.id.trimmingCharacters(in: .whitespacesAndNewlines)
            if !caseIDs.insert(caseID).inserted { issues.append(.duplicateReferenceCaseID(referenceCase.id)) }

            let uniqueModules = Set(referenceCase.moduleIDs)
            if caseID.isEmpty
                || referenceCase.moduleIDs.isEmpty
                || uniqueModules.count != referenceCase.moduleIDs.count
                || referenceCase.caseReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || referenceCase.expectations.isEmpty {
                issues.append(.invalidReferenceCase(referenceCase.id.isEmpty ? "<ohne ID>" : referenceCase.id))
            }
            if sourcesByID[referenceCase.sourceID] == nil {
                issues.append(.unknownReferenceCaseSource(caseID: referenceCase.id, sourceID: referenceCase.sourceID))
            }

            var expectationIDs = Set<String>()
            var expectationKeys = Set<String>()
            for expectation in referenceCase.expectations {
                let expectationID = expectation.id.trimmingCharacters(in: .whitespacesAndNewlines)
                let key = expectation.key.trimmingCharacters(in: .whitespacesAndNewlines)
                if !expectationIDs.insert(expectationID).inserted {
                    issues.append(.duplicateExpectationID(caseID: referenceCase.id, expectationID: expectation.id))
                }
                if !expectationKeys.insert(key).inserted {
                    issues.append(.duplicateExpectationKey(caseID: referenceCase.id, key: expectation.key))
                }
                if expectationID.isEmpty
                    || key.isEmpty
                    || !expectation.expectedValue.isFinite
                    || !expectation.absoluteTolerance.isFinite
                    || expectation.absoluteTolerance < 0 {
                    issues.append(.invalidExpectation(caseID: referenceCase.id, expectationID: expectation.id.isEmpty ? "<ohne ID>" : expectation.id))
                }
            }
        }

        return issues
    }

    var isStructurallyValid: Bool { validationIssues.isEmpty }
}

enum HeizBalanceNormativeEvidenceCandidateTrustState: String, Codable, Equatable, Sendable {
    case quarantined
}

struct HeizBalanceNormativeEvidenceCandidateImportReceipt: Equatable, Sendable {
    var package: HeizBalanceNormativeEvidenceCandidatePackage
    var trustState: HeizBalanceNormativeEvidenceCandidateTrustState

    var canAffectNormativeReadiness: Bool { false }
}

enum HeizBalanceNormativeEvidenceCandidateImportDecoder {
    enum ImportError: LocalizedError, Equatable {
        case unreadableEnvelope
        case unsupportedSchema(String)
        case validationFailed([String])

        var errorDescription: String? {
            switch self {
            case .unreadableEnvelope:
                "Evidenzpaket-Schema konnte nicht gelesen werden."
            case .unsupportedSchema(let schema):
                "Evidenzpaket-Schema wird nicht unterstützt: \(schema)"
            case .validationFailed(let issues):
                "Evidenzpaket ist strukturell ungültig: \(issues.joined(separator: "; "))"
            }
        }
    }

    private struct Envelope: Decodable { var schema: String }

    static func decode(data: Data) throws -> HeizBalanceNormativeEvidenceCandidateImportReceipt {
        let decoder = JSONDecoder()
        guard let envelope = try? decoder.decode(Envelope.self, from: data) else {
            throw ImportError.unreadableEnvelope
        }
        guard envelope.schema == HeizBalanceNormativeEvidenceCandidatePackage.schemaVersion else {
            throw ImportError.unsupportedSchema(envelope.schema)
        }

        let package = try decoder.decode(HeizBalanceNormativeEvidenceCandidatePackage.self, from: data)
        let issues = package.validationIssues.map(\.description)
        guard issues.isEmpty else { throw ImportError.validationFailed(issues) }

        return .init(package: package, trustState: .quarantined)
    }
}
