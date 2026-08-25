import Testing
@testable import SHKCore

struct HeizBalanceTemperatureScenarioTests {
    @Test
    func calculatesAvailableAndRequiredNominalPower() throws {
        let result = try #require(
            HeizBalanceTemperatureScenarioCalculator.calculate(
                .init(
                    nominalPowerDeltaT50W: 2000,
                    exponent: 1.3,
                    requiredPowerW: 1000,
                    roomTemperatureC: 20,
                    flowTemperatureC: 45,
                    returnTemperatureC: 35
                )
            )
        )

        #expect(abs(result.meanTemperatureDifferenceK - 20) < 0.001)
        #expect(abs(result.availablePowerW - 607.63) < 0.2)
        #expect(abs(result.capacityRatio - 0.60763) < 0.001)
        #expect(result.sufficient == false)
        #expect(abs(result.requiredNominalPowerDeltaT50W - 3291.1) < 1.0)
        #expect(abs(result.nominalPowerFactor - 1.64555) < 0.001)
    }

    @Test
    func reportsSufficientScenarioAndFactorBelowOne() throws {
        let result = try #require(
            HeizBalanceTemperatureScenarioCalculator.calculate(
                .init(
                    nominalPowerDeltaT50W: 2500,
                    exponent: 1.3,
                    requiredPowerW: 700,
                    roomTemperatureC: 20,
                    flowTemperatureC: 45,
                    returnTemperatureC: 35
                )
            )
        )

        #expect(result.sufficient == true)
        #expect(result.capacityRatio > 1)
        #expect(result.nominalPowerFactor < 1)
        #expect(result.requiredNominalPowerDeltaT50W < 2500)
    }

    @Test
    func rejectsReturnTemperatureAtOrBelowRoomTemperature() {
        #expect(
            HeizBalanceTemperatureScenarioCalculator.calculate(
                .init(
                    nominalPowerDeltaT50W: 2000,
                    exponent: 1.3,
                    requiredPowerW: 1000,
                    roomTemperatureC: 20,
                    flowTemperatureC: 30,
                    returnTemperatureC: 20
                )
            ) == nil
        )
    }

    @Test
    func rejectsInvalidTemperatureOrder() {
        #expect(
            HeizBalanceTemperatureScenarioCalculator.calculate(
                .init(
                    nominalPowerDeltaT50W: 2000,
                    exponent: 1.3,
                    requiredPowerW: 1000,
                    roomTemperatureC: 20,
                    flowTemperatureC: 35,
                    returnTemperatureC: 40
                )
            ) == nil
        )
    }
}
