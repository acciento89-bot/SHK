import Foundation

struct HeizBalancePumpSelection: Identifiable, Codable, Hashable {
    static let schemaVersion = "pump-curve-selection-v1"

    struct Point: Identifiable, Codable, Hashable {
        var id: String
        var volumeFlowM3H: Double
        var headM: Double
        var electricalInputPowerW: Double?
    }

    var id: UUID
    var schema: String
    var projectID: UUID
    var selectedAt: Date
    var calculationProfile: String

    var operatingPointVolumeFlowM3H: Double
    var requiredHeadM: Double
    var availableHeadM: Double
    var headReserveM: Double
    var technicallySufficient: Bool
    var electricalInputPowerW: Double?
    var lowerPointID: String
    var upperPointID: String
    var exactDocumentedPoint: Bool

    var datasetID: String
    var manufacturer: String
    var datasetName: String
    var datasetVersion: String
    var sourceReference: String
    var sourceURL: String?
    var usageBasis: HeizBalancePumpProductDataset.UsageBasis
    var rightsNote: String?

    var productID: String
    var productName: String
    var series: String?
    var articleNumber: String?
    var productSourceReference: String?

    var curveID: String
    var curveLabel: String
    var controlMode: String?
    var speedRPM: Double?
    var curveSourceReference: String?
    var documentedPoints: [Point]

    init(
        id: UUID = UUID(),
        projectID: UUID,
        selectedAt: Date = Date(),
        dataset: HeizBalancePumpProductDataset,
        product: HeizBalancePumpProductDataset.Product,
        curve: HeizBalancePumpProductDataset.Curve,
        evaluation: HeizBalancePumpCurveOperatingPointCalculator.Result
    ) {
        self.id = id
        self.schema = Self.schemaVersion
        self.projectID = projectID
        self.selectedAt = selectedAt
        self.calculationProfile = HeizBalancePumpCurveOperatingPointCalculator.profileVersion

        self.operatingPointVolumeFlowM3H = evaluation.targetVolumeFlowM3H
        self.requiredHeadM = evaluation.requiredHeadM
        self.availableHeadM = evaluation.availableHeadM
        self.headReserveM = evaluation.headReserveM
        self.technicallySufficient = evaluation.technicallySufficient
        self.electricalInputPowerW = evaluation.interpolatedElectricalInputPowerW
        self.lowerPointID = evaluation.lowerPointID
        self.upperPointID = evaluation.upperPointID
        self.exactDocumentedPoint = evaluation.exactDocumentedPoint

        self.datasetID = dataset.id
        self.manufacturer = dataset.manufacturer
        self.datasetName = dataset.datasetName
        self.datasetVersion = dataset.datasetVersion
        self.sourceReference = dataset.source.reference
        self.sourceURL = dataset.source.url
        self.usageBasis = dataset.source.usageBasis
        self.rightsNote = dataset.source.rightsNote

        self.productID = product.id
        self.productName = product.productName
        self.series = product.series
        self.articleNumber = product.articleNumber
        self.productSourceReference = product.sourceReference

        self.curveID = curve.id
        self.curveLabel = curve.label
        self.controlMode = curve.controlMode
        self.speedRPM = curve.speedRPM
        self.curveSourceReference = curve.sourceReference
        self.documentedPoints = curve.points.map {
            .init(
                id: $0.id,
                volumeFlowM3H: $0.volumeFlowM3H,
                headM: $0.headM,
                electricalInputPowerW: $0.electricalInputPowerW
            )
        }
    }

    var displayName: String {
        let product = [series, productName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        return manufacturer + (product.isEmpty ? "" : " · " + product)
    }

    func matchesOperatingPoint(volumeFlowM3H: Double, requiredHeadM: Double) -> Bool {
        approximatelyEqual(operatingPointVolumeFlowM3H, volumeFlowM3H)
            && approximatelyEqual(self.requiredHeadM, requiredHeadM)
    }

    private func approximatelyEqual(_ lhs: Double, _ rhs: Double) -> Bool {
        let scale = max(1, max(abs(lhs), abs(rhs)))
        return abs(lhs - rhs) <= scale * 1e-9
    }
}
