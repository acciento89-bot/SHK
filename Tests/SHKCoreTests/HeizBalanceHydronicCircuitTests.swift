import XCTest
@testable import SHKCore

final class HeizBalanceHydronicCircuitTests: XCTestCase {
    func testAggregatesStraightAndLocalPressureLosses() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydronicCircuitCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: 100,
                    densityKGPerM3: 980,
                    kinematicViscosityM2S: 0.55e-6,
                    sections: [
                        .init(id: "a", name: "Anbindung", innerDiameterMM: 12, lengthM: 10, roughnessMM: 0.007, zetaTotal: 5),
                        .init(id: "b", name: "Strang", innerDiameterMM: 16, lengthM: 8, roughnessMM: 0.007, zetaTotal: 2)
                    ]
                )
            )
        )

        let completePressureLoss = try XCTUnwrap(result.completePressureLossKPa)
        XCTAssertEqual(result.sections.count, 2)
        XCTAssertTrue(result.localResistanceCoverageComplete)
        XCTAssertEqual(result.straightPipePressureLossKPa, 1.1129933712, accuracy: 0.000001)
        XCTAssertEqual(result.knownLocalPressureLossKPa, 0.1664989989, accuracy: 0.000001)
        XCTAssertEqual(result.partialPressureLossKPa, 1.2794923701, accuracy: 0.000001)
        XCTAssertEqual(completePressureLoss, 1.2794923701, accuracy: 0.000001)
        XCTAssertNotNil(result.completeHeadMeters)
    }

    func testKeepsResultPartialWhenLocalResistanceIsUnknown() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydronicCircuitCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: 120,
                    densityKGPerM3: 985,
                    kinematicViscosityM2S: 0.65e-6,
                    sections: [
                        .init(id: "a", name: "Rohr", innerDiameterMM: 14, lengthM: 12, roughnessMM: 0.007, zetaTotal: nil)
                    ]
                )
            )
        )

        XCTAssertFalse(result.localResistanceCoverageComplete)
        XCTAssertGreaterThan(result.straightPipePressureLossKPa, 0)
        XCTAssertEqual(result.knownLocalPressureLossKPa, 0, accuracy: 0.000001)
        XCTAssertNil(result.completePressureLossKPa)
        XCTAssertNil(result.completeHeadMeters)
        XCTAssertNil(result.sections.first?.localPressureLossKPa)
    }

    func testRejectsInvalidHydraulicInputs() {
        XCTAssertNil(
            HeizBalanceHydronicCircuitCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: 0,
                    densityKGPerM3: 980,
                    kinematicViscosityM2S: 0.55e-6,
                    sections: [.init(id: "a", name: "Rohr", innerDiameterMM: 12, lengthM: 5, roughnessMM: 0.007, zetaTotal: 0)]
                )
            )
        )

        XCTAssertNil(
            HeizBalanceHydronicCircuitCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: 100,
                    densityKGPerM3: 980,
                    kinematicViscosityM2S: 0.55e-6,
                    sections: [.init(id: "a", name: "Rohr", innerDiameterMM: -1, lengthM: 5, roughnessMM: 0.007, zetaTotal: 0)]
                )
            )
        )
    }
}
