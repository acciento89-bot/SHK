import XCTest
@testable import SHKCore

final class HeizBalanceHydraulicNetworkTests: XCTestCase {
    func testTreeAggregatesDownstreamConsumerFlows() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydraulicNetworkCalculator.calculate(
                .init(
                    consumers: [
                        .init(id: "living", name: "Wohnzimmer", targetVolumeFlowLPH: 100),
                        .init(id: "bath", name: "Bad", targetVolumeFlowLPH: 150),
                        .init(id: "bed", name: "Schlafzimmer", targetVolumeFlowLPH: 200)
                    ],
                    segments: [
                        .init(id: "main", name: "Hauptstrang", parentSegmentID: nil, directConsumerIDs: []),
                        .init(id: "ground", name: "EG", parentSegmentID: "main", directConsumerIDs: ["living", "bath"]),
                        .init(id: "upper", name: "OG", parentSegmentID: "main", directConsumerIDs: ["bed"])
                    ]
                )
            )
        )

        XCTAssertTrue(result.allConsumersAssigned)
        XCTAssertEqual(try XCTUnwrap(result.designTotalConsumerFlowLPH), 450, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result.segment(id: "ground")?.designVolumeFlowLPH), 250, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result.segment(id: "upper")?.designVolumeFlowLPH), 200, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result.segment(id: "main")?.designVolumeFlowLPH), 450, accuracy: 0.000001)
    }

    func testMissingTerminalFlowKeepsKnownSubtotalButBlocksDesignFlowUpstream() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydraulicNetworkCalculator.calculate(
                .init(
                    consumers: [
                        .init(id: "a", name: "A", targetVolumeFlowLPH: 100),
                        .init(id: "b", name: "B", targetVolumeFlowLPH: nil)
                    ],
                    segments: [
                        .init(id: "main", name: "Hauptstrang", parentSegmentID: nil, directConsumerIDs: ["a", "b"])
                    ]
                )
            )
        )

        let main = try XCTUnwrap(result.segment(id: "main"))
        XCTAssertEqual(main.knownVolumeFlowLPH, 100, accuracy: 0.000001)
        XCTAssertNil(main.designVolumeFlowLPH)
        XCTAssertFalse(main.flowCoverageComplete)
        XCTAssertEqual(main.unresolvedConsumerIDs, ["b"])
        XCTAssertNil(result.designTotalConsumerFlowLPH)
    }

    func testRejectsDuplicateConsumerAssignment() {
        XCTAssertNil(
            HeizBalanceHydraulicNetworkCalculator.calculate(
                .init(
                    consumers: [.init(id: "a", name: "A", targetVolumeFlowLPH: 100)],
                    segments: [
                        .init(id: "one", name: "One", parentSegmentID: nil, directConsumerIDs: ["a"]),
                        .init(id: "two", name: "Two", parentSegmentID: nil, directConsumerIDs: ["a"])
                    ]
                )
            )
        )
    }

    func testRejectsCyclesAndUnknownParents() {
        XCTAssertNil(
            HeizBalanceHydraulicNetworkCalculator.calculate(
                .init(
                    consumers: [],
                    segments: [
                        .init(id: "a", name: "A", parentSegmentID: "b", directConsumerIDs: []),
                        .init(id: "b", name: "B", parentSegmentID: "a", directConsumerIDs: [])
                    ]
                )
            )
        )
        XCTAssertNil(
            HeizBalanceHydraulicNetworkCalculator.calculate(
                .init(
                    consumers: [],
                    segments: [.init(id: "a", name: "A", parentSegmentID: "missing", directConsumerIDs: [])]
                )
            )
        )
    }

    func testUnassignedConsumersAreVisibleWithoutInvalidatingTree() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydraulicNetworkCalculator.calculate(
                .init(
                    consumers: [
                        .init(id: "a", name: "A", targetVolumeFlowLPH: 100),
                        .init(id: "b", name: "B", targetVolumeFlowLPH: 120)
                    ],
                    segments: [.init(id: "main", name: "Main", parentSegmentID: nil, directConsumerIDs: ["a"])]
                )
            )
        )

        XCTAssertFalse(result.allConsumersAssigned)
        XCTAssertEqual(result.assignedConsumerCount, 1)
        XCTAssertEqual(try XCTUnwrap(result.segment(id: "main")?.designVolumeFlowLPH), 100, accuracy: 0.000001)
    }
}
