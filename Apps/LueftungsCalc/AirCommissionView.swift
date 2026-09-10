import SwiftUI

private func streamTitle(_ stream: AirStream) -> String { stream == .supply ? tr("Zuluft", "Supply") : tr("Abluft", "Extract") }

struct AirCommissionHome: View {
    @StateObject private var store = FieldStore<AirCommission>("air-commissions")
    @State private var draft: AirCommission?
    var body: some View {
        TabView {
            NavigationStack {
                List {
                    WorkHero(eyebrow: "LüftungsCalc", title: tr("Vom Sollwert zum Messprotokoll.", "From design flow to measured proof."), description: tr("Luftauslässe erfassen, Istwerte vergleichen und offene Messpunkte gezielt nacharbeiten.", "Record air terminals, compare measured flow and revisit the points that still need attention."), icon: "wind", color: .teal)
                    Button { draft = AirCommission() } label: { Label(tr("Einmessung beginnen", "Start commissioning"), systemImage: "plus.circle.fill").font(.headline).padding(.vertical, 8) }
                    if store.items.isEmpty { WorkEmpty(title: tr("Jeder Auslass zählt", "Every terminal counts"), detail: tr("Beginne mit den geplanten Volumenströmen. Messwerte kannst du später ergänzen.", "Start with the design flow rates. Add measurements when you are on site."), icon: "checklist") }
                    ForEach(store.items) { project in
                        NavigationLink { AirCommissionDetail(store: store, id: project.id) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(project.name).font(.headline)
                                Text("\(project.terminals.count) " + tr("Auslässe", "terminals") + " · \(project.missingCount) " + tr("offen", "unmeasured")).foregroundStyle(.secondary)
                                if project.outsideCount > 0 { Label("\(project.outsideCount) " + tr("außerhalb Toleranz", "outside tolerance"), systemImage: "exclamationmark.triangle") }
                            }.padding(.vertical, 8)
                        }
                    }
                }.navigationTitle(tr("Einmessungen", "Commissioning"))
            }.tabItem { Label(tr("Protokolle", "Records"), systemImage: "checklist") }
            LueftungsCalcView().tabItem { Label(tr("Auslegung", "Sizing"), systemImage: "ruler") }
        }.tint(Color(red: 0, green: 0.40, blue: 0.43))
            .sheet(item: $draft) { AirCommissionEditor(initial: $0) { store.save($0) } }.workError($store.error)
    }
}

private struct AirCommissionDetail: View {
    @ObservedObject var store: FieldStore<AirCommission>
    let id: UUID
    @State private var editing: AirCommission?
    @State private var attentionOnly = false
    @State private var deleting = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        if let project = store.items.first(where: { $0.id == id }) {
            List {
                Section {
                    WorkMetric(label: tr("Erfasste Messpunkte", "Measured terminals"), value: "\(project.terminals.count - project.missingCount) / \(project.terminals.count)")
                    WorkMetric(label: tr("Außerhalb gewählter Toleranz", "Outside selected tolerance"), value: "\(project.outsideCount)", color: project.outsideCount > 0 ? .red : .primary)
                    Text(tr("Projekttoleranz", "Project tolerance") + " ±\(fieldNumber(project.tolerancePercent)) %").font(.headline)
                }
                Section(tr("Luftmengenbilanz", "Airflow balance")) {
                    ForEach(AirStream.allCases, id: \.self) { stream in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(streamTitle(stream)).font(.headline)
                            Text(tr("Soll", "Target") + " \(fieldNumber(project.target(stream))) m³/h")
                            if let measured = project.measured(stream) { Text(tr("Ist", "Measured") + " \(fieldNumber(measured)) m³/h").font(.title3.bold()) }
                            else { Text(tr("Istsumme erst nach vollständiger Messung verfügbar", "Measured total available once all terminals are measured")).foregroundStyle(.secondary) }
                        }.padding(.vertical, 6)
                    }
                    if let supply = project.measured(.supply), let extract = project.measured(.extract) {
                        WorkMetric(label: tr("Differenz Zuluft − Abluft", "Supply − extract difference"), value: "\(fieldNumber(supply - extract)) m³/h")
                    }
                }
                Section(tr("Messpunkte", "Measurement points")) {
                    Toggle(tr("Nur offene und abweichende Punkte", "Only unmeasured and out-of-tolerance points"), isOn: $attentionOnly)
                    ForEach(project.terminals.filter { !attentionOnly || $0.meetsTolerance(project.tolerancePercent) != true }) { terminal in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(terminal.name).font(.headline)
                            Text(streamTitle(terminal.stream)).foregroundStyle(.secondary)
                            Text(tr("Soll", "Target") + " \(fieldNumber(terminal.targetM3H)) m³/h")
                            if let measured = terminal.measuredM3H, let deviation = terminal.deviationPercent {
                                WorkMetric(label: tr("Gemessen", "Measured"), value: "\(fieldNumber(measured)) m³/h")
                                let accepted = terminal.meetsTolerance(project.tolerancePercent) == true
                                Label("\(fieldNumber(deviation)) % · " + (accepted ? tr("In Toleranz", "Within tolerance") : tr("Nacharbeiten", "Needs adjustment")), systemImage: accepted ? "checkmark.circle" : "exclamationmark.triangle")
                                    .foregroundStyle(accepted ? Color.primary : Color.red)
                            } else { Label(tr("Noch nicht gemessen", "Not measured yet"), systemImage: "clock") }
                            if !terminal.note.isEmpty { Text(terminal.note).foregroundStyle(.secondary) }
                        }.padding(.vertical, 8)
                    }
                }
                Section(tr("Protokollgrundlage", "Record basis")) {
                    Text(tr("Toleranz frei nach Projektvorgabe; keine automatische Norm- oder Abnahmebestätigung. Messbedingungen und Messgerät in den Notizen dokumentieren.", "Tolerance is your project setting; this does not certify compliance or acceptance. Record measurement conditions and instrument in the notes."))
                    if !project.notes.isEmpty { Text(project.notes) }
                    ShareLink(item: airReport(project)) { Label(tr("Einmessprotokoll teilen", "Share commissioning record"), systemImage: "square.and.arrow.up") }
                    Button(tr("Protokoll löschen", "Delete record"), role: .destructive) { deleting = true }
                }
            }.navigationTitle(project.name)
                .toolbar { Button(tr("Messen / Bearbeiten", "Measure / Edit")) { editing = project } }
                .sheet(item: $editing) { AirCommissionEditor(initial: $0) { store.save($0) } }.workError($store.error)
                .confirmationDialog(tr("Protokoll endgültig löschen?", "Permanently delete record?"), isPresented: $deleting, titleVisibility: .visible) {
                    Button(tr("Löschen", "Delete"), role: .destructive) { store.delete(project); if store.error == nil { dismiss() } }
                }
        }
    }
}

