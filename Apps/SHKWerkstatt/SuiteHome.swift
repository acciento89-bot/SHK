import SwiftUI

struct SuiteRootView: View {
    @EnvironmentObject private var notebook: SuiteNotebook
    @EnvironmentObject private var store: SuiteStore
    @State private var tab = 0
    @State private var settings = false
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                SuiteProjectsHome(openPro: { tab = 2 })
                    .toolbar { ToolbarItem(placement: .topBarTrailing) {
                        Button { settings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel(S("Einstellungen", "Settings"))
                    } }
            }.tabItem { Label(S("Projekte", "Projects"), systemImage: "square.stack.3d.up") }.tag(0)
            NavigationStack { SuiteCalculatorsHome() }
                .tabItem { Label(S("Rechner", "Calculators"), systemImage: "function") }.tag(1)
            NavigationStack { SuiteProView() }
                .tabItem { Label("Pro", systemImage: "checkmark.seal") }.tag(2)
        }
        .toolbarBackground(SuiteTheme.canvas, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(isPresented: $settings) { SuiteSettingsView() }
        .alert(S("SHK Werkstatt", "SHK Workshop"), isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })) {
            Button("OK") { store.message = nil }
        } message: { Text(store.message ?? "") }
    }
}

struct SuiteProjectsHome: View {
    @EnvironmentObject private var notebook: SuiteNotebook
    @EnvironmentObject private var store: SuiteStore
    let openPro: () -> Void
    @State private var creating = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SuiteWorkshopHero()
                Button {
                    if SuiteAccess.canCreateProject(count: notebook.projects.count, hasPro: store.hasPro) { creating = true }
                    else { openPro() }
                } label: {
                    Label(S("Neues Projekt", "New project"), systemImage: "plus")
                }.buttonStyle(SuitePrimaryButtonStyle()).accessibilityIdentifier("project-new")
                if let error = notebook.error { Label(error, systemImage: "exclamationmark.triangle").font(.subheadline).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true) }
                SuiteSectionHeading(title: S("DEINE PROJEKTAKTEN", "YOUR PROJECT RECORDS"), detail: String(notebook.projects.count))
                if notebook.projects.isEmpty {
                    SuiteCard {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "folder.badge.plus").font(.title2).foregroundStyle(SuiteTheme.copper)
                            VStack(alignment: .leading, spacing: 7) {
                                Text(S("Bereit für den ersten Auftrag.", "Ready for your first job.")).font(.headline)
                                Text(S("Lege eine Anlage an und halte Berechnungen, Messwerte und Service zusammen fest.", "Create a system record and keep calculations, readings and service together.")).font(.subheadline).foregroundStyle(SuiteTheme.secondary)
                            }
                        }
                    }
                }
                ForEach(notebook.projects.sorted { $0.updatedAt > $1.updatedAt }) { project in
                    NavigationLink {
                        SuiteProjectDetail(initial: project)
                    } label: {
                        SuiteCard {
                            VStack(alignment: .leading, spacing: 13) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(project.name).font(.title3.bold()).foregroundStyle(.primary)
                                        if !project.customer.isEmpty { Text(project.customer).font(.subheadline).foregroundStyle(SuiteTheme.secondary) }
                                    }
                                    Spacer(minLength: 12)
                                    Image(systemName: "arrow.up.right").foregroundStyle(SuiteTheme.teal).padding(8).background(SuiteTheme.teal.opacity(0.08), in: Circle())
                                }
                                Rectangle().fill(SuiteTheme.line).frame(height: 1)
                                HStack(spacing: 13) {
                                    ForEach(SuiteModule.allCases) { module in
                                        Image(systemName: module.symbol).foregroundStyle(module.count(in: project) > 0 ? module.tint : .secondary.opacity(0.35)).font(.body)
                                    }
                                    Spacer(minLength: 0)
                                }.accessibilityLabel(S("Sechs Fachbereiche im Projekt", "Six disciplines in this project"))
                                HStack {
                                    Label(S("Lokal gespeichert", "Saved on device"), systemImage: "internaldrive").font(.caption)
                                    Spacer()
                                    Text(project.updatedAt, format: .dateTime.day().month().year()).font(.caption.monospacedDigit())
                                }.foregroundStyle(SuiteTheme.secondary)
                            }
                        }
                    }.buttonStyle(.plain).accessibilityIdentifier("project-card-" + project.name)
                }
                if !store.hasPro { Text(S("Ein Projekt und alle Grundrechner sind kostenlos. Pro erweitert deine Werkstatt dauerhaft.", "One project and all basic calculators are free. Pro permanently expands your workshop.")).font(.footnote).foregroundStyle(SuiteTheme.secondary) }
            }.padding(20).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.background(SuiteTheme.canvas).navigationTitle("SHK Werkstatt").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SuiteTheme.canvas, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $creating) { SuiteNewProjectView() }
    }
}

