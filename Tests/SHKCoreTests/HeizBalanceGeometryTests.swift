import Testing
@testable import SHKCore

@Test func heizBalanceFloorArea() {
    let area = HeizBalanceGeometry.floorArea(lengthM: 5.2, widthM: 4.1)
    #expect(abs(area - 21.32) < 0.0001)
}

@Test func heizBalanceRoomVolume() {
    let volume = HeizBalanceGeometry.roomVolume(lengthM: 5.2, widthM: 4.1, heightM: 2.5)
    #expect(abs(volume - 53.3) < 0.0001)
}

@Test func heizBalanceGeometryRejectsNegativeDimensions() {
    #expect(HeizBalanceGeometry.floorArea(lengthM: -5, widthM: 4) == 0)
    #expect(HeizBalanceGeometry.roomVolume(lengthM: 5, widthM: 4, heightM: -2.5) == 0)
}
