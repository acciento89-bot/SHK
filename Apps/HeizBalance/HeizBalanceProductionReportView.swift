import SwiftUI
import UniformTypeIdentifiers

struct HeizBalanceProductionReportView: View {
    let project: HeizBalanceProject

    @Environment(HeizBalanceDocumentationStore.self) private var documentationStore
    @Environment(HeizBalanceValveSettingSelectionStore.self) private var valveSelectionStore
    @Environment(HeizBalancePumpSelectionStore.self) private var pumpSelectionStore
    @Environment(HeizBalancePumpDatasetStore.self) private var pumpDatasetStore

    @State private var exportDocument = HeizBalancePDFDocument(data: Data())
    @State private var showingExporter = false
    @State private var exportMessage: String?

    @State private var pendingMain: HeizBalanceTechnicalReportSnapshot?
    @State private var pendingLowTemperature: HeizBalanceLowTemperatureReportSnapshot?
    @State private var pendingTemperatureScenario: HeizBalanceTemperatureScenarioReportSnapshot?
    @State private var pendingRadiatorReplacement: HeizBalanceRadiatorReplacementReportSnapshot?
    @State private var pendingPumpCurve: HeizBalancePumpCurveReportSnapshot?
    @State private var pendingAdjustment: HeizBalanceAdjustmentListSnapshot?
    @State private var pendingHandover: HeizBalanceProductionHandoverSnapshot?
    @State private var handoverArchive: [HeizBalanceProductionHandoverSnapshot] = []

    private var documentation: HeizBalanceDocumentationMetadata {
        documentationStore.metadata(projectID: project.id)
    }

    private var valveSelections: [HeizBalanceValveSettingSelection] {
        valveSelectionStore.selections(projectID: project.id)
    }

    private var pumpSelection: HeizBalancePumpSelection? {
        pumpSelectionStore.selection(projectID: project.id)
    }

    private var currentHandover: HeizBalanceProductionHandoverSnapshot {
        .make(
            project: project,
            documentation: documentation,
            valveSelections: valveSelections,
            pumpSelection: pumpSelection
        )
    }

    private var roomCount: Int { currentHandover.summary.roomCount }
    private var heatingSurfaceCount: Int { currentHandover.summary.heatingSurfaceCount }
    private var isLargeProject: Bool { roomCount >= 20 }
    private var isVeryLargeProject: Bool { roomCount >= 50 }

    private var filename: String {
        let raw = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = raw.isEmpty ? "HeizBalance" : raw
        let forbidden = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let cleaned = base.components(separatedBy: forbidden).joined(separator: "-")
        return "HeizBalance-\(cleaned)-Produktionsbericht"
    }

