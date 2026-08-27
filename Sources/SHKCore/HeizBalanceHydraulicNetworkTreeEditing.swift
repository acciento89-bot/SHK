import Foundation

enum HeizBalanceHydraulicNetworkTreeEditing {
    struct Segment: Sendable, Equatable {
        var id: String
        var parentSegmentID: String?
    }

    static func subtreeIDs(rootID: String, segments: [Segment]) -> [String]? {
        guard validatedSegmentMap(segments) != nil,
              segments.contains(where: { $0.id == rootID }) else {
            return nil
        }

        var childrenByParent: [String: [String]] = [:]
        for segment in segments {
            if let parent = segment.parentSegmentID {
                childrenByParent[parent, default: []].append(segment.id)
            }
        }
        for parent in childrenByParent.keys {
            childrenByParent[parent]?.sort()
        }

        var result: [String] = []
        var stack = [rootID]
        var visited = Set<String>()

        while let current = stack.popLast() {
            guard visited.insert(current).inserted else { return nil }
            result.append(current)
            let children = childrenByParent[current] ?? []
            stack.append(contentsOf: children.reversed())
        }

        return result
    }

    static func canMove(
        rootID: String,
        toParentID parentID: String?,
        segments: [Segment]
    ) -> Bool {
        guard let segmentMap = validatedSegmentMap(segments),
              segmentMap[rootID] != nil else {
            return false
        }

        guard let parentID else { return true }
        guard parentID != rootID,
              segmentMap[parentID] != nil,
              let subtree = subtreeIDs(rootID: rootID, segments: segments) else {
            return false
        }

        return !Set(subtree).contains(parentID)
    }

    static func validParentIDs(rootID: String, segments: [Segment]) -> [String]? {
        guard let subtree = subtreeIDs(rootID: rootID, segments: segments) else { return nil }
        let blocked = Set(subtree)
        return segments
            .map(\.id)
            .filter { !blocked.contains($0) }
            .sorted()
    }

    private static func validatedSegmentMap(_ segments: [Segment]) -> [String: Segment]? {
        let ids = segments.map(\.id)
        guard Set(ids).count == ids.count else { return nil }
        let idSet = Set(ids)

        var map: [String: Segment] = [:]
        for segment in segments {
            if let parent = segment.parentSegmentID {
                guard parent != segment.id, idSet.contains(parent) else { return nil }
            }
            map[segment.id] = segment
        }

        enum VisitState { case visiting, done }
        var states: [String: VisitState] = [:]

        func visit(_ id: String) -> Bool {
            if case .visiting? = states[id] { return false }
            if case .done? = states[id] { return true }
            guard let segment = map[id] else { return false }

            states[id] = .visiting
            if let parent = segment.parentSegmentID,
               !visit(parent) {
                return false
            }
            states[id] = .done
            return true
        }

        for id in ids where !visit(id) {
            return nil
        }
        return map
    }
}
