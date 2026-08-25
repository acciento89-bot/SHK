import Testing
@testable import SHKCore

@Test func hydronicPreparationUsesRequiredPowerForTargetFlow() {
    let result = HeizBalanceHydronicPreparationCalculator.calculate(
        .init(
            requiredPowerW: 1000,
            availablePowerW: 1250,
            flowTemperatureC: 55,
            returnTemperatureC: 45
        )
    )

    #expect(result != nil)
    #expect(result!.capacitySufficient)
    #expect(result!.capacityMarginW == 250)
    #expect(abs(result!.capacityRatio - 1.25) < 0.0001)
    #expect(result!.targetVolumeFlowLPH > 85)
    #expect(result!.targetVolumeFlowLPH < 87)
}

@Test func hydronicPreparationReportsInsufficientCapacity() {
    let result = HeizBalanceHydronicPreparationCalculator.calculate(
        .init(
            requiredPowerW: 1200,
            availablePowerW: 900,
            flowTemperatureC: 45,
            returnTemperatureC: 35
        )
    )

    #expect(result != nil)
    #expect(result!.capacitySufficient == false)
    #expect(result!.capacityMarginW == -300)
    #expect(result!.capacityRatio == 0.75)
}

@Test func hydronicPreparationRejectsInvalidInputs() {
    #expect(
        HeizBalanceHydronicPreparationCalculator.calculate(
            .init(requiredPowerW: 0, availablePowerW: 1000, flowTemperatureC: 55, returnTemperatureC: 45)
        ) == nil
    )
    #expect(
        HeizBalanceHydronicPreparationCalculator.calculate(
            .init(requiredPowerW: 1000, availablePowerW: 1000, flowTemperatureC: 45, returnTemperatureC: 45)
        ) == nil
    )
}
