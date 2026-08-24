import Foundation
import SwiftUI

enum LueftungsCalcMode: String, CaseIterable, Identifiable {
    case duct = "Kanal"
    case room = "Raum"
    case converter = "Umrechner"

    var id: String { rawValue }
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
                SHKBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        header

                        Picker("Bereich", selection: $mode) {
                            ForEach(LueftungsCalcMode.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch mode {
                        case .duct:
                            ductContent
                        case .room:
                            roomContent
                        case .converter:
                            converterContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("LüftungsCalc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: reportText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Berechnung teilen")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        SHKCard {
            HStack(spacing: 14) {
                Image(systemName: "wind")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.mint)
                    .frame(width: 54, height: 54)
                    .background(.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Luft richtig dimensionieren")
                        .font(.title2.bold())
                    Text("Volumenstrom, Kanal und Luftwechsel in einem Werkzeug.")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var ductContent: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Grunddaten", icon: "arrow.left.and.right")
                MetricField(title: "Volumenstrom", unit: "m³/h", value: $flow)
                MetricField(title: "Zielgeschwindigkeit", unit: "m/s", value: $targetVelocity)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Rundkanal", icon: "circle")

                HStack(alignment: .top, spacing: 18) {
                    BigResult(
                        title: "RECHNERISCHER Ø",
                        value: String(format: "%.0f mm", requiredRoundDiameter),
                        subtitle: "aus Volumenstrom und Zielgeschwindigkeit"
                    )

                    BigResult(
                        title: "NÄCHSTE GRÖSSE",
                        value: String(format: "%.0f mm", nextCommonDiameter),
                        subtitle: "gängige Rundabmessung"
                    )
                }

                Divider().opacity(0.4)

                MetricField(title: "Gewählter Ø", unit: "mm", value: $roundDiameter)
                resultRow("Geschwindigkeit", value: actualRoundVelocity, unit: "m/s", digits: 2)

                Text("Die vorgeschlagene Rundgröße ist eine Orientierung an gängigen Abmessungen. Das konkrete Kanalsystem des Herstellers bleibt maßgebend.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Rechteckkanal", icon: "rectangle")
                MetricField(title: "Breite", unit: "mm", value: $rectangularWidth)
                MetricField(title: "Höhe", unit: "mm", value: $rectangularHeight)

                Divider().opacity(0.4)

                resultRow("Ist-Geschwindigkeit", value: rectangularVelocity, unit: "m/s", digits: 2)
                resultRow("Äquivalenter Rund-Ø", value: equivalentRoundDiameter, unit: "mm", digits: 0)
                resultRow("Höhe bei Ziel-v", value: requiredRectangularHeight, unit: "mm", digits: 0)
            }
        }

        shareCard
    }

    @ViewBuilder
    private var roomContent: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Raum", icon: "house")
                MetricField(title: "Länge", unit: "m", value: $roomLength)
                MetricField(title: "Breite", unit: "m", value: $roomWidth)
                MetricField(title: "Höhe", unit: "m", value: $roomHeight)

                resultRow("Raumvolumen", value: roomVolume, unit: "m³", digits: 1)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Luftwechsel", icon: "arrow.triangle.2.circlepath")
                MetricField(title: "Ziel-Luftwechsel", unit: "1/h", value: $airChanges)

                BigResult(
                    title: "ERFORDERLICHE LUFTMENGE",
                    value: String(format: "%.0f m³/h", requiredRoomFlow),
                    subtitle: "Raumvolumen × Luftwechsel"
                )

                Divider().opacity(0.4)

                MetricField(title: "Tatsächliche Luftmenge", unit: "m³/h", value: $installedRoomFlow)
                resultRow("Tatsächlicher Luftwechsel", value: actualAirChanges, unit: "1/h", digits: 2)
            }
        }

        shareCard
    }

    @ViewBuilder
    private var converterContent: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Volumenstrom", icon: "arrow.left.arrow.right")
                MetricField(title: "m³/h", unit: "m³/h", value: $conversionFlow)
                resultRow("Liter pro Sekunde", value: VentilationCalculator.m3HToLitersPerSecond(conversionFlow), unit: "l/s", digits: 2)
                resultRow("CFM", value: VentilationCalculator.m3HToCFM(conversionFlow), unit: "cfm", digits: 1)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Merke", icon: "info.circle")
                Text("LüftungsCalc berechnet Geometrie und Luftmengen. Druckverlust, Ventilatorbetriebspunkt, Schall, Filterzustand sowie brandschutz- und normbezogene Anforderungen gehören zur vollständigen Auslegung weiterhin separat dazu.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shareCard: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Berechnung weitergeben", icon: "doc.text")
                ShareLink(item: reportText) {
                    Label("Ergebnis teilen", systemImage: "square.and.arrow.up")
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
