import SwiftUI

struct HeizBalanceProjectPreviewView: View {
    let project: HeizBalanceProject

    private var summary: HeizBalanceProjectPreviewState {
        project.heatLossPreviewSummary()
    }

    var body: some View {
        List {
            Section("Vollständigkeit") {
                LabeledContent("Räume vollständig") {
                    Text("\(summary.completeRoomCount) / \(summary.rooms.count)")
                }

                if summary.rooms.isEmpty {
                    Text("Es wurden noch keine Räume angelegt.")
                        .foregroundStyle(.secondary)
                } else if summary.allRoomsComplete {
                    Label("Alle Räume sind für die Vorberechnung vollständig.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label(
                        "\(summary.incompleteRoomCount) Räume benötigen noch Eingaben.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                }
            }

            if summary.completeRoomCount > 0 {
                Section {
                    LabeledContent("Transmission") {
                        Text(summary.transmissionSubtotalW.formatted(.number.precision(.fractionLength(0))) + " W")
                    }
                    LabeledContent("Lüftung") {
                        Text(summary.ventilationSubtotalW.formatted(.number.precision(.fractionLength(0))) + " W")
                    }
                    LabeledContent(summary.allRoomsComplete ? "Gebäudesumme" : "Zwischensumme") {
                        Text(summary.completedRoomsSubtotalW.formatted(.number.precision(.fractionLength(0))) + " W")
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Technische Vorberechnung")
                } footer: {
                    if summary.allRoomsComplete {
                        Text("Alle Räume sind enthalten. Das Ergebnis bleibt eine technische Vorberechnung und ist noch keine freigegebene Norm-Heizlast.")
                    } else {
                        Text("Die Zwischensumme enthält ausschließlich vollständig erfasste Räume und wird nicht als Gebäudewert ausgegeben.")
                    }
                }
            }

            Section("Räume") {
                ForEach(summary.rooms) { room in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(room.roomName)
                                    .font(.headline)
                                Text(room.floorName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let result = room.result {
                                Text(result.totalHeatLossW.formatted(.number.precision(.fractionLength(0))) + " W")
                                    .fontWeight(.semibold)
                            } else {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(.orange)
                            }
                        }

                        ForEach(room.missingInputs, id: \.self) { missing in
                            Text("• \(missing)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .navigationTitle("Vorberechnung")
        .navigationBarTitleDisplayMode(.inline)
    }
}
