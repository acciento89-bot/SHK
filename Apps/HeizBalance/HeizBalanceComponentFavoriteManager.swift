import SwiftUI

struct HeizBalanceComponentFavoriteManager: View {
    @Environment(HeizBalanceComponentFavoriteStore.self) private var store

    var body: some View {
        List {
            if store.favorites.isEmpty {
                ContentUnavailableView(
                    "Noch keine Bauteilvorlagen",
                    systemImage: "square.stack.3d.up.slash",
                    description: Text("Öffne ein Bauteil im Projekt und speichere dessen Art/U-Wert als wiederverwendbare Vorlage.")
                )
            } else {
                Section {
                    ForEach(store.favorites) { favorite in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(favorite.title)
                                .font(.headline)
                            Text(favorite.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !favorite.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(favorite.note)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.delete(id: favorite.id)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Gespeicherte Vorlagen")
                } footer: {
                    Text("Vorlagen speichern keine Fläche und keine raumspezifische Gegenseitentemperatur. Beim Anwenden bleiben solche Projektdaten bewusst separat.")
                }
            }
        }
        .navigationTitle("Bauteilvorlagen")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Speicherfehler", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                store.persistenceError = nil
            }
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
