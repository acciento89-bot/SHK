import Foundation

enum HeizBalanceHydraulicNetworkCalculator {
    static let profileVersion = "hydraulic-network-tree-v1"

    struct ConsumerInput: Sendable, Equatable {
        var id: String
        var name: String
        var targetVolumeFlowLPH: Double?
    }

    struct SegmentInput: Sendable, Equatable {
        var id: String
        var name: String
        var parentSegmentID: String?
        var directConsumerIDs: [String]
    }

    struct Input: Sendable, Equatable {
        var consumers: [ConsumerInput]
        var segments: [SegmentInput]
    }

    struct SegmentResult: Sendable, Equatable {
        var id: String
        var name: String
        var parentSegmentID: String?
        var depth: Int
        var directConsumerIDs: [String]
        var downstreamConsumerIDs: [String]
        var knownVolumeFlowLPH: Double
        var designVolumeFlowLPH: Double?
        var flowCoverageComplete: Bool
        var unresolvedConsumerIDs: [String]
    }

    struct Result: Sendable, Equatable {
        var profileVersion: String
        var consumerCount: Int
        var assignedConsumerCount: Int
        var allConsumersAssigned: Bool
        var knownTotalConsumerFlowLPH: Double
        var designTotalConsumerFlowLPH: Double?
        var roots: [String]
        var segments: [SegmentResult]

        func segment(id: String) -> SegmentResult? {
            segments.first { $0.id == id }
        }
    }

    static func calculate(_ input: Input) -> Result? {
        let consumerIDs = input.consumers.map(\.id)
        guard Set(consumerIDs).count == consumerIDs.count else { return nil }
        let segmentIDs = input.segments.map(\.id)
        guard Set(segmentIDs).count == segmentIDs.count else { return nil }

        var consumersByID: [String: ConsumerInput] = [:]
        for consumer in input.consumers {
            if let flow = consumer.targetVolumeFlowLPH,
               (!flow.isFinite || flow <= 0) {
                return nil
            }
            consumersByID[consumer.id] = consumer
        }

        let segmentIDSet = Set(segmentIDs)
        var segmentByID: [String: SegmentInput] = [:]
        var assignedConsumerIDs = Set<String>()

        for segment in input.segments {
            if let parent = segment.parentSegmentID {
                guard parent != segment.id, segmentIDSet.contains(parent) else { return nil }
            }
            guard Set(segment.directConsumerIDs).count == segment.directConsumerIDs.count else { return nil }
            for consumerID in segment.directConsumerIDs {
                guard consumersByID[consumerID] != nil,
                      !assignedConsumerIDs.contains(consumerID) else {
                    return nil
                }
                assignedConsumerIDs.insert(consumerID)
            }
            segmentByID[segment.id] = segment
        }

        var childrenByParent: [String: [String]] = [:]
        for segment in input.segments {
            if let parent = segment.parentSegmentID {
                childrenByParent[parent, default: []].append(segment.id)
            }
        }

        enum VisitState { case visiting, done }
        var visitState: [String: VisitState] = [:]
        var cached: [String: SegmentResult] = [:]

        func evaluate(_ segmentID: String, depth: Int) -> SegmentResult? {
            if case .visiting? = visitState[segmentID] { return nil }
            if let existing = cached[segmentID] { return existing }
            guard let segment = segmentByID[segmentID] else { return nil }

            visitState[segmentID] = .visiting
            var downstream = segment.directConsumerIDs
            var unresolved: [String] = []
            var knownFlow = 0.0

            for consumerID in segment.directConsumerIDs {
                guard let consumer = consumersByID[consumerID] else { return nil }
                if let flow = consumer.targetVolumeFlowLPH {
                    knownFlow += flow
                } else {
                    unresolved.append(consumerID)
                }
            }

            let children = (childrenByParent[segmentID] ?? []).sorted()
            for childID in children {
                guard let child = evaluate(childID, depth: depth + 1) else { return nil }
                downstream.append(contentsOf: child.downstreamConsumerIDs)
                unresolved.append(contentsOf: child.unresolvedConsumerIDs)
                knownFlow += child.knownVolumeFlowLPH
            }

            visitState[segmentID] = .done
            let result = SegmentResult(
                id: segment.id,
                name: segment.name,
                parentSegmentID: segment.parentSegmentID,
                depth: depth,
                directConsumerIDs: segment.directConsumerIDs.sorted(),
                downstreamConsumerIDs: downstream.sorted(),
                knownVolumeFlowLPH: knownFlow,
                designVolumeFlowLPH: unresolved.isEmpty ? knownFlow : nil,
                flowCoverageComplete: unresolved.isEmpty,
                unresolvedConsumerIDs: unresolved.sorted()
            )
            cached[segmentID] = result
            return result
        }

        let roots = input.segments
            .filter { $0.parentSegmentID == nil }
            .map(\.id)
            .sorted()

        for root in roots {
            guard evaluate(root, depth: 0) != nil else { return nil }
        }
        guard cached.count == input.segments.count else { return nil }
        let results = cached.values.sorted {
            if $0.depth == $1.depth { return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return $0.depth < $1.depth
        }

        let knownTotal = input.consumers.compactMap(\.targetVolumeFlowLPH).reduce(0, +)
        let allFlowsKnown = input.consumers.allSatisfy { $0.targetVolumeFlowLPH != nil }
        let allAssigned = assignedConsumerIDs.count == input.consumers.count

        return Result(
            profileVersion: profileVersion,
            consumerCount: input.consumers.count,
            assignedConsumerCount: assignedConsumerIDs.count,
            allConsumersAssigned: allAssigned,
            knownTotalConsumerFlowLPH: knownTotal,
            designTotalConsumerFlowLPH: allFlowsKnown ? knownTotal : nil,
            roots: roots,
            segments: results
        )
    }
}
