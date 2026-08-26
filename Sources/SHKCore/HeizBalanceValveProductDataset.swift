import Foundation

struct HeizBalanceValveProductDataset: Codable, Hashable, Identifiable {
    static let schemaVersion = "valve-product-dataset-v1"
    static let compositeIDSeparator = "::"

    var schema: String
    var id: String
    var manufacturer: String
    var datasetName: String
    var datasetVersion: String
    var source: Source
    var products: [Product]

    struct Source: Codable, Hashable {
        var reference: String
        var url: String?
        var usageBasis: UsageBasis
        var rightsNote: String?
        var distributionScope: HeizBalanceProductDataDistributionScope? = nil
        var authorizationReference: String? = nil
    }

    enum UsageBasis: String, Codable, CaseIterable, Identifiable {
        case manufacturerAuthorized
        case licensed
        case userProvided
        case otherDocumented

        var id: String { rawValue }

        var title: String {
            switch self {
            case .manufacturerAuthorized: "Vom Hersteller freigegeben"
            case .licensed: "Lizenziert"
            case .userProvided: "Vom Benutzer bereitgestellt"
            case .otherDocumented: "Andere dokumentierte Grundlage"
            }
        }
    }

    struct Product: Codable, Hashable, Identifiable {
        var id: String
        var productName: String
        var kind: String?
        var articleNumber: String?
        var sourceReference: String?
        var presetPoints: [PresetPoint]
    }

    struct PresetPoint: Codable, Hashable, Identifiable {
        var id: String
        var setting: String
        var kvM3H: Double
    }

    enum ValidationIssue: Hashable, CustomStringConvertible {
        case wrongSchema
        case missingDatasetID
        case reservedSeparatorInDatasetID
        case missingManufacturer
        case missingDatasetName
        case missingDatasetVersion
        case missingSourceReference
        case noProducts
        case duplicateProductID(String)
        case invalidProduct(String)
        case duplicatePresetSetting(productID: String, setting: String)
        case invalidPresetPoint(productID: String, setting: String)

        var description: String {
            switch self {
            case .wrongSchema: "Unbekanntes Ventil-Datensatzschema"
            case .missingDatasetID: "Datensatz-ID fehlt"
            case .reservedSeparatorInDatasetID: "Datensatz-ID enthält den reservierten Trenner ::"
            case .missingManufacturer: "Hersteller fehlt"
            case .missingDatasetName: "Datensatzname fehlt"
            case .missingDatasetVersion: "Datenstand/Version fehlt"
            case .missingSourceReference: "Quellenreferenz fehlt"
            case .noProducts: "Datensatz enthält keine Ventilprodukte"
            case .duplicateProductID(let id): "Doppelte Produkt-ID: \(id)"
            case .invalidProduct(let id): "Ungültige Ventilproduktdaten: \(id)"
            case .duplicatePresetSetting(let productID, let setting):
                "Doppelte Voreinstellung bei \(productID): \(setting)"
            case .invalidPresetPoint(let productID, let setting):
                "Ungültiger kv-Punkt bei \(productID): \(setting)"
            }
        }
    }

    var validationIssues: [ValidationIssue] {
        var issues: [ValidationIssue] = []
        let datasetID = id.trimmingCharacters(in: .whitespacesAndNewlines)

        if schema != Self.schemaVersion { issues.append(.wrongSchema) }
        if datasetID.isEmpty { issues.append(.missingDatasetID) }
        if datasetID.contains(Self.compositeIDSeparator) { issues.append(.reservedSeparatorInDatasetID) }
        if manufacturer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingManufacturer) }
        if datasetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingDatasetName) }
        if datasetVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingDatasetVersion) }
        if source.reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingSourceReference) }
        if products.isEmpty { issues.append(.noProducts) }

        var productIDs = Set<String>()
        for product in products {
            let productID = product.id.trimmingCharacters(in: .whitespacesAndNewlines)
            if !productIDs.insert(productID).inserted {
                issues.append(.duplicateProductID(product.id))
            }
            if productID.isEmpty
                || productID.contains(Self.compositeIDSeparator)
                || product.productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || product.presetPoints.isEmpty {
                issues.append(.invalidProduct(product.id.isEmpty ? "<ohne ID>" : product.id))
            }

            var settings = Set<String>()
            for point in product.presetPoints {
                let setting = point.setting.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalized = setting.lowercased()
                if !settings.insert(normalized).inserted {
                    issues.append(.duplicatePresetSetting(productID: product.id, setting: point.setting))
                }
                if point.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || setting.isEmpty
                    || !point.kvM3H.isFinite
                    || point.kvM3H <= 0 {
                    issues.append(.invalidPresetPoint(productID: product.id, setting: point.setting))
                }
            }
        }

        return issues
    }

    var isValid: Bool { validationIssues.isEmpty }

    var distributionRightsAssessment: HeizBalanceProductDataRightsGate.Assessment {
        HeizBalanceProductDataRightsGate.assess(
            .init(
                usageBasis: source.usageBasis.rawValue,
                sourceReference: source.reference,
                rightsNote: source.rightsNote,
                distributionScope: source.distributionScope,
                authorizationReference: source.authorizationReference
            )
        )
    }

    func compositeProductID(for productID: String) -> String {
        id + Self.compositeIDSeparator + productID
    }
}

extension HeizBalanceValveProductDataset.Product {
    func projectProductData(dataset: HeizBalanceValveProductDataset) -> HeizBalanceValveProductData {
        .init(
            manufacturer: dataset.manufacturer,
            productName: productName,
            dataSetVersion: dataset.datasetVersion,
            sourceReference: sourceReference ?? dataset.source.reference,
            presetPoints: presetPoints.map {
                HeizBalanceValvePresetPoint(setting: $0.setting, kvM3H: $0.kvM3H)
            },
            datasetID: dataset.id,
            productID: id,
            articleNumber: articleNumber,
            sourceURL: dataset.source.url,
            usageBasis: dataset.source.usageBasis.rawValue,
            rightsNote: dataset.source.rightsNote
        )
    }
}
