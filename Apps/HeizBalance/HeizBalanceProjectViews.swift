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
                        Text("Alle Projektdaten werden derzeit lokal auf diesem Gerät gespeichert. Die Statuschips zeigen nur den technischen Arbeitsstand, keine normative Freigabe.")
                    }
                }
            }
        }
        .navigationTitle("HeizBalance")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Section("Aufnahme") {
                        NavigationLink {
                            HeizBalanceComponentFavoriteManager()
                        } label: {
                            Label("Bauteilvorlagen", systemImage: "square.stack.3d.up")
                        }
                    }

                    Section("Produktdaten") {
                        NavigationLink {
                            HeizBalanceRadiatorDatasetManager()
                        } label: {
                            Label("Heizkörperdaten", systemImage: "radiator")
                        }

                        NavigationLink {
                            HeizBalanceValveDatasetManager()
                        } label: {
                            Label("Ventildaten", systemImage: "slider.horizontal.3")
                        }

                        NavigationLink {
                            HeizBalancePumpDatasetManager()
                        } label: {
                            Label("Pumpendaten", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                } label: {
                    Label("Daten & Vorlagen", systemImage: "shippingbox.and.arrow.backward")
                }
            }

#if DEBUG
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        store.save(HeizBalanceSampleProjectFactory.makeTechnicalDemoProject())
                    } label: {
                        Label("Musterprojekt hinzufügen", systemImage: "testtube.2")
                    }
                } label: {
                    Label("Entwicklung", systemImage: "ellipsis.circle")
                }
            }
#endif

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
    @Environment(HeizBalancePumpSelectionStore.self) private var pumpSelectionStore

    let project: HeizBalanceProject

    private var preview: HeizBalanceProjectPreviewState {
        project.heatLossPreviewSummary()
    }

    private var hydraulic: HeizBalanceHydraulicSystemPreparationCalculator.Result? {
        project.hydraulicSystemPreparationState().result
    }

    private var operatingPoint: (flowM3H: Double, headM: Double)? {
        guard let hydraulic,
              hydraulic.pumpOperatingPointReady,
              let flowLPH = hydraulic.designTotalVolumeFlowLPH,
              let headM = hydraulic.designNetworkHeadMeters else {
            return nil
        }
        return (flowLPH / 1_000, headM)
    }

    private var pumpSelection: HeizBalancePumpSelection? {
        pumpSelectionStore.selection(projectID: project.id)
    }

    private var pumpSelectionIsCurrent: Bool {
        guard let pumpSelection,
              let operatingPoint else {
            return false
        }
        return pumpSelection.matchesOperatingPoint(
            volumeFlowM3H: operatingPoint.flowM3H,
            requiredHeadM: operatingPoint.headM
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
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

            HStack(spacing: 8) {
                statusChip(
                    title: "Räume",
                    symbol: preview.allRoomsComplete && !preview.rooms.isEmpty ? "checkmark.circle.fill" : "circle.dashed",
                    color: preview.allRoomsComplete && !preview.rooms.isEmpty ? .green : .secondary
                )
                statusChip(
                    title: "Hydraulik",
                    symbol: operatingPoint != nil ? "checkmark.circle.fill" : "circle.dashed",
                    color: operatingPoint != nil ? .green : .secondary
                )
                statusChip(
                    title: "Pumpe",
                    symbol: pumpSelection == nil
                        ? "circle.dashed"
                        : (pumpSelectionIsCurrent ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"),
                    color: pumpSelection == nil
                        ? .secondary
                        : (pumpSelectionIsCurrent ? .green : .orange)
                )
            }
        }
        .padding(.vertical, 3)
    }

    private func statusChip(title: String, symbol: String, color: Color) -> some View {
        Label(title, systemImage: symbol)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
    }
}
