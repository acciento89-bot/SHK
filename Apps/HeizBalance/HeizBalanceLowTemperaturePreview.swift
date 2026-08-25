import SwiftUI

struct HeizBalanceLowTemperatureSurfaceEntry: Identifiable {
    var id: UUID
    var floorName: String
    var roomName: String
    var surfaceName: String
    var result: HeizBalanceLowTemperatureCheckCalculator.Result?
    var missingInputs: [String]

    var displayName: String {
        "\(roomName) · \(surfaceName)"
    }
}

struct HeizBalanceLowTemperatureProjectState {
    var waterTemperatureDifferenceK: Double?
    var entries: [HeizBalanceLowTemperatureSurfaceEntry]
    var limitingEntry: HeizBalanceLowTemperatureSurfaceEntry?

    var evaluableSurfaceCount: Int {
        entries.filter { $0.result != nil }.count
    }

    var coverageComplete: Bool {
        !entries.isEmpty && evaluableSurfaceCount == entries.count
    }

    var minimumSystemFlowTemperatureC: Double? {
        guard coverageComplete else { return nil }
        return limitingEntry?.result?.minimumFlowTemperatureC
    }

    var minimumSystemReturnTemperatureC: Double? {
        guard coverageComplete else { return nil }
        return limitingEntry?.result?.minimumReturnTemperatureC
    }

    var comparisonSufficient: Bool? {
        guard coverageComplete else { return nil }
        let values = entries.compactMap { $0.result?.comparisonSufficient }
        guard values.count == entries.count else { return nil }
        return values.allSatisfy { $0 }
    }
}

extension HeizBalanceProject {
    func lowTemperatureProjectState(
        comparisonFlowTemperatureC: Double? = nil
    ) -> HeizBalanceLowTemperatureProjectState {
        guard let flow = designFlowTemperatureC,
              let returnTemperature = designReturnTemperatureC,
              flow > returnTemperature else {
            return HeizBalanceLowTemperatureProjectState(
                waterTemperatureDifferenceK: nil,
                entries: [],
                limitingEntry: nil
            )
        }

        let spread = flow - returnTemperature
        var entries: [HeizBalanceLowTemperatureSurfaceEntry] = []

        for floor in floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    var missing: [String] = []
                    if surface.nominalPowerDeltaT50W == nil { missing.append("Nennleistung ΔT50 fehlt") }
                    if surface.exponent == nil { missing.append("Exponent n fehlt") }
                    if surface.assignedRequiredPowerW == nil { missing.append("Zugeordnete erforderliche Leistung fehlt") }

                    let result: HeizBalanceLowTemperatureCheckCalculator.Result?
                    if let nominalPower = surface.nominalPowerDeltaT50W,
                       let exponent = surface.exponent,
                       let requiredPower = surface.assignedRequiredPowerW {
                        result = HeizBalanceLowTemperatureCheckCalculator.calculate(
                            .init(
                                nominalPowerDeltaT50W: nominalPower,
                                exponent: exponent,
                                requiredPowerW: requiredPower,
                                roomTemperatureC: room.targetTemperature,
                                waterTemperatureDifferenceK: spread,
                                comparisonFlowTemperatureC: comparisonFlowTemperatureC
                            )
                        )
                        if result == nil && missing.isEmpty {
                            missing.append("Temperaturfenster mit dieser Spreizung nicht technisch auswertbar")
                        }
                    } else {
                        result = nil
                    }

                    entries.append(
                        HeizBalanceLowTemperatureSurfaceEntry(
                            id: surface.id,
                            floorName: floor.name,
                            roomName: room.name,
                            surfaceName: surface.name,
                            result: result,
                            missingInputs: missing
                        )
                    )
                }
            }
        }

        let limiting = entries
            .compactMap { entry -> HeizBalanceLowTemperatureSurfaceEntry? in
                entry.result == nil ? nil : entry
            }
            .max {
                ($0.result?.minimumFlowTemperatureC ?? -.infinity)
                    < ($1.result?.minimumFlowTemperatureC ?? -.infinity)
            }

        return HeizBalanceLowTemperatureProjectState(
            waterTemperatureDifferenceK: spread,
            entries: entries,
            limitingEntry: limiting
        )
    }
}

struct HeizBalanceLowTemperaturePreviewView: View {
    let project: HeizBalanceProject
    @State private var comparisonFlowTemperatureC: Double?

    init(project: HeizBalanceProject) {
        self.project = project
        _comparisonFlowTemperatureC = State(initialValue: project.designFlowTemperatureC)
    }

    private var state: HeizBalanceLowTemperatureProjectState {
        project.lowTemperatureProjectState(
            comparisonFlowTemperatureC: comparisonFlowTemperatureC
        )
    }

