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

    static func make(project: HeizBalanceProject, generatedAt: Date = Date()) -> Self {
        let state = project.hydraulicNetworkState()
        let networkSegments = project.hydraulicNetwork?.segments ?? []
        let segmentNameByID = Dictionary(uniqueKeysWithValues: networkSegments.map { ($0.id, $0.name) })
        let consumerNameByID = Dictionary(uniqueKeysWithValues: state.consumers.map { ($0.id.uuidString, $0.displayName) })
        let resultByID = Dictionary(uniqueKeysWithValues: (state.result?.segments ?? []).map { ($0.id, $0) })

        let segmentRows = networkSegments.map { segment -> Segment in
            let result = resultByID[segment.id.uuidString]
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
                note: segment.note
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
            notice: "Technische Netzbaum-Dokumentation. Segment-Q werden ausschließlich aus den aktuell zugeordneten Heizflächen-Zielvolumenströmen summiert. Veraltete verknüpfte Rohrabschnitte blockieren den vollständigen hydraulischen Betriebspunkt, bis die berechneten Netz-Q erneut angewendet wurden. Kein Verfahren-B-/GEG-/BEG-Nachweis."
        )
    }
}
