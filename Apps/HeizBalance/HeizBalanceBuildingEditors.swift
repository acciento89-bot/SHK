import SwiftUI

struct HeizBalanceFloorEditor: View {
    @Binding var floor: HeizBalanceFloor
    let designOutdoorTemperatureC: Double?
    let designFlowTemperatureC: Double?
    let designReturnTemperatureC: Double?
    let hydraulicFluidDensityKGPerM3: Double?
    let hydraulicKinematicViscosityMM2S: Double?

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
                        HeizBalanceRoomEditor(
                            room: $room,
                            designOutdoorTemperatureC: designOutdoorTemperatureC,
                            designFlowTemperatureC: designFlowTemperatureC,
                            designReturnTemperatureC: designReturnTemperatureC,
                            hydraulicFluidDensityKGPerM3: hydraulicFluidDensityKGPerM3,
                            hydraulicKinematicViscosityMM2S: hydraulicKinematicViscosityMM2S
                        )
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            duplicateRoom(room)
                        } label: {
                            Label("Duplizieren", systemImage: "plus.square.on.square")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button {
                            duplicateRoom(room)
                        } label: {
                            Label("Raum duplizieren", systemImage: "plus.square.on.square")
                        }
                    }
                }
                .onDelete { offsets in
                    floor.rooms.remove(atOffsets: offsets)
                }

                Menu {
                    Button {
                        addEmptyRoom()
                    } label: {
                        Label("Leerer Raum", systemImage: "square.dashed")
                    }

                    Section("Schnellvorlagen") {
                        ForEach(HeizBalanceRoomQuickTemplate.allCases) { template in
                            Button {
                                addRoom(template)
                            } label: {
                                Label(template.title, systemImage: template.systemImage)
                            }
                        }
                    }
                } label: {
                    Label("Raum hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Text("Räume")
            } footer: {
                Text("Schnellvorlagen setzen nur den Raumtyp als Startpunkt; Maße, Temperatur und Quellen bleiben prüfbare Projekteingaben. Beim Duplizieren werden IDs erneuert und hydraulische Entscheidungen bewusst nicht übernommen.")
            }
        }
        .navigationTitle(floor.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addEmptyRoom() {
        floor.rooms.append(HeizBalanceRoom(name: "Raum \(floor.rooms.count + 1)"))
    }

    private func addRoom(_ template: HeizBalanceRoomQuickTemplate) {
        var room = template.makeRoom()
        if floor.rooms.contains(where: { $0.name == room.name }) {
            let count = floor.rooms.filter { $0.name.hasPrefix(room.name) }.count + 1
            room.name += " \(count)"
        }
        floor.rooms.append(room)
    }

    private func duplicateRoom(_ room: HeizBalanceRoom) {
        let copy = room.duplicatedForCapture(suggestedName: nextCopyName(for: room.name))
        if let index = floor.rooms.firstIndex(where: { $0.id == room.id }) {
            floor.rooms.insert(copy, at: index + 1)
        } else {
            floor.rooms.append(copy)
        }
    }

    private func nextCopyName(for sourceName: String) -> String {
        let base = sourceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Raum" : sourceName
        var candidate = base + " Kopie"
        var number = 2
        let existing = Set(floor.rooms.map { $0.name })
        while existing.contains(candidate) {
            candidate = base + " Kopie \(number)"
            number += 1
        }
        return candidate
    }
}

struct HeizBalanceRoomEditor: View {
    @Environment(HeizBalanceComponentFavoriteStore.self) private var componentFavoriteStore

    @Binding var room: HeizBalanceRoom
    let designOutdoorTemperatureC: Double?
    let designFlowTemperatureC: Double?
    let designReturnTemperatureC: Double?
    let hydraulicFluidDensityKGPerM3: Double?
    let hydraulicKinematicViscosityMM2S: Double?

    private var preview: HeizBalanceRoomPreviewState {
        room.heatLossPreview(designOutdoorTemperatureC: designOutdoorTemperatureC)
    }

    private var heatingSurfacesBinding: Binding<[HeizBalanceHeatingSurface]> {
        Binding(
            get: { room.heatingSurfaces ?? [] },
            set: { room.heatingSurfaces = $0 }
        )
    }

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

