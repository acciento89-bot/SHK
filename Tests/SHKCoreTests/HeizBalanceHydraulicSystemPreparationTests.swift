import XCTest
@testable import SHKCore

final class HeizBalanceHydraulicSystemPreparationTests: XCTestCase {
    func testCompleteParallelSystemUsesSummedFlowAndWorstCircuitPressure() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydraulicSystemPreparationCalculator.calculate(
                .init(
                    circuits: [
                        .init(id: "a", name: "Wohnzimmer", targetVolumeFlowLPH: 100, completePressureLossKPa: 15),
                        .init(id: "b", name: "Bad", targetVolumeFlowLPH: 150, completePressureLossKPa: 22),
                        .init(id: "c", name: "Schlafzimmer", targetVolumeFlowLPH: 200, completePressureLossKPa: 18)
                    ],
                    densityKGPerM3: 980
                )
            )
        )

        XCTAssertTrue(result.flowCoverageComplete)
        XCTAssertTrue(result.pressureCoverageComplete)
        XCTAssertTrue(result.pumpOperatingPointReady)
        XCTAssertEqual(try XCTUnwrap(result.designTotalVolumeFlowLPH), 450, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result.designNetworkPressureLossKPa), 22, accuracy: 0.000001)
        XCTAssertEqual(result.designUnfavorableCircuit?.id, "b")
        XCTAssertNotNil(result.designNetworkHeadMeters)
    }

    func testIncompletePressureCoverageDoesNotReleasePumpPressure() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydraulicSystemPreparationCalculator.calculate(
                .init(
                    circuits: [
                        .init(id: "a", name: "A", targetVolumeFlowLPH: 100, completePressureLossKPa: 15),
                        .init(id: "b", name: "B", targetVolumeFlowLPH: 150, completePressureLossKPa: nil)
                    ],
                    densityKGPerM3: 1000
                )
            )
        )

        XCTAssertTrue(result.flowCoverageComplete)
        XCTAssertFalse(result.pressureCoverageComplete)
        XCTAssertFalse(result.pumpOperatingPointReady)
        XCTAssertEqual(result.highestKnownPressureCircuit?.id, "a")
        XCTAssertNil(result.designNetworkPressureLossKPa)
        XCTAssertNil(result.designUnfavorableCircuit)
    }

    func testIncompleteFlowCoverageDoesNotReleaseDesignTotalFlow() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydraulicSystemPreparationCalculator.calculate(
                .init(
                    circuits: [
                        .init(id: "a", name: "A", targetVolumeFlowLPH: 100, completePressureLossKPa: 10),
                        .init(id: "b", name: "B", targetVolumeFlowLPH: nil, completePressureLossKPa: 12)
                    ],
                    densityKGPerM3: 1000
                )
            )
        )

        XCTAssertFalse(result.flowCoverageComplete)
        XCTAssertTrue(result.pressureCoverageComplete)
        XCTAssertEqual(result.knownTotalVolumeFlowLPH, 100, accuracy: 0.000001)
        XCTAssertNil(result.designTotalVolumeFlowLPH)
        XCTAssertFalse(result.pumpOperatingPointReady)
    }

    func testRejectsInvalidExplicitCircuitValues() {
        XCTAssertNil(
            HeizBalanceHydraulicSystemPreparationCalculator.calculate(
                .init(
                    circuits: [.init(id: "a", name: "A", targetVolumeFlowLPH: -1, completePressureLossKPa: 10)],
                    densityKGPerM3: 1000
                )
            )
        )
        XCTAssertNil(
            HeizBalanceHydraulicSystemPreparationCalculator.calculate(
                .init(
                    circuits: [.init(id: "a", name: "A", targetVolumeFlowLPH: 100, completePressureLossKPa: -1)],
                    densityKGPerM3: 1000
                )
            )
        )
    }
}
