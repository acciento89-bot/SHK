import SwiftUI

struct HeizBalanceRadiatorUpgradeContext: Identifiable {
    var id: UUID { surfaceID }
    var surfaceID: UUID
    var floorName: String
    var roomName: String
    var surfaceName: String
    var roomTemperatureC: Double
    var requiredPowerW: Double?
    var currentNominalPowerDeltaT50W: Double?
    var scenarioResult: HeizBalanceTemperatureScenarioCalculator.Result?
    var replacementSelection: HeizBalanceRadiatorReplacementSelection?
    var missingInputs: [String]

    var displayName: String {
        roomName + " · " + surfaceName
    }
}

extension HeizBalanceProject {
    func radiatorUpgradeContextsForStoredTarget() -> [HeizBalanceRadiatorUpgradeContext] {
        guard let flow = retrofitTargetFlowTemperatureC,
              let returnTemperature = retrofitTargetReturnTemperatureC,
              flow > returnTemperature else {
            return []
        }

        var contexts: [HeizBalanceRadiatorUpgradeContext] = []

        for floor in floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    var missing: [String] = []
                    if surface.nominalPowerDeltaT50W == nil { missing.append("Nennleistung ΔT50 fehlt") }
                    if surface.exponent == nil { missing.append("Exponent n fehlt") }
                    if surface.assignedRequiredPowerW == nil { missing.append("Zugeordnete erforderliche Leistung fehlt") }

                    let result: HeizBalanceTemperatureScenarioCalculator.Result?
                    if let nominalPower = surface.nominalPowerDeltaT50W,
                       let exponent = surface.exponent,
                       let requiredPower = surface.assignedRequiredPowerW {
                        result = HeizBalanceTemperatureScenarioCalculator.calculate(
                            .init(
                                nominalPowerDeltaT50W: nominalPower,
                                exponent: exponent,
                                requiredPowerW: requiredPower,
                                roomTemperatureC: room.targetTemperature,
                                flowTemperatureC: flow,
                                returnTemperatureC: returnTemperature
                            )
                        )
                        if result == nil && missing.isEmpty {
                            missing.append("Zieltemperaturen für diesen Raum nicht auswertbar")
                        }
                    } else {
                        result = nil
                    }

                    if result?.sufficient != true {
                        contexts.append(
                            .init(
                                surfaceID: surface.id,
                                floorName: floor.name,
                                roomName: room.name,
                                surfaceName: surface.name,
                                roomTemperatureC: room.targetTemperature,
                                requiredPowerW: surface.assignedRequiredPowerW,
                                currentNominalPowerDeltaT50W: surface.nominalPowerDeltaT50W,
                                scenarioResult: result,
                                replacementSelection: surface.replacementSelection,
                                missingInputs: missing
                            )
                        )
                    }
                }
            }
        }

        return contexts
    }
}

struct HeizBalanceRadiatorUpgradeMatchView: View {
    @Environment(HeizBalanceRadiatorDatasetStore.self) private var datasetStore
    @Binding var project: HeizBalanceProject

    private var targetTemperatureText: String? {
        guard let flow = project.retrofitTargetFlowTemperatureC,
              let returnTemperature = project.retrofitTargetReturnTemperatureC,
              flow > returnTemperature else {
            return nil
        }
        return flow.formatted(.number.precision(.fractionLength(0...1)))
            + " / "
            + returnTemperature.formatted(.number.precision(.fractionLength(0...1)))
            + " °C"
    }

    private var contexts: [HeizBalanceRadiatorUpgradeContext] {
        project.radiatorUpgradeContextsForStoredTarget()
    }

