import SwiftUI

struct HeizBalanceProjectEditor: View {
    @Environment(HeizBalanceProjectStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let isNewProject: Bool
    @State private var draft: HeizBalanceProject

    init(project: HeizBalanceProject?) {
        isNewProject = project == nil
        _draft = State(initialValue: project ?? HeizBalanceProject())
    }

    private var previewSummary: HeizBalanceProjectPreviewState {
        draft.heatLossPreviewSummary()
    }

    var body: some View {
        Form {
            Section("Projekt") {
                TextField("Projektname", text: $draft.name)
                TextField("Kunde / Auftraggeber", text: $draft.customerName)
            }

            Section("Objekt") {
                TextField("Straße und Hausnummer", text: $draft.street)
                TextField("PLZ", text: $draft.postalCode)
                    .keyboardType(.numbersAndPunctuation)
                TextField("Ort", text: $draft.city)
                TextField("Baujahr", text: $draft.buildingYear)
                    .keyboardType(.numberPad)
            }

            Section {
                OptionalDecimalField(
                    title: "Auslegungs-Außentemperatur",
                    value: $draft.designOutdoorTemperatureC,
                    unit: "°C"
                )
                InputSourcePicker(title: "Quelle", selection: $draft.designOutdoorTemperatureSource)
            } header: {
                Text("Auslegungsbedingungen")
            } footer: {
                Text("Der Wert wird projektspezifisch dokumentiert. Eine normative Ortsdatenbank ist noch nicht Bestandteil dieses Entwicklungsstands.")
            }

            Section {
                if draft.floors.isEmpty {
                    Text("Noch keine Geschosse angelegt")
                        .foregroundStyle(.secondary)
                }

                ForEach($draft.floors) { $floor in
                    NavigationLink {
                        HeizBalanceFloorEditor(
                            floor: $floor,
                            designOutdoorTemperatureC: draft.designOutdoorTemperatureC
                        )
                    } label: {
                        HStack {
                            Label(floor.name, systemImage: "square.stack.3d.up")
                            Spacer()
                            Text("\(floor.rooms.count) Räume")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    draft.floors.remove(atOffsets: offsets)
                }

                Button {
                    addFloor()
                } label: {
                    Label("Geschoss hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Text("Gebäude")
            } footer: {
                Text("Räume, Bauteile und thermische Randbedingungen werden geschossweise aufgenommen.")
            }

            Section("Notizen") {
                TextField("Besonderheiten am Objekt", text: $draft.notes, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section {
                if draft.roomCount == 0 {
                    Text("Noch keine Räume für eine Vorberechnung vorhanden.")
                        .foregroundStyle(.secondary)
                } else {
                    LabeledContent("Vollständige Räume") {
                        Text("\(previewSummary.completeRoomCount) / \(previewSummary.rooms.count)")
                    }

                    if let buildingTotal = previewSummary.buildingPreviewTotalW {
                        LabeledContent("Gebäudesumme Vorberechnung") {
                            Text(buildingTotal.formatted(.number.precision(.fractionLength(0))) + " W")
                                .fontWeight(.semibold)
                        }
                    } else if previewSummary.completeRoomCount > 0 {
                        LabeledContent("Zwischensumme") {
                            Text(previewSummary.completedRoomsSubtotalW.formatted(.number.precision(.fractionLength(0))) + " W")
                        }
                    }

                    NavigationLink {
                        HeizBalanceProjectPreviewView(project: draft)
                    } label: {
                        Label("Vorberechnung je Raum", systemImage: "chart.bar.doc.horizontal")
                    }
                }

                LabeledContent("Norm-Heizlast") {
                    Text("Noch nicht freigegeben")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Hydraulischer Abgleich") {
                    Text("Noch nicht implementiert")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Berechnungsstatus")
            } footer: {
                Text("Eine Gebäudesumme wird nur angezeigt, wenn alle Räume vollständig sind. Die aktuelle Vorberechnung ist keine freigegebene Norm-Heizlast.")
            }
        }
        .navigationTitle(isNewProject ? "Neues Projekt" : draft.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNewProject {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    store.save(draft)
                    dismiss()
                }
                .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func addFloor() {
        let suggestedName: String
        switch draft.floors.count {
        case 0: suggestedName = "Erdgeschoss"
        case 1: suggestedName = "1. Obergeschoss"
        case 2: suggestedName = "2. Obergeschoss"
        default: suggestedName = "Geschoss \(draft.floors.count + 1)"
        }
        draft.floors.append(HeizBalanceFloor(name: suggestedName))
    }
}
