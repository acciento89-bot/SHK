import SwiftUI

struct HeatSurveyHome: View {
    @StateObject private var store = FieldStore<HeatSurvey>("heat-surveys")
    @State private var draft: HeatSurvey?
    var body: some View {
        TabView {
            NavigationStack {
                List {
                    WorkHero(eyebrow: "HeizkörperCalc", title: tr("Passt der Bestand zur Wärmepumpe?", "Ready for lower temperatures?"),
                        description: tr("Raumweise prüfen, wo vorhandene Heizkörper bei deiner Zieltemperatur ausreichen und wo Leistung fehlt.", "Check each room's existing radiators at your target temperatures and identify capacity shortfalls."), icon: "house.and.flag", color: .orange)
                    Button { draft = HeatSurvey() } label: { Label(tr("Bestandsaufnahme starten", "Start a survey"), systemImage: "plus.circle.fill").font(.headline).padding(.vertical, 8) }
                    if store.items.isEmpty {
                        WorkEmpty(title: tr("Dein erster Raumvergleich", "Your first room comparison"), detail: tr("Halte Raumheizlast und die gesamte ΔT50-Nennleistung der Heizkörper bereit.", "Have the room heat demand and total ΔT50 radiator rating ready."), icon: "rectangle.split.3x1")
                    }
                    ForEach(store.items) { survey in
                        NavigationLink { HeatSurveyDetail(store: store, id: survey.id) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(survey.name).font(.headline)
                                Text("\(survey.rooms.count) " + tr("Räume", "rooms") + " · \(fieldNumber(survey.flowC))/\(fieldNumber(survey.returnC)) °C").foregroundStyle(.secondary)
                                Text("\(survey.deficientRoomCount) " + tr("Räume mit Leistungsdefizit", "rooms with a shortfall")).font(.subheadline)
                            }.padding(.vertical, 6)
                        }
                    }
                }.navigationTitle(tr("Gebäude", "Buildings"))
            }.tabItem { Label(tr("Bestand", "Survey"), systemImage: "house") }
            HeizkoerperCalcView().tabItem { Label(tr("Einzelrechner", "Calculator"), systemImage: "function") }
        }.tint(.primary)
        .sheet(item: $draft) { value in HeatSurveyEditor(initial: value) { store.save($0) } }
        .workError($store.error)
    }
}

private struct HeatSurveyDetail: View {
    @ObservedObject var store: FieldStore<HeatSurvey>
    let id: UUID
    @State private var editing: HeatSurvey?
    @State private var deleting = false
    @Environment(\.dismiss) private var dismiss
    private var survey: HeatSurvey? { store.items.first { $0.id == id } }
    var body: some View {
        Group {
            if let survey {
                List {
                    Section {
                        WorkMetric(label: tr("Zielbetrieb · Vorlauf / Rücklauf", "Target · flow / return"), value: "\(fieldNumber(survey.flowC)) / \(fieldNumber(survey.returnC)) °C")
                        WorkMetric(label: tr("Fehlende Leistung in unterversorgten Räumen", "Shortfall in under-supplied rooms"), value: "\(fieldNumber(survey.deficitW, digits: 0)) W", color: survey.deficitW > 0 ? .red : .primary)
                        Text(tr("Überschüsse anderer Räume gleichen dieses Defizit nicht aus.", "Surplus capacity in other rooms does not cancel this shortfall.")).font(.body).foregroundStyle(.secondary)
                    }
                    if !survey.rooms.isEmpty {
                        Section(tr("Raum für Raum", "Room by room")) {
                            ForEach(survey.rooms) { room in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(room.name).font(.headline)
                                    let actual = room.power(flow: survey.flowC, returning: survey.returnC)
                                    WorkMetric(label: tr("Verfügbar / benötigt", "Available / required"), value: "\(fieldNumber(actual, digits: 0)) / \(fieldNumber(room.demandW, digits: 0)) W")
                                    ProgressView(value: min(actual / room.demandW, 1)).tint(actual >= room.demandW ? .green : .orange)
                                        .accessibilityLabel(tr("Deckung", "Coverage")).accessibilityValue("\(fieldNumber(actual / room.demandW * 100, digits: 0)) %")
                                    Label(actual >= room.demandW ? tr("Leistung ausreichend", "Capacity sufficient") : tr("Leistung fehlt", "Capacity shortfall"), systemImage: actual >= room.demandW ? "checkmark.circle" : "exclamationmark.triangle")
                                    Text("ΔT50: \(fieldNumber(room.nominalW, digits: 0)) W · n = \(fieldNumber(room.exponent, digits: 2)) · \(fieldNumber(room.roomC)) °C").font(.subheadline).foregroundStyle(.secondary)
                                }.padding(.vertical, 8)
                            }
                        }
                        Section(tr("Temperaturszenarien", "Temperature scenarios")) {
                            ForEach([35.0, 45.0, 55.0, 65.0], id: \.self) { flow in
                                let returning = flow - 10
                                if survey.rooms.allSatisfy({ $0.roomC < returning }) {
                                    let covered = survey.rooms.filter { $0.power(flow: flow, returning: returning) >= $0.demandW }.count
                                    LabeledContent("\(Int(flow))/\(Int(returning)) °C", value: "\(covered)/\(survey.rooms.count) " + tr("Räume gedeckt", "rooms covered"))
                                }
                            }
                            Text(tr("Szenarien mit 10 K Spreizung. Raumtemperaturen und Heizlasten bleiben unverändert.", "Scenarios use a 10 K flow/return difference; room temperatures and heat demand remain unchanged.")).foregroundStyle(.secondary)
                        }
                    } else { Text(tr("Füge Räume über Bearbeiten hinzu.", "Add rooms using Edit.")) }
                    Section(tr("Grundlage", "Basis")) {
                        Text(tr("Leistungsumrechnung aus ΔT50 und Herstellerexponent. Raumheizlast extern ermitteln; diese Bestandsprüfung ersetzt keine Heizlastberechnung. Mehrere Heizkörper mit unterschiedlichen Exponenten getrennt im Einzelrechner prüfen.", "Capacity correction uses the ΔT50 rating and manufacturer exponent. Supply an independently determined room heat demand; this survey does not calculate heat load. Check radiators with different exponents separately in the calculator."))
                        if !survey.notes.isEmpty { Text(survey.notes) }
                    }
                    Section {
                        ShareLink(item: heatReport(survey)) { Label(tr("Bestandsbericht teilen", "Share survey report"), systemImage: "square.and.arrow.up") }
                        Button(tr("Bestandsaufnahme löschen", "Delete survey"), role: .destructive) { deleting = true }
                    }
                }.navigationTitle(survey.name)
                .toolbar { Button(tr("Bearbeiten", "Edit")) { editing = survey } }
                .confirmationDialog(tr("Bestandsaufnahme endgültig löschen?", "Permanently delete this survey?"), isPresented: $deleting, titleVisibility: .visible) {
                    Button(tr("Löschen", "Delete"), role: .destructive) { store.delete(survey); if store.error == nil { dismiss() } }
                }
            }
        }.sheet(item: $editing) { HeatSurveyEditor(initial: $0) { store.save($0) } }.workError($store.error)
    }
}

