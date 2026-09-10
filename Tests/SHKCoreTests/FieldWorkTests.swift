import XCTest
@testable import SHKCore

final class FieldWorkTests: XCTestCase {
    func testRoomSurplusDoesNotHideOtherRoomDeficit() {
        var room = HeatRoom(); room.name = "A"; room.nominalW = 1000; room.demandW = 1500
        var surplus = HeatRoom(); surplus.name = "B"; surplus.nominalW = 3000; surplus.demandW = 500
        var survey = HeatSurvey(); survey.name = "Building"; survey.flowC = 75; survey.returnC = 65; survey.rooms = [room, surplus]
        XCTAssertEqual(survey.deficitW, 500, accuracy: 0.001)
        XCTAssertEqual(survey.deficientRoomCount, 1)
        XCTAssertTrue(survey.isValid)
        survey.returnC = 20
        XCTAssertFalse(survey.isValid)
    }
    func testLowerSystemTemperatureReducesCapacity() {
        var room = HeatRoom(); room.name = "Room"
        XCTAssertLessThan(room.power(flow: 45, returning: 35), room.power(flow: 55, returning: 45))
    }
    func testSerialRouteAddsFrictionAndLocalLosses() {
        var a = PipeSection(); a.name = "A"; a.zeta = 3
        var b = PipeSection(); b.name = "B"; b.diameterMM = 12; b.lengthM = 5
        var route = PipeRoute(); route.name = "Route"; route.sections = [a, b]
        let aResult = a.result(flow: route.flowLPH)
        let bResult = b.result(flow: route.flowLPH)
        XCTAssertEqual(route.totalLossKPa, aResult.base.totalPressureDropKPa + aResult.localPressureLossKPa + bResult.base.totalPressureDropKPa + bResult.localPressureLossKPa, accuracy: 1e-9)
        XCTAssertEqual(route.largestLossSection?.id, b.id)
        XCTAssertEqual(route.totalVolumeL, aResult.base.pipeVolumeL + bResult.base.pipeVolumeL, accuracy: 1e-9)
    }
    func testUnmeasuredIsDifferentFromMeasuredZero() {
        var terminal = AirTerminal(); terminal.name = "A"
        XCTAssertNil(terminal.deviationPercent)
        XCTAssertNil(terminal.meetsTolerance(10))
        terminal.measuredM3H = 0
        XCTAssertEqual(terminal.deviationPercent, -100)
        XCTAssertEqual(terminal.meetsTolerance(10), false)
    }
    func testCommissionDoesNotReportPartialTotalAsComplete() {
        var a = AirTerminal(); a.name = "A"; a.measuredM3H = 40
        var b = AirTerminal(); b.name = "B"
        var project = AirCommission(); project.name = "Project"; project.terminals = [a, b]
        XCTAssertNil(project.measured(.supply))
        XCTAssertNil(project.measured(.extract))
        XCTAssertEqual(project.missingCount, 1)
        project.terminals[1].measuredM3H = 0
        XCTAssertEqual(project.measured(.supply), 40)
        XCTAssertEqual(project.missingCount, 0)
        XCTAssertEqual(project.outsideCount, 1)
    }
    func testToleranceBoundaryAndNegativeMeasurement() {
        var terminal = AirTerminal(); terminal.name = "A"; terminal.targetM3H = 100; terminal.measuredM3H = 110
        XCTAssertEqual(terminal.meetsTolerance(10), true)
        terminal.measuredM3H = 110.01
        XCTAssertEqual(terminal.meetsTolerance(10), false)
        terminal.measuredM3H = -1
        XCTAssertFalse(terminal.isValid)
    }
    func testColdChronologyUsesTimestampsAndKeepsNegativeValues() {
        var early = ColdReading(); early.date = Date(timeIntervalSince1970: 100); early.suctionC = 0; early.evaporationC = 2
        var late = ColdReading(); late.date = Date(timeIntervalSince1970: 200); late.suctionC = 8; late.evaporationC = 2
        var session = ColdSession(); session.name = "Service"; session.readings = [late, early]
        XCTAssertEqual(early.superheatK, -2)
        XCTAssertEqual(session.chronological.first?.id, early.id)
        XCTAssertEqual(session.superheatChangeK, 8)
        session.readings = [early]
        XCTAssertNil(session.superheatChangeK)
    }
    func testInvalidNumbersCannotBeSaved() {
        var room = HeatRoom(); room.name = "A"; room.demandW = .nan; XCTAssertFalse(room.isValid)
        var section = PipeSection(); section.name = "A"; section.diameterMM = .infinity; XCTAssertFalse(section.isValid)
        var route = PipeRoute(); route.name = "A"; route.flowLPH = 0; XCTAssertFalse(route.isValid)
        var reading = ColdReading(); reading.liquidC = -.infinity; XCTAssertFalse(reading.isValid)
        var air = AirCommission(); air.name = "A"; air.tolerancePercent = -1; XCTAssertFalse(air.isValid)
    }
    func testAllDocumentTypesRoundTripWithoutChangingIDsOrMissingValues() throws {
        var heat = HeatSurvey(); heat.name = "Älteres Gebäude"; heat.rooms = [HeatRoom()]
        var pipe = PipeRoute(); pipe.name = "A → B"; pipe.sections = [PipeSection()]
        var air = AirCommission(); air.name = "Zuluft"; air.terminals = [AirTerminal()]
        var cold = ColdSession(); cold.name = "Service"; cold.readings = [ColdReading()]
        func roundTrip<T: Codable & Equatable>(_ value: T) throws {
            XCTAssertEqual(try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value)), value)
        }
        try roundTrip(heat); try roundTrip(pipe); try roundTrip(air); try roundTrip(cold)
    }
}
