import Foundation

struct HeizBalanceRoomHeatingCoverageState {
    var result: HeizBalanceRoomHeatingCoverageCalculator.Result
    var totalSurfaceCount: Int
    var validAvailableSurfaceCount: Int
    var assignedSurfaceCount: Int
    var targetFlowSurfaceCount: Int
}

extension HeizBalanceRoom {
    func heatingCoverage(
        requiredRoomPowerW: Double,
        designFlowTemperatureC: Double?,
        designReturnTemperatureC: Double?
    ) -> HeizBalanceRoomHeatingCoverageState? {
        let surfaces = heatingSurfaces ?? []
        guard !surfaces.isEmpty else { return nil }

        var availablePowers: [Double] = []
        var assignedPowers: [Double] = []
        var targetFlows: [Double] = []

        for surface in surfaces {
            if let technical = surface.technicalPreview(
                flowTemperatureC: designFlowTemperatureC,
                returnTemperatureC: designReturnTemperatureC,
                roomTemperatureC: targetTemperature
            ) {
                availablePowers.append(technical.availablePowerW)
            }

            if let assigned = surface.assignedRequiredPowerW, assigned > 0 {
                assignedPowers.append(assigned)
            }

            if let hydronic = surface.hydronicPreparation(
                flowTemperatureC: designFlowTemperatureC,
                returnTemperatureC: designReturnTemperatureC,
                roomTemperatureC: targetTemperature
            ) {
                targetFlows.append(hydronic.targetVolumeFlowLPH)
            }
        }

        guard let result = HeizBalanceRoomHeatingCoverageCalculator.calculate(
            .init(
                roomRequiredPowerW: requiredRoomPowerW,
                availableSurfacePowersW: availablePowers,
                assignedSurfacePowersW: assignedPowers,
                targetVolumeFlowsLPH: targetFlows
            )
        ) else {
            return nil
        }

        return HeizBalanceRoomHeatingCoverageState(
            result: result,
            totalSurfaceCount: surfaces.count,
            validAvailableSurfaceCount: availablePowers.count,
            assignedSurfaceCount: assignedPowers.count,
            targetFlowSurfaceCount: targetFlows.count
        )
    }
}

extension HeizBalanceProject {
    func room(id: UUID) -> HeizBalanceRoom? {
        for floor in floors {
            if let room = floor.rooms.first(where: { $0.id == id }) {
                return room
            }
        }
        return nil
    }
}
