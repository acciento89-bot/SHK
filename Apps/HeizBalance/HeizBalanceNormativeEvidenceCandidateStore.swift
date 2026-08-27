import Foundation
import Observation

@Observable
final class HeizBalanceNormativeEvidenceCandidateStore {
    typealias PackageIdentity = HeizBalanceNormativeEvidenceCandidatePackage.Identity

    struct StoredCandidate: Codable, Equatable, Identifiable {
        var package: HeizBalanceNormativeEvidenceCandidatePackage
        var importedAt: Date
        var trustState: HeizBalanceNormativeEvidenceCandidateTrustState

        var id: PackageIdentity { package.identity }

        var canAffectNormativeReadiness: Bool { false }
    }

    enum StoreError: LocalizedError, Equatable {
        case conflictingRevision(PackageIdentity)
        case conflictingPersistedRevision(PackageIdentity)

        var errorDescription: String? {
            switch self {
            case .conflictingRevision(let identity):
                "Evidenzpaket \(identity.displayValue) existiert bereits mit anderem Inhalt. Für geänderten Inhalt ist eine neue Paketversion erforderlich."
            case .conflictingPersistedRevision(let identity):
                "Gespeicherte Evidenz enthält widersprüchliche Revisionen für \(identity.displayValue). Die Quarantäne wurde fail-closed nicht geladen."
            }
        }
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
        load(fileManager: fileManager)
    }

    @discardableResult
    func importCandidate(data: Data, importedAt: Date = Date()) throws -> StoredCandidate {
        let receipt = try HeizBalanceNormativeEvidenceCandidateImportDecoder.decode(data: data)
        let incomingPackage = receipt.package

        switch HeizBalanceNormativeEvidenceCandidateRevisionPolicy.decision(
            existing: candidates.map(\.package),
            incoming: incomingPackage
        ) {
        case .identicalRevision:
            if let existing = candidate(identity: incomingPackage.identity) {
                persistenceError = nil
                return existing
            }

        case .conflictingRevision:
            throw StoreError.conflictingRevision(incomingPackage.identity)

        case .insertNewIdentity:
            break
        }

        let candidate = StoredCandidate(
            package: incomingPackage,
            importedAt: importedAt,
            trustState: .quarantined
        )
        let previous = candidates
        candidates.append(candidate)
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

    func delete(identity: PackageIdentity) {
        let previous = candidates
        candidates.removeAll { $0.package.identity == identity }

        do {
            try persistThrowing()
            persistenceError = nil
        } catch {
            candidates = previous
            persistenceError = "Evidenzkandidat konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }

    func candidate(identity: PackageIdentity) -> StoredCandidate? {
        candidates.first { $0.package.identity == identity }
    }

    private func sortCandidates() {
        candidates.sort {
            if $0.importedAt == $1.importedAt {
                if $0.package.id == $1.package.id {
                    return $0.package.packageVersion.localizedCaseInsensitiveCompare($1.package.packageVersion) == .orderedDescending
                }
                return $0.package.id.localizedCaseInsensitiveCompare($1.package.id) == .orderedAscending
            }
            return $0.importedAt > $1.importedAt
        }
    }

    private func load(fileManager: FileManager) {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([StoredCandidate].self, from: data)
            candidates = try sanitizedLoadedCandidates(decoded)
            sortCandidates()
            persistenceError = nil
        } catch {
            candidates = []
            persistenceError = "Evidenz-Quarantäne konnte nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func sanitizedLoadedCandidates(
        _ decoded: [StoredCandidate]
    ) throws -> [StoredCandidate] {
        var byIdentity: [PackageIdentity: StoredCandidate] = [:]

        for stored in decoded {
            let sanitized = StoredCandidate(
                package: stored.package,
                importedAt: stored.importedAt,
                trustState: .quarantined
            )
            let identity = sanitized.package.identity

            if let existing = byIdentity[identity] {
                guard existing.package == sanitized.package else {
                    throw StoreError.conflictingPersistedRevision(identity)
                }
                if sanitized.importedAt > existing.importedAt {
                    byIdentity[identity] = sanitized
                }
            } else {
                byIdentity[identity] = sanitized
            }
        }

        return Array(byIdentity.values)
    }

    private func persistThrowing() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(candidates)
        try data.write(to: fileURL, options: .atomic)
    }
}
