import SwiftUI
import UniformTypeIdentifiers

struct HeizBalanceTechnicalReportExportView: View {
    let project: HeizBalanceProject

    @State private var exportDocument = HeizBalancePDFDocument(data: Data())
    @State private var showingExporter = false
    @State private var exportMessage: String?

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
                Text("Das PDF enthält ausschließlich den aktuellen technischen Projektstand. Normative Freigaben, Verfahren-B-Bestätigung, automatische Ventilvoreinstellung und Pumpenauswahl bleiben gesperrt.")
            }
        }
        .navigationTitle("Technischer Bericht")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .pdf,
            defaultFilename: filename
        ) { result in
            switch result {
            case .success:
                exportMessage = "PDF-Bericht exportiert."
            case .failure(let error):
                exportMessage = "PDF-Export fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }

    private func preparePDFExport() {
        let freshSnapshot = project.technicalReportSnapshot(generatedAt: Date())
        exportDocument = HeizBalancePDFDocument(
            data: HeizBalanceTechnicalReportPDFRenderer.render(freshSnapshot)
        )
        exportMessage = nil
        showingExporter = true
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
