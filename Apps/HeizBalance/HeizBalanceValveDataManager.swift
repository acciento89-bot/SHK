import SwiftUI

struct HeizBalanceValveDataManager: View {
    @Environment(HeizBalanceValveDatasetStore.self) private var valveDatasetStore
    @Binding var project: HeizBalanceProject

    private struct ValveEntry: Identifiable {
        var id: UUID { componentID }
        var floorID: UUID
        var roomID: UUID
        var surfaceID: UUID
        var componentID: UUID
        var floorName: String
        var roomName: String
        var surfaceName: String
        var componentName: String
        var kind: HeizBalanceHydraulicLossComponent.Kind
        var snapshot: HeizBalanceHydraulicLossComponent
    }

    private var valveEntries: [ValveEntry] {
        var entries: [ValveEntry] = []

        for floor in project.floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    for component in surface.hydraulicLossComponents ?? [] where component.supportsValveProductData {
                        entries.append(
                            ValveEntry(
                                floorID: floor.id,
                                roomID: room.id,
                                surfaceID: surface.id,
                                componentID: component.id,
                                floorName: floor.name,
                                roomName: room.name,
                                surfaceName: surface.name,
                                componentName: component.name,
                                kind: component.kind,
                                snapshot: component
                            )
                        )
                    }
                }
            }
        }

        return entries
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Erfasste Ventile") {
                    Text("\(valveEntries.count)")
                }
                Text("Hier werden ausschließlich projektspezifisch dokumentierte Ventildaten gepflegt. HeizBalance liefert keine vorinstallierten Herstellerkennlinien und kopiert keine fremden Tabellen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Ventildaten")
            }

            Section {
                NavigationLink {
                    HeizBalanceValveDatasetManager()
                } label: {
                    Label("Ventilkataloge verwalten", systemImage: "shippingbox")
                }
                LabeledContent("Importierte Kataloge", value: "\(valveDatasetStore.datasets.count)")
                LabeledContent(
                    "Katalogprodukte",
                    value: "\(valveDatasetStore.datasets.reduce(0) { $0 + $1.products.count })"
                )
            } header: {
                Text("Herstellerdaten")
            } footer: {
                Text("Katalogdaten können nativ oder über ein dokumentiertes VDI-3805-Blatt-2-Mapping importiert werden. Ein Produkt muss anschließend ausdrücklich dem konkreten Projektventil zugeordnet werden.")
            }

            if valveEntries.isEmpty {
                Section {
                    Label("Noch keine Thermostat- oder Rücklaufventile in den Heizflächenkreisen erfasst.", systemImage: "circle.dashed")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Ventile im Projekt") {
                    ForEach(valveEntries) { entry in
                        if let binding = componentBinding(for: entry) {
                            NavigationLink {
                                HeizBalanceValveProductDataEditor(
                                    component: binding,
                                    requiredKvM3H: requiredKvM3H(for: entry)
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Label(entry.componentName, systemImage: "slider.horizontal.3")
                                        Spacer()
                                        if entry.snapshot.valveProductData != nil {
                                            Image(systemName: "doc.text.fill")
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Text("\(entry.roomName) · \(entry.surfaceName) · \(entry.floorName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if let requiredKv = requiredKvM3H(for: entry) {
                                        Text("erforderlicher kv ≈ \(requiredKv.formatted(.number.precision(.fractionLength(3)))) m³/h")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Soll-kv noch nicht berechenbar")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Ventildaten")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func componentBinding(for entry: ValveEntry) -> Binding<HeizBalanceHydraulicLossComponent>? {
        guard locateComponent(entry, in: project) != nil else { return nil }

        return Binding(
            get: {
                guard let location = locateComponent(entry, in: project) else {
                    return entry.snapshot
                }
                return project.floors[location.floor]
                    .rooms[location.room]
                    .heatingSurfaces![location.surface]
                    .hydraulicLossComponents![location.component]
            },
            set: { newValue in
                guard let location = locateComponent(entry, in: project) else { return }
                var updated = project
                updated.floors[location.floor]
                    .rooms[location.room]
                    .heatingSurfaces![location.surface]
                    .hydraulicLossComponents![location.component] = newValue
                project = updated
            }
        )
    }

    private func requiredKvM3H(for entry: ValveEntry) -> Double? {
        guard let location = locateComponent(entry, in: project),
              let density = project.hydraulicFluidDensityKGPerM3 else {
            return nil
        }

        let room = project.floors[location.floor].rooms[location.room]
        guard let surfaces = room.heatingSurfaces else { return nil }
        let surface = surfaces[location.surface]
        guard let components = surface.hydraulicLossComponents else { return nil }
        let component = components[location.component]

        guard let pressureLoss = component.pressureLossKPa,
              let hydronic = surface.hydronicPreparation(
                flowTemperatureC: project.designFlowTemperatureC,
                returnTemperatureC: project.designReturnTemperatureC,
                roomTemperatureC: room.targetTemperature
              ),
              let sizing = HeizBalanceValveSizingPreparationCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: hydronic.targetVolumeFlowLPH,
                    valvePressureDropKPa: pressureLoss,
                    densityKGPerM3: density
                )
              ) else {
            return nil
        }

        return sizing.requiredKvM3H
    }

    private func locateComponent(
        _ entry: ValveEntry,
        in project: HeizBalanceProject
    ) -> (floor: Int, room: Int, surface: Int, component: Int)? {
        guard let floorIndex = project.floors.firstIndex(where: { $0.id == entry.floorID }),
              let roomIndex = project.floors[floorIndex].rooms.firstIndex(where: { $0.id == entry.roomID }),
              let surfaces = project.floors[floorIndex].rooms[roomIndex].heatingSurfaces,
              let surfaceIndex = surfaces.firstIndex(where: { $0.id == entry.surfaceID }),
              let components = surfaces[surfaceIndex].hydraulicLossComponents,
              let componentIndex = components.firstIndex(where: { $0.id == entry.componentID }) else {
            return nil
        }

        return (floorIndex, roomIndex, surfaceIndex, componentIndex)
    }
}

struct HeizBalanceValveProductDataEditor: View {
    @Environment(HeizBalanceValveDatasetStore.self) private var valveDatasetStore
    @Binding var component: HeizBalanceHydraulicLossComponent
    let requiredKvM3H: Double?

    private var productDataBinding: Binding<HeizBalanceValveProductData> {
        Binding(
            get: { component.valveProductData ?? HeizBalanceValveProductData() },
            set: { component.valveProductData = $0 }
        )
    }

    private var presetPointsBinding: Binding<[HeizBalanceValvePresetPoint]> {
        Binding(
            get: { component.valveProductData?.presetPoints ?? [] },
            set: { points in
                var data = component.valveProductData ?? HeizBalanceValveProductData()
                data.presetPoints = points
                component.valveProductData = data
            }
        )
    }

    private var metadataComplete: Bool {
        guard let data = component.valveProductData else { return false }
        return !data.manufacturer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !data.productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !data.dataSetVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !data.sourceReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var comparison: HeizBalanceValvePresetComparisonCalculator.Result? {
        guard let requiredKvM3H,
              let data = component.valveProductData,
              !data.presetPoints.isEmpty else {
            return nil
        }

        var points: [HeizBalanceValvePresetComparisonCalculator.SettingPoint] = []
        for point in data.presetPoints {
            guard let kv = point.kvM3H else { return nil }
            points.append(.init(setting: point.setting, kvM3H: kv))
        }

        return HeizBalanceValvePresetComparisonCalculator.calculate(
            .init(requiredKvM3H: requiredKvM3H, points: points)
        )
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Ventilart") {
                    Text(component.kind.title)
                }
                if let requiredKvM3H {
                    LabeledContent("Erforderlicher kv") {
                        Text(requiredKvM3H.formatted(.number.precision(.fractionLength(3))) + " m³/h")
                            .fontWeight(.semibold)
                    }
                } else {
                    Label("Der erforderliche kv ist noch nicht berechenbar. Ziel-Volumenstrom, Ventil-Δp und Fluiddichte prüfen.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Technische Anforderung")
            } footer: {
                Text("Der Soll-kv wird aus dem Ziel-Volumenstrom, dem explizit erfassten Ventil-Druckverlust und der Projekt-Fluiddichte ermittelt.")
            }

            Section {
                NavigationLink {
                    HeizBalanceValveCatalogPicker(
                        component: $component,
                        requiredKvM3H: requiredKvM3H
                    )
                } label: {
                    Label("Produkt aus Katalog übernehmen", systemImage: "shippingbox")
                }

                NavigationLink {
                    HeizBalanceValveDatasetManager()
                } label: {
                    Label("Ventilkataloge verwalten", systemImage: "square.and.arrow.down")
                }

                LabeledContent("Importierte Kataloge", value: "\(valveDatasetStore.datasets.count)")

                if let data = component.valveProductData,
                   let datasetID = data.datasetID {
                    LabeledContent("Zuordnung aus Katalog") {
                        Text(datasetID)
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                    }
                    if let article = data.articleNumber, !article.isEmpty {
                        LabeledContent("Artikelnummer", value: article)
                    }
                }
            } header: {
                Text("Produktkatalog")
            } footer: {
                Text("Die Produktübernahme kopiert den dokumentierten Datensatz in das Projekt. Eine Voreinstellung wird dabei nicht automatisch gesetzt.")
            }

            if component.valveProductData == nil {
                Section {
                    Button {
                        component.valveProductData = HeizBalanceValveProductData()
                    } label: {
                        Label("Ventildatensatz manuell anlegen", systemImage: "plus.circle")
                    }
                } footer: {
                    Text("Es werden keine Herstellerwerte automatisch ergänzt. Jeder Datenpunkt muss aus einer rechtmäßig nutzbaren und dokumentierten Quelle stammen.")
                }
            } else {
                Section {
                    TextField("Hersteller", text: productDataBinding.manufacturer)
                    TextField("Produkt / Typ", text: productDataBinding.productName)
                    TextField("Datensatzversion / Stand", text: productDataBinding.dataSetVersion)
                    TextField("Quelle / Referenz", text: productDataBinding.sourceReference, axis: .vertical)
                        .lineLimit(2...5)

                    if metadataComplete {
                        Label("Datensatzherkunft dokumentiert", systemImage: "checkmark.circle")
                            .font(.caption)
                    } else {
                        Label("Hersteller, Produkt, Datenstand und Quelle vollständig dokumentieren.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if let data = component.valveProductData,
                       let usageBasis = data.usageBasis,
                       !usageBasis.isEmpty {
                        LabeledContent("Nutzungsgrundlage", value: usageBasis)
                    }
                    if let data = component.valveProductData,
                       let rightsNote = data.rightsNote,
                       !rightsNote.isEmpty {
                        LabeledContent("Rechtehinweis") {
                            Text(rightsNote)
                                .font(.caption)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                } header: {
                    Text("Hersteller-Datensatz")
                } footer: {
                    Text("Die Quellenangabe dient der Nachvollziehbarkeit und ersetzt keine erforderliche Lizenz oder Nutzungsfreigabe für fremde Produktdaten.")
                }

                Section {
                    if presetPointsBinding.wrappedValue.isEmpty {
                        Text("Noch keine Voreinstellung/kv-Datenpunkte erfasst")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(presetPointsBinding) { $point in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Voreinstellung", text: $point.setting)
                            OptionalDecimalField(title: "kv", value: $point.kvM3H, unit: "m³/h")
                        }
                        .padding(.vertical, 3)
                    }
                    .onDelete { offsets in
                        var points = presetPointsBinding.wrappedValue
                        points.remove(atOffsets: offsets)
                        presetPointsBinding.wrappedValue = points
                    }

                    Button {
                        var points = presetPointsBinding.wrappedValue
                        points.append(HeizBalanceValvePresetPoint())
                        presetPointsBinding.wrappedValue = points
                    } label: {
                        Label("Datenpunkt hinzufügen", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Voreinstellung → kv")
                } footer: {
                    Text("Nur diskrete Datenpunkte des tatsächlich dokumentierten Ventils erfassen. HeizBalance interpoliert keine nicht freigegebenen Herstellerkennlinien.")
                }

                Section {
                    if let comparison {
                        LabeledContent("Datensatzbereich") {
                            Text(
                                comparison.minimumKvM3H.formatted(.number.precision(.fractionLength(3)))
                                + "–"
                                + comparison.maximumKvM3H.formatted(.number.precision(.fractionLength(3)))
                                + " m³/h"
                            )
                        }

                        if let lower = comparison.lowerPoint {
                            LabeledContent("Unterer Datenpunkt") {
                                Text("\(lower.setting) · kv \(lower.kvM3H.formatted(.number.precision(.fractionLength(3))))")
                            }
                        }
                        if let upper = comparison.upperPoint {
                            LabeledContent("Oberer Datenpunkt") {
                                Text("\(upper.setting) · kv \(upper.kvM3H.formatted(.number.precision(.fractionLength(3))))")
                            }
                        }

                        LabeledContent("Technisch nächster Datenpunkt") {
                            Text(
                                "\(comparison.nearestPoint.setting) · kv "
                                + comparison.nearestPoint.kvM3H.formatted(.number.precision(.fractionLength(3)))
                            )
                            .fontWeight(.semibold)
                        }
                        LabeledContent("Abweichung zum Soll-kv") {
                            Text((comparison.relativeDeviation * 100).formatted(.number.precision(.fractionLength(1))) + " %")
                        }

                        if comparison.exactMatch {
                            Label("Der Soll-kv entspricht exakt einem hinterlegten Datenpunkt.", systemImage: "checkmark.circle")
                                .font(.caption)
                        } else if comparison.requiredKvInsideDataRange {
                            Label("Der Soll-kv liegt innerhalb des hinterlegten Datenbereichs.", systemImage: "info.circle")
                                .font(.caption)
                        } else {
                            Label("Der Soll-kv liegt außerhalb des hinterlegten Datenbereichs.", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    } else if requiredKvM3H == nil {
                        Text("Vergleich wartet auf einen gültigen Soll-kv.")
                            .foregroundStyle(.secondary)
                    } else if presetPointsBinding.wrappedValue.isEmpty {
                        Text("Vergleich wartet auf Ventildatenpunkte.")
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Ventildatensatz enthält unvollständige oder ungültige Datenpunkte.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Technischer Datenvergleich")
                } footer: {
                    Text("Der nächstliegende Datenpunkt ist ausdrücklich keine automatische Hersteller-Voreinstellung oder Verfahren-B-Freigabe. Maßgebend bleiben die gültigen Herstellerunterlagen und die fachliche Prüfung des konkreten Ventils.")
                }

                Section {
                    Button(role: .destructive) {
                        component.valveProductData = nil
                    } label: {
                        Label("Ventildatensatz entfernen", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(component.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
