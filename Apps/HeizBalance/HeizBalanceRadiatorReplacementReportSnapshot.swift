import Foundation

struct HeizBalanceRadiatorReplacementReportSnapshot: Codable, Hashable {
    static let schemaVersion = "technical-radiator-replacements-v1"

    var schema: String
    var generatedAt: Date
    var projectID: UUID
    var projectName: String
    var technicalPreparationOnly: Bool
    var entries: [Entry]

    struct Entry: Codable, Hashable, Identifiable {
        var id: UUID { surfaceID }
        var surfaceID: UUID
        var floorName: String
        var roomName: String
        var surfaceName: String
        var currentTargetMatchesSelection: Bool
        var selection: HeizBalanceRadiatorReplacementSelection
    }
}

extension HeizBalanceProject {
    func radiatorReplacementReportSnapshot(
        generatedAt: Date = Date()
    ) -> HeizBalanceRadiatorReplacementReportSnapshot {
        let currentFlow = retrofitTargetFlowTemperatureC
        let currentReturn = retrofitTargetReturnTemperatureC
        var entries: [HeizBalanceRadiatorReplacementReportSnapshot.Entry] = []

        for floor in floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    guard let selection = surface.replacementSelection else { continue }

                    let targetMatches: Bool
                    if let currentFlow, let currentReturn {
                        targetMatches = abs(currentFlow - selection.targetFlowTemperatureC) < 0.001
                            && abs(currentReturn - selection.targetReturnTemperatureC) < 0.001
                    } else {
                        targetMatches = false
                    }

                    entries.append(
                        .init(
                            surfaceID: surface.id,
                            floorName: floor.name,
                            roomName: room.name,
                            surfaceName: surface.name,
                            currentTargetMatchesSelection: targetMatches,
                            selection: selection
                        )
                    )
                }
            }
        }

        return .init(
            schema: Self.radiatorReplacementSnapshotSchema,
            generatedAt: generatedAt,
            projectID: id,
            projectName: name,
            technicalPreparationOnly: true,
            entries: entries
        )
    }

    private static var radiatorReplacementSnapshotSchema: String {
        HeizBalanceRadiatorReplacementReportSnapshot.schemaVersion
    }
}
