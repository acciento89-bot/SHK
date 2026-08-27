import SwiftUI
import UniformTypeIdentifiers

struct HeizBalanceTechnicalReportExportView: View {
    let project: HeizBalanceProject

    @Environment(HeizBalancePumpDatasetStore.self) private var pumpDatasetStore

    @State private var exportDocument = HeizBalancePDFDocument(data: Data())
    @State private var pendingSnapshot: HeizBalanceTechnicalReportSnapshot?
    @State private var pendingHydraulicNetworkSnapshot: HeizBalanceHydraulicNetworkReportSnapshot?
    @State private var pendingLowTemperatureSnapshot: HeizBalanceLowTemperatureReportSnapshot?
    @State private var pendingTemperatureScenarioSnapshot: HeizBalanceTemperatureScenarioReportSnapshot?
    @State private var pendingRadiatorReplacementSnapshot: HeizBalanceRadiatorReplacementReportSnapshot?
    @State private var pendingPumpCurveSnapshot: HeizBalancePumpCurveReportSnapshot?
    @State private var archiveEntries: [HeizBalanceReportArchiveStore.ArchiveEntry] = []
    @State private var showingExporter = false
    @State private var exportMessage: String?

    private var archiveStore: HeizBalanceReportArchiveStore { HeizBalanceReportArchiveStore() }
    private var networkArchiveStore: HeizBalanceHydraulicNetworkReportArchiveStore { HeizBalanceHydraulicNetworkReportArchiveStore() }
    private var lowTemperatureArchiveStore: HeizBalanceLowTemperatureReportArchiveStore { HeizBalanceLowTemperatureReportArchiveStore() }
    private var temperatureScenarioArchiveStore: HeizBalanceTemperatureScenarioReportArchiveStore { HeizBalanceTemperatureScenarioReportArchiveStore() }
    private var radiatorReplacementArchiveStore: HeizBalanceRadiatorReplacementReportArchiveStore { HeizBalanceRadiatorReplacementReportArchiveStore() }
    private var pumpCurveArchiveStore: HeizBalancePumpCurveReportArchiveStore { HeizBalancePumpCurveReportArchiveStore() }

    private var snapshot: HeizBalanceTechnicalReportSnapshot { project.technicalReportSnapshot() }
    private var networkSnapshot: HeizBalanceHydraulicNetworkReportSnapshot { .make(project: project) }
    private var lowTemperatureState: HeizBalanceLowTemperatureProjectState {
        project.lowTemperatureProjectState(comparisonFlowTemperatureC: project.designFlowTemperatureC)
    }
    private var temperatureScenarioSnapshot: HeizBalanceTemperatureScenarioReportSnapshot { project.temperatureScenarioReportSnapshot() }
    private var radiatorReplacementSnapshot: HeizBalanceRadiatorReplacementReportSnapshot { project.radiatorReplacementReportSnapshot() }
    private var pumpCurveSnapshot: HeizBalancePumpCurveReportSnapshot { project.pumpCurveReportSnapshot(datasets: pumpDatasetStore.datasets) }

    private var pumpCurveCount: Int {
        pumpCurveSnapshot.datasets.reduce(0) { total, dataset in
            total + dataset.products.reduce(0) { $0 + $1.curves.count }
        }
    }

    private var evaluatedPumpCurveCount: Int {
        pumpCurveSnapshot.datasets.reduce(0) { total, dataset in
            total + dataset.products.reduce(0) { $0 + $1.curves.filter { $0.status == .evaluated }.count }
        }
    }

    private var sufficientPumpCurveCount: Int {
        pumpCurveSnapshot.datasets.reduce(0) { total, dataset in
            total + dataset.products.reduce(0) { $0 + $1.curves.filter { $0.evaluation?.technicallySufficient == true }.count }
        }
    }

    private var roomCount: Int { snapshot.floors.reduce(0) { $0 + $1.rooms.count } }
    private var heatingSurfaceCount: Int {
        snapshot.floors.reduce(0) { floorTotal, floor in
            floorTotal + floor.rooms.reduce(0) { $0 + $1.heatingSurfaces.count }
        }
    }

