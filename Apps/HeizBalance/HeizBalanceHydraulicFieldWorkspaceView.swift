import SwiftUI

struct HeizBalanceHydraulicFieldWorkspaceView: View {
    @Binding var project: HeizBalanceProject

    private struct CircuitEntry: Identifiable {
        var id: UUID { surfaceID }
        var floorID: UUID
        var roomID: UUID
        var surfaceID: UUID
        var floorName: String
        var roomName: String
        var surfaceName: String
    }

    private var entries: [CircuitEntry] {
        project.floors.flatMap { floor in
            floor.rooms.flatMap { room in
                (room.heatingSurfaces ?? []).map { surface in
                    CircuitEntry(
                        floorID: floor.id,
                        roomID: room.id,
                        surfaceID: surface.id,
                        floorName: floor.name,
                        roomName: room.name,
                        surfaceName: surface.name
                    )
                }
            }
        }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Heizflächenkreise", value: "\(entries.count)")
                NavigationLink {
                    HeizBalanceAdjustmentListView(project: project)
                } label: {
                    Label("Baustellen-Einstellliste", systemImage: "list.clipboard")
                }
            } header: {
                Text("Hydraulik-Aufnahme")
            } footer: {
                Text("Hier werden wiederkehrende Rohr- und Bauteilstrukturen schneller erfasst. Flow- und druckabhängige Werte sowie konkrete Einstellentscheidungen werden beim Kopieren bewusst nicht blind übernommen.")
            }

