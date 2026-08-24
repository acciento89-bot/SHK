import Foundation
import SwiftUI

enum RohrCalcMode: String, CaseIterable, Identifiable {
    case hydraulics = "Hydraulik"
    case sizing = "Dimension"
    case comparison = "Vergleich"

    var id: String { rawValue }
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
                SHKBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        header

                        Picker("Bereich", selection: $mode) {
                            ForEach(RohrCalcMode.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch mode {
                        case .hydraulics:
                            hydraulicsContent
                        case .sizing:
                            sizingContent
                        case .comparison:
                            comparisonContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("RohrCalc")
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
                Image(systemName: "arrow.left.arrow.right.circle")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.mint)
                    .frame(width: 54, height: 54)
                    .background(.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Rohrhydraulik im Kundendienst")
                        .font(.title2.bold())
                    Text("Geschwindigkeit, Druckverlust und Dimensionierung.")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    private var baseInputs: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Rohrstrecke", icon: "point.topleft.down.to.point.bottomright.curvepath")
                MetricField(title: "Volumenstrom", unit: "l/h", value: $flow)
                MetricField(title: "Innendurchmesser", unit: "mm", value: $diameter)
                MetricField(title: "Länge", unit: "m", value: $length)
                MetricField(title: "Rauheit ε", unit: "mm", value: $roughness)
                MetricField(title: "ζ-Summe", unit: "", value: $zetaTotal)

                Text("Die Rauheit ist ein Rechenwert für die Innenoberfläche. Bei unbekanntem Rohrzustand nicht künstlich exakt einstellen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var hydraulicsContent: some View {
        baseInputs

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 18) {
                    BigResult(
                        title: "GESCHWINDIGKEIT",
                        value: String(format: "%.2f m/s", result.base.velocityMS),
                        subtitle: "aus Volumenstrom und freiem Querschnitt"
                    )
                    BigResult(
                        title: "REYNOLDS",
                        value: String(format: "%.0f", result.reynoldsNumber),
                        subtitle: result.flowRegime.rawValue
                    )
                }

                Divider().opacity(0.4)

                resultRow("Rohrreibung", value: result.base.pressureDropPaPerM, unit: "Pa/m", digits: 0)
                resultRow("Rohrreibung", value: PipeCalculator.pascalPerMeterToMbarPerMeter(result.base.pressureDropPaPerM), unit: "mbar/m", digits: 2)
                resultRow("Verlust Rohrstrecke", value: result.base.totalPressureDropKPa, unit: "kPa", digits: 2)
                resultRow("Verlust Einzelwiderstände", value: result.localPressureLossKPa, unit: "kPa", digits: 2)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                BigResult(
                    title: "GESAMTDRUCKVERLUST",
                    value: String(format: "%.2f kPa", result.totalPressureLossIncludingLocalKPa),
                    subtitle: "Rohrreibung + ζ-Einzelwiderstände"
                )

                resultRow("Förderhöhe", value: result.totalHeadMeters, unit: "mWS", digits: 2)
                resultRow("Rohrinhalt", value: result.base.pipeVolumeL, unit: "l", digits: 2)
            }
        }

        mediumNotice
        shareCard
    }

    @ViewBuilder
    private var sizingContent: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Zielwert", icon: "scope")
                MetricField(title: "Volumenstrom", unit: "l/h", value: $flow)
                MetricField(title: "Zielgeschwindigkeit", unit: "m/s", value: $targetVelocity)

                BigResult(
                    title: "BENÖTIGTER INNENDURCHMESSER",
                    value: String(format: "%.1f mm", requiredDiameter),
                    subtitle: "rein aus Volumenstrom und Zielgeschwindigkeit"
                )
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Vorhandenes Rohr prüfen", icon: "checkmark.circle")
                MetricField(title: "Innendurchmesser", unit: "mm", value: $diameter)

                resultRow("Ist-Geschwindigkeit", value: result.base.velocityMS, unit: "m/s", digits: 2)
                resultRow("Max. Volumenstrom bei Ziel-v", value: maximumFlowAtTargetVelocity, unit: "l/h", digits: 0)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Wichtig", icon: "info.circle")
                Text("Der geometrisch benötigte Innendurchmesser ist noch keine fertige Rohrdimensionierung. Druckverlust, verfügbare Pumpenförderhöhe, Armaturen, Geräusch und Herstellerdimensionen müssen gemeinsam bewertet werden.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var comparisonContent: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Vergleichsgrundlage", icon: "list.bullet")
                MetricField(title: "Volumenstrom", unit: "l/h", value: $flow)
                MetricField(title: "Rohrlänge", unit: "m", value: $length)
                MetricField(title: "Rauheit ε", unit: "mm", value: $roughness)

                Text("Die Liste vergleicht freie Innendurchmesser – keine DN-/Außendurchmesser-Zuordnung. So werden unterschiedliche Rohrsysteme nicht miteinander vermischt.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        ForEach(comparisonDiameters, id: \.self) { candidate in
            let candidateResult = PipeCalculator.calculateExtended(
                volumeFlowLPH: flow,
                innerDiameterMM: candidate,
                lengthM: length,
                roughnessMM: roughness
            )

            SHKCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(String(format: "Ø innen %.0f mm", candidate))
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.2f m/s", candidateResult.base.velocityMS))
                            .font(.title3.bold())
                            .foregroundStyle(.mint)
                    }

                    resultRow("Druckverlust", value: candidateResult.base.pressureDropPaPerM, unit: "Pa/m", digits: 0)
                    resultRow("Gesamt Rohrstrecke", value: candidateResult.base.totalPressureDropKPa, unit: "kPa", digits: 2)
                    resultRow("Reynolds", value: candidateResult.reynoldsNumber, unit: candidateResult.flowRegime.rawValue, digits: 0)
                }
            }
        }

        mediumNotice
    }

    private var mediumNotice: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Rechenzustand", icon: "drop")
                Text("v1 rechnet mit Wasserkennwerten nahe 20 °C: ρ ≈ 998 kg/m³ und ν ≈ 1,004·10⁻⁶ m²/s. Bei heißem Wasser, Glykol oder anderen Medien ändern sich insbesondere Reynolds-Zahl und Druckverlust.")
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
