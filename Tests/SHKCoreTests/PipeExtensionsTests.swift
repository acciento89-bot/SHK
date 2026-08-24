import Testing
@testable import SHKCore

@Test func pipeRequiredDiameterAndMaximumFlow() {
    let required = PipeCalculator.requiredInnerDiameterMM(volumeFlowLPH: 1000, targetVelocityMS: 1)
    #expect(required > 18.8 && required < 18.9)

    let maxFlow = PipeCalculator.maximumVolumeFlowLPH(innerDiameterMM: 20, maximumVelocityMS: 1)
    #expect(maxFlow > 1130 && maxFlow < 1132)
}

@Test func pipeReynoldsAndRegime() {
    let reynolds = PipeCalculator.reynoldsNumber(volumeFlowLPH: 1000, innerDiameterMM: 20)
    #expect(reynolds > 17_000 && reynolds < 18_000)
    #expect(PipeCalculator.flowRegime(reynoldsNumber: reynolds) == .turbulent)
    #expect(PipeCalculator.flowRegime(reynoldsNumber: 1500) == .laminar)
    #expect(PipeCalculator.flowRegime(reynoldsNumber: 3000) == .transitional)
}

@Test func pipeLocalLossAddsToLineLoss() {
    let noLocal = PipeCalculator.calculateExtended(
        volumeFlowLPH: 1000,
        innerDiameterMM: 20,
        lengthM: 10,
        roughnessMM: 0.01,
        zetaTotal: 0
    )
    let withLocal = PipeCalculator.calculateExtended(
        volumeFlowLPH: 1000,
        innerDiameterMM: 20,
        lengthM: 10,
        roughnessMM: 0.01,
        zetaTotal: 5
    )

    #expect(withLocal.localPressureLossKPa > 0)
    #expect(withLocal.totalPressureLossIncludingLocalKPa > noLocal.totalPressureLossIncludingLocalKPa)
    #expect(withLocal.totalHeadMeters > 0)
}

@Test func pressureLossUnitConversion() {
    #expect(abs(PipeCalculator.pascalPerMeterToMbarPerMeter(250) - 2.5) < 0.0001)
    #expect(abs(PipeCalculator.metersWaterColumn(pressureLossKPa: 9.786) - 1) < 0.01)
}
