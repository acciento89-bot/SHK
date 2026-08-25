import XCTest
@testable import SHKCore

final class HeizBalanceCircuitPressureLossSummaryTests: XCTestCase {
    func testCompleteCircuitRequiresCompletePipeAndComponentAssessment() throws {
        let result = try XCTUnwrap(
            HeizBalanceCircuitPressureLossSummaryCalculator.calculate(
                .init(
                    partialPipePressureLossKPa: 8,
                    completePipePressureLossKPa: 8,
                    components: [
                        .init(id: "valve", pressureLossKPa: 12),
                        .init(id: "radiator", pressureLossKPa: 1.5)
                    ],
                    componentAssessmentComplete: true
                )
            )
        )

        XCTAssertEqual(result.knownComponentPressureLossKPa, 13.5, accuracy: 0.000001)
        XCTAssertEqual(result.knownCircuitPressureLossKPa, 21.5, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(result.completeCircuitPressureLossKPa), 21.5, accuracy: 0.000001)
        XCTAssertTrue(result.pipeCoverageComplete)
        XCTAssertTrue(result.componentCoverageComplete)
        XCTAssertEqual(result.missingComponentCount, 0)
    }

    func testMissingComponentValueKeepsCircuitPartial() throws {
        let result = try XCTUnwrap(
            HeizBalanceCircuitPressureLossSummaryCalculator.calculate(
                .init(
                    partialPipePressureLossKPa: 5,
                    completePipePressureLossKPa: 5,
                    components: [
                        .init(id: "valve", pressureLossKPa: nil),
                        .init(id: "radiator", pressureLossKPa: 1)
                    ],
                    componentAssessmentComplete: true
                )
            )
        )

        XCTAssertEqual(result.knownCircuitPressureLossKPa, 6, accuracy: 0.000001)
        XCTAssertNil(result.completeCircuitPressureLossKPa)
        XCTAssertFalse(result.componentCoverageComplete)
        XCTAssertEqual(result.missingComponentCount, 1)
    }

    func testUnconfirmedComponentAssessmentKeepsCircuitPartialEvenWithNoComponents() throws {
        let result = try XCTUnwrap(
            HeizBalanceCircuitPressureLossSummaryCalculator.calculate(
                .init(
                    partialPipePressureLossKPa: 4,
                    completePipePressureLossKPa: 4,
                    components: [],
                    componentAssessmentComplete: false
                )
            )
        )

        XCTAssertEqual(result.knownCircuitPressureLossKPa, 4, accuracy: 0.000001)
        XCTAssertNil(result.completeCircuitPressureLossKPa)
        XCTAssertFalse(result.componentCoverageComplete)
    }

    func testIncompletePipeKeepsCircuitPartial() throws {
        let result = try XCTUnwrap(
            HeizBalanceCircuitPressureLossSummaryCalculator.calculate(
                .init(
                    partialPipePressureLossKPa: 3,
                    completePipePressureLossKPa: nil,
                    components: [.init(id: "valve", pressureLossKPa: 10)],
                    componentAssessmentComplete: true
                )
            )
        )

        XCTAssertEqual(result.knownCircuitPressureLossKPa, 13, accuracy: 0.000001)
        XCTAssertNil(result.completeCircuitPressureLossKPa)
        XCTAssertFalse(result.pipeCoverageComplete)
        XCTAssertTrue(result.componentCoverageComplete)
    }
}
