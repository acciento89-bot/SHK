import Foundation

struct HeizBalanceValveProductData: Codable, Hashable {
    var manufacturer: String
    var productName: String
    var dataSetVersion: String
    var sourceReference: String
    var presetPoints: [HeizBalanceValvePresetPoint]
    var datasetID: String?
    var productID: String?
    var articleNumber: String?
    var sourceURL: String?
    var usageBasis: String?
    var rightsNote: String?

    init(
        manufacturer: String = "",
        productName: String = "",
        dataSetVersion: String = "",
        sourceReference: String = "",
        presetPoints: [HeizBalanceValvePresetPoint] = [],
        datasetID: String? = nil,
        productID: String? = nil,
        articleNumber: String? = nil,
        sourceURL: String? = nil,
        usageBasis: String? = nil,
        rightsNote: String? = nil
    ) {
        self.manufacturer = manufacturer
        self.productName = productName
        self.dataSetVersion = dataSetVersion
        self.sourceReference = sourceReference
        self.presetPoints = presetPoints
        self.datasetID = datasetID
        self.productID = productID
        self.articleNumber = articleNumber
        self.sourceURL = sourceURL
        self.usageBasis = usageBasis
        self.rightsNote = rightsNote
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
