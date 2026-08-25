import SwiftUI

struct HeizBalanceTemperatureScenario: Identifiable, Hashable {
    var id: String { "\(flowTemperatureC)-\(returnTemperatureC)-\(title)" }
    var title: String
    var flowTemperatureC: Double
    var returnTemperatureC: Double

    var displayTemperature: String {
        flowTemperatureC.formatted(.number.precision(.fractionLength(0...1)))
            + " / "
            + returnTemperatureC.formatted(.number.precision(.fractionLength(0...1)))
            + " °C"
    }
}

struct HeizBalanceTemperatureScenarioSurfaceResult: Identifiable {
    var id: String { "\(surfaceID.uuidString)-\(scenario.id)" }
    var surfaceID: UUID
    var floorName: String
    var roomName: String
    var surfaceName: String
    var scenario: HeizBalanceTemperatureScenario
    var result: HeizBalanceTemperatureScenarioCalculator.Result?
    var missingInputs: [String]

    var displayName: String {
        "\(roomName) · \(surfaceName)"
    }
}

struct HeizBalanceTemperatureScenarioSummary: Identifiable {
    var id: String { scenario.id }
    var scenario: HeizBalanceTemperatureScenario
    var entries: [HeizBalanceTemperatureScenarioSurfaceResult]

    var evaluableCount: Int {
        entries.filter { $0.result != nil }.count
    }

    var sufficientCount: Int {
        entries.filter { $0.result?.sufficient == true }.count
    }

    var complete: Bool {
        !entries.isEmpty && evaluableCount == entries.count
    }

    var allSufficient: Bool {
        complete && sufficientCount == entries.count
    }

    var limitingEntry: HeizBalanceTemperatureScenarioSurfaceResult? {
        entries
            .filter { $0.result != nil }
            .min {
                ($0.result?.capacityRatio ?? Double.infinity)
                    < ($1.result?.capacityRatio ?? Double.infinity)
            }
    }
}

extension HeizBalanceProject {
    func temperatureScenarioSummary(
        _ scenario: HeizBalanceTemperatureScenario
    ) -> HeizBalanceTemperatureScenarioSummary {
        var entries: [HeizBalanceTemperatureScenarioSurfaceResult] = []

        for floor in floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    var missing: [String] = []
                    if surface.nominalPowerDeltaT50W == nil { missing.append("Nennleistung ΔT50 fehlt") }
                    if surface.exponent == nil { missing.append("Exponent n fehlt") }
                    if surface.assignedRequiredPowerW == nil { missing.append("Zugeordnete erforderliche Leistung fehlt") }

                    let result: HeizBalanceTemperatureScenarioCalculator.Result?
                    if let nominalPower = surface.nominalPowerDeltaT50W,
                       let exponent = surface.exponent,
                       let requiredPower = surface.assignedRequiredPowerW {
                        result = HeizBalanceTemperatureScenarioCalculator.calculate(
                            .init(
                                nominalPowerDeltaT50W: nominalPower,
                                exponent: exponent,
                                requiredPowerW: requiredPower,
                                roomTemperatureC: room.targetTemperature,
                                flowTemperatureC: scenario.flowTemperatureC,
                                returnTemperatureC: scenario.returnTemperatureC
                            )
                        )
                        if result == nil && missing.isEmpty {
                            missing.append("Temperaturniveau für diesen Raum nicht auswertbar")
                        }
                    } else {
                        result = nil
                    }

                    entries.append(
                        .init(
                            surfaceID: surface.id,
                            floorName: floor.name,
                            roomName: room.name,
                            surfaceName: surface.name,
                            scenario: scenario,
                            result: result,
                            missingInputs: missing
                        )
                    )
                }
            }
        }

        return .init(scenario: scenario, entries: entries)
    }
}

struct HeizBalanceTemperatureScenarioView: View {
    let project: HeizBalanceProject

    @State private var customFlowTemperatureC: Double? = 45
    @State private var customReturnTemperatureC: Double? = 35

