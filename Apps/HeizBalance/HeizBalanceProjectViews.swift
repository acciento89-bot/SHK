import SwiftUI

struct HeizBalanceProjectListView: View {
    @Environment(HeizBalanceProjectStore.self) private var store
    @State private var showingNewProject = false

    var body: some View {
        Group {
            if store.projects.isEmpty {
                ContentUnavailableView {
                    Label("Noch keine Projekte", systemImage: "house.and.flag")
                } description: {
                    Text("Lege das erste Gebäude an. Räume und Bauteile werden danach direkt vor Ort erfasst.")
                } actions: {
                    Button("Projekt anlegen") {
                        showingNewProject = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    Section {
                        ForEach(store.projects) { project in
                            NavigationLink {
                                HeizBalanceProjectEditor(project: project)
                            } label: {
                                HeizBalanceProjectRow(project: project)
                            }
                        }
                        .onDelete(perform: store.delete)
                    } header: {
                        Text("Projekte")
                    } footer: {
                        Text("Alle Projektdaten werden derzeit lokal auf diesem Gerät gespeichert.")
                    }
                }
            }
        }
        .navigationTitle("HeizBalance")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewProject = true
                } label: {
                    Label("Neues Projekt", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewProject) {
            NavigationStack {
                HeizBalanceProjectEditor(project: nil)
            }
        }
        .alert("Speicherfehler", isPresented: persistenceErrorBinding) {
            Button("OK", role: .cancel) {
                store.persistenceError = nil
            }
        } message: {
            Text(store.persistenceError ?? "Unbekannter Fehler")
        }
    }

    private var persistenceErrorBinding: Binding<Bool> {
        Binding(
            get: { store.persistenceError != nil },
            set: { newValue in
                if !newValue { store.persistenceError = nil }
            }
        )
    }
}

private struct HeizBalanceProjectRow: View {
    let project: HeizBalanceProject

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(project.name)
                    .font(.headline)
                Spacer()
                Text("\(project.roomCount) Räume")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !project.customerName.isEmpty {
                Text(project.customerName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !project.displayAddress.isEmpty {
                Label(project.displayAddress, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}

struct HeizBalanceProjectEditor: View {
    @Environment(HeizBalanceProjectStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let isNewProject: Bool
    @State private var draft: HeizBalanceProject

    init(project: HeizBalanceProject?) {
        isNewProject = project == nil
        _draft = State(initialValue: project ?? HeizBalanceProject())
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
                if draft.floors.isEmpty {
                    Text("Noch keine Geschosse angelegt")
                        .foregroundStyle(.secondary)
                }

                ForEach($draft.floors) { $floor in
                    NavigationLink {
                        HeizBalanceFloorEditor(floor: $floor)
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
                Text("Die Reihenfolge kann später an die tatsächliche Gebäudeaufnahme angepasst werden.")
            }

            Section("Notizen") {
                TextField("Besonderheiten am Objekt", text: $draft.notes, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("Berechnungsstatus") {
                LabeledContent("Heizlast") {
                    Text("Noch nicht berechnet")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Hydraulischer Abgleich") {
                    Text("Noch nicht berechnet")
                        .foregroundStyle(.secondary)
                }
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

struct HeizBalanceFloorEditor: View {
    @Binding var floor: HeizBalanceFloor

    var body: some View {
        Form {
            Section("Geschoss") {
                TextField("Bezeichnung", text: $floor.name)
            }

            Section {
                if floor.rooms.isEmpty {
                    Text("Noch keine Räume angelegt")
                        .foregroundStyle(.secondary)
                }

                ForEach($floor.rooms) { $room in
                    NavigationLink {
                        HeizBalanceRoomEditor(room: $room)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(room.name)
                            HStack(spacing: 12) {
                                if !room.roomNumber.isEmpty {
                                    Text("Nr. \(room.roomNumber)")
                                }
                                if room.floorArea > 0 {
                                    Text(room.floorArea.formatted(.number.precision(.fractionLength(1))) + " m²")
                                }
                                Text(room.targetTemperature.formatted(.number.precision(.fractionLength(0...1))) + " °C")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    floor.rooms.remove(atOffsets: offsets)
                }

                Button {
                    floor.rooms.append(HeizBalanceRoom(name: "Raum \(floor.rooms.count + 1)"))
                } label: {
                    Label("Raum hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Text("Räume")
            }
        }
        .navigationTitle(floor.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HeizBalanceRoomEditor: View {
    @Binding var room: HeizBalanceRoom

    var body: some View {
        Form {
            Section("Raum") {
                TextField("Raumname", text: $room.name)
                TextField("Raumnummer", text: $room.roomNumber)
            }

            Section("Abmessungen") {
                DecimalField(title: "Länge", value: $room.length, unit: "m")
                DecimalField(title: "Breite", value: $room.width, unit: "m")
                DecimalField(title: "Höhe", value: $room.height, unit: "m")

                LabeledContent("Grundfläche") {
                    Text(room.floorArea.formatted(.number.precision(.fractionLength(2))) + " m²")
                }
                LabeledContent("Raumvolumen") {
                    Text(room.volume.formatted(.number.precision(.fractionLength(2))) + " m³")
                }
            }

            Section("Auslegung") {
                DecimalField(title: "Raumtemperatur", value: $room.targetTemperature, unit: "°C")
            }

            Section {
                if room.components.isEmpty {
                    Text("Noch keine wärmeübertragenden Bauteile erfasst")
                        .foregroundStyle(.secondary)
                }

                ForEach($room.components) { $component in
                    NavigationLink {
                        HeizBalanceComponentEditor(component: $component)
                    } label: {
                        HStack {
                            Label(component.name, systemImage: component.kind.systemImage)
                            Spacer()
                            if component.area > 0 {
                                Text(component.area.formatted(.number.precision(.fractionLength(2))) + " m²")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    room.components.remove(atOffsets: offsets)
                }

                Menu {
                    ForEach(HeizBalanceComponent.Kind.allCases) { kind in
                        Button(kind.title) {
                            room.components.append(HeizBalanceComponent(kind: kind))
                        }
                    }
                } label: {
                    Label("Bauteil hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Text("Bauteile")
            } footer: {
                Text("U-Werte können als Projektwert eingetragen werden. Normative Tabellenwerte werden nicht ungeprüft in der App hinterlegt.")
            }
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HeizBalanceComponentEditor: View {
    @Binding var component: HeizBalanceComponent

    var body: some View {
        Form {
            Section("Bauteil") {
                Picker("Art", selection: $component.kind) {
                    ForEach(HeizBalanceComponent.Kind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                TextField("Bezeichnung", text: $component.name)
            }

            Section("Abmessungen & Kennwert") {
                DecimalField(title: "Fläche", value: $component.area, unit: "m²")
                OptionalDecimalField(title: "U-Wert", value: $component.uValue, unit: "W/(m²·K)")
            }

            Section("Notiz") {
                TextField("Quelle / Aufbau / Besonderheit", text: $component.note, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
        .navigationTitle(component.kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DecimalField: View {
    let title: String
    @Binding var value: Double
    let unit: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: $value, format: .number.precision(.fractionLength(0...3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 80, maxWidth: 120)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}

private struct OptionalDecimalField: View {
    let title: String
    @Binding var value: Double?
    let unit: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("optional", value: $value, format: .number.precision(.fractionLength(0...3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 90, maxWidth: 130)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}
