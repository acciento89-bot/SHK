import SwiftUI
import Charts

func volumeKindName(_ kind: ComponentKind) -> String {
    switch kind {
    case .pipe: S("Rohrleitung", "Pipe")
    case .floorHeating: S("Fußbodenheizung", "Underfloor heating")
    case .wallHeating: S("Wandheizung", "Wall heating")
    case .ceilingHeating: S("Deckenheizung", "Ceiling heating")
    case .radiator: S("Heizkörper", "Radiator")
    case .buffer: S("Puffer / Speicher", "Buffer / tank")
    case .heatGenerator: S("Wärmeerzeuger", "Heat generator")
    case .hydraulicSeparator: S("Hydraulische Weiche", "Hydraulic separator")
    case .distributor: S("Verteiler / Sammler", "Distributor / collector")
    case .heatExchanger: S("Wärmetauscher", "Heat exchanger")
    case .other: S("Sonstiges", "Other")
    }
}

struct SuiteVolumeFields: View {
    @Binding var project: SuiteProject
    let quick: Bool
    let showSheet: (SuiteEntrySheet) -> Void
    var body: some View {
        Group {
        Section {
            SuiteMetric(title: S("Berechneter Wasserinhalt", "Calculated water volume"), value: project.volume.components.isEmpty ? S("Noch kein Inventar", "No inventory yet") : "\(SN(project.volume.calculatedVolumeLiters)) l", tint: .blue)
            SuiteNumberField(S("Planungsreserve", "Planning reserve"), value: $project.volume.reservePercent, unit: "%")
            if !project.volume.components.isEmpty {
                LabeledContent(S("Reserve separat", "Reserve, separately"), value: "\(SN(project.volume.reserveLiters)) l")
                LabeledContent(S("Planungsvolumen", "Planning volume"), value: "\(SN(project.volume.planningVolumeLiters)) l")
            }
            if !project.volume.reservePercent.isFinite || !(0...100).contains(project.volume.reservePercent) { Text(S("Reserve zwischen 0 und 100 % eingeben.", "Enter a reserve between 0 and 100%.")).font(.footnote).foregroundStyle(.red) }
        }
        Section {
            ForEach($project.volume.components) { $component in
                DisclosureGroup {
                    if component.sourcePipeSectionID == nil {
                        TextField(S("Bauteil", "Component"), text: $component.name)
                        SuiteNumberField(S("Menge", "Quantity"), value: $component.quantity, unit: "×")
                        SuiteNumberField(S("Wasserinhalt je Bauteil", "Water volume per component"), value: $component.unitVolumeLiters, unit: "l")
                        TextField(S("Datenquelle / Hersteller", "Data source / manufacturer"), text: Binding(get: { component.source ?? "" }, set: { component.source = $0.isEmpty ? nil : $0 }))
                    } else {
                        Label(S("Mit Rohrnetz verknüpft", "Linked to pipe route"), systemImage: "link")
                        Text(S("Änderungen im Rohrnetz vornehmen und dort den Rohrinhalt aktualisieren.", "Make changes in the pipe route and update pipe volume there.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
                    }
                    LabeledContent(S("Gesamtinhalt", "Total volume"), value: "\(SN(component.totalLiters)) l")
                    if let source = component.source { Text(source).font(.footnote).foregroundStyle(SuiteTheme.secondary).textSelection(.enabled) }
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(component.name).foregroundStyle(.primary)
                        Text("\(volumeKindName(component.kind)) · \(SN(component.totalLiters)) l").font(.subheadline).foregroundStyle(SuiteTheme.secondary)
                    }
                }.deleteDisabled(component.sourcePipeSectionID != nil)
            }.onDelete { offsets in
                for index in offsets.sorted(by: >) where project.volume.components[index].sourcePipeSectionID == nil { project.volume.components.remove(at: index) }
            }
            Button { showSheet(.component) } label: { Label(S("Bauteil nach Herstellerwert hinzufügen", "Add component from manufacturer data"), systemImage: "plus.circle") }.buttonStyle(SuiteRowButtonStyle()).accessibilityIdentifier("volume-add-component")
            Button { showSheet(.pipe) } label: { Label(S("Rohr oder Heizkreis geometrisch erfassen", "Add pipe or heating circuit geometry"), systemImage: "point.topleft.down.to.point.bottomright.curvepath") }.buttonStyle(SuiteRowButtonStyle())
        } header: { Text(S("Bauteil-Inventar", "Component inventory")) }
          footer: { Text(S("Hersteller-Wasserinhalte verwenden. Rohrleitungen nur einmal erfassen: direkt hier oder verknüpft aus dem Rohrnetz.", "Use manufacturer water-content data. Record each pipe once: directly here or linked from the pipe route.")) }
        if !project.volume.components.isEmpty && project.volume.calculatedVolumeLiters > 0 {
            Section {
                // Freeze the current inventory when the user opens the reading.
                // A parent sheet closure can otherwise retain an earlier value.
                Button { showSheet(.fill(project.volume)) } label: { Label(S("Befüllung mit Inventar abgleichen", "Compare actual fill with inventory"), systemImage: "drop.circle") }.buttonStyle(SuiteRowButtonStyle()).accessibilityIdentifier("volume-add-fill")
                ForEach(project.volume.fillChecks ?? []) { check in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(check.date, format: .dateTime.day().month().year()).font(.headline)
                        Text("\(SN(check.netFillL)) l · " + S("Abweichung", "Deviation") + " \(SN(check.deviationL)) l / \(SN(check.deviationPercent ?? 0)) %")
                        Text(S("Inventar zum Messzeitpunkt", "Inventory at measurement") + ": \(SN(check.calculatedBaselineL)) l").font(.subheadline).foregroundStyle(SuiteTheme.secondary)
                        Label(check.isWithinTolerance ? S("Innerhalb Projekttoleranz", "Within project tolerance") : S("Abweichung untersuchen", "Investigate deviation"), systemImage: check.isWithinTolerance ? "checkmark.circle" : "exclamationmark.triangle")
                    }.padding(.vertical, 5)
                }.onDelete { project.volume.fillChecks?.remove(atOffsets: $0) }
            } header: { Text(S("Füllnachweis", "Fill evidence")) }
        }
        Section {
            Text(S("Die Planungsreserve ist kein tatsächlich eingefülltes Wasser. Für den Füllabgleich muss die Anlage anfangs leer sein; Inventar und Messung müssen dieselben Anlagenteile umfassen.", "Planning reserve is not water actually filled. A fill comparison requires an initially empty system and matching system boundaries for inventory and measurement.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
        }
        }
    }
}

struct SuiteVolumeComponentSheet: View {
    let add: (VolumeComponent) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var value = VolumeComponent(kind: .buffer, name: "", unitVolumeLiters: 0)
    private var valid: Bool { !value.name.trimmingCharacters(in: .whitespaces).isEmpty && value.quantity.isFinite && value.quantity > 0 && value.quantity <= 1_000_000 && value.unitVolumeLiters.isFinite && value.unitVolumeLiters > 0 && value.unitVolumeLiters <= 1_000_000_000 }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(S("Bauteilbezeichnung", "Component name"), text: $value.name).accessibilityIdentifier("component-name")
                    Picker(S("Bauteilart", "Component type"), selection: $value.kind) { ForEach(ComponentKind.allCases, id: \.self) { Text(volumeKindName($0)).tag($0) } }
                    SuiteNumberField(S("Menge", "Quantity"), value: $value.quantity, unit: "×")
                    SuiteNumberField(S("Hersteller-Wasserinhalt je Bauteil", "Manufacturer water volume per component"), value: $value.unitVolumeLiters, unit: "l").accessibilityIdentifier("component-unit-liters")
                    TextField(S("Hersteller / Datenblatt / Messung", "Manufacturer / data sheet / measurement"), text: Binding(get: { value.source ?? "" }, set: { value.source = $0 }))
                    TextField(S("Notiz", "Note"), text: Binding(get: { value.note ?? "" }, set: { value.note = $0 }), axis: .vertical)
                }
            }.navigationTitle(S("Bauteil hinzufügen", "Add component")).suiteKeyboard()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(S("Abbrechen", "Cancel")) { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button(S("Hinzufügen", "Add")) { add(value); dismiss() }.disabled(!valid).accessibilityIdentifier("component-save") }
                }
        }
    }
}

