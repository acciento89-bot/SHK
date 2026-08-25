import Foundation

enum HeizBalanceCalculationEngineID: String, Codable, Sendable, CaseIterable {
    case technicalPreviewV1 = "technical-preview-v1"
    case deRoomHeatLoad2017_2020 = "de-room-heat-load-2017-2020"
}

enum HeizBalanceCalculationValidationState: String, Codable, Sendable {
    case developmentOnly
    case specificationVerified
    case referenceValidated
    case released
}

struct HeizBalanceCalculationSourceEdition: Codable, Equatable, Sendable {
    var document: String
    var edition: String
}

struct HeizBalanceCalculationProfile: Codable, Equatable, Sendable {
    var engineID: HeizBalanceCalculationEngineID
    var displayName: String
    var validationState: HeizBalanceCalculationValidationState
    var sourceEditions: [HeizBalanceCalculationSourceEdition]
    var normativeOutputAllowed: Bool

    static let technicalPreviewV1 = HeizBalanceCalculationProfile(
        engineID: .technicalPreviewV1,
        displayName: "Technische Vorberechnung v1",
        validationState: .developmentOnly,
        sourceEditions: [],
        normativeOutputAllowed: false
    )

    /// Reserved profile for the German room heat-load implementation referenced by GEG §60c.
    /// Formula implementation is intentionally absent until the specification and reference
    /// cases have passed the project validation gates.
    static let germanRoomHeatLoad2017_2020 = HeizBalanceCalculationProfile(
        engineID: .deRoomHeatLoad2017_2020,
        displayName: "Raumheizlast DE 2017/2020",
        validationState: .developmentOnly,
        sourceEditions: [
            .init(document: "DIN EN 12831-1", edition: "2017-09"),
            .init(document: "DIN/TS 12831-1", edition: "2020-04")
        ],
        normativeOutputAllowed: false
    )
}
