import SwiftUI
import Charts

struct PipeRouteHome: View {
    @StateObject private var store = FieldStore<PipeRoute>("pipe-routes")
    @State private var draft: PipeRoute?
    var body: some View {
        TabView {
            NavigationStack {
                List {
                    if store.items.isEmpty {
                    WorkHero(eyebrow: "RohrCalc", title: tr("Die ganze Strecke zählt.", "Follow the whole route."), description: tr("Rohrabschnitte und Formstücke zu einem Fließweg verbinden. Druckverlust und den größten Verlustbeitrag erkennen.", "Connect pipe sections and fittings into one flow path. See total pressure loss and the largest contribution."), icon: "point.topleft.down.to.point.bottomright.curvepath", color: .blue)
                    }
                    Button { draft = PipeRoute() } label: { Label(tr("Fließweg anlegen", "Create flow path"), systemImage: "plus.circle.fill").font(.headline).padding(.vertical, 8) }
                    if store.items.isEmpty { WorkEmpty(title: tr("Vom Anschluss bis zum Verbraucher", "From connection to terminal"), detail: tr("Erfasse nacheinander Länge, Innendurchmesser und Formstücke jedes Abschnitts.", "Record each section's length, internal diameter and fittings in sequence."), icon: "point.3.connected.trianglepath.dotted") }
                    ForEach(store.items) { route in
                        NavigationLink { PipeRouteDetail(store: store, id: route.id) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(route.name).font(.headline)
                                Text("\(route.sections.count) " + tr("Abschnitte", "sections") + " · \(fieldNumber(route.totalLossKPa, digits: 2)) kPa").foregroundStyle(.secondary)
                            }.padding(.vertical, 8)
                        }
                    }
                }.navigationTitle(tr("Fließwege", "Flow paths"))
            }.tabItem { Label(tr("Strecken", "Routes"), systemImage: "point.topleft.down.to.point.bottomright.curvepath") }
            RohrCalcView().environment(\.colorScheme, .dark).tabItem { Label(tr("Einzelrechner", "Calculator"), systemImage: "function") }
        }.tint(.blue)
        .sheet(item: $draft) { PipeRouteEditor(initial: $0) { store.save($0) } }.workError($store.error)
    }
}

private struct PipeRouteDetail: View {
    @ObservedObject var store: FieldStore<PipeRoute>
    let id: UUID
    @State private var editing: PipeRoute?
    @State private var deleting = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        if let route = store.items.first(where: { $0.id == id }) {
            List {
                Section {
                    WorkMetric(label: tr("Gesamter Druckverlust", "Total pressure loss"), value: "\(fieldNumber(route.totalLossKPa, digits: 2)) kPa", color: .blue)
                    WorkMetric(label: tr("Wassersäule des Fließwegs", "Flow-path water head"), value: "\(fieldNumber(PipeCalculator.metersWaterColumn(pressureLossKPa: route.totalLossKPa), digits: 2)) m")
                    LabeledContent(tr("Gemeinsamer Volumenstrom", "Common flow rate"), value: "\(fieldNumber(route.flowLPH)) l/h")
                    LabeledContent(tr("Rohrinhalt", "Pipe water volume"), value: "\(fieldNumber(route.totalVolumeL, digits: 2)) l")
                    if let largest = route.largestLossSection { Text(tr("Größter Verlustbeitrag: ", "Largest loss contribution: ") + largest.name).font(.headline) }
                }
                if !route.sections.isEmpty {
                    Section(tr("Verlustanteile", "Loss contributions")) {
                        Chart(route.sections) { section in
                            BarMark(x: .value("kPa", section.result(flow: route.flowLPH).totalPressureLossIncludingLocalKPa), y: .value(tr("Abschnitt", "Section"), section.name))
                                .foregroundStyle(.blue)
                        }.frame(height: max(180, CGFloat(route.sections.count) * 50))
                            .accessibilityLabel(tr("Druckverlust nach Abschnitt. Einzelwerte folgen in der Streckenliste.", "Pressure loss by section. Values follow in the section list."))
                    }
                }
                Section(tr("Streckenliste · in Fließrichtung", "Sections · in flow direction")) {
                    ForEach(Array(route.sections.enumerated()), id: \.element.id) { index, section in
                        let result = section.result(flow: route.flowLPH)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(index + 1). \(section.name)").font(.headline)
                            Text("\(fieldNumber(section.lengthM)) m · Ø \(fieldNumber(section.diameterMM)) mm · ζ \(fieldNumber(section.zeta, digits: 2))")
                            WorkMetric(label: tr("Abschnitt gesamt", "Section total"), value: "\(fieldNumber(result.totalPressureLossIncludingLocalKPa, digits: 2)) kPa")
                            Text(tr("Rohrreibung", "Pipe friction") + " \(fieldNumber(result.base.totalPressureDropKPa, digits: 2)) kPa · " + tr("Formstücke", "Fittings") + " \(fieldNumber(result.localPressureLossKPa, digits: 2)) kPa")
                            Text("v = \(fieldNumber(result.base.velocityMS, digits: 2)) m/s · Re = \(fieldNumber(result.reynoldsNumber, digits: 0))").foregroundStyle(.secondary)
                        }.padding(.vertical, 8)
                    }
                }
                Section(tr("Berechnungsgrenzen", "Calculation scope")) {
                    Text(tr("Ein serieller Fließweg mit gleichem Volumenstrom in allen Abschnitten. Wasser bei etwa 20 °C (ρ 998 kg/m³; ν 1,004·10⁻⁶ m²/s). Keine Netzberechnung. Geräteverluste, weitere Kreise und geodätische Förderhöhe sind nicht enthalten.", "One series flow path with the same flow in every section. Water at approximately 20 °C (ρ 998 kg/m³; ν 1.004×10⁻⁶ m²/s). Not a network calculation. Equipment losses, other circuits and static elevation head are excluded."))
                    if !route.notes.isEmpty { Text(route.notes) }
                    ShareLink(item: pipeReport(route)) { Label(tr("Streckenbericht teilen", "Share route report"), systemImage: "square.and.arrow.up") }
                    Button(tr("Fließweg löschen", "Delete flow path"), role: .destructive) { deleting = true }
                }
            }.navigationTitle(route.name)
                .toolbar { Button(tr("Bearbeiten", "Edit")) { editing = route } }
                .sheet(item: $editing) { PipeRouteEditor(initial: $0) { store.save($0) } }
                .workError($store.error)
                .confirmationDialog(tr("Fließweg endgültig löschen?", "Permanently delete flow path?"), isPresented: $deleting, titleVisibility: .visible) {
                    Button(tr("Löschen", "Delete"), role: .destructive) { store.delete(route); if store.error == nil { dismiss() } }
                }
        }
    }
}

