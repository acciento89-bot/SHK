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
                        .init(id: "a", name: "Anbindung", volumeFlowLPH: 100, innerDiameterMM: 12, lengthM: 10, roughnessMM: 0.007, zetaTotal: 5),
                        .init(id: "b", name: "Strang", volumeFlowLPH: 100, innerDiameterMM: 16, lengthM: 8, roughnessMM: 0.007, zetaTotal: 2)
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

    func testUsesSectionSpecificFlowForSharedDistribution() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydronicCircuitCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: 100,
                    densityKGPerM3: 980,
                    kinematicViscosityM2S: 0.55e-6,
                    sections: [
                        .init(id: "branch", name: "Anbindung", volumeFlowLPH: 100, innerDiameterMM: 16, lengthM: 5, roughnessMM: 0.007, zetaTotal: 0),
                        .init(id: "main", name: "Gemeinsamer Strang", volumeFlowLPH: 400, innerDiameterMM: 16, lengthM: 5, roughnessMM: 0.007, zetaTotal: 0)
                    ]
                )
            )
        )

        XCTAssertEqual(result.sections[0].volumeFlowLPH, 100, accuracy: 0.000001)
        XCTAssertEqual(result.sections[1].volumeFlowLPH, 400, accuracy: 0.000001)
        XCTAssertGreaterThan(result.sections[1].velocityMS, result.sections[0].velocityMS)
        XCTAssertGreaterThan(result.sections[1].pressureDropPaPerM, result.sections[0].pressureDropPaPerM)
    }

    func testKeepsResultPartialWhenLocalResistanceIsUnknown() throws {
        let result = try XCTUnwrap(
            HeizBalanceHydronicCircuitCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: 120,
                    densityKGPerM3: 985,
                    kinematicViscosityM2S: 0.65e-6,
                    sections: [
                        .init(id: "a", name: "Rohr", volumeFlowLPH: 120, innerDiameterMM: 14, lengthM: 12, roughnessMM: 0.007, zetaTotal: nil)
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
                    sections: [.init(id: "a", name: "Rohr", volumeFlowLPH: 100, innerDiameterMM: 12, lengthM: 5, roughnessMM: 0.007, zetaTotal: 0)]
                )
            )
        )

        XCTAssertNil(
            HeizBalanceHydronicCircuitCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: 100,
                    densityKGPerM3: 980,
                    kinematicViscosityM2S: 0.55e-6,
                    sections: [.init(id: "a", name: "Rohr", volumeFlowLPH: 100, innerDiameterMM: -1, lengthM: 5, roughnessMM: 0.007, zetaTotal: 0)]
                )
            )
        )

        XCTAssertNil(
            HeizBalanceHydronicCircuitCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: 100,
                    densityKGPerM3: 980,
                    kinematicViscosityM2S: 0.55e-6,
                    sections: [.init(id: "a", name: "Rohr", volumeFlowLPH: 0, innerDiameterMM: 12, lengthM: 5, roughnessMM: 0.007, zetaTotal: 0)]
                )
            )
        )
    }
}
