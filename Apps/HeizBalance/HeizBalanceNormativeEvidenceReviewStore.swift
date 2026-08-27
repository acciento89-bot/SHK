import Foundation
import Observation

@Observable
final class HeizBalanceNormativeEvidenceReviewStore {
    typealias PackageIdentity = HeizBalanceNormativeEvidenceCandidatePackage.Identity

    struct StoredReview: Codable, Equatable, Identifiable {
        var review: HeizBalanceNormativeEvidenceReviewRecord
        var savedAt: Date

        var id: String { review.id }
        var packageIdentity: PackageIdentity { review.packageIdentity }
        var canAffectNormativeReadiness: Bool { false }
    }

    enum StoreError: LocalizedError, Equatable {
        case invalidReview([String])
        case conflictingReviewID(String)
        case conflictingPersistedReviewID(String)

        var errorDescription: String? {
            switch self {
            case .invalidReview(let issues):
                "Vorprüfung ist strukturell ungültig: \(issues.joined(separator: "; "))"
            case .conflictingReviewID(let id):
                "Review-ID \(id) existiert bereits mit anderem Inhalt. Eine geänderte Vorprüfung benötigt eine neue Review-ID."
            case .conflictingPersistedReviewID(let id):
                "Gespeicherte Vorprüfungen enthalten widersprüchliche Inhalte für Review-ID \(id). Der Review-Verlauf wurde fail-closed nicht geladen."
            }
        }
    }

    private(set) var reviews: [StoredReview] = []
    var persistenceError: String?

    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directoryURL = baseURL
            .appendingPathComponent("HeizBalance", isDirectory: true)
            .appendingPathComponent("NormativeEvidenceReviews", isDirectory: true)

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            persistenceError = "Review-Ordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }

        fileURL = directoryURL.appendingPathComponent("reviews.json")
        load(fileManager: fileManager)
    }

    @discardableResult
    func appendReview(
        _ review: HeizBalanceNormativeEvidenceReviewRecord,
        for package: HeizBalanceNormativeEvidenceCandidatePackage,
        savedAt: Date = Date()
    ) throws -> StoredReview {
        let assessment = HeizBalanceNormativeEvidenceReviewEvaluator.evaluate(
            package: package,
            review: review
        )
        guard assessment.structuralIssues.isEmpty else {
            throw StoreError.invalidReview(assessment.structuralIssues)
        }

        let stored = StoredReview(review: review, savedAt: savedAt)

        if let existing = reviews.first(where: { $0.id == stored.id }) {
            guard existing.review == stored.review else {
                throw StoreError.conflictingReviewID(stored.id)
            }
            persistenceError = nil
            return existing
        }

        let previous = reviews
        reviews.append(stored)
        sortReviews()

        do {
            try persistThrowing()
            persistenceError = nil
            return stored
        } catch {
            reviews = previous
            persistenceError = "Vorprüfung konnte nicht gespeichert werden: \(error.localizedDescription)"
            throw error
        }
    }

    func reviews(for identity: PackageIdentity) -> [StoredReview] {
        reviews
            .filter { $0.packageIdentity == identity }
            .sorted { $0.savedAt > $1.savedAt }
    }

    func latestReview(for identity: PackageIdentity) -> StoredReview? {
        reviews(for: identity).first
    }

    private func sortReviews() {
        reviews.sort {
            if $0.savedAt == $1.savedAt {
                return $0.review.id.localizedCaseInsensitiveCompare($1.review.id) == .orderedAscending
            }
            return $0.savedAt > $1.savedAt
        }
    }

    private func load(fileManager: FileManager) {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([StoredReview].self, from: data)
            reviews = try sanitizedLoadedReviews(decoded)
            sortReviews()
            persistenceError = nil
        } catch {
            reviews = []
            persistenceError = "Review-Verlauf konnte nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func sanitizedLoadedReviews(_ decoded: [StoredReview]) throws -> [StoredReview] {
        var byReviewID: [String: StoredReview] = [:]

        for stored in decoded {
            if let existing = byReviewID[stored.id] {
                guard existing.review == stored.review else {
                    throw StoreError.conflictingPersistedReviewID(stored.id)
                }
                if stored.savedAt > existing.savedAt {
                    byReviewID[stored.id] = stored
                }
            } else {
                byReviewID[stored.id] = stored
            }
        }

        return Array(byReviewID.values)
    }

    private func persistThrowing() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(reviews)
        try data.write(to: fileURL, options: .atomic)
    }
}
