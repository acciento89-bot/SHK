import SwiftUI

struct HeizBalanceHydraulicCaptureTemplateManager: View {
    @Environment(HeizBalanceHydraulicCaptureTemplateStore.self) private var store

    var body: some View {
        List {
            if store.templates.isEmpty {
                ContentUnavailableView(
                    "Noch keine Hydraulikvorlagen",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    description: Text("Speichere einen Heizflächenkreis im Projekt als Vorlage. Rohrstruktur und Ventilproduktdaten können wiederverwendet werden, flow- und druckabhängige Werte werden bewusst nicht übernommen.")
                )
            } else {
                Section {
                    ForEach(store.templates) { template in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.title)
                                .font(.headline)
                            Text(template.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.delete(id: template.id)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Gespeicherte Hydraulikvorlagen")
                } footer: {
                    Text("Vorlagen speichern Rohrabmessungen, Länge, Rauheit, ζ-Werte, Bauteilarten und ggf. dokumentierte Ventilproduktdaten. Abschnitts-Volumenströme, Δp-Werte, Quellen dieser flowabhängigen Werte und Vollständigkeitsfreigaben werden beim Speichern/Anwenden zurückgesetzt.")
                }
            }
        }
        .navigationTitle("Hydraulikvorlagen")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Speicherfehler", isPresented: errorBinding) {
            Button("OK", role: .cancel) { store.persistenceError = nil }
        } message: {
            Text(store.persistenceError ?? "Unbekannter Fehler")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { store.persistenceError != nil },
            set: { if !$0 { store.persistenceError = nil } }
        )
    }
}
