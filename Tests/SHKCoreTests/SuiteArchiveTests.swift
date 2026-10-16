import Foundation
import Testing
@testable import SHKCore

private func withSuiteArchive(_ work: (URL) throws -> Void) throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    try work(folder.appendingPathComponent("projects.json"))
}

@Test func freshArchiveIsEmptyAndRealAtomicSaveCanBeReloaded() throws {
    try withSuiteArchive { url in
        let archive = SuiteArchive(url: url)
        #expect(try archive.load().isEmpty)
        let project = SuiteProject(name: "Haus Lindenweg")
        try archive.save([project])
        #expect(try SuiteArchive(url: url).load() == [project])
    }
}

@Test func corruptedAndFutureArchivesSurviveLoadAndSaveAttemptsUnchanged() throws {
    for original in [Data("broken-json".utf8), Data("{\"schemaVersion\":99,\"projects\":[]}".utf8)] {
        try withSuiteArchive { url in
            try original.write(to: url)
            let archive = SuiteArchive(url: url)
            #expect(throws: (any Error).self) { try archive.load() }
            #expect(throws: (any Error).self) { try archive.save([SuiteProject(name: "Neues Projekt")]) }
            #expect(try Data(contentsOf: url) == original)
        }
    }
}

@Test func invalidReplacementAndDuplicateIDsDoNotOverwriteTheLastGoodFile() throws {
    try withSuiteArchive { url in
        let archive = SuiteArchive(url: url), good = SuiteProject(name: "Anlage")
        try archive.save([good]); let original = try Data(contentsOf: url)
        var bad = good; bad.heat.flowC = .nan
        #expect(throws: (any Error).self) { try archive.save([bad]) }
        #expect(try Data(contentsOf: url) == original)
        #expect(throws: (any Error).self) { try archive.save([good, good]) }
        #expect(try Data(contentsOf: url) == original)
    }
}
