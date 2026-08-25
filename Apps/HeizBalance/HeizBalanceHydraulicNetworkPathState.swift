import Foundation

struct HeizBalanceHydraulicNetworkPathProjectState {
    var centralPipeModeActive: Bool
    var centralLinkedPipeCount: Int
    var unlinkedLegacySharedPipeCount: Int
    var result: HeizBalanceHydraulicNetworkPathCalculator.Result?

    func completePressureLoss(surfaceID: UUID) -> Double? {
        result?.consumer(id: surfaceID.uuidString)?.completePathPressureLossKPa
    }

    func knownPressureLoss(surfaceID: UUID) -> Double? {
        result?.consumer(id: surfaceID.uuidString)?.knownPathPressureLossKPa
    }
}

extension HeizBalanceProject {
    func hydraulicNetworkPathState() -> HeizBalanceHydraulicNetworkPathProjectState {
        let networkState = hydraulicNetworkState()
        guard let network = hydraulicNetwork,
              network.schema == HeizBalanceHydraulicNetwork.schemaVersion else {
            return .init(
                centralPipeModeActive: false,
                centralLinkedPipeCount: 0,
                unlinkedLegacySharedPipeCount: legacySharedPipeCount,
                result: nil
            )
        }

        var pipesBySegment: [UUID: [HeizBalanceHydraulicNetworkPathCalculator.PipeSectionInput]] = [:]
        var linkedCount = 0
        var unlinkedCount = 0

        for floor in floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    for pipe in surface.pipeSections ?? [] where pipe.effectiveRole == .sharedDistribution {
                        guard let segmentID = pipe.networkSegmentID else {
                            unlinkedCount += 1
                            continue
                        }
                        linkedCount += 1
                        pipesBySegment[segmentID, default: []].append(
                            .init(
                                id: pipe.id.uuidString,
                                name: pipe.name,
                                innerDiameterMM: pipe.innerDiameterMM,
                                lengthM: pipe.lengthM,
                                roughnessMM: pipe.roughnessMM,
                                zetaTotal: pipe.zetaTotal
                            )
                        )
                    }
                }
            }
        }

        guard linkedCount > 0,
              let networkResult = networkState.result,
              let density = hydraulicFluidDensityKGPerM3,
              let viscosityMM2S = hydraulicKinematicViscosityMM2S,
              density > 0,
              viscosityMM2S > 0 else {
            return .init(
                centralPipeModeActive: linkedCount > 0,
                centralLinkedPipeCount: linkedCount,
                unlinkedLegacySharedPipeCount: unlinkedCount,
                result: nil
            )
        }

        var assignedSegmentByConsumer: [UUID: UUID] = [:]
        for segment in network.segments {
            for consumerID in segment.directConsumerSurfaceIDs {
                assignedSegmentByConsumer[consumerID] = segment.id
            }
        }

        let segmentInputs = network.segments.map { segment in
            HeizBalanceHydraulicNetworkPathCalculator.SegmentInput(
                id: segment.id.uuidString,
                name: segment.name,
                parentSegmentID: segment.parentSegmentID?.uuidString,
                designVolumeFlowLPH: networkResult.segment(id: segment.id.uuidString)?.designVolumeFlowLPH,
                pipeSections: pipesBySegment[segment.id] ?? []
            )
        }

        var consumerInputs: [HeizBalanceHydraulicNetworkPathCalculator.ConsumerInput] = []
        for floor in floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    let terminal = surface.terminalCircuitPressureLossSummary(
                        flowTemperatureC: designFlowTemperatureC,
                        returnTemperatureC: designReturnTemperatureC,
                        roomTemperatureC: room.targetTemperature,
                        densityKGPerM3: density,
                        kinematicViscosityMM2S: viscosityMM2S
                    )
                    consumerInputs.append(
                        .init(
                            id: surface.id.uuidString,
                            name: room.name + " · " + surface.name,
                            assignedSegmentID: assignedSegmentByConsumer[surface.id]?.uuidString,
                            terminalCompletePressureLossKPa: terminal?.completeCircuitPressureLossKPa,
                            terminalKnownPressureLossKPa: terminal?.knownCircuitPressureLossKPa ?? 0
                        )
                    )
                }
            }
        }

        let result = HeizBalanceHydraulicNetworkPathCalculator.calculate(
            .init(
                densityKGPerM3: density,
                kinematicViscosityM2S: viscosityMM2S * 1e-6,
                segments: segmentInputs,
                consumers: consumerInputs
            )
        )

        return .init(
            centralPipeModeActive: true,
            centralLinkedPipeCount: linkedCount,
            unlinkedLegacySharedPipeCount: unlinkedCount,
            result: result
        )
    }

    private var legacySharedPipeCount: Int {
        floors.reduce(0) { floorTotal, floor in
            floorTotal + floor.rooms.reduce(0) { roomTotal, room in
                roomTotal + (room.heatingSurfaces ?? []).reduce(0) { surfaceTotal, surface in
                    surfaceTotal + (surface.pipeSections ?? []).filter {
                        $0.effectiveRole == .sharedDistribution && $0.networkSegmentID == nil
                    }.count
                }
            }
        }
    }
}
