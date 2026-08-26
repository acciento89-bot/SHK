import Foundation
import SwiftUI

enum HeizkoerperCalcMode: String, CaseIterable, Identifiable {
    case performance = "Leistung"
    case sizing = "Raum auslegen"
    case comparison = "Temperaturen"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .performance: "radiator"
        case .sizing: "house"
        case .comparison: "thermometer.medium"
        }
    }
}

enum HeizkoerperMethodChoice: String, CaseIterable, Identifiable {
    case automatic = "Automatik"
    case arithmetic = "Arithmetisch"
    case logarithmic = "Logarithmisch"

    var id: String { rawValue }

    var method: RadiatorTemperatureMethod {
        switch self {
        case .automatic: .automatic
        case .arithmetic: .arithmetic
        case .logarithmic: .logarithmic
        }
    }
}

struct HeatingRegime: Identifiable {
    let name: String
    let flowC: Double
    let returnC: Double
    let roomC: Double

    var id: String { name }
}

struct HeizkoerperCalcView: View {
    @State private var mode: HeizkoerperCalcMode = .performance
    @State private var methodChoice: HeizkoerperMethodChoice = .automatic

    @State private var nominalPower = 2000.0
    @State private var requiredRoomPower = 1500.0
    @State private var flow = 55.0
    @State private var returnTemp = 45.0
    @State private var room = 20.0
    @State private var exponent = 1.30

    private let regimes = [
        HeatingRegime(name: "75 / 65 / 20", flowC: 75, returnC: 65, roomC: 20),
        HeatingRegime(name: "70 / 55 / 20", flowC: 70, returnC: 55, roomC: 20),
        HeatingRegime(name: "55 / 45 / 20", flowC: 55, returnC: 45, roomC: 20),
        HeatingRegime(name: "45 / 35 / 20", flowC: 45, returnC: 35, roomC: 20)
    ]

    private var evaluation: RadiatorTemperatureEvaluation {
        RadiatorCalculator.temperatureEvaluation(
            flowC: flow,
            returnC: returnTemp,
            roomC: room,
            method: methodChoice.method
        )
    }

    private var actualPower: Double {
        RadiatorCalculator.correctedPowerW(
            nominalPowerDeltaT50W: nominalPower,
            flowC: flow,
            returnC: returnTemp,
            roomC: room,
            exponent: exponent,
            method: methodChoice.method
        )
    }

    private var waterSpread: Double { flow - returnTemp }

    private var volumeFlow: Double {
        RadiatorCalculator.volumeFlowLPH(powerW: actualPower, waterDeltaTK: waterSpread)
    }

    private var requiredNominalPower: Double {
        RadiatorCalculator.requiredNominalPowerDeltaT50W(
            requiredActualPowerW: requiredRoomPower,
            flowC: flow,
            returnC: returnTemp,
            roomC: room,
            exponent: exponent,
            method: methodChoice.method
        )
    }

    private var radiatorCount: Int {
        RadiatorCalculator.radiatorCount(
            requiredPowerW: requiredRoomPower,
            actualPowerPerRadiatorW: actualPower
        )
    }

    private var resolvedMethodName: String {
        switch evaluation.method {
        case .arithmetic: "arithmetisch"
        case .logarithmic: "logarithmisch"
        case .automatic: "automatisch"
        }
    }

