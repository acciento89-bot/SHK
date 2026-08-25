import SwiftUI
import UniformTypeIdentifiers

private struct HeizBalancePumpOperatingPointContext: Hashable {
    var volumeFlowM3H: Double
    var requiredHeadM: Double
}

struct HeizBalancePumpDatasetManager: View {
    @Environment(HeizBalancePumpDatasetStore.self) private var store
    @Environment(HeizBalancePumpSelectionStore.self) private var selectionStore
    @State private var showingImporter = false
    @State private var importMessage: String?

    private let project: HeizBalanceProject?

    init(project: HeizBalanceProject? = nil) {
        self.project = project
    }

    private var operatingPoint: HeizBalancePumpOperatingPointContext? {
        guard let project,
              let result = project.hydraulicSystemPreparationState().result,
              result.pumpOperatingPointReady,
              let flowLPH = result.designTotalVolumeFlowLPH,
              let headM = result.designNetworkHeadMeters else {
            return nil
        }

        return .init(volumeFlowM3H: flowLPH / 1_000, requiredHeadM: headM)
    }

    private var heldSelection: HeizBalancePumpSelection? {
        guard let project else { return nil }
        return selectionStore.selection(projectID: project.id)
    }

    private var heldSelectionMatchesOperatingPoint: Bool {
        guard let selection = heldSelection,
              let operatingPoint else {
            return false
        }
        return selection.matchesOperatingPoint(
            volumeFlowM3H: operatingPoint.volumeFlowM3H,
            requiredHeadM: operatingPoint.requiredHeadM
        )
    }

