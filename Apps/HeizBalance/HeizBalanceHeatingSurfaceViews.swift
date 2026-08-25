import SwiftUI

struct HeizBalanceHeatingSurfaceEditor: View {
    @Binding var surface: HeizBalanceHeatingSurface
    let designFlowTemperatureC: Double?
    let designReturnTemperatureC: Double?
    let roomTemperatureC: Double

    private var preview: HeizBalanceHeatingSurfacePreviewCalculator.Result? {
        guard let nominalPower = surface.nominalPowerDeltaT50W,
              let exponent = surface.exponent,
              let flow = designFlowTemperatureC,
              let returnTemperature = designReturnTemperatureC else {
            return nil
        }

        return HeizBalanceHeatingSurfacePreviewCalculator.calculate(
            .init(
                nominalPowerDeltaT50W: nominalPower,
                exponent: exponent,
                flowTemperatureC: flow,
                returnTemperatureC: returnTemperature,
                roomTemperatureC: roomTemperatureC
            )
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
                if let flow = designFlowTemperatureC, let returnTemperature = designReturnTemperatureC {
                    LabeledContent("Systemtemperaturen") {
                        Text("\(flow.formatted(.number.precision(.fractionLength(0...1)))) / \(returnTemperature.formatted(.number.precision(.fractionLength(0...1)))) °C")
                    }
                }
                LabeledContent("Raumtemperatur") {
                    Text(roomTemperatureC.formatted(.number.precision(.fractionLength(0...1))) + " °C")
                }

                if let preview {
                    LabeledContent("Leistung bei Auslegung") {
                        Text(preview.availablePowerW.formatted(.number.precision(.fractionLength(0))) + " W")
                            .fontWeight(.semibold)
                    }
                    LabeledContent("Wasserspreizung") {
                        Text(preview.waterTemperatureDifferenceK.formatted(.number.precision(.fractionLength(0...1))) + " K")
                    }
                    LabeledContent("Technischer Volumenstrom") {
                        Text(preview.volumeFlowLPH.formatted(.number.precision(.fractionLength(0))) + " l/h")
                            .fontWeight(.semibold)
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
                Text("Leistung und Volumenstrom sind eine technische Vorberechnung aus den eingegebenen Kennwerten. Sie sind noch kein freigegebener hydraulischer Abgleich oder Normnachweis.")
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
