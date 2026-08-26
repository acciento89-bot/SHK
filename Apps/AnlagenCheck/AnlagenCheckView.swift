import Foundation
import SwiftUI

enum AnlagenCheckMode: String, CaseIterable, Identifiable {
    case measurements = "Prüfen"
    case checklist = "Checkliste"
    case report = "Bericht"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .measurements: "gauge.with.dots.needle.50percent"
        case .checklist: "checklist"
        case .report: "doc.text"
        }
    }
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
                InspectionBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        inspectionHeader
                        objectField
                        inspectionNavigation

                        switch mode {
                        case .measurements:
                            measurementsContent
                        case .checklist:
                            checklistContent
                        case .report:
                            reportContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("AnlagenCheck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: reportText) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(InspectionPalette.accent)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .shkKeyboardDismissal()
    }

    private var inspectionHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(InspectionPalette.track, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(checklistDoneCount) / 6.0)
                    .stroke(InspectionPalette.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(checklistDoneCount)")
                        .font(.title2.bold())
                    Text("/ 6")
                        .font(.caption)
                        .foregroundStyle(InspectionPalette.muted)
                }
            }
            .frame(width: 82, height: 82)

            VStack(alignment: .leading, spacing: 5) {
                Text("SERVICE INSPECTION")
                    .font(.caption2.weight(.black))
                    .tracking(2)
                    .foregroundStyle(InspectionPalette.accent)
                Text("Anlage Schritt für Schritt prüfen")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(InspectionPalette.ink)
                Text(overallTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(severityColor(overallSeverity))
            }
            Spacer()
        }
        .padding(18)
        .background(InspectionPalette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(InspectionPalette.outline))
    }

    private var objectField: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("OBJEKT / ANLAGE")
                .font(.caption2.weight(.black))
                .tracking(1)
                .foregroundStyle(InspectionPalette.muted)
            HStack {
                Image(systemName: "building.2")
                    .foregroundStyle(InspectionPalette.accent)
                TextField("z. B. EFH Müller – Heizraum", text: $objectName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(InspectionPalette.ink)
            }
            .padding(13)
            .background(InspectionPalette.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(InspectionPalette.outline))
        }
    }

    private var inspectionNavigation: some View {
        HStack(spacing: 0) {
            ForEach(AnlagenCheckMode.allCases) { item in
                Button {
                    mode = item
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.icon)
                        Text(item.rawValue)
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(mode == item ? Color.white : InspectionPalette.ink)
                    .background(mode == item ? InspectionPalette.accent : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(InspectionPalette.surface, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(InspectionPalette.outline))
    }

    @ViewBuilder
    private var measurementsContent: some View {
        InspectionSection(title: "01 · Messwerte", icon: "gauge.with.dots.needle.50percent") {
            HStack(spacing: 10) {
                InspectionCompactField(title: "Vorlauf", unit: "°C", value: $flow)
                InspectionCompactField(title: "Rücklauf", unit: "°C", value: $returnTemp)
            }
            HStack(spacing: 10) {
                InspectionCompactField(title: "Druck kalt", unit: "bar", value: $coldPressure)
                InspectionCompactField(title: "Druck warm", unit: "bar", value: $hotPressure)
            }

            InspectionResultLine(title: "Aktuelle Spreizung", value: "\(format(flow - returnTemp)) K")
            InspectionResultLine(title: "Druckanstieg", value: "\(format(hotPressure - coldPressure, digits: 2)) bar")
        }

        InspectionSection(title: "02 · Prüfvorgaben", icon: "slider.horizontal.3") {
            InspectionWideField(title: "Druck min.", unit: "bar", value: $minPressure)
            InspectionWideField(title: "Druck max.", unit: "bar", value: $maxPressure)
            InspectionWideField(title: "Spreizung min.", unit: "K", value: $minSpread)
            InspectionWideField(title: "Spreizung max.", unit: "K", value: $maxSpread)
            InspectionWideField(title: "Statische Höhe", unit: "m", value: $staticHeight)
            InspectionWideField(title: "Druckreserve Höhe", unit: "bar", value: $staticReserve)
            InspectionWideField(title: "Sicherheitsventil", unit: "bar", value: $safetyValvePressure)
            InspectionWideField(title: "Reserve zum SV", unit: "bar", value: $safetyMargin)
            InspectionWideField(title: "Max. Druckanstieg", unit: "bar", value: $maxPressureRise)
            InspectionResultLine(title: "Minimum aus Höhe + Reserve", value: "\(format(minimumPressureFromHeight, digits: 2)) bar")
        }

        InspectionSection(title: "03 · Plausibilität", icon: severityIcon(overallSeverity)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(overallTitle)
                        .font(.title3.bold())
                        .foregroundStyle(InspectionPalette.ink)
                    Text("\(checks.filter { $0.severity == .warning }.count) prüfen · \(checks.filter { $0.severity == .notice }.count) Hinweise")
                        .font(.caption)
                        .foregroundStyle(InspectionPalette.muted)
                }
                Spacer()
                Circle()
                    .fill(severityColor(overallSeverity).opacity(0.15))
                    .frame(width: 46, height: 46)
                    .overlay {
                        Image(systemName: severityIcon(overallSeverity))
                            .foregroundStyle(severityColor(overallSeverity))
                    }
            }

            ForEach(checks) { check in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: severityIcon(check.severity))
                        .foregroundStyle(severityColor(check.severity))
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(check.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(InspectionPalette.ink)
                        Text(check.detail)
                            .font(.caption)
                            .foregroundStyle(InspectionPalette.muted)
                    }
                    Spacer()
                }
                .padding(11)
                .background(severityColor(check.severity).opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }
        }

        disclaimerCard
    }

    @ViewBuilder
    private var checklistContent: some View {
        InspectionSection(title: "Service-Checkliste", icon: "checklist") {
            InspectionCheckRow(title: "Sichtprüfung / Leckage", isOn: $visualInspectionDone)
            InspectionCheckRow(title: "Entlüftung geprüft", isOn: $ventingChecked)
            InspectionCheckRow(title: "Schmutzfänger / Filter", isOn: $strainerChecked)
            InspectionCheckRow(title: "MAG / Vordruck", isOn: $expansionVesselChecked)
            InspectionCheckRow(title: "Sicherheitsventil", isOn: $safetyValveChecked)
            InspectionCheckRow(title: "Pumpe / Regelung", isOn: $pumpControlsChecked)

            HStack {
                Text("Dokumentationsstand")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(InspectionPalette.muted)
                Spacer()
                Text("\(checklistDoneCount) / 6")
                    .font(.title3.bold())
                    .foregroundStyle(InspectionPalette.accent)
            }
            .padding(.top, 5)

            Text("Nicht angehakt bedeutet nur: noch nicht als erledigt dokumentiert. Es ist keine automatische Fehlerbewertung.")
                .font(.caption)
                .foregroundStyle(InspectionPalette.muted)
        }

        InspectionSection(title: "Notizen", icon: "square.and.pencil") {
            TextEditor(text: $notes)
                .frame(minHeight: 160)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(InspectionPalette.background, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(InspectionPalette.outline))
        }

        disclaimerCard
    }

    @ViewBuilder
    private var reportContent: some View {
        InspectionSection(title: "Berichtsvorschau", icon: "doc.text") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(objectName.isEmpty ? "Ohne Objektbezeichnung" : objectName)
                        .font(.headline)
                        .foregroundStyle(InspectionPalette.ink)
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(InspectionPalette.muted)
                }
                Spacer()
                Image(systemName: severityIcon(overallSeverity))
                    .font(.title2)
                    .foregroundStyle(severityColor(overallSeverity))
            }

            Divider()
            InspectionResultLine(title: "Spreizung", value: "\(format(flow - returnTemp)) K")
            InspectionResultLine(title: "Druck kalt", value: "\(format(coldPressure, digits: 2)) bar")
            InspectionResultLine(title: "Druck warm", value: "\(format(hotPressure, digits: 2)) bar")
            InspectionResultLine(title: "Checkliste", value: "\(checklistDoneCount) / 6")

            if !notes.isEmpty {
                Divider()
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(InspectionPalette.muted)
            }
        }

        ShareLink(item: reportText) {
            HStack {
                Image(systemName: "doc.badge.arrow.up")
                Text("Servicebericht teilen")
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "arrow.right")
            }
            .padding(15)
            .foregroundStyle(.white)
            .background(InspectionPalette.accent, in: RoundedRectangle(cornerRadius: 14))
        }

        disclaimerCard
    }

    private var disclaimerCard: some View {
        InspectionSection(title: "Fachlicher Hinweis", icon: "info.circle") {
            Text("AnlagenCheck bewertet Messwerte gegen die hier eingestellten Prüfvorgaben. Die Grenzwerte müssen zur konkreten Anlage passen. Herstellerangaben, Normen, Sicherheitsvorgaben und reale Prüfungen haben Vorrang.")
                .font(.caption)
                .foregroundStyle(InspectionPalette.muted)
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
        case .ok: InspectionPalette.accent
        case .notice: .orange
        case .warning: .red
        }
    }

    private func checklistLine(_ title: String, _ done: Bool) -> String {
        "[\(done ? "x" : " ")] \(title)"
    }

    private var formattedDate: String {
        Date().formatted(date: .numeric, time: .shortened)
    }

    private func format(_ value: Double, digits: Int = 1) -> String {
        String(format: "%.*f", digits, value)
    }
}

