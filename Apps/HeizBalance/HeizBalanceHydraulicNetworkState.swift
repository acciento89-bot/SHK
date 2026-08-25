import Foundation

struct HeizBalanceHydraulicNetworkConsumerEntry: Identifiable, Hashable {
    var id: UUID
    var floorName: String
    var roomName: String
    var surfaceName: String
    var targetVolumeFlowLPH: Double?

    var displayName: String { "\(roomName) · \(surfaceName)" }
}

struct HeizBalanceHydraulicNetworkLinkedPipe: Identifiable, Hashable {
    var id: UUID
    var surfaceID: UUID
    var floorName: String
    var roomName: String
    var surfaceName: String
    var pipeName: String
    var segmentID: UUID
    var storedVolumeFlowLPH: Double?
    var calculatedVolumeFlowLPH: Double?

    var isCurrent: Bool {
        guard let storedVolumeFlowLPH, let calculatedVolumeFlowLPH else { return false }
        return abs(storedVolumeFlowLPH - calculatedVolumeFlowLPH) <= 0.05
    }
}

struct HeizBalanceHydraulicNetworkProjectState {
    var consumers: [HeizBalanceHydraulicNetworkConsumerEntry]
    var result: HeizBalanceHydraulicNetworkCalculator.Result?
    var linkedPipes: [HeizBalanceHydraulicNetworkLinkedPipe]

    var staleLinkedPipeCount: Int {
        linkedPipes.filter { !$0.isCurrent }.count
    }

    var hasStaleLinkedPipes: Bool { staleLinkedPipeCount > 0 }

    func designFlow(segmentID: UUID) -> Double? {
        result?.segment(id: segmentID.uuidString)?.designVolumeFlowLPH
    }
}

extension HeizBalanceProject {
    func hydraulicNetworkState() -> HeizBalanceHydraulicNetworkProjectState {
        var consumers: [HeizBalanceHydraulicNetworkConsumerEntry] = []

        for floor in floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    let hydronic = surface.hydronicPreparation(
                        flowTemperatureC: designFlowTemperatureC,
                        returnTemperatureC: designReturnTemperatureC,
                        roomTemperatureC: room.targetTemperature
                    )
                    consumers.append(
                        .init(
                            id: surface.id,
                            floorName: floor.name,
                            roomName: room.name,
                            surfaceName: surface.name,
                            targetVolumeFlowLPH: hydronic?.targetVolumeFlowLPH
                        )
                    )
                }
            }
        }

        let network = hydraulicNetwork
        let result: HeizBalanceHydraulicNetworkCalculator.Result?
        if let network, network.schema == HeizBalanceHydraulicNetwork.schemaVersion {
            result = HeizBalanceHydraulicNetworkCalculator.calculate(
                .init(
                    consumers: consumers.map {
                        .init(
                            id: $0.id.uuidString,
                            name: $0.displayName,
                            targetVolumeFlowLPH: $0.targetVolumeFlowLPH
                        )
                    },
                    segments: network.segments.map {
                        .init(
                            id: $0.id.uuidString,
                            name: $0.name,
                            parentSegmentID: $0.parentSegmentID?.uuidString,
                            directConsumerIDs: $0.directConsumerSurfaceIDs.map(\.uuidString)
                        )
                    }
                )
            )
        } else {
            result = nil
        }

        var linked: [HeizBalanceHydraulicNetworkLinkedPipe] = []
        for floor in floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    for pipe in surface.pipeSections ?? [] {
                        guard pipe.effectiveRole == .sharedDistribution,
                              let segmentID = pipe.networkSegmentID else { continue }
                        linked.append(
                            .init(
                                id: pipe.id,
                                surfaceID: surface.id,
                                floorName: floor.name,
                                roomName: room.name,
                                surfaceName: surface.name,
                                pipeName: pipe.name,
                                segmentID: segmentID,
                                storedVolumeFlowLPH: pipe.explicitDesignVolumeFlowLPH,
                                calculatedVolumeFlowLPH: result?.segment(id: segmentID.uuidString)?.designVolumeFlowLPH
                            )
                        )
                    }
                }
            }
        }

        return .init(
            consumers: consumers,
            result: result,
            linkedPipes: linked
        )
    }

    mutating func applyHydraulicNetworkFlows() -> Int {
        let state = hydraulicNetworkState()
        guard let result = state.result else { return 0 }
        var updated = 0

        for floorIndex in floors.indices {
            for roomIndex in floors[floorIndex].rooms.indices {
                let surfaces = floors[floorIndex].rooms[roomIndex].heatingSurfaces ?? []
                var updatedSurfaces = surfaces

                for surfaceIndex in updatedSurfaces.indices {
                    var pipes = updatedSurfaces[surfaceIndex].pipeSections ?? []
                    for pipeIndex in pipes.indices {
                        guard pipes[pipeIndex].effectiveRole == .sharedDistribution,
                              let segmentID = pipes[pipeIndex].networkSegmentID,
                              let flow = result.segment(id: segmentID.uuidString)?.designVolumeFlowLPH else {
                            continue
                        }
                        if pipes[pipeIndex].explicitDesignVolumeFlowLPH != flow || pipes[pipeIndex].volumeFlowSource != nil {
                            pipes[pipeIndex].explicitDesignVolumeFlowLPH = flow
                            pipes[pipeIndex].volumeFlowSource = nil
                            updated += 1
                        }
                    }
                    updatedSurfaces[surfaceIndex].pipeSections = pipes
                }
                floors[floorIndex].rooms[roomIndex].heatingSurfaces = updatedSurfaces
            }
        }
        return updated
    }

    mutating func detachMissingHydraulicNetworkLinks() -> Int {
        let validSegmentIDs = Set((hydraulicNetwork?.segments ?? []).map(\.id))
        var detached = 0
        for floorIndex in floors.indices {
            for roomIndex in floors[floorIndex].rooms.indices {
                var surfaces = floors[floorIndex].rooms[roomIndex].heatingSurfaces ?? []
                for surfaceIndex in surfaces.indices {
                    var pipes = surfaces[surfaceIndex].pipeSections ?? []
                    for pipeIndex in pipes.indices {
                        if let segmentID = pipes[pipeIndex].networkSegmentID,
                           !validSegmentIDs.contains(segmentID) {
                            pipes[pipeIndex].networkSegmentID = nil
                            detached += 1
                        }
                    }
                    surfaces[surfaceIndex].pipeSections = pipes
                }
                floors[floorIndex].rooms[roomIndex].heatingSurfaces = surfaces
            }
        }
        return detached
    }
}