    private var shareText: String {
        """
        HeizkörperCalc – Ergebnis

        Heizkörper-Nennleistung ΔT50: \(format(nominalPower, digits: 0)) W
        Hersteller-Exponent n: \(format(exponent, digits: 2))
        Systemtemperaturen: \(format(flow)) / \(format(returnTemp)) / \(format(room)) °C
        Berechnungsmethode: \(resolvedMethodName)
        Mittlere Übertemperatur: \(format(evaluation.deltaTK, digits: 2)) K
        Ist-Leistung: \(format(actualPower, digits: 0)) W
        Wasserspreizung: \(format(waterSpread)) K
        Volumenstrom: \(format(volumeFlow, digits: 0)) l/h

        Raum-Heizlast / Ziel-Leistung: \(format(requiredRoomPower, digits: 0)) W
        Benötigte Nennleistung ΔT50: \(format(requiredNominalPower, digits: 0)) W
        Anzahl des gewählten Heizkörpers: \(radiatorCount)

        Hinweis: Herstellerangaben zu Nennleistung und Exponent n haben Vorrang. Die Berechnung ist eine Auslegungshilfe und ersetzt keine vollständige Heizlastberechnung.
        """
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RadiatorRoomBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        roomHeader
                        roomNavigation

                        switch mode {
                        case .performance:
                            performanceContent
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
            .navigationTitle("HeizkörperCalc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(RadiatorPalette.accent)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .shkKeyboardDismissal()
    }

    private var roomHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("RAUM & HEIZFLÄCHE")
                        .font(.caption2.weight(.black))
                        .tracking(1.8)
                        .foregroundStyle(RadiatorPalette.accent)
                    Text("Heizkörper passend zum Betriebspunkt")
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .foregroundStyle(RadiatorPalette.ink)
                    Text("Leistung, Temperaturpaar und Volumenstrom zusammen betrachten.")
                        .font(.subheadline)
                        .foregroundStyle(RadiatorPalette.muted)
                }
                Spacer()
                Image(systemName: "radiator")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(RadiatorPalette.accent)
                    .padding(13)
                    .background(RadiatorPalette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
            }

            HStack(spacing: 12) {
                RadiatorStatusTile(label: "VORLAUF", value: "\(format(flow, digits: 0))°")
                RadiatorStatusTile(label: "RÜCKLAUF", value: "\(format(returnTemp, digits: 0))°")
                RadiatorStatusTile(label: "RAUM", value: "\(format(room, digits: 0))°")
            }
        }
        .padding(19)
        .background(RadiatorPalette.paper, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: RadiatorPalette.shadow, radius: 18, y: 8)
    }

    private var roomNavigation: some View {
        HStack(spacing: 10) {
            ForEach(HeizkoerperCalcMode.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { mode = item }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.headline)
                        Text(item.rawValue)
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundStyle(mode == item ? Color.white : RadiatorPalette.ink)
                    .background(
                        mode == item ? RadiatorPalette.accent : RadiatorPalette.paper,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .shadow(color: RadiatorPalette.shadow.opacity(mode == item ? 0 : 1), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var commonInputs: some View {
        VStack(spacing: 14) {
            RadiatorSectionCard(number: "01", title: "Heizkörperdaten", icon: "radiator") {
                RadiatorField(title: "Hersteller-Nennleistung", badge: "ΔT50", unit: "W", value: $nominalPower)
                RadiatorField(title: "Hersteller-Exponent", badge: "n", unit: "", value: $exponent)
                Text("ΔT50 ist die mittlere Heizkörper-Übertemperatur zum Raum, nicht die Vor-/Rücklauf-Spreizung.")
                    .font(.caption)
                    .foregroundStyle(RadiatorPalette.muted)
            }

            RadiatorSectionCard(number: "02", title: "Betriebspunkt", icon: "thermometer.medium") {
                HStack(spacing: 10) {
                    RadiatorCompactField(label: "VL", unit: "°C", value: $flow)
                    RadiatorCompactField(label: "RL", unit: "°C", value: $returnTemp)
                    RadiatorCompactField(label: "RAUM", unit: "°C", value: $room)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Berechnungsmethode")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RadiatorPalette.muted)
                        Text(resolvedMethodName.capitalized)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RadiatorPalette.ink)
                    }
                    Spacer()
                    Picker("Methode", selection: $methodChoice) {
                        ForEach(HeizkoerperMethodChoice.allCases) { choice in
                            Text(choice.rawValue).tag(choice)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(RadiatorPalette.accent)
                }
            }
        }
    }

    @ViewBuilder
    private var performanceContent: some View {
        commonInputs

        RadiatorHeroResult(
            eyebrow: "AKTUELLER BETRIEBSPUNKT",
            value: "\(format(actualPower, digits: 0)) W",
            detail: "Mittlere Übertemperatur \(format(evaluation.deltaTK, digits: 2)) K",
            progress: nominalPower > 0 ? min(max(actualPower / nominalPower, 0), 1.25) / 1.25 : 0
        )

        RadiatorSectionCard(number: "03", title: "Hydraulische Folge", icon: "drop") {
            RadiatorResultLine(title: "Wasserspreizung", value: "\(format(waterSpread)) K")
            RadiatorResultLine(title: "Volumenstrom", value: "\(format(volumeFlow, digits: 0)) l/h")
            RadiatorResultLine(title: "Leistungsfaktor", value: "\(format(nominalPower > 0 ? actualPower / nominalPower : 0, digits: 3)) ×")
        }

        formulaNote
        shareCard
    }

    @ViewBuilder
    private var sizingContent: some View {
        commonInputs

        RadiatorSectionCard(number: "03", title: "Raumziel", icon: "house.fill") {
            RadiatorField(title: "Heizlast / Ziel-Leistung", badge: "RAUM", unit: "W", value: $requiredRoomPower)

            VStack(alignment: .leading, spacing: 4) {
                Text("ERFORDERLICHE NENNLEISTUNG ΔT50")
                    .font(.caption2.weight(.black))
                    .tracking(1.1)
                    .foregroundStyle(RadiatorPalette.muted)
                Text("\(format(requiredNominalPower, digits: 0)) W")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(RadiatorPalette.accent)
            }
            .padding(.vertical, 6)
        }

        HStack(spacing: 12) {
            RadiatorCountCard(title: "Gewählter Heizkörper", value: "\(format(actualPower, digits: 0)) W", icon: "radiator")
            RadiatorCountCard(title: "Benötigte Stückzahl", value: "\(radiatorCount)", icon: "number.circle.fill")
        }

        formulaNote
        shareCard
    }

    @ViewBuilder
    private var comparisonContent: some View {
        RadiatorSectionCard(number: "01", title: "Vergleichs-Heizkörper", icon: "radiator") {
            RadiatorField(title: "Hersteller-Nennleistung", badge: "ΔT50", unit: "W", value: $nominalPower)
            RadiatorField(title: "Hersteller-Exponent", badge: "n", unit: "", value: $exponent)
        }

        VStack(spacing: 12) {
            ForEach(regimes) { regime in
                let regimeEvaluation = RadiatorCalculator.temperatureEvaluation(
                    flowC: regime.flowC,
                    returnC: regime.returnC,
                    roomC: regime.roomC
                )
                let regimePower = RadiatorCalculator.correctedPowerW(
                    nominalPowerDeltaT50W: nominalPower,
                    flowC: regime.flowC,
                    returnC: regime.returnC,
                    roomC: regime.roomC,
                    exponent: exponent
                )
                let regimeFlow = RadiatorCalculator.volumeFlowLPH(
                    powerW: regimePower,
                    waterDeltaTK: regime.flowC - regime.returnC
                )

                VStack(alignment: .leading, spacing: 11) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(regime.name + " °C")
                                .font(.headline)
                                .foregroundStyle(RadiatorPalette.ink)
                            Text("ΔT \(format(regimeEvaluation.deltaTK, digits: 1)) K")
                                .font(.caption)
                                .foregroundStyle(RadiatorPalette.muted)
                        }
                        Spacer()
                        Text("\(format(regimePower, digits: 0)) W")
                            .font(.title3.bold())
                            .foregroundStyle(RadiatorPalette.accent)
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(RadiatorPalette.track)
                            Capsule()
                                .fill(RadiatorPalette.accent)
                                .frame(width: proxy.size.width * min(max(nominalPower > 0 ? regimePower / nominalPower : 0, 0), 1))
                        }
                    }
                    .frame(height: 7)

                    HStack {
                        Text("\(format(nominalPower > 0 ? regimePower / nominalPower * 100 : 0, digits: 0)) % Nennleistung")
                        Spacer()
                        Text("\(format(regimeFlow, digits: 0)) l/h")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RadiatorPalette.muted)
                }
                .padding(16)
                .background(RadiatorPalette.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: RadiatorPalette.shadow, radius: 10, y: 5)
            }
        }

        formulaNote
    }

    private var formulaNote: some View {
        RadiatorSectionCard(number: "i", title: "Berechnungsgrundlage", icon: "function") {
            Text("Die Leistungsumrechnung folgt Φ = Φₙ · (ΔT / ΔTₙ)ⁿ. In Automatik wird bei stark asymmetrischen Temperaturen logarithmisch, sonst arithmetisch bewertet.")
                .font(.subheadline)
                .foregroundStyle(RadiatorPalette.muted)
            Text("Herstellerdaten zu Nennleistung und Exponent n haben Vorrang.")
                .font(.caption)
                .foregroundStyle(RadiatorPalette.muted)
        }
    }

    private var shareCard: some View {
        ShareLink(item: shareText) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Auslegung teilen")
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "radiator")
            }
            .padding(15)
            .foregroundStyle(.white)
            .background(RadiatorPalette.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func format(_ value: Double, digits: Int = 1) -> String {
        String(format: "%.*f", digits, value)
    }
}

