import SwiftUI
import UniformTypeIdentifiers

struct HeizBalanceAdjustmentListView: View {
    @Environment(HeizBalanceValveSettingSelectionStore.self) private var valveSelectionStore
    @Environment(HeizBalancePumpSelectionStore.self) private var pumpSelectionStore

    let project: HeizBalanceProject

    @State private var exportDocument = HeizBalancePDFDocument(data: Data())
    @State private var pendingSnapshot: HeizBalanceAdjustmentListSnapshot?
    @State private var archiveEntries: [HeizBalanceAdjustmentListSnapshot] = []
    @State private var showingExporter = false
    @State private var exportMessage: String?

    private var archiveStore: HeizBalanceAdjustmentListArchiveStore {
        HeizBalanceAdjustmentListArchiveStore()
    }

    private var snapshot: HeizBalanceAdjustmentListSnapshot {
        HeizBalanceAdjustmentListSnapshot.make(
            project: project,
            valveSelections: valveSelectionStore.selections(projectID: project.id),
            pumpSelection: pumpSelectionStore.selection(projectID: project.id)
        )
    }

    private var filename: String {
        let raw = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = raw.isEmpty ? "HeizBalance" : raw
        let forbidden = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let cleaned = base.components(separatedBy: forbidden).joined(separator: "-")
        return "HeizBalance-\(cleaned)-Einstellliste"
    }

    var body: some View {
        let current = snapshot
        List {
            Section {
                Text(current.notice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LabeledContent("Kreise", value: "\(current.summary.circuitCount)")
                LabeledContent("Q vollständig", value: "\(current.summary.flowReadyCount) / \(current.summary.circuitCount)")
                LabeledContent("Δp vollständig", value: "\(current.summary.pressureReadyCount) / \(current.summary.circuitCount)")
                LabeledContent("Ventile ohne Einstellung", value: "\(current.summary.valveWithoutHeldSettingCount)")
                LabeledContent("Neu zu bewerten", value: "\(current.summary.staleValveSettingCount)")
            } header: {
                Text("Baustellenstatus")
            }

            if let pump = current.pump {
                Section {
                    LabeledContent("Pumpe") {
                        Text(pump.displayName)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Kennlinie", value: pump.curveLabel)
                    LabeledContent("Betriebspunkt") {
                        Text(
                            pump.operatingPointVolumeFlowM3H.formatted(.number.precision(.fractionLength(0...3)))
                                + " m³/h · "
                                + pump.requiredHeadM.formatted(.number.precision(.fractionLength(0...2)))
                                + " m"
                        )
                    }
                    Label(
                        pump.selectionCurrent ? "Pumpenauswahl aktuell" : "Pumpenauswahl neu bewerten",
                        systemImage: pump.selectionCurrent ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(pump.selectionCurrent ? .green : .orange)
                } header: {
                    Text("Pumpe")
                }
            }

            Section("Heizflächenkreise") {
                ForEach(current.rows) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.roomName + " · " + row.surfaceName)
                            .font(.headline)
                        Text(row.floorName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Text("Q " + (row.targetVolumeFlowLPH.map { $0.formatted(.number.precision(.fractionLength(0))) + " l/h" } ?? "offen"))
                            Text("Δp " + (row.completeCircuitPressureLossKPa.map { $0.formatted(.number.precision(.fractionLength(0...2))) + " kPa" } ?? "offen"))
                        }
                        .font(.caption)

                        ForEach(row.thermostatSettings) { valve in
                            valveLine(prefix: "TV", valve: valve)
                        }
                        ForEach(row.returnSettings) { valve in
                            valveLine(prefix: "RL", valve: valve)
                        }

                        if !row.missingNotes.isEmpty {
                            Label(row.missingNotes.joined(separator: " · "), systemImage: "exclamationmark.triangle")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Button {
                    prepareExport()
                } label: {
                    Label("Einstellliste als PDF exportieren", systemImage: "square.and.arrow.up")
                }
                if let exportMessage {
                    Text(exportMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("PDF")
            } footer: {
                Text("Der Export ist eine kompakte technische Arbeitsliste und kein nachgebautes VdZ-/Verfahren-B-Formular. Nach erfolgreichem Export wird der verwendete Snapshot separat versioniert archiviert.")
            }

            Section {
                LabeledContent("Archivierte Einstelllisten", value: "\(archiveEntries.count) / 10")
                ForEach(Array(archiveEntries.prefix(5).enumerated()), id: \.offset) { _, item in
                    Text(item.generatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
            } header: {
                Text("Archiv")
            }
        }
        .navigationTitle("Einstellliste")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reloadArchive)
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .pdf,
            defaultFilename: filename
        ) { result in
            handleExport(result)
        }
    }

    @ViewBuilder
    private func valveLine(prefix: String, valve: HeizBalanceAdjustmentListSnapshot.ValveEntry) -> some View {
        let setting = valve.heldSetting.map { "Einstellung " + $0 } ?? "nicht festgehalten"
        Label(
            "\(prefix) \(valve.componentName): \(setting)",
            systemImage: valve.selectionCurrent == true
                ? "checkmark.circle.fill"
                : (valve.selectionCurrent == false ? "exclamationmark.triangle.fill" : "circle.dashed")
        )
        .font(.caption)
        .foregroundStyle(
            valve.selectionCurrent == true
                ? Color.green
                : (valve.selectionCurrent == false ? Color.orange : Color.secondary)
        )
    }

    private func prepareExport() {
        let generatedAt = Date()
        let fresh = HeizBalanceAdjustmentListSnapshot.make(
            project: project,
            valveSelections: valveSelectionStore.selections(projectID: project.id),
            pumpSelection: pumpSelectionStore.selection(projectID: project.id),
            generatedAt: generatedAt
        )
        pendingSnapshot = fresh
        exportDocument = HeizBalancePDFDocument(data: HeizBalanceAdjustmentListPDFRenderer.render(fresh))
        exportMessage = nil
        showingExporter = true
    }

    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            guard let pendingSnapshot else {
                exportMessage = "PDF exportiert; Snapshot war nicht mehr verfügbar."
                return
            }
            do {
                _ = try archiveStore.archive(pendingSnapshot)
                self.pendingSnapshot = nil
                reloadArchive()
                exportMessage = "Einstellliste exportiert und Snapshot archiviert."
            } catch {
                self.pendingSnapshot = nil
                exportMessage = "PDF exportiert; Snapshot-Archivierung fehlgeschlagen: \(error.localizedDescription)"
            }
        case .failure(let error):
            pendingSnapshot = nil
            exportMessage = "PDF-Export fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func reloadArchive() {
        do {
            archiveEntries = try archiveStore.entries(projectID: project.id)
        } catch {
            archiveEntries = []
            if exportMessage == nil {
                exportMessage = "Einstelllisten-Archiv konnte nicht gelesen werden: \(error.localizedDescription)"
            }
        }
    }
}
