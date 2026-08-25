import Foundation

struct HeizBalanceHydraulicSystemCircuitEntry: Identifiable {
    var id: UUID
    var floorName: String
    var roomName: String
    var surfaceName: String
    var targetVolumeFlowLPH: Double?
    var completePressureLossKPa: Double?
    var hydraulicNetworkCurrent: Bool

    var displayName: String {
        "\(roomName) · \(surfaceName)"
    }
}

struct HeizBalanceHydraulicSystemPreviewState {
    var circuits: [HeizBalanceHydraulicSystemCircuitEntry]
    var result: HeizBalanceHydraulicSystemPreparationCalculator.Result?
    var networkState: HeizBalanceHydraulicNetworkProjectState
}

extension HeizBalanceProject {
    func hydraulicSystemPreparationState() -> HeizBalanceHydraulicSystemPreviewState {
        var entries: [HeizBalanceHydraulicSystemCircuitEntry] = []
        let networkState = hydraulicNetworkState()
        let staleSurfaceIDs = Set(networkState.linkedPipes.filter { !$0.isCurrent }.map(\.surfaceID))

        for floor in floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    let hydronic = surface.hydronicPreparation(
                        flowTemperatureC: designFlowTemperatureC,
                        returnTemperatureC: designReturnTemperatureC,
                        roomTemperatureC: room.targetTemperature
                    )
                    let circuit = surface.circuitPressureLossSummary(
                        flowTemperatureC: designFlowTemperatureC,
                        returnTemperatureC: designReturnTemperatureC,
                        roomTemperatureC: room.targetTemperature,
                        densityKGPerM3: hydraulicFluidDensityKGPerM3,
                        kinematicViscosityMM2S: hydraulicKinematicViscosityMM2S
                    )
                    let networkCurrent = !staleSurfaceIDs.contains(surface.id)

                    entries.append(
                        HeizBalanceHydraulicSystemCircuitEntry(
                            id: surface.id,
                            floorName: floor.name,
                            roomName: room.name,
                            surfaceName: surface.name,
                            targetVolumeFlowLPH: hydronic?.targetVolumeFlowLPH,
                            completePressureLossKPa: networkCurrent ? circuit?.completeCircuitPressureLossKPa : nil,
                            hydraulicNetworkCurrent: networkCurrent
                        )
                    )
                }
            }
        }

        let inputs = entries.map {
            HeizBalanceHydraulicSystemPreparationCalculator.CircuitInput(
                id: $0.id.uuidString,
                name: $0.displayName,
                targetVolumeFlowLPH: $0.targetVolumeFlowLPH,
                completePressureLossKPa: $0.completePressureLossKPa
            )
        }

        let result = HeizBalanceHydraulicSystemPreparationCalculator.calculate(
            .init(
                circuits: inputs,
                densityKGPerM3: hydraulicFluidDensityKGPerM3
            )
        )

        return HeizBalanceHydraulicSystemPreviewState(
            circuits: entries,
            result: result,
            networkState: networkState
        )
    }
}
