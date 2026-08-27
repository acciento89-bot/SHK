import XCTest
@testable import SHKCore

final class HeizBalanceHydraulicNetworkComponentPathTests: XCTestCase {
    func testSharedComponentsAreAddedOnceInSeries() throws {
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
                            designVolumeFlowLPH: 100,
                            pipeSections: [],
                            components: [
                                .init(id: "filter", name: "Filter", pressureLossKPa: 2),
                                .init(id: "meter", name: "WMZ", pressureLossKPa: 3)
                            ],
                            componentAssessmentComplete: true
                        )
                    ],
                    consumers: [
                        .init(
                            id: "radiator",
                            name: "Heizkörper",
                            assignedSegmentID: "root",
                            terminalCompletePressureLossKPa: 4,
                            terminalKnownPressureLossKPa: 4
                        )
                    ]
                )
            )
        )

        let segment = try XCTUnwrap(result.segment(id: "root"))
        let consumer = try XCTUnwrap(result.consumer(id: "radiator"))

        XCTAssertEqual(segment.knownPipePressureLossKPa, 0, accuracy: 0.000001)
        XCTAssertEqual(segment.knownComponentPressureLossKPa, 5, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(segment.completePressureLossKPa), 5, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(consumer.completePathPressureLossKPa), 9, accuracy: 0.000001)
    }

    func testMissingSharedComponentLossBlocksCompletePathButKeepsKnownSubtotal() throws {
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
                            designVolumeFlowLPH: 100,
                            pipeSections: [],
                            components: [
                                .init(id: "known", name: "Bekannt", pressureLossKPa: 1.2),
                                .init(id: "open", name: "Offen", pressureLossKPa: nil)
                            ],
                            componentAssessmentComplete: true
                        )
                    ],
                    consumers: [
                        .init(
                            id: "radiator",
                            name: "Heizkörper",
                            assignedSegmentID: "root",
                            terminalCompletePressureLossKPa: 4,
                            terminalKnownPressureLossKPa: 4
                        )
                    ]
                )
            )
        )

        let segment = try XCTUnwrap(result.segment(id: "root"))
        let consumer = try XCTUnwrap(result.consumer(id: "radiator"))

        XCTAssertEqual(segment.missingComponentCount, 1)
        XCTAssertEqual(segment.knownComponentPressureLossKPa, 1.2, accuracy: 0.000001)
        XCTAssertNil(segment.completePressureLossKPa)
        XCTAssertEqual(consumer.knownPathPressureLossKPa, 5.2, accuracy: 0.000001)
        XCTAssertNil(consumer.completePathPressureLossKPa)
    }

    func testUnconfirmedSharedComponentAssessmentBlocksCompletePath() throws {
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
                            designVolumeFlowLPH: 100,
                            pipeSections: [],
                            components: [
                                .init(id: "filter", name: "Filter", pressureLossKPa: 2)
                            ],
                            componentAssessmentComplete: false
                        )
                    ],
                    consumers: [
                        .init(
                            id: "radiator",
                            name: "Heizkörper",
                            assignedSegmentID: "root",
                            terminalCompletePressureLossKPa: 4,
                            terminalKnownPressureLossKPa: 4
                        )
                    ]
                )
            )
        )

        let segment = try XCTUnwrap(result.segment(id: "root"))
        XCTAssertFalse(segment.componentCoverageComplete)
        XCTAssertNil(segment.completePressureLossKPa)
        XCTAssertNil(result.consumer(id: "radiator")?.completePathPressureLossKPa)
    }
}
