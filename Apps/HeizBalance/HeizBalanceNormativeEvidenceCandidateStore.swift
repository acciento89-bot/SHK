import Foundation
import Observation

@Observable
final class HeizBalanceNormativeEvidenceCandidateStore {
    struct StoredCandidate: Codable, Equatable, Identifiable {
        var package: HeizBalanceNormativeEvidenceCandidatePackage
        var importedAt: Date
        var trustState: HeizBalanceNormativeEvidenceCandidateTrustState

        var id: String { package.id }

        var canAffectNormativeReadiness: Bool { false }
    }

    private(set) var candidates: [StoredCandidate] = []
    var persistenceError: String?

    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directoryURL = baseURL
            .appendingPathComponent("HeizBalance", isDirectory: true)
            .appendingPathComponent("NormativeEvidenceCandidates", isDirectory: true)

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            persistenceError = "Evidenz-Quarantäneordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }

        fileURL = directoryURL.appendingPathComponent("candidates.json")
        load()
    }

    @discardableResult
    func importCandidate(data: Data, importedAt: Date = Date()) throws -> StoredCandidate {
        let receipt = try HeizBalanceNormativeEvidenceCandidateImportDecoder.decode(data: data)
        let candidate = StoredCandidate(
            package: receipt.package,
            importedAt: importedAt,
            trustState: .quarantined
        )
        let previous = candidates

        if let index = candidates.firstIndex(where: { $0.id == candidate.id }) {
            candidates[index] = candidate
        } else {
            candidates.append(candidate)
        }
        sortCandidates()

        do {
            try persistThrowing()
            persistenceError = nil
            return candidate
        } catch {
            candidates = previous
            persistenceError = "Evidenzkandidat konnte nicht gespeichert werden: \(error.localizedDescription)"
            throw error
        }
    }

    func delete(id: String) {
        let previous = candidates
        candidates.removeAll { $0.id == id }

        do {
            try persistThrowing()
            persistenceError = nil
        } catch {
            candidates = previous
            persistenceError = "Evidenzkandidat konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }

    func candidate(id: String) -> StoredCandidate? {
        candidates.first { $0.id == id }
    }

    private func sortCandidates() {
        candidates.sort {
            if $0.importedAt == $1.importedAt {
                return $0.package.id.localizedCaseInsensitiveCompare($1.package.id) == .orderedAscending
            }
            return $0.importedAt > $1.importedAt
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            candidates = try JSONDecoder().decode([StoredCandidate].self, from: data)
                .map { stored in
                    StoredCandidate(
                        package: stored.package,
                        importedAt: stored.importedAt,
                        trustState: .quarantined
                    )
                }
            sortCandidates()
            persistenceError = nil
        } catch {
            candidates = []
            persistenceError = "Evidenz-Quarantäne konnte nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func persistThrowing() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(candidates)
        try data.write(to: fileURL, options: .atomic)
    }
}
