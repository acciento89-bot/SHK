import SwiftUI

private func positive(_ values: Double...) -> Bool { values.allSatisfy { $0.isFinite && $0 > 0 && $0 <= 1_000_000 } }

struct SuitePipeSizing: View {
    let flow: Double
    @State private var speed = 0.5
    var body: some View {
        Section {
            DisclosureGroup(S("Innendurchmesser aus Zielgeschwindigkeit", "Internal diameter from target velocity")) {
                SuiteNumberField(S("Gewünschte Geschwindigkeit", "Target velocity"), value: $speed, unit: "m/s")
                if positive(flow, speed) {
                    SuiteMetric(title: S("Rechnerischer Innendurchmesser", "Calculated internal diameter"), value: "\(SN(PipeCalculator.requiredInnerDiameterMM(volumeFlowLPH: flow, targetVelocityMS: speed))) mm", tint: SuiteTheme.copper)
                    Text(S("Mit dem tatsächlichen Innendurchmesser der gewählten Rohrserie und dem Druckverlust abgleichen. Keine automatische DN-Zuordnung.", "Check against the selected pipe series' actual internal diameter and pressure loss. No automatic nominal-size assignment.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
                }
            }
        } header: { Text(S("Dimensionierung", "Sizing")) }
    }
}

struct SuiteColdUtilities: View {
    @State private var suction: Double?
    @State private var discharge: Double?
    @State private var atmosphere = RefrigerationCalculator.standardAtmosphericPressureBar
    @State private var flow: Double?
    @State private var entering: Double?
    @State private var leaving: Double?
    var body: some View {
        Section {
            DisclosureGroup(S("Verdichter-Druckverhältnis", "Compressor pressure ratio")) {
                SuiteNumberField(S("Saugdruck, Manometer", "Suction gauge pressure"), optional: $suction, unit: "bar(g)")
                SuiteNumberField(S("Hochdruck, Manometer", "Discharge gauge pressure"), optional: $discharge, unit: "bar(g)")
                SuiteNumberField(S("Atmosphärendruck absolut", "Absolute atmospheric pressure"), value: $atmosphere, unit: "bar(a)")
                if let suction, let discharge, positive(atmosphere), suction.isFinite, discharge.isFinite, suction + atmosphere > 0, discharge + atmosphere > 0 {
                    SuiteMetric(title: S("Absolutes Druckverhältnis", "Absolute pressure ratio"), value: SN(RefrigerationCalculator.compressorPressureRatio(suctionGaugeBar: suction, dischargeGaugeBar: discharge, atmosphericBar: atmosphere)), tint: .indigo)
                    Text(S("Beide Manometerdrücke werden mit dem Atmosphärendruck in Absolutdrücke umgerechnet.", "Both gauge pressures are converted to absolute pressures using atmospheric pressure.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
                }
            }
            DisclosureGroup(S("Luftseitige sensible Leistung", "Air-side sensible capacity")) {
                SuiteNumberField(S("Luftvolumenstrom", "Air flow"), optional: $flow, unit: "m³/h")
                SuiteNumberField(S("Lufteintritt", "Entering air"), optional: $entering, unit: "°C")
                SuiteNumberField(S("Luftaustritt", "Leaving air"), optional: $leaving, unit: "°C")
                if let flow, let entering, let leaving, positive(flow), [entering,leaving].allSatisfy({ $0.isFinite && (-150...200).contains($0) }) {
                    SuiteMetric(title: S("Sensible Leistung, Betrag", "Sensible capacity, magnitude"), value: "\(SN(RefrigerationCalculator.airSideCapacityKW(volumeFlowM3H: flow, enteringAirC: entering, leavingAirC: leaving))) kW", tint: .indigo)
                    Text(S("Näherung mit ρ·cp/3600 ≈ 0,335 Wh/(m³·K). Latente Leistung und Feuchte nicht enthalten.", "Approximation using ρ·cp/3600 ≈ 0.335 Wh/(m³·K). Excludes latent capacity and moisture.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
                }
            }
        } header: { Text(S("Weitere Kältewerkzeuge", "More refrigeration tools")) }
    }
}

struct SuiteDuctUtilities: View {
    @State private var flow = 200.0
    @State private var diameter = 160.0
    @State private var width = 200.0
    @State private var height = 100.0
    @State private var speed = 3.0
    @State private var roomVolume = 50.0
    var body: some View {
        Section {
            DisclosureGroup(S("Kanal prüfen und dimensionieren", "Check and size a duct")) {
                SuiteNumberField(S("Volumenstrom", "Flow rate"), value: $flow, unit: "m³/h")
                SuiteNumberField(S("Zielgeschwindigkeit", "Target velocity"), value: $speed, unit: "m/s")
                SuiteNumberField(S("Rundkanal, Innendurchmesser", "Round duct, internal diameter"), value: $diameter, unit: "mm")
                SuiteNumberField(S("Rechteckkanal, Breite", "Rectangular duct, width"), value: $width, unit: "mm")
                SuiteNumberField(S("Rechteckkanal, Höhe", "Rectangular duct, height"), value: $height, unit: "mm")
                if positive(flow, speed, diameter, width, height) {
                    LabeledContent(S("Rundkanal, Geschwindigkeit", "Round duct velocity"), value: "\(SN(VentilationCalculator.roundVelocityMS(volumeFlowM3H: flow, diameterMM: diameter))) m/s")
                    LabeledContent(S("Rechteckkanal, Geschwindigkeit", "Rectangular duct velocity"), value: "\(SN(VentilationCalculator.velocityMS(volumeFlowM3H: flow, widthMM: width, heightMM: height))) m/s")
                    LabeledContent(S("Erforderliche Rechteckhöhe bei Zielgeschwindigkeit", "Required height at target velocity"), value: "\(SN(VentilationCalculator.rectangularRequiredHeightMM(volumeFlowM3H: flow, widthMM: width, targetVelocityMS: speed))) mm")
                    LabeledContent(S("Hydraulisch äquivalenter Runddurchmesser", "Hydraulically equivalent round diameter"), value: "\(SN(VentilationCalculator.equivalentRoundDiameterMM(widthMM: width, heightMM: height))) mm")
                    Text(S("Rechnerische Querschnitte; keine Druckverlust-, Schall- oder Normfreigabe.", "Calculated cross-sections; no pressure-loss, acoustic or standards approval.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
                }
            }
            DisclosureGroup(S("Erreichten Luftwechsel bestimmen", "Calculate achieved air changes")) {
                SuiteNumberField(S("Volumenstrom", "Flow rate"), value: $flow, unit: "m³/h")
                SuiteNumberField(S("Raumvolumen", "Room volume"), value: $roomVolume, unit: "m³")
                if positive(flow, roomVolume) { SuiteMetric(title: S("Luftwechsel", "Air changes"), value: "\(SN(VentilationCalculator.airChangesPerHour(volumeFlowM3H: flow, roomVolumeM3: roomVolume))) 1/h") }
            }
        } header: { Text(S("Kanal und Luftwechsel", "Ducts and air changes")) }
    }
}

struct SuiteUnitConversions: View {
    @State private var temperature = 20.0
    @State private var bar = 1.0
    @State private var vacuum = 1.0
    @State private var air = 100.0
    var body: some View {
        Form {
            Section(S("Temperatur", "Temperature")) {
                SuiteNumberField("Celsius", value: $temperature, unit: "°C")
                if temperature.isFinite && temperature >= -273.15 {
                    SuiteMetric(title: "Fahrenheit", value: "\(SN(RefrigerationCalculator.celsiusToFahrenheit(temperature))) °F")
                }
            }
            Section(S("Druck", "Pressure")) {
                SuiteNumberField("Bar", value: $bar, unit: "bar")
                if bar.isFinite {
                    LabeledContent("PSI", value: SN(RefrigerationCalculator.barToPSI(bar)))
                    LabeledContent("kPa", value: SN(RefrigerationCalculator.barToKPa(bar)))
                }
            }
            Section(S("Vakuum, Absolutdruck", "Vacuum, absolute pressure")) {
                SuiteNumberField(S("Millibar absolut", "Absolute millibar"), value: $vacuum, unit: "mbar(a)")
                if vacuum.isFinite && vacuum >= 0 {
                    LabeledContent("Micron", value: SN(RefrigerationCalculator.mbarToMicron(vacuum), digits: 3))
                    LabeledContent("Pa", value: SN(RefrigerationCalculator.mbarToPascal(vacuum), digits: 3))
                }
            }
            Section(S("Luftvolumenstrom", "Air flow")) {
                SuiteNumberField(S("Volumenstrom", "Flow rate"), value: $air, unit: "m³/h")
                if air.isFinite && air >= 0 {
                    LabeledContent("l/s", value: SN(VentilationCalculator.m3HToLitersPerSecond(air)))
                    LabeledContent("CFM", value: SN(VentilationCalculator.m3HToCFM(air)))
                }
            }
        }.navigationTitle(S("Einheiten umrechnen", "Unit conversions")).navigationBarTitleDisplayMode(.inline).suiteKeyboard()
    }
}
