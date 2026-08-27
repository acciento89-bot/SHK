import Foundation

struct HeizBalanceHydraulicNetworkReportArchiveStore {
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
            .appendingPathComponent("HydraulicNetworkReportArchive", isDirectory: true)
    }

    func archive(_ snapshot: HeizBalanceHydraulicNetworkReportSnapshot) throws -> URL {
        let directory = try projectDirectory(projectID: snapshot.projectID)
        let target = directory.appendingPathComponent(filename(snapshot))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: target, options: .atomic)
        try trim(projectID: snapshot.projectID)
        return target
    }

    private func projectDirectory(projectID: UUID) throws -> URL {
        let url = archiveRootURL.appendingPathComponent(projectID.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func trim(projectID: UUID) throws {
        let directory = archiveRootURL.appendingPathComponent(projectID.uuidString, isDirectory: true)
        guard fileManager.fileExists(atPath: directory.path) else { return }
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "json" }
        .sorted {
            let lhs = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rhs = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return lhs > rhs
        }
        for url in urls.dropFirst(maximumSnapshotsPerProject) {
            try fileManager.removeItem(at: url)
        }
    }

    private func filename(_ snapshot: HeizBalanceHydraulicNetworkReportSnapshot) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: snapshot.generatedAt).replacingOccurrences(of: ":", with: "-")
        return "\(timestamp)-\(snapshot.schema).json"
    }
}
