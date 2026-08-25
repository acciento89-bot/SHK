import SwiftUI

struct HeizBalanceProjectListView: View {
    @Environment(HeizBalanceProjectStore.self) private var store
    @State private var showingNewProject = false

    var body: some View {
        Group {
            if store.projects.isEmpty {
                ContentUnavailableView {
                    Label("Noch keine Projekte", systemImage: "house.and.flag")
                } description: {
                    Text("Lege das erste Gebäude an. Räume und Bauteile werden danach direkt vor Ort erfasst.")
                } actions: {
                    Button("Projekt anlegen") {
                        showingNewProject = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    Section {
                        ForEach(store.projects) { project in
                            NavigationLink {
                                HeizBalanceProjectEditor(project: project)
                            } label: {
                                HeizBalanceProjectRow(project: project)
                            }
                        }
                        .onDelete(perform: store.delete)
                    } header: {
                        Text("Projekte")
                    } footer: {
                        Text("Alle Projektdaten werden derzeit lokal auf diesem Gerät gespeichert.")
                    }
                }
            }
        }
        .navigationTitle("HeizBalance")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewProject = true
                } label: {
                    Label("Neues Projekt", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewProject) {
            NavigationStack {
                HeizBalanceProjectEditor(project: nil)
            }
        }
        .alert("Speicherfehler", isPresented: persistenceErrorBinding) {
            Button("OK", role: .cancel) {
                store.persistenceError = nil
            }
        } message: {
            Text(store.persistenceError ?? "Unbekannter Fehler")
        }
    }

    private var persistenceErrorBinding: Binding<Bool> {
        Binding(
            get: { store.persistenceError != nil },
            set: { newValue in
                if !newValue { store.persistenceError = nil }
            }
        )
    }
}

private struct HeizBalanceProjectRow: View {
    let project: HeizBalanceProject

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(project.name)
                    .font(.headline)
                Spacer()
                Text("\(project.roomCount) Räume")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !project.customerName.isEmpty {
                Text(project.customerName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !project.displayAddress.isEmpty {
                Label(project.displayAddress, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}