    private var filename: String {
        let raw = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = raw.isEmpty ? "HeizBalance" : raw
        let forbidden = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        return "HeizBalance-\(base.components(separatedBy: forbidden).joined(separator: "-"))-Technischer-Bericht"
    }

    var body: some View {
        List {
            Section {
                Label("Technische Vorbereitung", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
                Text(snapshot.status.notice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: { Text("Berichtsstatus") }

            Section("Projektinhalt") {
                LabeledContent("Projekt", value: snapshot.project.name)
                LabeledContent("Geschosse", value: "\(snapshot.floors.count)")
                LabeledContent("Räume", value: "\(roomCount)")
                LabeledContent("Heizflächen", value: "\(heatingSurfaceCount)")
                LabeledContent("Berichtsschema", value: snapshot.schema)
            }

            Section {
                let network = networkSnapshot
                LabeledContent("Netzsegmente", value: "\(network.segments.count)")
                LabeledContent("Verbraucher zugeordnet", value: "\(network.assignedConsumerCount) / \(network.consumerCount)")
                LabeledContent("Verknüpfte Rohrabschnitte", value: "\(network.linkedPipes.count)")
                if !network.networkValid && !network.segments.isEmpty {
                    Label("Netzbaum ungültig", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                } else if network.staleLinkedPipeCount > 0 {
                    Label("\(network.staleLinkedPipeCount) Netzbaum-Q neu synchronisieren", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                } else if !network.linkedPipes.isEmpty {
                    Label("Netzbaum-Verknüpfungen aktuell", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } header: { Text("Hydraulischer Netzbaum") }
              footer: { Text("Der Netzbaum-Snapshot dokumentiert automatische Summenströme und den Synchronisationsstatus gemeinsamer Rohrabschnitte.") }

            Section {
                if let spread = lowTemperatureState.waterTemperatureDifferenceK {
                    LabeledContent("Spreizung") { Text(spread.formatted(.number.precision(.fractionLength(0...1))) + " K") }
                    LabeledContent("Heizflächen auswertbar", value: "\(lowTemperatureState.evaluableSurfaceCount) / \(lowTemperatureState.entries.count)")
                    if let minimumFlow = lowTemperatureState.minimumSystemFlowTemperatureC,
                       let minimumReturn = lowTemperatureState.minimumSystemReturnTemperatureC {
                        LabeledContent("Minimaler System-Vorlauf") { Text(minimumFlow.formatted(.number.precision(.fractionLength(1))) + " °C").fontWeight(.semibold) }
                        LabeledContent("Zugehöriger Rücklauf") { Text(minimumReturn.formatted(.number.precision(.fractionLength(1))) + " °C") }
                        LabeledContent("Begrenzende Heizfläche") { Text(lowTemperatureState.limitingEntry?.displayName ?? "—").multilineTextAlignment(.trailing) }
                    }
                    if let sufficient = lowTemperatureState.comparisonSufficient,
                       let flow = project.designFlowTemperatureC,
                       let ret = project.designReturnTemperatureC {
                        Label(
                            "\(flow.formatted(.number.precision(.fractionLength(0...1)))) / \(ret.formatted(.number.precision(.fractionLength(0...1)))) °C " + (sufficient ? "deckt alle zugeordneten Heizflächenleistungen." : "reicht für mindestens eine Heizfläche nicht aus."),
                            systemImage: sufficient ? "checkmark.circle" : "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(sufficient ? Color.primary : Color.orange)
                    }
                } else {
                    Text("Für den Niedertemperatur-Check fehlen gültige Projekt-Systemtemperaturen.")
                        .foregroundStyle(.secondary)
                }
            } header: { Text("Niedertemperatur") }
              footer: { Text("Bewertet wird die Heizflächenleistung bei konstanter Projekt-Wasserspreizung; dies ist keine Wärmepumpenauslegung.") }

            Section {
                if temperatureScenarioSnapshot.scenarios.isEmpty {
                    Text("Keine Temperaturszenarien auswertbar.").foregroundStyle(.secondary)
                } else {
                    ForEach(temperatureScenarioSnapshot.scenarios) { scenario in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scenario.title).font(.subheadline.weight(.semibold))
                                Text("\(scenario.flowTemperatureC.formatted(.number.precision(.fractionLength(0...1)))) / \(scenario.returnTemperatureC.formatted(.number.precision(.fractionLength(0...1)))) °C")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(scenario.coverageComplete ? "\(scenario.sufficientSurfaceCount)/\(scenario.surfaceCount)" : "offen")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(scenario.coverageComplete ? (scenario.allSufficient ? Color.green : Color.orange) : Color.secondary)
                        }
                    }
                }
            } header: { Text("Temperatur-Szenarien") }

            Section {
                LabeledContent("Festgehaltene Auswahlen", value: "\(radiatorReplacementSnapshot.entries.count)")
                if radiatorReplacementSnapshot.entries.isEmpty {
                    Text("Noch kein Katalogkandidat wurde ausdrücklich als Heizkörper-Auswahl festgehalten.").foregroundStyle(.secondary)
                } else {
                    ForEach(radiatorReplacementSnapshot.entries) { entry in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.roomName + " · " + entry.surfaceName).font(.subheadline.weight(.semibold))
                            Text(entry.selection.displayName).font(.caption)
                            if !entry.currentTargetMatchesSelection {
                                Label("Sanierungsziel wurde seit der Auswahl geändert", systemImage: "exclamationmark.triangle")
                                    .font(.caption2).foregroundStyle(.orange)
                            }
                        }
                    }
                }
            } header: { Text("Heizkörper-Auswahl") }

            Section {
                if let system = snapshot.hydraulicSystem {
                    LabeledContent("Hydraulikkreise", value: "\(system.circuitCount)")
                    LabeledContent("Volumenstrom vollständig", value: "\(system.knownFlowCircuitCount) / \(system.circuitCount)")
                    LabeledContent("Kreis-Δp vollständig", value: "\(system.completePressureCircuitCount) / \(system.circuitCount)")
                    if let flow = system.designTotalVolumeFlowLPH {
                        LabeledContent("Gesamtvolumenstrom") { Text(flow.formatted(.number.precision(.fractionLength(0))) + " l/h") }
                    }
                    if let pressure = system.designNetworkPressureLossKPa {
                        LabeledContent("Netz-Δp") { Text(pressure.formatted(.number.precision(.fractionLength(0...2))) + " kPa") }
                    }
                    Label(system.pumpOperatingPointReady ? "Technischer Betriebspunkt vollständig" : "Technischer Betriebspunkt noch unvollständig",
                          systemImage: system.pumpOperatingPointReady ? "checkmark.circle" : "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(system.pumpOperatingPointReady ? Color.primary : Color.orange)
                } else {
                    Text("Noch keine hydraulische Systemauswertung im Bericht verfügbar.").foregroundStyle(.secondary)
                }
            } header: { Text("Hydraulik") }

            Section {
                LabeledContent("Importierte Pumpenkataloge", value: "\(pumpCurveSnapshot.datasets.count)")
                LabeledContent("Dokumentierte Kennlinien", value: "\(pumpCurveCount)")
                if let operatingPoint = pumpCurveSnapshot.operatingPoint {
                    LabeledContent("Projekt-Betriebspunkt") {
                        Text("\(operatingPoint.volumeFlowM3H.formatted(.number.precision(.fractionLength(0...3)))) m³/h · \(operatingPoint.requiredHeadM.formatted(.number.precision(.fractionLength(0...2)))) m")
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Kennlinien auswertbar", value: "\(evaluatedPumpCurveCount) / \(pumpCurveCount)")
                    LabeledContent("Hydraulisch ausreichend", value: "\(sufficientPumpCurveCount)")
                } else {
                    Label("Pumpenkennlinien können ohne vollständigen Projekt-Betriebspunkt noch nicht bewertet werden.", systemImage: "circle.dashed")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } header: { Text("Pumpenkennlinien") }

            Section {
                Button { preparePDFExport() } label: {
                    Label("PDF-Bericht exportieren", systemImage: "square.and.arrow.up")
                }
                if let exportMessage { Text(exportMessage).font(.caption).foregroundStyle(.secondary) }
            } header: { Text("Export") }
              footer: { Text("Das gemeinsame PDF enthält Hauptbericht, Netzbaum-, Niedertemperatur-, Szenario-, Heizkörper-Auswahl- und Pumpenkennlinien-Supplement. Alle sechs Snapshots erhalten denselben Zeitstempel.") }

            Section {
                LabeledContent("Archivierte Exporte", value: "\(archiveEntries.count) / 10")
                ForEach(archiveEntries.prefix(5)) { entry in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened)).font(.subheadline.weight(.semibold))
                        Text(entry.snapshot.schema + " + technical-hydraulic-network-v1 + technical-low-temperature-v1 + technical-temperature-scenarios-v1 + technical-radiator-replacements-v1 + technical-pump-curves-v1")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            } header: { Text("Berichtsarchiv") }
              footer: { Text("Die letzten 10 erfolgreichen Exportstände je Berichtstyp werden getrennt versioniert archiviert.") }
        }
        .navigationTitle("Technischer Bericht")
        .navigationBarTitleDisplayMode(.inline)
        .task { reloadArchive() }
        .fileExporter(isPresented: $showingExporter, document: exportDocument, contentType: .pdf, defaultFilename: filename) {
            handleExportResult($0)
        }
    }

    private func preparePDFExport() {
        let generatedAt = Date()
        let main = project.technicalReportSnapshot(generatedAt: generatedAt)
        let network = HeizBalanceHydraulicNetworkReportSnapshot.make(project: project, generatedAt: generatedAt)
        let low = project.lowTemperatureReportSnapshot(generatedAt: generatedAt, comparisonFlowTemperatureC: project.designFlowTemperatureC)
        let scenarios = project.temperatureScenarioReportSnapshot(generatedAt: generatedAt)
        let radiators = project.radiatorReplacementReportSnapshot(generatedAt: generatedAt)
        let pumps = project.pumpCurveReportSnapshot(datasets: pumpDatasetStore.datasets, generatedAt: generatedAt)

        pendingSnapshot = main
        pendingHydraulicNetworkSnapshot = network
        pendingLowTemperatureSnapshot = low
        pendingTemperatureScenarioSnapshot = scenarios
        pendingRadiatorReplacementSnapshot = radiators
        pendingPumpCurveSnapshot = pumps

        let mainPDF = HeizBalanceTechnicalReportPDFRenderer.render(main)
        let reports = [
            mainPDF,
            HeizBalanceHydraulicNetworkReportPDFRenderer.render(network),
            HeizBalanceLowTemperatureReportPDFRenderer.render(low),
            HeizBalanceTemperatureScenarioReportPDFRenderer.render(scenarios),
            HeizBalanceRadiatorReplacementReportPDFRenderer.render(radiators),
            HeizBalancePumpCurveReportPDFRenderer.render(pumps)
        ]
        exportDocument = HeizBalancePDFDocument(data: HeizBalancePDFMerger.merge(reports) ?? mainPDF)
        exportMessage = nil
        showingExporter = true
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            guard let main = pendingSnapshot,
                  let network = pendingHydraulicNetworkSnapshot,
                  let low = pendingLowTemperatureSnapshot,
                  let scenarios = pendingTemperatureScenarioSnapshot,
                  let radiators = pendingRadiatorReplacementSnapshot,
                  let pumps = pendingPumpCurveSnapshot else {
                exportMessage = "PDF-Bericht exportiert; Berichtssnapshots waren nicht mehr vollständig verfügbar."
                clearPendingSnapshots()
                return
            }
            do {
                _ = try archiveStore.archive(main)
                _ = try networkArchiveStore.archive(network)
                _ = try lowTemperatureArchiveStore.archive(low)
                _ = try temperatureScenarioArchiveStore.archive(scenarios)
                _ = try radiatorReplacementArchiveStore.archive(radiators)
                _ = try pumpCurveArchiveStore.archive(pumps)
                clearPendingSnapshots()
                reloadArchive()
                exportMessage = "PDF-Bericht exportiert; alle sechs versionierten Snapshots archiviert."
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
        pendingHydraulicNetworkSnapshot = nil
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
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
