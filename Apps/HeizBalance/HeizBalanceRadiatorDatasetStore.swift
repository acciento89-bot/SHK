import Foundation
import Observation

@Observable
final class HeizBalanceRadiatorDatasetStore {
    private(set) var datasets: [HeizBalanceRadiatorProductDataset] = []
    var persistenceError: String?

    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directoryURL = baseURL
            .appendingPathComponent("HeizBalance", isDirectory: true)
            .appendingPathComponent("RadiatorDatasets", isDirectory: true)

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            persistenceError = "Heizkörper-Datensatzordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }

        fileURL = directoryURL.appendingPathComponent("datasets.json")
        load()
    }

    @discardableResult
    func importDataset(data: Data) throws -> HeizBalanceRadiatorProductDataset {
        let decoder = JSONDecoder()
        let dataset = try decoder.decode(HeizBalanceRadiatorProductDataset.self, from: data)

        guard dataset.isValid else {
            let message = dataset.validationIssues
                .map(\.description)
                .joined(separator: "; ")
            throw ImportError.validationFailed(message)
        }

        if let index = datasets.firstIndex(where: { $0.id == dataset.id }) {
            datasets[index] = dataset
        } else {
            datasets.append(dataset)
        }

        sortDatasets()
        try persistThrowing()
        persistenceError = nil
        return dataset
    }

    func delete(id: String) {
        datasets.removeAll { $0.id == id }
        do {
            try persistThrowing()
            persistenceError = nil
        } catch {
            persistenceError = "Heizkörper-Datensätze konnten nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    func dataset(id: String) -> HeizBalanceRadiatorProductDataset? {
        datasets.first { $0.id == id }
    }

    func product(compositeID: String) -> (dataset: HeizBalanceRadiatorProductDataset, product: HeizBalanceRadiatorProductDataset.Product)? {
        guard let separatorRange = compositeID.range(of: HeizBalanceRadiatorProductDataset.compositeIDSeparator) else {
            return nil
        }
        let datasetID = String(compositeID[..<separatorRange.lowerBound])
        let productID = String(compositeID[separatorRange.upperBound...])

        guard let dataset = dataset(id: datasetID),
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
            datasets = try JSONDecoder().decode([HeizBalanceRadiatorProductDataset].self, from: data)
            sortDatasets()
            persistenceError = nil
        } catch {
            persistenceError = "Heizkörper-Datensätze konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func persistThrowing() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(datasets)
        try data.write(to: fileURL, options: .atomic)
    }

    enum ImportError: LocalizedError {
        case validationFailed(String)

        var errorDescription: String? {
            switch self {
            case .validationFailed(let message):
                "Datensatz ist nicht gültig: \(message)"
            }
        }
    }
}
