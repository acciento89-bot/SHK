import SwiftUI

private enum HeizBalancePumpComparisonFilter: String, CaseIterable, Identifiable {
    case all
    case sufficient
    case insufficient
    case outsideRange

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Alle"
        case .sufficient: "Ausreichend"
        case .insufficient: "Zu wenig"
        case .outsideRange: "Außerhalb"
        }
    }
}

struct HeizBalancePumpProjectWorkspaceView: View {
    @Environment(HeizBalancePumpDatasetStore.self) private var datasetStore
    @Environment(HeizBalancePumpSelectionStore.self) private var selectionStore
    @State private var filter: HeizBalancePumpComparisonFilter = .all

    let project: HeizBalanceProject

    private var hydraulicResult: HeizBalanceHydraulicSystemPreparationCalculator.Result? {
        project.hydraulicSystemPreparationState().result
    }

    private var operatingPoint: (flowM3H: Double, headM: Double)? {
        guard let result = hydraulicResult,
              result.pumpOperatingPointReady,
              let flowLPH = result.designTotalVolumeFlowLPH,
              let headM = result.designNetworkHeadMeters else {
            return nil
        }
        return (flowLPH / 1_000, headM)
    }

    private var comparison: HeizBalancePumpCurveComparisonCalculator.Summary? {
        guard let operatingPoint else { return nil }
        return HeizBalancePumpCurveComparisonCalculator.calculate(
            datasets: datasetStore.datasets,
            targetVolumeFlowM3H: operatingPoint.flowM3H,
            requiredHeadM: operatingPoint.headM
        )
    }

    private var filteredEntries: [HeizBalancePumpCurveComparisonCalculator.Entry] {
        guard let comparison else { return [] }
        switch filter {
        case .all:
            return comparison.entries
        case .sufficient:
            return comparison.entries.filter { $0.status == .technicallySufficient }
        case .insufficient:
            return comparison.entries.filter { $0.status == .insufficientHead }
        case .outsideRange:
            return comparison.entries.filter { $0.status == .outsideDocumentedRange }
        }
    }

    private var heldSelection: HeizBalancePumpSelection? {
        selectionStore.selection(projectID: project.id)
    }

    private var heldSelectionIsCurrent: Bool {
        guard let selection = heldSelection,
              let operatingPoint else {
            return false
        }
        return selection.matchesOperatingPoint(
            volumeFlowM3H: operatingPoint.flowM3H,
            requiredHeadM: operatingPoint.headM
        )
    }