private struct AirCommissionEditor: View {
    @State var initial: AirCommission
    let save: (AirCommission) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var failed = false
    var body: some View {
        NavigationStack {
            Form {
                Section(tr("Projekt", "Project")) {
                    TextField(tr("Anlage / Projekt", "System / project"), text: $initial.name)
                    WorkNumber(title: tr("Zulässige Abweichung ±", "Permitted deviation ±"), value: $initial.tolerancePercent, unit: "%")
                }
                Section(tr("Luftauslässe", "Air terminals")) {
                    ForEach($initial.terminals) { $terminal in
                        DisclosureGroup(terminal.name) {
                            TextField(tr("Raum / Auslassnummer", "Room / terminal number"), text: $terminal.name)
                            Picker(tr("Luftart", "Air stream"), selection: $terminal.stream) {
                                ForEach(AirStream.allCases, id: \.self) { Text(streamTitle($0)).tag($0) }
                            }
                            WorkNumber(title: tr("Sollvolumenstrom", "Target flow"), value: $terminal.targetM3H, unit: "m³/h")
                            Toggle(tr("Messwert liegt vor", "Measurement available"), isOn: Binding(get: { terminal.measuredM3H != nil }, set: { terminal.measuredM3H = $0 ? 0 : nil }))
                            if terminal.measuredM3H != nil {
                                WorkNumber(title: tr("Gemessener Volumenstrom", "Measured flow"), value: Binding(get: { terminal.measuredM3H ?? 0 }, set: { terminal.measuredM3H = $0 }), unit: "m³/h")
                            }
                            TextField(tr("Ventilstellung / Messnotiz", "Valve setting / measurement note"), text: $terminal.note, axis: .vertical)
                        }
                    }.onDelete { initial.terminals.remove(atOffsets: $0) }
                    Button { var terminal = AirTerminal(); terminal.name = tr("Auslass", "Terminal") + " \(initial.terminals.count + 1)"; initial.terminals.append(terminal) } label: { Label(tr("Auslass hinzufügen", "Add terminal"), systemImage: "plus") }
                }
                Section(tr("Messbedingungen", "Measurement conditions")) { TextField(tr("Datum, Messgerät, Betriebsstufe …", "Date, instrument, operating mode …"), text: $initial.notes, axis: .vertical) }
                if !initial.isValid { WorkValidation(message: tr("Projekt und Auslässe benennen. Sollwerte > 0, Messwerte ≥ 0, Toleranz 0–100 %.", "Name the project and terminals. Targets > 0, measurements ≥ 0, tolerance 0–100%.")) }
            }.navigationTitle(tr("Einmessprotokoll", "Commissioning record"))
                .toolbar { WorkActions(valid: initial.isValid) { if save(initial) { dismiss() } else { failed = true } } }
                .alert(tr("Nicht gespeichert. Speicherplatz prüfen.", "Not saved. Check device storage."), isPresented: $failed) {}
        }.interactiveDismissDisabled()
    }
}

private func airReport(_ project: AirCommission) -> String {
    var lines = ["LüftungsCalc – \(project.name)", Date().formatted(), tr("Projekttoleranz", "Project tolerance") + " ±\(fieldNumber(project.tolerancePercent)) %"]
    for terminal in project.terminals {
        let measured = terminal.measuredM3H.map { "\(fieldNumber($0)) m³/h" } ?? tr("nicht gemessen", "not measured")
        let deviation = terminal.deviationPercent.map { "\(fieldNumber($0)) %" } ?? "—"
        lines.append("\(terminal.name) · \(streamTitle(terminal.stream)): " + tr("Soll", "Target") + " \(fieldNumber(terminal.targetM3H)) m³/h; " + tr("Ist", "Measured") + " \(measured); Δ \(deviation); \(terminal.note)")
    }
    for stream in AirStream.allCases {
        lines.append(streamTitle(stream) + ": " + tr("Soll", "Target") + " \(fieldNumber(project.target(stream))) m³/h; " + tr("Ist", "Measured") + " " + (project.measured(stream).map { "\(fieldNumber($0)) m³/h" } ?? tr("unvollständig", "incomplete")))
    }
    lines += ["\(project.missingCount) " + tr("Messpunkte offen", "points unmeasured"), "\(project.outsideCount) " + tr("außerhalb Toleranz", "outside tolerance"), project.notes, tr("Projektbezogener Soll-/Ist-Vergleich; keine Norm- oder Abnahmebestätigung.", "Project-specific target/measured comparison; not a compliance or acceptance certificate.")]
    return lines.joined(separator: "\n")
}
