import SwiftUI

extension HeizBalanceHeatingSurface {
    func technicalPreview(
        flowTemperatureC: Double?,
        returnTemperatureC: Double?,
        roomTemperatureC: Double
    ) -> HeizBalanceHeatingSurfacePreviewCalculator.Result? {
        guard let nominalPowerDeltaT50W,
              let exponent,
              let flowTemperatureC,
              let returnTemperatureC else {
            return nil
        }

        return HeizBalanceHeatingSurfacePreviewCalculator.calculate(
            .init(
                nominalPowerDeltaT50W: nominalPowerDeltaT50W,
                exponent: exponent,
                flowTemperatureC: flowTemperatureC,
                returnTemperatureC: returnTemperatureC,
                roomTemperatureC: roomTemperatureC
            )
        )
    }

    func hydronicPreparation(
        flowTemperatureC: Double?,
        returnTemperatureC: Double?,
        roomTemperatureC: Double
    ) -> HeizBalanceHydronicPreparationCalculator.Result? {
        guard let assignedRequiredPowerW,
              let flowTemperatureC,
              let returnTemperatureC,
              let preview = technicalPreview(
                flowTemperatureC: flowTemperatureC,
                returnTemperatureC: returnTemperatureC,
                roomTemperatureC: roomTemperatureC
              ) else {
            return nil
        }

        return HeizBalanceHydronicPreparationCalculator.calculate(
            .init(
                requiredPowerW: assignedRequiredPowerW,
                availablePowerW: preview.availablePowerW,
                flowTemperatureC: flowTemperatureC,
                returnTemperatureC: returnTemperatureC
            )
        )
    }
}

struct HeizBalanceHeatingSurfaceEditor: View {
    @Binding var surface: HeizBalanceHeatingSurface
    let designFlowTemperatureC: Double?
    let designReturnTemperatureC: Double?
    let roomTemperatureC: Double

    private var preview: HeizBalanceHeatingSurfacePreviewCalculator.Result? {
        surface.technicalPreview(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: roomTemperatureC
        )
    }

    private var hydronicPreparation: HeizBalanceHydronicPreparationCalculator.Result? {
        surface.hydronicPreparation(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: roomTemperatureC
        )
    }

    private var missingPreviewInputs: [String] {
        var items: [String] = []
        if surface.nominalPowerDeltaT50W == nil { items.append("Nennleistung ΔT50 fehlt") }
        if surface.exponent == nil { items.append("Heizkörperexponent n fehlt") }
        if designFlowTemperatureC == nil { items.append("Projekt-Vorlauftemperatur fehlt") }
        if designReturnTemperatureC == nil { items.append("Projekt-Rücklauftemperatur fehlt") }
        return items
    }

