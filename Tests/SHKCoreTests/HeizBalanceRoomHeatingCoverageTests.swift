import Testing
@testable import SHKCore

@Test func roomHeatingCoverageAggregatesAvailableAssignedAndTargetFlow() {
    let result = HeizBalanceRoomHeatingCoverageCalculator.calculate(
        .init(
            roomRequiredPowerW: 1500,
            availableSurfacePowersW: [1000, 800],
            assignedSurfacePowersW: [900, 600],
            targetVolumeFlowsLPH: [77.4, 51.6]
        )
    )

    #expect(result != nil)
    #expect(result!.availablePowerW == 1800)
    #expect(result!.availableMarginW == 300)
    #expect(abs(result!.availableCoverageRatio - 1.2) < 0.0001)
    #expect(result!.assignedPowerW == 1500)
    #expect(result!.assignmentDifferenceW == 0)
    #expect(abs(result!.totalTargetVolumeFlowLPH - 129) < 0.0001)
    #expect(result!.capacitySufficient)
}

@Test func roomHeatingCoverageShowsUnderCapacityAndAssignmentGap() {
    let result = HeizBalanceRoomHeatingCoverageCalculator.calculate(
        .init(
            roomRequiredPowerW: 1200,
            availableSurfacePowersW: [900],
            assignedSurfacePowersW: [700],
            targetVolumeFlowsLPH: [60]
        )
    )

    #expect(result != nil)
    #expect(result!.capacitySufficient == false)
    #expect(result!.availableMarginW == -300)
    #expect(result!.assignmentDifferenceW == -500)
}

@Test func roomHeatingCoverageIgnoresInvalidSurfaceValuesAndRejectsInvalidRoomPower() {
    let result = HeizBalanceRoomHeatingCoverageCalculator.calculate(
        .init(
            roomRequiredPowerW: 1000,
            availableSurfacePowersW: [800, -.infinity, -20],
            assignedSurfacePowersW: [600, .nan, 0],
            targetVolumeFlowsLPH: [50, .infinity, -1]
        )
    )

    #expect(result != nil)
    #expect(result!.availablePowerW == 800)
    #expect(result!.assignedPowerW == 600)
    #expect(result!.totalTargetVolumeFlowLPH == 50)

    #expect(
        HeizBalanceRoomHeatingCoverageCalculator.calculate(
            .init(roomRequiredPowerW: 0, availableSurfacePowersW: [], assignedSurfacePowersW: [], targetVolumeFlowsLPH: [])
        ) == nil
    )
}
