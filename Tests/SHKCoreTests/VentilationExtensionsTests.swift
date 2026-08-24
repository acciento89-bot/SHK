import Testing
@testable import SHKCore

@Test func roundDuctSizingAndVelocity() {
    let required = VentilationCalculator.roundDiameterMM(volumeFlowM3H: 250, targetVelocityMS: 3)
    #expect(required > 165 && required < 175)
    #expect(VentilationCalculator.nextCommonRoundDiameterMM(requiredDiameterMM: required) == 180)

    let velocity = VentilationCalculator.roundVelocityMS(volumeFlowM3H: 250, diameterMM: 180)
    #expect(velocity > 2.7 && velocity < 2.8)
}

@Test func rectangularDuctSizing() {
    let height = VentilationCalculator.rectangularRequiredHeightMM(volumeFlowM3H: 500, widthMM: 300, targetVelocityMS: 3)
    #expect(height > 154 && height < 155)

    let velocity = VentilationCalculator.velocityMS(volumeFlowM3H: 500, widthMM: 300, heightMM: 200)
    #expect(velocity > 2.31 && velocity < 2.32)

    let equivalent = VentilationCalculator.equivalentRoundDiameterMM(widthMM: 300, heightMM: 200)
    #expect(equivalent > 266 && equivalent < 267)
}

@Test func roomAirExchange() {
    let volume = VentilationCalculator.roomVolumeM3(lengthM: 5, widthM: 4, heightM: 2.5)
    #expect(volume == 50)

    let flow = VentilationCalculator.requiredFlowM3H(roomLengthM: 5, roomWidthM: 4, roomHeightM: 2.5, airChangesPerHour: 1.5)
    #expect(flow == 75)
    #expect(VentilationCalculator.airChangesPerHour(volumeFlowM3H: 75, roomVolumeM3: volume) == 1.5)
}

@Test func airflowUnitConversions() {
    #expect(abs(VentilationCalculator.m3HToLitersPerSecond(360) - 100) < 0.0001)
    #expect(abs(VentilationCalculator.litersPerSecondToM3H(100) - 360) < 0.0001)
    #expect(abs(VentilationCalculator.cfmToM3H(VentilationCalculator.m3HToCFM(500)) - 500) < 0.0001)
}
