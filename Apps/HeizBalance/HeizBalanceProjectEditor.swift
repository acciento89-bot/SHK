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

    private var hydraulicSystemResult: HeizBalanceHydraulicSystemPreparationCalculator.Result? {
        draft.hydraulicSystemPreparationState().result
    }

    private var systemTemperatureInvalid: Bool {
        guard let flow = draft.designFlowTemperatureC,
              let returnTemperature = draft.designReturnTemperatureC else {
            return false
        }
        return flow <= returnTemperature
    }

    private var fluidPropertiesInvalid: Bool {
        if let density = draft.hydraulicFluidDensityKGPerM3, density <= 0 { return true }
        if let viscosity = draft.hydraulicKinematicViscosityMM2S, viscosity <= 0 { return true }
        return false
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
                OptionalDecimalField(
                    title: "Vorlauftemperatur",
                    value: $draft.designFlowTemperatureC,
                    unit: "°C"
                )
                OptionalDecimalField(
                    title: "Rücklauftemperatur",
                    value: $draft.designReturnTemperatureC,
                    unit: "°C"
                )
                InputSourcePicker(
                    title: "Quelle Systemtemperaturen",
                    selection: $draft.systemTemperatureSource
                )

                if systemTemperatureInvalid {
                    Label("Die Vorlauftemperatur muss über der Rücklauftemperatur liegen.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Heizsystem")
            } footer: {
                Text("Die Systemtemperaturen werden für die technische Heizflächenprüfung verwendet. Sie stellen noch keine freigegebene Auslegung oder Abgleichbestätigung dar.")
            }

            Section {
                OptionalDecimalField(
                    title: "Fluiddichte",
                    value: $draft.hydraulicFluidDensityKGPerM3,
                    unit: "kg/m³"
                )
                OptionalDecimalField(
                    title: "Kinematische Viskosität",
                    value: $draft.hydraulicKinematicViscosityMM2S,
                    unit: "mm²/s"
                )
                InputSourcePicker(
                    title: "Quelle Fluidwerte",
                    selection: $draft.hydraulicFluidSource
                )

                if fluidPropertiesInvalid {
                    Label("Dichte und Viskosität müssen größer als 0 sein.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Hydraulik-Fluid")
            } footer: {
                Text("Für Rohrdruckverluste werden die Fluidwerte bewusst als Projektdaten erfasst. HeizBalance setzt hier derzeit keine versteckten Wasser- oder Glykolwerte voraus.")
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
                            designOutdoorTemperatureC: draft.designOutdoorTemperatureC,
                            designFlowTemperatureC: draft.designFlowTemperatureC,
                            designReturnTemperatureC: draft.designReturnTemperatureC,
                            hydraulicFluidDensityKGPerM3: draft.hydraulicFluidDensityKGPerM3,
                            hydraulicKinematicViscosityMM2S: draft.hydraulicKinematicViscosityMM2S
                        )
                    } label: {
                        HStack {
                            Label(floor.name, systemImage: "square.stack.3d.up")
                            Spacer()
                            Text("\(floor.rooms.count) Räume")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            duplicateFloor(floor)
                        } label: {
                            Label("Duplizieren", systemImage: "plus.square.on.square")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button {
                            duplicateFloor(floor)
                        } label: {
                            Label("Geschoss duplizieren", systemImage: "plus.square.on.square")
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
                Text("Geschosse können für wiederkehrende Grundrisse dupliziert werden. Raum- und Bauteil-IDs werden erneuert; hydraulische Entscheidungen und Ersatzprodukt-Auswahlen werden in den Kopien bewusst zurückgesetzt.")
            }

            Section("Notizen") {
                TextField("Besonderheiten am Objekt", text: $draft.notes, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section {
                HeizBalanceProjectTechnicalStatusView(project: draft)
                Divider()

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
                        Label("Vorberechnung je Raum & Hydraulik", systemImage: "chart.bar.doc.horizontal")
                    }
                }

                LabeledContent("Norm-Heizlast") {
                    Text("Noch nicht freigegeben")
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    HeizBalanceCalculationStatusView()
                } label: {
                    Label("Rechenprofil & Validierung", systemImage: "checkmark.shield")
                }

                NavigationLink {
                    HeizBalanceLowTemperaturePreviewView(project: draft)
                } label: {
                    Label("Niedertemperatur-Check", systemImage: "thermometer.low")
                }

                NavigationLink {
                    HeizBalanceTemperatureScenarioView(project: $draft)
                } label: {
                    Label("Temperatur-Szenarien", systemImage: "chart.xyaxis.line")
                }

                HeizBalanceRetrofitTargetDashboardView(project: $draft)

                NavigationLink {
                    HeizBalanceValveDataManager(project: $draft)
                } label: {
                    Label("Ventildaten & Kennlinien", systemImage: "slider.horizontal.3")
                }

                NavigationLink {
                    HeizBalanceHydraulicFieldWorkspaceView(project: $draft)
                } label: {
                    Label("Hydraulik-Aufnahme & Einstellliste", systemImage: "wrench.and.screwdriver")
                }

                NavigationLink {
                    HeizBalancePumpProjectWorkspaceView(project: draft)
                } label: {
                    Label("Pumpe & Betriebspunkt", systemImage: "arrow.triangle.2.circlepath")
                }

                NavigationLink {
                    HeizBalanceProductionReportView(project: draft)
                } label: {
                    Label("Produktionsbericht & Übergabe", systemImage: "doc.text.image")
                }

                NavigationLink {
                    HeizBalanceTechnicalReportExportView(project: draft)
                } label: {
                    Label("Technischer Bericht & PDF", systemImage: "doc.richtext")
                }

                LabeledContent("Hydraulischer Abgleich") {
                    if hydraulicSystemResult?.pumpOperatingPointReady == true {
                        Text("Technischer Betriebspunkt vollständig")
                            .foregroundStyle(.green)
                    } else {
                        Text("Kreise / Druckverluste ergänzen")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Berechnungsstatus")
            } footer: {
                Text("Eine Gebäudesumme wird nur angezeigt, wenn alle Räume vollständig sind. Wärme-, Heizflächen-, Niedertemperatur-, Szenario-, Rohrnetz-, Ventil-, Pumpen- und Berichtsausgaben bleiben bis zur fachlichen Freigabe technische Vorbereitung.")
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

    private func duplicateFloor(_ floor: HeizBalanceFloor) {
        let copy = floor.duplicatedForCapture(suggestedName: nextFloorCopyName(for: floor.name))
        if let index = draft.floors.firstIndex(where: { $0.id == floor.id }) {
            draft.floors.insert(copy, at: index + 1)
        } else {
            draft.floors.append(copy)
        }
    }

    private func nextFloorCopyName(for sourceName: String) -> String {
        let base = sourceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Geschoss" : sourceName
        var candidate = base + " Kopie"
        var number = 2
        let existing = Set(draft.floors.map { $0.name })
        while existing.contains(candidate) {
            candidate = base + " Kopie \(number)"
            number += 1
        }
        return candidate
    }
}
