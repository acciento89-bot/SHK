import Foundation
import Observation

@Observable
final class HeizBalancePumpSelectionStore {
    static let shared = HeizBalancePumpSelectionStore()

    private(set) var selections: [HeizBalancePumpSelection] = []
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
            persistenceError = "Pumpenauswahl-Ordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }

        fileURL = directoryURL.appendingPathComponent("pump-selections.json")
        load()
    }

    func selection(projectID: UUID) -> HeizBalancePumpSelection? {
        selections.first { $0.projectID == projectID }
    }

    func save(_ selection: HeizBalancePumpSelection) {
        let previous = selections
        selections.removeAll { $0.projectID == selection.projectID }
        selections.append(selection)
        selections.sort { $0.selectedAt > $1.selectedAt }

        do {
            try persist()
            persistenceError = nil
        } catch {
            selections = previous
            persistenceError = "Pumpenauswahl konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    func delete(projectID: UUID) {
        let previous = selections
        selections.removeAll { $0.projectID == projectID }

        do {
            try persist()
            persistenceError = nil
        } catch {
            selections = previous
            persistenceError = "Pumpenauswahl konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }

    private func load() {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            selections = try decoder.decode([HeizBalancePumpSelection].self, from: data)
                .filter { $0.schema == HeizBalancePumpSelection.schemaVersion }
                .sorted { $0.selectedAt > $1.selectedAt }
            persistenceError = nil
        } catch {
            persistenceError = "Gespeicherte Pumpenauswahlen konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(selections)
        try data.write(to: fileURL, options: .atomic)
    }
}
