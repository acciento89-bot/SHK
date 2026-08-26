import Foundation
import SwiftUI

enum RohrCalcMode: String, CaseIterable, Identifiable {
    case hydraulics = "Hydraulik"
    case sizing = "Dimension"
    case comparison = "Matrix"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hydraulics: "waveform.path.ecg.rectangle"
        case .sizing: "ruler"
        case .comparison: "square.grid.3x3"
        }
    }
}

struct RohrCalcView: View {
    @State private var mode: RohrCalcMode = .hydraulics

    @State private var flow = 1000.0
    @State private var diameter = 20.0
    @State private var length = 10.0
    @State private var roughness = 0.01
    @State private var zetaTotal = 0.0
    @State private var targetVelocity = 1.0

    private let comparisonDiameters: [Double] = [10, 12, 13, 16, 20, 25, 26, 32, 39, 50, 54]

    private var result: ExtendedPipeHydraulics {
        PipeCalculator.calculateExtended(
            volumeFlowLPH: flow,
            innerDiameterMM: diameter,
            lengthM: length,
            roughnessMM: roughness,
            zetaTotal: zetaTotal
        )
    }

    private var requiredDiameter: Double {
        PipeCalculator.requiredInnerDiameterMM(
            volumeFlowLPH: flow,
            targetVelocityMS: targetVelocity
        )
    }

    private var maximumFlowAtTargetVelocity: Double {
        PipeCalculator.maximumVolumeFlowLPH(
            innerDiameterMM: diameter,
            maximumVelocityMS: targetVelocity
        )
    }

    private var shareText: String {
        """
        RohrCalc – Hydraulik

        Volumenstrom: \(format(flow, digits: 0)) l/h
        Innendurchmesser: \(format(diameter)) mm
        Rohrlänge: \(format(length)) m
        absolute Rauheit: \(format(roughness, digits: 3)) mm
        ζ-Summe: \(format(zetaTotal, digits: 2))

        Geschwindigkeit: \(format(result.base.velocityMS, digits: 2)) m/s
        Reynolds-Zahl: \(format(result.reynoldsNumber, digits: 0))
        Strömung: \(result.flowRegime.rawValue)
        Rohrreibungsverlust: \(format(result.base.pressureDropPaPerM, digits: 0)) Pa/m
        Rohrstrecke: \(format(result.base.totalPressureDropKPa, digits: 2)) kPa
        Einzelwiderstände: \(format(result.localPressureLossKPa, digits: 2)) kPa
        Gesamtverlust: \(format(result.totalPressureLossIncludingLocalKPa, digits: 2)) kPa
        Förderhöhe: \(format(result.totalHeadMeters, digits: 2)) mWS
        Rohrinhalt: \(format(result.base.pipeVolumeL, digits: 2)) l

        Hinweis: Standardrechnung mit Wasserkennwerten nahe 20 °C. Tatsächliche Mediumtemperatur, Glykolanteil, Rohrzustand und Herstellerangaben können das Ergebnis verändern.
        """
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PipeBlueprintBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        blueprintHeader
                        modeRail

                        switch mode {
                        case .hydraulics:
                            hydraulicsContent
                        case .sizing:
                            sizingContent
                        case .comparison:
                            comparisonContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("RohrCalc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(PipePalette.accent)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .shkKeyboardDismissal()
    }

    private var blueprintHeader: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("HYDRAULIC WORKSHEET")
                        .font(.caption2.weight(.black))
                        .tracking(2.4)
                        .foregroundStyle(PipePalette.accent)
                    Text("Rohrstrecke 01")
                        .font(.system(size: 31, weight: .bold, design: .monospaced))
                    Text("Freier Innendurchmesser · reale Länge · ζ-Widerstände")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.system(size: 29, weight: .medium))
                    .foregroundStyle(PipePalette.accent)
                    .padding(13)
                    .background(PipePalette.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 0) {
                PipeHeaderStat(label: "Q", value: "\(format(flow, digits: 0)) l/h")
                Divider().overlay(Color.white.opacity(0.12)).padding(.vertical, 4)
                PipeHeaderStat(label: "Øi", value: "\(format(diameter)) mm")
                Divider().overlay(Color.white.opacity(0.12)).padding(.vertical, 4)
                PipeHeaderStat(label: "v", value: "\(format(result.base.velocityMS, digits: 2)) m/s")
            }
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(18)
        .background(PipePalette.panel, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(PipePalette.line, lineWidth: 1)
        }
    }

