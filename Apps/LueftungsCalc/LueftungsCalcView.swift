import Foundation
import SwiftUI

enum LueftungsCalcMode: String, CaseIterable, Identifiable {
    case duct = "Kanal"
    case room = "Raum"
    case converter = "Umrechner"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .duct: "rectangle.split.3x1"
        case .room: "house"
        case .converter: "arrow.left.arrow.right"
        }
    }
}

struct LueftungsCalcView: View {
    @State private var mode: LueftungsCalcMode = .duct

    @State private var flow = 250.0
    @State private var targetVelocity = 3.0
    @State private var roundDiameter = 180.0
    @State private var rectangularWidth = 300.0
    @State private var rectangularHeight = 200.0

    @State private var roomLength = 5.0
    @State private var roomWidth = 4.0
    @State private var roomHeight = 2.5
    @State private var airChanges = 1.5
    @State private var installedRoomFlow = 75.0

    @State private var conversionFlow = 500.0

    private var requiredRoundDiameter: Double {
        VentilationCalculator.roundDiameterMM(
            volumeFlowM3H: flow,
            targetVelocityMS: targetVelocity
        )
    }

    private var nextCommonDiameter: Double {
        VentilationCalculator.nextCommonRoundDiameterMM(requiredDiameterMM: requiredRoundDiameter)
    }

    private var actualRoundVelocity: Double {
        VentilationCalculator.roundVelocityMS(volumeFlowM3H: flow, diameterMM: roundDiameter)
    }

    private var rectangularVelocity: Double {
        VentilationCalculator.velocityMS(
            volumeFlowM3H: flow,
            widthMM: rectangularWidth,
            heightMM: rectangularHeight
        )
    }

    private var equivalentRoundDiameter: Double {
        VentilationCalculator.equivalentRoundDiameterMM(
            widthMM: rectangularWidth,
            heightMM: rectangularHeight
        )
    }

    private var requiredRectangularHeight: Double {
        VentilationCalculator.rectangularRequiredHeightMM(
            volumeFlowM3H: flow,
            widthMM: rectangularWidth,
            targetVelocityMS: targetVelocity
        )
    }

    private var roomVolume: Double {
        VentilationCalculator.roomVolumeM3(
            lengthM: roomLength,
            widthM: roomWidth,
            heightM: roomHeight
        )
    }

    private var requiredRoomFlow: Double {
        VentilationCalculator.requiredFlowM3H(
            roomLengthM: roomLength,
            roomWidthM: roomWidth,
            roomHeightM: roomHeight,
            airChangesPerHour: airChanges
        )
    }

    private var actualAirChanges: Double {
        VentilationCalculator.airChangesPerHour(
            volumeFlowM3H: installedRoomFlow,
            roomVolumeM3: roomVolume
        )
    }

    private var reportText: String {
        """
        LüftungsCalc – Berechnung

        Kanal
        Volumenstrom: \(format(flow, digits: 0)) m³/h
        Zielgeschwindigkeit: \(format(targetVelocity)) m/s
        Rechnerischer Rund-Ø: \(format(requiredRoundDiameter, digits: 0)) mm
        Nächste gängige Rundgröße: \(format(nextCommonDiameter, digits: 0)) mm
        Gewählter Rund-Ø: \(format(roundDiameter, digits: 0)) mm
        Geschwindigkeit rund: \(format(actualRoundVelocity)) m/s
        Rechteck: \(format(rectangularWidth, digits: 0)) × \(format(rectangularHeight, digits: 0)) mm
        Geschwindigkeit rechteckig: \(format(rectangularVelocity)) m/s
        Äquivalenter Rund-Ø: \(format(equivalentRoundDiameter, digits: 0)) mm

        Raum
        Raumvolumen: \(format(roomVolume)) m³
        Ziel-Luftwechsel: \(format(airChanges)) 1/h
        Erforderliche Luftmenge: \(format(requiredRoomFlow, digits: 0)) m³/h
        Eingestellte Luftmenge: \(format(installedRoomFlow, digits: 0)) m³/h
        Tatsächlicher Luftwechsel: \(format(actualAirChanges)) 1/h

        Hinweis: Die Ergebnisse sind Rechenwerte. Auslegung, Schall, Druckverlust, Brandschutz und Hersteller-/Normvorgaben sind separat zu prüfen.
        """
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VentilationBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        airflowHeader
                        airflowNavigation

                        switch mode {
                        case .duct:
                            ductContent
                        case .room:
                            roomContent
                        case .converter:
                            converterContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("LüftungsCalc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: reportText) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(VentPalette.accent)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .shkKeyboardDismissal()
    }

    private var airflowHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("AIRFLOW STUDIO")
                        .font(.caption2.weight(.black))
                        .tracking(2.0)
                        .foregroundStyle(VentPalette.accent)
                    Text("Luftmenge sichtbar machen")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(VentPalette.ink)
                    Text("Kanalquerschnitt und Raumluftwechsel getrennt bearbeiten.")
                        .font(.subheadline)
                        .foregroundStyle(VentPalette.muted)
                }
                Spacer()
                Image(systemName: "wind")
                    .font(.system(size: 35, weight: .medium))
                    .foregroundStyle(VentPalette.accent)
                    .padding(13)
                    .background(VentPalette.accent.opacity(0.11), in: Circle())
            }

