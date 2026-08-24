import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SHKBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.015, green: 0.045, blue: 0.055), Color(red: 0.02, green: 0.09, blue: 0.09)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct SHKCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial.opacity(0.45), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.08)))
    }
}

struct MetricField: View {
    let title: String
    let unit: String
    @Binding var value: Double
    @FocusState private var isFocused: Bool

    private var isDeltaT50NominalPower: Bool {
        title == "Nennleistung ΔT50"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 12) {
                HStack(spacing: 7) {
                    Text(isDeltaT50NominalPower ? "Hersteller-Nennleistung" : title)
                        .foregroundStyle(.primary)

                    if isDeltaT50NominalPower {
                        Text("ΔT50")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.mint)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.mint.opacity(0.12), in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 7) {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.mint)

                    TextField("0", value: $value, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .focused($isFocused)

                    Text(unit)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 10)
                .frame(width: 156)
                .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(isFocused ? Color.mint : Color.white.opacity(0.20), lineWidth: isFocused ? 1.6 : 1)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = true
                }
            }

            if isDeltaT50NominalPower {
                Text("ΔT50 = mittlere Heizkörper-Übertemperatur zum Raum (z. B. 75/65/20 °C), nicht die VL/RL-Spreizung.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct BigResult: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(.mint)
            Text(subtitle).font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct SHKKeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
                        dismissKeyboard()
                    }
                    .fontWeight(.semibold)
                }
            }
    }

    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}

extension View {
    func shkKeyboardDismissal() -> some View {
        modifier(SHKKeyboardDismissModifier())
    }
}
