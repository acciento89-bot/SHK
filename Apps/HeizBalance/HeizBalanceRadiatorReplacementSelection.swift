import Foundation

struct HeizBalanceRadiatorReplacementSelection: Identifiable, Codable, Hashable {
    static let schemaVersion = "radiator-replacement-selection-v1"

    var id: UUID
    var schema: String
    var selectedAt: Date
    var targetFlowTemperatureC: Double
    var targetReturnTemperatureC: Double
    var roomTemperatureC: Double
    var requiredPowerW: Double
    var availablePowerW: Double
    var capacityRatio: Double

    var datasetID: String
    var manufacturer: String
    var datasetName: String
    var datasetVersion: String
    var sourceReference: String
    var sourceURL: String?
    var usageBasis: HeizBalanceRadiatorProductDataset.UsageBasis
    var rightsNote: String?

    var productID: String
    var series: String
    var model: String
    var articleNumber: String?
    var nominalPowerDeltaT50W: Double
    var exponent: Double
    var widthMM: Double?
    var heightMM: Double?
    var depthMM: Double?
    var productSourceReference: String?

    init(
        id: UUID = UUID(),
        selectedAt: Date = Date(),
        targetFlowTemperatureC: Double,
        targetReturnTemperatureC: Double,
        roomTemperatureC: Double,
        requiredPowerW: Double,
        availablePowerW: Double,
        capacityRatio: Double,
        dataset: HeizBalanceRadiatorProductDataset,
        product: HeizBalanceRadiatorProductDataset.Product
    ) {
        self.id = id
        self.schema = Self.schemaVersion
        self.selectedAt = selectedAt
        self.targetFlowTemperatureC = targetFlowTemperatureC
        self.targetReturnTemperatureC = targetReturnTemperatureC
        self.roomTemperatureC = roomTemperatureC
        self.requiredPowerW = requiredPowerW
        self.availablePowerW = availablePowerW
        self.capacityRatio = capacityRatio
        self.datasetID = dataset.id
        self.manufacturer = dataset.manufacturer
        self.datasetName = dataset.datasetName
        self.datasetVersion = dataset.datasetVersion
        self.sourceReference = dataset.source.reference
        self.sourceURL = dataset.source.url
        self.usageBasis = dataset.source.usageBasis
        self.rightsNote = dataset.source.rightsNote
        self.productID = product.id
        self.series = product.series
        self.model = product.model
        self.articleNumber = product.articleNumber
        self.nominalPowerDeltaT50W = product.nominalPowerDeltaT50W
        self.exponent = product.exponent
        self.widthMM = product.widthMM
        self.heightMM = product.heightMM
        self.depthMM = product.depthMM
        self.productSourceReference = product.sourceReference
    }

    var displayName: String {
        let productName = [series, model]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        return manufacturer + (productName.isEmpty ? "" : " · " + productName)
    }
}

extension HeizBalanceProject {
    func radiatorReplacementSelection(surfaceID: UUID) -> HeizBalanceRadiatorReplacementSelection? {
        for floor in floors {
            for room in floor.rooms {
                if let surface = room.heatingSurfaces?.first(where: { $0.id == surfaceID }) {
                    return surface.replacementSelection
                }
            }
        }
        return nil
    }

    @discardableResult
    mutating func setRadiatorReplacementSelection(
        _ selection: HeizBalanceRadiatorReplacementSelection?,
        surfaceID: UUID
    ) -> Bool {
        for floorIndex in floors.indices {
            for roomIndex in floors[floorIndex].rooms.indices {
                guard let surfaces = floors[floorIndex].rooms[roomIndex].heatingSurfaces,
                      let surfaceIndex = surfaces.firstIndex(where: { $0.id == surfaceID }) else {
                    continue
                }

                floors[floorIndex].rooms[roomIndex].heatingSurfaces?[surfaceIndex].replacementSelection = selection
                return true
            }
        }
        return false
    }
}
