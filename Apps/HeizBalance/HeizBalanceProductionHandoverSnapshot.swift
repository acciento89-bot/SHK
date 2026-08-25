import Foundation

struct HeizBalanceProductionHandoverSnapshot: Codable, Hashable {
    static let schemaVersion = "technical-handover-v1"

    struct Summary: Codable, Hashable {
        var floorCount: Int
        var roomCount: Int
        var heatLossReadyRoomCount: Int
        var heatingSurfaceCount: Int
        var targetFlowReadyCount: Int
        var circuitPressureReadyCount: Int
        var currentValveSettingCount: Int
        var staleValveSettingCount: Int
        var valveWithoutHeldSettingCount: Int
        var pumpSelectionPresent: Bool
        var pumpSelectionCurrent: Bool?
        var openTechnicalItemCount: Int
    }

    struct FloorSummary: Identifiable, Codable, Hashable {
        var id: UUID
        var name: String
        var roomCount: Int
        var heatingSurfaceCount: Int
        var heatLossReadyRoomCount: Int
    }

    var schema: String
    var generatedAt: Date
    var projectID: UUID
    var projectName: String
    var customerName: String
    var address: String
    var documentation: HeizBalanceDocumentationSnapshot
    var summary: Summary
    var floors: [FloorSummary]
    var notice: String

    static func make(
        project: HeizBalanceProject,
        documentation: HeizBalanceDocumentationMetadata,
        valveSelections: [HeizBalanceValveSettingSelection],
        pumpSelection: HeizBalancePumpSelection?,
        generatedAt: Date = Date()
    ) -> Self {
        let adjustment = HeizBalanceAdjustmentListSnapshot.make(
            project: project,
            valveSelections: valveSelections,
            pumpSelection: pumpSelection,
            generatedAt: generatedAt
        )

        let floorSummaries = project.floors.map { floor in
            FloorSummary(
                id: floor.id,
                name: floor.name,
                roomCount: floor.rooms.count,
                heatingSurfaceCount: floor.rooms.reduce(0) { $0 + ($1.heatingSurfaces ?? []).count },
                heatLossReadyRoomCount: floor.rooms.filter {
                    $0.heatLossPreview(designOutdoorTemperatureC: project.designOutdoorTemperatureC).result != nil
                }.count
            )
        }

        let roomCount = floorSummaries.reduce(0) { $0 + $1.roomCount }
        let heatLossReadyRoomCount = floorSummaries.reduce(0) { $0 + $1.heatLossReadyRoomCount }
        let heatingSurfaceCount = floorSummaries.reduce(0) { $0 + $1.heatingSurfaceCount }
        let currentValveSettingCount = adjustment.summary.currentThermostatSettingCount
            + adjustment.summary.currentReturnSettingCount
        let rowOpenItems = adjustment.rows.reduce(0) { $0 + $1.missingNotes.count }
        let incompleteHeatLossRooms = max(0, roomCount - heatLossReadyRoomCount)
        let openTechnicalItems = rowOpenItems + incompleteHeatLossRooms

        return Self(
            schema: Self.schemaVersion,
            generatedAt: generatedAt,
            projectID: project.id,
            projectName: project.name,
            customerName: project.customerName,
            address: project.displayAddress,
            documentation: .init(metadata: documentation),
            summary: .init(
                floorCount: floorSummaries.count,
                roomCount: roomCount,
                heatLossReadyRoomCount: heatLossReadyRoomCount,
                heatingSurfaceCount: heatingSurfaceCount,
                targetFlowReadyCount: adjustment.summary.flowReadyCount,
                circuitPressureReadyCount: adjustment.summary.pressureReadyCount,
                currentValveSettingCount: currentValveSettingCount,
                staleValveSettingCount: adjustment.summary.staleValveSettingCount,
                valveWithoutHeldSettingCount: adjustment.summary.valveWithoutHeldSettingCount,
                pumpSelectionPresent: adjustment.pump != nil,
                pumpSelectionCurrent: adjustment.pump?.selectionCurrent,
                openTechnicalItemCount: openTechnicalItems
            ),
            floors: floorSummaries,
            notice: "Technische Übergabe-Zusammenfassung. Projektstatus und Personendaten werden ausdrücklich vom Bearbeiter gepflegt. Eine Unterschrift bestätigt nur Übergabe bzw. dokumentierten Arbeitsstand und ersetzt keine DIN-, Verfahren-B-, GEG-/BEG- oder Herstellerfreigabe."
        )
    }
}
