import SwiftUI

struct HeizBalanceRetrofitTargetDashboardView: View {
    let project: HeizBalanceProject

    private var scenario: HeizBalanceTemperatureScenario? {
        guard let flow = project.retrofitTargetFlowTemperatureC,
              let returnTemperature = project.retrofitTargetReturnTemperatureC,
              flow > returnTemperature else {
            return nil
        }
        return .init(
            title: "Sanierungsziel",
            flowTemperatureC: flow,
            returnTemperatureC: returnTemperature
        )
    }

    private var summary: HeizBalanceTemperatureScenarioSummary? {
        guard let scenario else { return nil }
        return project.temperatureScenarioSummary(scenario)
    }

    var body: some View {
        if let scenario, let summary {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Sanierungsziel", systemImage: "target")
                    Spacer()
                    Text(scenario.displayTemperature)
                        .fontWeight(.semibold)
                }

                if summary.entries.isEmpty {
                    Label("Noch keine Heizflächen zur Bewertung vorhanden.", systemImage: "circle.dashed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !summary.complete {
                    Label(
                        "Daten unvollständig · \(summary.evaluableCount)/\(summary.entries.count) Heizflächen auswertbar",
                        systemImage: "lock.trianglebadge.exclamationmark"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else if summary.allSufficient {
                    Label("Ziel erreichbar · alle Heizflächen ausreichend", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.green)
                } else {
                    Label(
                        "Upgradebedarf · \(summary.sufficientCount)/\(summary.entries.count) Heizflächen ausreichend",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.orange)

                    if let limiting = summary.limitingEntry,
                       let result = limiting.result {
                        Text("Begrenzend: \(limiting.displayName)")
                            .font(.caption)

                        Text(
                            "Benötigt mindestens "
                                + result.requiredNominalPowerDeltaT50W.formatted(.number.precision(.fractionLength(0)))
                                + " W ΔT50 · Faktor ×"
                                + result.nominalPowerFactor.formatted(.number.precision(.fractionLength(2)))
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if let source = project.retrofitTargetTemperatureSource {
                    Text("Quelle: \(source.title)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 3)
        }
    }
}
