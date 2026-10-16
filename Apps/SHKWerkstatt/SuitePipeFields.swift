import SwiftUI
import Charts

struct SuitePipeFields: View {
    @Binding var project: SuiteProject
    let quick: Bool
    @State private var sync = false
    @State private var syncError = false
    var body: some View {
        Group {
        Section {
            SuiteNumberField(S("Gemeinsamer Volumenstrom", "Common flow rate"), value: $project.pipe.flowLPH, unit: "l/h")
            Text(S("Ein serieller Fließweg mit demselben Volumenstrom in allen Abschnitten.", "One series flow path with the same flow through all sections.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
        }
        Section {
            ForEach($project.pipe.sections) { $section in
                DisclosureGroup(section.name.isEmpty ? S("Neuer Abschnitt", "New section") : section.name) {
                    TextField(S("Abschnitt", "Section"), text: $section.name)
                    SuiteNumberField(S("Echter Innendurchmesser", "Actual internal diameter"), value: $section.diameterMM, unit: "mm")
                    SuiteNumberField(S("Länge", "Length"), value: $section.lengthM, unit: "m")
                    SuiteNumberField(S("Absolute Rauheit", "Absolute roughness"), value: $section.roughnessMM, unit: "mm")
                    SuiteNumberField(S("Summe Einzelwiderstände", "Sum of local loss coefficients"), value: $section.zeta, unit: "ζ")
                    if section.isValid && project.pipe.isValid {
                        let result = section.result(flow: project.pipe.flowLPH)
                        LabeledContent(S("Geschwindigkeit", "Velocity"), value: "\(SN(result.base.velocityMS)) m/s")
                        LabeledContent(S("Druckverlust", "Pressure loss"), value: "\(SN(result.totalPressureLossIncludingLocalKPa)) kPa")
                        LabeledContent(S("Förderhöhe aus Reibung und Einzelverlusten", "Head from friction and local losses"), value: "\(SN(result.totalHeadMeters)) m")
                        LabeledContent(S("Strömungsart", "Flow regime"), value: result.flowRegime == .transitional ? S("Übergang", "Transitional") : result.flowRegime.rawValue)
                    } else { Text(S("Name, positive Länge und Durchmesser erforderlich; Rauheit kleiner als Innendurchmesser, ζ ≥ 0.", "Enter a name, positive length and diameter; roughness must be below diameter, ζ ≥ 0.")).font(.footnote).foregroundStyle(.red) }
                }
            }.onDelete { project.pipe.sections.remove(atOffsets: $0) }
            .onMove { project.pipe.sections.move(fromOffsets: $0, toOffset: $1) }
            Button { var section = PipeSection(); section.name = S("Abschnitt", "Section") + " \(project.pipe.sections.count+1)"; project.pipe.sections.append(section) } label: { Label(S("Abschnitt hinzufügen", "Add section"), systemImage: "plus.circle") }.buttonStyle(SuiteRowButtonStyle()).accessibilityIdentifier("pipe-add-section")
        } header: { Text(S("In Fließrichtung", "In flow direction")) }
        if project.pipe.isValid && !project.pipe.sections.isEmpty {
            Section {
                SuiteMetric(title: S("Druckverlust gesamt", "Total pressure loss"), value: "\(SN(project.pipe.totalLossKPa)) kPa", tint: SuiteTheme.copper)
                SuiteMetric(title: S("Rohrinhalt", "Pipe water volume"), value: "\(SN(project.pipe.totalVolumeL)) l")
                Chart(project.pipe.sections) { section in
                    BarMark(x: .value("kPa", section.result(flow: project.pipe.flowLPH).totalPressureLossIncludingLocalKPa), y: .value(S("Abschnitt", "Section"), section.name)).foregroundStyle(SuiteTheme.copper)
                }.frame(height: max(160, CGFloat(project.pipe.sections.count)*42))
                if !quick { Button { sync = true } label: { Label(S("Rohrinhalt im Inventar aktualisieren", "Update pipe volume in inventory"), systemImage: "arrow.right.circle") }.buttonStyle(SuiteRowButtonStyle()).accessibilityIdentifier("pipe-sync-volume") }
            } header: { Text(S("Der ganze Fließweg", "The complete flow path")) }
        }
        if !quick && project.pipe.sections.isEmpty && project.volume.components.contains(where: { $0.sourcePipeSectionID != nil }) {
            Section { Button { sync = true } label: { Label(S("Entfernte Rohrabschnitte im Inventar abgleichen", "Reconcile removed sections in inventory"), systemImage: "arrow.triangle.2.circlepath") }.buttonStyle(SuiteRowButtonStyle()) }
        }
        SuitePipeSizing(flow: project.pipe.flowLPH)
        Section {
            TextField(S("Material, Formstücke, Hinweise …", "Materials, fittings, notes …"), text: $project.pipe.notes, axis: .vertical)
            Text(S("Wasser bei etwa 20 °C. Darcy-Weisbach mit eingegebener Rauheit und ζ-Werten. Keine verzweigte Netzberechnung; Geräteverluste und geodätische Höhe nicht enthalten.", "Water at approximately 20°C. Darcy-Weisbach with entered roughness and ζ values. Not a branched network calculation; equipment losses and static elevation are excluded.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
        }
        }.confirmationDialog(S("Rohrvolumen synchronisieren?", "Synchronize pipe volume?"), isPresented: $sync, titleVisibility: .visible) {
            Button(S("Aktualisieren", "Update")) { do { try project.synchronizePipeVolumes() } catch { syncError = true } }
        } message: { Text(S("Nur verknüpfte Rohrabschnitte werden ersetzt. Manuelle Bauteile bleiben erhalten; erneutes Übernehmen zählt nichts doppelt.", "Only linked pipe sections are replaced. Manual components remain; repeating this action never duplicates volumes.")) }
        .alert(S("Abgleich nicht möglich. Bitte die Rohrdaten prüfen.", "Synchronization unavailable. Check pipe data."), isPresented: $syncError) { Button("OK") {} }
    }
}
