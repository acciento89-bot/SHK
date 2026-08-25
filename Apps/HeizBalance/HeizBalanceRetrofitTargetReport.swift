import Foundation

extension HeizBalanceProject {
    func temperatureScenarioReportSnapshotWithRetrofitTarget(
        generatedAt: Date = Date()
    ) -> HeizBalanceTemperatureScenarioReportSnapshot {
        var snapshot = temperatureScenarioReportSnapshot(generatedAt: generatedAt)

        guard let flow = retrofitTargetFlowTemperatureC,
              let returnTemperature = retrofitTargetReturnTemperatureC,
              flow > returnTemperature else {
            return snapshot
        }

        let sourceSuffix: String = {
            guard let source = retrofitTargetTemperatureSource else { return "" }
            return " · \(source.title)"
        }()
        let targetTitle = "Sanierungsziel\(sourceSuffix)"

        if let existingIndex = snapshot.scenarios.firstIndex(where: {
            abs($0.flowTemperatureC - flow) < 0.001
                && abs($0.returnTemperatureC - returnTemperature) < 0.001
        }) {
            var target = snapshot.scenarios.remove(at: existingIndex)
            target.title = targetTitle
            snapshot.scenarios.insert(target, at: 0)
            return snapshot
        }

        let scenario = HeizBalanceTemperatureScenario(
            title: targetTitle,
            flowTemperatureC: flow,
            returnTemperatureC: returnTemperature
        )
        let summary = temperatureScenarioSummary(scenario)
        let limiting = summary.limitingEntry

        let targetData = HeizBalanceTemperatureScenarioReportSnapshot.ScenarioData(
            title: scenario.title,
            flowTemperatureC: scenario.flowTemperatureC,
            returnTemperatureC: scenario.returnTemperatureC,
            surfaceCount: summary.entries.count,
            evaluableSurfaceCount: summary.evaluableCount,
            sufficientSurfaceCount: summary.sufficientCount,
            coverageComplete: summary.complete,
            allSufficient: summary.allSufficient,
            limitingSurfaceName: limiting?.displayName,
            limitingCapacityRatio: limiting?.result?.capacityRatio,
            limitingRequiredNominalPowerDeltaT50W: limiting?.result?.requiredNominalPowerDeltaT50W,
            limitingNominalPowerFactor: limiting?.result?.nominalPowerFactor,
            surfaces: summary.entries.map { entry in
                .init(
                    id: entry.surfaceID,
                    floorName: entry.floorName,
                    roomName: entry.roomName,
                    surfaceName: entry.surfaceName,
                    availablePowerW: entry.result?.availablePowerW,
                    capacityRatio: entry.result?.capacityRatio,
                    sufficient: entry.result?.sufficient,
                    requiredNominalPowerDeltaT50W: entry.result?.requiredNominalPowerDeltaT50W,
                    nominalPowerFactor: entry.result?.nominalPowerFactor,
                    missingInputs: entry.missingInputs
                )
            }
        )

        snapshot.scenarios.insert(targetData, at: 0)
        return snapshot
    }
}
