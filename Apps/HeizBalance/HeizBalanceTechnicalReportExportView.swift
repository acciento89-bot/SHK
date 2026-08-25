import SwiftUI
import UniformTypeIdentifiers

struct HeizBalanceTechnicalReportExportView: View {
    let project: HeizBalanceProject

    @Environment(HeizBalancePumpDatasetStore.self) private var pumpDatasetStore

    @State private var exportDocument = HeizBalancePDFDocument(data: Data())
    @State private var pendingSnapshot: HeizBalanceTechnicalReportSnapshot?
    @State private var pendingLowTemperatureSnapshot: HeizBalanceLowTemperatureReportSnapshot?
    @State private var pendingTemperatureScenarioSnapshot: HeizBalanceTemperatureScenarioReportSnapshot?
    @State private var pendingRadiatorReplacementSnapshot: HeizBalanceRadiatorReplacementReportSnapshot?
    @State private var pendingPumpCurveSnapshot: HeizBalancePumpCurveReportSnapshot?
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

    private var radiatorReplacementArchiveStore: HeizBalanceRadiatorReplacementReportArchiveStore {
        HeizBalanceRadiatorReplacementReportArchiveStore()
    }

    private var pumpCurveArchiveStore: HeizBalancePumpCurveReportArchiveStore {
        HeizBalancePumpCurveReportArchiveStore()
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

    private var radiatorReplacementSnapshot: HeizBalanceRadiatorReplacementReportSnapshot {
        project.radiatorReplacementReportSnapshot()
    }

    private var pumpCurveSnapshot: HeizBalancePumpCurveReportSnapshot {
        project.pumpCurveReportSnapshot(datasets: pumpDatasetStore.datasets)
    }

    private var pumpCurveCount: Int {
        pumpCurveSnapshot.datasets.reduce(0) { datasetTotal, dataset in
            datasetTotal + dataset.products.reduce(0) { productTotal, product in
                productTotal + product.curves.count
            }
        }
    }

    private var evaluatedPumpCurveCount: Int {
        pumpCurveSnapshot.datasets.reduce(0) { datasetTotal, dataset in
            datasetTotal + dataset.products.reduce(0) { productTotal, product in
                productTotal + product.curves.filter { $0.status == .evaluated }.count
            }
        }
    }

    private var sufficientPumpCurveCount: Int {
        pumpCurveSnapshot.datasets.reduce(0) { datasetTotal, dataset in
            datasetTotal + dataset.products.reduce(0) { productTotal, product in
                productTotal + product.curves.filter { $0.evaluation?.technicallySufficient == true }.count
            }
        }
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
                Text("Der Szenario-Bericht dokumentiert Sanierungsziel, Projekt-Temperaturen und Vergleichsszenarien. Für zu kleine Heizflächen werden erforderliche ΔT50-Nennleistung und Nennleistungsfaktor ausgegeben.")
            }

            Section {
                LabeledContent("Festgehaltene Auswahlen") {
                    Text("\(radiatorReplacementSnapshot.entries.count)")
                }

                if radiatorReplacementSnapshot.entries.isEmpty {
                    Text("Noch kein Katalogkandidat wurde ausdrücklich als Heizkörper-Auswahl festgehalten.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(radiatorReplacementSnapshot.entries) { entry in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.roomName + " · " + entry.surfaceName)
                                .font(.subheadline.weight(.semibold))
                            Text(entry.selection.displayName)
                                .font(.caption)
                            Text(entry.selection.datasetName + " · " + entry.selection.datasetVersion)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if !entry.currentTargetMatchesSelection {
                                Label("Sanierungsziel wurde seit der Auswahl geändert", systemImage: "exclamationmark.triangle")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            } header: {
                Text("Heizkörper-Auswahl")
            } footer: {
                Text("Nur ausdrücklich festgehaltene Benutzerauswahlen werden dokumentiert. Hersteller, Datensatzstand, Quelle, Produktwerte und die damalige Zieltemperatur werden als eigener Snapshot eingefroren.")
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
                LabeledContent("Importierte Pumpenkataloge") {
                    Text("\(pumpCurveSnapshot.datasets.count)")
                }
                LabeledContent("Dokumentierte Kennlinien") {
                    Text("\(pumpCurveCount)")
                }

                if let operatingPoint = pumpCurveSnapshot.operatingPoint {
                    LabeledContent("Projekt-Betriebspunkt") {
                        Text(
                            operatingPoint.volumeFlowM3H.formatted(.number.precision(.fractionLength(0...3)))
                                + " m³/h · "
                                + operatingPoint.requiredHeadM.formatted(.number.precision(.fractionLength(0...2)))
                                + " m"
                        )
                        .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Kennlinien auswertbar") {
                        Text("\(evaluatedPumpCurveCount) / \(pumpCurveCount)")
                    }
                    LabeledContent("Hydraulisch ausreichend") {
                        Text("\(sufficientPumpCurveCount)")
                    }
                } else {
                    Label("Pumpenkennlinien können ohne vollständigen Projekt-Betriebspunkt noch nicht bewertet werden.", systemImage: "circle.dashed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Pumpenkennlinien")
            } footer: {
                Text("Der Pumpenbericht verwendet \(HeizBalancePumpCurveOperatingPointCalculator.profileVersion): exakt dokumentierte Punkte oder lineare Zwischenwerte innerhalb des Kennlinienbereichs. Keine Extrapolation und keine automatische Pumpenauswahl.")
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
                Text("Das gemeinsame PDF enthält Hauptbericht, Niedertemperatur-, Szenario-, Heizkörper-Auswahl- und Pumpenkennlinien-Supplement. Nach erfolgreichem Export werden alle fünf versionierten Snapshots mit demselben Zeitstempel lokal archiviert.")
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

                            Text(entry.snapshot.schema + " + technical-low-temperature-v1 + technical-temperature-scenarios-v1 + technical-radiator-replacements-v1 + technical-pump-curves-v1")
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
                Text("Das Archiv speichert die letzten 10 erfolgreichen Exportstände je Projekt. Alle fünf Berichtssnapshots werden getrennt versioniert; die PDF-Datei bleibt am vom Benutzer gewählten Exportort.")
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
        let freshRadiatorReplacementSnapshot = project.radiatorReplacementReportSnapshot(
            generatedAt: generatedAt
        )
        let freshPumpCurveSnapshot = project.pumpCurveReportSnapshot(
            datasets: pumpDatasetStore.datasets,
            generatedAt: generatedAt
        )

        pendingSnapshot = freshSnapshot
        pendingLowTemperatureSnapshot = freshLowTemperatureSnapshot
        pendingTemperatureScenarioSnapshot = freshTemperatureScenarioSnapshot
        pendingRadiatorReplacementSnapshot = freshRadiatorReplacementSnapshot
        pendingPumpCurveSnapshot = freshPumpCurveSnapshot

        let mainReport = HeizBalanceTechnicalReportPDFRenderer.render(freshSnapshot)
        let lowTemperatureReport = HeizBalanceLowTemperatureReportPDFRenderer.render(
            freshLowTemperatureSnapshot
        )
        let temperatureScenarioReport = HeizBalanceTemperatureScenarioReportPDFRenderer.render(
            freshTemperatureScenarioSnapshot
        )
        let radiatorReplacementReport = HeizBalanceRadiatorReplacementReportPDFRenderer.render(
            freshRadiatorReplacementSnapshot
        )
        let pumpCurveReport = HeizBalancePumpCurveReportPDFRenderer.render(
            freshPumpCurveSnapshot
        )
        let combinedReport = HeizBalancePDFMerger.merge([
            mainReport,
            lowTemperatureReport,
            temperatureScenarioReport,
            radiatorReplacementReport,
            pumpCurveReport
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
                  let pendingTemperatureScenarioSnapshot,
                  let pendingRadiatorReplacementSnapshot,
                  let pendingPumpCurveSnapshot else {
                exportMessage = "PDF-Bericht exportiert; Berichtssnapshots waren nicht mehr vollständig verfügbar."
                clearPendingSnapshots()
                return
            }

            do {
                _ = try archiveStore.archive(pendingSnapshot)
                _ = try lowTemperatureArchiveStore.archive(pendingLowTemperatureSnapshot)
                _ = try temperatureScenarioArchiveStore.archive(pendingTemperatureScenarioSnapshot)
                _ = try radiatorReplacementArchiveStore.archive(pendingRadiatorReplacementSnapshot)
                _ = try pumpCurveArchiveStore.archive(pendingPumpCurveSnapshot)
                clearPendingSnapshots()
                reloadArchive()
                exportMessage = "PDF-Bericht exportiert; alle fünf versionierten Snapshots archiviert."
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
        pendingRadiatorReplacementSnapshot = nil
        pendingPumpCurveSnapshot = nil
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