    var body: some View {
        Form {
            Section("Heizfläche") {
                Picker("Art", selection: $surface.kind) {
                    ForEach(HeizBalanceHeatingSurface.Kind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                TextField("Bezeichnung", text: $surface.name)
                TextField("Hersteller", text: $surface.manufacturer)
                TextField("Modell / Typ", text: $surface.model)
            }

            Section {
                OptionalDecimalField(
                    title: "Nennleistung ΔT50",
                    value: $surface.nominalPowerDeltaT50W,
                    unit: "W"
                )
                OptionalDecimalField(
                    title: "Exponent n",
                    value: $surface.exponent,
                    unit: ""
                )
                InputSourcePicker(title: "Quelle Leistung", selection: $surface.powerSource)
            } header: {
                Text("Leistungsdaten")
            } footer: {
                Text("Nennleistung und Exponent werden als dokumentierte Hersteller- oder Projektwerte erfasst. HeizBalance hinterlegt hier keine erfundenen Typen- oder Leistungstabellen.")
            }

            Section {
                OptionalDecimalField(
                    title: "Zugeordnete erforderliche Leistung",
                    value: $surface.assignedRequiredPowerW,
                    unit: "W"
                )
            } header: {
                Text("Leistungszuordnung")
            } footer: {
                Text("Dieser Wert ist die Leistung, die diese konkrete Heizfläche im späteren Abgleich bereitstellen soll. Er wird bewusst getrennt von der maximal verfügbaren Heizflächenleistung gespeichert.")
            }

            Section {
                if let flow = designFlowTemperatureC, let returnTemperature = designReturnTemperatureC {
                    LabeledContent("Systemtemperaturen") {
                        Text("\(flow.formatted(.number.precision(.fractionLength(0...1)))) / \(returnTemperature.formatted(.number.precision(.fractionLength(0...1)))) °C")
                    }
                }
                LabeledContent("Raumtemperatur") {
                    Text(roomTemperatureC.formatted(.number.precision(.fractionLength(0...1))) + " °C")
                }

                if let preview {
                    LabeledContent("Verfügbare Leistung") {
                        Text(preview.availablePowerW.formatted(.number.precision(.fractionLength(0))) + " W")
                            .fontWeight(.semibold)
                    }
                    LabeledContent("Wasserspreizung") {
                        Text(preview.waterTemperatureDifferenceK.formatted(.number.precision(.fractionLength(0...1))) + " K")
                    }
                    LabeledContent("Volumenstrom bei verfügbarer Leistung") {
                        Text(preview.volumeFlowLPH.formatted(.number.precision(.fractionLength(0))) + " l/h")
                    }
                } else if missingPreviewInputs.isEmpty {
                    Label("Temperatur- oder Leistungsdaten ergeben keine gültige technische Vorberechnung.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    ForEach(missingPreviewInputs, id: \.self) { item in
                        Label(item, systemImage: "circle.dashed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Technische Heizflächen-Vorbereitung")
            } footer: {
                Text("Die verfügbare Leistung beschreibt die Heizfläche bei den eingegebenen Systemtemperaturen. Sie ist nicht automatisch die für den hydraulischen Abgleich benötigte Leistung.")
            }

            Section {
                if let hydronicPreparation {
                    LabeledContent("Erforderliche Leistung") {
                        Text(hydronicPreparation.requiredPowerW.formatted(.number.precision(.fractionLength(0))) + " W")
                    }
                    LabeledContent("Leistungsreserve") {
                        Text(hydronicPreparation.capacityMarginW.formatted(.number.precision(.fractionLength(0))) + " W")
                            .foregroundStyle(hydronicPreparation.capacitySufficient ? .secondary : .orange)
                    }
                    LabeledContent("Deckung") {
                        Text((hydronicPreparation.capacityRatio * 100).formatted(.number.precision(.fractionLength(0))) + " %")
                    }
                    LabeledContent("Ziel-Volumenstrom technisch") {
                        Text(hydronicPreparation.targetVolumeFlowLPH.formatted(.number.precision(.fractionLength(0))) + " l/h")
                            .fontWeight(.semibold)
                    }

                    if hydronicPreparation.capacitySufficient {
                        Label("Heizflächenleistung deckt die zugeordnete Leistung in dieser Vorberechnung.", systemImage: "checkmark.circle")
                            .font(.caption)
                    } else {
                        Label("Heizflächenleistung reicht für die zugeordnete Leistung bei diesen Temperaturen nicht aus.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } else if surface.assignedRequiredPowerW == nil {
                    Label("Noch keine erforderliche Leistung dieser Heizfläche zugeordnet.", systemImage: "circle.dashed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label("Für den Ziel-Volumenstrom fehlen gültige Heizflächen- oder Systemdaten.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Hydraulische Vorbereitung")
            } footer: {
                Text("Der Ziel-Volumenstrom wird aus der zugeordneten erforderlichen Leistung und der Wasserspreizung berechnet. Er ist noch keine freigegebene Ventilvoreinstellung oder Verfahren-B-Dokumentation.")
            }

            Section("Notiz") {
                TextField("Quelle / Typenschild / Besonderheit", text: $surface.note, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
        .navigationTitle(surface.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: surface.kind) { _, newKind in
            if surface.name.isEmpty || HeizBalanceHeatingSurface.Kind.allCases.map(\.title).contains(surface.name) {
                surface.name = newKind.title
            }
        }
    }
}
