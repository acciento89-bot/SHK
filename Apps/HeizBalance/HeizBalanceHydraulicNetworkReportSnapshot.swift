import Foundation

struct HeizBalanceHydraulicNetworkReportSnapshot: Codable, Hashable {
    static let schemaVersion = "technical-hydraulic-network-v1"

    var schema: String
    var generatedAt: Date
    var projectID: UUID
    var projectName: String
    var profileVersion: String
    var networkValid: Bool
    var consumerCount: Int
    var assignedConsumerCount: Int
    var allConsumersAssigned: Bool
    var staleLinkedPipeCount: Int
    var segments: [Segment]
    var linkedPipes: [LinkedPipe]
    var notice: String

    // Optional Batch-32+ extension. Optional on purpose so archived Batch-31
    // technical-hydraulic-network-v1 JSON remains decodable unchanged.
    var pathProfileVersion: String?
    var centralPathModeActive: Bool?
    var centralLinkedPipeCount: Int?
    var unlinkedLegacySharedPipeCount: Int?
    var consumerPaths: [ConsumerPath]?

    struct Segment: Identifiable, Codable, Hashable {
        var id: UUID
        var name: String
        var parentSegmentID: UUID?
        var parentName: String?
        var depth: Int
        var directConsumers: [String]
        var downstreamConsumerCount: Int
        var knownVolumeFlowLPH: Double
        var designVolumeFlowLPH: Double?
        var unresolvedConsumers: [String]
        var note: String

        // Optional Batch-32+ edge/path evidence.
        var centralPipeSectionCount: Int?
        var knownPressureLossKPa: Double?
        var completePressureLossKPa: Double?
        var pressureCoverageComplete: Bool?
    }

    struct LinkedPipe: Identifiable, Codable, Hashable {
        var id: UUID
        var floorName: String
        var roomName: String
        var surfaceName: String
        var pipeName: String
        var segmentID: UUID
        var segmentName: String
        var storedVolumeFlowLPH: Double?
        var calculatedVolumeFlowLPH: Double?
        var current: Bool
    }

    struct ConsumerPath: Identifiable, Codable, Hashable {
        var id: UUID { surfaceID }
        var surfaceID: UUID
        var displayName: String
        var assignedSegmentID: UUID?
        var pathSegmentIDs: [UUID]
        var pathSegmentNames: [String]
        var knownSharedPressureLossKPa: Double
        var terminalKnownPressureLossKPa: Double
        var knownPathPressureLossKPa: Double
        var completePathPressureLossKPa: Double?
        var pathCoverageComplete: Bool
    }

