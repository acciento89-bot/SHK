import Foundation

struct HeizBalanceAdjustmentListArchiveStore {
    private let fileManager: FileManager
    private let archiveRootURL: URL
    private let maximumSnapshotsPerProject: Int

    init(fileManager: FileManager = .default, maximumSnapshotsPerProject: Int = 10) {
        self.fileManager = fileManager
        self.maximumSnapshotsPerProject = max(1, maximumSnapshotsPerProject)
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        archiveRootURL = baseURL
            .appendingPathComponent("HeizBalance", isDirectory: true)
            .appendingPathComponent("AdjustmentListArchive", isDirectory: true)
    }

    func archive(_ snapshot: HeizBalanceAdjustmentListSnapshot) throws -> URL {
        let projectURL = try projectDirectory(projectID: snapshot.projectID)
        let targetURL = projectURL.appendingPathComponent(filename(snapshot))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: targetURL, options: .atomic)
        try trim(projectID: snapshot.projectID)
        return targetURL
    }

    func entries(projectID: UUID) throws -> [HeizBalanceAdjustmentListSnapshot] {
        let projectURL = archiveRootURL.appendingPathComponent(projectID.uuidString, isDirectory: true)
        guard fileManager.fileExists(atPath: projectURL.path) else { return [] }
        let urls = try fileManager.contentsOfDirectory(
            at: projectURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "json" }
        .sorted { lhs, rhs in
            let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return l > r
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try urls.compactMap { url in
            let snapshot = try decoder.decode(HeizBalanceAdjustmentListSnapshot.self, from: Data(contentsOf: url))
            return snapshot.schema == HeizBalanceAdjustmentListSnapshot.schemaVersion ? snapshot : nil
        }
    }

    private func projectDirectory(projectID: UUID) throws -> URL {
        let url = archiveRootURL.appendingPathComponent(projectID.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func trim(projectID: UUID) throws {
        let projectURL = archiveRootURL.appendingPathComponent(projectID.uuidString, isDirectory: true)
        guard fileManager.fileExists(atPath: projectURL.path) else { return }
        let urls = try fileManager.contentsOfDirectory(
            at: projectURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "json" }
        .sorted { lhs, rhs in
            let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return l > r
        }
        for url in urls.dropFirst(maximumSnapshotsPerProject) {
            try fileManager.removeItem(at: url)
        }
    }

    private func filename(_ snapshot: HeizBalanceAdjustmentListSnapshot) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: snapshot.generatedAt).replacingOccurrences(of: ":", with: "-")
        return "\(timestamp)-\(snapshot.schema).json"
    }
}
