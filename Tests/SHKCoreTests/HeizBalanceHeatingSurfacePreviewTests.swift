import Testing
@testable import SHKCore

@Test func heatingSurfacePreviewProducesPowerAndFlowFromExplicitInputs() {
    let result = HeizBalanceHeatingSurfacePreviewCalculator.calculate(
        .init(
            nominalPowerDeltaT50W: 2000,
            exponent: 1.3,
            flowTemperatureC: 55,
            returnTemperatureC: 45,
            roomTemperatureC: 20
        )
    )

    #expect(result != nil)
    #expect(result!.availablePowerW > 0)
    #expect(result!.availablePowerW < 2000)
    #expect(result!.waterTemperatureDifferenceK == 10)
    #expect(result!.volumeFlowLPH > 0)
}

@Test func heatingSurfacePreviewRejectsInvalidTemperatureOrder() {
    let result = HeizBalanceHeatingSurfacePreviewCalculator.calculate(
        .init(
            nominalPowerDeltaT50W: 1500,
            exponent: 1.3,
            flowTemperatureC: 45,
            returnTemperatureC: 50,
            roomTemperatureC: 20
        )
    )

    #expect(result == nil)
}

@Test func heatingSurfacePreviewRejectsReturnAtOrBelowRoomTemperature() {
    let result = HeizBalanceHeatingSurfacePreviewCalculator.calculate(
        .init(
            nominalPowerDeltaT50W: 1500,
            exponent: 1.3,
            flowTemperatureC: 35,
            returnTemperatureC: 20,
            roomTemperatureC: 20
        )
    )

    #expect(result == nil)
}
