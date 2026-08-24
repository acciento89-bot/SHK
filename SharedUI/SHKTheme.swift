import SwiftUI

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

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(.primary)
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