    var body: some View {
        List {
            Section {
                if let spread = state.waterTemperatureDifferenceK {
                    LabeledContent("Verwendete Spreizung") {
                        Text(spread.formatted(.number.precision(.fractionLength(0...1))) + " K")
                    }
                    OptionalDecimalField(
                        title: "Vergleich Vorlauf",
                        value: $comparisonFlowTemperatureC,
                        unit: "°C"
                    )
                    if let comparisonFlowTemperatureC {
                        LabeledContent("Vergleich Rücklauf") {
                            Text((comparisonFlowTemperatureC - spread).formatted(.number.precision(.fractionLength(0...1))) + " °C")
                        }
                    }
                } else {
                    Label("Im Projekt fehlen gültige Vorlauf-/Rücklauftemperaturen.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Temperaturbasis")
            } footer: {
                Text("Der Check hält die im Projekt gewählte Wasserspreizung konstant. Er verändert weder Heizlast noch Leistungszuordnung automatisch.")
            }

            Section {
                if state.entries.isEmpty {
                    Text("Noch keine Heizflächen für den Niedertemperatur-Check vorhanden.")
                        .foregroundStyle(.secondary)
                } else {
                    LabeledContent("Heizflächen auswertbar") {
                        Text("\(state.evaluableSurfaceCount) / \(state.entries.count)")
                    }

                    if let minimumFlow = state.minimumSystemFlowTemperatureC,
                       let minimumReturn = state.minimumSystemReturnTemperatureC,
                       let limiting = state.limitingEntry {
                        LabeledContent("Minimaler System-Vorlauf") {
                            Text(minimumFlow.formatted(.number.precision(.fractionLength(1))) + " °C")
                                .fontWeight(.bold)
                        }
                        LabeledContent("Zugehöriger Rücklauf") {
                            Text(minimumReturn.formatted(.number.precision(.fractionLength(1))) + " °C")
                        }
                        LabeledContent("Begrenzende Heizfläche") {
                            Text(limiting.displayName)
                                .multilineTextAlignment(.trailing)
                        }

                        if let sufficient = state.comparisonSufficient,
                           let comparisonFlowTemperatureC,
                           let spread = state.waterTemperatureDifferenceK {
                            if sufficient {
                                Label(
                                    "\(comparisonFlowTemperatureC.formatted(.number.precision(.fractionLength(0...1)))) / \((comparisonFlowTemperatureC - spread).formatted(.number.precision(.fractionLength(0...1)))) °C deckt alle zugeordneten Heizflächenleistungen.",
                                    systemImage: "checkmark.circle.fill"
                                )
                                .foregroundStyle(.green)
                            } else {
                                Label(
                                    "\(comparisonFlowTemperatureC.formatted(.number.precision(.fractionLength(0...1)))) / \((comparisonFlowTemperatureC - spread).formatted(.number.precision(.fractionLength(0...1)))) °C reicht für mindestens eine Heizfläche nicht aus.",
                                    systemImage: "exclamationmark.triangle.fill"
                                )
                                .foregroundStyle(.orange)
                            }
                        }
                    } else {
                        Label("Eine System-Minimaltemperatur wird erst ausgegeben, wenn jede Heizfläche vollständig auswertbar ist.", systemImage: "circle.dashed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Niedertemperatur-Systemcheck")
            } footer: {
                Text("Technischer Heizflächencheck für Wärmepumpen-/Niedertemperaturplanung. Keine Wärmepumpenauslegung, keine COP-/Bivalenzbewertung und kein normativer Heizlastnachweis.")
            }

            Section("Heizflächen") {
                ForEach(state.entries) { entry in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.displayName)
                            .font(.headline)
                        Text(entry.floorName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let result = entry.result {
                            HStack {
                                Text("Mind. VL / RL")
                                Spacer()
                                Text(
                                    result.minimumFlowTemperatureC.formatted(.number.precision(.fractionLength(1)))
                                        + " / "
                                        + result.minimumReturnTemperatureC.formatted(.number.precision(.fractionLength(1)))
                                        + " °C"
                                )
                                .fontWeight(.semibold)
                            }
                            .font(.caption)

                            if let ratio = result.comparisonCapacityRatio,
                               let sufficient = result.comparisonSufficient {
                                HStack {
                                    Text("Deckung Vergleich")
                                    Spacer()
                                    Text((ratio * 100).formatted(.number.precision(.fractionLength(0))) + " %")
                                        .foregroundStyle(sufficient ? .secondary : .orange)
                                }
                                .font(.caption)
                            }
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
            }
        }
        .navigationTitle("Niedertemperatur-Check")
        .navigationBarTitleDisplayMode(.inline)
    }
}
