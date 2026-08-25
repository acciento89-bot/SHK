import Foundation

struct HeizBalanceValveProductData: Codable, Hashable {
    var manufacturer: String
    var productName: String
    var dataSetVersion: String
    var sourceReference: String
    var presetPoints: [HeizBalanceValvePresetPoint]

    init(
        manufacturer: String = "",
        productName: String = "",
        dataSetVersion: String = "",
        sourceReference: String = "",
        presetPoints: [HeizBalanceValvePresetPoint] = []
    ) {
        self.manufacturer = manufacturer
        self.productName = productName
        self.dataSetVersion = dataSetVersion
        self.sourceReference = sourceReference
        self.presetPoints = presetPoints
    }
}

struct HeizBalanceValvePresetPoint: Identifiable, Codable, Hashable {
    var id: UUID
    var setting: String
    var kvM3H: Double?

    init(
        id: UUID = UUID(),
        setting: String = "",
        kvM3H: Double? = nil
    ) {
        self.id = id
        self.setting = setting
        self.kvM3H = kvM3H
    }
}
