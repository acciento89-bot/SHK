import Foundation
import SwiftUI

enum AnlagenCheckMode: String, CaseIterable, Identifiable {
    case measurements = "Messwerte"
    case checklist = "Checkliste"
    case report = "Bericht"

    var id: String { rawValue }
}

struct AnlagenCheckView: View {
    @State private var mode: AnlagenCheckMode = .measurements
    @State private var objectName = ""

    @State private var flow = 55.0
    @State private var returnTemp = 45.0
    @State private var coldPressure = 1.5
    @State private var hotPressure = 1.9

    @State private var minPressure = 1.2
    @State private var maxPressure = 2.0
    @State private var minSpread = 5.0
    @State private var maxSpread = 20.0
    @State private var staticHeight = 8.0
    @State private var staticReserve = 0.3
    @State private var safetyValvePressure = 3.0
    @State private var safetyMargin = 0.5
    @State private var maxPressureRise = 1.0

    @State private var visualInspectionDone = false
    @State private var ventingChecked = false
    @State private var strainerChecked = false
    @State private var expansionVesselChecked = false
    @State private var safetyValveChecked = false
    @State private var pumpControlsChecked = false
    @State private var notes = ""

    private var checks: [SystemCheckResult] {
        AnlagenCheckCalculator.evaluateExtended(
            flowC: flow,
            returnC: returnTemp,
            coldPressureBar: coldPressure,
            hotPressureBar: hotPressure,
            allowedMinBar: minPressure,
            allowedMaxBar: maxPressure,
            minimumSpreadK: minSpread,
            maximumSpreadK: maxSpread,
            staticHeightM: staticHeight,
            staticPressureReserveBar: staticReserve,
            safetyValveBar: safetyValvePressure,
            requiredSafetyMarginBar: safetyMargin,
            maximumPressureRiseBar: maxPressureRise
        )
    }

    private var overallSeverity: CheckSeverity {
        AnlagenCheckCalculator.overallSeverity(for: checks)
    }

    private var minimumPressureFromHeight: Double {
        AnlagenCheckCalculator.minimumColdFillPressureBar(
            staticHeightM: staticHeight,
            reserveBar: staticReserve
        )
    }

    private var checklistDoneCount: Int {
        [
            visualInspectionDone,
            ventingChecked,
            strainerChecked,
            expansionVesselChecked,
            safetyValveChecked,
            pumpControlsChecked
        ].filter { $0 }.count
    }

    private var reportText: String {
        let checkLines = checks.map { check in
            "[\(check.severity.rawValue)] \(check.title): \(check.detail)"
        }.joined(separator: "\n")

        let checklistLines = [
            checklistLine("Sichtprüfung / Leckage", visualInspectionDone),
            checklistLine("Entlüftung geprüft", ventingChecked),
            checklistLine("Schmutzfänger / Filter geprüft", strainerChecked),
            checklistLine("MAG / Vordruck geprüft", expansionVesselChecked),
            checklistLine("Sicherheitsventil geprüft", safetyValveChecked),
            checklistLine("Pumpe / Regelung geprüft", pumpControlsChecked)
        ].joined(separator: "\n")

        return """
        AnlagenCheck – Servicebericht
        Objekt: \(objectName.isEmpty ? "ohne Bezeichnung" : objectName)
        Datum: \(formattedDate)

        Messwerte
        Vorlauf: \(format(flow)) °C
        Rücklauf: \(format(returnTemp)) °C
        Spreizung: \(format(flow - returnTemp)) K
        Druck kalt: \(format(coldPressure, digits: 2)) bar
        Druck warm: \(format(hotPressure, digits: 2)) bar
        Druckanstieg: \(format(hotPressure - coldPressure, digits: 2)) bar

        Eingestellte Prüfvorgaben
        Kaltfülldruck: \(format(minPressure, digits: 2))–\(format(maxPressure, digits: 2)) bar
        Spreizung: \(format(minSpread))–\(format(maxSpread)) K
        Statische Höhe: \(format(staticHeight)) m
        Reserve statischer Druck: \(format(staticReserve, digits: 2)) bar
        Rechnerisches Minimum aus Höhe + Reserve: \(format(minimumPressureFromHeight, digits: 2)) bar
        Sicherheitsventil: \(format(safetyValvePressure, digits: 2)) bar
        Gewünschte Druckreserve: \(format(safetyMargin, digits: 2)) bar
        Max. Druckanstieg: \(format(maxPressureRise, digits: 2)) bar

        Plausibilitätscheck
        \(checkLines)

        Dokumentierte Arbeiten
        \(checklistLines)

        Notizen
        \(notes.isEmpty ? "–" : notes)

        Hinweis: AnlagenCheck ist eine Plausibilitäts- und Dokumentationshilfe. Die eingestellten Grenzwerte müssen zur konkreten Anlage passen. Herstellerangaben, Normen, Sicherheitsvorgaben und reale Messungen haben Vorrang.
        """
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SHKBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        header

                        SHKCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Objekt / Anlage")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                TextField("z. B. EFH Müller – Heizraum", text: $objectName)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        Picker("Bereich", selection: $mode) {
                            ForEach(AnlagenCheckMode.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch mode {
                        case .measurements:
                            measurementsContent
                        case .checklist:
                            checklistContent
                        case .report:
                            reportContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AnlagenCheck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: reportText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Servicebericht teilen")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        SHKCard {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.mint)
                    .frame(width: 54, height: 54)
                    .background(.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Anlage strukturiert prüfen")
                        .font(.title2.bold())
                    Text("Messwerte, eigene Grenzwerte und Service-Doku.")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var measurementsContent: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Messwerte", icon: "gauge.with.dots.needle.50percent")
                MetricField(title: "Vorlauf", unit: "°C", value: $flow)
                MetricField(title: "Rücklauf", unit: "°C", value: $returnTemp)
                MetricField(title: "Druck kalt", unit: "bar", value: $coldPressure)
                MetricField(title: "Druck warm", unit: "bar", value: $hotPressure)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Eigene Prüfvorgaben", icon: "slider.horizontal.3")
                MetricField(title: "Druck min.", unit: "bar", value: $minPressure)
                MetricField(title: "Druck max.", unit: "bar", value: $maxPressure)
                MetricField(title: "Spreizung min.", unit: "K", value: $minSpread)
                MetricField(title: "Spreizung max.", unit: "K", value: $maxSpread)
                MetricField(title: "Statische Höhe", unit: "m", value: $staticHeight)
                MetricField(title: "Druckreserve Höhe", unit: "bar", value: $staticReserve)
                MetricField(title: "Sicherheitsventil", unit: "bar", value: $safetyValvePressure)
                MetricField(title: "Reserve zum SV", unit: "bar", value: $safetyMargin)
                MetricField(title: "Max. Druckanstieg", unit: "bar", value: $maxPressureRise)

                resultRow("Minimum aus statischer Höhe", value: minimumPressureFromHeight, unit: "bar", digits: 2)
            }
        }

        statusSummary

        ForEach(checks) { check in
            checkCard(check)
        }

        disclaimerCard
    }

    @ViewBuilder
    private var checklistContent: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Service-Checkliste", icon: "checklist")

                Toggle("Sichtprüfung / Leckage geprüft", isOn: $visualInspectionDone)
                Toggle("Entlüftung geprüft", isOn: $ventingChecked)
                Toggle("Schmutzfänger / Filter geprüft", isOn: $strainerChecked)
                Toggle("MAG / Vordruck geprüft", isOn: $expansionVesselChecked)
                Toggle("Sicherheitsventil geprüft", isOn: $safetyValveChecked)
                Toggle("Pumpe / Regelung geprüft", isOn: $pumpControlsChecked)

                Divider().opacity(0.4)

                HStack {
                    Text("Dokumentiert")
                    Spacer()
                    Text("\(checklistDoneCount) / 6")
                        .font(.headline)
                        .foregroundStyle(.mint)
                }

                Text("Ein ausgeschalteter Punkt bedeutet nur „nicht als erledigt dokumentiert“ – nicht automatisch einen Anlagenfehler.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        SHKCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Notizen", icon: "square.and.pencil")
                TextEditor(text: $notes)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }

