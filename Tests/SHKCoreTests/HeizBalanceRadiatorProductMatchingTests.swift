import Testing
@testable import SHKCore

struct HeizBalanceRadiatorProductMatchingTests {
    @Test
    func sortsSufficientCandidatesBySmallestReserve() throws {
        let result = try #require(
            HeizBalanceRadiatorProductMatchingCalculator.calculate(
                .init(
                    requiredPowerW: 600,
                    roomTemperatureC: 20,
                    flowTemperatureC: 45,
                    returnTemperatureC: 35,
                    candidates: [
                        .init(id: "small", nominalPowerDeltaT50W: 1800, exponent: 1.3),
                        .init(id: "fit", nominalPowerDeltaT50W: 2200, exponent: 1.3),
                        .init(id: "large", nominalPowerDeltaT50W: 2700, exponent: 1.3)
                    ]
                )
            )
        )

        #expect(result.evaluatedCandidateCount == 3)
        #expect(result.candidates.map(\.candidateID) == ["fit", "large", "small"])
        #expect(result.smallestSufficientCandidate?.candidateID == "fit")
        #expect(result.candidates[0].sufficient == true)
        #expect(result.candidates[2].sufficient == false)
    }

    @Test
    func filtersCandidatesByDocumentedDimensions() throws {
        let result = try #require(
            HeizBalanceRadiatorProductMatchingCalculator.calculate(
                .init(
                    requiredPowerW: 500,
                    roomTemperatureC: 20,
                    flowTemperatureC: 50,
                    returnTemperatureC: 40,
                    candidates: [
                        .init(
                            id: "fits",
                            nominalPowerDeltaT50W: 1800,
                            exponent: 1.3,
                            widthMM: 1000,
                            heightMM: 600,
                            depthMM: 110
                        ),
                        .init(
                            id: "too-wide",
                            nominalPowerDeltaT50W: 2200,
                            exponent: 1.3,
                            widthMM: 1400,
                            heightMM: 600,
                            depthMM: 110
                        ),
                        .init(
                            id: "missing-width",
                            nominalPowerDeltaT50W: 2500,
                            exponent: 1.3,
                            widthMM: nil,
                            heightMM: 600,
                            depthMM: 110
                        )
                    ],
                    constraints: .init(maximumWidthMM: 1200)
                )
            )
        )

        #expect(result.evaluatedCandidateCount == 1)
        #expect(result.dimensionRejectedCandidateCount == 2)
        #expect(result.candidates.first?.candidateID == "fits")
    }

    @Test
    func countsInvalidProductsInsteadOfSilentlyUsingThem() throws {
        let result = try #require(
            HeizBalanceRadiatorProductMatchingCalculator.calculate(
                .init(
                    requiredPowerW: 500,
                    roomTemperatureC: 20,
                    flowTemperatureC: 50,
                    returnTemperatureC: 40,
                    candidates: [
                        .init(id: "valid", nominalPowerDeltaT50W: 1800, exponent: 1.3),
                        .init(id: "zero-power", nominalPowerDeltaT50W: 0, exponent: 1.3),
                        .init(id: "bad-exponent", nominalPowerDeltaT50W: 1800, exponent: 0)
                    ]
                )
            )
        )

        #expect(result.evaluatedCandidateCount == 1)
        #expect(result.invalidCandidateCount == 2)
        #expect(result.candidates.first?.candidateID == "valid")
    }

    @Test
    func rejectsInvalidScenarioTemperatures() {
        #expect(
            HeizBalanceRadiatorProductMatchingCalculator.calculate(
                .init(
                    requiredPowerW: 500,
                    roomTemperatureC: 20,
                    flowTemperatureC: 35,
                    returnTemperatureC: 20,
                    candidates: []
                )
            ) == nil
        )
    }
}
