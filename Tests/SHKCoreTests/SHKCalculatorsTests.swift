import Testing
@testable import SHKCore

@Test func refrigerationBasics() {
    #expect(RefrigerationCalculator.superheat(suctionGasC: 11, evaporationC: 4) == 7)
    #expect(RefrigerationCalculator.subcooling(condensationC: 42, liquidLineC: 36) == 6)
}

@Test func ventilationRoundDuct() {
    let d = VentilationCalculator.roundDiameterMM(volumeFlowM3H: 250, targetVelocityMS: 3)
    #expect(d > 165 && d < 175)
}

@Test func radiatorCorrection() {
    let power = RadiatorCalculator.correctedPowerW(nominalPowerW: 2000, actualDeltaTK: 30)
    #expect(power > 1000 && power < 1100)
    let flow = RadiatorCalculator.volumeFlowLPH(powerW: 2000, waterDeltaTK: 10)
    #expect(flow > 171 && flow < 173)
}

@Test func pipeHydraulics() {
    let value = PipeCalculator.calculate(volumeFlowLPH: 1000, innerDiameterMM: 20, lengthM: 10)
    #expect(value.velocityMS > 0.8 && value.velocityMS < 0.9)
    #expect(value.pipeVolumeL > 3.1 && value.pipeVolumeL < 3.2)
    #expect(value.pressureDropPaPerM > 0)
}

@Test func systemCheck() {
    let checks = AnlagenCheckCalculator.evaluate(flowC: 55, returnC: 45, coldPressureBar: 1.5, hotPressureBar: 1.9, allowedMinBar: 1.2, allowedMaxBar: 2.0)
    #expect(checks.count == 3)
    #expect(checks.allSatisfy { $0.severity == .ok })
}