    var body: some View {
        List {
            if let operatingPoint {
                Section {
                    LabeledContent("Auslegungs-Volumenstrom") {
                        Text(operatingPoint.volumeFlowM3H.formatted(.number.precision(.fractionLength(0...3))) + " m³/h")
                    }
                    LabeledContent("Erforderliche Förderhöhe") {
                        Text(operatingPoint.requiredHeadM.formatted(.number.precision(.fractionLength(0...2))) + " m")
                    }
                    Label("Kennlinien werden nur innerhalb ihres dokumentierten Volumenstrombereichs linear ausgewertet. Es wird nicht extrapoliert.", systemImage: "checkmark.shield")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Projekt-Betriebspunkt")
                } footer: {
                    Text("Dieser Vergleich ist eine technische Vorbereitung und noch keine automatische Pumpenauswahl oder Herstellerfreigabe.")
                }
            } else if project != nil {
                Section {
                    Label("Projekt-Betriebspunkt noch nicht vollständig berechenbar.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                } footer: {
                    Text("Für den Pumpenvergleich müssen Gesamtvolumenstrom und hydraulisch ungünstigster vollständiger Kreis vorliegen.")
                }
            }

            if let selection = heldSelection {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(selection.displayName, systemImage: "checkmark.seal")
                            .font(.headline)
                        Text(selection.curveLabel)
                            .font(.subheadline)
                        Text(selection.datasetName + " · " + selection.datasetVersion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Festgehalten am") {
                        Text(selection.selectedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    LabeledContent("Betriebspunkt bei Auswahl") {
                        Text(
                            selection.operatingPointVolumeFlowM3H.formatted(.number.precision(.fractionLength(0...3)))
                                + " m³/h · "
                                + selection.requiredHeadM.formatted(.number.precision(.fractionLength(0...2)))
                                + " m"
                        )
                        .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Förderhöhenreserve") {
                        Text(selection.headReserveM.formatted(.number.precision(.fractionLength(0...2))) + " m")
                    }

                    if heldSelectionMatchesOperatingPoint {
                        Label("Auswahl gehört zum aktuellen Projekt-Betriebspunkt.", systemImage: "checkmark.circle")
                            .font(.caption)
                    } else {
                        Label("Projekt-Betriebspunkt wurde seit der Auswahl geändert oder ist unvollständig. Auswahl neu bewerten.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Button(role: .destructive) {
                        selectionStore.delete(projectID: selection.projectID)
                    } label: {
                        Label("Festgehaltene Auswahl entfernen", systemImage: "trash")
                    }
                } header: {
                    Text("Festgehaltene Pumpenauswahl")
                } footer: {
                    Text("Die Auswahl ist ein eingefrorener Projektsnapshot. Sie bleibt dokumentierbar, auch wenn der globale Katalog später geändert oder gelöscht wird.")
                }
            }

            Section {
                if store.datasets.isEmpty {
                    ContentUnavailableView(
                        "Keine Pumpendaten",
                        systemImage: "arrow.triangle.2.circlepath",
                        description: Text(
                            "Importiere \(HeizBalancePumpProductDataset.schemaVersion) oder ein autorisiert erzeugtes \(HeizBalanceVDI3805PumpMappedDataset.schemaVersion)-Mapping."
                        )
                    )
                } else {
                    ForEach(store.datasets) { dataset in
                        NavigationLink {
                            HeizBalancePumpDatasetDetailView(
                                dataset: dataset,
                                projectID: project?.id,
                                operatingPoint: operatingPoint
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(dataset.manufacturer)
                                    .font(.headline)
                                Text(dataset.datasetName + " · " + dataset.datasetVersion)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(dataset.products.count) Pumpenprodukte")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.delete(id: dataset.id)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("Importierte Pumpenkataloge")
            } footer: {
                Text("HeizBalance enthält keine eingebauten Pumpenkennlinien. Es werden ausschließlich explizit importierte und dokumentierte Produktdaten gespeichert.")
            }

            Section {
                Button {
                    showingImporter = true
                } label: {
                    Label("Pumpendaten importieren", systemImage: "square.and.arrow.down")
                }

                if let importMessage {
                    Text(importMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let error = store.persistenceError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if let error = selectionStore.persistenceError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Import")
            } footer: {
                Text("Unterstützt werden natives HeizBalance-JSON und autorisiert erzeugte VDI-3805-Blatt-4-Mappingdateien. Die Roh-Datensatzstruktur der Richtlinie wird nicht im App-Code nachgebaut.")
            }

            Section {
                LabeledContent("VDI-Bezug", value: "VDI 3805 Blatt 4")
                LabeledContent("Mapping-Schema", value: HeizBalanceVDI3805PumpMappedDataset.schemaVersion)
                Text("Kennlinienpunkte werden dokumentiert gespeichert. HeizBalance wertet Zwischenwerte nur linear zwischen dokumentierten Punkten aus und extrapoliert nicht außerhalb des Katalogbereichs.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("VDI 3805 Adapter")
            }
        }
        .navigationTitle("Pumpendaten")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }

            do {
                let data = try Data(contentsOf: url)
                let receipt = try store.importDataset(data: data)
                importMessage = "Importiert über \(receipt.origin.title): \(receipt.dataset.manufacturer) · \(receipt.dataset.products.count) Produkte"
            } catch {
                importMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
            }

        case .failure(let error):
            importMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}

private struct HeizBalancePumpDatasetDetailView: View {
    let dataset: HeizBalancePumpProductDataset
    let projectID: UUID?
    let operatingPoint: HeizBalancePumpOperatingPointContext?

    var body: some View {
        List {
            Section("Datensatz") {
                LabeledContent("Hersteller", value: dataset.manufacturer)
                LabeledContent("Name", value: dataset.datasetName)
                LabeledContent("Version / Stand", value: dataset.datasetVersion)
                LabeledContent("Schema", value: dataset.schema)
                LabeledContent("Nutzungsgrundlage", value: dataset.source.usageBasis.title)
                LabeledContent("Quelle") {
                    Text(dataset.source.reference)
                        .multilineTextAlignment(.trailing)
                }
                if let note = dataset.source.rightsNote, !note.isEmpty {
                    LabeledContent("Rechtehinweis") {
                        Text(note)
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            ForEach(dataset.products) { product in
                Section(product.displayName) {
                    if let article = product.articleNumber, !article.isEmpty {
                        LabeledContent("Artikelnummer", value: article)
                    }
                    LabeledContent("Kennlinien", value: "\(product.curves.count)")

                    ForEach(product.curves) { curve in
                        NavigationLink {
                            HeizBalancePumpCurveDetailView(
                                dataset: dataset,
                                product: product,
                                curve: curve,
                                projectID: projectID,
                                operatingPoint: operatingPoint
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(curve.label)
                                    .font(.subheadline.weight(.semibold))
                                if let mode = curve.controlMode, !mode.isEmpty {
                                    Text(mode)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text("\(curve.points.count) dokumentierte Punkte")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                if let operatingPoint {
                                    let evaluation = evaluate(curve, at: operatingPoint)
                                    if let evaluation {
                                        Text(
                                            evaluation.technicallySufficient
                                                ? "Betriebspunkt technisch abgedeckt"
                                                : "Förderhöhe am Betriebspunkt nicht ausreichend"
                                        )
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(evaluation.technicallySufficient ? Color.primary : Color.orange)
                                    } else {
                                        Text("Betriebspunkt außerhalb Kennlinienbereich")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(dataset.manufacturer)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func evaluate(
        _ curve: HeizBalancePumpProductDataset.Curve,
        at operatingPoint: HeizBalancePumpOperatingPointContext
    ) -> HeizBalancePumpCurveOperatingPointCalculator.Result? {
        HeizBalancePumpCurveOperatingPointCalculator.calculate(
            .init(
                targetVolumeFlowM3H: operatingPoint.volumeFlowM3H,
                requiredHeadM: operatingPoint.requiredHeadM,
                points: curve.points
            )
        )
    }
}

private struct HeizBalancePumpCurveDetailView: View {
    @Environment(HeizBalancePumpSelectionStore.self) private var selectionStore

    let dataset: HeizBalancePumpProductDataset
    let product: HeizBalancePumpProductDataset.Product
    let curve: HeizBalancePumpProductDataset.Curve
    let projectID: UUID?
    let operatingPoint: HeizBalancePumpOperatingPointContext?

    private var sortedPoints: [HeizBalancePumpProductDataset.CurvePoint] {
        curve.points.sorted { $0.volumeFlowM3H < $1.volumeFlowM3H }
    }

    private var evaluation: HeizBalancePumpCurveOperatingPointCalculator.Result? {
        guard let operatingPoint else { return nil }
        return HeizBalancePumpCurveOperatingPointCalculator.calculate(
            .init(
                targetVolumeFlowM3H: operatingPoint.volumeFlowM3H,
                requiredHeadM: operatingPoint.requiredHeadM,
                points: curve.points
            )
        )
    }

    private var isHeldSelection: Bool {
        guard let projectID,
              let selection = selectionStore.selection(projectID: projectID) else {
            return false
        }
        return selection.datasetID == dataset.id
            && selection.productID == product.id
            && selection.curveID == curve.id
    }

    var body: some View {
        List {
            Section("Produkt") {
                LabeledContent("Hersteller", value: dataset.manufacturer)
                LabeledContent("Produkt", value: product.displayName)
                LabeledContent("Datenstand", value: dataset.datasetVersion)
                if let article = product.articleNumber, !article.isEmpty {
                    LabeledContent("Artikelnummer", value: article)
                }
            }

            Section("Kennlinie") {
                LabeledContent("Bezeichnung", value: curve.label)
                if let mode = curve.controlMode, !mode.isEmpty {
                    LabeledContent("Betriebs-/Regelart", value: mode)
                }
                if let speed = curve.speedRPM {
                    LabeledContent("Drehzahl") {
                        Text(speed.formatted(.number.precision(.fractionLength(0))) + " 1/min")
                    }
                }
                if let source = curve.sourceReference, !source.isEmpty {
                    LabeledContent("Quelle") {
                        Text(source)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            if let operatingPoint {
                Section {
                    LabeledContent("Projekt-Volumenstrom") {
                        Text(operatingPoint.volumeFlowM3H.formatted(.number.precision(.fractionLength(0...3))) + " m³/h")
                    }
                    LabeledContent("Erforderliche Förderhöhe") {
                        Text(operatingPoint.requiredHeadM.formatted(.number.precision(.fractionLength(0...2))) + " m")
                    }

                    if let evaluation {
                        LabeledContent("Kennlinien-Förderhöhe") {
                            Text(evaluation.availableHeadM.formatted(.number.precision(.fractionLength(0...2))) + " m")
                                .fontWeight(.semibold)
                        }
                        LabeledContent("Förderhöhenreserve") {
                            Text(evaluation.headReserveM.formatted(.number.precision(.fractionLength(0...2))) + " m")
                        }
                        if let power = evaluation.interpolatedElectricalInputPowerW {
                            LabeledContent("Elektrische Aufnahme") {
                                Text(power.formatted(.number.precision(.fractionLength(0...1))) + " W")
                            }
                        }
                        Label(
                            evaluation.technicallySufficient
                                ? "Kennlinie deckt den technischen Betriebspunkt ab."
                                : "Kennlinie erreicht die erforderliche Förderhöhe am Betriebspunkt nicht.",
                            systemImage: evaluation.technicallySufficient ? "checkmark.circle" : "exclamationmark.triangle"
                        )
                        .foregroundStyle(evaluation.technicallySufficient ? Color.primary : Color.orange)

                        Text(
                            evaluation.exactDocumentedPoint
                                ? "Auswertung an einem exakt dokumentierten Kennlinienpunkt."
                                : "Linear interpoliert zwischen den dokumentierten Punkten \(evaluation.lowerPointID) und \(evaluation.upperPointID)."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if let projectID, evaluation.technicallySufficient {
                            Button {
                                let selection = HeizBalancePumpSelection(
                                    projectID: projectID,
                                    dataset: dataset,
                                    product: product,
                                    curve: curve,
                                    evaluation: evaluation
                                )
                                selectionStore.save(selection)
                            } label: {
                                Label(
                                    isHeldSelection ? "Auswahl erneut festhalten" : "Diese Pumpe/Kennlinie festhalten",
                                    systemImage: isHeldSelection ? "checkmark.seal.fill" : "checkmark.seal"
                                )
                            }

                            if isHeldSelection {
                                Text("Dieses Produkt und diese Kennlinie sind aktuell als ausdrückliche Projektauswahl gespeichert.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else if projectID != nil && !evaluation.technicallySufficient {
                            Label("Nicht festhaltbar: Die Kennlinie deckt den aktuellen technischen Betriebspunkt nicht ab.", systemImage: "xmark.circle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Label("Betriebspunkt nicht bewertbar: Volumenstrom liegt außerhalb des dokumentierten Kennlinienbereichs. Keine Extrapolation.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Projektvergleich")
                } footer: {
                    Text("Nur eine technisch ausreichende Kennlinie kann ausdrücklich festgehalten werden. Auch diese Benutzerauswahl ist keine automatische Pumpenempfehlung, Effizienzbewertung oder Herstellerfreigabe.")
                }
            }

            Section {
                ForEach(sortedPoints) { point in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(point.volumeFlowM3H.formatted(.number.precision(.fractionLength(0...3))) + " m³/h")
                                .font(.subheadline.monospacedDigit())
                            Spacer()
                            Text(point.headM.formatted(.number.precision(.fractionLength(0...2))) + " m")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                        }
                        if let power = point.electricalInputPowerW {
                            Text("Elektrische Aufnahme: \(power.formatted(.number.precision(.fractionLength(0...1)))) W")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Dokumentierte Kennlinienpunkte")
            } footer: {
                Text("Zwischenwerte werden ausschließlich linear zwischen zwei dokumentierten Kennlinienpunkten berechnet. Außerhalb des dokumentierten Bereichs wird nicht extrapoliert.")
            }
        }
        .navigationTitle(curve.label)
        .navigationBarTitleDisplayMode(.inline)
    }
}
