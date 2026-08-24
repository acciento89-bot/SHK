import Foundation
import SwiftUI

enum KalteCalcMode: String, CaseIterable, Identifiable {
    case circuit = "Kältekreis"
    case air = "Luft"
    case converter = "Umrechner"

    var id: String { rawValue }
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

    private var airDelta: Double {
        enteringAir - leavingAir
    }

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
                SHKBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        header

                        Picker("Bereich", selection: $mode) {
                            ForEach(KalteCalcMode.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch mode {
                        case .circuit:
                            circuitContent
                        case .air:
                            airContent
                        case .converter:
                            converterContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("KälteCalc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: serviceSummary) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Messwerte teilen")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        SHKCard {
            HStack(spacing: 14) {
                Image(systemName: "snowflake")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.mint)
                    .frame(width: 54, height: 54)
                    .background(.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Kälte-Service")
                        .font(.title2.bold())
                    Text("Messwerte rechnen statt überschlagen.")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var circuitContent: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Kältemittel", icon: "drop.degreesign")

                Picker("Kältemittel", selection: $refrigerant) {
                    ForEach(refrigerants, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
                .pickerStyle(.menu)

                Text("Die Auswahl wird aktuell im Servicebericht geführt. P/T-Sättigungswerte werden bewusst nicht geschätzt – die Sättigungstemperatur kommt aus Manometer, Hersteller- oder verifizierter P/T-Tabelle.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Niederdruckseite", icon: "arrow.down.right.circle")
                MetricField(title: "Verdampfung / Sättigung", unit: "°C", value: $evaporation)
                MetricField(title: "Sauggas", unit: "°C", value: $suction)
                MetricField(title: "Saugdruck", unit: "bar(g)", value: $suctionPressure)

                Divider().opacity(0.4)

                BigResult(
                    title: "ÜBERHITZUNG",
                    value: String(format: "%.1f K", superheat),
                    subtitle: superheat < 0
                        ? "Negativer Wert – Messpunkte bzw. Sättigungstemperatur prüfen."
                        : "Sauggastemperatur minus Verdampfung/Sättigung."
                )
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Hochdruckseite", icon: "arrow.up.right.circle")
                MetricField(title: "Kondensation / Sättigung", unit: "°C", value: $condensation)
                MetricField(title: "Flüssigkeitsleitung", unit: "°C", value: $liquid)
                MetricField(title: "Hochdruck", unit: "bar(g)", value: $dischargePressure)

                Divider().opacity(0.4)

                BigResult(
                    title: "UNTERKÜHLUNG",
                    value: String(format: "%.1f K", subcooling),
                    subtitle: subcooling < 0
                        ? "Negativer Wert – Messpunkte bzw. Sättigungstemperatur prüfen."
                        : "Kondensation/Sättigung minus Flüssigkeitsleitung."
                )
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Verdichter", icon: "gauge.with.dots.needle.50percent")
                BigResult(
                    title: "DRUCKVERHÄLTNIS",
                    value: pressureRatio > 0 ? String(format: "%.2f : 1", pressureRatio) : "–",
                    subtitle: "Berechnung aus Absolutdrücken; Eingabe bleibt bar(g)."
                )
            }
        }

        shareCard
    }

    @ViewBuilder
    private var airContent: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Luftseite", icon: "wind")
                MetricField(title: "Luftmenge", unit: "m³/h", value: $airFlow)
                MetricField(title: "Lufteintritt", unit: "°C", value: $enteringAir)
                MetricField(title: "Luftaustritt", unit: "°C", value: $leavingAir)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    BigResult(
                        title: "ΔT LUFT",
                        value: String(format: "%.1f K", airDelta),
                        subtitle: "Eintritt minus Austritt"
                    )

                    BigResult(
                        title: "SENSIBEL",
                        value: String(format: "%.2f kW", airCapacity),
                        subtitle: "Näherung aus Luftmenge und ΔT"
                    )
                }

                Text("Die luftseitige Leistung ist eine sensible Näherung. Latente Leistung/Entfeuchtung ist darin nicht enthalten.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        shareCard
    }

    @ViewBuilder
    private var converterContent: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Temperatur", icon: "thermometer.medium")
                MetricField(title: "Celsius", unit: "°C", value: $celsius)
                converterRow("Fahrenheit", value: RefrigerationCalculator.celsiusToFahrenheit(celsius), unit: "°F", digits: 1)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Druck", icon: "gauge.open.with.lines.needle.33percent")
                MetricField(title: "bar", unit: "bar", value: $bar)
                converterRow("psi", value: RefrigerationCalculator.barToPSI(bar), unit: "psi", digits: 2)
                converterRow("kPa", value: RefrigerationCalculator.barToKPa(bar), unit: "kPa", digits: 1)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Vakuum absolut", icon: "arrow.down.to.line.compact")
                MetricField(title: "mbar", unit: "mbar abs", value: $vacuumMbar)
                converterRow("Micron", value: RefrigerationCalculator.mbarToMicron(vacuumMbar), unit: "micron", digits: 0)
                converterRow("Pascal", value: RefrigerationCalculator.mbarToPascal(vacuumMbar), unit: "Pa", digits: 1)

                Text("Vakuumwerte sind Absolutdrücke. Nicht mit bar(g) aus dem Kältekreis verwechseln.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shareCard: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Servicebericht", icon: "doc.text")
                Text("Alle aktuellen Kältekreis- und Luftmesswerte als Text weitergeben oder in einen Arbeitsbericht übernehmen.")
                    .foregroundStyle(.secondary)

                ShareLink(item: serviceSummary) {
                    Label("Messwerte teilen", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
        }
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    private func converterRow(_ title: String, value: Double, unit: String, digits: Int) -> some View {
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