private struct HeatSurveyEditor: View {
    @State var initial: HeatSurvey
    let save: (HeatSurvey) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var saveFailed = false
    var body: some View {
        NavigationStack {
            Form {
                Section(tr("Gebäude und Zieltemperaturen", "Building and target temperatures")) {
                    TextField(tr("Gebäudename", "Building name"), text: $initial.name)
                    WorkNumber(title: tr("Vorlauf", "Flow"), value: $initial.flowC, unit: "°C")
                    WorkNumber(title: tr("Rücklauf", "Return"), value: $initial.returnC, unit: "°C")
                }
                Section(tr("Heizkörperbestand", "Radiator inventory")) {
                    ForEach($initial.rooms) { $room in
                        DisclosureGroup(room.name.isEmpty ? tr("Neuer Raum", "New room") : room.name) {
                            TextField(tr("Raumname", "Room name"), text: $room.name)
                            WorkNumber(title: tr("Ermittelte Raumheizlast", "Determined room heat demand"), value: $room.demandW, unit: "W")
                            WorkNumber(title: tr("Gesamte Nennleistung bei ΔT50", "Total rated capacity at ΔT50"), value: $room.nominalW, unit: "W")
                            WorkNumber(title: tr("Herstellerexponent n", "Manufacturer exponent n"), value: $room.exponent, unit: "")
                            WorkNumber(title: tr("Raumtemperatur", "Room temperature"), value: $room.roomC, unit: "°C")
                        }
                    }.onDelete { initial.rooms.remove(atOffsets: $0) }
                    Button { var room = HeatRoom(); room.name = tr("Raum", "Room") + " \(initial.rooms.count + 1)"; initial.rooms.append(room) } label: { Label(tr("Raum hinzufügen", "Add room"), systemImage: "plus") }
                }
                Section(tr("Notizen", "Notes")) { TextField(tr("Heizlastquelle, Heizkörpertyp …", "Heat demand source, radiator type …"), text: $initial.notes, axis: .vertical) }
                if !initial.isValid { WorkValidation(message: tr("Name und positive Leistungswerte eintragen. Vorlauf ≥ Rücklauf > jede Raumtemperatur; Exponent > 0 bis 5.", "Enter a name and positive capacities. Flow ≥ return > every room temperature; exponent > 0 up to 5.")) }
            }.navigationTitle(tr("Bestandsaufnahme", "Survey"))
            .toolbar { WorkActions(valid: initial.isValid) { if save(initial) { dismiss() } else { saveFailed = true } } }
            .alert(tr("Nicht gespeichert", "Not saved"), isPresented: $saveFailed) {} message: { Text(tr("Bitte Speicherplatz prüfen. Deine Eingaben bleiben geöffnet.", "Check available storage. Your entries remain open.")) }
        }.interactiveDismissDisabled()
    }
}

private func heatReport(_ survey: HeatSurvey) -> String {
    var lines = ["HeizkörperCalc – \(survey.name)", Date().formatted(), "\(fieldNumber(survey.flowC))/\(fieldNumber(survey.returnC)) °C", tr("Raum: verfügbar / Heizlast; ΔT50; n; Raumtemperatur", "Room: available / demand; ΔT50; n; room temperature")]
    for room in survey.rooms {
        lines.append("\(room.name): \(fieldNumber(room.power(flow: survey.flowC, returning: survey.returnC), digits: 0)) / \(fieldNumber(room.demandW, digits: 0)) W; \(fieldNumber(room.nominalW)) W; \(fieldNumber(room.exponent, digits: 2)); \(fieldNumber(room.roomC)) °C")
    }
    lines += [tr("Summe Raumdefizite: ", "Total room shortfalls: ") + "\(fieldNumber(survey.deficitW)) W", survey.notes, tr("ΔT50-Leistungsumrechnung; keine Heizlastberechnung. Überschüsse werden nicht mit Defiziten verrechnet.", "ΔT50 capacity correction; not a heat load calculation. Surpluses do not offset shortfalls.")]
    return lines.joined(separator: "\n")
}
