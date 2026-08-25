import SwiftUI
import UniformTypeIdentifiers

struct HeizBalancePumpDatasetManager: View {
    @Environment(HeizBalancePumpDatasetStore.self) private var store
    @State private var showingImporter = false
    @State private var importMessage: String?

    var body: some View {
        List {
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
                            HeizBalancePumpDatasetDetailView(dataset: dataset)
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
            } header: {
                Text("Import")
            } footer: {
                Text("Unterstützt werden natives HeizBalance-JSON und autorisiert erzeugte VDI-3805-Blatt-4-Mappingdateien. Die Roh-Datensatzstruktur der Richtlinie wird nicht im App-Code nachgebaut.")
            }

            Section {
                LabeledContent("VDI-Bezug", value: "VDI 3805 Blatt 4")
                LabeledContent("Mapping-Schema", value: HeizBalanceVDI3805PumpMappedDataset.schemaVersion)
                Text("Kennlinienpunkte werden dokumentiert gespeichert. HeizBalance leitet daraus in diesem Entwicklungsstand noch keine automatische Pumpenauswahl oder Herstellerfreigabe ab.")
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
                            HeizBalancePumpCurveDetailView(curve: curve)
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
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(dataset.manufacturer)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HeizBalancePumpCurveDetailView: View {
    let curve: HeizBalancePumpProductDataset.Curve

    private var sortedPoints: [HeizBalancePumpProductDataset.CurvePoint] {
        curve.points.sorted { $0.volumeFlowM3H < $1.volumeFlowM3H }
    }

    var body: some View {
        List {
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
                Text("Die Punkte werden unverändert als Produktdaten dokumentiert. Zwischenwerte und eine automatische Betriebspunkt-/Pumpenauswahl sind noch nicht freigegeben.")
            }
        }
        .navigationTitle(curve.label)
        .navigationBarTitleDisplayMode(.inline)
    }
}
