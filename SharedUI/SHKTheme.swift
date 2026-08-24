import SwiftUI

struct SHKBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.015, green: 0.045, blue: 0.055), Color(red: 0.02, green: 0.09, blue: 0.09)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct SHKCard<Content: View>: View {
    @ViewBuilder var content: Content
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

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: $value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 110)
            Text(unit).foregroundStyle(.secondary)
        }
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