    private var scenarios: [HeizBalanceTemperatureScenario] {
        var values: [HeizBalanceTemperatureScenario] = []

        if let flow = project.designFlowTemperatureC,
           let returnTemperature = project.designReturnTemperatureC,
           flow > returnTemperature {
            values.append(
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

        for preset in presets where !values.contains(where: {
            abs($0.flowTemperatureC - preset.flowTemperatureC) < 0.001
                && abs($0.returnTemperatureC - preset.returnTemperatureC) < 0.001
        }) {
            values.append(preset)
        }

        if let flow = customFlowTemperatureC,
           let returnTemperature = customReturnTemperatureC,
           flow > returnTemperature,
           !values.contains(where: {
               abs($0.flowTemperatureC - flow) < 0.001
                   && abs($0.returnTemperatureC - returnTemperature) < 0.001
           }) {
            values.append(
                .init(
                    title: "Benutzerdefiniert",
                    flowTemperatureC: flow,
                    returnTemperatureC: returnTemperature
                )
            )
        }

        return values
    }

    private var summaries: [HeizBalanceTemperatureScenarioSummary] {
        scenarios.map { project.temperatureScenarioSummary($0) }
    }

    var body: some View {
        List {
            Section {
                OptionalDecimalField(
                    title: "Eigener Vorlauf",
                    value: $customFlowTemperatureC,
                    unit: "°C"
                )
                OptionalDecimalField(
                    title: "Eigener Rücklauf",
                    value: $customReturnTemperatureC,
                    unit: "°C"
                )

                if let flow = customFlowTemperatureC,
                   let returnTemperature = customReturnTemperatureC,
                   flow <= returnTemperature {
                    Label("Vorlauf muss über Rücklauf liegen.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(Color.orange)
                }
            } header: {
                Text("Szenarien")
            } footer: {
                Text("Jedes Temperaturniveau wird direkt gegen die zugeordnete erforderliche Leistung jeder Heizfläche geprüft. Es werden keine Herstellerabmessungen oder Ersatzmodelle erfunden.")
            }

            ForEach(summaries, id: \.id) { summary in
                Section {
                    scenarioSummary(summary)

                    NavigationLink {
                        HeizBalanceTemperatureScenarioDetailView(summary: summary)
                    } label: {
                        Label("Heizflächen im Detail", systemImage: "radiator")
                    }
                } header: {
                    HStack {
                        Text(summary.scenario.title)
                        Spacer()
                        Text(summary.scenario.displayTemperature)
                    }
                }
            }
        }
        .navigationTitle("Temperatur-Szenarien")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func scenarioSummary(_ summary: HeizBalanceTemperatureScenarioSummary) -> some View {
        if summary.entries.isEmpty {
            Text("Noch keine Heizflächen vorhanden.")
                .foregroundStyle(.secondary)
        } else {
            LabeledContent("Auswertbar") {
                Text("\(summary.evaluableCount) / \(summary.entries.count)")
            }
            LabeledContent("Ausreichend") {
                Text("\(summary.sufficientCount) / \(summary.entries.count)")
            }

            if summary.complete {
                Label(
                    summary.allSufficient
                        ? "Alle Heizflächen decken ihre zugeordnete Leistung."
                        : "Mindestens eine Heizfläche ist bei diesem Temperaturniveau zu klein.",
                    systemImage: summary.allSufficient ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(summary.allSufficient ? Color.green : Color.orange)

                if let limiting = summary.limitingEntry,
                   let result = limiting.result {
                    LabeledContent("Begrenzend") {
                        Text(limiting.displayName)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Deckungsgrad") {
                        Text(scenarioPercentText(result.capacityRatio))
                    }

                    if !result.sufficient {
                        LabeledContent("Benötigte ΔT50-Nennleistung") {
                            Text(scenarioWattText(result.requiredNominalPowerDeltaT50W))
                                .fontWeight(.semibold)
                        }
                        LabeledContent("Nennleistungsfaktor") {
                            Text(scenarioFactorText(result.nominalPowerFactor))
                                .fontWeight(.semibold)
                        }
                    }
                }
            } else {
                Label("Systemaussage gesperrt, bis alle Heizflächen auswertbar sind.", systemImage: "lock.trianglebadge.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct HeizBalanceTemperatureScenarioDetailView: View {
    let summary: HeizBalanceTemperatureScenarioSummary

    var body: some View {
        List {
            Section {
                LabeledContent("Temperaturniveau") {
                    Text(summary.scenario.displayTemperature)
                }
                LabeledContent("Heizflächen auswertbar") {
                    Text("\(summary.evaluableCount) / \(summary.entries.count)")
                }
            }

            Section("Heizflächen") {
                ForEach(summary.entries, id: \.id) { entry in
                    HeizBalanceTemperatureScenarioSurfaceRow(entry: entry)
                }
            }
        }
        .navigationTitle(summary.scenario.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HeizBalanceTemperatureScenarioSurfaceRow: View {
    let entry: HeizBalanceTemperatureScenarioSurfaceResult

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(entry.displayName)
                .font(.headline)
            Text(entry.floorName)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let result = entry.result {
                resultContent(result)
            } else {
                ForEach(entry.missingInputs, id: \.self) { missing in
                    Text("• \(missing)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private func resultContent(_ result: HeizBalanceTemperatureScenarioCalculator.Result) -> some View {
        LabeledContent("Verfügbar") {
            Text(scenarioWattText(result.availablePowerW))
        }
        .font(.caption)

        LabeledContent("Deckungsgrad") {
            Text(scenarioPercentText(result.capacityRatio))
                .foregroundStyle(result.sufficient ? Color.secondary : Color.orange)
        }
        .font(.caption)

        if result.sufficient {
            Label("Heizfläche ausreichend", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(Color.green)
        } else {
            LabeledContent("Erforderlich bei ΔT50") {
                Text(scenarioWattText(result.requiredNominalPowerDeltaT50W))
                    .fontWeight(.semibold)
            }
            .font(.caption)

            LabeledContent("Faktor zur aktuellen Nennleistung") {
                Text(scenarioFactorText(result.nominalPowerFactor))
                    .fontWeight(.semibold)
            }
            .font(.caption)
        }
    }
}

private func scenarioPercentText(_ ratio: Double) -> String {
    let percent = ratio * 100
    return percent.formatted(.number.precision(.fractionLength(0))) + " %"
}

private func scenarioWattText(_ powerW: Double) -> String {
    powerW.formatted(.number.precision(.fractionLength(0))) + " W"
}

private func scenarioFactorText(_ factor: Double) -> String {
    "×" + factor.formatted(.number.precision(.fractionLength(2)))
}