    static func make(project: HeizBalanceProject, generatedAt: Date = Date()) -> Self {
        let state = project.hydraulicNetworkState()
        let pathState = project.hydraulicNetworkPathState()
        let networkSegments = project.hydraulicNetwork?.segments ?? []
        let segmentNameByID = Dictionary(uniqueKeysWithValues: networkSegments.map { ($0.id, $0.name) })
        let consumerNameByID = Dictionary(uniqueKeysWithValues: state.consumers.map { ($0.id.uuidString, $0.displayName) })
        let resultByID = Dictionary(uniqueKeysWithValues: (state.result?.segments ?? []).map { ($0.id, $0) })
        let pathSegmentByID = Dictionary(uniqueKeysWithValues: (pathState.result?.segments ?? []).map { ($0.id, $0) })

        let segmentRows = networkSegments.map { segment -> Segment in
            let result = resultByID[segment.id.uuidString]
            let path = pathSegmentByID[segment.id.uuidString]
            return Segment(
                id: segment.id,
                name: segment.name,
                parentSegmentID: segment.parentSegmentID,
                parentName: segment.parentSegmentID.flatMap { segmentNameByID[$0] },
                depth: result?.depth ?? 0,
                directConsumers: segment.directConsumerSurfaceIDs.map { consumerNameByID[$0.uuidString] ?? "Nicht mehr vorhandene Heizfläche · \($0.uuidString)" },
                downstreamConsumerCount: result?.downstreamConsumerIDs.count ?? 0,
                knownVolumeFlowLPH: result?.knownVolumeFlowLPH ?? 0,
                designVolumeFlowLPH: result?.designVolumeFlowLPH,
                unresolvedConsumers: (result?.unresolvedConsumerIDs ?? []).map { consumerNameByID[$0] ?? $0 },
                note: segment.note,
                centralPipeSectionCount: pathState.centralPipeModeActive ? path?.pipeSectionCount : nil,
                knownPressureLossKPa: pathState.centralPipeModeActive ? path?.knownPressureLossKPa : nil,
                completePressureLossKPa: pathState.centralPipeModeActive ? path?.completePressureLossKPa : nil,
                pressureCoverageComplete: pathState.centralPipeModeActive ? path?.pressureCoverageComplete : nil
            )
        }

        let linked = state.linkedPipes.map { pipe in
            LinkedPipe(
                id: pipe.id,
                floorName: pipe.floorName,
                roomName: pipe.roomName,
                surfaceName: pipe.surfaceName,
                pipeName: pipe.pipeName,
                segmentID: pipe.segmentID,
                segmentName: segmentNameByID[pipe.segmentID] ?? "Unbekanntes Segment",
                storedVolumeFlowLPH: pipe.storedVolumeFlowLPH,
                calculatedVolumeFlowLPH: pipe.calculatedVolumeFlowLPH,
                current: pipe.isCurrent
            )
        }

        let consumerPaths: [ConsumerPath]?
        if pathState.centralPipeModeActive {
            consumerPaths = pathState.result?.consumers.compactMap { consumer in
                guard let surfaceID = UUID(uuidString: consumer.id) else { return nil }
                let assignedID = consumer.assignedSegmentID.flatMap(UUID.init(uuidString:))
                let pathIDs = consumer.pathSegmentIDs.compactMap(UUID.init(uuidString:))
                return ConsumerPath(
                    surfaceID: surfaceID,
                    displayName: consumer.name,
                    assignedSegmentID: assignedID,
                    pathSegmentIDs: pathIDs,
                    pathSegmentNames: consumer.pathSegmentIDs.map { id in
                        guard let uuid = UUID(uuidString: id) else { return id }
                        return segmentNameByID[uuid] ?? id
                    },
                    knownSharedPressureLossKPa: consumer.knownSharedPressureLossKPa,
                    terminalKnownPressureLossKPa: consumer.terminalKnownPressureLossKPa,
                    knownPathPressureLossKPa: consumer.knownPathPressureLossKPa,
                    completePathPressureLossKPa: consumer.completePathPressureLossKPa,
                    pathCoverageComplete: consumer.pathCoverageComplete
                )
            }
        } else {
            consumerPaths = nil
        }

        return Self(
            schema: schemaVersion,
            generatedAt: generatedAt,
            projectID: project.id,
            projectName: project.name,
            profileVersion: HeizBalanceHydraulicNetworkCalculator.profileVersion,
            networkValid: state.result != nil,
            consumerCount: state.result?.consumerCount ?? state.consumers.count,
            assignedConsumerCount: state.result?.assignedConsumerCount ?? 0,
            allConsumersAssigned: state.result?.allConsumersAssigned ?? false,
            staleLinkedPipeCount: state.staleLinkedPipeCount,
            segments: segmentRows,
            linkedPipes: linked,
            notice: "Technische Netzbaum-Dokumentation. Segment-Q werden ausschließlich aus den aktuell zugeordneten Heizflächen-Zielvolumenströmen summiert. Im zentralen Pfadmodus werden verknüpfte gemeinsame Rohrabschnitte je Netzsegment genau einmal gerechnet; jeder Verbraucherpfad erhält die seriellen Segmentverluste plus ausschließlich terminale Heizflächen-Anbindung und Bauteilverluste. Fehlende Rohr-/ζ-/Fluid-/Q-Daten blockieren vollständige Pfad- und Pumpenergebnisse. Kein Verfahren-B-/GEG-/BEG-Nachweis.",
            pathProfileVersion: pathState.centralPipeModeActive ? HeizBalanceHydraulicNetworkPathCalculator.profileVersion : nil,
            centralPathModeActive: pathState.centralPipeModeActive,
            centralLinkedPipeCount: pathState.centralLinkedPipeCount,
            unlinkedLegacySharedPipeCount: pathState.unlinkedLegacySharedPipeCount,
            consumerPaths: consumerPaths
        )
    }
}
