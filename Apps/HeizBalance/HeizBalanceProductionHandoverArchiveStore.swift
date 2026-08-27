import Foundation

struct HeizBalanceProductionHandoverArchiveStore {
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
            .appendingPathComponent("ProductionHandoverArchive", isDirectory: true)
    }

    func archive(_ snapshot: HeizBalanceProductionHandoverSnapshot) throws -> URL {
        let projectURL = try projectDirectory(projectID: snapshot.projectID)
        let targetURL = projectURL.appendingPathComponent(archiveFilename(snapshot: snapshot))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: targetURL, options: .atomic)

        try trimArchive(projectID: snapshot.projectID)
        return targetURL
    }

    func entries(projectID: UUID) throws -> [HeizBalanceProductionHandoverSnapshot] {
        let projectURL = archiveRootURL.appendingPathComponent(projectID.uuidString, isDirectory: true)
        guard fileManager.fileExists(atPath: projectURL.path) else { return [] }

        let urls = try fileManager.contentsOfDirectory(
            at: projectURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "json" }
        .sorted { lhs, rhs in
            let leftDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rightDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return leftDate > rightDate
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try urls.compactMap { url in
            let snapshot = try decoder.decode(HeizBalanceProductionHandoverSnapshot.self, from: Data(contentsOf: url))
            return snapshot.schema == HeizBalanceProductionHandoverSnapshot.schemaVersion ? snapshot : nil
        }
    }

    private func projectDirectory(projectID: UUID) throws -> URL {
        let projectURL = archiveRootURL.appendingPathComponent(projectID.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true)
        return projectURL
    }

    private func trimArchive(projectID: UUID) throws {
        let projectURL = archiveRootURL.appendingPathComponent(projectID.uuidString, isDirectory: true)
        guard fileManager.fileExists(atPath: projectURL.path) else { return }

        let urls = try fileManager.contentsOfDirectory(
            at: projectURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "json" }
        .sorted { lhs, rhs in
            let leftDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rightDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return leftDate > rightDate
        }

        guard urls.count > maximumSnapshotsPerProject else { return }
        for url in urls.dropFirst(maximumSnapshotsPerProject) {
            try fileManager.removeItem(at: url)
        }
    }

    private func archiveFilename(snapshot: HeizBalanceProductionHandoverSnapshot) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter
            .string(from: snapshot.generatedAt)
            .replacingOccurrences(of: ":", with: "-")
        return "\(timestamp)-\(snapshot.schema).json"
    }
}
