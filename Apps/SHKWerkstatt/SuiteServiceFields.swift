import SwiftUI

struct SuiteServiceFields: View {
    @Binding var project: SuiteProject
    private var checks: [SystemCheckResult] { project.service.recordedChecks(language: suiteLanguage) }
    var body: some View {
        Section {
            SuiteNumberField(S("Vorlauf tatsächlich gemessen", "Measured supply temperature"), optional: $project.service.measuredFlowC, unit: "°C")
            SuiteNumberField(S("Rücklauf tatsächlich gemessen", "Measured return temperature"), optional: $project.service.measuredReturnC, unit: "°C")
            SuiteNumberField(S("Druck kalt", "Cold pressure"), optional: $project.service.coldPressureBar, unit: "bar")
            SuiteNumberField(S("Druck warm", "Hot pressure"), optional: $project.service.hotPressureBar, unit: "bar")
        } header: { Text(S("Messwerte vor Ort", "On-site measurements")) }
          footer: { Text(S("Leere Felder bleiben offen. Die Auslegungstemperaturen aus Wärme sind keine Service-Messungen.", "Empty fields remain unrecorded. Heating design temperatures are not service measurements.")) }
        Section {
            DisclosureGroup(S("Prüfvorgaben für diese Anlage", "Inspection criteria for this system")) {
                SuiteNumberField(S("Druckbereich mindestens", "Minimum fill pressure"), value: $project.service.minimumPressureBar, unit: "bar")
                SuiteNumberField(S("Druckbereich höchstens", "Maximum fill pressure"), value: $project.service.maximumPressureBar, unit: "bar")
                SuiteNumberField(S("Spreizung mindestens", "Minimum temperature difference"), value: $project.service.minimumSpreadK, unit: "K")
                SuiteNumberField(S("Spreizung höchstens", "Maximum temperature difference"), value: $project.service.maximumSpreadK, unit: "K")
                SuiteNumberField(S("Statische Höhe", "Static height"), value: $project.service.staticHeightM, unit: "m")
                SuiteNumberField(S("Reserve zum statischen Druck", "Static pressure reserve"), value: $project.service.staticReserveBar, unit: "bar")
                SuiteNumberField(S("Sicherheitsventil-Wert", "Safety valve value"), value: $project.service.safetyValveBar, unit: "bar")
                SuiteNumberField(S("Geforderte Reserve zum Ventil", "Required valve margin"), value: $project.service.safetyMarginBar, unit: "bar")
                SuiteNumberField(S("Maximaler Druckanstieg", "Maximum pressure rise"), value: $project.service.maximumPressureRiseBar, unit: "bar")
            }
            if !project.service.isValid { Text(S("Messwerte und Vorgaben prüfen. Druckwerte0–100bar, Temperaturen−50–150°C; minimale Vorgaben dürfen nicht über den maximalen liegen.", "Check readings and criteria. Pressures0–100bar, temperatures−50–150°C; minimum criteria must not exceed maximum criteria.")).font(.footnote).foregroundStyle(.red) }
        }
        Section {
            if checks.isEmpty {
                Label(S("Prüfung noch unvollständig", "Inspection incomplete"), systemImage: "circle.dotted").foregroundStyle(SuiteTheme.secondary)
            }
            ForEach(checks) { check in
                VStack(alignment: .leading, spacing: 7) {
                    Label(check.title, systemImage: check.severity == .ok ? "checkmark.circle" : "exclamationmark.triangle")
                        .font(.headline).foregroundStyle(check.severity == .ok ? SuiteTheme.teal : SuiteTheme.copper)
                    Text(check.detail).font(.subheadline).foregroundStyle(SuiteTheme.secondary)
                }.padding(.vertical, 6)
            }
        } header: { Text(S("Plausibilität der Eingaben", "Input plausibility")) }
        Section {
            ForEach(Array(SuiteService.tasks.enumerated()), id: \.element) { index, task in
                Toggle(isOn: Binding(get: { project.service.completedTasks.contains(task) }, set: { done in if done { project.service.completedTasks.insert(task) } else { project.service.completedTasks.remove(task) } })) {
                    Text(taskName(index)).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                }
            }
        } header: { Text(S("Dokumentierte Arbeiten", "Recorded work")) }
        Section {
            TextField(S("Befund, Maßnahmen, offene Punkte …", "Findings, work done, open points …"), text: $project.service.notes, axis: .vertical).lineLimit(3...10)
            Text(S("Prüfvorgaben müssen zur tatsächlichen Anlage passen. Herstellerangaben und reale Messungen haben Vorrang. Keine automatische Sicherheits- oder Normfreigabe.", "Inspection criteria must match the actual system. Manufacturer data and real measurements take precedence. Not an automatic safety or standards approval.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
        }
    }
    private func taskName(_ index: Int) -> String {
        let de = ["Sichtprüfung / Leckage", "Entlüftung geprüft", "Schmutzfänger / Filter geprüft", "Ausdehnungsgefäß geprüft", "Sicherheitsventil geprüft", "Pumpe / Regelung geprüft"]
        let en = ["Visual inspection / leakage", "Venting checked", "Strainer / filter checked", "Expansion vessel checked", "Safety valve checked", "Pump / controls checked"]
        return S(de[index], en[index])
    }
}