            AirflowRibbon(flow: flow, velocity: targetVelocity)
        }
        .padding(19)
        .background(VentPalette.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(VentPalette.outline)
        }
    }

    private var airflowNavigation: some View {
        HStack(spacing: 10) {
            ForEach(LueftungsCalcMode.allCases) { item in
                Button {
                    withAnimation(.easeOut(duration: 0.16)) { mode = item }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                        Text(item.rawValue)
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundStyle(mode == item ? Color.white : VentPalette.ink)
                    .background(
                        mode == item ? VentPalette.accent : VentPalette.surface,
                        in: Capsule()
                    )
                    .overlay {
                        if mode != item {
                            Capsule().stroke(VentPalette.outline)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var ductContent: some View {
        VentSectionCard(title: "Luftstrom", icon: "arrow.right") {
            HStack(spacing: 12) {
                VentCompactField(title: "Volumenstrom", unit: "m³/h", value: $flow)
                VentCompactField(title: "Ziel-v", unit: "m/s", value: $targetVelocity)
            }
        }

        HStack(spacing: 12) {
            VentResultCard(
                eyebrow: "RECHNERISCHER RUND-Ø",
                value: "\(format(requiredRoundDiameter, digits: 0)) mm",
                icon: "circle"
            )
            VentResultCard(
                eyebrow: "NÄCHSTE RUNDE GRÖSSE",
                value: "\(format(nextCommonDiameter, digits: 0)) mm",
                icon: "arrow.up.circle"
            )
        }

        VentSectionCard(title: "Rundkanal prüfen", icon: "circle.dotted") {
            VentWideField(title: "Gewählter Durchmesser", unit: "mm", value: $roundDiameter)
            VentResultLine(title: "Strömungsgeschwindigkeit", value: "\(format(actualRoundVelocity, digits: 2)) m/s")
            Text("Die nächste gängige Rundgröße ist eine Orientierung. Das konkrete Kanalsystem und die zulässige Strömung bleiben maßgebend.")
                .font(.caption)
                .foregroundStyle(VentPalette.muted)
        }

        VentSectionCard(title: "Rechteckkanal", icon: "rectangle") {
            HStack(spacing: 12) {
                VentCompactField(title: "Breite", unit: "mm", value: $rectangularWidth)
                VentCompactField(title: "Höhe", unit: "mm", value: $rectangularHeight)
            }

            DuctSketch(width: rectangularWidth, height: rectangularHeight, velocity: rectangularVelocity)

            VentResultLine(title: "Ist-Geschwindigkeit", value: "\(format(rectangularVelocity, digits: 2)) m/s")
            VentResultLine(title: "Äquivalenter Rund-Ø", value: "\(format(equivalentRoundDiameter, digits: 0)) mm")
            VentResultLine(title: "Höhe bei Ziel-v", value: "\(format(requiredRectangularHeight, digits: 0)) mm")
        }

        shareCard
    }

    @ViewBuilder
    private var roomContent: some View {
        VentSectionCard(title: "Raumgeometrie", icon: "cube.transparent") {
            HStack(spacing: 9) {
                VentCompactField(title: "Länge", unit: "m", value: $roomLength)
                VentCompactField(title: "Breite", unit: "m", value: $roomWidth)
                VentCompactField(title: "Höhe", unit: "m", value: $roomHeight)
            }

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("RAUMVOLUMEN")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(VentPalette.muted)
                    Text("\(format(roomVolume)) m³")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(VentPalette.ink)
                }
                Spacer()
                Image(systemName: "cube.fill")
                    .font(.title2)
                    .foregroundStyle(VentPalette.accent.opacity(0.65))
            }
            .padding(14)
            .background(VentPalette.tint, in: RoundedRectangle(cornerRadius: 16))
        }

        VentSectionCard(title: "Luftwechsel", icon: "arrow.triangle.2.circlepath") {
            VentWideField(title: "Ziel-Luftwechsel", unit: "1/h", value: $airChanges)

            VStack(alignment: .leading, spacing: 6) {
                Text("ERFORDERLICHE LUFTMENGE")
                    .font(.caption2.weight(.black))
                    .tracking(1.1)
                    .foregroundStyle(VentPalette.muted)
                Text("\(format(requiredRoomFlow, digits: 0)) m³/h")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(VentPalette.accent)
            }
            .padding(.vertical, 4)

            VentWideField(title: "Tatsächliche Luftmenge", unit: "m³/h", value: $installedRoomFlow)
            VentResultLine(title: "Tatsächlicher Luftwechsel", value: "\(format(actualAirChanges, digits: 2)) 1/h")
        }

        shareCard
    }

    @ViewBuilder
    private var converterContent: some View {
        VentSectionCard(title: "Volumenstrom umrechnen", icon: "arrow.left.arrow.right") {
            VentWideField(title: "Ausgangswert", unit: "m³/h", value: $conversionFlow)

            HStack(spacing: 12) {
                VentResultCard(
                    eyebrow: "LITER / SEKUNDE",
                    value: "\(format(VentilationCalculator.m3HToLitersPerSecond(conversionFlow), digits: 2)) l/s",
                    icon: "drop"
                )
                VentResultCard(
                    eyebrow: "CFM",
                    value: "\(format(VentilationCalculator.m3HToCFM(conversionFlow), digits: 1)) cfm",
                    icon: "wind"
                )
            }
        }

        VentSectionCard(title: "Planungshinweis", icon: "info.circle") {
            Text("LüftungsCalc berechnet Geometrie und Luftmengen. Druckverlust, Ventilatorbetriebspunkt, Schall, Filterzustand sowie Brandschutz- und Normanforderungen bleiben Teil der vollständigen Auslegung.")
                .font(.subheadline)
                .foregroundStyle(VentPalette.muted)
        }
    }

    private var shareCard: some View {
        ShareLink(item: reportText) {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("Luftberechnung teilen")
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "arrow.right")
            }
            .padding(15)
            .foregroundStyle(.white)
            .background(VentPalette.accent, in: Capsule())
        }
    }

    private func format(_ value: Double, digits: Int = 1) -> String {
        String(format: "%.*f", digits, value)
    }
}

private enum VentPalette {
    static let background = Color(red: 0.93, green: 0.975, blue: 0.99)
    static let surface = Color.white.opacity(0.94)
    static let accent = Color(red: 0.03, green: 0.55, blue: 0.72)
    static let ink = Color(red: 0.06, green: 0.17, blue: 0.21)
    static let muted = Color(red: 0.30, green: 0.44, blue: 0.49)
    static let outline = Color(red: 0.10, green: 0.55, blue: 0.68).opacity(0.14)
    static let tint = Color(red: 0.85, green: 0.96, blue: 0.98)
}

private struct VentilationBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [VentPalette.background, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(VentPalette.accent.opacity(0.035))
                    .frame(width: 360, height: 28)
                    .rotationEffect(.degrees(-12))
                    .offset(x: CGFloat(index % 2 == 0 ? -90 : 110), y: CGFloat(index * 145 - 330))
            }
        }
        .ignoresSafeArea()
    }
}

