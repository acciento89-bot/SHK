import Foundation

struct HeizBalanceVDI3805RadiatorMappedDataset: Codable, Hashable, Identifiable {
    static let schemaVersion = "vdi-3805-part6-mapped-v1"
    static let supportedStandardPart = "VDI 3805 Blatt 6"

    var schema: String
    var id: String
    var manufacturer: String
    var datasetName: String
    var datasetVersion: String
    var standardReference: String
    var mappingProfileVersion: String
    var source: HeizBalanceRadiatorProductDataset.Source
    var products: [MappedProduct]

    struct MappedProduct: Codable, Hashable, Identifiable {
        var id: String
        var series: String
        var model: String
        var kind: String?
        var nominalPowerDeltaT50W: Double
        var exponent: Double
        var widthMM: Double?
        var heightMM: Double?
        var depthMM: Double?
        var articleNumber: String?
        var sourceReference: String?
        var originalRecordReference: String?
    }

    enum ValidationIssue: Hashable, CustomStringConvertible {
        case wrongSchema
        case missingDatasetID
        case missingManufacturer
        case missingDatasetName
        case missingDatasetVersion
        case missingStandardReference
        case unsupportedStandardPart
        case missingMappingProfileVersion
        case missingSourceReference
        case noProducts
        case duplicateProductID(String)
        case invalidProduct(String)

        var description: String {
            switch self {
            case .wrongSchema:
                "Unbekanntes VDI-3805-Mappingschema"
            case .missingDatasetID:
                "Datensatz-ID fehlt"
            case .missingManufacturer:
                "Hersteller fehlt"
            case .missingDatasetName:
                "Datensatzname fehlt"
            case .missingDatasetVersion:
                "Datenstand/Version fehlt"
            case .missingStandardReference:
                "VDI-3805-Standardbezug fehlt"
            case .unsupportedStandardPart:
                "Standardbezug ist nicht VDI 3805 Blatt 6"
            case .missingMappingProfileVersion:
                "Mappingprofil-Version fehlt"
            case .missingSourceReference:
                "Quellenreferenz fehlt"
            case .noProducts:
                "Datensatz enthält keine Produkte"
            case .duplicateProductID(let id):
                "Doppelte Produkt-ID: \(id)"
            case .invalidProduct(let id):
                "Ungültige Produktdaten: \(id)"
            }
        }
    }

    var validationIssues: [ValidationIssue] {
        var issues: [ValidationIssue] = []

        if schema != Self.schemaVersion { issues.append(.wrongSchema) }
        if id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingDatasetID) }
        if manufacturer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingManufacturer) }
        if datasetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingDatasetName) }
        if datasetVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingDatasetVersion) }

        let trimmedStandardReference = standardReference.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedStandardReference.isEmpty {
            issues.append(.missingStandardReference)
        } else if !trimmedStandardReference.localizedCaseInsensitiveContains(Self.supportedStandardPart) {
            issues.append(.unsupportedStandardPart)
        }

        if mappingProfileVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.missingMappingProfileVersion)
        }
        if source.reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.missingSourceReference)
        }
        if products.isEmpty { issues.append(.noProducts) }

        var seen = Set<String>()
        for product in products {
            let productID = product.id.trimmingCharacters(in: .whitespacesAndNewlines)
            if !seen.insert(productID).inserted {
                issues.append(.duplicateProductID(product.id))
            }

            let displayName = [product.series, product.model]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
            let dimensionsValid = [product.widthMM, product.heightMM, product.depthMM]
                .compactMap { $0 }
                .allSatisfy { $0.isFinite && $0 > 0 }

            if productID.isEmpty
                || productID.contains(HeizBalanceRadiatorProductDataset.compositeIDSeparator)
                || displayName.isEmpty
                || !product.nominalPowerDeltaT50W.isFinite
                || product.nominalPowerDeltaT50W <= 0
                || !product.exponent.isFinite
                || product.exponent <= 0
                || !dimensionsValid {
                issues.append(.invalidProduct(product.id.isEmpty ? "<ohne ID>" : product.id))
            }
        }

        return issues
    }

    var isValid: Bool {
        validationIssues.isEmpty
    }

    func convertedDataset() -> HeizBalanceRadiatorProductDataset? {
        guard isValid else { return nil }

        let mappingNote = "Mapped via \(schema), profile \(mappingProfileVersion), source standard \(standardReference)."
        let existingRightsNote = source.rightsNote?.trimmingCharacters(in: .whitespacesAndNewlines)
        let rightsNote = [existingRightsNote, mappingNote]
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " ")

        return HeizBalanceRadiatorProductDataset(
            schema: HeizBalanceRadiatorProductDataset.schemaVersion,
            id: id,
            manufacturer: manufacturer,
            datasetName: datasetName,
            datasetVersion: datasetVersion,
            source: .init(
                reference: source.reference,
                url: source.url,
                usageBasis: source.usageBasis,
                rightsNote: rightsNote.isEmpty ? nil : rightsNote,
                distributionScope: source.distributionScope,
                authorizationReference: source.authorizationReference
            ),
            products: products.map { product in
                HeizBalanceRadiatorProductDataset.Product(
                    id: product.id,
                    series: product.series,
                    model: product.model,
                    kind: product.kind,
                    nominalPowerDeltaT50W: product.nominalPowerDeltaT50W,
                    exponent: product.exponent,
                    widthMM: product.widthMM,
                    heightMM: product.heightMM,
                    depthMM: product.depthMM,
                    articleNumber: product.articleNumber,
                    sourceReference: product.sourceReference ?? product.originalRecordReference
                )
            }
        )
    }
}

