import Foundation

enum HeizBalanceHydraulicNetworkPathCalculator {
    static let profileVersion = "hydraulic-network-path-v1"

    struct PipeSectionInput: Sendable, Equatable {
        var id: String
        var name: String
        var innerDiameterMM: Double?
        var lengthM: Double?
        var roughnessMM: Double?
        var zetaTotal: Double?
    }

    struct SegmentInput: Sendable, Equatable {
        var id: String
        var name: String
        var parentSegmentID: String?
        var designVolumeFlowLPH: Double?
        var pipeSections: [PipeSectionInput]
    }

    struct ConsumerInput: Sendable, Equatable {
        var id: String
        var name: String
        var assignedSegmentID: String?
        var terminalCompletePressureLossKPa: Double?
        var terminalKnownPressureLossKPa: Double
    }

    struct Input: Sendable, Equatable {
        var densityKGPerM3: Double
        var kinematicViscosityM2S: Double
        var segments: [SegmentInput]
        var consumers: [ConsumerInput]
    }

    struct SegmentResult: Sendable, Equatable {
        var id: String
        var name: String
        var parentSegmentID: String?
        var designVolumeFlowLPH: Double?
        var pipeSectionCount: Int
        var knownPressureLossKPa: Double
        var completePressureLossKPa: Double?
        var pressureCoverageComplete: Bool
    }

    struct ConsumerResult: Sendable, Equatable {
        var id: String
        var name: String
        var assignedSegmentID: String?
        var pathSegmentIDs: [String]
        var knownSharedPressureLossKPa: Double
        var terminalKnownPressureLossKPa: Double
        var knownPathPressureLossKPa: Double
        var completePathPressureLossKPa: Double?
        var pathCoverageComplete: Bool
    }

    struct Result: Sendable, Equatable {
        var profileVersion: String
        var segments: [SegmentResult]
        var consumers: [ConsumerResult]

        func segment(id: String) -> SegmentResult? {
            segments.first { $0.id == id }
        }

        func consumer(id: String) -> ConsumerResult? {
            consumers.first { $0.id == id }
        }
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.densityKGPerM3.isFinite,
              input.densityKGPerM3 > 0,
              input.kinematicViscosityM2S.isFinite,
              input.kinematicViscosityM2S > 0 else {
            return nil
        }

        let segmentIDs = input.segments.map(\.id)
        guard Set(segmentIDs).count == segmentIDs.count else { return nil }
        let segmentIDSet = Set(segmentIDs)

        var segmentsByID: [String: SegmentInput] = [:]
        for segment in input.segments {
            if let parent = segment.parentSegmentID {
                guard parent != segment.id, segmentIDSet.contains(parent) else { return nil }
            }
            if let flow = segment.designVolumeFlowLPH,
               (!flow.isFinite || flow <= 0) {
                return nil
            }
            segmentsByID[segment.id] = segment
        }

        // Reject cycles before any path is evaluated.
        for segment in input.segments {
            var visited = Set<String>()
            var current: String? = segment.id
            while let id = current {
                guard visited.insert(id).inserted else { return nil }
                current = segmentsByID[id]?.parentSegmentID
            }
        }

        var segmentResults: [SegmentResult] = []
        var segmentResultByID: [String: SegmentResult] = [:]

        for segment in input.segments {
            var knownLoss = 0.0
            var complete = true

            if !segment.pipeSections.isEmpty, segment.designVolumeFlowLPH == nil {
                complete = false
            }

            for section in segment.pipeSections {
                guard let diameter = section.innerDiameterMM,
                      let length = section.lengthM,
                      let roughness = section.roughnessMM,
                      diameter.isFinite, diameter > 0,
                      length.isFinite, length >= 0,
                      roughness.isFinite, roughness >= 0,
                      let flow = segment.designVolumeFlowLPH else {
                    complete = false
                    continue
                }

                if let zeta = section.zetaTotal,
                   (!zeta.isFinite || zeta < 0) {
                    return nil
                }

                let hydraulics = PipeCalculator.calculateExtended(
                    volumeFlowLPH: flow,
                    innerDiameterMM: diameter,
                    lengthM: length,
                    roughnessMM: roughness,
                    zetaTotal: section.zetaTotal ?? 0,
                    densityKGPerM3: input.densityKGPerM3,
                    kinematicViscosityM2S: input.kinematicViscosityM2S
                )

                knownLoss += hydraulics.base.totalPressureDropKPa
                if section.zetaTotal != nil {
                    knownLoss += hydraulics.localPressureLossKPa
                } else {
                    complete = false
                }
            }

            let result = SegmentResult(
                id: segment.id,
                name: segment.name,
                parentSegmentID: segment.parentSegmentID,
                designVolumeFlowLPH: segment.designVolumeFlowLPH,
                pipeSectionCount: segment.pipeSections.count,
                knownPressureLossKPa: knownLoss,
                completePressureLossKPa: complete ? knownLoss : nil,
                pressureCoverageComplete: complete
            )
            segmentResults.append(result)
            segmentResultByID[result.id] = result
        }

        var consumerIDs = Set<String>()
        var consumerResults: [ConsumerResult] = []

        for consumer in input.consumers {
            guard consumerIDs.insert(consumer.id).inserted,
                  consumer.terminalKnownPressureLossKPa.isFinite,
                  consumer.terminalKnownPressureLossKPa >= 0 else {
                return nil
            }
            if let completeTerminal = consumer.terminalCompletePressureLossKPa,
               (!completeTerminal.isFinite || completeTerminal < 0) {
                return nil
            }

            guard let assignedID = consumer.assignedSegmentID,
                  segmentsByID[assignedID] != nil else {
                consumerResults.append(
                    ConsumerResult(
                        id: consumer.id,
                        name: consumer.name,
                        assignedSegmentID: consumer.assignedSegmentID,
                        pathSegmentIDs: [],
                        knownSharedPressureLossKPa: 0,
                        terminalKnownPressureLossKPa: consumer.terminalKnownPressureLossKPa,
                        knownPathPressureLossKPa: consumer.terminalKnownPressureLossKPa,
                        completePathPressureLossKPa: nil,
                        pathCoverageComplete: false
                    )
                )
                continue
            }

            var path: [String] = []
            var current: String? = assignedID
            while let id = current {
                path.append(id)
                current = segmentsByID[id]?.parentSegmentID
            }
            path.reverse()

            var knownShared = 0.0
            var sharedComplete = true
            for segmentID in path {
                guard let segmentResult = segmentResultByID[segmentID] else { return nil }
                knownShared += segmentResult.knownPressureLossKPa
                if segmentResult.completePressureLossKPa == nil {
                    sharedComplete = false
                }
            }

            let totalKnown = knownShared + consumer.terminalKnownPressureLossKPa
            let pathComplete = sharedComplete && consumer.terminalCompletePressureLossKPa != nil
            let completeTotal = pathComplete
                ? knownShared + (consumer.terminalCompletePressureLossKPa ?? 0)
                : nil

            consumerResults.append(
                ConsumerResult(
                    id: consumer.id,
                    name: consumer.name,
                    assignedSegmentID: assignedID,
                    pathSegmentIDs: path,
                    knownSharedPressureLossKPa: knownShared,
                    terminalKnownPressureLossKPa: consumer.terminalKnownPressureLossKPa,
                    knownPathPressureLossKPa: totalKnown,
                    completePathPressureLossKPa: completeTotal,
                    pathCoverageComplete: pathComplete
                )
            )
        }

        return Result(
            profileVersion: profileVersion,
            segments: segmentResults.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending },
            consumers: consumerResults.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        )
    }
}
