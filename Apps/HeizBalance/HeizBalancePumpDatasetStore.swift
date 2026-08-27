import Foundation
import Observation

@Observable
final class HeizBalancePumpDatasetStore {
    private(set) var datasets: [HeizBalancePumpProductDataset] = []
    var persistenceError: String?

    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directoryURL = baseURL
            .appendingPathComponent("HeizBalance", isDirectory: true)
            .appendingPathComponent("PumpDatasets", isDirectory: true)

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            persistenceError = "Pumpen-Datensatzordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }

        fileURL = directoryURL.appendingPathComponent("datasets.json")
        load()
    }

    @discardableResult
    func importDataset(data: Data) throws -> HeizBalancePumpDatasetImportDecoder.Receipt {
        let receipt = try HeizBalancePumpDatasetImportDecoder.decode(data: data)
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
            persistenceError = "Pumpen-Datensatz konnte nicht gespeichert werden: \(error.localizedDescription)"
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
            persistenceError = "Pumpen-Datensätze konnten nicht gespeichert werden: \(error.localizedDescription)"
        }
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
            datasets = try JSONDecoder().decode([HeizBalancePumpProductDataset].self, from: data)
            sortDatasets()
            persistenceError = nil
        } catch {
            persistenceError = "Pumpen-Datensätze konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func persistThrowing() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(datasets)
        try data.write(to: fileURL, options: .atomic)
    }
}
