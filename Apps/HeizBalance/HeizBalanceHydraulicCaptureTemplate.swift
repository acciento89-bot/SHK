import Foundation

struct HeizBalanceHydraulicCaptureTemplate: Identifiable, Codable, Hashable {
    static let schemaVersion = "hydraulic-capture-template-v1"

    var schema: String
    var id: UUID
    var title: String
    var pipeSections: [HeizBalancePipeSection]
    var hydraulicComponents: [HeizBalanceHydraulicLossComponent]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        surface: HeizBalanceHeatingSurface,
        createdAt: Date = Date()
    ) {
        self.schema = Self.schemaVersion
        self.id = id
        self.title = title
        self.pipeSections = Self.safePipeStructure(from: surface.pipeSections ?? [])
        self.hydraulicComponents = Self.safeComponentStructure(from: surface.hydraulicLossComponents ?? [])
        self.createdAt = createdAt
    }

    var detail: String {
        "\(pipeSections.count) Rohrabschnitte · \(hydraulicComponents.count) Bauteile"
    }

    func apply(to surface: inout HeizBalanceHeatingSurface) {
        surface.pipeSections = Self.safePipeStructure(from: pipeSections)
        surface.hydraulicLossComponents = Self.safeComponentStructure(from: hydraulicComponents)
        surface.hydraulicComponentAssessmentComplete = false
    }

    static func safePipeStructure(from sections: [HeizBalancePipeSection]) -> [HeizBalancePipeSection] {
        sections.map { section in
            HeizBalancePipeSection(
                name: section.name,
                role: section.effectiveRole,
                explicitDesignVolumeFlowLPH: nil,
                volumeFlowSource: nil,
                innerDiameterMM: section.innerDiameterMM,
                lengthM: section.lengthM,
                roughnessMM: section.roughnessMM,
                zetaTotal: section.zetaTotal,
                note: section.note
            )
        }
    }

    static func safeComponentStructure(from components: [HeizBalanceHydraulicLossComponent]) -> [HeizBalanceHydraulicLossComponent] {
        components.map { component in
            HeizBalanceHydraulicLossComponent(
                kind: component.kind,
                name: component.name,
                pressureLossKPa: nil,
                source: nil,
                valveProductData: component.valveProductData,
                note: component.note
            )
        }
    }
}

extension HeizBalanceHeatingSurface {
    func duplicatedWithHydraulicStructureForCapture() -> HeizBalanceHeatingSurface {
        HeizBalanceHeatingSurface(
            kind: kind,
            name: name + " Kopie",
            manufacturer: manufacturer,
            model: model,
            nominalPowerDeltaT50W: nominalPowerDeltaT50W,
            exponent: exponent,
            powerSource: powerSource,
            assignedRequiredPowerW: nil,
            pipeSections: HeizBalanceHydraulicCaptureTemplate.safePipeStructure(from: pipeSections ?? []),
            hydraulicLossComponents: HeizBalanceHydraulicCaptureTemplate.safeComponentStructure(from: hydraulicLossComponents ?? []),
            hydraulicComponentAssessmentComplete: false,
            replacementSelection: nil,
            note: note
        )
    }
}