    var body: some View {
        let handover = currentHandover

        List {
            Section {
                LabeledContent("Projektstatus") {
                    Text(documentation.projectStatus.title)
                        .fontWeight(.semibold)
                }
                LabeledContent("Firma") {
                    Text(documentation.companyName.isBlank ? "—" : documentation.companyName)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Techniker") {
                    Text(documentation.technicianName.isBlank ? "—" : documentation.technicianName)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Bearbeiter") {
                    Text(documentation.preparedBy.isBlank ? "—" : documentation.preparedBy)
                        .multilineTextAlignment(.trailing)
                }

                NavigationLink {
                    HeizBalanceDocumentationView(projectID: project.id, projectName: project.name)
                } label: {
                    Label("Dokumentationsdaten bearbeiten", systemImage: "person.text.rectangle")
                }
            } header: {
                Text("Dokumentation")
            } footer: {
                Text("Projektstatus und Verantwortliche werden vom Bearbeiter gesetzt. Die PDF-Unterschrift bleibt eine freie handschriftliche Zeile und ist keine automatische Norm-/Förder-/Herstellerfreigabe.")
            }

            Section {
                LabeledContent("Geschosse", value: "\(handover.summary.floorCount)")
                LabeledContent("Räume", value: "\(roomCount)")
                LabeledContent("Heizflächen", value: "\(heatingSurfaceCount)")
                LabeledContent("Wärmeverlust vollständig") {
                    Text("\(handover.summary.heatLossReadyRoomCount) / \(roomCount)")
                }
                LabeledContent("Ziel-Q verfügbar") {
                    Text("\(handover.summary.targetFlowReadyCount) / \(heatingSurfaceCount)")
                }
                LabeledContent("Kreis-Δp vollständig") {
                    Text("\(handover.summary.circuitPressureReadyCount) / \(heatingSurfaceCount)")
                }
                LabeledContent("Offene technische Punkte", value: "\(handover.summary.openTechnicalItemCount)")

                if isVeryLargeProject {
                    Label("50+-Räume-Projekt: dynamische Mehrseiten-Ausgabe aktiv", systemImage: "doc.on.doc.fill")
                        .foregroundStyle(.blue)
                } else if isLargeProject {
                    Label("Großprojekt: dynamische Mehrseiten-Ausgabe aktiv", systemImage: "doc.on.doc")
                        .foregroundStyle(.blue)
                }
            } header: {
                Text("Projektumfang")
            } footer: {
                Text("Der Produktionsbericht besitzt kein künstliches Raumlimit. Einstelllisten-Zeilen, Geschosse und lange Übergabehinweise werden seitenweise fortgeführt; Kopf-/Fußzeilen werden wiederholt.")
            }

            Section {
                packageRow("Übergabe-Zusammenfassung", schema: HeizBalanceProductionHandoverSnapshot.schemaVersion)
                packageRow("Technischer Hauptbericht", schema: HeizBalanceTechnicalReportSnapshot.schemaVersion)
                packageRow("Niedertemperatur", schema: HeizBalanceLowTemperatureReportSnapshot.schemaVersion)
                packageRow("Temperatur-Szenarien", schema: HeizBalanceTemperatureScenarioReportSnapshot.schemaVersion)
                packageRow("Heizkörper-Auswahl", schema: HeizBalanceRadiatorReplacementReportSnapshot.schemaVersion)
                packageRow("Pumpenkennlinien", schema: HeizBalancePumpCurveReportSnapshot.schemaVersion)
                packageRow("Baustellen-Einstellliste", schema: HeizBalanceAdjustmentListSnapshot.schemaVersion)
            } header: {
                Text("PDF-Paket")
            } footer: {
                Text("Alle sieben Snapshots werden beim Export mit exakt demselben Zeitstempel erzeugt. Das Übergabeblatt steht vorne, danach folgen Fachbericht und Supplements; die kompakte Einstellliste bildet den Baustellen-Anhang.")
            }

            Section {
                if !documentation.handoverNote.isBlank {
                    Text(documentation.handoverNote)
                        .font(.caption)
                } else {
                    Text("Noch kein Übergabehinweis / Restpunkt erfasst.")
                        .foregroundStyle(.secondary)
                }

                if handover.summary.openTechnicalItemCount > 0 {
                    Label(
                        "\(handover.summary.openTechnicalItemCount) offene technische Punkte bleiben im Bericht sichtbar.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .foregroundStyle(.orange)
                } else {
                    Label("Keine offenen Punkte aus der technischen Zusammenfassung erkannt.", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
            } header: {
                Text("Übergabe-Kurzfassung")
            }

            Section {
                Button {
                    prepareExport()
                } label: {
                    Label("Produktionsbericht als PDF exportieren", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)

                if let exportMessage {
                    Text(exportMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Export")
            } footer: {
                Text("Der Export dokumentiert den technischen Arbeitsstand. Unvollständige oder veraltete Werte bleiben sichtbar und werden nicht durch versteckte Annahmen ersetzt.")
            }

            Section {
                LabeledContent("Archivierte Übergabestände", value: "\(handoverArchive.count) / 10")
                ForEach(Array(handoverArchive.prefix(5)), id: \.generatedAt) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.generatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption.weight(.semibold))
                        Text(item.documentation.projectStatusTitle + " · " + item.schema)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Produktionsarchiv")
            }
        }
        .navigationTitle("Produktionsbericht")
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
    private func packageRow(_ title: String, schema: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(schema)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
    }

    private func prepareExport() {
        let generatedAt = Date()
        let metadata = documentation
        let valves = valveSelections
        let selectedPump = pumpSelection

        let handover = HeizBalanceProductionHandoverSnapshot.make(
            project: project,
            documentation: metadata,
            valveSelections: valves,
            pumpSelection: selectedPump,
            generatedAt: generatedAt
        )
        let main = project.technicalReportSnapshot(generatedAt: generatedAt)
        let lowTemperature = project.lowTemperatureReportSnapshot(
            generatedAt: generatedAt,
            comparisonFlowTemperatureC: project.designFlowTemperatureC
        )
        let temperatureScenario = project.temperatureScenarioReportSnapshot(generatedAt: generatedAt)
        let radiatorReplacement = project.radiatorReplacementReportSnapshot(generatedAt: generatedAt)
        let pumpCurve = project.pumpCurveReportSnapshot(
            datasets: pumpDatasetStore.datasets,
            generatedAt: generatedAt
        )
        let adjustment = HeizBalanceAdjustmentListSnapshot.make(
            project: project,
            valveSelections: valves,
            pumpSelection: selectedPump,
            generatedAt: generatedAt
        )

        pendingHandover = handover
        pendingMain = main
        pendingLowTemperature = lowTemperature
        pendingTemperatureScenario = temperatureScenario
        pendingRadiatorReplacement = radiatorReplacement
        pendingPumpCurve = pumpCurve
        pendingAdjustment = adjustment

        let reports = [
            HeizBalanceProductionHandoverPDFRenderer.render(handover),
            HeizBalanceTechnicalReportPDFRenderer.render(main),
            HeizBalanceLowTemperatureReportPDFRenderer.render(lowTemperature),
            HeizBalanceTemperatureScenarioReportPDFRenderer.render(temperatureScenario),
            HeizBalanceRadiatorReplacementReportPDFRenderer.render(radiatorReplacement),
            HeizBalancePumpCurveReportPDFRenderer.render(pumpCurve),
            HeizBalanceAdjustmentListPDFRenderer.render(adjustment)
        ]

        exportDocument = HeizBalancePDFDocument(
            data: HeizBalancePDFMerger.merge(reports) ?? reports[0]
        )
        exportMessage = nil
        showingExporter = true
    }

    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            guard let handover = pendingHandover,
                  let main = pendingMain,
                  let lowTemperature = pendingLowTemperature,
                  let temperatureScenario = pendingTemperatureScenario,
                  let radiatorReplacement = pendingRadiatorReplacement,
                  let pumpCurve = pendingPumpCurve,
                  let adjustment = pendingAdjustment else {
                exportMessage = "PDF exportiert; die vollständige Snapshot-Gruppe war nicht mehr verfügbar."
                clearPending()
                return
            }

            do {
                _ = try HeizBalanceProductionHandoverArchiveStore().archive(handover)
                _ = try HeizBalanceReportArchiveStore().archive(main)
                _ = try HeizBalanceLowTemperatureReportArchiveStore().archive(lowTemperature)
                _ = try HeizBalanceTemperatureScenarioReportArchiveStore().archive(temperatureScenario)
                _ = try HeizBalanceRadiatorReplacementReportArchiveStore().archive(radiatorReplacement)
                _ = try HeizBalancePumpCurveReportArchiveStore().archive(pumpCurve)
                _ = try HeizBalanceAdjustmentListArchiveStore().archive(adjustment)
                clearPending()
                reloadArchive()
                exportMessage = "Produktionsbericht exportiert; alle sieben versionierten Snapshots wurden archiviert."
            } catch {
                clearPending()
                exportMessage = "PDF exportiert; Snapshot-Archivierung fehlgeschlagen: \(error.localizedDescription)"
            }

        case .failure(let error):
            clearPending()
            exportMessage = "PDF-Export fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func clearPending() {
        pendingMain = nil
        pendingLowTemperature = nil
        pendingTemperatureScenario = nil
        pendingRadiatorReplacement = nil
        pendingPumpCurve = nil
        pendingAdjustment = nil
        pendingHandover = nil
    }

    private func reloadArchive() {
        do {
            handoverArchive = try HeizBalanceProductionHandoverArchiveStore().entries(projectID: project.id)
        } catch {
            handoverArchive = []
            if exportMessage == nil {
                exportMessage = "Produktionsarchiv konnte nicht gelesen werden: \(error.localizedDescription)"
            }
        }
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
