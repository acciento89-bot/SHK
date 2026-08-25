import Foundation

enum HeizBalanceHeatingSurfacePreviewCalculator {
    struct Input: Sendable, Equatable {
        var nominalPowerDeltaT50W: Double
        var exponent: Double
        var flowTemperatureC: Double
        var returnTemperatureC: Double
        var roomTemperatureC: Double
    }

    struct Result: Sendable, Equatable {
        var availablePowerW: Double
        var waterTemperatureDifferenceK: Double
        var volumeFlowLPH: Double
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.nominalPowerDeltaT50W > 0,
              input.exponent > 0,
              input.flowTemperatureC > input.returnTemperatureC,
              input.returnTemperatureC > input.roomTemperatureC else {
            return nil
        }

        let availablePower = RadiatorCalculator.correctedPowerW(
            nominalPowerDeltaT50W: input.nominalPowerDeltaT50W,
            flowC: input.flowTemperatureC,
            returnC: input.returnTemperatureC,
            roomC: input.roomTemperatureC,
            exponent: input.exponent
        )
        let waterDeltaT = input.flowTemperatureC - input.returnTemperatureC
        guard availablePower > 0, waterDeltaT > 0 else { return nil }

        let volumeFlow = RadiatorCalculator.volumeFlowLPH(
            powerW: availablePower,
            waterDeltaTK: waterDeltaT
        )

        return Result(
            availablePowerW: availablePower,
            waterTemperatureDifferenceK: waterDeltaT,
            volumeFlowLPH: volumeFlow
        )
    }
}
