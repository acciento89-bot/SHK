import Foundation
import SwiftUI

enum KalteCalcMode: String, CaseIterable, Identifiable {
    case circuit = "Kältekreis"
    case air = "Luftseite"
    case converter = "Tools"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .circuit: "gauge.with.dots.needle.50percent"
        case .air: "wind"
        case .converter: "arrow.left.arrow.right"
        }
    }
}

struct KalteCalcView: View {
    @State private var mode: KalteCalcMode = .circuit
    @State private var refrigerant = "R32"

    @State private var evaporation = 4.0
    @State private var suction = 11.0
    @State private var condensation = 42.0
    @State private var liquid = 36.0
    @State private var suctionPressure = 7.5
    @State private var dischargePressure = 24.0

    @State private var airFlow = 800.0
    @State private var enteringAir = 27.0
    @State private var leavingAir = 19.0

    @State private var celsius = 20.0
    @State private var bar = 10.0
    @State private var vacuumMbar = 1.0

    private let refrigerants = [
        "R32", "R290", "R410A", "R134a", "R407C", "R454B", "R1234yf", "R744 (CO₂)", "Andere"
    ]

    private var superheat: Double {
        RefrigerationCalculator.superheat(suctionGasC: suction, evaporationC: evaporation)
    }

    private var subcooling: Double {
        RefrigerationCalculator.subcooling(condensationC: condensation, liquidLineC: liquid)
    }

    private var pressureRatio: Double {
        RefrigerationCalculator.compressorPressureRatio(
            suctionGaugeBar: suctionPressure,
            dischargeGaugeBar: dischargePressure
        )
    }

    private var airDelta: Double { enteringAir - leavingAir }

    private var airCapacity: Double {
        RefrigerationCalculator.airSideCapacityKW(
            volumeFlowM3H: airFlow,
            enteringAirC: enteringAir,
            leavingAirC: leavingAir
        )
    }

