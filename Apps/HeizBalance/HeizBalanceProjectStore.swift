import Foundation
import Observation

@Observable
final class HeizBalanceProjectStore {
    private(set) var projects: [HeizBalanceProject] = []
    var persistenceError: String?

    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directoryURL = baseURL.appendingPathComponent("HeizBalance", isDirectory: true)

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            persistenceError = "Projektordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }

        fileURL = directoryURL.appendingPathComponent("projects.json")
        load()
    }

    func project(id: UUID) -> HeizBalanceProject? {
        projects.first { $0.id == id }
    }

    func save(_ project: HeizBalanceProject) {
        var updatedProject = project
        updatedProject.modifiedAt = Date()

        if let index = projects.firstIndex(where: { $0.id == updatedProject.id }) {
            projects[index] = updatedProject
        } else {
            projects.insert(updatedProject, at: 0)
        }

        sortProjects()
        persist()
    }

    func delete(id: UUID) {
        projects.removeAll { $0.id == id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        projects.remove(atOffsets: offsets)
        persist()
    }

    private func sortProjects() {
        projects.sort { $0.modifiedAt > $1.modifiedAt }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            projects = try decoder.decode([HeizBalanceProject].self, from: data)
            sortProjects()
        } catch {
            persistenceError = "Gespeicherte Projekte konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(projects)
            try data.write(to: fileURL, options: .atomic)
            persistenceError = nil
        } catch {
            persistenceError = "Projekt konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }
}
