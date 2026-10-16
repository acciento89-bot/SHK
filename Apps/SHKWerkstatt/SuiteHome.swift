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
                if notebook.projects.isEmpty {
                    SuiteCard {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(S("DEIN TECHNISCHER BEGLEITER", "YOUR TECHNICAL NOTEBOOK")).font(.caption.weight(.semibold)).tracking(1.2).foregroundStyle(SuiteTheme.teal)
                            Text(S("Von der Messung\nzum fertigen Bericht.", "From measurement\nto a finished report."))
                                .font(.system(.largeTitle, design: .rounded).weight(.bold)).fixedSize(horizontal: false, vertical: true)
                            Text(S("Sechs Fachbereiche. Eine gemeinsame Projektakte. Alles Wichtige für deinen nächsten Einsatz.", "Six disciplines. One shared project record. Everything you need for your next site visit."))
                                .foregroundStyle(SuiteTheme.secondary).fixedSize(horizontal: false, vertical: true)
                            SuiteCircuitIllustration().frame(height: 150).accessibilityHidden(true)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(S("Gut vorbereitet.\nSauber dokumentiert.", "Ready for the job.\nClearly documented."))
                            .font(.system(.title, design: .rounded).weight(.bold))
                        Text(S("Deine Anlagen, Berechnungen und Messwerte an einem Ort.", "Your systems, calculations and measurements in one place.")).foregroundStyle(SuiteTheme.secondary)
                    }.padding(.top, 6)
                }
                Button {
                    if SuiteAccess.canCreateProject(count: notebook.projects.count, hasPro: store.hasPro) { creating = true }
                    else { openPro() }
                } label: {
                    Label(S("Neues Projekt", "New project"), systemImage: "plus").font(.headline).frame(maxWidth: .infinity, minHeight: 34)
                }.buttonStyle(.borderedProminent).tint(SuiteTheme.action).controlSize(.large).accessibilityIdentifier("project-new")
                if let error = notebook.error { Label(error, systemImage: "exclamationmark.triangle").font(.subheadline).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true) }
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
                                Divider()
                                HStack(spacing: 13) {
                                    ForEach(SuiteModule.allCases) { module in
                                        Image(systemName: module.symbol).foregroundStyle(module.count(in: project) > 0 ? module.tint : .secondary.opacity(0.35)).font(.body)
                                    }
                                    Spacer(minLength: 0)
                                }.accessibilityLabel(S("Sechs Fachbereiche im Projekt", "Six disciplines in this project"))
                                Text(project.updatedAt, format: .dateTime.day().month().year()).font(.caption).foregroundStyle(SuiteTheme.secondary)
                            }
                        }
                    }.buttonStyle(.plain).accessibilityIdentifier("project-card-" + project.name)
                }
                if !store.hasPro { Text(S("Ein Projekt und alle Grundrechner sind kostenlos. Pro erweitert deine Werkstatt dauerhaft.", "One project and all basic calculators are free. Pro permanently expands your workshop.")).font(.footnote).foregroundStyle(SuiteTheme.secondary) }
            }.padding(20).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.background(SuiteTheme.canvas).navigationTitle("SHK Werkstatt")
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
            }.navigationTitle(S("Neues Projekt", "New project"))
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
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(S("Schnell etwas nachrechnen.", "Work out a quick answer.")).font(.system(.title2, design: .rounded).bold())
                Text(S("Alle sechs Bereiche frei verwenden. Einzelberechnungen bleiben hier, deine gespeicherten Anlagen findest du unter Projekte.", "Use all six disciplines for free. Quick calculations stay here; saved systems live in Projects.")).foregroundStyle(SuiteTheme.secondary)
                ForEach(SuiteModule.allCases) { module in
                    NavigationLink { SuiteQuickCalculator(module: module) } label: { SuiteCard { SuiteModuleLabel(module: module) } }
                        .buttonStyle(.plain).accessibilityIdentifier("calculator-" + module.rawValue)
                }
                NavigationLink { SuiteUnitConversions() } label: {
                    SuiteCard { Label(S("Einheiten umrechnen", "Unit conversions"), systemImage: "arrow.left.arrow.right").font(.headline).foregroundStyle(SuiteTheme.teal) }
                }.buttonStyle(.plain).accessibilityIdentifier("calculator-units")
            }.padding(20).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.background(SuiteTheme.canvas).navigationTitle(S("Rechner", "Calculators"))
    }
}

struct SuiteQuickCalculator: View {
    let module: SuiteModule
    @State private var draft = SuiteProject(name: "Direktberechnung")
    var body: some View { SuiteModuleEditor(module: module, project: $draft, quick: true) }
}

private struct SuiteCircuitIllustration: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width, height = proxy.size.height
            let points = [CGPoint(x: width*0.15, y: height*0.25), CGPoint(x: width*0.5, y: height*0.25), CGPoint(x: width*0.85, y: height*0.25), CGPoint(x: width*0.85, y: height*0.77), CGPoint(x: width*0.5, y: height*0.77), CGPoint(x: width*0.15, y: height*0.77)]
            ZStack {
                Path { path in path.addLines(points) }.stroke(SuiteTheme.teal.opacity(0.16), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                ForEach(Array(SuiteModule.allCases.enumerated()), id: \.element.id) { index, module in
                    Image(systemName: module.symbol).font(.title2).foregroundStyle(module.tint)
                        .frame(width: 52, height: 52).background(SuiteTheme.paper, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(module.tint.opacity(0.18)))
                        .position(points[index])
                }
            }
        }
    }
}