enum HeizBalanceRadiatorDatasetImportDecoder {
    struct Receipt: Equatable {
        var dataset: HeizBalanceRadiatorProductDataset
        var origin: Origin
    }

    enum Origin: Equatable {
        case native
        case vdi3805Mapped(standardReference: String, mappingProfileVersion: String)

        var title: String {
            switch self {
            case .native:
                "HeizBalance JSON"
            case .vdi3805Mapped:
                "VDI 3805 Blatt 6 Mapping"
            }
        }
    }

    enum ImportError: LocalizedError, Equatable {
        case unreadableEnvelope
        case unsupportedSchema(String)
        case nativeValidationFailed([String])
        case vdi3805ValidationFailed([String])
        case conversionFailed

        var errorDescription: String? {
            switch self {
            case .unreadableEnvelope:
                "Datensatzschema konnte nicht gelesen werden."
            case .unsupportedSchema(let schema):
                "Datensatzschema wird nicht unterstützt: \(schema)"
            case .nativeValidationFailed(let issues):
                "HeizBalance-Datensatz ist ungültig: \(issues.joined(separator: "; "))"
            case .vdi3805ValidationFailed(let issues):
                "VDI-3805-Mapping ist ungültig: \(issues.joined(separator: "; "))"
            case .conversionFailed:
                "VDI-3805-Mapping konnte nicht in das HeizBalance-Datenmodell umgewandelt werden."
            }
        }
    }

    private struct Envelope: Decodable {
        var schema: String
    }

    static func decode(data: Data) throws -> Receipt {
        let decoder = JSONDecoder()
        guard let envelope = try? decoder.decode(Envelope.self, from: data) else {
            throw ImportError.unreadableEnvelope
        }

        switch envelope.schema {
        case HeizBalanceRadiatorProductDataset.schemaVersion:
            let dataset = try decoder.decode(HeizBalanceRadiatorProductDataset.self, from: data)
            let issues = dataset.validationIssues.map(\.description)
            guard issues.isEmpty else {
                throw ImportError.nativeValidationFailed(issues)
            }
            return .init(dataset: dataset, origin: .native)

        case HeizBalanceVDI3805RadiatorMappedDataset.schemaVersion:
            let mapped = try decoder.decode(HeizBalanceVDI3805RadiatorMappedDataset.self, from: data)
            let issues = mapped.validationIssues.map(\.description)
            guard issues.isEmpty else {
                throw ImportError.vdi3805ValidationFailed(issues)
            }
            guard let dataset = mapped.convertedDataset(), dataset.isValid else {
                throw ImportError.conversionFailed
            }
            return .init(
                dataset: dataset,
                origin: .vdi3805Mapped(
                    standardReference: mapped.standardReference,
                    mappingProfileVersion: mapped.mappingProfileVersion
                )
            )

        default:
            throw ImportError.unsupportedSchema(envelope.schema)
        }
    }
}
