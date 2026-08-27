import Foundation

struct HeizBalanceTemperatureScenarioReportSnapshot: Codable, Hashable {
    static let schemaVersion = "technical-temperature-scenarios-v1"
    static let calculationProfileVersion = "explicit-flow-return-emitter-sizing-v1"

    var schema: String
    var calculationProfile: String
    var generatedAt: Date
    var projectID: UUID
    var projectName: String
    var technicalPreparationOnly: Bool
    var scenarios: [ScenarioData]

    struct ScenarioData: Codable, Hashable, Identifiable {
        var id: String { "\(flowTemperatureC)-\(returnTemperatureC)-\(title)" }
        var title: String
        var flowTemperatureC: Double
        var returnTemperatureC: Double
        var surfaceCount: Int
        var evaluableSurfaceCount: Int
        var sufficientSurfaceCount: Int
        var coverageComplete: Bool
        var allSufficient: Bool
        var limitingSurfaceName: String?
        var limitingCapacityRatio: Double?
        var limitingRequiredNominalPowerDeltaT50W: Double?
        var limitingNominalPowerFactor: Double?
        var surfaces: [SurfaceData]
    }

    struct SurfaceData: Codable, Hashable, Identifiable {
        var id: UUID
        var floorName: String
        var roomName: String
        var surfaceName: String
        var availablePowerW: Double?
        var capacityRatio: Double?
        var sufficient: Bool?
        var requiredNominalPowerDeltaT50W: Double?
        var nominalPowerFactor: Double?
        var missingInputs: [String]

        var displayName: String {
            "\(roomName) · \(surfaceName)"
        }
    }
}

extension HeizBalanceProject {
    func temperatureScenarioReportSnapshot(
        generatedAt: Date = Date()
    ) -> HeizBalanceTemperatureScenarioReportSnapshot {
        let scenarios = reportTemperatureScenarios()
        let scenarioData = scenarios.map { scenario in
            let summary = temperatureScenarioSummary(scenario)
            let limiting = summary.limitingEntry

            return HeizBalanceTemperatureScenarioReportSnapshot.ScenarioData(
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
        }

        return HeizBalanceTemperatureScenarioReportSnapshot(
            schema: HeizBalanceTemperatureScenarioReportSnapshot.schemaVersion,
            calculationProfile: HeizBalanceTemperatureScenarioReportSnapshot.calculationProfileVersion,
            generatedAt: generatedAt,
            projectID: id,
            projectName: name,
            technicalPreparationOnly: true,
            scenarios: scenarioData
        )
    }

    private func reportTemperatureScenarios() -> [HeizBalanceTemperatureScenario] {
        var values: [HeizBalanceTemperatureScenario] = []

        func appendUnique(_ candidate: HeizBalanceTemperatureScenario) {
            guard !values.contains(where: {
                abs($0.flowTemperatureC - candidate.flowTemperatureC) < 0.001
                    && abs($0.returnTemperatureC - candidate.returnTemperatureC) < 0.001
            }) else { return }
            values.append(candidate)
        }

        if let flow = retrofitTargetFlowTemperatureC,
           let returnTemperature = retrofitTargetReturnTemperatureC,
           flow > returnTemperature {
            let sourceSuffix: String = {
                guard let source = retrofitTargetTemperatureSource else { return "" }
                return " · \(source.title)"
            }()
            appendUnique(
                .init(
                    title: "Sanierungsziel\(sourceSuffix)",
                    flowTemperatureC: flow,
                    returnTemperatureC: returnTemperature
                )
            )
        }

        if let flow = designFlowTemperatureC,
           let returnTemperature = designReturnTemperatureC,
           flow > returnTemperature {
            appendUnique(
                .init(
                    title: "Projekt",
                    flowTemperatureC: flow,
                    returnTemperatureC: returnTemperature
                )
            )
        }

        let presets: [HeizBalanceTemperatureScenario] = [
            .init(title: "50 / 40", flowTemperatureC: 50, returnTemperatureC: 40),
            .init(title: "45 / 35", flowTemperatureC: 45, returnTemperatureC: 35),
            .init(title: "45 / 40", flowTemperatureC: 45, returnTemperatureC: 40),
            .init(title: "40 / 35", flowTemperatureC: 40, returnTemperatureC: 35)
        ]

        for preset in presets {
            appendUnique(preset)
        }

        return values
    }
}