    var body: some View {
        List {
            operatingPointSection
            heldSelectionSection
            comparisonSection

            Section {
                NavigationLink {
                    HeizBalancePumpDatasetManager(project: project)
                } label: {
                    Label("Pumpenkataloge, Import & Kennliniendetails", systemImage: "shippingbox")
                }

                NavigationLink {
                    HeizBalanceProjectPreviewView(project: project)
                } label: {
                    Label("Hydraulikkreise und Druckverluste prüfen", systemImage: "point.3.connected.trianglepath.dotted")
                }
            } header: {
                Text("Werkzeuge")
            }
        }
        .navigationTitle("Pumpe & Betriebspunkt")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var operatingPointSection: some View {
        Section {
            if let operatingPoint {
                LabeledContent("Auslegungs-Volumenstrom") {
                    Text(operatingPoint.flowM3H.formatted(.number.precision(.fractionLength(0...3))) + " m³/h")
                        .fontWeight(.semibold)
                }
                LabeledContent("Erforderliche Förderhöhe") {
                    Text(operatingPoint.headM.formatted(.number.precision(.fractionLength(0...2))) + " m")
                        .fontWeight(.semibold)
                }

                if let density = project.hydraulicFluidDensityKGPerM3,
                   let metrics = HeizBalancePumpTechnicalMetricsCalculator.calculate(
                        .init(
                            volumeFlowM3H: operatingPoint.flowM3H,
                            requiredHeadM: operatingPoint.headM,
                            availableHeadM: operatingPoint.headM,
                            fluidDensityKGPerM3: density,
                            electricalInputPowerW: nil,
                            documentedMinimumFlowM3H: nil,
                            documentedMaximumFlowM3H: nil
                        )
                   ) {
                    LabeledContent("Hydraulischer Leistungsbedarf") {
                        Text(metrics.requiredHydraulicPowerW.formatted(.number.precision(.fractionLength(0...1))) + " W")
                    }
                    Text("Aus Volumenstrom, Förderhöhe und expliziter Projektdichte berechnet.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("Der Pumpen-Betriebspunkt ist noch nicht vollständig.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Alle Verbraucherströme und vollständigen Kreis-Druckverluste müssen vorliegen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Projekt-Betriebspunkt")
        } footer: {
            Text("Technische Projektvorbereitung. Keine automatische Pumpenauslegung, Regelart- oder Herstellerfreigabe.")
        }
    }

    @ViewBuilder
    private var heldSelectionSection: some View {
        Section {
            if let selection = heldSelection {
                VStack(alignment: .leading, spacing: 5) {
                    Label(selection.displayName, systemImage: heldSelectionIsCurrent ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(heldSelectionIsCurrent ? Color.primary : Color.orange)
                    Text(selection.curveLabel)
                        .font(.subheadline)
                    Text(selection.datasetName + " · " + selection.datasetVersion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Reserve bei Auswahl") {
                    Text(selection.headReserveM.formatted(.number.precision(.fractionLength(0...2))) + " m")
                }
                if let power = selection.electricalInputPowerW {
                    LabeledContent("Dokumentierte elektrische Aufnahme") {
                        Text(power.formatted(.number.precision(.fractionLength(0...1))) + " W")
                    }
                }

                if heldSelectionIsCurrent {
                    Label("Auswahl passt zum aktuellen Projekt-Betriebspunkt.", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else {
                    Label("Betriebspunkt geändert oder unvollständig – Auswahl neu bewerten.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }

                Button(role: .destructive) {
                    selectionStore.delete(projectID: project.id)
                } label: {
                    Label("Festgehaltene Auswahl entfernen", systemImage: "trash")
                }
            } else {
                Label("Noch keine Pumpe/Kennlinie ausdrücklich festgehalten.", systemImage: "circle.dashed")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Projektentscheidung")
        } footer: {
            Text("Eine Auswahl wird ausschließlich durch einen Benutzer-Tap gespeichert und ist keine automatische Empfehlung.")
        }
    }

    @ViewBuilder
    private var comparisonSection: some View {
        Section {
            if datasetStore.datasets.isEmpty {
                ContentUnavailableView(
                    "Keine Pumpendaten",
                    systemImage: "arrow.triangle.2.circlepath",
                    description: Text("Importiere zuerst dokumentierte Pumpen-Produktdaten.")
                )
            } else if let comparison {
                LabeledContent("Kennlinien gesamt", value: "\(comparison.totalCurveCount)")
                LabeledContent("Technisch auswertbar", value: "\(comparison.evaluableCount)")
                LabeledContent("Förderhöhe ausreichend", value: "\(comparison.technicallySufficientCount)")
                LabeledContent("Förderhöhe zu gering", value: "\(comparison.insufficientHeadCount)")
                LabeledContent("Außerhalb Datenbereich", value: "\(comparison.outsideDocumentedRangeCount)")

                Picker("Filter", selection: $filter) {
                    ForEach(HeizBalancePumpComparisonFilter.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                if filteredEntries.isEmpty {
                    Text("Für diesen Filter gibt es keine Kennlinien.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredEntries) { entry in
                        comparisonRow(entry)
                    }
                }
            } else {
                Label("Kennlinienvergleich wartet auf einen vollständigen Projekt-Betriebspunkt.", systemImage: "lock")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Direkter Kennlinienvergleich")
        } footer: {
            Text("Ausreichende Kennlinien werden zuerst gruppiert und innerhalb der Gruppen nur alphabetisch sortiert. Die Reihenfolge ist ausdrücklich keine Produktempfehlung. Außerhalb dokumentierter Volumenstrombereiche wird nicht extrapoliert.")
        }
    }

    @ViewBuilder
    private func comparisonRow(_ entry: HeizBalancePumpCurveComparisonCalculator.Entry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.manufacturer + " · " + entry.productDisplayName)
                        .font(.subheadline.weight(.semibold))
                    Text(entry.curveLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let controlMode = entry.controlMode, !controlMode.isEmpty {
                        Text(controlMode)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                statusLabel(entry.status)
            }

            if let availableHead = entry.availableHeadM,
               let reserve = entry.headReserveM {
                HStack(spacing: 12) {
                    Text("H: \(availableHead.formatted(.number.precision(.fractionLength(0...2)))) m")
                    Text("Reserve: \(reserve.formatted(.number.precision(.fractionLength(0...2)))) m")
                    if let power = entry.electricalInputPowerW {
                        Text("P₁: \(power.formatted(.number.precision(.fractionLength(0...1)))) W")
                    }
                }
                .font(.caption.monospacedDigit())

                if let metrics = technicalMetrics(entry) {
                    HStack(spacing: 12) {
                        Text("Pₕ,erf: \(metrics.requiredHydraulicPowerW.formatted(.number.precision(.fractionLength(0...1)))) W")
                        if let reservePercent = metrics.headReservePercent {
                            Text("H-Reserve: \(reservePercent.formatted(.number.precision(.fractionLength(0...1)))) %")
                        }
                        if let ratio = metrics.requiredHydraulicToElectricalRatio {
                            Text("Pₕ,erf/P₁: \((ratio * 100).formatted(.number.precision(.fractionLength(0...1)))) %")
                        }
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
            }

            if entry.status == .technicallySufficient {
                Button {
                    hold(entry)
                } label: {
                    Label(
                        isHeld(entry) ? "Festgehalten" : "Diese Pumpe/Kennlinie festhalten",
                        systemImage: isHeld(entry) ? "checkmark.seal.fill" : "checkmark.seal"
                    )
                }
                .buttonStyle(.borderless)
                .disabled(isHeld(entry) && heldSelectionIsCurrent)
            }
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private func statusLabel(_ status: HeizBalancePumpCurveComparisonCalculator.Status) -> some View {
        switch status {
        case .technicallySufficient:
            Label("ausreichend", systemImage: "checkmark.circle.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.green)
        case .insufficientHead:
            Label("zu gering", systemImage: "xmark.circle.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.orange)
        case .outsideDocumentedRange:
            Label("außerhalb", systemImage: "arrow.left.and.right.circle")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.orange)
        }
    }

    private func isHeld(_ entry: HeizBalancePumpCurveComparisonCalculator.Entry) -> Bool {
        guard let selection = heldSelection else { return false }
        return selection.datasetID == entry.datasetID
            && selection.productID == entry.productID
            && selection.curveID == entry.curveID
    }

    private func hold(_ entry: HeizBalancePumpCurveComparisonCalculator.Entry) {
        guard entry.status == .technicallySufficient,
              let operatingPoint,
              let dataset = datasetStore.datasets.first(where: { $0.id == entry.datasetID }),
              let product = dataset.products.first(where: { $0.id == entry.productID }),
              let curve = product.curves.first(where: { $0.id == entry.curveID }),
              let evaluation = HeizBalancePumpCurveOperatingPointCalculator.calculate(
                .init(
                    targetVolumeFlowM3H: operatingPoint.flowM3H,
                    requiredHeadM: operatingPoint.headM,
                    points: curve.points
                )
              ),
              evaluation.technicallySufficient else {
            return
        }

        selectionStore.save(
            HeizBalancePumpSelection(
                projectID: project.id,
                dataset: dataset,
                product: product,
                curve: curve,
                evaluation: evaluation
            )
        )
    }

    private func technicalMetrics(
        _ entry: HeizBalancePumpCurveComparisonCalculator.Entry
    ) -> HeizBalancePumpTechnicalMetricsCalculator.Result? {
        guard let operatingPoint,
              let density = project.hydraulicFluidDensityKGPerM3,
              let availableHeadM = entry.availableHeadM else {
            return nil
        }

        return HeizBalancePumpTechnicalMetricsCalculator.calculate(
            .init(
                volumeFlowM3H: operatingPoint.flowM3H,
                requiredHeadM: operatingPoint.headM,
                availableHeadM: availableHeadM,
                fluidDensityKGPerM3: density,
                electricalInputPowerW: entry.electricalInputPowerW,
                documentedMinimumFlowM3H: entry.documentedMinimumFlowM3H,
                documentedMaximumFlowM3H: entry.documentedMaximumFlowM3H
            )
        )
    }
}
