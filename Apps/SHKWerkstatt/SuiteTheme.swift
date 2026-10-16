import SwiftUI

func S(_ de: String, _ en: String) -> String {
    let selected = UserDefaults.standard.string(forKey: "suite-language") ?? "system"
    let german = selected == "de" || (selected == "system" && Bundle.main.preferredLocalizations.first?.hasPrefix("de") == true)
    return german ? de : en
}
var suiteLanguage: SuiteLanguage { S("de", "en") == "de" ? .german : .english }
func SN(_ value: Double, digits: Int = 2) -> String {
    guard value.isFinite else { return "—" }
    return value.formatted(.number.locale(Locale(identifier: suiteLanguage == .german ? "de_DE" : "en_GB")).precision(.fractionLength(0...digits)))
}

enum SuiteTheme {
    static let teal = Color(uiColor: UIColor { trait in trait.userInterfaceStyle == .dark ? UIColor(red: 0.28, green: 0.79, blue: 0.75, alpha: 1) : UIColor(red: 0.02, green: 0.42, blue: 0.43, alpha: 1) })
    static let action = Color(red: 0.02, green: 0.42, blue: 0.43)
    static let copper = Color(uiColor: UIColor { trait in trait.userInterfaceStyle == .dark ? UIColor(red: 1, green: 0.64, blue: 0.38, alpha: 1) : UIColor(red: 0.66, green: 0.32, blue: 0.14, alpha: 1) })
    static let secondary = Color(uiColor: UIColor { trait in trait.userInterfaceStyle == .dark ? UIColor(red: 0.75, green: 0.79, blue: 0.80, alpha: 1) : UIColor(red: 0.32, green: 0.38, blue: 0.40, alpha: 1) })
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let paper = Color(uiColor: .secondarySystemGroupedBackground)
}

enum SuiteModule: String, CaseIterable, Identifiable {
    case heat, pipe, volume, air, cold, service
    var id: String { rawValue }
    var title: String {
        switch self {
        case .heat: S("Wärme", "Heating")
        case .pipe: S("Rohrnetz", "Pipe route")
        case .volume: S("Wasserinhalt", "Water volume")
        case .air: S("Lüftung", "Ventilation")
        case .cold: S("Kälte", "Refrigeration")
        case .service: "Service"
        }
    }
    var detail: String {
        switch self {
        case .heat: S("Räume und Heizkörper auslegen", "Size rooms and radiators")
        case .pipe: S("Abschnitte, Fluss und Druckverlust", "Sections, flow and pressure loss")
        case .volume: S("Bauteile und Füllmenge erfassen", "Record components and fill volume")
        case .air: S("Soll- und Ist-Volumenströme", "Target and measured air flow")
        case .cold: S("Messreihe mit Überhitzung und Unterkühlung", "Superheat and subcooling readings")
        case .service: S("Prüfen, dokumentieren, übergeben", "Inspect, document and hand over")
        }
    }
    var symbol: String {
        switch self {
        case .heat: "heater.vertical.fill"
        case .pipe: "point.topleft.down.to.point.bottomright.curvepath"
        case .volume: "drop.fill"
        case .air: "wind"
        case .cold: "snowflake"
        case .service: "checklist"
        }
    }
    var tint: Color {
        switch self {
        case .heat: SuiteTheme.copper
        case .pipe: SuiteTheme.copper
        case .volume: .blue
        case .air: SuiteTheme.teal
        case .cold: .indigo
        case .service: .green
        }
    }
    func count(in p: SuiteProject) -> Int {
        switch self {
        case .heat: p.heat.rooms.count
        case .pipe: p.pipe.sections.count
        case .volume: p.volume.components.count
        case .air: p.air.terminals.count
        case .cold: p.cold.readings.count
        case .service: p.service.completedTasks.count
        }
    }
}

struct SuiteCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(SuiteTheme.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.primary.opacity(0.05)))
            .shadow(color: .black.opacity(0.025), radius: 14, y: 5)
    }
}

struct SuiteModuleLabel: View {
    let module: SuiteModule
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: module.symbol).font(.title2.weight(.medium))
                .frame(width: 48, height: 48).foregroundStyle(module.tint)
                .background(module.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(module.title).font(.headline).foregroundStyle(.primary)
                Text(module.detail).font(.subheadline).foregroundStyle(SuiteTheme.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }.padding(.vertical, 5)
    }
}

struct SuiteNumberField: View {
    let title: String, unit: String
    let value: Binding<Double?>
    let required: Bool
    @State private var entered: String?
    @FocusState private var focused: Bool
    init(_ title: String, value: Binding<Double>, unit: String) {
        self.title = title; self.unit = unit; self.required = true
        self.value = Binding(get: { value.wrappedValue }, set: { value.wrappedValue = $0 ?? .nan })
    }
    init(_ title: String, optional: Binding<Double?>, unit: String) {
        self.title = title; self.unit = unit; self.required = false; self.value = optional
    }
    private var text: Binding<String> {
        Binding(get: {
            if let entered { return entered }
            guard let number = value.wrappedValue, number.isFinite else { return "" }
            return number.formatted(.number.grouping(.never).precision(.significantDigits(1...8)))
        }, set: { raw in
            entered = raw
            let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: "−", with: "-")
            value.wrappedValue = clean.isEmpty && !required ? nil : (Double(clean) ?? .nan)
        })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.medium))
            HStack(alignment: .firstTextBaseline) {
                TextField(required ? "0" : S("Nicht erfasst", "Not recorded"), text: text)
                    .keyboardType(.numbersAndPunctuation).focused($focused)
                    .font(.title3.monospacedDigit()).padding(.vertical, 10)
                    .accessibilityLabel(title + ", " + unit)
                    .onChange(of: focused) { _, isFocused in if !isFocused && value.wrappedValue?.isFinite == true { entered = nil } }
                    .onChange(of: value.wrappedValue) { _, _ in if !focused { entered = nil } }
                Text(unit).foregroundStyle(SuiteTheme.secondary).fixedSize()
            }
            if let number = value.wrappedValue, !number.isFinite {
                Text(S("Bitte eine gültige Zahl eingeben.", "Enter a valid number.")).font(.caption).foregroundStyle(.red)
            }
        }.padding(.vertical, 3)
    }
}

struct SuiteMetric: View {
    let title: String, value: String
    var tint: Color = SuiteTheme.teal
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundStyle(SuiteTheme.secondary)
            Text(value).font(.system(.title, design: .rounded).weight(.semibold)).foregroundStyle(tint).monospacedDigit()
        }.padding(.vertical, 5).accessibilityElement(children: .combine)
    }
}

/// Expand the label's actual hit region as well as its accessible Form-row frame.
/// On a wide iPad row, a label-only hit region leaves its center unresponsive.
struct SuiteRowButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
            .foregroundStyle(configuration.role == .destructive ? Color.red : SuiteTheme.teal)
            .opacity(enabled ? (configuration.isPressed ? 0.55 : 1) : 0.4)
    }
}

extension View {
    func suiteKeyboard() -> some View {
        scrollDismissesKeyboard(.interactively).toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(S("Fertig", "Done")) { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
            }
        }
    }
}
