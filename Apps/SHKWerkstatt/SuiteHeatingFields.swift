import SwiftUI
import Charts

struct SuiteHeatingFields: View {
    @Binding var project: SuiteProject
    let quick: Bool
    @State private var transfer = false
    @State private var transferError = false
    var body: some View {
        Group {
        Section {
            SuiteNumberField(S("Auslegung Vorlauf", "Design supply"), value: $project.heat.flowC, unit: "°C")
            SuiteNumberField(S("Auslegung Rücklauf", "Design return"), value: $project.heat.returnC, unit: "°C")
        } header: { Text(S("Systemtemperaturen", "System temperatures")) }
          footer: { Text(S("Auslegungswerte für die Heizkörper. Tatsächliche Service-Messwerte werden separat erfasst.", "Radiator design values. Actual service measurements are recorded separately.")) }
        Section {
            ForEach($project.heat.rooms) { $room in
                DisclosureGroup(room.name.isEmpty ? S("Neuer Raum", "New room") : room.name) {
                    TextField(S("Raumname", "Room name"), text: $room.name)
                    SuiteNumberField(S("Wärmebedarf des Raums", "Room heat demand"), value: $room.demandW, unit: "W")
                    SuiteNumberField(S("Hersteller-Nennleistung bei ΔT50", "Manufacturer output at ΔT50"), value: $room.nominalW, unit: "W")
                    SuiteNumberField(S("Hersteller-Exponent n", "Manufacturer exponent n"), value: $room.exponent, unit: "n")
                    SuiteNumberField(S("Raumtemperatur", "Room temperature"), value: $room.roomC, unit: "°C")
                    if project.heat.isValid && room.isValid && project.heat.returnC > room.roomC {
                        LabeledContent(S("Erforderliche Nennleistung bei ΔT50", "Required rated output at ΔT50"), value: "\(SN(RadiatorCalculator.requiredNominalPowerDeltaT50W(requiredActualPowerW: room.demandW, flowC: project.heat.flowC, returnC: project.heat.returnC, roomC: room.roomC, exponent: room.exponent), digits: 0)) W")
                        if let count = project.checkedRadiatorCount(for: room) {
                            LabeledContent(S("Anzahl dieser Heizkörper", "Number of these radiators"), value: "\(count)")
                        } else {
                            Text(S("Die berechnete Anzahl liegt außerhalb des darstellbaren Bereichs. Bitte Herstellerleistung und Systemtemperaturen prüfen.", "The calculated count is out of range. Check manufacturer output and system temperatures.")).font(.footnote).foregroundStyle(.red)
                        }
                    }
                    if !room.isValid || project.heat.returnC <= room.roomC { Text(S("Name und positive Leistungswerte erforderlich. Der Rücklauf muss über der Raumtemperatur liegen.", "Enter a name and positive output values. Return temperature must exceed room temperature.")).font(.footnote).foregroundStyle(.red) }
                }
            }.onDelete { project.heat.rooms.remove(atOffsets: $0) }
            Button {
                var room = HeatRoom(); room.name = S("Raum", "Room") + " \(project.heat.rooms.count+1)"; project.heat.rooms.append(room)
            } label: { Label(S("Raum hinzufügen", "Add room"), systemImage: "plus.circle") }.buttonStyle(SuiteRowButtonStyle()).accessibilityIdentifier("heat-add-room")
        } header: { Text(S("Räume und Heizkörper", "Rooms and radiators")) }
        if project.heat.isValid && !project.heat.rooms.isEmpty {
            Section {
                SuiteMetric(title: S("Wärmebedarf gesamt", "Total heat demand"), value: "\(SN(project.heatingDemandW, digits: 0)) W", tint: SuiteTheme.copper)
                SuiteMetric(title: S("Ungedeckter Bedarf", "Unmet demand"), value: "\(SN(project.heat.deficitW, digits: 0)) W", tint: project.heat.deficitW > 0 ? SuiteTheme.copper : SuiteTheme.teal)
                if let flow = project.heatingFlowLPH { SuiteMetric(title: S("Volumenstrom aus Bedarf und Spreizung", "Flow from demand and temperature difference"), value: "\(SN(flow)) l/h") }
                Chart(project.heat.rooms) { room in
                    BarMark(x: .value(S("Raum", "Room"), room.name), y: .value("W", room.demandW)).foregroundStyle(by: .value(S("Wert", "Value"), S("Bedarf", "Demand"))).position(by: .value(S("Wert", "Value"), S("Bedarf", "Demand")))
                    BarMark(x: .value(S("Raum", "Room"), room.name), y: .value("W", room.power(flow: project.heat.flowC, returning: project.heat.returnC))).foregroundStyle(by: .value(S("Wert", "Value"), S("Leistung", "Output"))).position(by: .value(S("Wert", "Value"), S("Leistung", "Output")))
                }.frame(height: 220).chartForegroundStyleScale([S("Bedarf", "Demand"): Color.orange, S("Leistung", "Output"): SuiteTheme.teal])
                if !quick {
                    Button { transfer = true } label: { Label(S("Volumenstrom ins Rohrnetz übernehmen", "Use flow in pipe route"), systemImage: "arrow.right.circle") }
                        .disabled(project.heatingFlowLPH == nil).buttonStyle(SuiteRowButtonStyle()).accessibilityIdentifier("heat-transfer-flow")
                }
            } header: { Text(S("Auswertung", "Results")) }
        }
        Section {
            TextField(S("Notizen zur Auslegung", "Design notes"), text: $project.heat.notes, axis: .vertical)
            Text(S("Herstellerwerte für n und ΔT50 verwenden. Kein automatischer Heizlastnachweis; ein Überschuss in einem Raum gleicht ein Defizit in einem anderen nicht aus.", "Use manufacturer n and ΔT50 values. Not an automatic heat-load certificate; a surplus in one room cannot offset another room's deficit.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
        }
        }
        .confirmationDialog(S("Volumenstrom im Rohrnetz ersetzen?", "Replace the pipe-route flow?"), isPresented: $transfer, titleVisibility: .visible) {
            Button(S("Übernehmen", "Use flow")) { do { try project.transferHeatingFlow() } catch { transferError = true } }
        } message: { Text(S("Der berechnete Bedarf wird mit den eingegebenen Systemtemperaturen in einen gemeinsamen Volumenstrom umgerechnet.", "The calculated demand and entered system temperatures determine one shared flow rate.")) }
        .alert(S("Übernahme nicht möglich. Bitte die Auslegungswerte prüfen.", "Transfer unavailable. Check the design inputs."), isPresented: $transferError) { Button("OK") {} }
    }
}
