import Foundation

enum HeizBalanceLowTemperatureCheckCalculator {
    struct Input: Sendable, Equatable {
        var nominalPowerDeltaT50W: Double
        var exponent: Double
        var requiredPowerW: Double
        var roomTemperatureC: Double
        var waterTemperatureDifferenceK: Double
        var comparisonFlowTemperatureC: Double?
    }

    struct Result: Sendable, Equatable {
        var requiredMeanTemperatureDifferenceK: Double
        var minimumFlowTemperatureC: Double
        var minimumReturnTemperatureC: Double
        var comparisonAvailablePowerW: Double?
        var comparisonCapacityRatio: Double?
        var comparisonSufficient: Bool?
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.nominalPowerDeltaT50W.isFinite,
              input.exponent.isFinite,
              input.requiredPowerW.isFinite,
              input.roomTemperatureC.isFinite,
              input.waterTemperatureDifferenceK.isFinite,
              input.nominalPowerDeltaT50W > 0,
              input.exponent > 0,
              input.requiredPowerW > 0,
              input.waterTemperatureDifferenceK > 0 else {
            return nil
        }

        let requiredMeanDeltaT = 50 * pow(
            input.requiredPowerW / input.nominalPowerDeltaT50W,
            1 / input.exponent
        )
        guard requiredMeanDeltaT.isFinite, requiredMeanDeltaT > 0 else { return nil }

        let minimumFlow = input.roomTemperatureC
            + requiredMeanDeltaT
            + input.waterTemperatureDifferenceK / 2
        let minimumReturn = minimumFlow - input.waterTemperatureDifferenceK

        guard minimumFlow.isFinite,
              minimumReturn.isFinite,
              minimumReturn > input.roomTemperatureC else {
            return nil
        }

        var comparisonAvailablePowerW: Double?
        var comparisonCapacityRatio: Double?
        var comparisonSufficient: Bool?

        if let comparisonFlow = input.comparisonFlowTemperatureC {
            guard comparisonFlow.isFinite else { return nil }
            let comparisonReturn = comparisonFlow - input.waterTemperatureDifferenceK

            if comparisonReturn > input.roomTemperatureC {
                let availablePower = RadiatorCalculator.correctedPowerW(
                    nominalPowerDeltaT50W: input.nominalPowerDeltaT50W,
                    flowC: comparisonFlow,
                    returnC: comparisonReturn,
                    roomC: input.roomTemperatureC,
                    exponent: input.exponent
                )

                if availablePower.isFinite, availablePower > 0 {
                    comparisonAvailablePowerW = availablePower
                    comparisonCapacityRatio = availablePower / input.requiredPowerW
                    comparisonSufficient = availablePower >= input.requiredPowerW
                }
            }
        }

        return Result(
            requiredMeanTemperatureDifferenceK: requiredMeanDeltaT,
            minimumFlowTemperatureC: minimumFlow,
            minimumReturnTemperatureC: minimumReturn,
            comparisonAvailablePowerW: comparisonAvailablePowerW,
            comparisonCapacityRatio: comparisonCapacityRatio,
            comparisonSufficient: comparisonSufficient
        )
    }
}
