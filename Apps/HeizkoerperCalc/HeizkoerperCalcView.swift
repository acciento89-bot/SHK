import Foundation
import SwiftUI

enum HeizkoerperCalcMode: String, CaseIterable, Identifiable {
    case performance = "Leistung"
    case sizing = "Auslegung"
    case comparison = "Vergleich"

    var id: String { rawValue }
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

    private var waterSpread: Double {
        flow - returnTemp
    }

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
                SHKBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        header

                        Picker("Bereich", selection: $mode) {
                            ForEach(HeizkoerperCalcMode.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch mode {
                        case .performance:
                            performanceContent
                        case .sizing:
                            sizingContent
                        case .comparison:
                            comparisonContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("HeizkörperCalc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Ergebnis teilen")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        SHKCard {
            HStack(spacing: 14) {
                Image(systemName: "radiator")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.mint)
                    .frame(width: 54, height: 54)
                    .background(.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Heizkörper richtig umrechnen")
                        .font(.title2.bold())
                    Text("ΔT50, Niedertemperatur und Volumenstrom.")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var commonInputCards: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Heizkörper", icon: "radiator")
                MetricField(title: "Nennleistung ΔT50", unit: "W", value: $nominalPower)
                MetricField(title: "Exponent n", unit: "", value: $exponent)

                Text("Den Exponenten n möglichst aus den Herstellerdaten des konkreten Heizkörpers übernehmen. 1,30 ist nur der voreingestellte Arbeitswert.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Betriebspunkt", icon: "thermometer.medium")
                MetricField(title: "Vorlauf", unit: "°C", value: $flow)
                MetricField(title: "Rücklauf", unit: "°C", value: $returnTemp)
                MetricField(title: "Raum", unit: "°C", value: $room)

                Picker("Methode", selection: $methodChoice) {
                    ForEach(HeizkoerperMethodChoice.allCases) { choice in
                        Text(choice.rawValue).tag(choice)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Verwendet")
                    Spacer()
                    Text(resolvedMethodName.capitalized)
                        .foregroundStyle(.mint)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Verhältnis c")
                    Spacer()
                    Text(format(evaluation.ratioC, digits: 3))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var performanceContent: some View {
        commonInputCards

        SHKCard {
            VStack(alignment: .leading, spacing: 16) {
                BigResult(
                    title: "IST-LEISTUNG",
                    value: String(format: "%.0f W", actualPower),
                    subtitle: String(format: "Mittlere Übertemperatur %.2f K", evaluation.deltaTK)
                )

                Divider().opacity(0.4)

                resultRow("Wasserspreizung", value: waterSpread, unit: "K", digits: 1)
                resultRow("Volumenstrom", value: volumeFlow, unit: "l/h", digits: 0)
                resultRow("Leistungsfaktor", value: nominalPower > 0 ? actualPower / nominalPower : 0, unit: "× ΔT50", digits: 3)
            }
        }

        formulaNotice
        shareCard
    }

    @ViewBuilder
    private var sizingContent: some View {
        commonInputCards

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Benötigte Raumleistung", icon: "house")
                MetricField(title: "Heizlast / Ziel", unit: "W", value: $requiredRoomPower)

                BigResult(
                    title: "ERFORDERLICHE NENNLEISTUNG ΔT50",
                    value: String(format: "%.0f W", requiredNominalPower),
                    subtitle: "Nennleistung, die bei diesem Betriebspunkt nötig wäre"
                )
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Mit dem gewählten Heizkörper", icon: "number")

                HStack(alignment: .firstTextBaseline) {
                    Text("Benötigte Stückzahl")
                    Spacer()
                    Text("\(radiatorCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.mint)
                }

                Text(String(format: "Ein Heizkörper mit %.0f W bei ΔT50 liefert am aktuellen Betriebspunkt rechnerisch %.0f W.", nominalPower, actualPower))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        formulaNotice
        shareCard
    }

    @ViewBuilder
    private var comparisonContent: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Grundlage", icon: "radiator")
                MetricField(title: "Nennleistung ΔT50", unit: "W", value: $nominalPower)
                MetricField(title: "Exponent n", unit: "", value: $exponent)

                Text("Vergleich desselben Heizkörpers bei typischen Temperaturpaaren. Für jeden Betriebspunkt wird die Temperaturdifferenz automatisch bewertet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

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

            SHKCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(regime.name + " °C")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.0f W", regimePower))
                            .font(.title3.bold())
                            .foregroundStyle(.mint)
                    }

                    resultRow("Übertemperatur", value: regimeEvaluation.deltaTK, unit: "K", digits: 2)
                    resultRow("Anteil Nennleistung", value: nominalPower > 0 ? regimePower / nominalPower * 100 : 0, unit: "%", digits: 0)
                    resultRow("Volumenstrom", value: regimeFlow, unit: "l/h", digits: 0)
                }
            }
        }

        formulaNotice
    }

    private var formulaNotice: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Berechnungsgrundlage", icon: "function")
                Text("Die Leistungsumrechnung folgt der üblichen Heizkörperbeziehung Φ = Φₙ · (ΔT / ΔTₙ)ⁿ. In Automatik wird bei stark asymmetrischen Temperaturen die logarithmische, sonst die arithmetische Übertemperatur verwendet.")
                    .foregroundStyle(.secondary)

                Text("Für Auswahl und Auslegung sind die Leistungsdaten und der Exponent n des Herstellers maßgebend.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shareCard: some View {
        SHKCard {
            ShareLink(item: shareText) {
                Label("Ergebnis teilen", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.mint)
        }
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }

    private func resultRow(_ title: String, value: Double, unit: String, digits: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(format(value, digits: digits)) \(unit)")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(.mint)
        }
    }

    private func format(_ value: Double, digits: Int = 1) -> String {
        String(format: "%.*f", digits, value)
    }
}
