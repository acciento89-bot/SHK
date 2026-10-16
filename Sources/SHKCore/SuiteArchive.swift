import Foundation

/// Every write revalidates the existing file, including saves before a first load.
/// A corrupt/newer file is never replaced by an apparently empty project list.
public struct SuiteArchive: Sendable {
    public let url: URL
    public init(url: URL) { self.url = url }
    private struct Envelope: Codable { let schemaVersion: Int; let projects: [SuiteProject] }

    public func load() throws -> [SuiteProject] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let envelope = try JSONDecoder().decode(Envelope.self, from: Data(contentsOf: url))
        guard envelope.schemaVersion == 1 else { throw SuiteValidationError.unsupportedSchema(envelope.schemaVersion) }
        try validate(envelope.projects)
        return envelope.projects
    }

    public func save(_ projects: [SuiteProject]) throws {
        _ = try load()
        try validate(projects)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(Envelope(schemaVersion: 1, projects: projects))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    private func validate(_ projects: [SuiteProject]) throws {
        guard Set(projects.map(\.id)).count == projects.count else { throw SuiteValidationError.duplicateIdentity }
        guard projects.allSatisfy(\.isValid) else { throw SuiteValidationError.invalidProject }
    }
}
