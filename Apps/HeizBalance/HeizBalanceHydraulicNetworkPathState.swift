import Foundation

struct HeizBalanceHydraulicNetworkPathProjectState {
    var centralPipeModeActive: Bool
    var segmentOwnedPipeCount: Int
    var segmentOwnedComponentCount: Int
    var centralLinkedPipeCount: Int
    var unlinkedLegacySharedPipeCount: Int
    var result: HeizBalanceHydraulicNetworkPathCalculator.Result?

    var totalCentralElementCount: Int {
        segmentOwnedPipeCount + segmentOwnedComponentCount + centralLinkedPipeCount
    }

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
                segmentOwnedPipeCount: 0,
                segmentOwnedComponentCount: 0,
                centralLinkedPipeCount: 0,
                unlinkedLegacySharedPipeCount: legacySharedPipeCount,
                result: nil
            )
        }

        var pipesBySegment: [UUID: [HeizBalanceHydraulicNetworkPathCalculator.PipeSectionInput]] = [:]
        var segmentOwnedCount = 0
        var segmentOwnedComponentCount = 0
        var linkedCount = 0
        var unlinkedCount = 0

        for segment in network.segments {
            for pipe in segment.pipeSections ?? [] {
                segmentOwnedCount += 1
                pipesBySegment[segment.id, default: []].append(
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
            segmentOwnedComponentCount += (segment.hydraulicLossComponents ?? []).count
        }

        // Backward compatibility for Batch-31/34 projects. Legacy linked shared
        // pipes remain fully usable until the user explicitly migrates them into
        // their network segment. Once migrated, they are removed from the
        // heating-surface path and therefore cannot be counted twice.
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

        let centralModeActive = segmentOwnedCount + segmentOwnedComponentCount + linkedCount > 0
        guard centralModeActive,
              let networkResult = networkState.result,
              let density = hydraulicFluidDensityKGPerM3,
              let viscosityMM2S = hydraulicKinematicViscosityMM2S,
              density > 0,
              viscosityMM2S > 0 else {
            return .init(
                centralPipeModeActive: centralModeActive,
                segmentOwnedPipeCount: segmentOwnedCount,
                segmentOwnedComponentCount: segmentOwnedComponentCount,
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
            let components = segment.hydraulicLossComponents ?? []
            return HeizBalanceHydraulicNetworkPathCalculator.SegmentInput(
                id: segment.id.uuidString,
                name: segment.name,
                parentSegmentID: segment.parentSegmentID?.uuidString,
                designVolumeFlowLPH: networkResult.segment(id: segment.id.uuidString)?.designVolumeFlowLPH,
                pipeSections: pipesBySegment[segment.id] ?? [],
                components: components.map {
                    .init(
                        id: $0.id.uuidString,
                        name: $0.name,
                        pressureLossKPa: $0.pressureLossKPa
                    )
                },
                componentAssessmentComplete: components.isEmpty || segment.hydraulicComponentAssessmentComplete == true
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
            segmentOwnedPipeCount: segmentOwnedCount,
            segmentOwnedComponentCount: segmentOwnedComponentCount,
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
