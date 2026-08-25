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
        return parts.joined(separator: " · ")
    }

    func apply(to component: inout HeizBalanceComponent) {
        component.kind = kind
        component.name = componentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? kind.title
            : componentName
        component.uValue = uValue
        component.uValueSource = uValueSource
        component.note = note
        component.thermalBoundary = kind.defaultThermalBoundary
        component.customBoundaryTemperatureC = nil
    }
}