private enum RadiatorPalette {
    static let background = Color(red: 0.965, green: 0.94, blue: 0.90)
    static let paper = Color(red: 1.0, green: 0.985, blue: 0.955)
    static let accent = Color(red: 0.78, green: 0.25, blue: 0.12)
    static let ink = Color(red: 0.16, green: 0.12, blue: 0.10)
    static let muted = Color(red: 0.40, green: 0.34, blue: 0.30)
    static let track = Color(red: 0.82, green: 0.76, blue: 0.69).opacity(0.38)
    static let shadow = Color.black.opacity(0.07)
}

private struct RadiatorRoomBackground: View {
    var body: some View {
        ZStack {
            RadiatorPalette.background
            Circle()
                .fill(RadiatorPalette.accent.opacity(0.06))
                .frame(width: 360, height: 360)
                .offset(x: 170, y: -270)
            RoundedRectangle(cornerRadius: 80)
                .fill(Color.white.opacity(0.28))
                .frame(width: 330, height: 180)
                .rotationEffect(.degrees(-12))
                .offset(x: -170, y: 310)
        }
        .ignoresSafeArea()
    }
}

private struct RadiatorStatusTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundStyle(RadiatorPalette.muted)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(RadiatorPalette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(RadiatorPalette.background.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct RadiatorSectionCard<Content: View>: View {
    let number: String
    let title: String
    let icon: String
    let content: Content

    init(number: String, title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.number = number
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(number)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(RadiatorPalette.accent, in: Circle())
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(RadiatorPalette.ink)
                Spacer()
            }
            content
        }
        .padding(17)
        .background(RadiatorPalette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: RadiatorPalette.shadow, radius: 12, y: 6)
    }
}