private enum InspectionPalette {
    static let background = Color(red: 0.95, green: 0.96, blue: 0.945)
    static let surface = Color.white
    static let accent = Color(red: 0.10, green: 0.48, blue: 0.30)
    static let ink = Color(red: 0.11, green: 0.15, blue: 0.13)
    static let muted = Color(red: 0.36, green: 0.43, blue: 0.39)
    static let outline = Color(red: 0.12, green: 0.35, blue: 0.23).opacity(0.12)
    static let track = Color(red: 0.79, green: 0.84, blue: 0.80)
}

private struct InspectionBackground: View {
    var body: some View {
        ZStack {
            InspectionPalette.background
            VStack(spacing: 0) {
                ForEach(0..<18, id: \.self) { _ in
                    Divider()
                        .overlay(InspectionPalette.outline.opacity(0.45))
                        .frame(height: 42)
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct InspectionSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(InspectionPalette.ink)
                Spacer()
            }
            content
        }
        .padding(17)
        .background(InspectionPalette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(InspectionPalette.outline))
    }
}

private struct InspectionCompactField: View {
    let title: String
    let unit: String
    @Binding var value: Double
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(InspectionPalette.muted)
            HStack(spacing: 4) {
                TextField("0", value: $value, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(InspectionPalette.ink)
                    .focused($focused)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(InspectionPalette.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(11)
        .background(InspectionPalette.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(focused ? InspectionPalette.accent : Color.clear, lineWidth: 1.4)
        }
    }
}

private struct InspectionWideField: View {
    let title: String
    let unit: String
    @Binding var value: Double
    @FocusState private var focused: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(InspectionPalette.muted)
            Spacer()
            HStack(spacing: 5) {
                TextField("0", value: $value, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(InspectionPalette.ink)
                    .focused($focused)
                    .frame(minWidth: 65)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(InspectionPalette.muted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(InspectionPalette.background, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(focused ? InspectionPalette.accent : Color.clear, lineWidth: 1.4)
            }
        }
    }
}

private struct InspectionResultLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(InspectionPalette.muted)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(InspectionPalette.ink)
        }
        .padding(.vertical, 3)
    }
}

private struct InspectionCheckRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isOn ? InspectionPalette.accent : InspectionPalette.muted.opacity(0.65))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(InspectionPalette.ink)
                Spacer()
            }
            .padding(11)
            .background(isOn ? InspectionPalette.accent.opacity(0.06) : InspectionPalette.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
