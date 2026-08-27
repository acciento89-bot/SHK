import Foundation
import Observation

@MainActor
@Observable
final class HeizBalanceHydraulicCaptureTemplateStore {
    private(set) var templates: [HeizBalanceHydraulicCaptureTemplate] = []
    var persistenceError: String?

    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directoryURL = baseURL.appendingPathComponent("HeizBalance", isDirectory: true)
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            persistenceError = "Hydraulikvorlagen-Ordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }
        fileURL = directoryURL.appendingPathComponent("hydraulic-capture-templates.json")
        load()
    }

    func save(title: String, surface: HeizBalanceHeatingSurface) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        let previous = templates
        templates.removeAll { $0.title.localizedCaseInsensitiveCompare(cleanTitle) == .orderedSame }
        templates.append(.init(title: cleanTitle, surface: surface))
        templates.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        do {
            try persist()
            persistenceError = nil
        } catch {
            templates = previous
            persistenceError = "Hydraulikvorlage konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    func delete(id: UUID) {
        let previous = templates
        templates.removeAll { $0.id == id }
        do {
            try persist()
            persistenceError = nil
        } catch {
            templates = previous
            persistenceError = "Hydraulikvorlage konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            templates = try decoder.decode([HeizBalanceHydraulicCaptureTemplate].self, from: data)
                .filter { $0.schema == HeizBalanceHydraulicCaptureTemplate.schemaVersion }
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            persistenceError = nil
        } catch {
            persistenceError = "Hydraulikvorlagen konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(templates).write(to: fileURL, options: .atomic)
    }
}
