import SwiftUI

struct HeizBalanceView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Projekt") {
                    Label("Gebäude & Räume", systemImage: "house")
                    Label("Bauteile & U-Werte", systemImage: "square.3.layers.3d")
                }

                Section("Berechnung") {
                    Label("Raumweise Heizlast", systemImage: "flame")
                    Label("Heizflächenprüfung", systemImage: "radiator")
                    Label("Hydraulischer Abgleich", systemImage: "drop.triangle")
                    Label("Pumpe & Volumenströme", systemImage: "arrow.triangle.2.circlepath")
                }

                Section("Dokumentation") {
                    Label("Projektbericht", systemImage: "doc.text")
                }
            }
            .navigationTitle("HeizBalance")
        }
    }
}

#Preview {
    HeizBalanceView()
        .preferredColorScheme(.dark)
}
