import Foundation
import Observation

@MainActor
@Observable
final class HeizBalanceDocumentationStore {
    struct Entry: Codable, Hashable {
        static let schemaVersion = "project-documentation-v1"

        var schema: String
        var projectID: UUID
        var metadata: HeizBalanceDocumentationMetadata
        var modifiedAt: Date

        init(
            projectID: UUID,
            metadata: HeizBalanceDocumentationMetadata,
            modifiedAt: Date = Date()
        ) {
            self.schema = Self.schemaVersion
            self.projectID = projectID
            self.metadata = metadata
            self.modifiedAt = modifiedAt
        }
    }

    private(set) var entries: [Entry] = []
    var persistenceError: String?

    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directoryURL = baseURL.appendingPathComponent("HeizBalance", isDirectory: true)
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            persistenceError = "Dokumentations-Ordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }
        fileURL = directoryURL.appendingPathComponent("project-documentation.json")
        load()
    }

    func metadata(projectID: UUID) -> HeizBalanceDocumentationMetadata {
        entries.first { $0.projectID == projectID }?.metadata ?? .init()
    }

    func storedMetadata(projectID: UUID) -> HeizBalanceDocumentationMetadata? {
        entries.first { $0.projectID == projectID }?.metadata
    }

    func save(projectID: UUID, metadata: HeizBalanceDocumentationMetadata) {
        let previous = entries
        entries.removeAll { $0.projectID == projectID }
        entries.append(.init(projectID: projectID, metadata: metadata))
        do {
            try persist()
            persistenceError = nil
        } catch {
            entries = previous
            persistenceError = "Dokumentationsdaten konnten nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    func delete(projectID: UUID) {
        let previous = entries
        entries.removeAll { $0.projectID == projectID }
        do {
            try persist()
            persistenceError = nil
        } catch {
            entries = previous
            persistenceError = "Dokumentationsdaten konnten nicht gelöscht werden: \(error.localizedDescription)"
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([Entry].self, from: data)
                .filter { $0.schema == Entry.schemaVersion }
            persistenceError = nil
        } catch {
            persistenceError = "Dokumentationsdaten konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(entries).write(to: fileURL, options: .atomic)
    }
}
