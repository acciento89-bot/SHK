import Foundation

enum HeizBalanceValveSizingPreparationCalculator {
    struct Input: Sendable, Equatable {
        var targetVolumeFlowLPH: Double
        var valvePressureDropKPa: Double
        var densityKGPerM3: Double
    }

    struct Result: Sendable, Equatable {
        var targetVolumeFlowM3H: Double
        var valvePressureDropBar: Double
        var relativeDensity: Double
        var requiredKvM3H: Double
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.targetVolumeFlowLPH.isFinite,
              input.valvePressureDropKPa.isFinite,
              input.densityKGPerM3.isFinite,
              input.targetVolumeFlowLPH > 0,
              input.valvePressureDropKPa > 0,
              input.densityKGPerM3 > 0 else {
            return nil
        }

        let flowM3H = input.targetVolumeFlowLPH / 1000
        let pressureDropBar = input.valvePressureDropKPa / 100
        let relativeDensity = input.densityKGPerM3 / 1000
        let requiredKv = flowM3H * sqrt(relativeDensity / pressureDropBar)

        guard requiredKv.isFinite, requiredKv > 0 else { return nil }

        return Result(
            targetVolumeFlowM3H: flowM3H,
            valvePressureDropBar: pressureDropBar,
            relativeDensity: relativeDensity,
            requiredKvM3H: requiredKv
        )
    }
}