struct SuiteVolumePipeSheet: View {
    let add: (VolumeComponent) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var diameter = 12.0
    @State private var length = 100.0
    @State private var count = 1
    @State private var kind = ComponentKind.floorHeating
    private var valid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && diameter.isFinite && (1...2000).contains(diameter) && length.isFinite && length > 0 && length <= 10000 }
    var body: some View {
        NavigationStack {
            Form {
                TextField(S("Bezeichnung", "Name"), text: $name)
                Picker(S("Art", "Type"), selection: $kind) { ForEach([ComponentKind.pipe, .floorHeating, .wallHeating, .ceilingHeating], id: \.self) { Text(volumeKindName($0)).tag($0) } }
                SuiteNumberField(S("Echter Innendurchmesser", "Actual internal diameter"), value: $diameter, unit: "mm")
                SuiteNumberField(S("Länge je Abschnitt / Kreis", "Length per section / circuit"), value: $length, unit: "m")
                Stepper(S("Anzahl", "Quantity") + ": \(count)", value: $count, in: 1...10000)
                if valid { SuiteMetric(title: S("Wasserinhalt gesamt", "Total water volume"), value: "\(SN(VolumeCalculator.pipeVolumeLiters(innerDiameterMM: diameter, lengthMeters: length)*Double(count))) l", tint: .blue) }
            }.navigationTitle(S("Rohr / Heizkreis", "Pipe / circuit")).suiteKeyboard()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(S("Abbrechen", "Cancel")) { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button(S("Hinzufügen", "Add")) {
                        add(VolumeComponent(kind: kind, name: name, quantity: Double(count), unitVolumeLiters: VolumeCalculator.pipeVolumeLiters(innerDiameterMM: diameter, lengthMeters: length), source: S("Geometrie aus echtem Innendurchmesser", "Geometry from actual internal diameter"), note: "di \(SN(diameter)) mm; L \(SN(length)) m")); dismiss()
                    }.disabled(!valid) }
                }
        }
    }
}

