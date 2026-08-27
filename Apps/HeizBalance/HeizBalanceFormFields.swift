import SwiftUI

struct InputSourcePicker: View {
    let title: String
    @Binding var selection: HeizBalanceInputSource?

    var body: some View {
        Picker(title, selection: $selection) {
            Text("Nicht angegeben").tag(nil as HeizBalanceInputSource?)
            ForEach(HeizBalanceInputSource.allCases) { source in
                Text(source.title).tag(Optional(source))
            }
        }
    }
}

struct DecimalField: View {
    let title: String
    @Binding var value: Double
    let unit: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: $value, format: .number.precision(.fractionLength(0...3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 80, maxWidth: 120)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}

struct OptionalDecimalField: View {
    let title: String
    @Binding var value: Double?
    let unit: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("optional", value: $value, format: .number.precision(.fractionLength(0...3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 90, maxWidth: 130)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}
