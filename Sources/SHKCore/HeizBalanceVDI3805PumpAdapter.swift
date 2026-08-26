import Foundation

struct HeizBalanceVDI3805PumpMappedDataset: Codable, Hashable, Identifiable {
    static let schemaVersion = "vdi-3805-part4-mapped-v1"
    static let supportedStandardPart = "VDI 3805 Blatt 4"

    var schema: String
    var id: String
    var manufacturer: String
    var datasetName: String
    var datasetVersion: String
    var standardReference: String
    var mappingProfileVersion: String
    var source: HeizBalancePumpProductDataset.Source
    var products: [MappedProduct]

    struct MappedProduct: Codable, Hashable, Identifiable {
        var id: String
        var productName: String
        var series: String?
        var articleNumber: String?
        var sourceReference: String?
        var originalRecordReference: String?
        var curves: [MappedCurve]
    }

    struct MappedCurve: Codable, Hashable, Identifiable {
        var id: String
        var label: String
        var controlMode: String?
        var speedRPM: Double?
        var sourceReference: String?
        var originalRecordReference: String?
        var points: [MappedCurvePoint]
    }

    struct MappedCurvePoint: Codable, Hashable, Identifiable {
        var id: String
        var volumeFlowM3H: Double
        var headM: Double
        var electricalInputPowerW: Double?
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
        case invalidMappedProduct(String)

        var description: String {
            switch self {
            case .wrongSchema: "Unbekanntes VDI-3805-Pumpen-Mappingschema"
            case .missingDatasetID: "Datensatz-ID fehlt"
            case .missingManufacturer: "Hersteller fehlt"
            case .missingDatasetName: "Datensatzname fehlt"
            case .missingDatasetVersion: "Datenstand/Version fehlt"
            case .missingStandardReference: "VDI-3805-Standardbezug fehlt"
            case .unsupportedStandardPart: "Standardbezug ist nicht VDI 3805 Blatt 4"
            case .missingMappingProfileVersion: "Mappingprofil-Version fehlt"
            case .missingSourceReference: "Quellenreferenz fehlt"
            case .noProducts: "Datensatz enthält keine Pumpenprodukte"
            case .invalidMappedProduct(let id): "Ungültige Pumpen-Mappingdaten: \(id)"
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

        let standard = standardReference.trimmingCharacters(in: .whitespacesAndNewlines)
        if standard.isEmpty {
            issues.append(.missingStandardReference)
        } else if !standard.localizedCaseInsensitiveContains(Self.supportedStandardPart) {
            issues.append(.unsupportedStandardPart)
        }

        if mappingProfileVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.missingMappingProfileVersion)
        }
        if source.reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.missingSourceReference)
        }
        if products.isEmpty { issues.append(.noProducts) }

        for product in products {
            let productID = product.id.trimmingCharacters(in: .whitespacesAndNewlines)
            let curvesValid = !product.curves.isEmpty && product.curves.allSatisfy { curve in
                let speedValid = curve.speedRPM.map { $0.isFinite && $0 > 0 } ?? true
                return !curve.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !curve.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && curve.points.count >= 2
                    && speedValid
                    && curve.points.allSatisfy { point in
                        !point.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && point.volumeFlowM3H.isFinite
                            && point.volumeFlowM3H >= 0
                            && point.headM.isFinite
                            && point.headM >= 0
                            && (point.electricalInputPowerW.map { $0.isFinite && $0 > 0 } ?? true)
                    }
            }

            if productID.isEmpty
                || productID.contains(HeizBalancePumpProductDataset.compositeIDSeparator)
                || product.productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !curvesValid {
                issues.append(.invalidMappedProduct(product.id.isEmpty ? "<ohne ID>" : product.id))
            }
        }

        return issues
    }

    var isValid: Bool { validationIssues.isEmpty }

    func convertedDataset() -> HeizBalancePumpProductDataset? {
        guard isValid else { return nil }

        let mappingNote = "Mapped via \(schema), profile \(mappingProfileVersion), source standard \(standardReference)."
        let existingRightsNote = source.rightsNote?.trimmingCharacters(in: .whitespacesAndNewlines)
        let rightsNote = [existingRightsNote, mappingNote]
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " ")

        let dataset = HeizBalancePumpProductDataset(
            schema: HeizBalancePumpProductDataset.schemaVersion,
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
                .init(
                    id: product.id,
                    productName: product.productName,
                    series: product.series,
                    articleNumber: product.articleNumber,
                    sourceReference: product.sourceReference ?? product.originalRecordReference,
                    curves: product.curves.map { curve in
                        .init(
                            id: curve.id,
                            label: curve.label,
                            controlMode: curve.controlMode,
                            speedRPM: curve.speedRPM,
                            sourceReference: curve.sourceReference ?? curve.originalRecordReference,
                            points: curve.points.map { point in
                                .init(
                                    id: point.id,
                                    volumeFlowM3H: point.volumeFlowM3H,
                                    headM: point.headM,
                                    electricalInputPowerW: point.electricalInputPowerW
                                )
                            }
                        )
                    }
                )
            }
        )

        return dataset.isValid ? dataset : nil
    }
}

enum HeizBalancePumpDatasetImportDecoder {
    struct Receipt: Equatable {
        var dataset: HeizBalancePumpProductDataset
        var origin: Origin
    }

    enum Origin: Equatable {
        case native
        case vdi3805Mapped(standardReference: String, mappingProfileVersion: String)

        var title: String {
            switch self {
            case .native: "HeizBalance JSON"
            case .vdi3805Mapped: "VDI 3805 Blatt 4 Mapping"
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
            case .unreadableEnvelope: "Datensatzschema konnte nicht gelesen werden."
            case .unsupportedSchema(let schema): "Pumpen-Datensatzschema wird nicht unterstützt: \(schema)"
            case .nativeValidationFailed(let issues): "Pumpen-Datensatz ist ungültig: \(issues.joined(separator: "; "))"
            case .vdi3805ValidationFailed(let issues): "VDI-3805-Pumpen-Mapping ist ungültig: \(issues.joined(separator: "; "))"
            case .conversionFailed: "VDI-3805-Pumpen-Mapping konnte nicht in das HeizBalance-Datenmodell umgewandelt werden."
            }
        }
    }

    private struct Envelope: Decodable { var schema: String }

    static func decode(data: Data) throws -> Receipt {
        let decoder = JSONDecoder()
        guard let envelope = try? decoder.decode(Envelope.self, from: data) else {
            throw ImportError.unreadableEnvelope
        }

        switch envelope.schema {
        case HeizBalancePumpProductDataset.schemaVersion:
            let dataset = try decoder.decode(HeizBalancePumpProductDataset.self, from: data)
            let issues = dataset.validationIssues.map(\.description)
            guard issues.isEmpty else { throw ImportError.nativeValidationFailed(issues) }
            return .init(dataset: dataset, origin: .native)

        case HeizBalanceVDI3805PumpMappedDataset.schemaVersion:
            let mapped = try decoder.decode(HeizBalanceVDI3805PumpMappedDataset.self, from: data)
            let issues = mapped.validationIssues.map(\.description)
            guard issues.isEmpty else { throw ImportError.vdi3805ValidationFailed(issues) }
            guard let dataset = mapped.convertedDataset() else { throw ImportError.conversionFailed }
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