    private var modeRail: some View {
        HStack(spacing: 10) {
            ForEach(RohrCalcMode.allCases) { item in
                Button {
                    mode = item
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: item.icon)
                        Text(item.rawValue)
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(mode == item ? Color.black : PipePalette.textSecondary)
                    .background(mode == item ? PipePalette.accent : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        if mode != item {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(PipePalette.line)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var pipeInputs: some View {
        PipeBlueprintCard(index: "A", title: "Rohrstrecke", icon: "line.diagonal") {
            PipeField(code: "Q", title: "Volumenstrom", unit: "l/h", value: $flow)
            PipeField(code: "DI", title: "Innendurchmesser", unit: "mm", value: $diameter)
            PipeField(code: "L", title: "Rohrlänge", unit: "m", value: $length)
            PipeField(code: "EPS", title: "Rauheit ε", unit: "mm", value: $roughness)
            PipeField(code: "ZETA", title: "ζ-Summe", unit: "", value: $zetaTotal)

            Text("Rauheit als Rechenwert der Innenoberfläche verwenden. Bei unbekanntem Rohrzustand keine Scheingenauigkeit erzeugen.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var hydraulicsContent: some View {
        pipeInputs

        PipeBlueprintCard(index: "B", title: "Strömungszustand", icon: "waveform.path") {
            HStack(spacing: 10) {
                PipeMetricTile(code: "V", label: "Geschwindigkeit", value: "\(format(result.base.velocityMS, digits: 2)) m/s")
                PipeMetricTile(code: "RE", label: result.flowRegime.rawValue, value: format(result.reynoldsNumber, digits: 0))
            }

            PipeResultLine(label: "Rohrreibung", value: "\(format(result.base.pressureDropPaPerM, digits: 0)) Pa/m")
            PipeResultLine(label: "Rohrreibung", value: "\(format(PipeCalculator.pascalPerMeterToMbarPerMeter(result.base.pressureDropPaPerM), digits: 2)) mbar/m")
            PipeResultLine(label: "Rohrstrecke", value: "\(format(result.base.totalPressureDropKPa, digits: 2)) kPa")
            PipeResultLine(label: "Einzelwiderstände", value: "\(format(result.localPressureLossKPa, digits: 2)) kPa")
        }

        PipeBlueprintCard(index: "C", title: "Druckbilanz", icon: "arrow.down.right.and.arrow.up.left") {
            VStack(alignment: .leading, spacing: 5) {
                Text("GESAMTDRUCKVERLUST")
                    .font(.caption2.weight(.black))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Text("\(format(result.totalPressureLossIncludingLocalKPa, digits: 2)) kPa")
                    .font(.system(size: 38, weight: .black, design: .monospaced))
                    .foregroundStyle(PipePalette.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)

            PipeResultLine(label: "Förderhöhe", value: "\(format(result.totalHeadMeters, digits: 2)) mWS")
            PipeResultLine(label: "Rohrinhalt", value: "\(format(result.base.pipeVolumeL, digits: 2)) l")
        }

        mediumNotice
        shareBlock
    }

    @ViewBuilder
    private var sizingContent: some View {
        PipeBlueprintCard(index: "D", title: "Geometrische Dimension", icon: "scope") {
            PipeField(code: "Q", title: "Volumenstrom", unit: "l/h", value: $flow)
            PipeField(code: "VT", title: "Zielgeschwindigkeit", unit: "m/s", value: $targetVelocity)

            VStack(alignment: .leading, spacing: 5) {
                Text("ERFORDERLICHER FREIER Ø")
                    .font(.caption2.weight(.black))
                    .tracking(1.3)
                    .foregroundStyle(.secondary)
                Text("\(format(requiredDiameter)) mm")
                    .font(.system(size: 42, weight: .black, design: .monospaced))
                    .foregroundStyle(PipePalette.accent)
            }
            .padding(.vertical, 8)
        }

        PipeBlueprintCard(index: "E", title: "Bestandsrohr", icon: "checkmark.circle") {
            PipeField(code: "DI", title: "Innendurchmesser", unit: "mm", value: $diameter)
            PipeResultLine(label: "Ist-Geschwindigkeit", value: "\(format(result.base.velocityMS, digits: 2)) m/s")
            PipeResultLine(label: "Max. Q bei Ziel-v", value: "\(format(maximumFlowAtTargetVelocity, digits: 0)) l/h")
        }

        PipeBlueprintCard(index: "!", title: "Auslegungshinweis", icon: "exclamationmark.triangle") {
            Text("Der geometrisch benötigte Innendurchmesser ist keine vollständige Rohrdimensionierung. Druckverlust, Pumpenförderhöhe, Armaturen, Geräusch und Herstellerdimensionen gehören in die Gesamtbewertung.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var comparisonContent: some View {
        PipeBlueprintCard(index: "M", title: "Vergleichsmatrix", icon: "square.grid.3x3") {
            PipeField(code: "Q", title: "Volumenstrom", unit: "l/h", value: $flow)
            PipeField(code: "L", title: "Rohrlänge", unit: "m", value: $length)
            PipeField(code: "EPS", title: "Rauheit ε", unit: "mm", value: $roughness)
            Text("Verglichen werden freie Innendurchmesser, bewusst ohne DN- oder Außendurchmesser-Zuordnung.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        VStack(spacing: 0) {
            HStack {
                Text("Øi")
                Spacer()
                Text("v")
                    .frame(width: 82, alignment: .trailing)
                Text("Pa/m")
                    .frame(width: 82, alignment: .trailing)
            }
            .font(.caption2.weight(.black))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)

            ForEach(comparisonDiameters, id: \.self) { candidate in
                let candidateResult = PipeCalculator.calculateExtended(
                    volumeFlowLPH: flow,
                    innerDiameterMM: candidate,
                    lengthM: length,
                    roughnessMM: roughness
                )

                HStack {
                    Text("Ø \(format(candidate, digits: 0)) mm")
                        .font(.system(.body, design: .monospaced).weight(.bold))
                    Spacer()
                    Text(format(candidateResult.base.velocityMS, digits: 2))
                        .frame(width: 82, alignment: .trailing)
                    Text(format(candidateResult.base.pressureDropPaPerM, digits: 0))
                        .frame(width: 82, alignment: .trailing)
                        .foregroundStyle(PipePalette.accent)
                }
                .font(.system(.subheadline, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(candidate == diameter ? PipePalette.accent.opacity(0.09) : Color.clear)

                if candidate != comparisonDiameters.last {
                    Divider().overlay(PipePalette.line)
                }
            }
        }
        .padding(8)
        .background(PipePalette.panel, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(PipePalette.line))

        mediumNotice
    }

    private var mediumNotice: some View {
        PipeBlueprintCard(index: "W", title: "Rechenmedium", icon: "drop") {
            Text("v1 nutzt Wasserkennwerte nahe 20 °C: ρ ≈ 998 kg/m³ und ν ≈ 1,004·10⁻⁶ m²/s. Temperatur, Glykol und andere Medien verändern Reynolds-Zahl und Druckverlust.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var shareBlock: some View {
        ShareLink(item: shareText) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Hydraulikblatt teilen")
                    .fontWeight(.bold)
                Spacer()
                Text("PDF/Text")
                    .font(.caption.monospaced())
                    .opacity(0.7)
            }
            .padding(14)
            .foregroundStyle(.black)
            .background(PipePalette.accent, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func format(_ value: Double, digits: Int = 1) -> String {
        String(format: "%.*f", digits, value)
    }
}

private enum PipePalette {
    static let accent = Color(red: 0.35, green: 0.95, blue: 0.84)
    static let panel = Color(red: 0.035, green: 0.10, blue: 0.14).opacity(0.96)
    static let line = Color(red: 0.30, green: 0.72, blue: 0.72).opacity(0.22)
    static let textSecondary = Color.white.opacity(0.66)
}

private struct PipeBlueprintBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.018, green: 0.07, blue: 0.10),
                    Color(red: 0.025, green: 0.12, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GeometryReader { proxy in
                Path { path in
                    let spacing: CGFloat = 28
                    var x: CGFloat = 0
                    while x <= proxy.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                        x += spacing
                    }
                    var y: CGFloat = 0
                    while y <= proxy.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                        y += spacing
                    }
                }
                .stroke(PipePalette.line.opacity(0.35), lineWidth: 0.5)
            }
        }
        .ignoresSafeArea()
    }
}

private struct PipeHeaderStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundStyle(PipePalette.accent)
            Text(value)
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PipeBlueprintCard<Content: View>: View {
    let index: String
    let title: String
    let icon: String
    let content: Content

    init(index: String, title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.index = index
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(index)
                    .font(.system(.caption, design: .monospaced).weight(.black))
                    .foregroundStyle(.black)
                    .frame(width: 27, height: 27)
                    .background(PipePalette.accent, in: RoundedRectangle(cornerRadius: 5))
                Label(title.uppercased(), systemImage: icon)
                    .font(.caption.weight(.black))
                    .tracking(0.8)
                Spacer()
            }
            content
        }
        .padding(15)
        .background(PipePalette.panel, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(PipePalette.line))
    }
}

private struct PipeField: View {
    let code: String
    let title: String
    let unit: String
    @Binding var value: Double
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(code)
                .font(.system(.caption2, design: .monospaced).weight(.black))
                .foregroundStyle(PipePalette.accent)
                .frame(width: 38, alignment: .leading)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            HStack(spacing: 5) {
                TextField("0", value: $value, format: .number.precision(.fractionLength(0...3)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .focused($focused)
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
            .frame(width: 145)
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(focused ? PipePalette.accent : PipePalette.line, lineWidth: focused ? 1.5 : 1)
            }
        }
    }
}

private struct PipeMetricTile: View {
    let code: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(code)
                .font(.caption2.weight(.black))
                .foregroundStyle(PipePalette.accent)
            Text(value)
                .font(.system(.title3, design: .monospaced).weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(PipePalette.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(PipePalette.line))
    }
}

private struct PipeResultLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundStyle(PipePalette.accent)
        }
        .padding(.vertical, 3)
    }
}