private struct AirflowRibbon: View {
    let flow: Double
    let velocity: Double

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VentPalette.accent.opacity(0.45 + Double(index) * 0.13))
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(String(format: "%.0f", flow)) m³/h")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(VentPalette.ink)
                Text("Ziel \(String(format: "%.1f", velocity)) m/s")
                    .font(.caption)
                    .foregroundStyle(VentPalette.muted)
            }
            Spacer()
            Image(systemName: "circle.grid.cross")
                .foregroundStyle(VentPalette.accent)
        }
        .padding(13)
        .background(VentPalette.tint, in: Capsule())
    }
}

private struct VentSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(VentPalette.ink)
                Spacer()
                Circle()
                    .fill(VentPalette.accent.opacity(0.12))
                    .frame(width: 10, height: 10)
            }
            content
        }
        .padding(17)
        .background(VentPalette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(VentPalette.outline)
        }
    }
}

private struct VentCompactField: View {
    let title: String
    let unit: String
    @Binding var value: Double
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(VentPalette.muted)
                .lineLimit(1)
            HStack(spacing: 4) {
                TextField("0", value: $value, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(VentPalette.ink)
                    .focused($focused)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(VentPalette.muted)
                    .fixedSize()
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity)
        .background(VentPalette.tint.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(focused ? VentPalette.accent : Color.clear, lineWidth: 1.4)
        }
    }
}

private struct VentWideField: View {
    let title: String
    let unit: String
    @Binding var value: Double
    @FocusState private var focused: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(VentPalette.muted)
            Spacer()
            HStack(spacing: 5) {
                TextField("0", value: $value, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(VentPalette.ink)
                    .focused($focused)
                    .frame(minWidth: 62)
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(VentPalette.muted)
                    .fixedSize()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(VentPalette.tint, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focused ? VentPalette.accent : Color.clear, lineWidth: 1.4)
            }
        }
    }
}

private struct VentResultCard: View {
    let eyebrow: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(VentPalette.accent)
            Text(eyebrow)
                .font(.caption2.weight(.black))
                .foregroundStyle(VentPalette.muted)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(VentPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(VentPalette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(VentPalette.outline))
    }
}

private struct VentResultLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(VentPalette.muted)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(VentPalette.accent)
        }
        .padding(.vertical, 3)
    }
}

private struct DuctSketch: View {
    let width: Double
    let height: Double
    let velocity: Double

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(VentPalette.accent, lineWidth: 2)
                    .frame(width: 86, height: 54)
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { _ in
                        Image(systemName: "arrow.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(VentPalette.accent)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(String(format: "%.0f", width)) × \(String(format: "%.0f", height)) mm")
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(VentPalette.ink)
                Text("\(String(format: "%.2f", velocity)) m/s im Querschnitt")
                    .font(.caption)
                    .foregroundStyle(VentPalette.muted)
            }
            Spacer()
        }
        .padding(13)
        .background(VentPalette.tint.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
    }
}
