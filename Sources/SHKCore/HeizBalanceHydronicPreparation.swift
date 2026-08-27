import Foundation

enum HeizBalanceHydronicPreparationCalculator {
    struct Input: Sendable, Equatable {
        var requiredPowerW: Double
        var availablePowerW: Double
        var flowTemperatureC: Double
        var returnTemperatureC: Double
    }

    struct Result: Sendable, Equatable {
        var requiredPowerW: Double
        var availablePowerW: Double
        var capacityMarginW: Double
        var capacityRatio: Double
        var targetVolumeFlowLPH: Double
        var capacitySufficient: Bool
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.requiredPowerW > 0,
              input.availablePowerW >= 0,
              input.flowTemperatureC > input.returnTemperatureC else {
            return nil
        }

        let waterDeltaT = input.flowTemperatureC - input.returnTemperatureC
        let targetVolumeFlow = RadiatorCalculator.volumeFlowLPH(
            powerW: input.requiredPowerW,
            waterDeltaTK: waterDeltaT
        )
        guard targetVolumeFlow > 0 else { return nil }

        let ratio = input.availablePowerW / input.requiredPowerW
        return Result(
            requiredPowerW: input.requiredPowerW,
            availablePowerW: input.availablePowerW,
            capacityMarginW: input.availablePowerW - input.requiredPowerW,
            capacityRatio: ratio,
            targetVolumeFlowLPH: targetVolumeFlow,
            capacitySufficient: input.availablePowerW >= input.requiredPowerW
        )
    }
}
