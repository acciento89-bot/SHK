import Testing
@testable import SHKCore

struct HeizBalanceLowTemperatureCheckTests {
    @Test
    func derivesMinimumTemperaturesForFixedSpread() throws {
        let result = try #require(
            HeizBalanceLowTemperatureCheckCalculator.calculate(
                .init(
                    nominalPowerDeltaT50W: 2000,
                    exponent: 1.3,
                    requiredPowerW: 1000,
                    roomTemperatureC: 20,
                    waterTemperatureDifferenceK: 10,
                    comparisonFlowTemperatureC: 55
                )
            )
        )

        #expect(abs(result.requiredMeanTemperatureDifferenceK - 29.3365) < 0.001)
        #expect(abs(result.minimumFlowTemperatureC - 54.3365) < 0.001)
        #expect(abs(result.minimumReturnTemperatureC - 44.3365) < 0.001)
        #expect(result.comparisonSufficient == true)
        #expect((result.comparisonCapacityRatio ?? 0) > 1)
    }

    @Test
    func reportsInsufficientComparisonTemperature() throws {
        let result = try #require(
            HeizBalanceLowTemperatureCheckCalculator.calculate(
                .init(
                    nominalPowerDeltaT50W: 2000,
                    exponent: 1.3,
                    requiredPowerW: 1000,
                    roomTemperatureC: 20,
                    waterTemperatureDifferenceK: 10,
                    comparisonFlowTemperatureC: 45
                )
            )
        )

        #expect(result.comparisonSufficient == false)
        #expect((result.comparisonCapacityRatio ?? 1) < 1)
    }

    @Test
    func rejectsMissingPhysicalTemperatureWindow() {
        let result = HeizBalanceLowTemperatureCheckCalculator.calculate(
            .init(
                nominalPowerDeltaT50W: 5000,
                exponent: 1.3,
                requiredPowerW: 10,
                roomTemperatureC: 20,
                waterTemperatureDifferenceK: 20,
                comparisonFlowTemperatureC: nil
            )
        )

        #expect(result == nil)
    }

    @Test
    func rejectsInvalidInputs() {
        #expect(
            HeizBalanceLowTemperatureCheckCalculator.calculate(
                .init(
                    nominalPowerDeltaT50W: 0,
                    exponent: 1.3,
                    requiredPowerW: 1000,
                    roomTemperatureC: 20,
                    waterTemperatureDifferenceK: 10,
                    comparisonFlowTemperatureC: nil
                )
            ) == nil
        )
    }
}