private struct SuiteNewProjectView: View {
    @EnvironmentObject private var notebook: SuiteNotebook
    @EnvironmentObject private var store: SuiteStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var customer = ""
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(S("Projektname", "Project name"), text: $name).accessibilityIdentifier("project-name")
                    TextField(S("Kunde / Auftraggeber", "Customer / client"), text: $customer)
                } header: { Text(S("Dein nächster Einsatz", "Your next site visit")) }
                Section {
                    Label(S("Wärme, Rohrnetz, Wasserinhalt, Lüftung, Kälte und Service gehören zu derselben Anlage.", "Heating, pipe route, water volume, ventilation, refrigeration and service belong to the same system."), systemImage: "square.stack.3d.up")
                        .font(.subheadline).foregroundStyle(SuiteTheme.secondary)
                }
                if let error = notebook.error { Text(error).foregroundStyle(.red) }
            }.suiteFormSurface().navigationTitle(S("Neues Projekt", "New project"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(S("Abbrechen", "Cancel")) { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(S("Anlegen", "Create")) {
                            if notebook.save(SuiteProject(name: name.trimmingCharacters(in: .whitespacesAndNewlines), customer: customer), hasPro: store.hasPro) { dismiss() }
                        }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("project-create")
                    }
                }.suiteKeyboard()
        }
    }
}

struct SuiteCalculatorsHome: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SuiteSectionHeading(title: S("DEINE FACHWERKZEUGE", "YOUR TRADE TOOLS"), detail: S("6 BEREICHE", "6 DISCIPLINES"))
                Text(S("Passendes Werkzeug.\nKlare Ergebnisse.", "The right tool.\nClear results.")).font(.system(.title, design: .rounded).bold())
                Text(S("Alle Grundrechner kostenlos nutzen. Für zusammenhängende Anlagen arbeitest du in deiner Projektakte.", "Use all basic calculators for free. For connected systems, work in your project record.")).font(.subheadline).foregroundStyle(SuiteTheme.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 280 : 165), spacing: 14)], alignment: .leading, spacing: 14) {
                    ForEach(SuiteModule.allCases) { module in
                        NavigationLink { SuiteQuickCalculator(module: module) } label: {
                            SuiteCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        SuiteEquipmentIcon(module: module).frame(width: 76, height: 76).accessibilityHidden(true)
                                        Spacer(minLength: 0)
                                        Image(systemName: "arrow.up.right").font(.caption.weight(.semibold)).foregroundStyle(module.tint)
                                    }
                                    Text(module.title).font(.headline).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
                                    Text(module.detail).font(.caption).foregroundStyle(SuiteTheme.secondary).fixedSize(horizontal: false, vertical: true)
                                }.frame(maxWidth: .infinity, minHeight: typeSize.isAccessibilitySize ? 0 : 156, alignment: .topLeading)
                            }
                        }.buttonStyle(.plain).accessibilityIdentifier("calculator-" + module.rawValue)
                    }
                }
                NavigationLink { SuiteUnitConversions() } label: {
                    SuiteCard { Label(S("Einheiten umrechnen", "Unit conversions"), systemImage: "arrow.left.arrow.right").font(.headline).foregroundStyle(SuiteTheme.teal) }
                }.buttonStyle(.plain).accessibilityIdentifier("calculator-units")
            }.padding(20).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.background(SuiteTheme.canvas).navigationTitle(S("Rechner", "Calculators")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SuiteTheme.canvas, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
    }
}

struct SuiteQuickCalculator: View {
    let module: SuiteModule
    @State private var draft = SuiteProject(name: "Direktberechnung")
    var body: some View { SuiteModuleEditor(module: module, project: $draft, quick: true) }
}