    var body: some View {
        List {
            Section {
                if let targetTemperatureText {
                    LabeledContent("Sanierungsziel", value: targetTemperatureText)
                    LabeledContent("Kataloge", value: "\(datasetStore.datasets.count)")
                    LabeledContent("Katalogprodukte", value: "\(datasetStore.datasets.reduce(0) { $0 + $1.products.count })")
                } else {
                    Label("Noch kein gültiges Sanierungsziel gespeichert.", systemImage: "target")
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    HeizBalanceRadiatorDatasetManager()
                } label: {
                    Label("Heizkörperdaten verwalten", systemImage: "shippingbox")
                }
            } header: {
                Text("Produktdaten")
            } footer: {
                Text("Es werden ausschließlich importierte Datensätze verwendet. HeizBalance erfindet keine Hersteller, Typen oder Leistungswerte.")
            }

            if targetTemperatureText != nil {
                Section {
                    if contexts.isEmpty {
                        Label("Kein Upgradebedarf aus den aktuell vollständig auswertbaren Heizflächen erkannt.", systemImage: "checkmark.circle")
                    } else {
                        ForEach(contexts) { context in
                            if let result = context.scenarioResult,
                               let requiredPower = context.requiredPowerW,
                               let flow = project.retrofitTargetFlowTemperatureC,
                               let returnTemperature = project.retrofitTargetReturnTemperatureC {
                                NavigationLink {
                                    HeizBalanceRadiatorCandidateMatchDetailView(
                                        project: $project,
                                        context: context,
                                        requiredPowerW: requiredPower,
                                        flowTemperatureC: flow,
                                        returnTemperatureC: returnTemperature
                                    )
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(context.displayName)
                                            .font(.headline)
                                        Text(context.floorName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(
                                            "Deckung "
                                                + (result.capacityRatio * 100).formatted(.number.precision(.fractionLength(0)))
                                                + " % · benötigt ΔT50 "
                                                + result.requiredNominalPowerDeltaT50W.formatted(.number.precision(.fractionLength(0)))
                                                + " W"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.orange)

                                        if let selection = context.replacementSelection {
                                            Label(
                                                "Auswahl festgehalten: " + selection.displayName,
                                                systemImage: "bookmark.fill"
                                            )
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                        }
                                    }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(context.displayName)
                                        .font(.headline)
                                    Text("Daten unvollständig")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                    ForEach(context.missingInputs, id: \.self) { missing in
                                        Text("• " + missing)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                } header: {
                    Text("Upgradebedarf")
                } footer: {
                    Text("Eine Kandidatenliste bedeutet nur, dass dokumentierte Leistung und optionale Abmessungsfilter rechnerisch passen. Eine festgehaltene Auswahl ist eine Benutzerentscheidung, keine automatische Produktempfehlung oder Montagefreigabe.")
                }
            }
        }
        .navigationTitle("Heizkörper-Upgrade")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HeizBalanceRadiatorCandidateMatchDetailView: View {
    @Environment(HeizBalanceRadiatorDatasetStore.self) private var datasetStore

    @Binding var project: HeizBalanceProject
    let context: HeizBalanceRadiatorUpgradeContext
    let requiredPowerW: Double
    let flowTemperatureC: Double
    let returnTemperatureC: Double

    @State private var maximumWidthMM: Double?
    @State private var maximumHeightMM: Double?
    @State private var maximumDepthMM: Double?

    private var currentSelection: HeizBalanceRadiatorReplacementSelection? {
        project.radiatorReplacementSelection(surfaceID: context.surfaceID)
    }

    private var matchResult: HeizBalanceRadiatorProductMatchingCalculator.Result? {
        let candidates = datasetStore.datasets.flatMap { dataset in
            dataset.products.map { $0.matchingCandidate(datasetID: dataset.id) }
        }

        return HeizBalanceRadiatorProductMatchingCalculator.calculate(
            .init(
                requiredPowerW: requiredPowerW,
                roomTemperatureC: context.roomTemperatureC,
                flowTemperatureC: flowTemperatureC,
                returnTemperatureC: returnTemperatureC,
                candidates: candidates,
                constraints: .init(
                    maximumWidthMM: maximumWidthMM,
                    maximumHeightMM: maximumHeightMM,
                    maximumDepthMM: maximumDepthMM
                )
            )
        )
    }

    var body: some View {
        List {
            Section("Anforderung") {
                LabeledContent("Raum / Heizfläche", value: context.displayName)
                LabeledContent("Zieltemperaturen") {
                    Text(
                        flowTemperatureC.formatted(.number.precision(.fractionLength(0...1)))
                            + " / "
                            + returnTemperatureC.formatted(.number.precision(.fractionLength(0...1)))
                            + " °C"
                    )
                }
                LabeledContent("Erforderliche Raumleistung") {
                    Text(requiredPowerW.formatted(.number.precision(.fractionLength(0))) + " W")
                }
                if let requiredNominal = context.scenarioResult?.requiredNominalPowerDeltaT50W {
                    LabeledContent("Mindestens ΔT50") {
                        Text(requiredNominal.formatted(.number.precision(.fractionLength(0))) + " W")
                            .fontWeight(.semibold)
                    }
                }
            }

            if let selection = currentSelection {
                Section {
                    Label(selection.displayName, systemImage: "bookmark.fill")
                        .font(.headline)
                    LabeledContent("Datensatz") {
                        Text(selection.datasetName + " · " + selection.datasetVersion)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Bei Auswahl bewertet") {
                        Text(
                            selection.targetFlowTemperatureC.formatted(.number.precision(.fractionLength(0...1)))
                                + " / "
                                + selection.targetReturnTemperatureC.formatted(.number.precision(.fractionLength(0...1)))
                                + " °C"
                        )
                    }
                    LabeledContent("Leistung am Ziel") {
                        Text(selection.availablePowerW.formatted(.number.precision(.fractionLength(0))) + " W")
                    }
                    LabeledContent("Deckungsgrad") {
                        Text((selection.capacityRatio * 100).formatted(.number.precision(.fractionLength(0))) + " %")
                    }
                    Text("Quelle: " + selection.sourceReference)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(role: .destructive) {
                        project.setRadiatorReplacementSelection(nil, surfaceID: context.surfaceID)
                    } label: {
                        Label("Festgehaltene Auswahl löschen", systemImage: "bookmark.slash")
                    }
                } header: {
                    Text("Festgehaltene Auswahl")
                } footer: {
                    Text("Der Snapshot bleibt unabhängig vom aktuell importierten Katalog nachvollziehbar. Eine spätere Änderung des Katalogs überschreibt diese Auswahl nicht.")
                }
            }

            Section {
                OptionalDecimalField(title: "Max. Breite", value: $maximumWidthMM, unit: "mm")
                OptionalDecimalField(title: "Max. Höhe", value: $maximumHeightMM, unit: "mm")
                OptionalDecimalField(title: "Max. Tiefe", value: $maximumDepthMM, unit: "mm")
            } header: {
                Text("Einbauraum optional")
            } footer: {
                Text("Wird ein Maß begrenzt, werden Produkte ohne dokumentiertes entsprechendes Maß ebenfalls ausgeschlossen.")
            }

            Section {
                if datasetStore.datasets.isEmpty {
                    Text("Keine Heizkörperdatensätze importiert.")
                        .foregroundStyle(.secondary)
                } else if let matchResult {
                    LabeledContent("Ausgewertet", value: "\(matchResult.evaluatedCandidateCount)")
                    LabeledContent("Wegen Abmessungen ausgeschlossen", value: "\(matchResult.dimensionRejectedCandidateCount)")
                    LabeledContent("Ungültige Produkte übersprungen", value: "\(matchResult.invalidCandidateCount)")
                    LabeledContent("Leistung ausreichend", value: "\(matchResult.sufficientCandidates.count)")
                }
            } header: {
                Text("Abdeckung")
            }

            Section {
                if let result = matchResult {
                    if result.sufficientCandidates.isEmpty {
                        ContentUnavailableView(
                            "Kein passender Katalogkandidat",
                            systemImage: "magnifyingglass",
                            description: Text("In den importierten Datensätzen erfüllt aktuell kein Produkt Leistung und gesetzte Abmessungsgrenzen.")
                        )
                    } else {
                        ForEach(result.sufficientCandidates) { candidate in
                            if let resolved = datasetStore.product(compositeID: candidate.candidateID) {
                                HeizBalanceRadiatorCandidateRow(
                                    dataset: resolved.dataset,
                                    product: resolved.product,
                                    result: candidate,
                                    isSelected: currentSelection?.datasetID == resolved.dataset.id
                                        && currentSelection?.productID == resolved.product.id
                                ) {
                                    holdSelection(
                                        dataset: resolved.dataset,
                                        product: resolved.product,
                                        result: candidate
                                    )
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Technisch passende Kandidaten")
            } footer: {
                Text("Sortierung: ausreichende Leistung mit kleinster rechnerischer Leistungsreserve zuerst. Nur ein ausdrücklicher Tap auf „Auswahl festhalten“ speichert einen Kandidaten; daraus entsteht keine automatische Produktempfehlung oder Montagefreigabe.")
            }
        }
        .navigationTitle(context.surfaceName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func holdSelection(
        dataset: HeizBalanceRadiatorProductDataset,
        product: HeizBalanceRadiatorProductDataset.Product,
        result: HeizBalanceRadiatorProductMatchingCalculator.CandidateResult
    ) {
        let selection = HeizBalanceRadiatorReplacementSelection(
            targetFlowTemperatureC: flowTemperatureC,
            targetReturnTemperatureC: returnTemperatureC,
            roomTemperatureC: context.roomTemperatureC,
            requiredPowerW: requiredPowerW,
            availablePowerW: result.availablePowerW,
            capacityRatio: result.capacityRatio,
            dataset: dataset,
            product: product
        )
        project.setRadiatorReplacementSelection(selection, surfaceID: context.surfaceID)
    }
}

private struct HeizBalanceRadiatorCandidateRow: View {
    let dataset: HeizBalanceRadiatorProductDataset
    let product: HeizBalanceRadiatorProductDataset.Product
    let result: HeizBalanceRadiatorProductMatchingCalculator.CandidateResult
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(dataset.manufacturer + " · " + product.displayName)
                    .font(.headline)
                if isSelected {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(Color.green)
                }
            }

            Text(dataset.datasetName + " · " + dataset.datasetVersion)
                .font(.caption)
                .foregroundStyle(.secondary)

            LabeledContent("Nennleistung ΔT50") {
                Text(product.nominalPowerDeltaT50W.formatted(.number.precision(.fractionLength(0))) + " W")
            }
            .font(.caption)

            LabeledContent("Leistung am Ziel") {
                Text(result.availablePowerW.formatted(.number.precision(.fractionLength(0))) + " W")
            }
            .font(.caption)

            LabeledContent("Deckungsgrad") {
                Text((result.capacityRatio * 100).formatted(.number.precision(.fractionLength(0))) + " %")
            }
            .font(.caption)

            LabeledContent("Reserve") {
                Text(result.reservePowerW.formatted(.number.precision(.fractionLength(0))) + " W")
            }
            .font(.caption)

            let dimensions = candidateDimensionText(product)
            if !dimensions.isEmpty {
                Text(dimensions)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text("Quelle: " + dataset.source.reference)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button {
                onSelect()
            } label: {
                Label(
                    isSelected ? "Auswahl erneut festhalten" : "Auswahl festhalten",
                    systemImage: isSelected ? "bookmark.fill" : "bookmark"
                )
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }

    private func candidateDimensionText(_ product: HeizBalanceRadiatorProductDataset.Product) -> String {
        var parts: [String] = []
        if let width = product.widthMM { parts.append("B \(width.formatted(.number.precision(.fractionLength(0)))) mm") }
        if let height = product.heightMM { parts.append("H \(height.formatted(.number.precision(.fractionLength(0)))) mm") }
        if let depth = product.depthMM { parts.append("T \(depth.formatted(.number.precision(.fractionLength(0)))) mm") }
        return parts.joined(separator: " · ")
    }
}
