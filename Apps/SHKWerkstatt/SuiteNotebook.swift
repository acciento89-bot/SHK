import SwiftUI

@MainActor final class SuiteNotebook: ObservableObject {
    @Published private(set) var projects: [SuiteProject] = []
    @Published var error: String?
    private let archive: SuiteArchive
    init() {
        var directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("SHKWerkstatt", isDirectory: true)
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--uitest-id"), arguments.indices.contains(index+1) {
            let safe = arguments[index+1].filter { $0.isLetter || $0.isNumber || $0 == "-" }.prefix(64)
            directory = directory.appendingPathComponent("test-" + safe, isDirectory: true)
        }
        #endif
        archive = SuiteArchive(url: directory.appendingPathComponent("projects-v1.json"))
        do { projects = try archive.load() }
        catch { self.error = S("Projekte konnten nicht geöffnet werden. Vorhandene Daten bleiben erhalten. Bitte den Support kontaktieren.", "Projects could not be opened. Existing data is preserved. Please contact support.") }
    }
    @discardableResult func save(_ project: SuiteProject, hasPro: Bool) -> Bool {
        var next = projects
        if let index = next.firstIndex(where: { $0.id == project.id }) { next[index] = project }
        else {
            guard SuiteAccess.canCreateProject(count: projects.count, hasPro: hasPro) else {
                error = S("Ein Projekt ist kostenlos. Für weitere Projekte kannst du Pro dauerhaft freischalten.", "One project is free. Unlock lifetime Pro for additional projects."); return false
            }
            next.insert(project, at: 0)
        }
        return persist(next)
    }
    @discardableResult func delete(_ id: UUID) -> Bool { persist(projects.filter { $0.id != id }) }
    private func persist(_ next: [SuiteProject]) -> Bool {
        do { try archive.save(next); projects = next; return true }
        catch { self.error = S("Nicht gespeichert. Prüfe die Eingaben und den freien Speicher. Vorhandene Daten wurden nicht überschrieben.", "Not saved. Check inputs and available storage. Existing data was not overwritten."); return false }
    }
}
