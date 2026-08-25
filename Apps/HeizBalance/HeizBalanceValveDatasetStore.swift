import Foundation
import Observation

@Observable
final class HeizBalanceValveDatasetStore {
    private(set) var datasets: [HeizBalanceValveProductDataset] = []
    var persistenceError: String?

    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directoryURL = baseURL
            .appendingPathComponent("HeizBalance", isDirectory: true)
            .appendingPathComponent("ValveDatasets", isDirectory: true)

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            persistenceError = "Ventil-Datensatzordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }

        fileURL = directoryURL.appendingPathComponent("datasets.json")
        load()
    }

    @discardableResult
    func importDataset(data: Data) throws -> HeizBalanceValveDatasetImportDecoder.Receipt {
        let receipt = try HeizBalanceValveDatasetImportDecoder.decode(data: data)
        let dataset = receipt.dataset
        let previous = datasets

        if let index = datasets.firstIndex(where: { $0.id == dataset.id }) {
            datasets[index] = dataset
        } else {
            datasets.append(dataset)
        }
        sortDatasets()

        do {
            try persistThrowing()
            persistenceError = nil
            return receipt
        } catch {
            datasets = previous
            persistenceError = "Ventil-Datensatz konnte nicht gespeichert werden: \(error.localizedDescription)"
            throw error
        }
    }

    func delete(id: String) {
        let previous = datasets
        datasets.removeAll { $0.id == id }

        do {
            try persistThrowing()
            persistenceError = nil
        } catch {
            datasets = previous
            persistenceError = "Ventil-Datensätze konnten nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    func product(compositeID: String) -> (dataset: HeizBalanceValveProductDataset, product: HeizBalanceValveProductDataset.Product)? {
        guard let separator = compositeID.range(of: HeizBalanceValveProductDataset.compositeIDSeparator) else {
            return nil
        }
        let datasetID = String(compositeID[..<separator.lowerBound])
        let productID = String(compositeID[separator.upperBound...])
        guard let dataset = datasets.first(where: { $0.id == datasetID }),
              let product = dataset.products.first(where: { $0.id == productID }) else {
            return nil
        }
        return (dataset, product)
    }

    private func sortDatasets() {
        datasets.sort {
            if $0.manufacturer.localizedCaseInsensitiveCompare($1.manufacturer) == .orderedSame {
                return $0.datasetName.localizedCaseInsensitiveCompare($1.datasetName) == .orderedAscending
            }
            return $0.manufacturer.localizedCaseInsensitiveCompare($1.manufacturer) == .orderedAscending
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            datasets = try JSONDecoder().decode([HeizBalanceValveProductDataset].self, from: data)
            sortDatasets()
            persistenceError = nil
        } catch {
            persistenceError = "Ventil-Datensätze konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func persistThrowing() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(datasets)
        try data.write(to: fileURL, options: .atomic)
    }
}
