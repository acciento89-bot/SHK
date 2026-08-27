import Foundation

struct HeizBalanceReportArchiveStore {
    struct ArchiveEntry: Identifiable, Hashable {
        var id: String { fileURL.lastPathComponent }
        var fileURL: URL
        var snapshot: HeizBalanceTechnicalReportSnapshot
    }

    private let fileManager: FileManager
    private let archiveRootURL: URL
    private let maximumSnapshotsPerProject: Int

    init(
        fileManager: FileManager = .default,
        maximumSnapshotsPerProject: Int = 10
    ) {
        self.fileManager = fileManager
        self.maximumSnapshotsPerProject = max(1, maximumSnapshotsPerProject)

        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        archiveRootURL = baseURL
            .appendingPathComponent("HeizBalance", isDirectory: true)
            .appendingPathComponent("ReportArchive", isDirectory: true)
    }

    func archive(_ snapshot: HeizBalanceTechnicalReportSnapshot) throws -> URL {
        let projectURL = try projectDirectory(projectID: snapshot.project.projectID)
        let filename = archiveFilename(snapshot: snapshot)
        let targetURL = projectURL.appendingPathComponent(filename)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: targetURL, options: .atomic)

        try trimArchive(projectID: snapshot.project.projectID)
        return targetURL
    }

    func entries(projectID: UUID) throws -> [ArchiveEntry] {
        let projectURL = archiveRootURL.appendingPathComponent(projectID.uuidString, isDirectory: true)
        guard fileManager.fileExists(atPath: projectURL.path) else {
            return []
        }

        let urls = try fileManager.contentsOfDirectory(
            at: projectURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "json" }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var values: [ArchiveEntry] = []
        for url in urls {
            let data = try Data(contentsOf: url)
            let snapshot = try decoder.decode(HeizBalanceTechnicalReportSnapshot.self, from: data)
            values.append(.init(fileURL: url, snapshot: snapshot))
        }

        return values.sorted { lhs, rhs in
            lhs.snapshot.generatedAt > rhs.snapshot.generatedAt
        }
    }

    private func projectDirectory(projectID: UUID) throws -> URL {
        let projectURL = archiveRootURL.appendingPathComponent(projectID.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true)
        return projectURL
    }

    private func trimArchive(projectID: UUID) throws {
        let values = try entries(projectID: projectID)
        guard values.count > maximumSnapshotsPerProject else { return }

        for entry in values.dropFirst(maximumSnapshotsPerProject) {
            try fileManager.removeItem(at: entry.fileURL)
        }
    }

    private func archiveFilename(snapshot: HeizBalanceTechnicalReportSnapshot) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter
            .string(from: snapshot.generatedAt)
            .replacingOccurrences(of: ":", with: "-")
        return "\(timestamp)-\(snapshot.schema).json"
    }
}