            if entries.isEmpty {
                Section {
                    Label("Noch keine Heizflächen im Projekt erfasst.", systemImage: "circle.dashed")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Kreise") {
                    ForEach(entries) { entry in
                        if let binding = surfaceBinding(for: entry),
                           let roomTemperature = roomTemperature(for: entry) {
                            NavigationLink {
                                HeizBalanceHydraulicCircuitWorkspaceView(
                                    projectID: project.id,
                                    surface: binding,
                                    roomTemperatureC: roomTemperature,
                                    designFlowTemperatureC: project.designFlowTemperatureC,
                                    designReturnTemperatureC: project.designReturnTemperatureC,
                                    densityKGPerM3: project.hydraulicFluidDensityKGPerM3,
                                    kinematicViscosityMM2S: project.hydraulicKinematicViscosityMM2S
                                )
                            } label: {
                                circuitRow(entry: entry, surface: binding.wrappedValue, roomTemperatureC: roomTemperature)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    duplicateCircuit(entry)
                                } label: {
                                    Label("Kreis kopieren", systemImage: "plus.square.on.square")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Hydraulik-Aufnahme")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func circuitRow(
        entry: CircuitEntry,
        surface: HeizBalanceHeatingSurface,
        roomTemperatureC: Double
    ) -> some View {
        let hydronic = surface.hydronicPreparation(
            flowTemperatureC: project.designFlowTemperatureC,
            returnTemperatureC: project.designReturnTemperatureC,
            roomTemperatureC: roomTemperatureC
        )
        let circuit = surface.circuitPressureLossSummary(
            flowTemperatureC: project.designFlowTemperatureC,
            returnTemperatureC: project.designReturnTemperatureC,
            roomTemperatureC: roomTemperatureC,
            densityKGPerM3: project.hydraulicFluidDensityKGPerM3,
            kinematicViscosityMM2S: project.hydraulicKinematicViscosityMM2S
        )

        VStack(alignment: .leading, spacing: 5) {
            Text(entry.surfaceName)
                .font(.headline)
            Text("\(entry.roomName) · \(entry.floorName)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Text(hydronic.map { "Q " + $0.targetVolumeFlowLPH.formatted(.number.precision(.fractionLength(0))) + " l/h" } ?? "Q offen")
                Text(circuit?.completeCircuitPressureLossKPa.map { "Δp " + $0.formatted(.number.precision(.fractionLength(0...2))) + " kPa" } ?? "Δp offen")
                Text("\((surface.pipeSections ?? []).count) Rohre")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func roomTemperature(for entry: CircuitEntry) -> Double? {
        guard let location = locate(entry) else { return nil }
        return project.floors[location.floor].rooms[location.room].targetTemperature
    }

    private func surfaceBinding(for entry: CircuitEntry) -> Binding<HeizBalanceHeatingSurface>? {
        guard locate(entry) != nil else { return nil }
        return Binding(
            get: {
                guard let location = locate(entry),
                      let surfaces = project.floors[location.floor].rooms[location.room].heatingSurfaces else {
                    return HeizBalanceHeatingSurface()
                }
                return surfaces[location.surface]
            },
            set: { newValue in
                guard let location = locate(entry) else { return }
                var updated = project
                updated.floors[location.floor].rooms[location.room].heatingSurfaces![location.surface] = newValue
                project = updated
            }
        )
    }

    private func duplicateCircuit(_ entry: CircuitEntry) {
        guard let location = locate(entry),
              var surfaces = project.floors[location.floor].rooms[location.room].heatingSurfaces else { return }
        let source = surfaces[location.surface]
        var copy = source.duplicatedWithHydraulicStructureForCapture()
        copy.name = nextCopyName(source.name, in: surfaces)
        surfaces.insert(copy, at: location.surface + 1)
        project.floors[location.floor].rooms[location.room].heatingSurfaces = surfaces
    }

    private func nextCopyName(_ source: String, in surfaces: [HeizBalanceHeatingSurface]) -> String {
        let base = source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Heizfläche" : source
        let existing = Set(surfaces.map(\.name))
        var candidate = base + " Kopie"
        var number = 2
        while existing.contains(candidate) {
            candidate = base + " Kopie \(number)"
            number += 1
        }
        return candidate
    }

    private func locate(_ entry: CircuitEntry) -> (floor: Int, room: Int, surface: Int)? {
        guard let floor = project.floors.firstIndex(where: { $0.id == entry.floorID }),
              let room = project.floors[floor].rooms.firstIndex(where: { $0.id == entry.roomID }),
              let surfaces = project.floors[floor].rooms[room].heatingSurfaces,
              let surface = surfaces.firstIndex(where: { $0.id == entry.surfaceID }) else { return nil }
        return (floor, room, surface)
    }
}

struct HeizBalanceHydraulicCircuitWorkspaceView: View {
    @Environment(HeizBalanceHydraulicCaptureTemplateStore.self) private var templateStore
    @Environment(HeizBalanceValveSettingSelectionStore.self) private var valveSelectionStore

    let projectID: UUID
    @Binding var surface: HeizBalanceHeatingSurface
    let roomTemperatureC: Double
    let designFlowTemperatureC: Double?
    let designReturnTemperatureC: Double?
    let densityKGPerM3: Double?
    let kinematicViscosityMM2S: Double?

    @State private var templateName = ""

    private var hydronic: HeizBalanceHydronicPreparationCalculator.Result? {
        surface.hydronicPreparation(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: roomTemperatureC
        )
    }

    private var circuit: HeizBalanceCircuitPressureLossSummaryCalculator.Result? {
        surface.circuitPressureLossSummary(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: roomTemperatureC,
            densityKGPerM3: densityKGPerM3,
            kinematicViscosityMM2S: kinematicViscosityMM2S
        )
    }

    private var pipeBinding: Binding<[HeizBalancePipeSection]> {
        Binding(
            get: { surface.pipeSections ?? [] },
            set: { surface.pipeSections = $0 }
        )
    }

    private var componentBinding: Binding<[HeizBalanceHydraulicLossComponent]> {
        Binding(
            get: { surface.hydraulicLossComponents ?? [] },
            set: {
                surface.hydraulicLossComponents = $0
                surface.hydraulicComponentAssessmentComplete = false
            }
        )
    }

    private var componentAssessmentBinding: Binding<Bool> {
        Binding(
            get: { surface.isHydraulicComponentAssessmentComplete },
            set: { surface.hydraulicComponentAssessmentComplete = $0 }
        )
    }

    private var componentValuesComplete: Bool {
        (surface.hydraulicLossComponents ?? []).allSatisfy { component in
            guard let pressureLoss = component.pressureLossKPa else { return false }
            return pressureLoss.isFinite && pressureLoss >= 0
        }
    }

    private var valveIndices: [Int] {
        (surface.hydraulicLossComponents ?? []).indices.filter { index in
            surface.hydraulicLossComponents?[index].supportsValveProductData == true
        }
    }

    var body: some View {
        Form {
            Section {
                if let hydronic {
                    LabeledContent("Ziel-Volumenstrom") {
                        Text(hydronic.targetVolumeFlowLPH.formatted(.number.precision(.fractionLength(0))) + " l/h")
                            .fontWeight(.semibold)
                    }
                } else {
                    Label("Ziel-Volumenstrom noch nicht berechenbar", systemImage: "circle.dashed")
                        .foregroundStyle(.secondary)
                }
                if let complete = circuit?.completeCircuitPressureLossKPa {
                    LabeledContent("Vollständiger Kreis Δp") {
                        Text(complete.formatted(.number.precision(.fractionLength(0...2))) + " kPa")
                            .fontWeight(.semibold)
                    }
                } else {
                    Label("Kreis-Δp noch unvollständig", systemImage: "circle.dashed")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Kreisstatus")
            }

            Section {
                TextField("Vorlagenname", text: $templateName)
                Button {
                    let title = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
                    templateStore.save(title: title, surface: surface)
                    if !title.isEmpty { templateName = "" }
                } label: {
                    Label("Aktuelle Struktur als Vorlage speichern", systemImage: "square.and.arrow.down")
                }
                .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !templateStore.templates.isEmpty {
                    Menu {
                        ForEach(templateStore.templates) { template in
                            Button(template.title) {
                                removeSelectionsForCurrentComponents()
                                var updated = surface
                                template.apply(to: &updated)
                                surface = updated
                            }
                        }
                    } label: {
                        Label("Hydraulikvorlage anwenden", systemImage: "square.stack.3d.up")
                    }
                }

                Button(role: .destructive) {
                    removeSelectionsForCurrentComponents()
                    surface.pipeSections = []
                    surface.hydraulicLossComponents = []
                    surface.hydraulicComponentAssessmentComplete = false
                } label: {
                    Label("Hydraulikstruktur leeren", systemImage: "trash")
                }
            } header: {
                Text("Schnellaufnahme")
            } footer: {
                Text("Beim Anwenden einer Vorlage werden gemeinsame Abschnitts-Volumenströme, Bauteil-Δp, deren Quellen und die Vollständigkeitsbestätigung zurückgesetzt. Ventilprodukt-Identität darf als dokumentierte Struktur mitkommen; die konkrete Einstellung nie.")
            }

            Section {
                ForEach(pipeBinding) { $section in
                    NavigationLink {
                        HeizBalancePipeSectionEditor(section: $section)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.name)
                            Text(section.effectiveRole.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            duplicatePipeSection(section)
                        } label: {
                            Label("Duplizieren", systemImage: "plus.square.on.square")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { offsets in
                    var values = pipeBinding.wrappedValue
                    values.remove(atOffsets: offsets)
                    pipeBinding.wrappedValue = values
                }

                Button {
                    var values = pipeBinding.wrappedValue
                    values.append(.init(name: "Rohrabschnitt \(values.count + 1)"))
                    pipeBinding.wrappedValue = values
                } label: {
                    Label("Rohrabschnitt hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Text("Rohrweg")
            }

            Section {
                ForEach(componentBinding) { $component in
                    NavigationLink {
                        HeizBalanceHydraulicLossComponentEditor(component: $component)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(component.name)
                                Text(component.kind.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let loss = component.pressureLossKPa {
                                Text(loss.formatted(.number.precision(.fractionLength(0...2))) + " kPa")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            duplicateHydraulicComponent(component)
                        } label: {
                            Label("Duplizieren", systemImage: "plus.square.on.square")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { offsets in
                    var values = componentBinding.wrappedValue
                    let removedIDs = Set(offsets.compactMap { index in
                        values.indices.contains(index) ? values[index].id : nil
                    })
                    valveSelectionStore.delete(projectID: projectID, componentIDs: removedIDs)
                    values.remove(atOffsets: offsets)
                    componentBinding.wrappedValue = values
                }

                Menu {
                    ForEach(HeizBalanceHydraulicLossComponent.Kind.allCases) { kind in
                        Button(kind.title) {
                            var values = componentBinding.wrappedValue
                            values.append(.init(kind: kind))
                            componentBinding.wrappedValue = values
                        }
                    }
                } label: {
                    Label("Hydraulisches Bauteil hinzufügen", systemImage: "plus.circle")
                }

                Toggle("Bauteilaufnahme vollständig", isOn: componentAssessmentBinding)
                    .disabled(!componentValuesComplete)
            } header: {
                Text("Bauteile")
            } footer: {
                Text("Änderungen an Bauteilen setzen die Vollständigkeitsbestätigung zurück. Erst wenn alle erfassten Bauteile einen gültigen Δp-Wert haben, kann die Aufnahme wieder als vollständig bestätigt werden.")
            }

            valveSettingSection
        }
        .navigationTitle(surface.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Speicherfehler", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                templateStore.persistenceError = nil
                valveSelectionStore.persistenceError = nil
            }
        } message: {
            Text(templateStore.persistenceError ?? valveSelectionStore.persistenceError ?? "Unbekannter Fehler")
        }
    }

    @ViewBuilder
    private var valveSettingSection: some View {
        Section {
            if valveIndices.isEmpty {
                Text("Noch keine Thermostat- oder Rücklaufventile im Kreis.")
                    .foregroundStyle(.secondary)
            }

            ForEach(valveIndices, id: \.self) { index in
                let component = componentBinding.wrappedValue[index]
                VStack(alignment: .leading, spacing: 8) {
                    Text(component.name)
                        .font(.subheadline.weight(.semibold))
                    if let current = valveSelectionStore.selection(projectID: projectID, componentID: component.id) {
                        let fresh = current.matchesCurrent(
                            component: component,
                            requiredKvM3H: requiredKv(for: component),
                            targetVolumeFlowLPH: hydronic?.targetVolumeFlowLPH,
                            densityKGPerM3: densityKGPerM3
                        )
                        Label(
                            current.selectedSetting + " · kv " + current.selectedKvM3H.formatted(.number.precision(.fractionLength(3)))
                                + (fresh ? " · aktuell" : " · neu bewerten"),
                            systemImage: fresh ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(fresh ? Color.green : Color.orange)

                        Button(role: .destructive) {
                            valveSelectionStore.delete(projectID: projectID, componentID: component.id)
                        } label: {
                            Label("Festgehaltene Einstellung entfernen", systemImage: "trash")
                        }
                        .font(.caption)
                    }

                    if let data = component.valveProductData,
                       let requiredKv = requiredKv(for: component),
                       let targetFlow = hydronic?.targetVolumeFlowLPH,
                       let density = densityKGPerM3 {
                        Text("Soll-kv ≈ \(requiredKv.formatted(.number.precision(.fractionLength(3)))) m³/h · \(data.manufacturer) \(data.productName)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Menu("Dokumentierten Datenpunkt festhalten") {
                            ForEach(data.presetPoints.filter { ($0.kvM3H ?? 0) > 0 }) { point in
                                Button(point.setting + " · kv " + (point.kvM3H?.formatted(.number.precision(.fractionLength(3))) ?? "—")) {
                                    let liveComponent = componentBinding.wrappedValue[index]
                                    if let selection = HeizBalanceValveSettingSelection(
                                        projectID: projectID,
                                        surfaceID: surface.id,
                                        component: liveComponent,
                                        point: point,
                                        requiredKvM3H: requiredKv,
                                        targetVolumeFlowLPH: targetFlow,
                                        densityKGPerM3: density
                                    ) {
                                        valveSelectionStore.save(selection)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("Für eine explizite Einstellung fehlen Ventildatensatz, Soll-kv, Ziel-Volumenstrom oder Fluiddichte.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Ventil-/Rücklaufeinstellungen")
        } footer: {
            Text("Es wird ausschließlich der von dir ausdrücklich gewählte dokumentierte Hersteller-Datenpunkt festgehalten. Der mathematisch nächste kv-Punkt wird niemals automatisch als Voreinstellung übernommen.")
        }
    }

    private func requiredKv(for component: HeizBalanceHydraulicLossComponent) -> Double? {
        guard component.supportsValveProductData,
              let targetFlow = hydronic?.targetVolumeFlowLPH,
              let pressureLoss = component.pressureLossKPa,
              let density = densityKGPerM3 else { return nil }
        return HeizBalanceValveSizingPreparationCalculator.calculate(
            .init(
                targetVolumeFlowLPH: targetFlow,
                valvePressureDropKPa: pressureLoss,
                densityKGPerM3: density
            )
        )?.requiredKvM3H
    }

    private func duplicatePipeSection(_ section: HeizBalancePipeSection) {
        guard let copy = HeizBalanceHydraulicCaptureTemplate.safePipeStructure(from: [section]).first else { return }
        var values = pipeBinding.wrappedValue
        if let index = values.firstIndex(where: { $0.id == section.id }) {
            values.insert(copy, at: index + 1)
        } else {
            values.append(copy)
        }
        pipeBinding.wrappedValue = values
    }

    private func duplicateHydraulicComponent(_ component: HeizBalanceHydraulicLossComponent) {
        guard let copy = HeizBalanceHydraulicCaptureTemplate.safeComponentStructure(from: [component]).first else { return }
        var values = componentBinding.wrappedValue
        if let index = values.firstIndex(where: { $0.id == component.id }) {
            values.insert(copy, at: index + 1)
        } else {
            values.append(copy)
        }
        componentBinding.wrappedValue = values
    }

    private func removeSelectionsForCurrentComponents() {
        let ids = Set((surface.hydraulicLossComponents ?? []).map(\.id))
        valveSelectionStore.delete(projectID: projectID, componentIDs: ids)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { templateStore.persistenceError != nil || valveSelectionStore.persistenceError != nil },
            set: { if !$0 { templateStore.persistenceError = nil; valveSelectionStore.persistenceError = nil } }
        )
    }
}
