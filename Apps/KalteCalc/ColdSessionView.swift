import SwiftUI
import Charts

struct ColdSessionHome: View {
    @StateObject private var store = FieldStore<ColdSession>("cold-sessions")
    @State private var draft: ColdSession?
    var body: some View {
        TabView {
            NavigationStack {
                List {
                    if store.items.isEmpty {
                    WorkHero(eyebrow: "KälteCalc", title: tr("Ein Messwert ist nur der Anfang.", "One reading is only the start."), description: tr("Überhitzung und Unterkühlung über einen Serviceeinsatz verfolgen. Eingriffe und Betriebszustände direkt am Messpunkt festhalten.", "Track superheat and subcooling throughout a service visit. Attach adjustments and operating conditions to each reading."), icon: "waveform.path.ecg", color: .indigo)
                    }
                    Button { draft = ColdSession() } label: { Label(tr("Serviceverlauf starten", "Start service session"), systemImage: "plus.circle.fill").font(.headline).padding(.vertical, 8) }
                    if store.items.isEmpty { WorkEmpty(title: tr("Vorher. Eingriff. Nachher.", "Before. Adjustment. After."), detail: tr("Dokumentiere die Stabilisierung mit mehreren zeitgestempelten Messungen.", "Document stabilization with a sequence of timestamped readings."), icon: "clock.arrow.circlepath") }
                    ForEach(store.items) { session in
                        NavigationLink { ColdSessionDetail(store: store, id: session.id) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(session.name).font(.headline)
                                Text("\(session.readings.count) " + tr("Messungen", "readings") + (session.refrigerant.isEmpty ? "" : " · \(session.refrigerant)")).foregroundStyle(.secondary)
                                if let last = session.chronological.last { Text(last.date.formatted(date: .abbreviated, time: .shortened)).font(.subheadline) }
                            }.padding(.vertical, 8)
                        }
                    }
                }.navigationTitle(tr("Serviceverläufe", "Service sessions"))
            }.tabItem { Label(tr("Messverlauf", "Sessions"), systemImage: "waveform.path.ecg") }
            KalteCalcView().environment(\.colorScheme, .dark).tabItem { Label(tr("Werkzeuge", "Tools"), systemImage: "wrench.and.screwdriver") }
        }.tint(.indigo)
            .sheet(item: $draft) { ColdSessionEditor(initial: $0) { store.save($0) } }.workError($store.error)
    }
}

private struct ColdSessionDetail: View {
    @ObservedObject var store: FieldStore<ColdSession>
    let id: UUID
    @State private var editing: ColdSession?
    @State private var deleting = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        if let session = store.items.first(where: { $0.id == id }) {
            List {
                Section {
                    if !session.refrigerant.isEmpty { LabeledContent(tr("Kältemittel", "Refrigerant"), value: session.refrigerant) }
                    if let last = session.chronological.last {
                        WorkMetric(label: tr("Letzte Überhitzung", "Latest superheat"), value: "\(fieldNumber(last.superheatK)) K")
                        WorkMetric(label: tr("Letzte Unterkühlung", "Latest subcooling"), value: "\(fieldNumber(last.subcoolingK)) K")
                    }
                    if let change = session.superheatChangeK { WorkMetric(label: tr("Überhitzung · Änderung erste → letzte Messung", "Superheat · first → last change"), value: "\(fieldNumber(change)) K") }
                }
                if session.readings.count > 1 {
                    Section(tr("Verlauf", "Trend")) {
                        Chart(session.chronological) { reading in
                            LineMark(x: .value(tr("Zeit", "Time"), reading.date), y: .value("K", reading.superheatK))
                                .foregroundStyle(by: .value(tr("Messgröße", "Quantity"), tr("Überhitzung", "Superheat")))
                                .symbol(by: .value(tr("Messgröße", "Quantity"), tr("Überhitzung", "Superheat")))
                            LineMark(x: .value(tr("Zeit", "Time"), reading.date), y: .value("K", reading.subcoolingK))
                                .foregroundStyle(by: .value(tr("Messgröße", "Quantity"), tr("Unterkühlung", "Subcooling")))
                                .symbol(by: .value(tr("Messgröße", "Quantity"), tr("Unterkühlung", "Subcooling")))
                        }.frame(height: 240).chartYAxisLabel("K")
                            .accessibilityLabel(tr("Überhitzung und Unterkühlung im Zeitverlauf. Alle Messwerte stehen in der folgenden Liste.", "Superheat and subcooling over time. All readings are listed below."))
                    }
                }
                Section(tr("Messchronik", "Measurement log")) {
                    ForEach(session.chronological) { reading in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(reading.date.formatted(date: .abbreviated, time: .shortened)).font(.headline)
                            Text(tr("Überhitzung", "Superheat") + " \(fieldNumber(reading.superheatK)) K · " + tr("Unterkühlung", "Subcooling") + " \(fieldNumber(reading.subcoolingK)) K").font(.title3.bold())
                            if reading.superheatK < 0 || reading.subcoolingK < 0 { Label(tr("Negativer Wert: Messpunkte und Betriebszustand prüfen", "Negative value: check measurement points and operating state"), systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
                            Text(tr("Sauggas / Verdampfung", "Suction gas / evaporation") + " \(fieldNumber(reading.suctionC)) / \(fieldNumber(reading.evaporationC)) °C")
                            Text(tr("Kondensation / Flüssigkeit", "Condensation / liquid") + " \(fieldNumber(reading.condensationC)) / \(fieldNumber(reading.liquidC)) °C")
                            if !reading.note.isEmpty { Text(reading.note).foregroundStyle(.secondary) }
                        }.padding(.vertical, 8)
                    }
                }
                Section(tr("Messgrundlage", "Measurement basis")) {
                    Text(tr("Sättigungstemperaturen aus einem geeigneten Messgerät oder Herstellerdaten übernehmen. Bei Gemischen Taupunkt für Überhitzung und Blasenpunkt für Unterkühlung beachten. Kältemittelname dient der Dokumentation; keine automatische Druck-Temperatur-Umrechnung. Zielwerte nach Hersteller und Betriebszustand beurteilen.", "Enter saturation temperatures from a suitable instrument or manufacturer data. For blends, use dew point for superheat and bubble point for subcooling. The refrigerant name is documentation only; no automatic pressure-temperature conversion. Assess targets against manufacturer guidance and operating conditions."))
                    if !session.notes.isEmpty { Text(session.notes) }
                    ShareLink(item: coldReport(session)) { Label(tr("Serviceprotokoll teilen", "Share service report"), systemImage: "square.and.arrow.up") }
                    Button(tr("Serviceverlauf löschen", "Delete session"), role: .destructive) { deleting = true }
                }
            }.navigationTitle(session.name)
                .toolbar { Button(tr("Messung / Bearbeiten", "Reading / Edit")) { editing = session } }
                .sheet(item: $editing) { ColdSessionEditor(initial: $0) { store.save($0) } }.workError($store.error)
                .confirmationDialog(tr("Serviceverlauf endgültig löschen?", "Permanently delete session?"), isPresented: $deleting, titleVisibility: .visible) {
                    Button(tr("Löschen", "Delete"), role: .destructive) { store.delete(session); if store.error == nil { dismiss() } }
                }
        }
    }
}

