import Foundation
import Observation

@MainActor
@Observable
final class HeizBalanceValveSettingSelectionStore {
    private(set) var selections: [HeizBalanceValveSettingSelection] = []
    var persistenceError: String?

    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directoryURL = baseURL.appendingPathComponent("HeizBalance", isDirectory: true)
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            persistenceError = "Ventileinstellungs-Ordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }
        fileURL = directoryURL.appendingPathComponent("valve-setting-selections.json")
        load()
    }

    func selection(projectID: UUID, componentID: UUID) -> HeizBalanceValveSettingSelection? {
        selections.first { $0.projectID == projectID && $0.componentID == componentID }
    }

    func save(_ selection: HeizBalanceValveSettingSelection) {
        let previous = selections
        selections.removeAll {
            $0.projectID == selection.projectID && $0.componentID == selection.componentID
        }
        selections.append(selection)
        do {
            try persist()
            persistenceError = nil
        } catch {
            selections = previous
            persistenceError = "Ventileinstellung konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    func delete(projectID: UUID, componentID: UUID) {
        let previous = selections
        selections.removeAll { $0.projectID == projectID && $0.componentID == componentID }
        do {
            try persist()
            persistenceError = nil
        } catch {
            selections = previous
            persistenceError = "Ventileinstellung konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }

    func selections(projectID: UUID) -> [HeizBalanceValveSettingSelection] {
        selections
            .filter { $0.projectID == projectID }
            .sorted { lhs, rhs in
                if lhs.componentName == rhs.componentName {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.componentName.localizedCaseInsensitiveCompare(rhs.componentName) == .orderedAscending
            }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            selections = try decoder.decode([HeizBalanceValveSettingSelection].self, from: data)
                .filter { $0.schema == HeizBalanceValveSettingSelection.schemaVersion }
            persistenceError = nil
        } catch {
            persistenceError = "Ventileinstellungen konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(selections).write(to: fileURL, options: .atomic)
    }
}
