import Foundation

struct HeizBalancePumpTechnicalMetricsCalculator {
    static let profileVersion = "pump-technical-metrics-v1"
    private static let gravityMS2 = 9.80665

    struct Input: Hashable {
        var volumeFlowM3H: Double
        var requiredHeadM: Double
        var availableHeadM: Double
        var fluidDensityKGPerM3: Double
        var electricalInputPowerW: Double?
        var documentedMinimumFlowM3H: Double?
        var documentedMaximumFlowM3H: Double?
    }

    struct Result: Hashable {
        var requiredHydraulicPowerW: Double
        var availableHydraulicPowerW: Double
        var headReserveM: Double
        var headReservePercent: Double?
        var electricalInputPowerW: Double?
        var requiredHydraulicToElectricalRatio: Double?
        var documentedFlowPosition: Double?
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.volumeFlowM3H.isFinite,
              input.volumeFlowM3H >= 0,
              input.requiredHeadM.isFinite,
              input.requiredHeadM >= 0,
              input.availableHeadM.isFinite,
              input.availableHeadM >= 0,
              input.fluidDensityKGPerM3.isFinite,
              input.fluidDensityKGPerM3 > 0,
              input.electricalInputPowerW.map({ $0.isFinite && $0 > 0 }) ?? true else {
            return nil
        }

        let volumeFlowM3S = input.volumeFlowM3H / 3_600
        let requiredHydraulicPowerW = input.fluidDensityKGPerM3
            * gravityMS2
            * volumeFlowM3S
            * input.requiredHeadM
        let availableHydraulicPowerW = input.fluidDensityKGPerM3
            * gravityMS2
            * volumeFlowM3S
            * input.availableHeadM
        let headReserveM = input.availableHeadM - input.requiredHeadM

        let headReservePercent: Double?
        if input.requiredHeadM > 0 {
            headReservePercent = headReserveM / input.requiredHeadM * 100
        } else {
            headReservePercent = nil
        }

        let requiredHydraulicToElectricalRatio: Double?
        if let electricalInputPowerW = input.electricalInputPowerW {
            requiredHydraulicToElectricalRatio = requiredHydraulicPowerW / electricalInputPowerW
        } else {
            requiredHydraulicToElectricalRatio = nil
        }

        let documentedFlowPosition: Double?
        if let minimum = input.documentedMinimumFlowM3H,
           let maximum = input.documentedMaximumFlowM3H,
           minimum.isFinite,
           maximum.isFinite,
           minimum >= 0,
           maximum > minimum,
           input.volumeFlowM3H >= minimum,
           input.volumeFlowM3H <= maximum {
            documentedFlowPosition = (input.volumeFlowM3H - minimum) / (maximum - minimum)
        } else {
            documentedFlowPosition = nil
        }

        return .init(
            requiredHydraulicPowerW: requiredHydraulicPowerW,
            availableHydraulicPowerW: availableHydraulicPowerW,
            headReserveM: headReserveM,
            headReservePercent: headReservePercent,
            electricalInputPowerW: input.electricalInputPowerW,
            requiredHydraulicToElectricalRatio: requiredHydraulicToElectricalRatio,
            documentedFlowPosition: documentedFlowPosition
        )
    }
}