private struct PipeRouteEditor: View {
    @State var initial: PipeRoute
    let save: (PipeRoute) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var failed = false
    var body: some View {
        NavigationStack {
            Form {
                Section(tr("Fließweg", "Flow path")) {
                    TextField(tr("Bezeichnung", "Name"), text: $initial.name)
                    WorkNumber(title: tr("Volumenstrom aller Abschnitte", "Flow rate through all sections"), value: $initial.flowLPH, unit: "l/h")
                }
                Section(tr("Abschnitte · zum Sortieren Bearbeiten wählen", "Sections · use Edit to reorder")) {
                    ForEach($initial.sections) { $section in
                        DisclosureGroup(section.name) {
                            TextField(tr("Abschnitt", "Section"), text: $section.name)
                            WorkNumber(title: tr("Länge", "Length"), value: $section.lengthM, unit: "m")
                            WorkNumber(title: tr("Innendurchmesser", "Internal diameter"), value: $section.diameterMM, unit: "mm")
                            WorkNumber(title: tr("Absolute Rauheit", "Absolute roughness"), value: $section.roughnessMM, unit: "mm")
                            WorkNumber(title: tr("Summe Widerstandsbeiwerte", "Sum of loss coefficients"), value: $section.zeta, unit: "ζ")
                        }
                    }.onDelete { initial.sections.remove(atOffsets: $0) }
                        .onMove { initial.sections.move(fromOffsets: $0, toOffset: $1) }
                    Button { var section = PipeSection(); section.name = tr("Abschnitt", "Section") + " \(initial.sections.count + 1)"; initial.sections.append(section) } label: { Label(tr("Abschnitt hinzufügen", "Add section"), systemImage: "plus") }
                }
                Section(tr("Notizen", "Notes")) { TextField(tr("Material, Formstücke, Anlage …", "Material, fittings, system …"), text: $initial.notes, axis: .vertical) }
                if !initial.isValid { WorkValidation(message: tr("Name, positive Länge und Volumenstrom erforderlich. Innendurchmesser 1–2000 mm, Rauheit ≥ 0 und kleiner als Durchmesser, ζ ≥ 0.", "Enter a name, positive length and flow. Internal diameter 1–2000 mm, roughness ≥ 0 and below diameter, ζ ≥ 0.")) }
            }.navigationTitle(tr("Strecke bearbeiten", "Edit route"))
                .toolbar {
                    WorkActions(valid: initial.isValid) { if save(initial) { dismiss() } else { failed = true } }
                    ToolbarItem(placement: .bottomBar) { EditButton() }
                }
                .alert(tr("Nicht gespeichert. Speicherplatz prüfen.", "Not saved. Check device storage."), isPresented: $failed) {}
        }.interactiveDismissDisabled()
    }
}

private func pipeReport(_ route: PipeRoute) -> String {
    var lines = ["RohrCalc – \(route.name)", Date().formatted(), "Q = \(fieldNumber(route.flowLPH)) l/h"]
    for (index, section) in route.sections.enumerated() {
        let result = section.result(flow: route.flowLPH)
        lines.append("\(index + 1). \(section.name): L \(fieldNumber(section.lengthM)) m; di \(fieldNumber(section.diameterMM)) mm; ε \(fieldNumber(section.roughnessMM, digits: 3)) mm; ζ \(fieldNumber(section.zeta, digits: 2)); Δp \(fieldNumber(result.totalPressureLossIncludingLocalKPa, digits: 2)) kPa; v \(fieldNumber(result.base.velocityMS, digits: 2)) m/s")
    }
    lines += ["Σ Δp = \(fieldNumber(route.totalLossKPa, digits: 2)) kPa", "V = \(fieldNumber(route.totalVolumeL, digits: 2)) l", route.notes, tr("Serieller Fließweg; Wasser 20 °C. Geräteverluste, andere Kreise und geodätische Höhe nicht enthalten.", "Series flow path; water at 20 °C. Equipment losses, other circuits and static elevation excluded.")]
    return lines.joined(separator: "\n")
}
