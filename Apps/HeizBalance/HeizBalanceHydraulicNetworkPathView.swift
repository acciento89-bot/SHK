import SwiftUI

struct HeizBalanceHydraulicNetworkPathView: View {
    let project: HeizBalanceProject

    private var state: HeizBalanceHydraulicNetworkPathProjectState {
        project.hydraulicNetworkPathState()
    }

    private var segmentNames: [String: String] {
        Dictionary(uniqueKeysWithValues: (project.hydraulicNetwork?.segments ?? []).map { ($0.id.uuidString, $0.name) })
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Rechenprofil", value: HeizBalanceHydraulicNetworkPathCalculator.profileVersion)
                LabeledContent("Zentrale Shared-Rohre", value: "\(state.centralLinkedPipeCount)")
                LabeledContent("Legacy/manuell", value: "\(state.unlinkedLegacySharedPipeCount)")

                if !state.centralPipeModeActive {
                    Label("Zentraler Pfadmodus noch nicht aktiv. Mindestens einen gemeinsamen Rohrabschnitt mit einem Netzsegment verknüpfen.", systemImage: "circle.dashed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if state.result == nil {
                    Label("Pfadberechnung unvollständig: Netzbaum, Fluidwerte, Verbraucher-Q oder Rohrdaten prüfen.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Label("Gemeinsame Rohrabschnitte werden zentral je Netzsegment und nicht pro Heizfläche gerechnet.", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            } header: {
                Text("Pfadmodus")
            }

            if let result = state.result {
                Section {
                    ForEach(result.segments, id: \.id) { segment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(segment.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                if let complete = segment.completePressureLossKPa {
                                    Text("Δp \(complete.formatted(.number.precision(.fractionLength(0...3)))) kPa")
                                        .font(.caption.monospacedDigit())
                                } else {
                                    Text("Δp offen")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                            HStack(spacing: 12) {
                                Text("\(segment.pipeSectionCount) Abschnitt(e)")
                                if let flow = segment.designVolumeFlowLPH {
                                    Text("Q \(flow.formatted(.number.precision(.fractionLength(0...1)))) l/h")
                                } else {
                                    Text("Q offen")
                                        .foregroundStyle(.orange)
                                }
                                if segment.completePressureLossKPa == nil,
                                   segment.knownPressureLossKPa > 0 {
                                    Text("bekannt \(segment.knownPressureLossKPa.formatted(.number.precision(.fractionLength(0...3)))) kPa")
                                }
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Zentrale Netzsegmente")
                } footer: {
                    Text("Ein Segment ohne eigene Rohrabschnitte fügt 0 kPa hinzu und dient nur als Verzweigung. Sobald Rohrabschnitte erfasst sind, müssen Innendurchmesser, Länge, Rauheit, Segment-Q und ζ vollständig sein, bevor ein vollständiger Segment-Δp freigegeben wird.")
                }

                Section {
                    ForEach(result.consumers, id: \.id) { consumer in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(consumer.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                if let complete = consumer.completePathPressureLossKPa {
                                    Text("\(complete.formatted(.number.precision(.fractionLength(0...3)))) kPa")
                                        .font(.caption.monospacedDigit().weight(.semibold))
                                } else {
                                    Text("unvollständig")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }

                            if !consumer.pathSegmentIDs.isEmpty {
                                Text(consumer.pathSegmentIDs.map { segmentNames[$0] ?? $0 }.joined(separator: " → "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Keinem Netzsegment zugeordnet")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }

                            HStack(spacing: 12) {
                                Text("Shared \(consumer.knownSharedPressureLossKPa.formatted(.number.precision(.fractionLength(0...3)))) kPa")
                                Text("Terminal \(consumer.terminalKnownPressureLossKPa.formatted(.number.precision(.fractionLength(0...3)))) kPa")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Verbraucherpfade")
                } footer: {
                    Text("Der vollständige Kreis-Δp ist die Summe aller zentralen Netzsegmente vom Wurzelstrang bis zum zugeordneten Segment plus der ausschließlich terminalen Heizflächen-Anbindung und der erfassten Bauteilverluste.")
                }
            }

            if state.centralPipeModeActive && state.unlinkedLegacySharedPipeCount > 0 {
                Section {
                    Label("\(state.unlinkedLegacySharedPipeCount) gemeinsame Rohrabschnitt(e) sind nicht mit dem Netzbaum verknüpft und werden im zentralen Pfadmodus nicht zusätzlich mitgezählt.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                } header: {
                    Text("Legacy-Hinweis")
                } footer: {
                    Text("Damit derselbe physische Strang nicht mehrfach gerechnet wird, zählen im zentralen Pfadmodus ausschließlich Shared-Rohre mit Netzsegment-Verknüpfung. Nicht verknüpfte Altabschnitte bleiben im Projekt erhalten, müssen aber fachlich geprüft oder entfernt werden.")
                }
            }
        }
        .navigationTitle("Netzpfade & Δp")
        .navigationBarTitleDisplayMode(.inline)
    }
}
