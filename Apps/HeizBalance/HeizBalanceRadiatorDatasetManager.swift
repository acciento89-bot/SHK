import SwiftUI
import UniformTypeIdentifiers

struct HeizBalanceRadiatorDatasetManager: View {
    @Environment(HeizBalanceRadiatorDatasetStore.self) private var store
    @State private var showingImporter = false
    @State private var importMessage: String?

    var body: some View {
        List {
            Section {
                if store.datasets.isEmpty {
                    ContentUnavailableView(
                        "Keine Heizkörperdaten",
                        systemImage: "radiator",
                        description: Text(
                            "Importiere einen dokumentierten JSON-Datensatz im Schema \(HeizBalanceRadiatorProductDataset.schemaVersion) oder ein autorisiert erzeugtes \(HeizBalanceVDI3805RadiatorMappedDataset.schemaVersion)-Mapping."
                        )
                    )
                } else {
                    ForEach(store.datasets) { dataset in
                        NavigationLink {
                            HeizBalanceRadiatorDatasetDetailView(dataset: dataset)
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
                Text("Importierte Datensätze")
            } footer: {
                Text("HeizBalance enthält keine eingebauten Herstellerlisten. Produktdaten werden nur aus explizit importierten, dokumentierten Datensätzen verwendet.")
            }

            Section {
                Button {
                    showingImporter = true
                } label: {
                    Label("Produktdaten importieren", systemImage: "square.and.arrow.down")
                }

                if let importMessage {
                    Text(importMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let persistenceError = store.persistenceError {
                    Label(persistenceError, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Import")
            } footer: {
                Text("Unterstützt werden natives HeizBalance-JSON und autorisiert erzeugte VDI-3805-Blatt-6-Mappingdateien. Rohdatenstrukturen aus der Richtlinie werden nicht im App-Code nachgebaut. Pflichtmetadaten sind Hersteller, Datenstand, Quellenreferenz und Nutzungsgrundlage.")
            }

            Section {
                LabeledContent("VDI-Bezug", value: "VDI 3805 Blatt 6")
                LabeledContent("Mapping-Schema", value: HeizBalanceVDI3805RadiatorMappedDataset.schemaVersion)
                Text("Das Mapping muss Standardbezug, Mappingprofil-Version und die rechtliche Nutzungsgrundlage dokumentieren. Erst danach werden die Daten in das interne HeizBalance-Schema überführt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("VDI 3805 Adapter")
            }
        }
        .navigationTitle("Heizkörperdaten")
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
                let receipt = try store.importDatasetWithReceipt(data: data)
                let dataset = receipt.dataset
                importMessage = "Importiert über \(receipt.origin.title): \(dataset.manufacturer) · \(dataset.datasetName) · \(dataset.products.count) Produkte"
            } catch {
                importMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
            }

        case .failure(let error):
            importMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}

private struct HeizBalanceRadiatorDatasetDetailView: View {
    let dataset: HeizBalanceRadiatorProductDataset

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
                if let url = dataset.source.url, !url.isEmpty {
                    LabeledContent("Quellen-URL") {
                        Text(url)
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                    }
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
                    VStack(alignment: .leading, spacing: 3) {
                        Text(product.displayName)
                            .font(.headline)
                        Text("ΔT50: \(product.nominalPowerDeltaT50W.formatted(.number.precision(.fractionLength(0)))) W · n = \(product.exponent.formatted(.number.precision(.fractionLength(1...3))))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        let dimensions = productDimensionText(product)
                        if !dimensions.isEmpty {
                            Text(dimensions)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if let article = product.articleNumber, !article.isEmpty {
                            Text("Artikel: \(article)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(dataset.manufacturer)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func productDimensionText(_ product: HeizBalanceRadiatorProductDataset.Product) -> String {
        var parts: [String] = []
        if let width = product.widthMM { parts.append("B \(width.formatted(.number.precision(.fractionLength(0)))) mm") }
        if let height = product.heightMM { parts.append("H \(height.formatted(.number.precision(.fractionLength(0)))) mm") }
        if let depth = product.depthMM { parts.append("T \(depth.formatted(.number.precision(.fractionLength(0)))) mm") }
        return parts.joined(separator: " · ")
    }
}
