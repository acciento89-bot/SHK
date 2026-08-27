import Foundation

enum HeizBalanceRoomHeatingCoverageCalculator {
    struct Input: Sendable, Equatable {
        var roomRequiredPowerW: Double
        var availableSurfacePowersW: [Double]
        var assignedSurfacePowersW: [Double]
        var targetVolumeFlowsLPH: [Double]
    }

    struct Result: Sendable, Equatable {
        var roomRequiredPowerW: Double
        var availablePowerW: Double
        var availableMarginW: Double
        var availableCoverageRatio: Double
        var assignedPowerW: Double
        var assignmentDifferenceW: Double
        var totalTargetVolumeFlowLPH: Double
        var capacitySufficient: Bool
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.roomRequiredPowerW > 0 else { return nil }

        let available = input.availableSurfacePowersW
            .filter { $0.isFinite && $0 > 0 }
            .reduce(0, +)
        let assigned = input.assignedSurfacePowersW
            .filter { $0.isFinite && $0 > 0 }
            .reduce(0, +)
        let targetFlow = input.targetVolumeFlowsLPH
            .filter { $0.isFinite && $0 > 0 }
            .reduce(0, +)

        return Result(
            roomRequiredPowerW: input.roomRequiredPowerW,
            availablePowerW: available,
            availableMarginW: available - input.roomRequiredPowerW,
            availableCoverageRatio: available / input.roomRequiredPowerW,
            assignedPowerW: assigned,
            assignmentDifferenceW: assigned - input.roomRequiredPowerW,
            totalTargetVolumeFlowLPH: targetFlow,
            capacitySufficient: available >= input.roomRequiredPowerW
        )
    }
}
