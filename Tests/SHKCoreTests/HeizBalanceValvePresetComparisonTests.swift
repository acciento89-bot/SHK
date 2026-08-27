import XCTest
@testable import SHKCore

final class HeizBalanceValvePresetComparisonTests: XCTestCase {
    func testReturnsBracketingAndNearestDataPoints() throws {
        let result = try XCTUnwrap(
            HeizBalanceValvePresetComparisonCalculator.calculate(
                .init(
                    requiredKvM3H: 0.65,
                    points: [
                        .init(setting: "1", kvM3H: 0.50),
                        .init(setting: "2", kvM3H: 0.70),
                        .init(setting: "3", kvM3H: 0.90)
                    ]
                )
            )
        )

        XCTAssertEqual(result.lowerPoint?.setting, "1")
        XCTAssertEqual(result.upperPoint?.setting, "2")
        XCTAssertEqual(result.nearestPoint.setting, "2")
        XCTAssertEqual(result.nearestPoint.kvM3H, 0.70, accuracy: 0.000001)
        XCTAssertEqual(result.absoluteDeviationKvM3H, 0.05, accuracy: 0.000001)
        XCTAssertEqual(result.relativeDeviation, 0.05 / 0.65, accuracy: 0.000001)
        XCTAssertTrue(result.requiredKvInsideDataRange)
        XCTAssertFalse(result.exactMatch)
    }

    func testRecognizesExactDataPoint() throws {
        let result = try XCTUnwrap(
            HeizBalanceValvePresetComparisonCalculator.calculate(
                .init(
                    requiredKvM3H: 0.70,
                    points: [
                        .init(setting: "1", kvM3H: 0.50),
                        .init(setting: "2", kvM3H: 0.70)
                    ]
                )
            )
        )

        XCTAssertTrue(result.exactMatch)
        XCTAssertEqual(result.lowerPoint?.setting, "2")
        XCTAssertEqual(result.upperPoint?.setting, "2")
        XCTAssertEqual(result.nearestPoint.setting, "2")
    }

    func testKeepsOutOfRangeRequirementVisible() throws {
        let result = try XCTUnwrap(
            HeizBalanceValvePresetComparisonCalculator.calculate(
                .init(
                    requiredKvM3H: 1.10,
                    points: [
                        .init(setting: "1", kvM3H: 0.50),
                        .init(setting: "2", kvM3H: 0.90)
                    ]
                )
            )
        )

        XCTAssertFalse(result.requiredKvInsideDataRange)
        XCTAssertEqual(result.lowerPoint?.setting, "2")
        XCTAssertNil(result.upperPoint)
        XCTAssertEqual(result.nearestPoint.setting, "2")
        XCTAssertEqual(result.maximumKvM3H, 0.90, accuracy: 0.000001)
    }

    func testRejectsInvalidOrAmbiguousData() {
        XCTAssertNil(
            HeizBalanceValvePresetComparisonCalculator.calculate(
                .init(requiredKvM3H: 0, points: [.init(setting: "1", kvM3H: 0.5)])
            )
        )

        XCTAssertNil(
            HeizBalanceValvePresetComparisonCalculator.calculate(
                .init(requiredKvM3H: 0.5, points: [.init(setting: "", kvM3H: 0.5)])
            )
        )

        XCTAssertNil(
            HeizBalanceValvePresetComparisonCalculator.calculate(
                .init(
                    requiredKvM3H: 0.5,
                    points: [
                        .init(setting: "2", kvM3H: 0.5),
                        .init(setting: " 2 ", kvM3H: 0.7)
                    ]
                )
            )
        )
    }
}