    private var serviceSummary: String {
        """
        KälteCalc – Service-Messwerte
        Kältemittel: \(refrigerant)

        Kältekreis
        Verdampfung/Sättigung: \(format(evaporation)) °C
        Sauggas: \(format(suction)) °C
        Überhitzung: \(format(superheat)) K
        Saugdruck: \(format(suctionPressure)) bar(g)

        Kondensation/Sättigung: \(format(condensation)) °C
        Flüssigkeitsleitung: \(format(liquid)) °C
        Unterkühlung: \(format(subcooling)) K
        Hochdruck: \(format(dischargePressure)) bar(g)
        Druckverhältnis: \(format(pressureRatio)) : 1

        Luftseite
        Luftmenge: \(format(airFlow, digits: 0)) m³/h
        Eintritt: \(format(enteringAir)) °C
        Austritt: \(format(leavingAir)) °C
        ΔT: \(format(airDelta)) K
        sensible Näherung: \(format(airCapacity, digits: 2)) kW

        Hinweis: Sättigungstemperaturen müssen aus einer geeigneten P/T-Quelle bzw. dem Messgerät übernommen werden. Herstellerangaben und Kältemitteldaten haben Vorrang.
        """
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KalteConsoleBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        consoleHeader
                        modeSelector

                        switch mode {
                        case .circuit:
                            circuitContent
                        case .air:
                            airContent
                        case .converter:
                            converterContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("KälteCalc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: serviceSummary) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.cyan)
                    }
                    .accessibilityLabel("Messwerte teilen")
                }
            }
        }
        .preferredColorScheme(.dark)
        .shkKeyboardDismissal()
    }

    private var consoleHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SERVICE CONSOLE")
                        .font(.caption.weight(.black))
                        .tracking(2.2)
                        .foregroundStyle(.cyan)
                    Text("Kältekreis im Blick")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("Messwerte getrennt nach Nieder- und Hochdruckseite.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(.cyan.opacity(0.25), lineWidth: 8)
                        .frame(width: 68, height: 68)
                    Image(systemName: "snowflake")
                        .font(.system(size: 29, weight: .semibold))
                        .foregroundStyle(.cyan)
                }
            }

            HStack(spacing: 10) {
                statusPill("REF", value: refrigerant, color: .cyan)
                statusPill("SH", value: "\(format(superheat)) K", color: .blue)
                statusPill("SC", value: "\(format(subcooling)) K", color: .orange)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.035, green: 0.08, blue: 0.12))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.cyan.opacity(0.18), lineWidth: 1)
        }
    }

    private var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(KalteCalcMode.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        mode = item
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.headline)
                        Text(item.rawValue)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundStyle(mode == item ? Color.black : Color.white.opacity(0.72))
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(mode == item ? Color.cyan : Color.white.opacity(0.055))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var circuitContent: some View {
        KalteConsoleCard(title: "Kältemittel", systemImage: "drop.degreesign", accent: .cyan) {
            Picker("Kältemittel", selection: $refrigerant) {
                ForEach(refrigerants, id: \.self) { item in
                    Text(item).tag(item)
                }
            }
            .pickerStyle(.menu)
            .tint(.cyan)

            Text("Sättigungstemperaturen werden nicht geraten. Werte aus Messgerät, Hersteller- oder verifizierter P/T-Quelle übernehmen.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

        HStack(alignment: .top, spacing: 12) {
            KalteSidePanel(
                title: "NIEDERDRUCK",
                icon: "arrow.down.right",
                value: "\(format(suctionPressure)) bar(g)",
                accent: .cyan
            )
            KalteSidePanel(
                title: "HOCHDRUCK",
                icon: "arrow.up.right",
                value: "\(format(dischargePressure)) bar(g)",
                accent: .orange
            )
        }

        KalteConsoleCard(title: "Niederdruckseite", systemImage: "arrow.down.right.circle.fill", accent: .cyan) {
            KalteServiceField(title: "Verdampfung / Sättigung", unit: "°C", value: $evaporation, accent: .cyan)
            KalteServiceField(title: "Sauggas", unit: "°C", value: $suction, accent: .cyan)
            KalteServiceField(title: "Saugdruck", unit: "bar(g)", value: $suctionPressure, accent: .cyan)

            KalteResultStrip(
                title: "ÜBERHITZUNG",
                value: "\(format(superheat)) K",
                detail: superheat < 0 ? "Messpunkte / Sättigung prüfen" : "Sauggas − Verdampfung",
                accent: .cyan
            )
        }

        KalteConsoleCard(title: "Hochdruckseite", systemImage: "arrow.up.right.circle.fill", accent: .orange) {
            KalteServiceField(title: "Kondensation / Sättigung", unit: "°C", value: $condensation, accent: .orange)
            KalteServiceField(title: "Flüssigkeitsleitung", unit: "°C", value: $liquid, accent: .orange)
            KalteServiceField(title: "Hochdruck", unit: "bar(g)", value: $dischargePressure, accent: .orange)

            KalteResultStrip(
                title: "UNTERKÜHLUNG",
                value: "\(format(subcooling)) K",
                detail: subcooling < 0 ? "Messpunkte / Sättigung prüfen" : "Kondensation − Flüssigkeitsleitung",
                accent: .orange
            )
        }

        KalteConsoleCard(title: "Verdichter", systemImage: "gearshape.2.fill", accent: .purple) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("DRUCKVERHÄLTNIS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("aus Absolutdrücken")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(pressureRatio > 0 ? "\(format(pressureRatio, digits: 2)) : 1" : "–")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.purple)
            }
        }

        shareConsole
    }

    @ViewBuilder
    private var airContent: some View {
        KalteConsoleCard(title: "Luftseite", systemImage: "wind", accent: .blue) {
            KalteServiceField(title: "Luftmenge", unit: "m³/h", value: $airFlow, accent: .blue)
            KalteServiceField(title: "Lufteintritt", unit: "°C", value: $enteringAir, accent: .blue)
            KalteServiceField(title: "Luftaustritt", unit: "°C", value: $leavingAir, accent: .blue)
        }

        HStack(spacing: 12) {
            KalteSidePanel(title: "ΔT LUFT", icon: "thermometer.medium", value: "\(format(airDelta)) K", accent: .blue)
            KalteSidePanel(title: "SENSIBEL", icon: "bolt.fill", value: "\(format(airCapacity, digits: 2)) kW", accent: .indigo)
        }

        KalteConsoleCard(title: "Einordnung", systemImage: "info.circle.fill", accent: .blue) {
            Text("Die luftseitige Leistung ist eine sensible Näherung. Latente Leistung und Entfeuchtung sind darin nicht enthalten.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        shareConsole
    }

    @ViewBuilder
    private var converterContent: some View {
        KalteConsoleCard(title: "Temperatur", systemImage: "thermometer.medium", accent: .cyan) {
            KalteServiceField(title: "Celsius", unit: "°C", value: $celsius, accent: .cyan)
            converterLine("Fahrenheit", value: RefrigerationCalculator.celsiusToFahrenheit(celsius), unit: "°F", digits: 1, accent: .cyan)
        }

        KalteConsoleCard(title: "Druck", systemImage: "gauge.open.with.lines.needle.33percent", accent: .orange) {
            KalteServiceField(title: "bar", unit: "bar", value: $bar, accent: .orange)
            converterLine("psi", value: RefrigerationCalculator.barToPSI(bar), unit: "psi", digits: 2, accent: .orange)
            converterLine("kPa", value: RefrigerationCalculator.barToKPa(bar), unit: "kPa", digits: 1, accent: .orange)
        }

        KalteConsoleCard(title: "Vakuum absolut", systemImage: "arrow.down.to.line.compact", accent: .purple) {
            KalteServiceField(title: "mbar absolut", unit: "mbar", value: $vacuumMbar, accent: .purple)
            converterLine("Micron", value: RefrigerationCalculator.mbarToMicron(vacuumMbar), unit: "micron", digits: 0, accent: .purple)
            converterLine("Pascal", value: RefrigerationCalculator.mbarToPascal(vacuumMbar), unit: "Pa", digits: 1, accent: .purple)
            Text("Vakuumwerte sind Absolutdrücke – nicht mit bar(g) aus dem Kältekreis verwechseln.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var shareConsole: some View {
        ShareLink(item: serviceSummary) {
            HStack {
                Image(systemName: "doc.text.fill")
                Text("Servicewerte teilen")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "square.and.arrow.up")
            }
            .padding(16)
            .foregroundStyle(.black)
            .background(.cyan, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func statusPill(_ title: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(color)
            Text(value)
                .font(.caption.weight(.semibold).monospacedDigit())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(color.opacity(0.09), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.18)))
    }

    private func converterLine(_ title: String, value: Double, unit: String, digits: Int, accent: Color) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(format(value, digits: digits)) \(unit)")
                .font(.system(.body, design: .monospaced).weight(.bold))
                .foregroundStyle(accent)
        }
        .padding(.vertical, 5)
    }

    private func format(_ value: Double, digits: Int = 1) -> String {
        String(format: "%.*f", digits, value)
    }
}

private struct KalteConsoleBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.005, green: 0.025, blue: 0.045),
                Color(red: 0.015, green: 0.055, blue: 0.085),
                Color(red: 0.01, green: 0.02, blue: 0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct KalteConsoleCard<Content: View>: View {
    let title: String
    let systemImage: String
    let accent: Color
    @ViewBuilder let content: Content

    init(title: String, systemImage: String, accent: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .foregroundStyle(accent)
                Text(title.uppercased())
                    .font(.caption.weight(.black))
                    .tracking(1.1)
                Spacer()
            }
            content
        }
        .padding(16)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accent)
                .frame(width: 3)
                .padding(.vertical, 14)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
    }
}

private struct KalteServiceField: View {
    let title: String
    let unit: String
    @Binding var value: Double
    let accent: Color
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 10)
            HStack(spacing: 6) {
                TextField("0", value: $value, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .focused($focused)
                    .frame(minWidth: 64)
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(focused ? accent : Color.white.opacity(0.12), lineWidth: focused ? 1.5 : 1)
            }
        }
    }
}

private struct KalteResultStrip: View {
    let title: String
    let value: String
    let detail: String
    let accent: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(accent)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(value)
                .font(.system(size: 25, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
        }
        .padding(13)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct KalteSidePanel: View {
    let title: String
    let icon: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(accent)
                Spacer()
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                    .shadow(color: accent, radius: 5)
            }
            Text(title)
                .font(.caption2.weight(.black))
                .tracking(1)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.16))
        }
    }
}
