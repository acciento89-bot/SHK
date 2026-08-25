import Foundation
import Observation

@MainActor
@Observable
final class HeizBalanceComponentFavoriteStore {
    private(set) var favorites: [HeizBalanceComponentFavorite] = []
    var persistenceError: String?

    private let fileManager: FileManager
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directoryURL = baseURL.appendingPathComponent("HeizBalance", isDirectory: true)

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            persistenceError = "Bauteilvorlagen-Ordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }

        fileURL = directoryURL.appendingPathComponent("component-favorites.json")
        load()
    }

    func save(title: String, component: HeizBalanceComponent) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            persistenceError = "Die Bauteilvorlage benötigt einen Namen."
            return
        }

        if let uValue = component.uValue,
           (!uValue.isFinite || uValue <= 0) {
            persistenceError = "Der U-Wert der Bauteilvorlage muss größer als 0 sein."
            return
        }

        let previous = favorites
        favorites.removeAll { $0.title.localizedCaseInsensitiveCompare(cleanTitle) == .orderedSame }
        favorites.append(.init(title: cleanTitle, component: component))
        favorites.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        do {
            try persist()
            persistenceError = nil
        } catch {
            favorites = previous
            persistenceError = "Bauteilvorlage konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    func delete(id: UUID) {
        let previous = favorites
        favorites.removeAll { $0.id == id }

        do {
            try persist()
            persistenceError = nil
        } catch {
            favorites = previous
            persistenceError = "Bauteilvorlage konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }

    private func load() {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            favorites = try decoder.decode([HeizBalanceComponentFavorite].self, from: data)
                .filter { $0.schema == HeizBalanceComponentFavorite.schemaVersion }
                .filter { $0.uValue.map { $0.isFinite && $0 > 0 } ?? true }
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            persistenceError = nil
        } catch {
            persistenceError = "Bauteilvorlagen konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(favorites)
        try data.write(to: fileURL, options: .atomic)
    }
}
