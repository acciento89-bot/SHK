import XCTest
@testable import SHKCore

final class HeizBalanceHydraulicNetworkScaleTests: XCTestCase {
    func testFiftyConsumerTreeAggregatesDeterministically() throws {
        let fixture = makeFixture()

        let result = try XCTUnwrap(
            HeizBalanceHydraulicNetworkCalculator.calculate(
                .init(consumers: fixture.consumers, segments: fixture.segments)
            )
        )

        XCTAssertEqual(result.consumerCount, 50)
        XCTAssertEqual(result.assignedConsumerCount, 50)
        XCTAssertTrue(result.allConsumersAssigned)
        XCTAssertEqual(try XCTUnwrap(result.designTotalConsumerFlowLPH), 5_000, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result.segment(id: "root")?.designVolumeFlowLPH), 5_000, accuracy: 0.000001)

        for floorIndex in 0..<5 {
            XCTAssertEqual(
                try XCTUnwrap(result.segment(id: "floor-\(floorIndex)")?.designVolumeFlowLPH),
                1_000,
                accuracy: 0.000001
            )
            for branchIndex in 0..<2 {
                XCTAssertEqual(
                    try XCTUnwrap(result.segment(id: "floor-\(floorIndex)-branch-\(branchIndex)")?.designVolumeFlowLPH),
                    500,
                    accuracy: 0.000001
                )
            }
        }

        let repeated = try XCTUnwrap(
            HeizBalanceHydraulicNetworkCalculator.calculate(
                .init(consumers: fixture.consumers, segments: fixture.segments)
            )
        )
        XCTAssertEqual(result, repeated)
    }

    func testFiftyConsumerSharedPathsStayIndependentAndComplete() throws {
        let fixture = makeFixture()
        let network = try XCTUnwrap(
            HeizBalanceHydraulicNetworkCalculator.calculate(
                .init(consumers: fixture.consumers, segments: fixture.segments)
            )
        )

        let pathSegments = fixture.segments.map { segment in
            let flow = network.segment(id: segment.id)?.designVolumeFlowLPH
            let level: Int
            if segment.id == "root" {
                level = 0
            } else if segment.id.contains("branch") {
                level = 2
            } else {
                level = 1
            }

            let diameterMM: Double = switch level {
            case 0: 32
            case 1: 25
            default: 20
            }
            let lengthM: Double = switch level {
            case 0: 18
            case 1: 12
            default: 9
            }
            let componentLossKPa: Double = switch level {
            case 0: 2
            case 1: 1.5
            default: 0.75
            }

            return HeizBalanceHydraulicNetworkPathCalculator.SegmentInput(
                id: segment.id,
                name: segment.name,
                parentSegmentID: segment.parentSegmentID,
                designVolumeFlowLPH: flow,
                pipeSections: [
                    .init(
                        id: "pipe-\(segment.id)",
                        name: "Shared \(segment.name)",
                        innerDiameterMM: diameterMM,
                        lengthM: lengthM,
                        roughnessMM: 0.007,
                        zetaTotal: 2
                    )
                ],
                components: [
                    .init(
                        id: "component-\(segment.id)",
                        name: "Expliziter Verlust",
                        pressureLossKPa: componentLossKPa
                    )
                ],
                componentAssessmentComplete: true
            )
        }

        let pathConsumers = fixture.consumers.enumerated().map { index, consumer in
            HeizBalanceHydraulicNetworkPathCalculator.ConsumerInput(
                id: consumer.id,
                name: consumer.name,
                assignedSegmentID: fixture.directSegmentByConsumerID[consumer.id],
                terminalCompletePressureLossKPa: 4 + Double(index % 3),
                terminalKnownPressureLossKPa: 4 + Double(index % 3)
            )
        }

        let result = try XCTUnwrap(
            HeizBalanceHydraulicNetworkPathCalculator.calculate(
                .init(
                    densityKGPerM3: 998,
                    kinematicViscosityM2S: 1.004e-6,
                    segments: pathSegments,
                    consumers: pathConsumers
                )
            )
        )

        XCTAssertEqual(result.segments.count, 16)
        XCTAssertEqual(result.consumers.count, 50)

        for consumer in result.consumers {
            XCTAssertEqual(consumer.pathSegmentIDs.count, 3)
            XCTAssertEqual(consumer.pathSegmentIDs.first, "root")
            XCTAssertTrue(consumer.pathCoverageComplete)
            XCTAssertNotNil(consumer.completePathPressureLossKPa)
            XCTAssertGreaterThan(consumer.knownSharedPressureLossKPa, 0)
            XCTAssertGreaterThan(consumer.knownPathPressureLossKPa, consumer.terminalKnownPressureLossKPa)
        }

        let repeated = try XCTUnwrap(
            HeizBalanceHydraulicNetworkPathCalculator.calculate(
                .init(
                    densityKGPerM3: 998,
                    kinematicViscosityM2S: 1.004e-6,
                    segments: pathSegments,
                    consumers: pathConsumers
                )
            )
        )
        XCTAssertEqual(result, repeated)
    }

    private func makeFixture() -> (
        consumers: [HeizBalanceHydraulicNetworkCalculator.ConsumerInput],
        segments: [HeizBalanceHydraulicNetworkCalculator.SegmentInput],
        directSegmentByConsumerID: [String: String]
    ) {
        var consumers: [HeizBalanceHydraulicNetworkCalculator.ConsumerInput] = []
        var segments: [HeizBalanceHydraulicNetworkCalculator.SegmentInput] = [
            .init(id: "root", name: "Hauptstrang", parentSegmentID: nil, directConsumerIDs: [])
        ]
        var directSegmentByConsumerID: [String: String] = [:]

        for floorIndex in 0..<5 {
            let floorID = "floor-\(floorIndex)"
            segments.append(
                .init(id: floorID, name: "Etage \(floorIndex + 1)", parentSegmentID: "root", directConsumerIDs: [])
            )

            for branchIndex in 0..<2 {
                let branchID = "floor-\(floorIndex)-branch-\(branchIndex)"
                let firstConsumer = floorIndex * 10 + branchIndex * 5
                let ids = (firstConsumer..<(firstConsumer + 5)).map { "consumer-\($0)" }

                for (offset, id) in ids.enumerated() {
                    let flow = 80.0 + Double(offset) * 10.0
                    consumers.append(
                        .init(id: id, name: "Verbraucher \(firstConsumer + offset + 1)", targetVolumeFlowLPH: flow)
                    )
                    directSegmentByConsumerID[id] = branchID
                }

                segments.append(
                    .init(
                        id: branchID,
                        name: "Teilstrang \(floorIndex + 1).\(branchIndex + 1)",
                        parentSegmentID: floorID,
                        directConsumerIDs: ids
                    )
                )
            }
        }

        return (consumers, segments, directSegmentByConsumerID)
    }
}
