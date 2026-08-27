import Foundation

struct HeizBalancePumpProductDataset: Codable, Hashable, Identifiable {
    static let schemaVersion = "pump-product-dataset-v1"
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
        var series: String?
        var articleNumber: String?
        var sourceReference: String?
        var curves: [Curve]

        var displayName: String {
            [series, productName]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
        }
    }

    struct Curve: Codable, Hashable, Identifiable {
        var id: String
        var label: String
        var controlMode: String?
        var speedRPM: Double?
        var sourceReference: String?
        var points: [CurvePoint]
    }

    struct CurvePoint: Codable, Hashable, Identifiable {
        var id: String
        var volumeFlowM3H: Double
        var headM: Double
        var electricalInputPowerW: Double?
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
        case duplicateCurveID(productID: String, curveID: String)
        case invalidCurve(productID: String, curveID: String)
        case duplicateFlowPoint(productID: String, curveID: String, flowM3H: Double)
        case invalidCurvePoint(productID: String, curveID: String, pointID: String)

        var description: String {
            switch self {
            case .wrongSchema: "Unbekanntes Pumpen-Datensatzschema"
            case .missingDatasetID: "Datensatz-ID fehlt"
            case .reservedSeparatorInDatasetID: "Datensatz-ID enthält den reservierten Trenner ::"
            case .missingManufacturer: "Hersteller fehlt"
            case .missingDatasetName: "Datensatzname fehlt"
            case .missingDatasetVersion: "Datenstand/Version fehlt"
            case .missingSourceReference: "Quellenreferenz fehlt"
            case .noProducts: "Datensatz enthält keine Pumpenprodukte"
            case .duplicateProductID(let id): "Doppelte Produkt-ID: \(id)"
            case .invalidProduct(let id): "Ungültige Pumpenproduktdaten: \(id)"
            case .duplicateCurveID(let productID, let curveID): "Doppelte Kennlinien-ID bei \(productID): \(curveID)"
            case .invalidCurve(let productID, let curveID): "Ungültige Kennlinie bei \(productID): \(curveID)"
            case .duplicateFlowPoint(let productID, let curveID, let flow):
                "Doppelter Volumenstrompunkt bei \(productID)/\(curveID): \(flow) m³/h"
            case .invalidCurvePoint(let productID, let curveID, let pointID):
                "Ungültiger Kennlinienpunkt bei \(productID)/\(curveID): \(pointID)"
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
            if !productIDs.insert(productID).inserted { issues.append(.duplicateProductID(product.id)) }
            if productID.isEmpty
                || productID.contains(Self.compositeIDSeparator)
                || product.productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || product.curves.isEmpty {
                issues.append(.invalidProduct(product.id.isEmpty ? "<ohne ID>" : product.id))
            }

            var curveIDs = Set<String>()
            for curve in product.curves {
                let curveID = curve.id.trimmingCharacters(in: .whitespacesAndNewlines)
                if !curveIDs.insert(curveID).inserted {
                    issues.append(.duplicateCurveID(productID: product.id, curveID: curve.id))
                }

                let speedValid = curve.speedRPM.map { $0.isFinite && $0 > 0 } ?? true
                if curveID.isEmpty
                    || curve.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || curve.points.count < 2
                    || !speedValid {
                    issues.append(.invalidCurve(productID: product.id, curveID: curve.id))
                }

                var flows = Set<Double>()
                var pointIDs = Set<String>()
                for point in curve.points {
                    if !flows.insert(point.volumeFlowM3H).inserted {
                        issues.append(
                            .duplicateFlowPoint(
                                productID: product.id,
                                curveID: curve.id,
                                flowM3H: point.volumeFlowM3H
                            )
                        )
                    }

                    let pointID = point.id.trimmingCharacters(in: .whitespacesAndNewlines)
                    let uniquePointID = pointIDs.insert(pointID).inserted
                    let powerValid = point.electricalInputPowerW.map { $0.isFinite && $0 > 0 } ?? true
                    if pointID.isEmpty
                        || !uniquePointID
                        || !point.volumeFlowM3H.isFinite
                        || point.volumeFlowM3H < 0
                        || !point.headM.isFinite
                        || point.headM < 0
                        || !powerValid {
                        issues.append(
                            .invalidCurvePoint(
                                productID: product.id,
                                curveID: curve.id,
                                pointID: point.id.isEmpty ? "<ohne ID>" : point.id
                            )
                        )
                    }
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
