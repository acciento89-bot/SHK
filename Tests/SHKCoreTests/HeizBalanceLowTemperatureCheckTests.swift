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
    func technicalDemoCaseIsLimitedByBathroomAtFortyFiveThirtyFive() throws {
        let inputs: [HeizBalanceLowTemperatureCheckCalculator.Input] = [
            .init(
                nominalPowerDeltaT50W: 2500,
                exponent: 1.3,
                requiredPowerW: 700,
                roomTemperatureC: 20,
                waterTemperatureDifferenceK: 10,
                comparisonFlowTemperatureC: 45
            ),
            .init(
                nominalPowerDeltaT50W: 1800,
                exponent: 1.3,
                requiredPowerW: 500,
                roomTemperatureC: 19,
                waterTemperatureDifferenceK: 10,
                comparisonFlowTemperatureC: 45
            ),
            .init(
                nominalPowerDeltaT50W: 2200,
                exponent: 1.3,
                requiredPowerW: 600,
                roomTemperatureC: 24,
                waterTemperatureDifferenceK: 10,
                comparisonFlowTemperatureC: 45
            )
        ]

        let results = try inputs.map {
            try #require(HeizBalanceLowTemperatureCheckCalculator.calculate($0))
        }
        let limiting = try #require(results.max { $0.minimumFlowTemperatureC < $1.minimumFlowTemperatureC })

        #expect(abs(results[0].minimumFlowTemperatureC - 43.7805) < 0.001)
        #expect(abs(results[1].minimumFlowTemperatureC - 42.6657) < 0.001)
        #expect(abs(results[2].minimumFlowTemperatureC - 47.4041) < 0.001)
        #expect(abs(limiting.minimumFlowTemperatureC - 47.4041) < 0.001)
        #expect(results[0].comparisonSufficient == true)
        #expect(results[1].comparisonSufficient == true)
        #expect(results[2].comparisonSufficient == false)
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
