import SwiftUI

struct HeizBalanceProjectTechnicalStatusView: View {
    @Environment(HeizBalancePumpSelectionStore.self) private var pumpSelectionStore

    let project: HeizBalanceProject

    private var preview: HeizBalanceProjectPreviewState {
        project.heatLossPreviewSummary()
    }

    private var hydraulic: HeizBalanceHydraulicSystemPreparationCalculator.Result? {
        project.hydraulicSystemPreparationState().result
    }

    private var retrofitScenario: HeizBalanceTemperatureScenario? {
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

    private var retrofitSummary: HeizBalanceTemperatureScenarioSummary? {
        guard let retrofitScenario else { return nil }
        return project.temperatureScenarioSummary(retrofitScenario)
    }

    private var operatingPoint: (flowM3H: Double, headM: Double)? {
        guard let hydraulic,
              hydraulic.pumpOperatingPointReady,
              let flowLPH = hydraulic.designTotalVolumeFlowLPH,
              let headM = hydraulic.designNetworkHeadMeters else {
            return nil
        }
        return (flowLPH / 1_000, headM)
    }

    private var pumpSelection: HeizBalancePumpSelection? {
        pumpSelectionStore.selection(projectID: project.id)
    }

    private var pumpSelectionIsCurrent: Bool {
        guard let pumpSelection,
              let operatingPoint else {
            return false
        }
        return pumpSelection.matchesOperatingPoint(
            volumeFlowM3H: operatingPoint.flowM3H,
            requiredHeadM: operatingPoint.headM
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Projekt-Cockpit", systemImage: "gauge.with.dots.needle.67percent")
                .font(.headline)

            statusRow(
                title: "Raumdaten",
                detail: preview.rooms.isEmpty
                    ? "noch keine Räume"
                    : "\(preview.completeRoomCount)/\(preview.rooms.count) vollständig",
                state: preview.rooms.isEmpty ? .pending : (preview.allRoomsComplete ? .ready : .warning)
            )

            statusRow(
                title: "Niedertemperaturziel",
                detail: retrofitDetail,
                state: retrofitState
            )

            statusRow(
                title: "Hydraulik",
                detail: hydraulicDetail,
                state: operatingPoint == nil ? .warning : .ready
            )

            statusRow(
                title: "Pumpenentscheidung",
                detail: pumpDetail,
                state: pumpState
            )
        }
        .padding(.vertical, 4)
    }

    private var retrofitDetail: String {
        guard retrofitScenario != nil else { return "kein Sanierungsziel gespeichert" }
        guard let retrofitSummary else { return "nicht auswertbar" }
        if retrofitSummary.entries.isEmpty { return "noch keine Heizflächen" }
        if !retrofitSummary.complete {
            return "\(retrofitSummary.evaluableCount)/\(retrofitSummary.entries.count) Heizflächen auswertbar"
        }
        return retrofitSummary.allSufficient
            ? "Ziel technisch erreichbar"
            : "Upgradebedarf bei Heizflächen"
    }

    private var retrofitState: StatusState {
        guard retrofitScenario != nil else { return .pending }
        guard let retrofitSummary,
              !retrofitSummary.entries.isEmpty,
              retrofitSummary.complete else {
            return .warning
        }
        return retrofitSummary.allSufficient ? .ready : .warning
    }

    private var hydraulicDetail: String {
        guard let hydraulic else { return "noch nicht berechenbar" }
        if let operatingPoint {
            return operatingPoint.flowM3H.formatted(.number.precision(.fractionLength(0...3)))
                + " m³/h · "
                + operatingPoint.headM.formatted(.number.precision(.fractionLength(0...2)))
                + " m"
        }
        return "\(hydraulic.completePressureCircuitCount)/\(hydraulic.circuitCount) Kreis-Δp vollständig"
    }

    private var pumpDetail: String {
        guard let pumpSelection else { return "noch keine Auswahl festgehalten" }
        if pumpSelectionIsCurrent {
            return pumpSelection.displayName + " · aktuell"
        }
        return pumpSelection.displayName + " · neu bewerten"
    }

    private var pumpState: StatusState {
        guard pumpSelection != nil else { return .pending }
        return pumpSelectionIsCurrent ? .ready : .warning
    }

    @ViewBuilder
    private func statusRow(title: String, detail: String, state: StatusState) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: state.symbol)
                .foregroundStyle(state.color)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private enum StatusState {
        case ready
        case warning
        case pending

        var symbol: String {
            switch self {
            case .ready: "checkmark.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .pending: "circle.dashed"
            }
        }

        var color: Color {
            switch self {
            case .ready: .green
            case .warning: .orange
            case .pending: .secondary
            }
        }
    }
}
