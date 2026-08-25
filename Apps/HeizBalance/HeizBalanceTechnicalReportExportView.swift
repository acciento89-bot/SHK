import SwiftUI
import UniformTypeIdentifiers

struct HeizBalanceTechnicalReportExportView: View {
    let project: HeizBalanceProject

    @State private var exportDocument = HeizBalancePDFDocument(data: Data())
    @State private var pendingSnapshot: HeizBalanceTechnicalReportSnapshot?
    @State private var archiveEntries: [HeizBalanceReportArchiveStore.ArchiveEntry] = []
    @State private var showingExporter = false
    @State private var exportMessage: String?

    private var archiveStore: HeizBalanceReportArchiveStore {
        HeizBalanceReportArchiveStore()
    }

    private var snapshot: HeizBalanceTechnicalReportSnapshot {
        project.technicalReportSnapshot()
    }

    private var roomCount: Int {
        snapshot.floors.reduce(0) { $0 + $1.rooms.count }
    }

    private var heatingSurfaceCount: Int {
        snapshot.floors.reduce(0) { floorTotal, floor in
            floorTotal + floor.rooms.reduce(0) { $0 + $1.heatingSurfaces.count }
        }
    }

    private var filename: String {
        let raw = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = raw.isEmpty ? "HeizBalance" : raw
        let forbidden = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let cleaned = base.components(separatedBy: forbidden).joined(separator: "-")
        return "HeizBalance-\(cleaned)-Technischer-Bericht"
    }

    var body: some View {
        List {
            Section {
                Label("Technische Vorbereitung", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
                Text(snapshot.status.notice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Berichtsstatus")
            }

            Section("Projektinhalt") {
                LabeledContent("Projekt") {
                    Text(snapshot.project.name)
                }
                LabeledContent("Geschosse") {
                    Text("\(snapshot.floors.count)")
                }
                LabeledContent("Räume") {
                    Text("\(roomCount)")
                }
                LabeledContent("Heizflächen") {
                    Text("\(heatingSurfaceCount)")
                }
                LabeledContent("Berichtsschema") {
                    Text(snapshot.schema)
                }
            }

            Section {
                if let system = snapshot.hydraulicSystem {
                    LabeledContent("Hydraulikkreise") {
                        Text("\(system.circuitCount)")
                    }
                    LabeledContent("Volumenstrom vollständig") {
                        Text("\(system.knownFlowCircuitCount) / \(system.circuitCount)")
                    }
                    LabeledContent("Kreis-Δp vollständig") {
                        Text("\(system.completePressureCircuitCount) / \(system.circuitCount)")
                    }
                    if let flow = system.designTotalVolumeFlowLPH {
                        LabeledContent("Gesamtvolumenstrom") {
                            Text(flow.formatted(.number.precision(.fractionLength(0))) + " l/h")
                        }
                    }
                    if let pressure = system.designNetworkPressureLossKPa {
                        LabeledContent("Netz-Δp") {
                            Text(pressure.formatted(.number.precision(.fractionLength(0...2))) + " kPa")
                        }
                    }

                    if system.pumpOperatingPointReady {
                        Label("Technischer Betriebspunkt vollständig", systemImage: "checkmark.circle")
                            .font(.caption)
                    } else {
                        Label("Technischer Betriebspunkt noch unvollständig", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } else {
                    Text("Noch keine hydraulische Systemauswertung im Bericht verfügbar.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Hydraulik")
            } footer: {
                Text("Ein unvollständiges Projekt darf trotzdem als technischer Arbeitsstand exportiert werden. Fehlende Werte bleiben im Bericht als fehlend erkennbar und werden nicht durch Annahmen ersetzt.")
            }

            Section {
                Button {
                    preparePDFExport()
                } label: {
                    Label("PDF-Bericht exportieren", systemImage: "square.and.arrow.up")
                }

                if let exportMessage {
                    Text(exportMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Export")
            } footer: {
                Text("Das PDF enthält ausschließlich den aktuellen technischen Projektstand. Nach einem erfolgreichen Export wird exakt der dafür verwendete `technical-report-v1`-Snapshot lokal archiviert.")
            }

            Section {
                LabeledContent("Archivierte Exporte") {
                    Text("\(archiveEntries.count) / 10")
                }

                if archiveEntries.isEmpty {
                    Text("Noch kein erfolgreich exportierter Bericht archiviert.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(archiveEntries.prefix(5)) { entry in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(
                                entry.snapshot.generatedAt.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .font(.subheadline.weight(.semibold))

                            Text(entry.snapshot.schema)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let system = entry.snapshot.hydraulicSystem {
                                Text(
                                    "Kreise \(system.completePressureCircuitCount)/\(system.circuitCount) vollständig · Betriebspunkt \(system.pumpOperatingPointReady ? "vollständig" : "unvollständig")"
                                )
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    if archiveEntries.count > 5 {
                        Text("Weitere \(archiveEntries.count - 5) Snapshots sind lokal archiviert.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Berichtsarchiv")
            } footer: {
                Text("Das Archiv speichert die letzten 10 erfolgreich exportierten Berichtssnapshots je Projekt als JSON in Application Support. Die PDF-Datei selbst bleibt am vom Benutzer gewählten Exportort.")
            }
        }
        .navigationTitle("Technischer Bericht")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reloadArchive()
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .pdf,
            defaultFilename: filename
        ) { result in
            handleExportResult(result)
        }
    }

    private func preparePDFExport() {
        let freshSnapshot = project.technicalReportSnapshot(generatedAt: Date())
        pendingSnapshot = freshSnapshot
        exportDocument = HeizBalancePDFDocument(
            data: HeizBalanceTechnicalReportPDFRenderer.render(freshSnapshot)
        )
        exportMessage = nil
        showingExporter = true
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            guard let pendingSnapshot else {
                exportMessage = "PDF-Bericht exportiert; Snapshot war nicht mehr verfügbar."
                return
            }

            do {
                _ = try archiveStore.archive(pendingSnapshot)
                self.pendingSnapshot = nil
                reloadArchive()
                exportMessage = "PDF-Bericht exportiert und Berichtssnapshot archiviert."
            } catch {
                self.pendingSnapshot = nil
                exportMessage = "PDF-Bericht exportiert; Snapshot-Archivierung fehlgeschlagen: \(error.localizedDescription)"
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
                exportMessage = "Berichtsarchiv konnte nicht gelesen werden: \(error.localizedDescription)"
            }
        }
    }
}

struct HeizBalancePDFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