private struct ColdSessionEditor: View {
    @State var initial: ColdSession
    let save: (ColdSession) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var failed = false
    var body: some View {
        NavigationStack {
            Form {
                Section(tr("Serviceeinsatz", "Service visit")) {
                    TextField(tr("Anlage / Auftrag", "System / job"), text: $initial.name)
                    TextField(tr("Kältemittel laut Typenschild", "Refrigerant from nameplate"), text: $initial.refrigerant)
                }
                Section(tr("Messpunkte", "Readings")) {
                    ForEach($initial.readings) { $reading in
                        DisclosureGroup(reading.date.formatted(date: .abbreviated, time: .shortened)) {
                            DatePicker(tr("Messzeitpunkt", "Measured at"), selection: $reading.date)
                            WorkNumber(title: tr("Sauggastemperatur", "Suction gas temperature"), value: $reading.suctionC, unit: "°C")
                            WorkNumber(title: tr("Sättigung Verdampfung · Taupunkt", "Evaporation saturation · dew point"), value: $reading.evaporationC, unit: "°C")
                            WorkNumber(title: tr("Sättigung Kondensation · Blasenpunkt", "Condensation saturation · bubble point"), value: $reading.condensationC, unit: "°C")
                            WorkNumber(title: tr("Flüssigkeitsleitung", "Liquid line"), value: $reading.liquidC, unit: "°C")
                            TextField(tr("Betriebszustand / Eingriff", "Operating state / adjustment"), text: $reading.note, axis: .vertical)
                        }.accessibilityIdentifier("cold-reading")
                    }.onDelete { initial.readings.remove(atOffsets: $0) }
                    Button { var reading = ColdReading(); reading.suctionC = .nan; reading.evaporationC = .nan; reading.condensationC = .nan; reading.liquidC = .nan; initial.readings.append(reading) } label: { Label(tr("Messung hinzufügen", "Add reading"), systemImage: "plus") }
                }
                Section(tr("Einsatznotizen", "Visit notes")) { TextField(tr("Messgerät, Umgebung, Auftrag …", "Instrument, ambient conditions, job …"), text: $initial.notes, axis: .vertical) }
                if !initial.isValid { WorkValidation(message: tr("Anlage benennen und gültige Temperaturen zwischen −150 und 200 °C eintragen.", "Name the system and enter valid temperatures between −150 and 200 °C.")) }
            }.navigationTitle(tr("Servicemessung", "Service readings"))
                .toolbar { WorkActions(valid: initial.isValid) { if save(initial) { dismiss() } else { failed = true } } }
                .alert(tr("Nicht gespeichert. Speicherplatz prüfen.", "Not saved. Check device storage."), isPresented: $failed) {}
        }.interactiveDismissDisabled()
    }
}

private func coldReport(_ session: ColdSession) -> String {
    var lines = ["KälteCalc – \(session.name)", session.refrigerant, tr("Zeit; Sauggas; Verdampfung; Kondensation; Flüssigkeit; Überhitzung; Unterkühlung; Notiz", "Time; suction gas; evaporation; condensation; liquid; superheat; subcooling; note")]
    for reading in session.chronological {
        lines.append("\(reading.date.formatted(date: .numeric, time: .standard)); \(fieldNumber(reading.suctionC)) °C; \(fieldNumber(reading.evaporationC)) °C; \(fieldNumber(reading.condensationC)) °C; \(fieldNumber(reading.liquidC)) °C; \(fieldNumber(reading.superheatK)) K; \(fieldNumber(reading.subcoolingK)) K; \(reading.note)")
    }
    lines += [session.notes, tr("Sättigungstemperaturen manuell übernommen. Keine automatische Druck-Temperatur-Umrechnung oder Freigabe des Anlagenzustands.", "Saturation temperatures entered manually. No automatic pressure-temperature conversion or approval of system condition.")]
    return lines.joined(separator: "\n")
}
