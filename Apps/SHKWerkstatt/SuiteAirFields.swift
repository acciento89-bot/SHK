import SwiftUI
import Charts

struct SuiteAirFields: View {
    @Binding var project: SuiteProject
    var body: some View {
        Section {
            SuiteNumberField(S("Zulässige Projektabweichung", "Project tolerance"), value: $project.air.tolerancePercent, unit: "%")
        } footer: { Text(S("Die Toleranz legst du für dieses Projekt fest. Ein fehlender Istwert ist keine Nullmessung.", "You set the tolerance for this project. A missing reading is not a measured zero.")) }
        Section {
            ForEach($project.air.terminals) { $terminal in
                DisclosureGroup(terminal.name.isEmpty ? S("Neuer Auslass", "New terminal") : terminal.name) {
                    TextField(S("Raum / Auslass", "Room / terminal"), text: $terminal.name)
                    Picker(S("Luftart", "Air stream"), selection: $terminal.stream) {
                        Text(S("Zuluft", "Supply")).tag(AirStream.supply)
                        Text(S("Abluft", "Extract")).tag(AirStream.extract)
                    }
                    SuiteNumberField(S("Soll-Volumenstrom", "Target flow"), value: $terminal.targetM3H, unit: "m³/h")
                    SuiteNumberField(S("Gemessener Volumenstrom", "Measured flow"), optional: $terminal.measuredM3H, unit: "m³/h")
                    TextField(S("Messgerät / Notiz", "Instrument / note"), text: $terminal.note, axis: .vertical)
                    if terminal.isValid {
                        if let deviation = terminal.deviationPercent {
                            LabeledContent(S("Abweichung", "Deviation"), value: "\(SN(deviation)) %")
                            Label(terminal.meetsTolerance(project.air.tolerancePercent) == true ? S("Innerhalb Projekttoleranz", "Within project tolerance") : S("Einregulierung prüfen", "Check balancing"), systemImage: terminal.meetsTolerance(project.air.tolerancePercent) == true ? "checkmark.circle" : "exclamationmark.triangle")
                        } else { Label(S("Messung noch offen", "Measurement pending"), systemImage: "circle.dotted").foregroundStyle(SuiteTheme.secondary) }
                    } else { Text(S("Positiven Sollwert und einen gültigen Istwert ≥0 eingeben.", "Enter a positive target and a valid measured value ≥0.")).font(.footnote).foregroundStyle(.red) }
                }
            }.onDelete { project.air.terminals.remove(atOffsets: $0) }
            Button { var terminal = AirTerminal(); terminal.name = S("Auslass", "Terminal") + " \(project.air.terminals.count+1)"; project.air.terminals.append(terminal) } label: { Label(S("Auslass hinzufügen", "Add terminal"), systemImage: "plus.circle") }.buttonStyle(SuiteRowButtonStyle()).accessibilityIdentifier("air-add-terminal")
        } header: { Text(S("Auslässe und Räume", "Terminals and rooms")) }
        if project.air.isValid && !project.air.terminals.isEmpty {
            Section {
                LabeledContent(S("Fehlende Messungen", "Missing measurements"), value: "\(project.air.missingCount)")
                LabeledContent(S("Außerhalb Projekttoleranz", "Outside project tolerance"), value: "\(project.air.outsideCount)")
                ForEach([AirStream.supply, .extract], id: \.self) { stream in
                    let title = stream == .supply ? S("Zuluft", "Supply") : S("Abluft", "Extract")
                    LabeledContent(title + S(" Soll", " target"), value: "\(SN(project.air.target(stream))) m³/h")
                    LabeledContent(title + S(" Ist", " measured"), value: project.air.measured(stream).map { "\(SN($0)) m³/h" } ?? S("Unvollständig", "Incomplete"))
                }
                Chart(project.air.terminals) { terminal in
                    BarMark(x: .value(S("Auslass", "Terminal"), terminal.name), y: .value("m³/h", terminal.targetM3H)).foregroundStyle(by: .value(S("Wert", "Value"), S("Soll", "Target"))).position(by: .value(S("Wert", "Value"), S("Soll", "Target")))
                    if let measured = terminal.measuredM3H {
                        BarMark(x: .value(S("Auslass", "Terminal"), terminal.name), y: .value("m³/h", measured)).foregroundStyle(by: .value(S("Wert", "Value"), S("Ist", "Measured"))).position(by: .value(S("Wert", "Value"), S("Ist", "Measured")))
                    }
                }.frame(height: 220).chartForegroundStyleScale([S("Soll", "Target"): SuiteTheme.teal, S("Ist", "Measured"): SuiteTheme.copper])
            } header: { Text(S("Einregulierung im Überblick", "Commissioning overview")) }
        }
        SuiteAirSizing(project: $project)
        SuiteDuctUtilities()
        Section { TextField(S("Notizen zur Lüftung", "Ventilation notes"), text: $project.air.notes, axis: .vertical) }
    }
}

private struct SuiteAirSizing: View {
    @Binding var project: SuiteProject
    @State private var length = 5.0
    @State private var width = 4.0
    @State private var height = 2.5
    @State private var changes = 1.0
    @State private var targetSpeed = 3.0
    private var valid: Bool { [length,width,height,changes,targetSpeed].allSatisfy { $0.isFinite && $0 > 0 && $0 <= 10000 } }
    private var flow: Double { VentilationCalculator.requiredFlowM3H(roomLengthM: length, roomWidthM: width, roomHeightM: height, airChangesPerHour: changes) }
    var body: some View {
        Section {
            DisclosureGroup(S("Raumbedarf und Rundkanal bestimmen", "Determine room demand and round duct size")) {
                SuiteNumberField(S("Raumlänge", "Room length"), value: $length, unit: "m")
                SuiteNumberField(S("Raumbreite", "Room width"), value: $width, unit: "m")
                SuiteNumberField(S("Raumhöhe", "Room height"), value: $height, unit: "m")
                SuiteNumberField(S("Gewünschter Luftwechsel", "Required air changes"), value: $changes, unit: "1/h")
                SuiteNumberField(S("Zielgeschwindigkeit im Kanal", "Target duct velocity"), value: $targetSpeed, unit: "m/s")
                if valid && flow.isFinite && flow <= 1_000_000 {
                    SuiteMetric(title: S("Erforderlicher Volumenstrom", "Required air flow"), value: "\(SN(flow)) m³/h")
                    LabeledContent(S("Rundkanal rechnerisch", "Calculated round duct"), value: "\(SN(VentilationCalculator.roundDiameterMM(volumeFlowM3H: flow, targetVelocityMS: targetSpeed))) mm")
                    Button {
                        var terminal = AirTerminal(); terminal.name = S("Raum", "Room") + " \(project.air.terminals.count+1)"; terminal.targetM3H = flow
                        terminal.note = S("Raumbedarf aus", "Room demand from") + " \(SN(length)) × \(SN(width)) × \(SN(height)) m; \(SN(changes)) 1/h"
                        project.air.terminals.append(terminal)
                    } label: { Label(S("Als Sollwert eines Auslasses verwenden", "Use as a terminal target"), systemImage: "arrow.up.right.circle") }.buttonStyle(SuiteRowButtonStyle())
                }
            }
        } header: { Text(S("Auslegungshilfe", "Sizing tool")) }
    }
}