private struct RadiatorField: View {
    let title: String
    let badge: String
    let unit: String
    @Binding var value: Double
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RadiatorPalette.ink)
                Text(badge)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(RadiatorPalette.accent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(RadiatorPalette.accent.opacity(0.09), in: Capsule())
                Spacer()
            }
            HStack {
                TextField("0", value: $value, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(RadiatorPalette.ink)
                    .focused($focused)
                Text(unit)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RadiatorPalette.muted)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(RadiatorPalette.background.opacity(0.65), in: RoundedRectangle(cornerRadius: 13))
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .stroke(focused ? RadiatorPalette.accent : Color.clear, lineWidth: 1.5)
            }
        }
    }
}

private struct RadiatorCompactField: View {
    let label: String
    let unit: String
    @Binding var value: Double
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundStyle(RadiatorPalette.muted)
            HStack(spacing: 3) {
                TextField("0", value: $value, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(RadiatorPalette.ink)
                    .focused($focused)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(RadiatorPalette.muted)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(RadiatorPalette.background.opacity(0.72), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(focused ? RadiatorPalette.accent : Color.clear, lineWidth: 1.3)
        }
    }
}

private struct RadiatorHeroResult: View {
    let eyebrow: String
    let value: String
    let detail: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(eyebrow)
                .font(.caption2.weight(.black))
                .tracking(1.3)
                .foregroundStyle(RadiatorPalette.muted)
            Text(value)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(RadiatorPalette.accent)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(RadiatorPalette.muted)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(RadiatorPalette.track)
                    Capsule()
                        .fill(RadiatorPalette.accent)
                        .frame(width: proxy.size.width * min(max(progress, 0), 1))
                }
            }
            .frame(height: 8)
        }
        .padding(19)
        .background(RadiatorPalette.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: RadiatorPalette.shadow, radius: 12, y: 6)
    }
}

private struct RadiatorResultLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(RadiatorPalette.muted)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundStyle(RadiatorPalette.ink)
        }
        .padding(.vertical, 3)
    }
}

private struct RadiatorCountCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(RadiatorPalette.accent)
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(RadiatorPalette.ink)
            Text(title)
                .font(.caption)
                .foregroundStyle(RadiatorPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RadiatorPalette.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: RadiatorPalette.shadow, radius: 10, y: 5)
    }
}
