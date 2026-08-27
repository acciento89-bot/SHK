import SwiftUI
import UniformTypeIdentifiers

struct HeizBalanceValveDatasetManager: View {
    @Environment(HeizBalanceValveDatasetStore.self) private var store
    @State private var showingImporter = false
    @State private var importMessage: String?

    var body: some View {
        List {
            Section {
                if store.datasets.isEmpty {
                    ContentUnavailableView(
                        "Keine Ventildaten",
                        systemImage: "slider.horizontal.3",
                        description: Text(
                            "Importiere \(HeizBalanceValveProductDataset.schemaVersion) oder ein autorisiert erzeugtes \(HeizBalanceVDI3805ValveMappedDataset.schemaVersion)-Mapping."
                        )
                    )
                } else {
                    ForEach(store.datasets) { dataset in
                        NavigationLink {
                            HeizBalanceValveDatasetDetailView(dataset: dataset)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(dataset.manufacturer)
                                    .font(.headline)
                                Text(dataset.datasetName + " · " + dataset.datasetVersion)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(dataset.products.count) Produkte")
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
                Text("Importierte Ventilkataloge")
            } footer: {
                Text("HeizBalance liefert keine eingebauten Herstellerkennlinien. Verwendet werden nur explizit importierte und dokumentierte Produktdaten.")
            }

            Section {
                Button {
                    showingImporter = true
                } label: {
                    Label("Ventildaten importieren", systemImage: "square.and.arrow.down")
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
                Text("Unterstützt werden natives HeizBalance-JSON und autorisiert erzeugte VDI-3805-Blatt-2-Mappingdateien. Roh-Datensatzbeschreibungen der Richtlinie werden nicht im App-Code nachgebaut.")
            }

            Section {
                LabeledContent("VDI-Bezug", value: "VDI 3805 Blatt 2")
                LabeledContent("Mapping-Schema", value: HeizBalanceVDI3805ValveMappedDataset.schemaVersion)
            } header: {
                Text("VDI 3805 Adapter")
            }
        }
        .navigationTitle("Ventilkataloge")
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

private struct HeizBalanceValveDatasetDetailView: View {
    let dataset: HeizBalanceValveProductDataset

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
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            Section("Produkte") {
                ForEach(dataset.products) { product in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.productName)
                            .font(.headline)
                        if let article = product.articleNumber, !article.isEmpty {
                            Text("Artikel: \(article)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text("\(product.presetPoints.count) Voreinstellung-/kv-Punkte")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(product.presetPoints.prefix(4)) { point in
                            Text("\(point.setting) → kv \(point.kvM3H.formatted(.number.precision(.fractionLength(3)))) m³/h")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        if product.presetPoints.count > 4 {
                            Text("… \(product.presetPoints.count - 4) weitere")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .navigationTitle(dataset.manufacturer)
        .navigationBarTitleDisplayMode(.inline)
    }
}
