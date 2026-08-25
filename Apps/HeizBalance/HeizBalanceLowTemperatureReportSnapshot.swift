import Foundation

struct HeizBalanceLowTemperatureReportSnapshot: Codable, Hashable {
    static let schemaVersion = "technical-low-temperature-v1"
    static let calculationProfileVersion = "fixed-spread-emitter-check-v1"

    var schema: String
    var calculationProfile: String
    var generatedAt: Date
    var projectID: UUID
    var projectName: String
    var technicalPreparationOnly: Bool
    var waterTemperatureDifferenceK: Double?
    var comparisonFlowTemperatureC: Double?
    var comparisonReturnTemperatureC: Double?
    var surfaceCount: Int
    var evaluableSurfaceCount: Int
    var coverageComplete: Bool
    var minimumSystemFlowTemperatureC: Double?
    var minimumSystemReturnTemperatureC: Double?
    var limitingSurfaceName: String?
    var comparisonSufficient: Bool?
    var surfaces: [SurfaceData]

    struct SurfaceData: Codable, Hashable, Identifiable {
        var id: UUID
        var floorName: String
        var roomName: String
        var surfaceName: String
        var minimumFlowTemperatureC: Double?
        var minimumReturnTemperatureC: Double?
        var comparisonAvailablePowerW: Double?
        var comparisonCapacityRatio: Double?
        var comparisonSufficient: Bool?
        var missingInputs: [String]

        var displayName: String {
            "\(roomName) · \(surfaceName)"
        }
    }
}

extension HeizBalanceProject {
    func lowTemperatureReportSnapshot(
        generatedAt: Date = Date(),
        comparisonFlowTemperatureC: Double? = nil
    ) -> HeizBalanceLowTemperatureReportSnapshot {
        let comparisonFlow = comparisonFlowTemperatureC ?? designFlowTemperatureC
        let state = lowTemperatureProjectState(
            comparisonFlowTemperatureC: comparisonFlow
        )
        let comparisonReturn: Double?
        if let comparisonFlow,
           let spread = state.waterTemperatureDifferenceK {
            comparisonReturn = comparisonFlow - spread
        } else {
            comparisonReturn = nil
        }

        return HeizBalanceLowTemperatureReportSnapshot(
            schema: HeizBalanceLowTemperatureReportSnapshot.schemaVersion,
            calculationProfile: HeizBalanceLowTemperatureReportSnapshot.calculationProfileVersion,
            generatedAt: generatedAt,
            projectID: id,
            projectName: name,
            technicalPreparationOnly: true,
            waterTemperatureDifferenceK: state.waterTemperatureDifferenceK,
            comparisonFlowTemperatureC: comparisonFlow,
            comparisonReturnTemperatureC: comparisonReturn,
            surfaceCount: state.entries.count,
            evaluableSurfaceCount: state.evaluableSurfaceCount,
            coverageComplete: state.coverageComplete,
            minimumSystemFlowTemperatureC: state.minimumSystemFlowTemperatureC,
            minimumSystemReturnTemperatureC: state.minimumSystemReturnTemperatureC,
            limitingSurfaceName: state.limitingEntry?.displayName,
            comparisonSufficient: state.comparisonSufficient,
            surfaces: state.entries.map { entry in
                .init(
                    id: entry.id,
                    floorName: entry.floorName,
                    roomName: entry.roomName,
                    surfaceName: entry.surfaceName,
                    minimumFlowTemperatureC: entry.result?.minimumFlowTemperatureC,
                    minimumReturnTemperatureC: entry.result?.minimumReturnTemperatureC,
                    comparisonAvailablePowerW: entry.result?.comparisonAvailablePowerW,
                    comparisonCapacityRatio: entry.result?.comparisonCapacityRatio,
                    comparisonSufficient: entry.result?.comparisonSufficient,
                    missingInputs: entry.missingInputs
                )
            }
        )
    }
}
