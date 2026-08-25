import XCTest
@testable import SHKCore

final class HeizBalancePumpCurveOperatingPointTests: XCTestCase {
    func testExactDocumentedPointIsUsedWithoutInterpolation() throws {
        let result = try XCTUnwrap(
            HeizBalancePumpCurveOperatingPointCalculator.calculate(
                .init(
                    targetVolumeFlowM3H: 1.0,
                    requiredHeadM: 3.0,
                    points: [
                        .init(id: "p0", volumeFlowM3H: 0.0, headM: 5.0, electricalInputPowerW: 20),
                        .init(id: "p1", volumeFlowM3H: 1.0, headM: 4.0, electricalInputPowerW: 28),
                        .init(id: "p2", volumeFlowM3H: 2.0, headM: 2.0, electricalInputPowerW: 40)
                    ]
                )
            )
        )

        XCTAssertTrue(result.exactDocumentedPoint)
        XCTAssertEqual(result.lowerPointID, "p1")
        XCTAssertEqual(result.upperPointID, "p1")
        XCTAssertEqual(result.availableHeadM, 4.0, accuracy: 0.000001)
        XCTAssertEqual(result.headReserveM, 1.0, accuracy: 0.000001)
        XCTAssertTrue(result.technicallySufficient)
        XCTAssertEqual(try XCTUnwrap(result.interpolatedElectricalInputPowerW), 28, accuracy: 0.000001)
    }

    func testInterpolatesOnlyBetweenDocumentedPoints() throws {
        let result = try XCTUnwrap(
            HeizBalancePumpCurveOperatingPointCalculator.calculate(
                .init(
                    targetVolumeFlowM3H: 1.5,
                    requiredHeadM: 3.2,
                    points: [
                        .init(id: "p2", volumeFlowM3H: 2.0, headM: 2.0, electricalInputPowerW: 40),
                        .init(id: "p0", volumeFlowM3H: 0.0, headM: 5.0, electricalInputPowerW: 20),
                        .init(id: "p1", volumeFlowM3H: 1.0, headM: 4.0, electricalInputPowerW: 28)
                    ]
                )
            )
        )

        XCTAssertFalse(result.exactDocumentedPoint)
        XCTAssertEqual(result.lowerPointID, "p1")
        XCTAssertEqual(result.upperPointID, "p2")
        XCTAssertEqual(result.availableHeadM, 3.0, accuracy: 0.000001)
        XCTAssertEqual(result.headReserveM, -0.2, accuracy: 0.000001)
        XCTAssertFalse(result.technicallySufficient)
        XCTAssertEqual(try XCTUnwrap(result.interpolatedElectricalInputPowerW), 34, accuracy: 0.000001)
    }

    func testDoesNotExtrapolateBelowOrAboveDocumentedRange() {
        let points = [
            HeizBalancePumpProductDataset.CurvePoint(id: "p1", volumeFlowM3H: 0.5, headM: 5.0, electricalInputPowerW: nil),
            HeizBalancePumpProductDataset.CurvePoint(id: "p2", volumeFlowM3H: 1.5, headM: 3.0, electricalInputPowerW: nil)
        ]

        XCTAssertNil(
            HeizBalancePumpCurveOperatingPointCalculator.calculate(
                .init(targetVolumeFlowM3H: 0.4, requiredHeadM: 2.0, points: points)
            )
        )
        XCTAssertNil(
            HeizBalancePumpCurveOperatingPointCalculator.calculate(
                .init(targetVolumeFlowM3H: 1.6, requiredHeadM: 2.0, points: points)
            )
        )
    }

    func testElectricalPowerIsOnlyInterpolatedWhenBothBracketPointsContainIt() throws {
        let result = try XCTUnwrap(
            HeizBalancePumpCurveOperatingPointCalculator.calculate(
                .init(
                    targetVolumeFlowM3H: 1.0,
                    requiredHeadM: 2.0,
                    points: [
                        .init(id: "p1", volumeFlowM3H: 0.5, headM: 4.0, electricalInputPowerW: 25),
                        .init(id: "p2", volumeFlowM3H: 1.5, headM: 3.0, electricalInputPowerW: nil)
                    ]
                )
            )
        )

        XCTAssertNil(result.interpolatedElectricalInputPowerW)
        XCTAssertEqual(result.availableHeadM, 3.5, accuracy: 0.000001)
    }

    func testRejectsDuplicateFlowPointsAndInvalidInputs() {
        let duplicate = [
            HeizBalancePumpProductDataset.CurvePoint(id: "a", volumeFlowM3H: 1.0, headM: 4.0, electricalInputPowerW: nil),
            HeizBalancePumpProductDataset.CurvePoint(id: "b", volumeFlowM3H: 1.0, headM: 3.0, electricalInputPowerW: nil)
        ]

        XCTAssertNil(
            HeizBalancePumpCurveOperatingPointCalculator.calculate(
                .init(targetVolumeFlowM3H: 1.0, requiredHeadM: 2.0, points: duplicate)
            )
        )
        XCTAssertNil(
            HeizBalancePumpCurveOperatingPointCalculator.calculate(
                .init(targetVolumeFlowM3H: -1.0, requiredHeadM: 2.0, points: duplicate)
            )
        )
    }
}
