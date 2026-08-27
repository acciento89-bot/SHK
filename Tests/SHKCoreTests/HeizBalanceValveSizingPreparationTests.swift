import XCTest
@testable import SHKCore

final class HeizBalanceValveSizingPreparationTests: XCTestCase {
    func testDanfossWaterExampleProducesExpectedKv() throws {
        let result = try XCTUnwrap(
            HeizBalanceValveSizingPreparationCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: 600,
                    valvePressureDropKPa: 12,
                    densityKGPerM3: 1000
                )
            )
        )

        XCTAssertEqual(result.targetVolumeFlowM3H, 0.6, accuracy: 0.000001)
        XCTAssertEqual(result.valvePressureDropBar, 0.12, accuracy: 0.000001)
        XCTAssertEqual(result.relativeDensity, 1.0, accuracy: 0.000001)
        XCTAssertEqual(result.requiredKvM3H, 1.7320508076, accuracy: 0.000001)
    }

    func testDensityCorrectionIsAppliedForLiquid() throws {
        let result = try XCTUnwrap(
            HeizBalanceValveSizingPreparationCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: 100,
                    valvePressureDropKPa: 10,
                    densityKGPerM3: 980
                )
            )
        )

        XCTAssertEqual(result.requiredKvM3H, 0.3130495168, accuracy: 0.000001)
    }

    func testRejectsInvalidInput() {
        XCTAssertNil(
            HeizBalanceValveSizingPreparationCalculator.calculate(
                .init(targetVolumeFlowLPH: 0, valvePressureDropKPa: 10, densityKGPerM3: 1000)
            )
        )
        XCTAssertNil(
            HeizBalanceValveSizingPreparationCalculator.calculate(
                .init(targetVolumeFlowLPH: 100, valvePressureDropKPa: 0, densityKGPerM3: 1000)
            )
        )
        XCTAssertNil(
            HeizBalanceValveSizingPreparationCalculator.calculate(
                .init(targetVolumeFlowLPH: 100, valvePressureDropKPa: 10, densityKGPerM3: 0)
            )
        )
    }
}
