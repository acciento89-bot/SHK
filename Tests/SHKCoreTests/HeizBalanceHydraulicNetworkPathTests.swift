import XCTest
@testable import SHKCore

final class HeizBalanceHydraulicNetworkPathTests: XCTestCase {
    func testSharedSegmentsAreCountedOncePerConsumerPath() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydraulicNetworkPathCalculator.calculate(
                .init(
                    densityKGPerM3: 1000,
                    kinematicViscosityM2S: 1e-6,
                    segments: [
                        .init(
                            id: "root",
                            name: "Hauptstrang",
                            parentSegmentID: nil,
                            designVolumeFlowLPH: 450,
                            pipeSections: [
                                .init(id: "r1", name: "Keller", innerDiameterMM: 20, lengthM: 10, roughnessMM: 0.01, zetaTotal: 2)
                            ]
                        ),
                        .init(
                            id: "eg",
                            name: "EG",
                            parentSegmentID: "root",
                            designVolumeFlowLPH: 250,
                            pipeSections: [
                                .init(id: "e1", name: "EG-Strang", innerDiameterMM: 16, lengthM: 8, roughnessMM: 0.01, zetaTotal: 1)
                            ]
                        ),
                        .init(
                            id: "og",
                            name: "OG",
                            parentSegmentID: "root",
                            designVolumeFlowLPH: 200,
                            pipeSections: [
                                .init(id: "o1", name: "OG-Strang", innerDiameterMM: 16, lengthM: 9, roughnessMM: 0.01, zetaTotal: 1)
                            ]
                        )
                    ],
                    consumers: [
                        .init(id: "living", name: "Wohnzimmer", assignedSegmentID: "eg", terminalCompletePressureLossKPa: 5, terminalKnownPressureLossKPa: 5),
                        .init(id: "bed", name: "Schlafzimmer", assignedSegmentID: "og", terminalCompletePressureLossKPa: 6, terminalKnownPressureLossKPa: 6)
                    ]
                )
            )
        )

        let root = try XCTUnwrap(result.segment(id: "root"))
        let eg = try XCTUnwrap(result.segment(id: "eg"))
        let living = try XCTUnwrap(result.consumer(id: "living"))
        let bed = try XCTUnwrap(result.consumer(id: "bed"))
        let rootLoss = try XCTUnwrap(root.completePressureLossKPa)
        let egLoss = try XCTUnwrap(eg.completePressureLossKPa)
        let livingLoss = try XCTUnwrap(living.completePathPressureLossKPa)
        let bedLoss = try XCTUnwrap(bed.completePathPressureLossKPa)

        XCTAssertEqual(living.pathSegmentIDs, ["root", "eg"])
        XCTAssertEqual(bed.pathSegmentIDs, ["root", "og"])
        XCTAssertEqual(livingLoss, rootLoss + egLoss + 5, accuracy: 0.000001)
        XCTAssertGreaterThan(livingLoss, 5)
        XCTAssertGreaterThan(bedLoss, 6)
    }

    func testMissingZetaBlocksCompletePathButKeepsKnownStraightLoss() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydraulicNetworkPathCalculator.calculate(
                .init(
                    densityKGPerM3: 1000,
                    kinematicViscosityM2S: 1e-6,
                    segments: [
                        .init(
                            id: "root",
                            name: "Hauptstrang",
                            parentSegmentID: nil,
                            designVolumeFlowLPH: 200,
                            pipeSections: [
                                .init(id: "r1", name: "Rohr", innerDiameterMM: 16, lengthM: 10, roughnessMM: 0.01, zetaTotal: nil)
                            ]
                        )
                    ],
                    consumers: [
                        .init(id: "a", name: "A", assignedSegmentID: "root", terminalCompletePressureLossKPa: 4, terminalKnownPressureLossKPa: 4)
                    ]
                )
            )
        )

        let root = try XCTUnwrap(result.segment(id: "root"))
        let consumer = try XCTUnwrap(result.consumer(id: "a"))
        XCTAssertGreaterThan(root.knownPressureLossKPa, 0)
        XCTAssertNil(root.completePressureLossKPa)
        XCTAssertGreaterThan(consumer.knownPathPressureLossKPa, 4)
        XCTAssertNil(consumer.completePathPressureLossKPa)
        XCTAssertFalse(consumer.pathCoverageComplete)
    }

    func testUnassignedConsumerCannotReceiveCompletePath() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydraulicNetworkPathCalculator.calculate(
                .init(
                    densityKGPerM3: 1000,
                    kinematicViscosityM2S: 1e-6,
                    segments: [
                        .init(id: "root", name: "Root", parentSegmentID: nil, designVolumeFlowLPH: 100, pipeSections: [])
                    ],
                    consumers: [
                        .init(id: "a", name: "A", assignedSegmentID: nil, terminalCompletePressureLossKPa: 4, terminalKnownPressureLossKPa: 4)
                    ]
                )
            )
        )
        XCTAssertNil(result.consumer(id: "a")?.completePathPressureLossKPa)
    }

    func testRejectsCycle() {
        XCTAssertNil(
            HeizBalanceHydraulicNetworkPathCalculator.calculate(
                .init(
                    densityKGPerM3: 1000,
                    kinematicViscosityM2S: 1e-6,
                    segments: [
                        .init(id: "a", name: "A", parentSegmentID: "b", designVolumeFlowLPH: 100, pipeSections: []),
                        .init(id: "b", name: "B", parentSegmentID: "a", designVolumeFlowLPH: 100, pipeSections: [])
                    ],
                    consumers: []
                )
            )
        )
    }
}
