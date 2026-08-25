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
                ForEach(summary.rooms) { roomEntry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(roomEntry.roomName)
                                    .font(.headline)
                                Text(roomEntry.floorName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let result = roomEntry.result {
                                Text(result.totalHeatLossW.formatted(.number.precision(.fractionLength(0))) + " W")
                                    .fontWeight(.semibold)
                            } else {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(.orange)
                            }
                        }

                        ForEach(roomEntry.missingInputs, id: \.self) { missing in
                            Text("• \(missing)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let roomResult = roomEntry.result,
                           let sourceRoom = project.room(id: roomEntry.id),
                           let coverage = sourceRoom.heatingCoverage(
                                requiredRoomPowerW: roomResult.totalHeatLossW,
                                designFlowTemperatureC: project.designFlowTemperatureC,
                                designReturnTemperatureC: project.designReturnTemperatureC
                           ) {
                            Divider()
                            RoomHeatingCoverageSummaryView(state: coverage)
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

private struct RoomHeatingCoverageSummaryView: View {
    let state: HeizBalanceRoomHeatingCoverageState

    private var result: HeizBalanceRoomHeatingCoverageCalculator.Result {
        state.result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("Heizflächenabdeckung", systemImage: "radiator")
                .font(.subheadline.weight(.semibold))

            if state.validAvailableSurfaceCount > 0 {
                HStack {
                    Text("Verfügbar")
                    Spacer()
                    Text(result.availablePowerW.formatted(.number.precision(.fractionLength(0))) + " W")
                }
                .font(.caption)

                HStack {
                    Text("Deckung Raum-Vorbereitung")
                    Spacer()
                    Text((result.availableCoverageRatio * 100).formatted(.number.precision(.fractionLength(0))) + " %")
                }
                .font(.caption)

                if result.capacitySufficient {
                    Text("Heizflächenleistung deckt die technische Raum-Vorbereitung.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Heizflächenleistung liegt unter der technischen Raum-Vorbereitung.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else {
                Text("Die verfügbare Heizflächenleistung ist noch nicht berechenbar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if state.assignedSurfaceCount > 0 {
                HStack {
                    Text("Zugeordnet")
                    Spacer()
                    Text(result.assignedPowerW.formatted(.number.precision(.fractionLength(0))) + " W")
                }
                .font(.caption)

                HStack {
                    Text("Differenz zur Raum-Vorbereitung")
                    Spacer()
                    Text(result.assignmentDifferenceW.formatted(.number.precision(.fractionLength(0))) + " W")
                }
                .font(.caption)
            } else {
                Text("Noch keine erforderliche Leistung auf Heizflächen verteilt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if state.targetFlowSurfaceCount > 0 {
                HStack {
                    Text("Ziel-Volumenstrom gesamt")
                    Spacer()
                    Text(result.totalTargetVolumeFlowLPH.formatted(.number.precision(.fractionLength(0))) + " l/h")
                        .fontWeight(.semibold)
                }
                .font(.caption)
            }

            if state.validAvailableSurfaceCount < state.totalSurfaceCount
                || state.assignedSurfaceCount < state.totalSurfaceCount {
                Text(
                    "Heizflächen: \(state.validAvailableSurfaceCount)/\(state.totalSurfaceCount) leistungsseitig berechenbar, \(state.assignedSurfaceCount)/\(state.totalSurfaceCount) mit erforderlicher Leistung belegt."
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Text("Vergleich mit der technischen Raum-Vorbereitung – kein Norm- oder Verfahren-B-Nachweis.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
