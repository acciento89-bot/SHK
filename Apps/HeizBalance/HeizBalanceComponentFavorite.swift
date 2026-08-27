import Foundation

struct HeizBalanceComponentFavorite: Identifiable, Codable, Hashable {
    static let schemaVersion = "component-favorite-v1"

    var schema: String
    var id: UUID
    var title: String
    var kind: HeizBalanceComponent.Kind
    var componentName: String
    var uValue: Double?
    var uValueSource: HeizBalanceInputSource?
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        component: HeizBalanceComponent,
        createdAt: Date = Date()
    ) {
        self.schema = Self.schemaVersion
        self.id = id
        self.title = title
        self.kind = component.kind
        self.componentName = component.name
        self.uValue = component.uValue
        self.uValueSource = component.uValueSource
        self.note = component.note
        self.createdAt = createdAt
    }

    var detail: String {
        var parts = [kind.title]
        if let uValue {
            parts.append("U " + uValue.formatted(.number.precision(.fractionLength(0...3))) + " W/(m²·K)")
        }
        if let uValueSource {
            parts.append(uValueSource.title)
        }
        return parts.joined(separator: " · ")
    }

    func makeComponent() -> HeizBalanceComponent {
        HeizBalanceComponent(
            kind: kind,
            name: resolvedComponentName,
            area: 0,
            uValue: uValue,
            uValueSource: uValueSource,
            thermalBoundary: kind.defaultThermalBoundary,
            customBoundaryTemperatureC: nil,
            note: note
        )
    }

    func apply(to component: inout HeizBalanceComponent) {
        component.kind = kind
        component.name = resolvedComponentName
        component.uValue = uValue
        component.uValueSource = uValueSource
        component.note = note
        component.thermalBoundary = kind.defaultThermalBoundary
        component.customBoundaryTemperatureC = nil
        // Area is deliberately not touched: it always remains a room-specific input.
    }

    private var resolvedComponentName: String {
        let clean = componentName.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? kind.title : clean
    }
}
