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

        // Only legacy Batch-31/34 shared pipes live below heating surfaces and
        // require stored-Q synchronization. New segment-owned pipe sections do
        // not persist Q at all; they always use the current calculated segment Q.
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

        // Compatibility sync only. Segment-owned shared pipe geometry has no
        // stored flow and is evaluated directly with the live segment result.
        for floorIndex in floors.indices {
            for roomIndex in floors[floorIndex].rooms.indices {
                var surfaces = floors[floorIndex].rooms[roomIndex].heatingSurfaces ?? []
                for surfaceIndex in surfaces.indices {
                    var pipes = surfaces[surfaceIndex].pipeSections ?? []
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
                    surfaces[surfaceIndex].pipeSections = pipes
                }
                floors[floorIndex].rooms[roomIndex].heatingSurfaces = surfaces
            }
        }
        return updated
    }

    @discardableResult
    mutating func normalizeHydraulicNetworkReferences() -> Int {
        var changes = 0
        let validConsumerIDs = Set(
            floors.flatMap { floor in
                floor.rooms.flatMap { room in
                    (room.heatingSurfaces ?? []).map(\.id)
                }
            }
        )
        let validSegmentIDs = Set((hydraulicNetwork?.segments ?? []).map(\.id))

        if var network = hydraulicNetwork {
            for index in network.segments.indices {
                let before = network.segments[index].directConsumerSurfaceIDs.count
                network.segments[index].directConsumerSurfaceIDs.removeAll { !validConsumerIDs.contains($0) }
                changes += before - network.segments[index].directConsumerSurfaceIDs.count

                if let parent = network.segments[index].parentSegmentID,
                   !validSegmentIDs.contains(parent) {
                    network.segments[index].parentSegmentID = nil
                    changes += 1
                }

                // Segment-owned geometry is canonical shared-distribution data.
                // Strip legacy linkage/flow metadata if an older pipe object was
                // copied here by migration or external editing.
                var segmentPipes = network.segments[index].pipeSections ?? []
                for pipeIndex in segmentPipes.indices {
                    if segmentPipes[pipeIndex].role != .sharedDistribution {
                        segmentPipes[pipeIndex].role = .sharedDistribution
                        changes += 1
                    }
                    if segmentPipes[pipeIndex].networkSegmentID != nil {
                        segmentPipes[pipeIndex].networkSegmentID = nil
                        changes += 1
                    }
                    if segmentPipes[pipeIndex].explicitDesignVolumeFlowLPH != nil {
                        segmentPipes[pipeIndex].explicitDesignVolumeFlowLPH = nil
                        changes += 1
                    }
                    if segmentPipes[pipeIndex].volumeFlowSource != nil {
                        segmentPipes[pipeIndex].volumeFlowSource = nil
                        changes += 1
                    }
                }
                network.segments[index].pipeSections = segmentPipes
            }
            hydraulicNetwork = network
        }

        for floorIndex in floors.indices {
            for roomIndex in floors[floorIndex].rooms.indices {
                var surfaces = floors[floorIndex].rooms[roomIndex].heatingSurfaces ?? []
                for surfaceIndex in surfaces.indices {
                    var pipes = surfaces[surfaceIndex].pipeSections ?? []
                    for pipeIndex in pipes.indices {
                        guard let segmentID = pipes[pipeIndex].networkSegmentID else { continue }
                        if pipes[pipeIndex].effectiveRole != .sharedDistribution || !validSegmentIDs.contains(segmentID) {
                            pipes[pipeIndex].networkSegmentID = nil
                            changes += 1
                        }
                    }
                    surfaces[surfaceIndex].pipeSections = pipes
                }
                floors[floorIndex].rooms[roomIndex].heatingSurfaces = surfaces
            }
        }
        return changes
    }

    /// Moves legacy shared pipe sections that are already linked to a valid
    /// network segment into that segment's own geometry collection. Technical
    /// geometry, zeta and notes are preserved. Stored legacy Q/source metadata
    /// is intentionally removed because segment Q is derived live from consumers.
    /// The original heating-surface copy is removed in the same operation, so a
    /// migrated physical pipe can never be counted twice.
    @discardableResult
    mutating func migrateLinkedSharedPipesIntoNetworkSegments() -> Int {
        guard var network = hydraulicNetwork else { return 0 }
        let segmentIndexByID = Dictionary(uniqueKeysWithValues: network.segments.indices.map { (network.segments[$0].id, $0) })
        var migrated = 0

        for floorIndex in floors.indices {
            for roomIndex in floors[floorIndex].rooms.indices {
                var surfaces = floors[floorIndex].rooms[roomIndex].heatingSurfaces ?? []
                for surfaceIndex in surfaces.indices {
                    let originalPipes = surfaces[surfaceIndex].pipeSections ?? []
                    var retained: [HeizBalancePipeSection] = []

                    for var pipe in originalPipes {
                        guard pipe.effectiveRole == .sharedDistribution,
                              let segmentID = pipe.networkSegmentID,
                              let segmentIndex = segmentIndexByID[segmentID] else {
                            retained.append(pipe)
                            continue
                        }

                        var segmentPipes = network.segments[segmentIndex].pipeSections ?? []
                        if !segmentPipes.contains(where: { $0.id == pipe.id }) {
                            pipe.role = .sharedDistribution
                            pipe.networkSegmentID = nil
                            pipe.explicitDesignVolumeFlowLPH = nil
                            pipe.volumeFlowSource = nil
                            segmentPipes.append(pipe)
                            network.segments[segmentIndex].pipeSections = segmentPipes
                        }
                        migrated += 1
                    }

                    surfaces[surfaceIndex].pipeSections = retained
                }
                floors[floorIndex].rooms[roomIndex].heatingSurfaces = surfaces
            }
        }

        hydraulicNetwork = network
        _ = normalizeHydraulicNetworkReferences()
        return migrated
    }

    mutating func detachMissingHydraulicNetworkLinks() -> Int {
        normalizeHydraulicNetworkReferences()
    }
}
