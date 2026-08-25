import Foundation

struct HeizBalanceRadiatorProductDataset: Codable, Hashable, Identifiable {
    static let schemaVersion = "radiator-product-dataset-v1"

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

        var displayName: String {
            [series, model]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
        }
    }

    enum ValidationIssue: Hashable, CustomStringConvertible {
        case wrongSchema
        case missingDatasetID
        case missingManufacturer
        case missingDatasetName
        case missingDatasetVersion
        case missingSourceReference
        case noProducts
        case duplicateProductID(String)
        case invalidProduct(String)

        var description: String {
            switch self {
            case .wrongSchema: "Unbekanntes Datensatzschema"
            case .missingDatasetID: "Datensatz-ID fehlt"
            case .missingManufacturer: "Hersteller fehlt"
            case .missingDatasetName: "Datensatzname fehlt"
            case .missingDatasetVersion: "Datenstand/Version fehlt"
            case .missingSourceReference: "Quellenreferenz fehlt"
            case .noProducts: "Datensatz enthält keine Produkte"
            case .duplicateProductID(let id): "Doppelte Produkt-ID: \(id)"
            case .invalidProduct(let id): "Ungültige Produktdaten: \(id)"
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
        if source.reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.missingSourceReference) }
        if products.isEmpty { issues.append(.noProducts) }

        var seen = Set<String>()
        for product in products {
            let productID = product.id.trimmingCharacters(in: .whitespacesAndNewlines)
            if !seen.insert(productID).inserted {
                issues.append(.duplicateProductID(product.id))
            }

            let dimensionsValid = [product.widthMM, product.heightMM, product.depthMM]
                .compactMap { $0 }
                .allSatisfy { $0.isFinite && $0 > 0 }

            if productID.isEmpty
                || product.displayName.isEmpty
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
}

extension HeizBalanceRadiatorProductDataset.Product {
    func matchingCandidate(datasetID: String) -> HeizBalanceRadiatorProductMatchingCalculator.Candidate {
        .init(
            id: datasetID + "::" + id,
            nominalPowerDeltaT50W: nominalPowerDeltaT50W,
            exponent: exponent,
            widthMM: widthMM,
            heightMM: heightMM,
            depthMM: depthMM
        )
    }
}
