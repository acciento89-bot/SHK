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
                LabeledContent("Segment-Rohre", value: "\(state.segmentOwnedPipeCount)")
                LabeledContent("Zentrale Bauteile", value: "\(state.segmentOwnedComponentCount)")
                LabeledContent("Legacy verknüpft", value: "\(state.centralLinkedPipeCount)")
                LabeledContent("Legacy/manuell", value: "\(state.unlinkedLegacySharedPipeCount)")

                if !state.centralPipeModeActive {
                    Label("Zentraler Pfadmodus noch nicht aktiv. Gemeinsame Rohrgeometrie oder zentrale Bauteilverluste direkt in mindestens einem Netzsegment erfassen.", systemImage: "circle.dashed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if state.result == nil {
                    Label("Pfadberechnung unvollständig: Netzbaum, Fluidwerte, Verbraucher-Q, Rohrdaten oder zentrale Bauteile prüfen.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Label("Gemeinsame Rohre und zentrale Bauteilverluste werden je Netzsegment genau einmal in den betroffenen Verbraucherpfad gerechnet.", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            } header: {
                Text("Pfadmodus")
            } footer: {
                Text("Neue gemeinsame Rohrstrecken und zentrale Armaturen gehören direkt zum Netzsegment. Bereits vorhandene verknüpfte Alt-Rohre bleiben bis zur Migration rechenbar.")
            }

            if let result = state.result {
                Section {
                    ForEach(result.segments.indices, id: \.self) { index in
                        let segment = result.segments[index]
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
                                Text("Rohr \(segment.pipeSectionCount)")
                                Text("Bauteil \(segment.componentCount)")
                                if let flow = segment.designVolumeFlowLPH {
                                    Text("Q \(flow.formatted(.number.precision(.fractionLength(0...1)))) l/h")
                                } else {
                                    Text("Q offen")
                                        .foregroundStyle(.orange)
                                }
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                Text("Rohr Δp \(segment.knownPipePressureLossKPa.formatted(.number.precision(.fractionLength(0...3)))) kPa")
                                Text("Bauteil Δp \(segment.knownComponentPressureLossKPa.formatted(.number.precision(.fractionLength(0...3)))) kPa")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                            if segment.completePressureLossKPa == nil {
                                var reasons: [String] = []
                                if !segment.pressureCoverageComplete { reasons.append("Rohr/ζ unvollständig") }
                                if !segment.componentCoverageComplete { reasons.append("Bauteilaufnahme unvollständig") }
                                if segment.missingComponentCount > 0 { reasons.append("\(segment.missingComponentCount) Bauteil-Δp offen") }
                                if !reasons.isEmpty {
                                    Text(reasons.joined(separator: " · "))
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Zentrale Netzsegmente")
                } footer: {
                    Text("Ein Segment ohne eigene Rohre oder Bauteile fügt 0 kPa hinzu und dient nur als Verzweigung. Sobald reale gemeinsame Elemente erfasst sind, müssen ihre technischen Werte vollständig sein, bevor ein vollständiger Segment-Δp freigegeben wird.")
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
                    Text("Der vollständige Kreis-Δp ist die Summe aller zentralen Netzsegmente vom Wurzelstrang bis zum zugeordneten Segment plus der ausschließlich terminalen Heizflächen-Anbindung und ihrer terminalen Bauteilverluste.")
                }
            }

            if state.centralLinkedPipeCount > 0 || state.unlinkedLegacySharedPipeCount > 0 {
                Section {
                    if state.centralLinkedPipeCount > 0 {
                        Label("\(state.centralLinkedPipeCount) verknüpfte Altabschnitt(e) liegen noch unter Heizflächen. Sie werden weiterhin korrekt zentral gerechnet, können aber im Netzbaum in die Segmentgeometrie migriert werden.", systemImage: "arrow.right.circle")
                            .foregroundStyle(.orange)
                    }
                    if state.unlinkedLegacySharedPipeCount > 0 {
                        Label("\(state.unlinkedLegacySharedPipeCount) unverknüpfte Altabschnitt(e) werden im zentralen Pfadmodus nicht zusätzlich mitgezählt.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Legacy-Hinweis")
                } footer: {
                    Text("Neue gemeinsame Rohrgeometrie gehört direkt zum Netzsegment. Damit derselbe physische Strang nicht mehrfach gerechnet wird, müssen Altabschnitte fachlich geprüft, verknüpft und migriert oder entfernt werden.")
                }
            }
        }
        .navigationTitle("Netzpfade & Δp")
        .navigationBarTitleDisplayMode(.inline)
    }
}
