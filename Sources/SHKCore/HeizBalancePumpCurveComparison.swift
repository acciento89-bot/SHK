import Foundation

struct HeizBalancePumpCurveComparisonCalculator {
    enum Status: String, Codable, Hashable {
        case technicallySufficient
        case insufficientHead
        case outsideDocumentedRange
    }

    struct Entry: Identifiable, Codable, Hashable {
        var id: String
        var datasetID: String
        var manufacturer: String
        var datasetName: String
        var datasetVersion: String
        var productID: String
        var productDisplayName: String
        var curveID: String
        var curveLabel: String
        var controlMode: String?
        var status: Status
        var availableHeadM: Double?
        var requiredHeadM: Double
        var headReserveM: Double?
        var electricalInputPowerW: Double?
        var lowerPointID: String?
        var upperPointID: String?
        var exactDocumentedPoint: Bool?
        var documentedMinimumFlowM3H: Double?
        var documentedMaximumFlowM3H: Double?
    }

    struct Summary: Codable, Hashable {
        var targetVolumeFlowM3H: Double
        var requiredHeadM: Double
        var entries: [Entry]

        var totalCurveCount: Int { entries.count }
        var technicallySufficientCount: Int {
            entries.filter { $0.status == .technicallySufficient }.count
        }
        var insufficientHeadCount: Int {
            entries.filter { $0.status == .insufficientHead }.count
        }
        var outsideDocumentedRangeCount: Int {
            entries.filter { $0.status == .outsideDocumentedRange }.count
        }
        var evaluableCount: Int {
            technicallySufficientCount + insufficientHeadCount
        }
    }

    static func calculate(
        datasets: [HeizBalancePumpProductDataset],
        targetVolumeFlowM3H: Double,
        requiredHeadM: Double
    ) -> Summary? {
        guard targetVolumeFlowM3H.isFinite,
              targetVolumeFlowM3H >= 0,
              requiredHeadM.isFinite,
              requiredHeadM >= 0 else {
            return nil
        }

        var entries: [Entry] = []

        for dataset in datasets {
            for product in dataset.products {
                for curve in product.curves {
                    let evaluation = HeizBalancePumpCurveOperatingPointCalculator.calculate(
                        .init(
                            targetVolumeFlowM3H: targetVolumeFlowM3H,
                            requiredHeadM: requiredHeadM,
                            points: curve.points
                        )
                    )
                    let flows = curve.points.map(\.volumeFlowM3H)
                    let minimumFlow = flows.min()
                    let maximumFlow = flows.max()

                    let status: Status
                    if let evaluation {
                        status = evaluation.technicallySufficient
                            ? .technicallySufficient
                            : .insufficientHead
                    } else {
                        status = .outsideDocumentedRange
                    }

                    entries.append(
                        .init(
                            id: dataset.id + "|" + product.id + "|" + curve.id,
                            datasetID: dataset.id,
                            manufacturer: dataset.manufacturer,
                            datasetName: dataset.datasetName,
                            datasetVersion: dataset.datasetVersion,
                            productID: product.id,
                            productDisplayName: product.displayName,
                            curveID: curve.id,
                            curveLabel: curve.label,
                            controlMode: curve.controlMode,
                            status: status,
                            availableHeadM: evaluation?.availableHeadM,
                            requiredHeadM: requiredHeadM,
                            headReserveM: evaluation?.headReserveM,
                            electricalInputPowerW: evaluation?.interpolatedElectricalInputPowerW,
                            lowerPointID: evaluation?.lowerPointID,
                            upperPointID: evaluation?.upperPointID,
                            exactDocumentedPoint: evaluation?.exactDocumentedPoint,
                            documentedMinimumFlowM3H: minimumFlow,
                            documentedMaximumFlowM3H: maximumFlow
                        )
                    )
                }
            }
        }

        entries.sort { lhs, rhs in
            let leftStatus = sortRank(lhs.status)
            let rightStatus = sortRank(rhs.status)
            if leftStatus != rightStatus { return leftStatus < rightStatus }

            let leftManufacturer = lhs.manufacturer.lowercased()
            let rightManufacturer = rhs.manufacturer.lowercased()
            if leftManufacturer != rightManufacturer { return leftManufacturer < rightManufacturer }

            let leftProduct = lhs.productDisplayName.lowercased()
            let rightProduct = rhs.productDisplayName.lowercased()
            if leftProduct != rightProduct { return leftProduct < rightProduct }

            return lhs.curveLabel.lowercased() < rhs.curveLabel.lowercased()
        }

        return .init(
            targetVolumeFlowM3H: targetVolumeFlowM3H,
            requiredHeadM: requiredHeadM,
            entries: entries
        )
    }

    private static func sortRank(_ status: Status) -> Int {
        switch status {
        case .technicallySufficient: 0
        case .insufficientHead: 1
        case .outsideDocumentedRange: 2
        }
    }
}