            Section {
                DecimalField(title: "Raumtemperatur", value: $room.targetTemperature, unit: "°C")
                OptionalDecimalField(title: "Luftwechsel", value: $room.airChangeRatePerHour, unit: "1/h")
                InputSourcePicker(title: "Quelle Luftwechsel", selection: $room.airChangeSource)
            } header: {
                Text("Auslegung")
            } footer: {
                Text("Der Luftwechsel wird aktuell als expliziter Projekteingabewert verwendet. Automatische normative Ermittlung folgt erst mit der validierten Heizlast-Engine.")
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
                            VStack(alignment: .trailing, spacing: 2) {
                                if component.area > 0 {
                                    Text(component.area.formatted(.number.precision(.fractionLength(2))) + " m²")
                                }
                                if let uValue = component.uValue {
                                    Text("U " + uValue.formatted(.number.precision(.fractionLength(0...3))))
                                        .font(.caption2)
                                }
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            duplicateComponent(component)
                        } label: {
                            Label("Duplizieren", systemImage: "plus.square.on.square")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { offsets in
                    room.components.remove(atOffsets: offsets)
                }

                Menu {
                    if !componentFavoriteStore.favorites.isEmpty {
                        Section("Eigene Bauteilvorlagen") {
                            ForEach(componentFavoriteStore.favorites) { favorite in
                                Button {
                                    room.components.append(favorite.makeComponent())
                                } label: {
                                    Label(favorite.title, systemImage: favorite.kind.systemImage)
                                }
                            }
                        }
                    }

                    Section("Einzelnes Bauteil") {
                        ForEach(HeizBalanceComponent.Kind.allCases) { kind in
                            Button(kind.title) {
                                room.components.append(HeizBalanceComponent(kind: kind))
                            }
                        }
                    }

                    Section("Bauteilsätze ohne Kennwerte") {
                        ForEach(HeizBalanceComponentSetTemplate.allCases) { template in
                            Button {
                                room.components.append(contentsOf: template.makeComponents())
                            } label: {
                                Label(template.title, systemImage: "square.stack.3d.up")
                            }
                        }
                    }
                } label: {
                    Label("Bauteil / Satz hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Text("Bauteile")
            } footer: {
                Text("Eigene Vorlagen übernehmen Art/U-Wert/Quelle, aber niemals Fläche oder eine raumspezifische Gegenseitentemperatur. Bauteilsätze enthalten keine Kennwerte oder versteckten Normannahmen.")
            }

            Section {
                if heatingSurfacesBinding.wrappedValue.isEmpty {
                    Text("Noch keine Heizflächen erfasst")
                        .foregroundStyle(.secondary)
                }

                ForEach(heatingSurfacesBinding) { $surface in
                    NavigationLink {
                        HeizBalanceHeatingSurfaceEditor(
                            surface: $surface,
                            designFlowTemperatureC: designFlowTemperatureC,
                            designReturnTemperatureC: designReturnTemperatureC,
                            roomTemperatureC: room.targetTemperature,
                            hydraulicFluidDensityKGPerM3: hydraulicFluidDensityKGPerM3,
                            hydraulicKinematicViscosityMM2S: hydraulicKinematicViscosityMM2S
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Label(surface.name, systemImage: surface.kind.systemImage)
                                Spacer()
                                if let nominalPower = surface.nominalPowerDeltaT50W {
                                    Text(nominalPower.formatted(.number.precision(.fractionLength(0))) + " W ΔT50")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            let product = [surface.manufacturer, surface.model]
                                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                                .joined(separator: " · ")
                            if !product.isEmpty {
                                Text(product)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            duplicateHeatingSurface(surface)
                        } label: {
                            Label("Duplizieren", systemImage: "plus.square.on.square")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { offsets in
                    var items = heatingSurfacesBinding.wrappedValue
                    items.remove(atOffsets: offsets)
                    heatingSurfacesBinding.wrappedValue = items
                }

                Menu {
                    ForEach(HeizBalanceHeatingSurface.Kind.allCases) { kind in
                        Button(kind.title) {
                            var items = heatingSurfacesBinding.wrappedValue
                            items.append(HeizBalanceHeatingSurface(kind: kind))
                            heatingSurfacesBinding.wrappedValue = items
                        }
                    }
                } label: {
                    Label("Heizfläche hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Text("Heizflächen")
            } footer: {
                Text("Beim Duplizieren werden nur physische Heizflächendaten übernommen. Zugeordnete Last, Rohrnetz, Ventilverluste und Ersatzproduktentscheidung werden bewusst zurückgesetzt.")
            }

            Section("Technische Vorberechnung") {
                HeizBalanceHeatLossPreviewView(preview: preview, floorAreaM2: room.floorArea)
            }
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func duplicateComponent(_ component: HeizBalanceComponent) {
        let copy = component.duplicatedForCapture()
        if let index = room.components.firstIndex(where: { $0.id == component.id }) {
            room.components.insert(copy, at: index + 1)
        } else {
            room.components.append(copy)
        }
    }

    private func duplicateHeatingSurface(_ surface: HeizBalanceHeatingSurface) {
        var items = heatingSurfacesBinding.wrappedValue
        let copy = surface.duplicatedPhysicalSurfaceForCapture()
        if let index = items.firstIndex(where: { $0.id == surface.id }) {
            items.insert(copy, at: index + 1)
        } else {
            items.append(copy)
        }
        heatingSurfacesBinding.wrappedValue = items
    }
}

struct HeizBalanceComponentEditor: View {
    @Environment(HeizBalanceComponentFavoriteStore.self) private var favoriteStore

    @Binding var component: HeizBalanceComponent
    @State private var showingSaveFavorite = false
    @State private var favoriteTitle = ""

    private var boundaryBinding: Binding<HeizBalanceComponent.ThermalBoundary> {
        Binding(
            get: { component.effectiveThermalBoundary },
            set: { newValue in
                component.thermalBoundary = newValue
                if newValue == .outsideAir {
                    component.customBoundaryTemperatureC = nil
                }
            }
        )
    }

    private var suggestedFavoriteTitle: String {
        let base = component.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? component.kind.title
            : component.name
        if let uValue = component.uValue,
           uValue.isFinite,
           uValue > 0 {
            return base + " · U " + uValue.formatted(.number.precision(.fractionLength(0...3)))
        }
        return base
    }

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
                InputSourcePicker(title: "Quelle U-Wert", selection: $component.uValueSource)
            }

            Section {
                if favoriteStore.favorites.isEmpty {
                    Text("Noch keine eigenen Bauteilvorlagen gespeichert.")
                        .foregroundStyle(.secondary)
                } else {
                    Menu {
                        ForEach(favoriteStore.favorites) { favorite in
                            Button {
                                apply(favorite)
                            } label: {
                                Label(favorite.title, systemImage: favorite.kind.systemImage)
                            }
                        }
                    } label: {
                        Label("Gespeicherte Vorlage übernehmen", systemImage: "square.and.arrow.down")
                    }
                }

                Button {
                    favoriteTitle = suggestedFavoriteTitle
                    showingSaveFavorite = true
                } label: {
                    Label("Aktuelles Bauteil als Vorlage speichern", systemImage: "star.square")
                }

                NavigationLink {
                    HeizBalanceComponentFavoriteManager()
                } label: {
                    Label("Bauteilvorlagen verwalten", systemImage: "square.stack.3d.up")
                }

                if let error = favoriteStore.persistenceError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Bauteilvorlagen")
            } footer: {
                Text("Gespeichert werden Art, Bezeichnung, U-Wert, Quelle und Notiz. Fläche wird nie übernommen. Beim Anwenden wird die thermische Randbedingung auf den Standard der Bauteilart zurückgesetzt und muss vor Ort geprüft werden.")
            }

            Section {
                Picker("Randbedingung", selection: boundaryBinding) {
                    ForEach(HeizBalanceComponent.ThermalBoundary.allCases) { boundary in
                        Text(boundary.title).tag(boundary)
                    }
                }

                if component.effectiveThermalBoundary == .customTemperature {
                    OptionalDecimalField(
                        title: "Temperatur Gegenseite",
                        value: $component.customBoundaryTemperatureC,
                        unit: "°C"
                    )
                }
            } header: {
                Text("Thermische Randbedingung")
            } footer: {
                Text("Für Boden, Decken und angrenzende unbeheizte Bereiche wird derzeit keine pauschale Korrektur angenommen. Die Gegenseitentemperatur muss explizit erfasst werden.")
            }

            Section("Notiz") {
                TextField("Quelle / Aufbau / Besonderheit", text: $component.note, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
        .navigationTitle(component.kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: component.kind) { _, newKind in
            component.thermalBoundary = newKind.defaultThermalBoundary
            component.customBoundaryTemperatureC = nil
        }
        .alert("Bauteilvorlage speichern", isPresented: $showingSaveFavorite) {
            TextField("Name der Vorlage", text: $favoriteTitle)
            Button("Speichern") {
                favoriteStore.save(title: favoriteTitle, component: component)
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Die Vorlage speichert keine Fläche und keine raumspezifische Gegenseitentemperatur.")
        }
    }

    private func apply(_ favorite: HeizBalanceComponentFavorite) {
        favorite.apply(to: &component)
    }
}

struct HeizBalanceHeatLossPreviewView: View {
    let preview: HeizBalanceRoomPreviewState
    let floorAreaM2: Double

    var body: some View {
        if let result = preview.result {
            LabeledContent("Transmission") {
                Text(result.transmissionHeatLossW.formatted(.number.precision(.fractionLength(0))) + " W")
            }
            LabeledContent("Lüftung") {
                Text(result.ventilationHeatLossW.formatted(.number.precision(.fractionLength(0))) + " W")
            }
            LabeledContent("Summe") {
                Text(result.totalHeatLossW.formatted(.number.precision(.fractionLength(0))) + " W")
                    .fontWeight(.semibold)
            }

            if floorAreaM2 > 0 {
                LabeledContent("Spezifisch") {
                    Text((result.totalHeatLossW / floorAreaM2).formatted(.number.precision(.fractionLength(1))) + " W/m²")
                }
            }

            Label(
                "Vorberechnung aus expliziten Eingaben – noch keine freigegebene Norm-Heizlast.",
                systemImage: "exclamationmark.triangle"
            )
            .font(.caption)
            .foregroundStyle(.orange)
        } else {
            ForEach(preview.missingInputs, id: \.self) { item in
                Label(item, systemImage: "circle.dashed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
