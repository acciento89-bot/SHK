import Testing
@testable import SHKCore

@Test func radiatorArithmeticReference() {
    let evaluation = RadiatorCalculator.temperatureEvaluation(flowC: 75, returnC: 65, roomC: 20)
    #expect(evaluation.method == .arithmetic)
    #expect(abs(evaluation.deltaTK - 50) < 0.0001)
    #expect(abs(evaluation.referenceDeltaTK - 50) < 0.0001)
}

@Test func radiatorLogarithmicTemperatureDifference() {
    let evaluation = RadiatorCalculator.temperatureEvaluation(flowC: 70, returnC: 40, roomC: 20)
    #expect(evaluation.method == .logarithmic)
    #expect(evaluation.deltaTK > 32.7 && evaluation.deltaTK < 32.8)
    #expect(evaluation.referenceDeltaTK > 49.8 && evaluation.referenceDeltaTK < 49.9)
}

@Test func radiatorCorrectedPowerAtLowTemperature() {
    let power = RadiatorCalculator.correctedPowerW(
        nominalPowerDeltaT50W: 2000,
        flowC: 55,
        returnC: 45,
        roomC: 20,
        exponent: 1.3
    )
    #expect(power > 1020 && power < 1040)
}

@Test func radiatorRequiredNominalPowerRoundTrip() {
    let requiredActual = 1500.0
    let nominal = RadiatorCalculator.requiredNominalPowerDeltaT50W(
        requiredActualPowerW: requiredActual,
        flowC: 55,
        returnC: 45,
        roomC: 20,
        exponent: 1.3
    )
    let actual = RadiatorCalculator.correctedPowerW(
        nominalPowerDeltaT50W: nominal,
        flowC: 55,
        returnC: 45,
        roomC: 20,
        exponent: 1.3
    )
    #expect(abs(actual - requiredActual) < 0.001)
}

@Test func radiatorCountRoundsUp() {
    #expect(RadiatorCalculator.radiatorCount(requiredPowerW: 2200, actualPowerPerRadiatorW: 900) == 3)
    #expect(RadiatorCalculator.radiatorCount(requiredPowerW: 0, actualPowerPerRadiatorW: 900) == 0)
}
