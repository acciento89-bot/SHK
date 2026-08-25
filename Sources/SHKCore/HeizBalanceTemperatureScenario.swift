import Foundation

enum HeizBalanceTemperatureScenarioCalculator {
    struct Input: Sendable, Equatable {
        var nominalPowerDeltaT50W: Double
        var exponent: Double
        var requiredPowerW: Double
        var roomTemperatureC: Double
        var flowTemperatureC: Double
        var returnTemperatureC: Double
    }

    struct Result: Sendable, Equatable {
        var meanTemperatureDifferenceK: Double
        var availablePowerW: Double
        var capacityRatio: Double
        var sufficient: Bool
        var requiredNominalPowerDeltaT50W: Double
        var nominalPowerFactor: Double
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.nominalPowerDeltaT50W.isFinite,
              input.exponent.isFinite,
              input.requiredPowerW.isFinite,
              input.roomTemperatureC.isFinite,
              input.flowTemperatureC.isFinite,
              input.returnTemperatureC.isFinite,
              input.nominalPowerDeltaT50W > 0,
              input.exponent > 0,
              input.requiredPowerW > 0,
              input.flowTemperatureC > input.returnTemperatureC,
              input.returnTemperatureC > input.roomTemperatureC else {
            return nil
        }

        let meanDeltaT = RadiatorCalculator.meanTemperatureDifferenceK(
            flowC: input.flowTemperatureC,
            returnC: input.returnTemperatureC,
            roomC: input.roomTemperatureC
        )
        guard meanDeltaT.isFinite, meanDeltaT > 0 else { return nil }

        let correctionFactor = pow(meanDeltaT / 50, input.exponent)
        guard correctionFactor.isFinite, correctionFactor > 0 else { return nil }

        let availablePower = input.nominalPowerDeltaT50W * correctionFactor
        let requiredNominalPower = input.requiredPowerW / correctionFactor
        let capacityRatio = availablePower / input.requiredPowerW
        let nominalPowerFactor = requiredNominalPower / input.nominalPowerDeltaT50W

        guard availablePower.isFinite,
              requiredNominalPower.isFinite,
              capacityRatio.isFinite,
              nominalPowerFactor.isFinite else {
            return nil
        }

        return Result(
            meanTemperatureDifferenceK: meanDeltaT,
            availablePowerW: availablePower,
            capacityRatio: capacityRatio,
            sufficient: availablePower >= input.requiredPowerW,
            requiredNominalPowerDeltaT50W: requiredNominalPower,
            nominalPowerFactor: nominalPowerFactor
        )
    }
}
