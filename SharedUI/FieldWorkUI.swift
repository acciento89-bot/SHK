import SwiftUI

func tr(_ german: String, _ english: String) -> String {
    Locale.current.language.languageCode?.identifier == "de" ? german : english
}
func fieldNumber(_ value: Double, digits: Int = 1) -> String {
    value.formatted(.number.precision(.fractionLength(0...digits)))
}

/// Atomic writes; failed loads are never silently replaced by an empty notebook.
@MainActor final class FieldStore<Item: Codable & Identifiable>: ObservableObject where Item.ID == UUID {
    @Published private(set) var items: [Item] = []
    @Published var error: String?
    private var loadFailed = false
    private let url: URL
    init(_ name: String) {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        url = directory.appendingPathComponent(name + "-v1.json")
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                items = try JSONDecoder().decode([Item].self, from: Data(contentsOf: url))
            }
        } catch {
            loadFailed = true
            self.error = tr("Gespeicherte Projekte konnten nicht geöffnet werden. Die Datei wurde nicht verändert.", "Saved projects could not be opened. The file was left intact.")
        }
    }
    @discardableResult func save(_ item: Item) -> Bool {
        var next = items
        if let index = next.firstIndex(where: { $0.id == item.id }) { next[index] = item }
        else { next.insert(item, at: 0) }
        return persist(next)
    }
    func delete(_ item: Item) { _ = persist(items.filter { $0.id != item.id }) }
    private func persist(_ next: [Item]) -> Bool {
        guard !loadFailed else {
            error = tr("Speichern gesperrt, um vorhandene Daten zu erhalten. Bitte App-Support kontaktieren.", "Saving is blocked to preserve existing data. Please contact app support.")
            return false
        }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(next).write(to: url, options: .atomic)
            items = next
            return true
        } catch {
            self.error = tr("Nicht gespeichert. Bitte freien Gerätespeicher prüfen und erneut versuchen.", "Not saved. Check available device storage and try again.")
            return false
        }
    }
}

struct WorkHero: View {
    let eyebrow: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label { Text(eyebrow).foregroundStyle(.primary) } icon: { Image(systemName: icon).foregroundStyle(color) }.font(.headline)
            Text(title).font(.largeTitle.bold()).fixedSize(horizontal: false, vertical: true)
            Text(description).font(.body).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.padding(.vertical, 12).accessibilityElement(children: .combine)
    }
}

struct WorkMetric: View {
    let label: String
    let value: String
    var color: Color = .primary
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Text(value).font(.title2.bold()).foregroundStyle(color).monospacedDigit()
        }.fixedSize(horizontal: false, vertical: true).accessibilityElement(children: .combine)
    }
}

struct WorkNumber: View {
    let title: String
    @Binding var value: Double
    let unit: String
    @State private var text: String
    init(title: String, value: Binding<Double>, unit: String) {
        self.title = title; self._value = value; self.unit = unit
        self._text = State(initialValue: value.wrappedValue.isFinite ? value.wrappedValue.formatted(.number.grouping(.never).precision(.fractionLength(0...6))) : "")
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.body)
            HStack(alignment: .firstTextBaseline) {
                TextField(title, text: $text)
                    .keyboardType(.numbersAndPunctuation).font(.title3.monospacedDigit())
                    .accessibilityLabel(title + ", " + unit)
                    .onChange(of: text) { _, newValue in
                        let decimal = Locale.current.decimalSeparator ?? "."
                        let normalized = newValue.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: decimal, with: ".").replacingOccurrences(of: "−", with: "-")
                        value = Double(normalized) ?? .nan
                    }
                    .padding(10).background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                Text(unit).font(.body).foregroundStyle(.secondary)
            }
            if !value.isFinite { Text(tr("Bitte eine gültige Zahl eingeben", "Please enter a valid number")).font(.subheadline).foregroundStyle(.red) }
        }.padding(.vertical, 3)
    }
}

struct WorkEmpty: View {
    let title: String
    let detail: String
    let icon: String
    var body: some View {
        ContentUnavailableView(title, systemImage: icon, description: Text(detail))
    }
}

struct WorkActions: ToolbarContent {
    let valid: Bool
    let save: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(tr("Abbrechen", "Cancel")) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(tr("Speichern", "Save"), action: save).disabled(!valid).fontWeight(.semibold)
        }
    }
}

struct WorkValidation: View {
    let message: String
    var body: some View { Label(message, systemImage: "exclamationmark.circle").foregroundStyle(.red).font(.body) }
}

extension View {
    func workError(_ error: Binding<String?>) -> some View {
        alert(tr("Projekt nicht gespeichert", "Project not saved"), isPresented: Binding(
            get: { error.wrappedValue != nil }, set: { if !$0 { error.wrappedValue = nil } }
        )) { Button("OK") { error.wrappedValue = nil } } message: { Text(error.wrappedValue ?? "") }
    }
}
