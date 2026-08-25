import SwiftUI
import UniformTypeIdentifiers

struct HeizBalanceTechnicalReportExportView: View {
    let project: HeizBalanceProject

    @State private var exportDocument = HeizBalancePDFDocument(data: Data())
    @State private var pendingSnapshot: HeizBalanceTechnicalReportSnapshot?
    @State private var pendingLowTemperatureSnapshot: HeizBalanceLowTemperatureReportSnapshot?
    @State private var pendingTemperatureScenarioSnapshot: HeizBalanceTemperatureScenarioReportSnapshot?
    @State private var archiveEntries: [HeizBalanceReportArchiveStore.ArchiveEntry] = []
    @State private var showingExporter = false
    @State private var exportMessage: String?

    private var archiveStore: HeizBalanceReportArchiveStore {
        HeizBalanceReportArchiveStore()
    }

    private var lowTemperatureArchiveStore: HeizBalanceLowTemperatureReportArchiveStore {
        HeizBalanceLowTemperatureReportArchiveStore()
    }

    private var temperatureScenarioArchiveStore: HeizBalanceTemperatureScenarioReportArchiveStore {
        HeizBalanceTemperatureScenarioReportArchiveStore()
    }

    private var snapshot: HeizBalanceTechnicalReportSnapshot {
        project.technicalReportSnapshot()
    }

    private var lowTemperatureState: HeizBalanceLowTemperatureProjectState {
        project.lowTemperatureProjectState(
            comparisonFlowTemperatureC: project.designFlowTemperatureC
        )
    }

