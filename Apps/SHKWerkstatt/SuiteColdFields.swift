import SwiftUI
import Charts

struct SuiteColdFields: View {
    @Binding var project: SuiteProject
    let addReading: () -> Void
    var body: some View {
        Group {
        Section {
            TextField(S("Kältemittelbezeichnung", "Refrigerant designation"), text: $project.cold.refrigerant)
            Text(S("Sättigungstemperaturen aus verifizierten Stoffdaten oder einem geeigneten Messgerät übernehmen. Die App schätzt keine P/T-Tabelle.", "Use saturation temperatures from verified refrigerant data or a suitable instrument. The app does not invent a P/T table.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
        }
        Section {
            ForEach($project.cold.readings) { $reading in
                DisclosureGroup(reading.date.formatted(date: .abbreviated, time: .shortened)) {
                    DatePicker(S("Messzeitpunkt", "Measurement time"), selection: $reading.date)
                    SuiteNumberField(S("Sauggastemperatur", "Suction-gas temperature"), value: $reading.suctionC, unit: "°C")
                    SuiteNumberField(S("Verdampfungstemperatur", "Evaporating temperature"), value: $reading.evaporationC, unit: "°C")
                    SuiteNumberField(S("Verflüssigungstemperatur", "Condensing temperature"), value: $reading.condensationC, unit: "°C")
                    SuiteNumberField(S("Flüssigkeitsleitung", "Liquid-line temperature"), value: $reading.liquidC, unit: "°C")
                    TextField(S("Eingriff / Messgerät / Beobachtung", "Intervention / instrument / observation"), text: $reading.note, axis: .vertical)
                    if reading.isValid {
                        SuiteMetric(title: S("Überhitzung", "Superheat"), value: "\(SN(reading.superheatK)) K", tint: .indigo)
                        SuiteMetric(title: S("Unterkühlung", "Subcooling"), value: "\(SN(reading.subcoolingK)) K", tint: .blue)
                        if reading.superheatK < 0 || reading.subcoolingK < 0 { Label(S("Negativer Diagnosewert · Messpunkte und Betriebszustand prüfen", "Negative diagnostic value · check measurement points and operating state"), systemImage: "exclamationmark.triangle").font(.subheadline).foregroundStyle(SuiteTheme.copper) }
                    } else { Text(S("Gültige Temperaturen zwischen −150 und 200 °C eingeben.", "Enter valid temperatures between −150 and 200°C.")).font(.footnote).foregroundStyle(.red) }
                }
            }.onDelete { project.cold.readings.remove(atOffsets: $0) }
            Button(action: addReading) { Label(S("Messung hinzufügen", "Add reading"), systemImage: "plus.circle") }.buttonStyle(SuiteRowButtonStyle()).accessibilityIdentifier("cold-add-reading")
        } header: { Text(S("Messreihe", "Measurement series")) }
        if project.cold.isValid && !project.cold.readings.isEmpty {
            Section {
                Chart(project.cold.chronological) { reading in
                    LineMark(x: .value(S("Zeit", "Time"), reading.date), y: .value("K", reading.superheatK)).foregroundStyle(by: .value(S("Wert", "Value"), S("Überhitzung", "Superheat")))
                    PointMark(x: .value(S("Zeit", "Time"), reading.date), y: .value("K", reading.superheatK)).foregroundStyle(by: .value(S("Wert", "Value"), S("Überhitzung", "Superheat")))
                    LineMark(x: .value(S("Zeit", "Time"), reading.date), y: .value("K", reading.subcoolingK)).foregroundStyle(by: .value(S("Wert", "Value"), S("Unterkühlung", "Subcooling")))
                    PointMark(x: .value(S("Zeit", "Time"), reading.date), y: .value("K", reading.subcoolingK)).foregroundStyle(by: .value(S("Wert", "Value"), S("Unterkühlung", "Subcooling")))
                }.frame(height: 210).chartForegroundStyleScale([S("Überhitzung", "Superheat"): Color.indigo, S("Unterkühlung", "Subcooling"): Color.blue])
                if let change = project.cold.superheatChangeK { LabeledContent(S("Änderung Überhitzung, erste bis letzte Messung", "Superheat change, first to last reading"), value: "\(SN(change)) K") }
            } header: { Text(S("Vorher und nachher", "Before and after")) }
        }
        Section { TextField(S("Notizen zur Kälteanlage", "Refrigeration notes"), text: $project.cold.notes, axis: .vertical) }
        SuiteColdUtilities()
        }
    }
}

struct SuiteColdReadingSheet: View {
    let add: (ColdReading) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var suction: Double?
    @State private var evaporation: Double?
    @State private var condensation: Double?
    @State private var liquid: Double?
    @State private var note = ""
    private var completed: ColdReading? {
        guard let suction, let evaporation, let condensation, let liquid else { return nil }
        var value = ColdReading()
        value.date = date; value.suctionC = suction; value.evaporationC = evaporation
        value.condensationC = condensation; value.liquidC = liquid; value.note = note
        return value.isValid ? value : nil
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(S("Messzeitpunkt", "Measurement time"), selection: $date)
                    SuiteNumberField(S("Sauggastemperatur", "Suction-gas temperature"), optional: $suction, unit: "°C").accessibilityIdentifier("cold-measured-suction")
                    SuiteNumberField(S("Verdampfungstemperatur", "Evaporating temperature"), optional: $evaporation, unit: "°C").accessibilityIdentifier("cold-measured-evaporation")
                    SuiteNumberField(S("Verflüssigungstemperatur", "Condensing temperature"), optional: $condensation, unit: "°C").accessibilityIdentifier("cold-measured-condensation")
                    SuiteNumberField(S("Flüssigkeitsleitung", "Liquid-line temperature"), optional: $liquid, unit: "°C").accessibilityIdentifier("cold-measured-liquid")
                } footer: { Text(S("Alle vier tatsächlichen Temperaturen eingeben (−150 bis 200 °C). Sättigungstemperaturen aus verifizierten Stoffdaten übernehmen.", "Enter all four actual temperatures (−150 to 200 °C). Use verified data for saturation temperatures.")) }
                if let value = completed {
                    Section {
                        SuiteMetric(title: S("Überhitzung", "Superheat"), value: "\(SN(value.superheatK)) K", tint: .indigo)
                        SuiteMetric(title: S("Unterkühlung", "Subcooling"), value: "\(SN(value.subcoolingK)) K", tint: .blue)
                    }
                }
                TextField(S("Messgerät / Beobachtung", "Instrument / observation"), text: $note, axis: .vertical)
            }.suiteFormSurface().navigationTitle(S("Neue Messung", "New reading")).navigationBarTitleDisplayMode(.inline).suiteKeyboard()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(S("Abbrechen", "Cancel")) { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button(S("Übernehmen", "Use reading")) { if let value = completed { add(value); dismiss() } }.disabled(completed == nil).accessibilityIdentifier("cold-save-reading") }
                }
        }
    }
}
