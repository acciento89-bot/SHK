import SwiftUI

/// Native, vertically arranged controls keep labels and values readable at all Dynamic Type sizes.
struct LueftungsCalcView: View {
    @State private var mode = 0
    @State private var flow = 250.0
    @State private var velocity = 3.0
    @State private var diameter = 180.0
    @State private var width = 300.0
    @State private var height = 200.0
    @State private var roomLength = 5.0
    @State private var roomWidth = 4.0
    @State private var roomHeight = 2.5
    @State private var changes = 1.5
    @State private var installed = 75.0
    @State private var conversion = 500.0
    private var ductValid: Bool { [flow, velocity, diameter, width, height].allSatisfy { $0.isFinite && $0 > 0 && $0 <= 1_000_000 } }
    private var roomValid: Bool { [roomLength, roomWidth, roomHeight, changes].allSatisfy { $0.isFinite && $0 > 0 && $0 <= 10000 } && installed.isFinite && installed >= 0 }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(tr("Werkzeug", "Tool"), selection: $mode) {
                        Text(tr("Kanalquerschnitt", "Duct sizing")).tag(0)
                        Text(tr("Raumluftwechsel", "Room air changes")).tag(1)
                        Text(tr("Einheiten", "Units")).tag(2)
                    }.pickerStyle(.menu)
                }
                if mode == 0 { duct }
                else if mode == 1 { room }
                else {
                    Section(tr("Volumenstrom", "Flow rate")) { WorkNumber(title: tr("Ausgangswert", "Input"), value: $conversion, unit: "m³/h") }
                    if conversion.isFinite && conversion >= 0 {
                        Section(tr("Umrechnung", "Conversion")) {
                            WorkMetric(label: tr("Liter pro Sekunde", "Litres per second"), value: "\(fieldNumber(VentilationCalculator.m3HToLitersPerSecond(conversion), digits: 2)) l/s")
                            WorkMetric(label: "Cubic feet per minute", value: "\(fieldNumber(VentilationCalculator.m3HToCFM(conversion), digits: 2)) cfm")
                        }
                    } else { WorkValidation(message: tr("Gültigen Wert ≥ 0 eingeben.", "Enter a valid value ≥ 0.")) }
                }
                Section(tr("Einordnung", "Scope")) {
                    Text(tr("Rechenhilfe für Querschnitt und Luftwechsel. Schall, Druckverlust, Brandschutz und projektspezifische Vorgaben separat prüfen. Zielwerte werden von dir vorgegeben.", "Calculation aid for cross-section and air changes. Assess noise, pressure loss, fire protection and project requirements separately. Targets are supplied by you."))
                }
            }.navigationTitle(tr("Luftauslegung", "Air sizing"))
        }
    }
    private var duct: some View {
        Group {
            Section(tr("Auslegungsziel", "Design target")) {
                WorkNumber(title: tr("Volumenstrom", "Flow rate"), value: $flow, unit: "m³/h")
                WorkNumber(title: tr("Zielgeschwindigkeit", "Target velocity"), value: $velocity, unit: "m/s")
            }
            Section(tr("Gewählte Querschnitte", "Selected cross-sections")) {
                WorkNumber(title: tr("Rundkanal · Innendurchmesser", "Round duct · internal diameter"), value: $diameter, unit: "mm")
                WorkNumber(title: tr("Rechteck · Breite", "Rectangle · width"), value: $width, unit: "mm")
                WorkNumber(title: tr("Rechteck · Höhe", "Rectangle · height"), value: $height, unit: "mm")
            }
            if ductValid {
                let required = VentilationCalculator.roundDiameterMM(volumeFlowM3H: flow, targetVelocityMS: velocity)
                Section(tr("Querschnittsvergleich", "Cross-section comparison")) {
                    WorkMetric(label: tr("Erforderlicher Runddurchmesser", "Required round diameter"), value: "\(fieldNumber(required)) mm")
                    if let common = VentilationCalculator.commonRoundDiametersMM.first(where: { $0 >= required }) {
                        WorkMetric(label: tr("Nächste hinterlegte Rundgröße", "Next listed round size"), value: "\(fieldNumber(common)) mm")
                    } else { Text(tr("Oberhalb der hinterlegten Größen bis 630 mm. Herstellerprogramm prüfen.", "Exceeds the listed range up to 630 mm. Check manufacturer sizes.")) }
                    WorkMetric(label: tr("Geschwindigkeit · gewählter Rundkanal", "Velocity · selected round duct"), value: "\(fieldNumber(VentilationCalculator.roundVelocityMS(volumeFlowM3H: flow, diameterMM: diameter), digits: 2)) m/s")
                    WorkMetric(label: tr("Geschwindigkeit · Rechteck", "Velocity · rectangle"), value: "\(fieldNumber(VentilationCalculator.velocityMS(volumeFlowM3H: flow, widthMM: width, heightMM: height), digits: 2)) m/s")
                    WorkMetric(label: tr("Erforderliche Höhe bei gewählter Breite", "Required height at selected width"), value: "\(fieldNumber(VentilationCalculator.rectangularRequiredHeightMM(volumeFlowM3H: flow, widthMM: width, targetVelocityMS: velocity))) mm")
                    WorkMetric(label: tr("Hydraulisch äquivalenter Runddurchmesser", "Hydraulically equivalent round diameter"), value: "\(fieldNumber(VentilationCalculator.equivalentRoundDiameterMM(widthMM: width, heightMM: height))) mm")
                    Text(tr("Äquivalentdurchmesser ist eine Näherung für Reibungsvergleiche, kein flächengleicher Durchmesser.", "Equivalent diameter approximates friction equivalence; it is not an equal-area diameter.")).foregroundStyle(.secondary)
                    ShareLink(item: "LüftungsCalc\nQ \(fieldNumber(flow)) m³/h; v \(fieldNumber(velocity)) m/s\nØ \(fieldNumber(required)) mm\n\(fieldNumber(width)) × \(fieldNumber(height)) mm") { Label(tr("Auslegung teilen", "Share sizing"), systemImage: "square.and.arrow.up") }
                }
            } else { WorkValidation(message: tr("Alle Werte müssen gültig und größer als null sein.", "All values must be valid and greater than zero.")) }
        }
    }
    private var room: some View {
        Group {
            Section(tr("Raum und Vorgabe", "Room and target")) {
                WorkNumber(title: tr("Länge", "Length"), value: $roomLength, unit: "m")
                WorkNumber(title: tr("Breite", "Width"), value: $roomWidth, unit: "m")
                WorkNumber(title: tr("Höhe", "Height"), value: $roomHeight, unit: "m")
                WorkNumber(title: tr("Vorgegebener Luftwechsel", "Specified air change rate"), value: $changes, unit: "1/h")
                WorkNumber(title: tr("Eingestellter Volumenstrom", "Installed flow rate"), value: $installed, unit: "m³/h")
            }
            if roomValid {
                let volume = VentilationCalculator.roomVolumeM3(lengthM: roomLength, widthM: roomWidth, heightM: roomHeight)
                Section(tr("Ergebnis", "Result")) {
                    WorkMetric(label: tr("Raumvolumen", "Room volume"), value: "\(fieldNumber(volume)) m³")
                    WorkMetric(label: tr("Benötigter Volumenstrom", "Required flow rate"), value: "\(fieldNumber(volume * changes)) m³/h")
                    WorkMetric(label: tr("Erreichter Luftwechsel", "Achieved air change rate"), value: "\(fieldNumber(installed / volume, digits: 2)) 1/h")
                    ShareLink(item: "LüftungsCalc\nV \(fieldNumber(volume)) m³; n \(fieldNumber(changes)) 1/h\nQ \(fieldNumber(volume * changes)) m³/h\nIst \(fieldNumber(installed)) m³/h") { Label(tr("Raumberechnung teilen", "Share room calculation"), systemImage: "square.and.arrow.up") }
                }
            } else { WorkValidation(message: tr("Raummaße und Luftwechsel > 0; Volumenstrom ≥ 0 eingeben.", "Enter room dimensions and air changes > 0; flow rate ≥ 0.")) }
        }
    }
}
