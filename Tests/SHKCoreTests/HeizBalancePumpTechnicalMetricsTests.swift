import XCTest
@testable import SHKCore

final class HeizBalancePumpTechnicalMetricsTests: XCTestCase {
    func testCalculatesHydraulicDemandReserveAndDocumentedFlowPosition() throws {
        let result = try XCTUnwrap(
            HeizBalancePumpTechnicalMetricsCalculator.calculate(
                .init(
                    volumeFlowM3H: 1.5,
                    requiredHeadM: 3.2,
                    availableHeadM: 4.0,
                    fluidDensityKGPerM3: 998,
                    electricalInputPowerW: 34,
                    documentedMinimumFlowM3H: 0,
                    documentedMaximumFlowM3H: 2.0
                )
            )
        )

        XCTAssertEqual(result.requiredHydraulicPowerW, 13.05, accuracy: 0.02)
        XCTAssertEqual(result.availableHydraulicPowerW, 16.31, accuracy: 0.02)
        XCTAssertEqual(result.headReserveM, 0.8, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result.headReservePercent), 25, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result.requiredHydraulicToElectricalRatio), 0.3839, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(result.documentedFlowPosition), 0.75, accuracy: 0.000001)
    }

    func testElectricalRatioRemainsUnavailableWithoutDocumentedElectricalInput() throws {
        let result = try XCTUnwrap(
            HeizBalancePumpTechnicalMetricsCalculator.calculate(
                .init(
                    volumeFlowM3H: 0.8,
                    requiredHeadM: 2.5,
                    availableHeadM: 2.8,
                    fluidDensityKGPerM3: 1_000,
                    electricalInputPowerW: nil,
                    documentedMinimumFlowM3H: nil,
                    documentedMaximumFlowM3H: nil
                )
            )
        )

        XCTAssertNil(result.requiredHydraulicToElectricalRatio)
        XCTAssertNil(result.documentedFlowPosition)
        XCTAssertGreaterThan(result.requiredHydraulicPowerW, 0)
    }

    func testRejectsInvalidFluidOrElectricalInputs() {
        XCTAssertNil(
            HeizBalancePumpTechnicalMetricsCalculator.calculate(
                .init(
                    volumeFlowM3H: 1.0,
                    requiredHeadM: 2.0,
                    availableHeadM: 3.0,
                    fluidDensityKGPerM3: 0,
                    electricalInputPowerW: 30,
                    documentedMinimumFlowM3H: 0,
                    documentedMaximumFlowM3H: 2
                )
            )
        )

        XCTAssertNil(
            HeizBalancePumpTechnicalMetricsCalculator.calculate(
                .init(
                    volumeFlowM3H: 1.0,
                    requiredHeadM: 2.0,
                    availableHeadM: 3.0,
                    fluidDensityKGPerM3: 1_000,
                    electricalInputPowerW: -5,
                    documentedMinimumFlowM3H: 0,
                    documentedMaximumFlowM3H: 2
                )
            )
        )
    }
}
