import XCTest
@testable import SHKCore

final class HeizBalancePumpCurveComparisonTests: XCTestCase {
    func testSummarizesSufficientInsufficientAndOutOfRangeCurves() throws {
        let dataset = HeizBalancePumpProductDataset(
            schema: HeizBalancePumpProductDataset.schemaVersion,
            id: "demo",
            manufacturer: "Demo",
            datasetName: "Pumpen",
            datasetVersion: "2026-08",
            source: .init(
                reference: "Fiktiver Testdatensatz",
                url: nil,
                usageBasis: .userProvided,
                rightsNote: nil
            ),
            products: [
                .init(
                    id: "p1",
                    productName: "Alpha",
                    series: nil,
                    articleNumber: nil,
                    sourceReference: nil,
                    curves: [
                        .init(
                            id: "ok",
                            label: "Ausreichend",
                            controlMode: nil,
                            speedRPM: nil,
                            sourceReference: nil,
                            points: [
                                .init(id: "a", volumeFlowM3H: 0, headM: 5, electricalInputPowerW: 20),
                                .init(id: "b", volumeFlowM3H: 2, headM: 3.5, electricalInputPowerW: 34)
                            ]
                        ),
                        .init(
                            id: "low",
                            label: "Zu niedrig",
                            controlMode: nil,
                            speedRPM: nil,
                            sourceReference: nil,
                            points: [
                                .init(id: "a", volumeFlowM3H: 0, headM: 3, electricalInputPowerW: 18),
                                .init(id: "b", volumeFlowM3H: 2, headM: 2, electricalInputPowerW: 26)
                            ]
                        ),
                        .init(
                            id: "range",
                            label: "Außerhalb",
                            controlMode: nil,
                            speedRPM: nil,
                            sourceReference: nil,
                            points: [
                                .init(id: "a", volumeFlowM3H: 0, headM: 5, electricalInputPowerW: nil),
                                .init(id: "b", volumeFlowM3H: 1, headM: 4, electricalInputPowerW: nil)
                            ]
                        )
                    ]
                )
            ]
        )

        let summary = try XCTUnwrap(
            HeizBalancePumpCurveComparisonCalculator.calculate(
                datasets: [dataset],
                targetVolumeFlowM3H: 1.5,
                requiredHeadM: 3.2
            )
        )

        XCTAssertEqual(summary.totalCurveCount, 3)
        XCTAssertEqual(summary.evaluableCount, 2)
        XCTAssertEqual(summary.technicallySufficientCount, 1)
        XCTAssertEqual(summary.insufficientHeadCount, 1)
        XCTAssertEqual(summary.outsideDocumentedRangeCount, 1)
        XCTAssertEqual(summary.entries.first?.status, .technicallySufficient)
        XCTAssertEqual(summary.entries.first?.curveID, "ok")
    }

    func testRejectsInvalidOperatingPoint() {
        XCTAssertNil(
            HeizBalancePumpCurveComparisonCalculator.calculate(
                datasets: [],
                targetVolumeFlowM3H: -0.1,
                requiredHeadM: 2
            )
        )
    }
}
