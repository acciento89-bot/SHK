import SwiftUI

struct SuiteProjectDetail: View {
    @EnvironmentObject private var notebook: SuiteNotebook
    @EnvironmentObject private var store: SuiteStore
    @Environment(\.dismiss) private var dismiss
    @State private var project: SuiteProject
    @State private var saved: SuiteProject
    @State private var discard = false
    @State private var deleting = false
    @State private var report = false
    init(initial: SuiteProject) {
        _project = State(initialValue: initial); _saved = State(initialValue: initial)
    }
    private var dirty: Bool { project != saved }
    var body: some View {
        List {
            Section {
                TextField(S("Projektname", "Project name"), text: $project.name).font(.title3.bold())
                TextField(S("Kunde / Auftraggeber", "Customer / client"), text: $project.customer)
                TextField(S("Adresse / Anlagenstandort", "Address / system location"), text: $project.address)
            } header: { Text(S("Deine Anlage", "Your system")) }
            Section {
                ForEach(SuiteModule.allCases) { module in
                    NavigationLink {
                        SuiteModuleEditor(module: module, project: $project)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            SuiteModuleLabel(module: module)
                            if module.count(in: project) > 0 {
                                Text("\(module.count(in: project)) " + S("Einträge", "entries")).font(.caption.weight(.medium)).foregroundStyle(module.tint).padding(.leading, 62)
                            }
                        }
                    }.accessibilityIdentifier("module-" + module.rawValue)
                }
            } header: { Text(S("Sechs Bereiche. Ein Zusammenhang.", "Six disciplines. One connected record.")) }
            Section(S("Übergabe", "Handover")) {
                Button { report = true } label: { Label(S("Projektbericht ansehen", "View project report"), systemImage: "doc.text") }
                    .buttonStyle(SuiteRowButtonStyle()).disabled(!project.isValid).accessibilityIdentifier("report-open")
                TextField(S("Projektweite Notizen", "Project notes"), text: $project.notes, axis: .vertical).lineLimit(3...8)
                if dirty { Label(S("Änderungen noch nicht gesichert", "Changes have not been saved"), systemImage: "pencil.circle").font(.subheadline).foregroundStyle(SuiteTheme.copper) }
                if !project.isValid { Label(S("Bitte prüfe Namen, Zahlen und die Hinweise in den Fachbereichen.", "Check names, numbers and the guidance in each discipline."), systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
                if let error = notebook.error { Text(error).font(.subheadline).foregroundStyle(.red) }
                Button(S("Projekt löschen", "Delete project"), role: .destructive) { deleting = true }.buttonStyle(SuiteRowButtonStyle())
            }
        }.navigationTitle(project.name).navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { if dirty { discard = true } else { dismiss() } } label: { Label(S("Projekte", "Projects"), systemImage: "chevron.left") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(S("Sichern", "Save")) {
                        var changed = project; changed.updatedAt = Date()
                        if notebook.save(changed, hasPro: store.hasPro) { project = changed; saved = changed }
                    }.fontWeight(.semibold).disabled(!project.isValid || !dirty).accessibilityIdentifier("project-save")
                }
            }
            .confirmationDialog(S("Änderungen verwerfen?", "Discard changes?"), isPresented: $discard, titleVisibility: .visible) {
                Button(S("Verwerfen", "Discard"), role: .destructive) { dismiss() }
                Button(S("Weiter bearbeiten", "Keep editing"), role: .cancel) {}
            }
            .confirmationDialog(S("Dieses Projekt endgültig löschen?", "Permanently delete this project?"), isPresented: $deleting, titleVisibility: .visible) {
                Button(S("Projekt löschen", "Delete project"), role: .destructive) { if notebook.delete(project.id) { dismiss() } }
            }
            .sheet(isPresented: $report) { SuiteReportView(project: project, draft: dirty) }
            .suiteKeyboard()
    }
}

enum SuiteEntrySheet: Identifiable {
    case cold, component, pipe
    case fill(VolumeProject)
    var id: String {
        switch self {
        case .cold: "cold"
        case .component: "component"
        case .pipe: "pipe"
        case .fill: "fill"
        }
    }
}

struct SuiteModuleEditor: View {
    let module: SuiteModule
    @Binding var project: SuiteProject
    var quick = false
    @State private var reset = false
    @State private var entrySheet: SuiteEntrySheet?
    var body: some View {
        Form {
            Section {
                SuiteModuleLabel(module: module)
                if quick { Text(S("Direktberechnung · wird nicht als Projekt gespeichert", "Quick calculation · not saved as a project")).font(.footnote).foregroundStyle(SuiteTheme.secondary) }
            }
            switch module {
            case .heat: SuiteHeatingFields(project: $project, quick: quick)
            case .pipe: SuitePipeFields(project: $project, quick: quick)
            case .volume: SuiteVolumeFields(project: $project, quick: quick, showSheet: { entrySheet = $0 })
            case .air: SuiteAirFields(project: $project)
            case .cold: SuiteColdFields(project: $project, addReading: { entrySheet = .cold })
            case .service: SuiteServiceFields(project: $project)
            }
        }.navigationTitle(module.title).navigationBarTitleDisplayMode(.inline).suiteKeyboard()
            .sheet(item: $entrySheet) { sheet in
                switch sheet {
                case .cold: SuiteColdReadingSheet { project.cold.readings.append($0) }
                case .component: SuiteVolumeComponentSheet { project.volume.components.append($0) }
                case .pipe: SuiteVolumePipeSheet { project.volume.components.append($0) }
                case .fill(let inventory): SuiteFillSheet(project: inventory) { project.volume.fillChecks = (project.volume.fillChecks ?? []) + [$0] }
                }
            }
            .toolbar {
                if quick { ToolbarItem(placement: .topBarTrailing) { Button(S("Leeren", "Reset")) { reset = true } } }
            }
            .confirmationDialog(S("Diese Direktberechnung leeren?", "Reset this quick calculation?"), isPresented: $reset, titleVisibility: .visible) {
                Button(S("Leeren", "Reset"), role: .destructive) { project = SuiteProject(name: "Direktberechnung") }
            }
    }
}