    private var temperatureScenarioSnapshot: HeizBalanceTemperatureScenarioReportSnapshot {
        project.temperatureScenarioReportSnapshot()
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
                if let spread = lowTemperatureState.waterTemperatureDifferenceK {
                    LabeledContent("Spreizung") {
                        Text(spread.formatted(.number.precision(.fractionLength(0...1))) + " K")
                    }
                    LabeledContent("Heizflächen auswertbar") {
                        Text("\(lowTemperatureState.evaluableSurfaceCount) / \(lowTemperatureState.entries.count)")
                    }

                    if let minimumFlow = lowTemperatureState.minimumSystemFlowTemperatureC,
                       let minimumReturn = lowTemperatureState.minimumSystemReturnTemperatureC {
                        LabeledContent("Minimaler System-Vorlauf") {
                            Text(minimumFlow.formatted(.number.precision(.fractionLength(1))) + " °C")
                                .fontWeight(.semibold)
                        }
                        LabeledContent("Zugehöriger Rücklauf") {
                            Text(minimumReturn.formatted(.number.precision(.fractionLength(1))) + " °C")
                        }
                        LabeledContent("Begrenzende Heizfläche") {
                            Text(lowTemperatureState.limitingEntry?.displayName ?? "—")
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if let comparisonSufficient = lowTemperatureState.comparisonSufficient,
                       let designFlow = project.designFlowTemperatureC,
                       let designReturn = project.designReturnTemperatureC {
                        if comparisonSufficient {
                            Label(
                                "\(designFlow.formatted(.number.precision(.fractionLength(0...1)))) / \(designReturn.formatted(.number.precision(.fractionLength(0...1)))) °C deckt alle zugeordneten Heizflächenleistungen.",
                                systemImage: "checkmark.circle"
                            )
                            .font(.caption)
                        } else {
                            Label(
                                "\(designFlow.formatted(.number.precision(.fractionLength(0...1)))) / \(designReturn.formatted(.number.precision(.fractionLength(0...1)))) °C reicht für mindestens eine Heizfläche nicht aus.",
                                systemImage: "exclamationmark.triangle"
                            )
                            .font(.caption)
                            .foregroundStyle(.orange)
                        }
                    } else if !lowTemperatureState.entries.isEmpty {
                        Label("Niedertemperatur-Systemwert noch unvollständig.", systemImage: "circle.dashed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Für den Niedertemperatur-Check fehlen gültige Projekt-Systemtemperaturen.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Niedertemperatur")
            } footer: {
                Text("Der PDF-Export enthält einen eigenen versionierten Niedertemperatur-Snapshot. Bewertet wird die Heizflächenleistung bei konstanter Projekt-Wasserspreizung; dies ist keine Wärmepumpenauslegung.")
            }

            Section {
                if temperatureScenarioSnapshot.scenarios.isEmpty {
                    Text("Keine Temperaturszenarien auswertbar.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(temperatureScenarioSnapshot.scenarios) { scenario in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scenario.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(
                                    scenario.flowTemperatureC.formatted(.number.precision(.fractionLength(0...1)))
                                        + " / "
                                        + scenario.returnTemperatureC.formatted(.number.precision(.fractionLength(0...1)))
                                        + " °C"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if scenario.coverageComplete {
                                Text("\(scenario.sufficientSurfaceCount)/\(scenario.surfaceCount)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(scenario.allSufficient ? .green : .orange)
                            } else {
                                Text("offen")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Temperatur-Szenarien")
            } footer: {
                Text("Der Szenario-Bericht dokumentiert Projekt-Temperaturen sowie 50/40, 45/35, 45/40 und 40/35 °C. Für zu kleine Heizflächen werden erforderliche ΔT50-Nennleistung und Nennleistungsfaktor ausgegeben; konkrete Ersatzmodelle erfordern dokumentierte Herstellerdaten.")
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
                Text("Das gemeinsame PDF enthält Hauptbericht, Niedertemperatur-Supplement und Szenario-Matrix. Nach erfolgreichem Export werden alle drei versionierten Snapshots mit demselben Zeitstempel lokal archiviert.")
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

                            Text(entry.snapshot.schema + " + technical-low-temperature-v1 + technical-temperature-scenarios-v1")
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
                Text("Das Archiv speichert die letzten 10 erfolgreichen Exportstände je Projekt. Hauptbericht, Niedertemperatur- und Szenario-Snapshot werden getrennt versioniert; die PDF-Datei bleibt am vom Benutzer gewählten Exportort.")
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
        let generatedAt = Date()
        let freshSnapshot = project.technicalReportSnapshot(generatedAt: generatedAt)
        let freshLowTemperatureSnapshot = project.lowTemperatureReportSnapshot(
            generatedAt: generatedAt,
            comparisonFlowTemperatureC: project.designFlowTemperatureC
        )
        let freshTemperatureScenarioSnapshot = project.temperatureScenarioReportSnapshot(
            generatedAt: generatedAt
        )

        pendingSnapshot = freshSnapshot
        pendingLowTemperatureSnapshot = freshLowTemperatureSnapshot
        pendingTemperatureScenarioSnapshot = freshTemperatureScenarioSnapshot

        let mainReport = HeizBalanceTechnicalReportPDFRenderer.render(freshSnapshot)
        let lowTemperatureReport = HeizBalanceLowTemperatureReportPDFRenderer.render(
            freshLowTemperatureSnapshot
        )
        let temperatureScenarioReport = HeizBalanceTemperatureScenarioReportPDFRenderer.render(
            freshTemperatureScenarioSnapshot
        )
        let combinedReport = HeizBalancePDFMerger.merge([
            mainReport,
            lowTemperatureReport,
            temperatureScenarioReport
        ]) ?? mainReport

        exportDocument = HeizBalancePDFDocument(data: combinedReport)
        exportMessage = nil
        showingExporter = true
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            guard let pendingSnapshot,
                  let pendingLowTemperatureSnapshot,
                  let pendingTemperatureScenarioSnapshot else {
                exportMessage = "PDF-Bericht exportiert; Berichtssnapshots waren nicht mehr vollständig verfügbar."
                clearPendingSnapshots()
                return
            }

            do {
                _ = try archiveStore.archive(pendingSnapshot)
                _ = try lowTemperatureArchiveStore.archive(pendingLowTemperatureSnapshot)
                _ = try temperatureScenarioArchiveStore.archive(pendingTemperatureScenarioSnapshot)
                clearPendingSnapshots()
                reloadArchive()
                exportMessage = "PDF-Bericht exportiert; Haupt-, Niedertemperatur- und Szenario-Snapshot archiviert."
            } catch {
                clearPendingSnapshots()
                exportMessage = "PDF-Bericht exportiert; Snapshot-Archivierung fehlgeschlagen: \(error.localizedDescription)"
            }

        case .failure(let error):
            clearPendingSnapshots()
            exportMessage = "PDF-Export fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func clearPendingSnapshots() {
        pendingSnapshot = nil
        pendingLowTemperatureSnapshot = nil
        pendingTemperatureScenarioSnapshot = nil
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
