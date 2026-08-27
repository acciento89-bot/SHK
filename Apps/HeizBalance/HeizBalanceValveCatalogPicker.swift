import SwiftUI

struct HeizBalanceValveCatalogPicker: View {
    @Environment(HeizBalanceValveDatasetStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @Binding var component: HeizBalanceHydraulicLossComponent
    let requiredKvM3H: Double?

    private struct Entry: Identifiable {
        var id: String
        var dataset: HeizBalanceValveProductDataset
        var product: HeizBalanceValveProductDataset.Product
        var comparison: HeizBalanceValvePresetComparisonCalculator.Result?
    }

    private var entries: [Entry] {
        store.datasets
            .flatMap { dataset in
                dataset.products.map { product in
                    Entry(
                        id: dataset.compositeProductID(for: product.id),
                        dataset: dataset,
                        product: product,
                        comparison: comparison(for: product)
                    )
                }
            }
            .sorted { lhs, rhs in
                let leftInside = lhs.comparison?.requiredKvInsideDataRange == true
                let rightInside = rhs.comparison?.requiredKvInsideDataRange == true
                if leftInside != rightInside { return leftInside && !rightInside }

                if lhs.dataset.manufacturer.localizedCaseInsensitiveCompare(rhs.dataset.manufacturer) == .orderedSame {
                    return lhs.product.productName.localizedCaseInsensitiveCompare(rhs.product.productName) == .orderedAscending
                }
                return lhs.dataset.manufacturer.localizedCaseInsensitiveCompare(rhs.dataset.manufacturer) == .orderedAscending
            }
    }

    var body: some View {
        List {
            Section {
                if let requiredKvM3H {
                    LabeledContent("Erforderlicher kv") {
                        Text(requiredKvM3H.formatted(.number.precision(.fractionLength(3))) + " m³/h")
                            .fontWeight(.semibold)
                    }
                } else {
                    Label("Soll-kv ist noch nicht berechenbar; Katalogprodukt kann trotzdem dokumentiert übernommen werden.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Kataloge", value: "\(store.datasets.count)")
                LabeledContent("Produkte", value: "\(entries.count)")
            } header: {
                Text("Technische Anforderung")
            }

            if entries.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Keine Ventilprodukte",
                        systemImage: "slider.horizontal.3",
                        description: Text("Importiere zuerst einen dokumentierten Ventilkatalog.")
                    )
                    NavigationLink {
                        HeizBalanceValveDatasetManager()
                    } label: {
                        Label("Ventilkataloge verwalten", systemImage: "shippingbox")
                    }
                }
            } else {
                Section {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.dataset.manufacturer + " · " + entry.product.productName)
                                .font(.headline)

                            Text(entry.dataset.datasetName + " · " + entry.dataset.datasetVersion)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let comparison = entry.comparison {
                                LabeledContent("kv-Bereich") {
                                    Text(
                                        comparison.minimumKvM3H.formatted(.number.precision(.fractionLength(3)))
                                            + "–"
                                            + comparison.maximumKvM3H.formatted(.number.precision(.fractionLength(3)))
                                            + " m³/h"
                                    )
                                }
                                .font(.caption)

                                if comparison.requiredKvInsideDataRange {
                                    Label("Soll-kv liegt im dokumentierten Datenbereich", systemImage: "checkmark.circle")
                                        .font(.caption)
                                        .foregroundStyle(Color.green)
                                } else {
                                    Label("Soll-kv liegt außerhalb des dokumentierten Datenbereichs", systemImage: "exclamationmark.triangle")
                                        .font(.caption)
                                        .foregroundStyle(Color.orange)
                                }

                                Text(
                                    "Technisch nächster Datenpunkt: \(comparison.nearestPoint.setting) · kv "
                                        + comparison.nearestPoint.kvM3H.formatted(.number.precision(.fractionLength(3)))
                                )
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            } else {
                                Text("Kein Soll-kv-Vergleich verfügbar")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                component.valveProductData = entry.product.projectProductData(dataset: entry.dataset)
                                dismiss()
                            } label: {
                                Label("Produktdaten übernehmen", systemImage: "checkmark.circle")
                            }
                            .buttonStyle(.bordered)

                            Text("Quelle: " + (entry.product.sourceReference ?? entry.dataset.source.reference))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Dokumentierte Produkte")
                } footer: {
                    Text("Die Übernahme speichert Herstellerdaten und Kennlinien am Ventil. Der technisch nächste Datenpunkt ist ausdrücklich keine automatische Voreinstellung oder Montagefreigabe.")
                }
            }
        }
        .navigationTitle("Ventil aus Katalog")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func comparison(
        for product: HeizBalanceValveProductDataset.Product
    ) -> HeizBalanceValvePresetComparisonCalculator.Result? {
        guard let requiredKvM3H else { return nil }
        let points = product.presetPoints.map {
            HeizBalanceValvePresetComparisonCalculator.SettingPoint(
                setting: $0.setting,
                kvM3H: $0.kvM3H
            )
        }
        return HeizBalanceValvePresetComparisonCalculator.calculate(
            .init(requiredKvM3H: requiredKvM3H, points: points)
        )
    }
}