struct SuiteFillSheet: View {
    let project: VolumeProject
    let add: (FillCheck) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var check = SuiteFillDraft()
    private var completed: FillCheck? { check.completed(in: project) }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(S("Messzeitpunkt", "Measurement time"), selection: $check.date)
                    SuiteNumberField(S("Zählerstand vorher", "Meter reading before"), optional: $check.meterStartL, unit: "l").accessibilityIdentifier("fill-meter-before")
                    SuiteNumberField(S("Zählerstand nachher", "Meter reading after"), optional: $check.meterEndL, unit: "l").accessibilityIdentifier("fill-meter-after")
                    SuiteNumberField(S("Währenddessen abgelassen / verworfen", "Drained / discarded during filling"), value: $check.drainedL, unit: "l")
                    SuiteNumberField(S("Projekttoleranz", "Project tolerance"), value: $check.tolerancePercent, unit: "%")
                    Toggle(isOn: $check.confirmedEmptySystem) {
                        Text(S("Anlage war anfangs leer; Messung und Inventar umfassen dieselben Bauteile", "System was initially empty; measurement and inventory cover the same components"))
                            .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                    }.accessibilityIdentifier("fill-confirm-boundary")
                }
                Section {
                    Text(S("Unveränderliche Inventar-Basis", "Fixed inventory baseline") + ": \(SN(project.calculatedVolumeLiters)) l")
                    if let completed { SuiteMetric(title: S("Netto eingefüllt", "Net water filled"), value: "\(SN(completed.netFillL)) l", tint: .blue) }
                    TextField(S("Messgerät, Systemgrenzen, Hinweise …", "Instrument, system boundary, notes …"), text: $check.note, axis: .vertical)
                }
            }.navigationTitle(S("Befüllung erfassen", "Record actual fill")).suiteKeyboard()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(S("Abbrechen", "Cancel")) { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button(S("Übernehmen", "Use reading")) { if let completed { add(completed); dismiss() } }.disabled(completed == nil).accessibilityIdentifier("fill-save-reading") }
                }
        }
    }
}
