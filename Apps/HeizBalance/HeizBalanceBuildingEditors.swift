import SwiftUI

struct HeizBalanceFloorEditor: View {
    @Binding var floor: HeizBalanceFloor
    let designOutdoorTemperatureC: Double?
    let designFlowTemperatureC: Double?
    let designReturnTemperatureC: Double?

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
                            designReturnTemperatureC: designReturnTemperatureC
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
    let designOutdoorTemperatureC: Double?
    let designFlowTemperatureC: Double?
    let designReturnTemperatureC: Double?

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
                Text("Normative Tabellenwerte werden nicht ungeprüft in der App hinterlegt. U-Wert und Randbedingung bleiben nachvollziehbare Projekteingaben.")
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
                            roomTemperatureC: room.targetTemperature
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
                Text("Leistung und Exponent werden je Heizfläche als dokumentierte Hersteller- oder Projektwerte erfasst. Herstellerkennlinien und Ventilvoreinstellungen folgen erst mit geprüften Datensätzen.")
            }

            Section("Technische Vorberechnung") {
                HeizBalanceHeatLossPreviewView(preview: preview, floorAreaM2: room.floorArea)
            }
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HeizBalanceComponentEditor: View {
    @Binding var component: HeizBalanceComponent

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
