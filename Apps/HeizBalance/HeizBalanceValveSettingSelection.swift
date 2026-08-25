import Foundation

struct HeizBalanceValveSettingSelection: Identifiable, Codable, Hashable {
    static let schemaVersion = "valve-setting-selection-v1"

    var schema: String
    var id: UUID
    var projectID: UUID
    var surfaceID: UUID
    var componentID: UUID
    var componentKind: String
    var componentName: String
    var selectedSetting: String
    var selectedKvM3H: Double
    var requiredKvM3H: Double
    var targetVolumeFlowLPH: Double
    var valvePressureLossKPa: Double
    var densityKGPerM3: Double
    var manufacturer: String
    var productName: String
    var dataSetVersion: String
    var datasetID: String?
    var productID: String?
    var articleNumber: String?
    var sourceReference: String
    var sourceURL: String?
    var usageBasis: String?
    var rightsNote: String?
    var createdAt: Date

    init(
        projectID: UUID,
        surfaceID: UUID,
        component: HeizBalanceHydraulicLossComponent,
        point: HeizBalanceValvePresetPoint,
        requiredKvM3H: Double,
        targetVolumeFlowLPH: Double,
        densityKGPerM3: Double,
        createdAt: Date = Date()
    )? {
        guard component.supportsValveProductData,
              let pressureLoss = component.pressureLossKPa,
              let kv = point.kvM3H,
              kv.isFinite,
              kv > 0,
              requiredKvM3H.isFinite,
              requiredKvM3H > 0,
              targetVolumeFlowLPH.isFinite,
              targetVolumeFlowLPH > 0,
              pressureLoss.isFinite,
              pressureLoss > 0,
              densityKGPerM3.isFinite,
              densityKGPerM3 > 0,
              let data = component.valveProductData else {
            return nil
        }

        self.schema = Self.schemaVersion
        self.id = UUID()
        self.projectID = projectID
        self.surfaceID = surfaceID
        self.componentID = component.id
        self.componentKind = component.kind.rawValue
        self.componentName = component.name
        self.selectedSetting = point.setting
        self.selectedKvM3H = kv
        self.requiredKvM3H = requiredKvM3H
        self.targetVolumeFlowLPH = targetVolumeFlowLPH
        self.valvePressureLossKPa = pressureLoss
        self.densityKGPerM3 = densityKGPerM3
        self.manufacturer = data.manufacturer
        self.productName = data.productName
        self.dataSetVersion = data.dataSetVersion
        self.datasetID = data.datasetID
        self.productID = data.productID
        self.articleNumber = data.articleNumber
        self.sourceReference = data.sourceReference
        self.sourceURL = data.sourceURL
        self.usageBasis = data.usageBasis
        self.rightsNote = data.rightsNote
        self.createdAt = createdAt
    }

    var displayName: String {
        [manufacturer, productName, selectedSetting]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " · ")
    }

    func matchesCurrent(
        component: HeizBalanceHydraulicLossComponent,
        requiredKvM3H currentRequiredKv: Double?,
        targetVolumeFlowLPH currentFlow: Double?,
        densityKGPerM3 currentDensity: Double?
    ) -> Bool {
        guard component.id == componentID,
              component.kind.rawValue == componentKind,
              let currentRequiredKv,
              let currentFlow,
              let currentDensity,
              let currentPressureLoss = component.pressureLossKPa,
              let data = component.valveProductData else {
            return false
        }

        guard nearlyEqual(currentRequiredKv, requiredKvM3H),
              nearlyEqual(currentFlow, targetVolumeFlowLPH),
              nearlyEqual(currentDensity, densityKGPerM3),
              nearlyEqual(currentPressureLoss, valvePressureLossKPa),
              data.manufacturer == manufacturer,
              data.productName == productName,
              data.dataSetVersion == dataSetVersion,
              data.datasetID == datasetID,
              data.productID == productID else {
            return false
        }

        return data.presetPoints.contains { point in
            point.setting == selectedSetting
                && point.kvM3H.map { nearlyEqual($0, selectedKvM3H) } == true
        }
    }

    private func nearlyEqual(_ lhs: Double, _ rhs: Double) -> Bool {
        let scale = max(1, abs(lhs), abs(rhs))
        return abs(lhs - rhs) <= scale * 1e-6
    }
}