        disclaimerCard
    }

    @ViewBuilder
    private var reportContent: some View {
        statusSummary

        SHKCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Berichtsvorschau", icon: "doc.text")

                Text(objectName.isEmpty ? "ohne Objektbezeichnung" : objectName)
                    .font(.headline)
                Text(formattedDate)
                    .foregroundStyle(.secondary)

                Divider().opacity(0.4)

                resultRow("Vorlauf / Rücklauf", value: flow - returnTemp, unit: "K Spreizung", digits: 1)
                resultRow("Druck kalt", value: coldPressure, unit: "bar", digits: 2)
                resultRow("Druck warm", value: hotPressure, unit: "bar", digits: 2)
                resultRow("Checkliste", value: Double(checklistDoneCount), unit: "/ 6", digits: 0)

                if !notes.isEmpty {
                    Divider().opacity(0.4)
                    Text(notes)
                        .foregroundStyle(.secondary)
                }
            }
        }

        SHKCard {
            ShareLink(item: reportText) {
                Label("Servicebericht teilen", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.mint)
        }

        disclaimerCard
    }

    private var statusSummary: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("PLAUSIBILITÄT")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: severityIcon(overallSeverity))
                        .foregroundStyle(severityColor(overallSeverity))
                    Text(overallTitle)
                        .font(.title2.bold())
                    Spacer()
                    Text("\(checks.filter { $0.severity == .warning }.count) prüfen · \(checks.filter { $0.severity == .notice }.count) Hinweise")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func checkCard(_ check: SystemCheckResult) -> some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(check.severity.rawValue.uppercased(), systemImage: severityIcon(check.severity))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(severityColor(check.severity))
                Text(check.title)
                    .font(.headline)
                Text(check.detail)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var disclaimerCard: some View {
        SHKCard {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("Fachlicher Hinweis", icon: "info.circle")
                Text("AnlagenCheck bewertet ausschließlich Messwerte gegen die hier eingestellten Prüfvorgaben. Die Grenzwerte müssen zur konkreten Anlage passen. Herstellerangaben, Normen, Sicherheitsvorgaben und reale Prüfungen haben Vorrang.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var overallTitle: String {
        switch overallSeverity {
        case .ok: "Werte innerhalb deiner Vorgaben"
        case .notice: "Hinweise vorhanden"
        case .warning: "Werte prüfen"
        }
    }

    private func severityIcon(_ severity: CheckSeverity) -> String {
        switch severity {
        case .ok: "checkmark.circle.fill"
        case .notice: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        }
    }

    private func severityColor(_ severity: CheckSeverity) -> Color {
        switch severity {
        case .ok: .mint
        case .notice: .yellow
        case .warning: .orange
        }
    }

    private func checklistLine(_ title: String, _ done: Bool) -> String {
        "[\(done ? "x" : " ")] \(title)"
    }

    private var formattedDate: String {
        Date().formatted(date: .numeric, time: .shortened)
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }

    private func resultRow(_ title: String, value: Double, unit: String, digits: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(format(value, digits: digits)) \(unit)")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(.mint)
        }
    }

    private func format(_ value: Double, digits: Int = 1) -> String {
        String(format: "%.*f", digits, value)
    }
}
