import Testing
@testable import SHKCore

@Test func refrigerationBasics() {
    #expect(RefrigerationCalculator.superheat(suctionGasC: 11, evaporationC: 4) == 7)
    #expect(RefrigerationCalculator.subcooling(condensationC: 42, liquidLineC: 36) == 6)

    // Negative values are intentionally preserved as diagnostic information.
    #expect(RefrigerationCalculator.superheat(suctionGasC: 2, evaporationC: 4) == -2)
    #expect(RefrigerationCalculator.subcooling(condensationC: 35, liquidLineC: 37) == -2)
}

@Test func refrigerationPressureRatio() {
    let ratio = RefrigerationCalculator.compressorPressureRatio(suctionGaugeBar: 7.5, dischargeGaugeBar: 24)
    #expect(ratio > 2.9 && ratio < 3.0)
}

@Test func refrigerationConversions() {
    #expect(abs(RefrigerationCalculator.celsiusToFahrenheit(0) - 32) < 0.0001)
    #expect(abs(RefrigerationCalculator.fahrenheitToCelsius(212) - 100) < 0.0001)
    #expect(abs(RefrigerationCalculator.barToPSI(1) - 14.5037738) < 0.0001)
    #expect(abs(RefrigerationCalculator.psiToBar(14.5037738) - 1) < 0.0001)
    #expect(abs(RefrigerationCalculator.barToKPa(10) - 1000) < 0.0001)
    #expect(abs(RefrigerationCalculator.mbarToPascal(1) - 100) < 0.0001)
    #expect(RefrigerationCalculator.mbarToMicron(1) > 750 && RefrigerationCalculator.mbarToMicron(1) < 751)
    #expect(abs(RefrigerationCalculator.micronToMbar(RefrigerationCalculator.mbarToMicron(1)) - 1) < 0.0001)
}

@Test func refrigerationAirCapacity() {
    let capacity = RefrigerationCalculator.airSideCapacityKW(volumeFlowM3H: 800, enteringAirC: 27, leavingAirC: 19)
    #expect(capacity > 2.14 && capacity < 2.15)
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
