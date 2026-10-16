import XCTest
@testable import SHKCore

final class VolumeCalculatorTests: XCTestCase {
    func testPipe16x2At100Meters() {
        let volume = VolumeCalculator.pipeVolumeLiters(innerDiameterMM: 12, lengthMeters: 100)
        XCTAssertEqual(volume, 11.3097, accuracy: 0.001)
    }

    func testCopper22At25Meters() {
        let volume = VolumeCalculator.pipeVolumeLiters(innerDiameterMM: 20, lengthMeters: 25)
        XCTAssertEqual(volume, 7.854, accuracy: 0.001)
    }

    func testGalvanizedSteelDN25Preset() throws {
        let preset = try XCTUnwrap(
            ReferenceData.pipePresets.first {
                $0.group == "Stahl Gewinderohr verzinkt" && $0.name.contains("DN 25")
            }
        )
        XCTAssertEqual(preset.innerDiameterMM, 27.3, accuracy: 0.0001)
        XCTAssertEqual(preset.litersPerMeter, 0.5854, accuracy: 0.001)
    }

    func testBoilerTube604x29Preset() throws {
        let preset = try XCTUnwrap(
            ReferenceData.pipePresets.first {
                $0.group == "Siederohr normalwandig" && $0.name == "60,3 × 2,9 mm"
            }
        )
        XCTAssertEqual(preset.innerDiameterMM, 54.5, accuracy: 0.0001)
        XCTAssertEqual(preset.litersPerMeter, 2.3329, accuracy: 0.001)
    }

    func testPurmoReferenceType22Height600Length1000() throws {
        let ref = try XCTUnwrap(ReferenceData.radiatorReference(type: "22", heightMM: 600))
        XCTAssertEqual(ref.litersPerMeter, 6.6, accuracy: 0.0001)
        XCTAssertEqual(
            VolumeCalculator.radiatorVolumeLiters(litersPerMeter: ref.litersPerMeter, lengthMM: 1000),
            6.6,
            accuracy: 0.0001
        )
    }

    func testSteelSectionRadiator600x110TenSections() throws {
        let ref = try XCTUnwrap(
            ReferenceData.sectionRadiatorReferences.first {
                $0.material == .steel && $0.heightMM == 600 && $0.depthMM == 110
            }
        )
        XCTAssertEqual(ref.litersPerSection, 0.833, accuracy: 0.0001)
        XCTAssertEqual(
            VolumeCalculator.sectionRadiatorVolumeLiters(
                litersPerSection: ref.litersPerSection,
                sections: 10
            ),
            8.33,
            accuracy: 0.001
        )
    }

    func testCastIronSectionRadiator580x220TwelveSections() throws {
        let ref = try XCTUnwrap(
            ReferenceData.sectionRadiatorReferences.first {
                $0.material == .castIron && $0.heightMM == 580 && $0.depthMM == 220
            }
        )
        XCTAssertEqual(ref.litersPerSection, 1.3, accuracy: 0.0001)
        XCTAssertEqual(
            VolumeCalculator.sectionRadiatorVolumeLiters(
                litersPerSection: ref.litersPerSection,
                sections: 12
            ),
            15.6,
            accuracy: 0.001
        )
    }

    func testProjectReserve() {
        var project = VolumeProject(reservePercent: 5)
        project.components = [
            VolumeComponent(kind: .other, name: "A", unitVolumeLiters: 100),
            VolumeComponent(kind: .other, name: "B", quantity: 2, unitVolumeLiters: 25)
        ]
        XCTAssertEqual(project.calculatedVolumeLiters, 150, accuracy: 0.001)
        XCTAssertEqual(project.reserveLiters, 7.5, accuracy: 0.001)
        XCTAssertEqual(project.planningVolumeLiters, 157.5, accuracy: 0.001)
    }

    func testZeroAndNegativeValuesClampToZero() {
        XCTAssertEqual(VolumeCalculator.pipeVolumeLiters(innerDiameterMM: 0, lengthMeters: 10), 0)
        XCTAssertEqual(VolumeCalculator.pipeVolumeLiters(innerDiameterMM: 12, lengthMeters: -1), 0)
        XCTAssertEqual(VolumeCalculator.sectionRadiatorVolumeLiters(litersPerSection: 1, sections: -1), 0)
    }
}

final class FillCheckTests: XCTestCase {
    func testNetFillSubtractsDrainedWaterAndUsesFrozenInventory() {
        var check = FillCheck(); check.meterStartL = 100; check.meterEndL = 220; check.drainedL = 10
        check.calculatedBaselineL = 100; check.confirmedEmptySystem = true
        XCTAssertTrue(check.isValid)
        XCTAssertEqual(check.netFillL, 110)
        XCTAssertEqual(check.deviationL, 10)
        XCTAssertEqual(check.deviationPercent, 10)
        XCTAssertTrue(check.isWithinTolerance)
    }
    func testInvalidOrPartialFillCannotBeRecorded() {
        var check = FillCheck(); check.meterEndL = 100; check.calculatedBaselineL = 100
        XCTAssertFalse(check.isValid)
        check.confirmedEmptySystem = true; XCTAssertTrue(check.isValid)
        check.drainedL = 101; XCTAssertFalse(check.isValid)
        check.drainedL = 0; check.meterEndL = .nan; XCTAssertFalse(check.isValid)
    }
    func testOldProjectsDecodeWithoutFillChecks() throws {
        let id = UUID()
        let json = """
        {"id":"\(id.uuidString)","name":"Old","createdAt":0,"updatedAt":0,"reservePercent":5,"components":[]}
        """
        let project = try JSONDecoder().decode(VolumeProject.self, from: Data(json.utf8))
        XCTAssertEqual(project.id, id)
        XCTAssertNil(project.fillChecks)
    }
    func testReserveNeverChangesFillBaseline() throws {
        var project = VolumeProject(components: [.init(kind: .buffer, name: "Buffer", unitVolumeLiters: 100)])
        var check = FillCheck(); check.calculatedBaselineL = project.calculatedVolumeLiters
        project.fillChecks = [check]; project.reservePercent = 50
        project.components.append(.init(kind: .other, name: "Addition", unitVolumeLiters: 20))
        XCTAssertEqual(project.fillChecks?.first?.calculatedBaselineL, 100)
        XCTAssertEqual(project.calculatedVolumeLiters, 120)
        XCTAssertEqual(project.planningVolumeLiters, 180)
        let restored = try JSONDecoder().decode(VolumeProject.self, from: JSONEncoder().encode(project))
        XCTAssertEqual(restored, project)
    }
}
